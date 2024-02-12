/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.redvpn.android.backend.WgQuickBackend;
import com.redvpn.android.model.TunnelManager;
import com.redvpn.android.util.ExceptionLoggers;
import com.redvpn.util.NonNullForAll;

@NonNullForAll
public class BootShutdownReceiver extends BroadcastReceiver {
    private static final String TAG = "RedVPN/" + BootShutdownReceiver.class.getSimpleName();

    @Override
    public void onReceive(final Context context, final Intent intent) {
        Application.getBackendAsync().thenAccept(backend -> {
            if (!(backend instanceof WgQuickBackend))
                return;
            final String action = intent.getAction();
            if (action == null)
                return;
            final TunnelManager tunnelManager = Application.getTunnelManager();
            if (Intent.ACTION_BOOT_COMPLETED.equals(action)) {
                Log.i(TAG, "Broadcast receiver restoring state (boot)");
                tunnelManager.restoreState(false).whenComplete(ExceptionLoggers.D);
            } else if (Intent.ACTION_SHUTDOWN.equals(action)) {
                Log.i(TAG, "Broadcast receiver saving state (shutdown)");
                tunnelManager.saveState();
            }
        });
    }
}
