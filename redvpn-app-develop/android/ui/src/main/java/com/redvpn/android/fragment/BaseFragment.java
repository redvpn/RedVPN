/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android.fragment;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.util.Log;
import android.view.View;

import com.redvpn.android.Application;
import com.redvpn.android.R;
import com.redvpn.android.activity.BaseActivity;
import com.redvpn.android.activity.BaseActivity.OnSelectedTunnelChangedListener;
import com.redvpn.android.backend.GoBackend;
import com.redvpn.android.backend.Tunnel.RedVpnState;
import com.redvpn.android.backend.Tunnel.State;
import com.redvpn.android.databinding.TunnelListItemBinding;
import com.redvpn.android.model.ObservableTunnel;
import com.redvpn.android.redVpnProfile.ConfigBuilder;
import com.redvpn.android.redVpnProfile.ConfigBuilderCallback;
import com.redvpn.android.redVpnProfile.EndpointManager;
import com.redvpn.android.util.ErrorMessages;
import com.redvpn.android.util.NetworkUtils;
import com.redvpn.android.util.StyleableToastUtils;
import com.redvpn.config.BadConfigException;
import com.redvpn.config.Config;
import com.redvpn.crypto.KeyPair;
import com.redvpn.util.NonNullForAll;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import androidx.annotation.Nullable;
import androidx.databinding.DataBindingUtil;
import androidx.databinding.ViewDataBinding;
import androidx.fragment.app.Fragment;

import io.github.muddz.styleabletoast.StyleableToast;

/**
 * Base class for fragments that need to know the currently-selected tunnel. Only does anything when
 * attached to a {@code BaseActivity}.
 */

@NonNullForAll
public abstract class BaseFragment extends Fragment implements OnSelectedTunnelChangedListener {
    private static final int REQUEST_CODE_VPN_PERMISSION = 23491;
    private static final String TAG = "RedVPN/" + BaseFragment.class.getSimpleName();
    protected Handler animationHandler = new Handler();
    protected Runnable animationRunnable;

    @Nullable private BaseActivity activity;
    @Nullable private ObservableTunnel pendingTunnel;
    @Nullable private Boolean pendingTunnelUp;
    protected EndpointManager endpointManager;

    @Override
    public void onActivityResult(final int requestCode, final int resultCode, @Nullable final Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == REQUEST_CODE_VPN_PERMISSION) {
            if (pendingTunnel != null && pendingTunnelUp != null)
                setTunnelStateWithPermissionsResult(pendingTunnel, pendingTunnelUp);
            pendingTunnel = null;
            pendingTunnelUp = null;
        }
    }

    @Override
    public void onAttach(final Context context) {
        super.onAttach(context);
        if (context instanceof BaseActivity) {
            activity = (BaseActivity) context;
            activity.addOnSelectedTunnelChangedListener(this);
        } else {
            activity = null;
        }
    }

    @Override
    public void onDetach() {
        if (activity != null)
            activity.removeOnSelectedTunnelChangedListener(this);
        activity = null;
        super.onDetach();
    }

    protected void getNewEndpoints(final ObservableTunnel tunnel, final String region, final boolean checked) {
        final Activity activity = getActivity();
        if (tunnel == null || activity == null)
            return;

        final KeyPair keyPair = Application.getKeyStore().getKeyPair();

        ConfigBuilder.build(keyPair, region, new ConfigBuilderCallback() {
            @Override
            public void onSuccess(String configText) {
                try {
                    final Config newConfig = Config.parse(new ByteArrayInputStream(configText.getBytes(StandardCharsets.UTF_8)));

                    tunnel.setConfig(newConfig).whenComplete((savedTunnel, throwable) -> {
                        final String message;
                        if (throwable == null) {
                            message = getString(R.string.config_save_success, Application.TUNNEL_NAME);
                            Log.d(TAG, message);

                            if(checked) {
                                // Turn VPN on
                                setTunnelState(activity, tunnel, true);
                            }
                        } else {
                            final String error = ErrorMessages.get(throwable);
                            message = getString(R.string.config_save_error, Application.TUNNEL_NAME, error);
                            Log.e(TAG, message, throwable);

                            StyleableToast.makeText(activity, getString(R.string.vpn_connection_try_again), StyleableToastUtils.LENGTH_LONG, R.style.ToastError).show();
                        }
                    });
                } catch (final BadConfigException | IOException e) {
                    Log.e(TAG, e.getMessage());

                    StyleableToast.makeText(activity, getString(R.string.vpn_connection_try_again), StyleableToastUtils.LENGTH_LONG, R.style.ToastError).show();
                }
            }

            @Override
            public void onFail() {
                stopPulse();
                StyleableToast.makeText(activity, getString(R.string.vpn_connection_try_again), StyleableToastUtils.LENGTH_LONG, R.style.ToastError).show();
            }
        });
    }

    public void setTunnelState(View view) {
        final ViewDataBinding binding = DataBindingUtil.findBinding(view);
        final ObservableTunnel tunnel = ((TunnelListItemBinding) binding).getItem();
        if (tunnel == null)
            return;

        final int status = NetworkUtils.getConnectivityStatus(requireContext());
        final boolean checked = tunnel.getState() == State.DOWN;
        final boolean hasInternetConnection = status != NetworkUtils.NETWORK_STATUS_NOT_CONNECTED;

        // Only if there's internet connectivity...
        if(hasInternetConnection) {
            if(checked) {
                startPulse();
                // If there are no stored endpoints get new ones, otherwise turn VPN on...
                final String selectedRegion = Application.getRegionManager().getSelectedRegion();
                this.endpointManager = new EndpointManager(tunnel, selectedRegion);
                if(this.endpointManager.getNextEndpoint() == null) {
                    getNewEndpoints(tunnel, selectedRegion, true);
                } else {
                    setTunnelState(view.getContext(), tunnel, true);
                }
            } else {
                // Turn VPN off
                setTunnelState(view.getContext(), tunnel, false);
            }
        } else {
            tunnel.setRedVpnState(RedVpnState.OFF);
            StyleableToast.makeText(activity, getString(R.string.no_internet_connection), StyleableToastUtils.LENGTH_LONG, R.style.ToastError).show();
            stopPulse();
        }
    }

    protected void setTunnelState(final Context context, final ObservableTunnel tunnel, final boolean checked) {
        Application.getBackendAsync().thenAccept(backend -> {
            if (backend instanceof GoBackend) {
                final Intent intent = GoBackend.VpnService.prepare(context);
                if (intent != null) {
                    pendingTunnel = tunnel;
                    pendingTunnelUp = checked;
                    startActivityForResult(intent, REQUEST_CODE_VPN_PERMISSION);
                    return;
                }
            }

            setTunnelStateWithPermissionsResult(tunnel, checked);
        });
    }

    private void setTunnelStateWithPermissionsResult(final ObservableTunnel tunnel, final boolean checked) {
        tunnel.setState(State.of(checked)).whenComplete((state, throwable) -> {
            if (throwable == null) {
                return;
            }

            tunnel.setRedVpnState(RedVpnState.OFF);
            tunnel.setStateChanging(false);
            stopPulse();

            final String error = ErrorMessages.get(throwable);
            Log.e(TAG, error, throwable);
        });
    }

    protected void startPulse() {
        animationRunnable.run();
    }

    protected void stopPulse() {
        animationHandler.removeCallbacks(animationRunnable);
    }
}
