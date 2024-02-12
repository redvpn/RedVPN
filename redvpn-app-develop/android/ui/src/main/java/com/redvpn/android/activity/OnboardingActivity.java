package com.redvpn.android.activity;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.graphics.Insets;
import android.os.Build;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowMetrics;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;

import com.redvpn.android.adapter.SectionsPagerAdapter;
import com.redvpn.android.Application;
import com.redvpn.android.R;
import com.redvpn.util.NonNullForAll;

import androidx.appcompat.app.AppCompatActivity;
import androidx.viewpager.widget.ViewPager;

@NonNullForAll
public class OnboardingActivity extends AppCompatActivity {
    private ImageView zero, one, two;
    private ImageView[] indicators;
    public final static String ONBOARDING_COMPLETED = "is_onboarding_completed";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_onboarding);
        SectionsPagerAdapter sectionsPagerAdapter = new SectionsPagerAdapter(this, getSupportFragmentManager());
        ViewPager viewPager = findViewById(R.id.view_pager);
        viewPager.setAdapter(sectionsPagerAdapter);

        zero = findViewById(R.id.intro_indicator_0);
        one = findViewById(R.id.intro_indicator_1);
        two = findViewById(R.id.intro_indicator_2);
        indicators = new ImageView[]{zero, one, two};

        viewPager.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {

            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

            }

            @Override
            public void onPageSelected(int position) {
                updateIndicators(position);
            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });

        Button nextButton = findViewById(R.id.next_button);
        nextButton.setOnClickListener(v -> {
            int currentItem = viewPager.getCurrentItem();
            if(currentItem == indicators.length - 1) {
                // Save the onboarding completed shared preference...
                SharedPreferences sharedPreferences = Application.getSharedPreferences();
                Editor editor = sharedPreferences.edit();
                editor.putBoolean(ONBOARDING_COMPLETED, true);
                editor.apply();

                // Invoke the main activity and finish this one...
                Intent intent = new Intent(getApplicationContext(), MainActivity.class);
                startActivity(intent);
                finish();
            } else {
                viewPager.setCurrentItem(currentItem + 1, true);
            }
        });

        if(getScreenHeight() < 1200) {
            final LinearLayout indicatorsLayout = findViewById(R.id.indicators_layout);
            LinearLayout.LayoutParams indicatorsParams = (LinearLayout.LayoutParams)indicatorsLayout.getLayoutParams();
            indicatorsParams.bottomMargin = 0;
            indicatorsLayout.setLayoutParams(indicatorsParams);
            indicatorsLayout.requestLayout();

            final LinearLayout.LayoutParams nextButtonParams = (LinearLayout.LayoutParams)nextButton.getLayoutParams();
            nextButtonParams.topMargin = (int)getResources().getDimension(R.dimen.small_next_button_margin);
            nextButtonParams.bottomMargin = (int)getResources().getDimension(R.dimen.small_next_button_margin);
            nextButton.setLayoutParams(nextButtonParams);
            nextButton.requestLayout();
        }
    }

    void updateIndicators(int position) {
        for (int i = 0; i < indicators.length; i++) {
            indicators[i].setBackgroundResource(
                i == position ? R.drawable.indicator_selected : R.drawable.indicator_unselected
            );
        }
        int text = position == indicators.length - 1 ?  R.string.onboarding_complete : R.string.onboarding_next;
        Button nextButton = findViewById(R.id.next_button);
        nextButton.setText(getString(text));
    }

    private int getScreenHeight() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowMetrics windowMetrics = getWindowManager().getCurrentWindowMetrics();
            Insets insets = windowMetrics.getWindowInsets()
                    .getInsetsIgnoringVisibility(WindowInsets.Type.systemBars());
            return windowMetrics.getBounds().height() - insets.top - insets.bottom;
        } else {
            DisplayMetrics displayMetrics = new DisplayMetrics();
            getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
            return displayMetrics.heightPixels;
        }
    }
}