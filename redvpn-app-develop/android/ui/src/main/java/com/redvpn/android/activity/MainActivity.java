/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android.activity;

import android.annotation.SuppressLint;
import android.content.ContentResolver;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.LinearLayout;

import com.google.android.material.navigation.NavigationView;

import com.redvpn.android.Application;
import com.redvpn.android.R;
import com.redvpn.android.fragment.AboutFragment;
import com.redvpn.android.fragment.PrivacyPolicyFragment;
import com.redvpn.android.fragment.TunnelListFragment;
import com.redvpn.android.model.ObservableTunnel;
import com.redvpn.android.redVpnProfile.ConfigBuilder;
import com.redvpn.android.redVpnProfile.ConfigBuilderCallback;
import com.redvpn.config.Config;
import com.redvpn.crypto.KeyPair;
import com.redvpn.util.NonNullForAll;

import java.io.FileNotFoundException;
import java.io.InputStream;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.widget.AppCompatButton;
import androidx.appcompat.widget.Toolbar;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import java9.util.concurrent.CompletableFuture;
import java9.util.concurrent.CompletionStage;

@NonNullForAll
public class MainActivity extends BaseActivity implements NavigationView.OnNavigationItemSelectedListener {
    @Nullable private Toolbar toolbar;
    private DrawerLayout drawer;
    @Nullable private TunnelListFragment listFragment;
    private static final String TAG = "RedVPN/" + MainActivity.class.getSimpleName();
    private KeyPair keyPair;

    @Override
    public boolean onNavigationItemSelected(@NonNull MenuItem menuItem) {
        FragmentManager fragmentManager = getSupportFragmentManager();
        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container);
        switch (menuItem.getItemId()) {
            case R.id.nav_about:
                if (!(currentFragment instanceof  AboutFragment)) {
                    fragmentManager.beginTransaction()
                            .replace(R.id.fragment_container, new AboutFragment())
                            .addToBackStack(null).commit();
                }
                break;
            case R.id.nav_privacy:
                if (!(currentFragment instanceof PrivacyPolicyFragment)) {
                    fragmentManager.beginTransaction()
                            .replace(R.id.fragment_container, new PrivacyPolicyFragment())
                            .addToBackStack(null).commit();
                }
                break;
        }
        drawer.closeDrawer(GravityCompat.START);

