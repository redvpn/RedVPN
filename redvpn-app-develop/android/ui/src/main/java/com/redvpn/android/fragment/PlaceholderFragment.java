package com.redvpn.android.fragment;

import android.app.Activity;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.redvpn.android.R;
import com.redvpn.android.viewmodel.PageViewModel;
import com.redvpn.util.NonNullForAll;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProviders;

/**
 * A placeholder fragment containing a simple view.
 */
@NonNullForAll
public class PlaceholderFragment extends Fragment {

    private static final String ARG_SECTION_NUMBER = "section_number";

    private PageViewModel pageViewModel;

    public static PlaceholderFragment newInstance(int index) {
        PlaceholderFragment fragment = new PlaceholderFragment();
        Bundle bundle = new Bundle();
        bundle.putInt(ARG_SECTION_NUMBER, index);
        fragment.setArguments(bundle);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        pageViewModel = ViewModelProviders.of(this).get(PageViewModel.class);
        int index = 1;
        if (getArguments() != null) {
            index = getArguments().getInt(ARG_SECTION_NUMBER);
        }
        pageViewModel.setIndex(index);
    }

    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState) {
        View root = inflater.inflate(R.layout.fragment_onboarding, container, false);
        final TextView textView = root.findViewById(R.id.section_label);
        pageViewModel.getText().observe(this, resId -> {
            if(resId != null) {
                String text = getString(resId);
                textView.setText(text);
            }
        });

        final ImageView imageView = root.findViewById(R.id.section_image);
        pageViewModel.getImage().observe(this, resId -> {
            if(resId != null) {
                imageView.setImageResource(resId);
            }
        });

        if(getScreenHeight() < 1200) {
            LinearLayout.LayoutParams params = (LinearLayout.LayoutParams)imageView.getLayoutParams();
            params.topMargin = (int)getResources().getDimension(R.dimen.small_section_image_top_margin);
            params.bottomMargin = (int)getResources().getDimension(R.dimen.small_section_image_bottom_margin);
            imageView.setLayoutParams(params);
            imageView.requestLayout();
        }

        return root;
    }

    private int getScreenHeight() {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        ((Activity) requireContext()).getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);

        return displayMetrics.heightPixels;
    }

}