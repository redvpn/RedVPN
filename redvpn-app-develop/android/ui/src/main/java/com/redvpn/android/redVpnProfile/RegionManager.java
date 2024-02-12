package com.redvpn.android.redVpnProfile;

import android.content.SharedPreferences;
import android.util.Log;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.JsonObjectRequest;

import com.redvpn.android.Application;
import com.redvpn.util.NonNullForAll;

import java.net.InetAddress;
import java.net.URL;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;

import org.json.JSONArray;
import org.json.JSONException;

@NonNullForAll
public class RegionManager {
    private static final String TAG = "RedVPN/" + RegionManager.class.getSimpleName();
    private static final String REGIONS_API_URL = "https://d2gs9rprpayrzi.cloudfront.net/api/2/regions/";
    private static final String REGIONS_API_TAG = "RedVPNRegionsApi";
    private static final String SELECTED_REGION_KEY = "redvpn_selected_region";
    private static final String LATENCY = "latency";
    private ArrayList<String> regions;
    private String selectedRegion;

    public RegionManager() {
        regions = new ArrayList<>(Arrays.asList(new String[]{LATENCY}));
    }

    public String getSelectedRegion() {
        if(selectedRegion != null) {
            return selectedRegion;
        }

        selectedRegion = Application.getSharedPreferences().getString(SELECTED_REGION_KEY, LATENCY);
        // if selected region doesn't exist default back to latency...
        if(selectedRegion != LATENCY && !regions.contains(selectedRegion)) {
            setSelectedRegion(LATENCY);
        }

        return selectedRegion;
    }

    public void setSelectedRegion(final String region) {
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(SELECTED_REGION_KEY, region);
        editor.apply();

        selectedRegion = region;
        Log.d(TAG, "Region selected: " + region);
    }

    public void loadRegions(RegionsApiCallback callback) {
        if(regions.size() > 1) {
            callback.onComplete(regions);
        }

        // This is a hack for the UnknownHostException issue
        // https://stackoverflow.com/questions/3293659/android-java-net-unknownhostexception-host-is-unresolved-strategy-question
        Application.getAsyncWorker().runAsync(() -> {
            try {
                URL url = new URL(REGIONS_API_URL);
                InetAddress inetAddress = InetAddress.getByName(url.getHost());
            } catch (UnknownHostException e) {
                Log.e(TAG, e.getMessage());
            }
        });

        // Get the RequestQueue.
        RequestQueue queue = Application.getRequestQueue();
        queue.getCache().clear();

        // Call the API to get the endpoint and address...
        JsonObjectRequest jsonObjectRequest = new JsonObjectRequest
                (Request.Method.POST, REGIONS_API_URL, null, response -> {
                    Log.d(TAG, "API Response: " + response);

                    try {
                        String status = response.getString("status");
                        if(status.equals("ok")) {
                            addRegions(response.getJSONArray( "regions"));
                        }
                    }
                    catch (JSONException e) {
                        Log.e(TAG, e.getMessage());
                    }
                    callback.onComplete(regions);
                }, error -> {
                    Log.e(TAG, error.getMessage(), error);
                    callback.onComplete(regions);
                });

        // Add the request to the RequestQueue.
        jsonObjectRequest.setTag(REGIONS_API_TAG);
        jsonObjectRequest.setRetryPolicy(Application.getDefaultRetryPolicy());
        jsonObjectRequest.setShouldCache(false);
        queue.add(jsonObjectRequest);
    }

    private void addRegions(JSONArray jsonArray) {
        if (jsonArray != null) {
            int length = jsonArray.length();
            for (int i = 0; i < length; i++) {
                String region = jsonArray.optString(i);
                if (!regions.contains(region)) {
                    regions.add(region);
                }
            }
        }
    }
}
