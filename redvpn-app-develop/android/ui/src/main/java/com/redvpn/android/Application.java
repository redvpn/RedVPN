/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.StrictMode;
import android.util.Log;


import com.android.volley.DefaultRetryPolicy;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.Volley;

import com.redvpn.android.backend.Backend;
import com.redvpn.android.backend.GoBackend;
import com.redvpn.android.backend.WgQuickBackend;
import com.redvpn.android.configStore.FileConfigStore;
import com.redvpn.android.model.TunnelManager;
import com.redvpn.android.redVpnProfile.KeyStore;
import com.redvpn.android.redVpnProfile.RegionManager;
import com.redvpn.android.util.AsyncWorker;
import com.redvpn.android.util.ExceptionLoggers;
import com.redvpn.android.util.ModuleLoader;
import com.redvpn.android.util.RootShell;
import com.redvpn.android.util.ToolsInstaller;
import com.redvpn.util.NonNullForAll;

import java.lang.ref.WeakReference;
import java.util.Locale;

import androidx.annotation.Nullable;
import androidx.preference.PreferenceManager;
import java9.util.concurrent.CompletableFuture;

@NonNullForAll
public class Application extends android.app.Application implements SharedPreferences.OnSharedPreferenceChangeListener {
    private static final String TAG = "RedVPN/" + Application.class.getSimpleName();
    public static final String USER_AGENT = String.format(Locale.ENGLISH, "RedVPN/%s (Android %d; %s; %s; %s %s; %s)", BuildConfig.VERSION_NAME, Build.VERSION.SDK_INT, Build.SUPPORTED_ABIS.length > 0 ? Build.SUPPORTED_ABIS[0] : "unknown ABI", Build.BOARD, Build.MANUFACTURER, Build.MODEL, Build.FINGERPRINT);

    @SuppressWarnings("NullableProblems") private static WeakReference<Application> weakSelf;
    private final CompletableFuture<Backend> futureBackend = new CompletableFuture<>();
    @SuppressWarnings("NullableProblems") private AsyncWorker asyncWorker;
    @Nullable private Backend backend;
    @SuppressWarnings("NullableProblems") private RootShell rootShell;
    @SuppressWarnings("NullableProblems") private SharedPreferences sharedPreferences;
    @SuppressWarnings("NullableProblems") private ToolsInstaller toolsInstaller;
    @SuppressWarnings("NullableProblems") private ModuleLoader moduleLoader;
    @SuppressWarnings("NullableProblems") private TunnelManager tunnelManager;
    @SuppressWarnings("NullableProblems") private KeyStore keyStore;
    @SuppressWarnings("NullableProblems") private RegionManager regionManager;
    @SuppressWarnings("NullableProblems") private DefaultRetryPolicy defaultRetryPolicy;

    private RequestQueue requestQueue;
    public static final String TUNNEL_NAME = "RedVPN";

    public Application() {
        weakSelf = new WeakReference<>(this);
    }

    public static Application get() {
        return weakSelf.get();
    }

    public static AsyncWorker getAsyncWorker() {
        return get().asyncWorker;
    }

    public static Backend getBackend() {
        final Application app = get();
        synchronized (app.futureBackend) {
            if (app.backend == null) {
                Backend backend = null;
                boolean didStartRootShell = false;
                if (!ModuleLoader.isModuleLoaded() && app.moduleLoader.moduleMightExist()) {
                    try {
                        app.rootShell.start();
                        didStartRootShell = true;
                        app.moduleLoader.loadModule();
                    } catch (final Exception ignored) {
                    }
                }
                if (ModuleLoader.isModuleLoaded()) {
                    try {
                        if (!didStartRootShell)
                            app.rootShell.start();
                        WgQuickBackend wgQuickBackend = new WgQuickBackend(app.getApplicationContext(), app.rootShell, app.toolsInstaller);
                        wgQuickBackend.setMultipleTunnels(app.sharedPreferences.getBoolean("multiple_tunnels", false));
                        backend = wgQuickBackend;
                    } catch (final Exception ignored) {
                    }
                }
                if (backend == null) {
                    backend = new GoBackend(app.getApplicationContext());
                    GoBackend.setAlwaysOnCallback(() -> {
                        get().tunnelManager.restoreState(true).whenComplete(ExceptionLoggers.D);
                    });
                }
                app.backend = backend;
            }
            return app.backend;
        }
    }

    public static CompletableFuture<Backend> getBackendAsync() {
        return get().futureBackend;
    }

    public static RootShell getRootShell() {
        return get().rootShell;
    }

    public static SharedPreferences getSharedPreferences() {
        return get().sharedPreferences;
    }

    public static ToolsInstaller getToolsInstaller() {
        return get().toolsInstaller;
    }

    public static ModuleLoader getModuleLoader() { 
        return get().moduleLoader; 
    }

    public static TunnelManager getTunnelManager() { return get().tunnelManager; }

    public static RegionManager getRegionManager() { return get().regionManager; }

    public static DefaultRetryPolicy getDefaultRetryPolicy() { return get().defaultRetryPolicy; }

    public static KeyStore getKeyStore() { return get().keyStore; }

    public static RequestQueue getRequestQueue() {
        final Application app = get();
        if (app.requestQueue == null) {
            app.requestQueue = Volley.newRequestQueue(app.getApplicationContext());
        }

        return app.requestQueue;
    }

    @Override
    protected void attachBaseContext(final Context context) {
        super.attachBaseContext(context);

        if (BuildConfig.MIN_SDK_VERSION > Build.VERSION.SDK_INT) {
            final Intent intent = new Intent(Intent.ACTION_MAIN);
            intent.addCategory(Intent.CATEGORY_HOME);
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            System.exit(0);
        }

        if (BuildConfig.DEBUG) {
            StrictMode.setVmPolicy(new StrictMode.VmPolicy.Builder().detectAll().penaltyLog().build());
        }
    }

    @Override
    public void onCreate() {
        Log.i(TAG, USER_AGENT);
        super.onCreate();

        asyncWorker = new AsyncWorker(AsyncTask.SERIAL_EXECUTOR, new Handler(Looper.getMainLooper()));
        rootShell = new RootShell(getApplicationContext());
        toolsInstaller = new ToolsInstaller(getApplicationContext(), rootShell);
        moduleLoader = new ModuleLoader(getApplicationContext(), rootShell, USER_AGENT);

        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(getApplicationContext());

        tunnelManager = new TunnelManager(new FileConfigStore(getApplicationContext()));
        tunnelManager.onCreate();

        regionManager = new RegionManager();

        defaultRetryPolicy = new DefaultRetryPolicy(5 * 1000, DefaultRetryPolicy.DEFAULT_MAX_RETRIES, DefaultRetryPolicy.DEFAULT_BACKOFF_MULT);

        keyStore = new KeyStore();

        asyncWorker.supplyAsync(Application::getBackend).thenAccept(futureBackend::complete);

        sharedPreferences.registerOnSharedPreferenceChangeListener(this);
    }

    @Override
    public void onTerminate() {
        sharedPreferences.unregisterOnSharedPreferenceChangeListener(this);
        super.onTerminate();
    }

    @Override
    public void onSharedPreferenceChanged(final SharedPreferences sharedPreferences, final String key) {
        if ("multiple_tunnels".equals(key) && backend != null && backend instanceof WgQuickBackend)
            ((WgQuickBackend)backend).setMultipleTunnels(sharedPreferences.getBoolean(key, false));
    }
}
