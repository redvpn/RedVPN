/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android.activity;

import android.os.Bundle;

import com.redvpn.android.Application;
import com.redvpn.android.model.ObservableTunnel;
import com.redvpn.util.NonNullForAll;

import io.sentry.Sentry;
import io.sentry.android.AndroidSentryClientFactory;

import java.util.Objects;

import androidx.appcompat.app.AppCompatActivity;
import androidx.databinding.CallbackRegistry;
import androidx.databinding.CallbackRegistry.NotifierCallback;
import androidx.annotation.Nullable;

/**
 * Base class for activities that need to remember the currently-selected tunnel.
 */

@NonNullForAll
public abstract class BaseActivity extends AppCompatActivity {
    private static final String KEY_SELECTED_TUNNEL = "selected_tunnel";

    private final SelectionChangeRegistry selectionChangeRegistry = new SelectionChangeRegistry();
    @Nullable private ObservableTunnel selectedTunnel;

    public void addOnSelectedTunnelChangedListener(final OnSelectedTunnelChangedListener listener) {
        selectionChangeRegistry.add(listener);
    }

    @Nullable
    public ObservableTunnel getSelectedTunnel() {
        return selectedTunnel;
    }

    @Override
    protected void onCreate(@Nullable final Bundle savedInstanceState) {
        // Initialize Sentry...
        String sentryDsn = "https://fdf19792f85d4820869d9adbbaa80351@o1353527.ingest.sentry.io/6639672";
        Sentry.init(sentryDsn, new AndroidSentryClientFactory(getApplicationContext()));
        
        // Restore the saved tunnel if there is one; otherwise grab it from the arguments.
        final String savedTunnelName;
        if (savedInstanceState != null)
            savedTunnelName = savedInstanceState.getString(KEY_SELECTED_TUNNEL);
        else if (getIntent() != null)
            savedTunnelName = getIntent().getStringExtra(KEY_SELECTED_TUNNEL);
        else
            savedTunnelName = null;

        if (savedTunnelName != null)
            Application.getTunnelManager().getTunnels()
                    .thenAccept(tunnels -> setSelectedTunnel(tunnels.get(savedTunnelName)));

        // The selected tunnel must be set before the superclass method recreates fragments.
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void onSaveInstanceState(final Bundle outState) {
        if (selectedTunnel != null)
            outState.putString(KEY_SELECTED_TUNNEL, selectedTunnel.getName());
        super.onSaveInstanceState(outState);
    }

    protected abstract void onSelectedTunnelChanged(@Nullable ObservableTunnel oldTunnel, @Nullable ObservableTunnel newTunnel);

    public void removeOnSelectedTunnelChangedListener(
            final OnSelectedTunnelChangedListener listener) {
        selectionChangeRegistry.remove(listener);
    }

    public void setSelectedTunnel(@Nullable final ObservableTunnel tunnel) {
        final ObservableTunnel oldTunnel = selectedTunnel;
        if (Objects.equals(oldTunnel, tunnel))
            return;
        selectedTunnel = tunnel;
        onSelectedTunnelChanged(oldTunnel, tunnel);
        selectionChangeRegistry.notifyCallbacks(oldTunnel, 0, tunnel);
    }

    public interface OnSelectedTunnelChangedListener {
        void onSelectedTunnelChanged(@Nullable ObservableTunnel oldTunnel, @Nullable ObservableTunnel newTunnel);
    }

    private static final class SelectionChangeNotifier
            extends NotifierCallback<OnSelectedTunnelChangedListener, ObservableTunnel, ObservableTunnel> {
        @Override
        public void onNotifyCallback(final OnSelectedTunnelChangedListener listener,
                                     final ObservableTunnel oldTunnel, final int ignored,
                                     final ObservableTunnel newTunnel) {
            listener.onSelectedTunnelChanged(oldTunnel, newTunnel);
        }
    }

    private static final class SelectionChangeRegistry
            extends CallbackRegistry<OnSelectedTunnelChangedListener, ObservableTunnel, ObservableTunnel> {
        private SelectionChangeRegistry() {
            super(new SelectionChangeNotifier());
        }
    }
}
