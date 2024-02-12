package com.redvpn.android.redVpnProfile;

import com.redvpn.util.NonNullForAll;

@NonNullForAll
public interface ConfigBuilderCallback {
    void onSuccess(final String configText);
    void onFail();
}
