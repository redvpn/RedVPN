package com.redvpn.android.activity;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import androidx.core.splashscreen.SplashScreen;

import com.redvpn.android.Application;
import com.redvpn.util.NonNullForAll;

@NonNullForAll
public class SplashActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstance) {
        super.onCreate(savedInstance);
        SplashScreen splashScreen = SplashScreen.installSplashScreen(this);
        splashScreen.setKeepOnScreenCondition(() -> true);

        final Boolean isOnboardingCompleted = Application.getSharedPreferences().getBoolean(OnboardingActivity.ONBOARDING_COMPLETED, false);
        if(isOnboardingCompleted) {
            // Invoke the main activity
            Intent intent = new Intent(getApplicationContext(), MainActivity.class);
            startActivity(intent);
        }
        else {
            // Invoke the onboarding activity
            Intent onboardingIntent = new Intent(getApplicationContext(), OnboardingActivity.class);
            startActivity(onboardingIntent);
        }

        // Finish the splash activity...
        finish();
    }
}