package com.redvpn.android.redVpnProfile;

import android.content.SharedPreferences;

import com.redvpn.android.Application;
import com.redvpn.crypto.Key;
import com.redvpn.crypto.KeyFormatException;
import com.redvpn.crypto.KeyPair;
import com.redvpn.util.NonNullForAll;

@NonNullForAll
public class KeyStore {
    private Key privateKey;
    private Key publicKey;
    private KeyPair keyPair;
    private static final String PRIVATE_KEY = "private_key";
    private static final String PUBLIC_KEY = "public_key";

    public KeyStore() {
        // Get private key...
        final String privateKeyBase64 = Application.getSharedPreferences().getString(PRIVATE_KEY, null);
        if(privateKeyBase64 == null) {
            generatePrivateKey();
        }
        else {
            try {
                privateKey = Key.fromBase64(privateKeyBase64);
            }
            catch (KeyFormatException ex) {
                generatePrivateKey();
            }
        }

        // Get public key...
        final String publicKeyBase64 = Application.getSharedPreferences().getString(PUBLIC_KEY, null);
        if(publicKeyBase64 == null) {
            generatePublicKey();
        }
        else {
            try {
                publicKey = Key.fromBase64(publicKeyBase64);
            }
            catch (KeyFormatException ex) {
                generatePublicKey();
            }
        }

        keyPair = new KeyPair(privateKey, publicKey);
    }

    public KeyPair getKeyPair() {
        return keyPair;
    }

    private void generatePrivateKey() {
        privateKey = Key.generatePrivateKey();
        final String privateKeyBase64 = privateKey.toBase64();
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(PRIVATE_KEY, privateKeyBase64);
        editor.apply();
    }

    private void generatePublicKey() {
        publicKey = Key.generatePublicKey(privateKey);
        final String publicKeyBase64 = publicKey.toBase64();
        SharedPreferences sharedPreferences = Application.getSharedPreferences();
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(PUBLIC_KEY, publicKeyBase64);
        editor.apply();
    }
}
