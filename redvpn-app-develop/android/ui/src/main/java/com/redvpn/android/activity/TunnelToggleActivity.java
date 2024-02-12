/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android.activity;

import android.content.ComponentName;
import android.os.Bundle;
import android.os.Build;
import android.service.quicksettings.TileService;
import android.util.Log;
import android.widget.Toast;

import com.redvpn.android.Application;
import com.redvpn.android.QuickTileService;
import com.redvpn.android.R;
import com.redvpn.android.backend.Tunnel.State;
import com.redvpn.android.model.ObservableTunnel;
import com.redvpn.android.util.ErrorMessages;
import com.redvpn.util.NonNullForAll;

import androidx.appcompat.app.AppCompatActivity;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

@RequiresApi(Build.VERSION_CODES.N)
@NonNullForAll
public class TunnelToggleActivity extends AppCompatActivity {
    private static final String TAG = "WireGuard/" + TunnelToggleActivity.class.getSimpleName();

    @Override
    protected void onCreate(@Nullable final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        final ObservableTunnel tunnel = Application.getTunnelManager().getLastUsedTunnel();
        if (tunnel == null)
            return;
        tunnel.setState(State.TOGGLE).whenComplete((v, t) -> {
            TileService.requestListeningState(this, new ComponentName(this, QuickTileService.class));
            onToggleFinished(t);
            finishAffinity();
        });
    }

    private void onToggleFinished(@Nullable final Throwable throwable) {
        if (throwable == null)
            return;
        final String error = ErrorMessages.get(throwable);
        final String message = getString(R.string.toggle_error, error);
        Log.e(TAG, message, throwable);
        Toast.makeText(this, message, Toast.LENGTH_LONG).show();
    }
}
