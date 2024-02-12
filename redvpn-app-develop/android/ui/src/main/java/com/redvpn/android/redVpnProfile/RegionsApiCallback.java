package com.redvpn.android.redVpnProfile;

import com.redvpn.util.NonNullForAll;

import java.util.ArrayList;

@NonNullForAll
public interface RegionsApiCallback {
    void onComplete(final ArrayList<String> regions);
}
