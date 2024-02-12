package com.redvpn.android.redVpnProfile;

import android.util.Base64;
import android.util.Log;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.JsonObjectRequest;

import com.redvpn.android.Application;
import com.redvpn.config.BadConfigException;
import com.redvpn.config.Config;
import com.redvpn.crypto.KeyPair;
import com.redvpn.util.NonNullForAll;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.util.HashMap;
import java.util.Map;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

@NonNullForAll
public class ConfigBuilder {
    private static final String TAG = "RedVPN/" + ConfigBuilder.class.getSimpleName();
    private static final String PROFILE_API_TAG = "RedVPNProfileApi";
    private static final String PROFILE_API_URL = "###";
    private static final String PROFILE_API_USERNAME = "###";
    private static final String PROFILE_API_PASSWORD = "###";

    public static void build(final KeyPair keyPair, final String region, ConfigBuilderCallback callback) {
        getProfileData(keyPair, region, new ProfileApiCallback() {
            @Override
            public void onSuccess(final String address, final String[] endpoints, final String serverPublicKey) {
                final String endpoint = endpoints[0];
                final String configText = createConfigText(keyPair.getPrivateKey().toBase64(), serverPublicKey, address, endpoint);

                callback.onSuccess(configText);
            }

            @Override
            public void onFail(final String errorMessage) {
                try {
                    JSONObject eventProperties = new JSONObject();
                    eventProperties.put("error", errorMessage);
                }
                catch (JSONException ex) {
                    Log.e(TAG, ex.getMessage());
                }

                callback.onFail();
            }
        });
    }

    public static Config parse(final KeyPair keyPair, final InputStream stream) throws IOException, JSONException, BadConfigException, InvalidKeyException {
        final StringBuilder builder = new StringBuilder();
        final BufferedReader reader = new BufferedReader(new InputStreamReader(stream));

        String line;
        while ((line = reader.readLine()) != null) {
            builder.append(line + System.lineSeparator());
        }

        final JSONObject json = new JSONObject(builder.toString());

        final String address = json.getString( "address");
        final String[] endpoints = getStringArray(json.getJSONArray( "endpoint"));
        final String clientPublicKey = json.getString("client_pubkey");
        final String serverPublicKey = json.getString( "pubkey");

        final String pubkey = keyPair.getPublicKey().toBase64();
        if(!clientPublicKey.equals(pubkey)) {
            throw new InvalidKeyException("Invalid public key!");
        }

        EndpointManager.storeEndpoints(endpoints, null);

        final String endpoint = endpoints[0];
        final String configText = createConfigText(keyPair.getPrivateKey().toBase64(), serverPublicKey, address, endpoint);
        final Config config = Config.parse(new ByteArrayInputStream(configText.getBytes(StandardCharsets.UTF_8)));

        return config;
    }

    private static void getProfileData(final KeyPair keyPair, final String region, ProfileApiCallback callback) {
        // Get the RequestQueue.
        RequestQueue queue = Application.getRequestQueue();
        queue.getCache().clear();

        // Call the API to get the endpoint and address...
        Map<String, String> params = new HashMap<>();
        params.put("pubkey", keyPair.getPublicKey().toBase64());
        if(region != null) {
            params.put("region", region);
        }
        JSONObject parameters = new JSONObject(params);
        JsonObjectRequest jsonObjectRequest = new JsonObjectRequest
            (Request.Method.POST, PROFILE_API_URL, parameters, response -> {
                Log.d(TAG, "Profile API Response: " + response);

                String status;
                String message = "";
                String address = "";
                String endpoint = "";
                String serverPublicKey = "";
                try {
                    status = response.getString("status");
                    message = response.getString( "message");
                    address = response.getString( "address");
                    endpoint = response.getString( "endpoint");
                    serverPublicKey = response.getString( "pubkey");
                }
                catch (JSONException e) {
                    Log.e(TAG, e.getMessage());
                    status = "fail";
                }

                if(status.equals("ok")) {
                    String[] endpoints = new String[] { endpoint };
                    EndpointManager.storeEndpoints(endpoints, region);
                    callback.onSuccess(address, endpoints, serverPublicKey);
                }
                else {
                    Log.d(TAG, message);
                    callback.onFail(message);
                }
            }, error -> {
                Log.e(TAG, error.getMessage(), error);
                final String message = error.getMessage() != null ? error.getMessage() : error.toString();
                callback.onFail(message);
            }) {
            @Override
            public Map<String, String> getHeaders() {
                HashMap<String, String> headers = new HashMap<>();
                String credentials = String.format("%s:%s", PROFILE_API_USERNAME, PROFILE_API_PASSWORD);
                String auth = "Basic " + Base64.encodeToString(credentials.getBytes(), Base64.DEFAULT);
                headers.put("Authorization", auth);
                
                return headers;
            }
        };
        // Add the request to the RequestQueue.
        jsonObjectRequest.setTag(PROFILE_API_TAG);
        jsonObjectRequest.setRetryPolicy(Application.getDefaultRetryPolicy());
        jsonObjectRequest.setShouldCache(false);
        queue.add(jsonObjectRequest);
    }

    private static String createConfigText(final String privateKey, final String publicKey, final String address, final String endpoint) {
        final StringBuilder builder = new StringBuilder();
        builder.append("[Interface]");
        builder.append("\nPrivateKey = " + privateKey);
        builder.append("\nAddress = " + address);
        builder.append("\nDNS = 8.8.8.8");
        builder.append("\n\n[Peer]");
        builder.append("\nPublicKey = " + publicKey);
        builder.append("\nAllowedIPs = 0.0.0.0/0");
        builder.append("\nEndpoint = " + endpoint);
        builder.append("\nPersistentKeepalive = 25");

        return builder.toString();
    }

    private static String[] getStringArray(JSONArray jsonArray) {
        String[] stringArray = null;
        if (jsonArray != null) {
            int length = jsonArray.length();
            stringArray = new String[length];
            for (int i = 0; i < length; i++) {
                stringArray[i] = jsonArray.optString(i);
            }
        }

        return stringArray;
    }
}
