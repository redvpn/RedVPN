package com.redvpn.android.fragment;

import android.app.Activity;
import android.os.Bundle;
import android.text.Spanned;
import android.text.method.LinkMovementMethod;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.google.android.material.navigation.NavigationView;
import com.redvpn.android.R;
import com.redvpn.util.NonNullForAll;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.text.HtmlCompat;
import androidx.fragment.app.Fragment;

/**
 * A simple {@link Fragment} subclass.
 */
@NonNullForAll
public class AboutFragment extends Fragment {

    public AboutFragment() {
        // Required empty public constructor
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_about, container, false);

        Toolbar toolbar = rootView.findViewById(R.id.subpage_toolbar);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setTitle(getString(R.string.about_us_title));
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                int backStackEntries = getParentFragmentManager().getBackStackEntryCount();
                if (backStackEntries == 1) {
                    getParentFragmentManager().popBackStack();
                } else {
                    while (backStackEntries > 0) {
                        getParentFragmentManager().popBackStack();
                        backStackEntries--;
                    }
                }
                final Activity activity = getActivity();
                if(activity != null) {
                    NavigationView navigationView = activity.findViewById(R.id.nav_view);
                    if (navigationView != null) {
                        MenuItem checkedItem = navigationView.getCheckedItem();
                        if (checkedItem != null) {
                            checkedItem.setChecked(false);
                        }
                    }
                }
            }
        });

        return rootView;
    }
}
