package com.redvpn.android.redVpnProfile;

import com.redvpn.util.NonNullForAll;

@NonNullForAll
public interface ProfileApiCallback {
    void onSuccess(final String address, final String[] endpoints, final String serverPublicKey);
    void onFail(final String errorMessage);
}
