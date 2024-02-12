package com.redvpn.android.redVpnProfile;

import com.redvpn.util.NonNullForAll;

@NonNullForAll
public interface ApiDataCallback {
    void onSuccess();
    void onFail(final String errorMessage);
}