        return true;
    }

    @Override
    public void onBackPressed() {
        if(drawer.isDrawerOpen(GravityCompat.START)) {
            drawer.closeDrawer(GravityCompat.START);
        }
        else {
            final int backStackEntries = getSupportFragmentManager().getBackStackEntryCount();
            if(backStackEntries == 1 && toolbar != null) {
                setSupportActionBar(toolbar);
                ActionBarDrawerToggle toggle = new ActionBarDrawerToggle(this, drawer, toolbar, R.string.navigation_drawer_open, R.string.navigation_drawer_close);
                drawer.addDrawerListener(toggle);
                toggle.syncState();
                toolbar.setNavigationIcon(R.drawable.ic_menu);
                getSupportActionBar().setDisplayShowTitleEnabled(false);
                getSupportActionBar().show();
            }

            super.onBackPressed();

            updateNavigationItemSelection();
        }
    }

    private void updateNavigationItemSelection() {
        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container);
        NavigationView navigationView = findViewById(R.id.nav_view);
        if(currentFragment instanceof AboutFragment) {
            navigationView.setCheckedItem(R.id.nav_about);
        }
        else if (currentFragment instanceof PrivacyPolicyFragment) {
            navigationView.setCheckedItem(R.id.nav_privacy);
        }
        else if (currentFragment instanceof TunnelListFragment){
            MenuItem checkedItem = navigationView.getCheckedItem();
            if(checkedItem != null)
                checkedItem.setChecked(false);
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);

        final String action = intent.getAction();
        if(Intent.ACTION_VIEW.equals(action)) {
            loadNewConfigFile(intent);
        }
    }

    // We use onTouchListener here to avoid the UI click sound, hence
    // calling View#performClick defeats the purpose of it.
    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void onCreate(@Nullable final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.main_activity);

        final Intent intent = getIntent();
        final String action = intent.getAction();

        drawer = findViewById(R.id.drawer_layout);
        NavigationView navigationView = findViewById(R.id.nav_view);
        navigationView.setNavigationItemSelectedListener(this);
        View headerView = navigationView.getHeaderView(0);

        final AppCompatButton drawerCloseButton = headerView.findViewById(R.id.drawer_arrow_left);
        drawerCloseButton.setOnClickListener(v -> {
            drawer.closeDrawer(GravityCompat.START, true);
        });

        toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        ActionBarDrawerToggle toggle = new ActionBarDrawerToggle(this, drawer, toolbar, R.string.navigation_drawer_open, R.string.navigation_drawer_close);
        drawer.addDrawerListener(toggle);
        toggle.syncState();
        toolbar.setNavigationIcon(R.drawable.ic_menu);
        getSupportActionBar().setDisplayShowTitleEnabled(false);

        listFragment = new TunnelListFragment();
        if(savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction().replace(R.id.fragment_container, listFragment).commit();
            // Make sure the fragment is attached so the tunnel can be imported if needed...
            getSupportFragmentManager().executePendingTransactions();
        }

        keyPair = Application.getKeyStore().getKeyPair();
        if(Intent.ACTION_VIEW.equals(action)) {
            loadNewConfigFile(intent);
        } else {
            createTunnel();
        }

        // Set selected tunnel...
        Application.getTunnelManager().getTunnels().thenAccept(tunnels -> {
            final ObservableTunnel tunnel = tunnels.get(Application.TUNNEL_NAME);
            setSelectedTunnel(tunnel);
        });
    }

    private void openUrl(final String url) {
        Intent openURL = new Intent(android.content.Intent.ACTION_VIEW);
        openURL.setData(Uri.parse(url));
        startActivity(openURL);
    }

    private CompletionStage<Config> getTunnelConfig(final ObservableTunnel tunnel) {
        if(tunnel != null) {
            return tunnel.getConfigAsync();
        }

        return CompletableFuture.completedFuture(null);
    }

    private boolean isTunnelPrivateKeyCorrect(final Config config) {
        boolean isCorrect = true;

        if(config != null) {
            final KeyPair tunnelKeyPair = config.getInterface().getKeyPair();
            isCorrect = tunnelKeyPair.getPrivateKey().toBase64().equals(keyPair.getPrivateKey().toBase64());
        }

        return isCorrect;
    }

    private void createTunnel() {
        final LinearLayout loadingLayout = findViewById(R.id.tunnel_creation_loading);
        Application.getTunnelManager().getTunnels().thenAccept(tunnels -> {
            final ObservableTunnel tunnel = tunnels.get(Application.TUNNEL_NAME);
            getTunnelConfig(tunnel).thenAccept(config -> {
                boolean isPrivateKeyCorrect = isTunnelPrivateKeyCorrect(config);

                if(tunnel == null || !isPrivateKeyCorrect) {
                    loadingLayout.setVisibility(View.VISIBLE);
                    ConfigBuilder.build(keyPair, null, new ConfigBuilderCallback() {
                        @Override
                        public void onSuccess(String configText) {
                            if(tunnel == null) {
                                listFragment.importTunnel(configText);
                            }
                            else {
                                listFragment.updateTunnel(tunnel, configText);
                            }
                            loadingLayout.setVisibility(View.GONE);
                        }

                        @Override
                        public void onFail() {
                            // Import the fake tunnel from the raw folder if it doesn't exist...
                            if(tunnel == null) {
                                final InputStream inputStream = getResources().openRawResource(R.raw.tunnel);
                                listFragment.importTunnel(inputStream);
                            }
                            loadingLayout.setVisibility(View.GONE);
                        }
                    });
                }
            });
        });
    }

    private void loadNewConfigFile(final Intent intent) {
        final Uri uri = intent.getData();
        final ContentResolver contentResolver = this.getContentResolver();
        try {
            final InputStream inputStream = contentResolver.openInputStream(uri);

            Application.getTunnelManager().getTunnels().thenAccept(tunnels -> {
                if(tunnels.containsKey(Application.TUNNEL_NAME) == false) {
                    listFragment.importTunnel(inputStream);
                }
                else {
                    final ObservableTunnel tunnel = tunnels.get(Application.TUNNEL_NAME);
                    listFragment.updateTunnel(tunnel, inputStream);
                }
            });
        }
        catch (FileNotFoundException ex) {
            Log.e(TAG, "File not found.", ex);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(final Menu menu) {
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(final MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                onBackPressed();
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    @Override
    protected void onSelectedTunnelChanged(@Nullable final ObservableTunnel oldTunnel,
                                           @Nullable final ObservableTunnel newTunnel) {
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }
}
