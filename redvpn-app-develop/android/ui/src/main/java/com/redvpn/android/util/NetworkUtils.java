package com.redvpn.android.util;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.os.Build;
import android.util.Log;

import com.redvpn.util.NonNullForAll;

import java.net.NetworkInterface;
import java.util.Collections;

@NonNullForAll
public class NetworkUtils {
    private static final String TAG = "RedVPN/" + NetworkUtils.class.getSimpleName();

    public static final int NETWORK_STATUS_NOT_CONNECTED = 0;
    public static final int NETWORK_STATUS_WIFI = 1;
    public static final int NETWORK_STATUS_MOBILE = 2;
    public static final int NETWORK_STATUS_VPN = 3;

    @SuppressWarnings("deprecation")
    public static int getConnectivityStatus(Context context) {
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

        if(connectivityManager != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Network activeNetwork = connectivityManager.getActiveNetwork();
                if(activeNetwork != null) {
                    NetworkCapabilities networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork);
                    if (networkCapabilities != null) {
                        if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
                        ) {
                            return NETWORK_STATUS_VPN;
                        } else if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                            return NETWORK_STATUS_WIFI;
                        } else if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                            return NETWORK_STATUS_MOBILE;
                        }
                    }
                }
            } else {
                android.net.NetworkInfo activeNetwork = connectivityManager.getActiveNetworkInfo();
                if (activeNetwork != null && activeNetwork.isConnected()) {
                    try {
                        for (NetworkInterface networkInterface : Collections.list(NetworkInterface.getNetworkInterfaces())) {

                            if (networkInterface.isUp() && networkInterface.getName().contains("tun0"))
                                return NETWORK_STATUS_VPN;
                        }
                    } catch (Exception ex) {
                        Log.e(TAG, "VPN Network status cannot be retrieved.", ex);
                    }

                    if (activeNetwork.getType() == ConnectivityManager.TYPE_WIFI)
                        return NETWORK_STATUS_WIFI;

                    if (activeNetwork.getType() == ConnectivityManager.TYPE_MOBILE)
                        return NETWORK_STATUS_MOBILE;
                }
            }
        }

        return NETWORK_STATUS_NOT_CONNECTED;
    }
}

