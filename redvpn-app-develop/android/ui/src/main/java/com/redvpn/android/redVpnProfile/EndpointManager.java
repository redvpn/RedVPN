package com.redvpn.android.redVpnProfile;

import android.content.SharedPreferences;
import android.text.TextUtils;
import android.util.Log;

import com.redvpn.android.Application;
import com.redvpn.android.model.ObservableTunnel;
import com.redvpn.config.Config;
import com.redvpn.config.InetEndpoint;
import com.redvpn.config.ParseException;
import com.redvpn.config.Peer;
import com.redvpn.util.NonNullForAll;

import java.util.ArrayList;
import java.util.Collections;
import java.util.EmptyStackException;
import java.util.List;
import java.util.Stack;

import androidx.annotation.Nullable;

@NonNullForAll
public class EndpointManager {
    private static final String TAG = "RedVPN/" + EndpointManager.class.getSimpleName();
    static final String ENDPOINTS_KEY_PREFIX = "redvpn_endpoints";
    private static List<InetEndpoint> endpoints = new ArrayList<>();
    private final Stack<InetEndpoint> stack;

    public EndpointManager(final ObservableTunnel tunnel, final String region) {
        loadEndpoints(region);
        this.stack = new Stack<>();

        for (InetEndpoint endpoint: endpoints) {
            stack.push(endpoint);
        }
    }

    @Nullable
    public InetEndpoint getNextEndpoint() {
        try {
            return stack.pop();
        } catch (EmptyStackException ex) {
            return null;
        }
    }

    public static boolean changeConfigEndpoint(final Config config, final InetEndpoint endpoint) {
        List<Peer> peers = config.getPeers();
        if (peers.size() > 0) {
            Peer peer = peers.get(0);
            if(endpoint != null) {
                try {
                    peer.setEndpoint(endpoint);
                    return true;
                } catch (Exception ex) {
                    Log.e(TAG, ex.getMessage());
                }
            }
        }

        return false;
    }

    @Nullable
    public static InetEndpoint getEndpoint(final Config config) {
        if(config != null) {
            List<Peer> peers = config.getPeers();
            if (peers.size() > 0) {
                Peer peer = peers.get(0);
                InetEndpoint endpoint = peer.getEndpoint().orElse(null);
                return endpoint;
            }
        }

        return null;
    }

    private void loadEndpoints(final String region) {
        endpoints.clear();
        final String key = getSharedPreferenceKey(region);
        final String endpointsString = Application.getSharedPreferences().getString(key, null);
        if(endpointsString != null) {
            String[] endpointStrings = endpointsString.split(",");
            for(String endpointString: endpointStrings) {
                try {
                    InetEndpoint endpoint = InetEndpoint.parse(endpointString);
                    endpoints.add(endpoint);
                } catch (ParseException ex) {
                    Log.e(TAG, ex.getMessage());
                }
            }
        }
    }

    public static void storeEndpoints(final String[] endpoints, final String region) {
        final String key = getSharedPreferenceKey(region);
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(key, TextUtils.join(",", endpoints));
        editor.apply();
    }

    public static void removeEndpoints(final String region) {
        final String key = getSharedPreferenceKey(region);
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.remove(key);
        editor.apply();
    }

    private static String getSharedPreferenceKey(final String region) {
        String key = ENDPOINTS_KEY_PREFIX;
        if(region != null && region != "latency") {
            key = key + "_" + region;
        }

        return key;
    }
}
