package com.redvpn.android.viewmodel;

import com.redvpn.android.R;
import com.redvpn.util.NonNullForAll;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.Transformations;
import androidx.lifecycle.ViewModel;

@NonNullForAll
public class PageViewModel extends ViewModel {

    private MutableLiveData<Integer> mIndex = new MutableLiveData<>();
    private LiveData<Integer> mText = Transformations.map(mIndex, input -> {
        switch(input) {
            case 1:
                return R.string.onboarding_encryption;
            case 2:
                return R.string.onboarding_fast_servers;
            case 3:
                return R.string.onboarding_no_logs;
            default:
                return null;
        }
    });
    private LiveData<Integer> mImage = Transformations.map(mIndex, input -> {
       switch (input) {
           case 1:
               return R.drawable.illustration_encryption;
           case 2:
               return R.drawable.illustration_fast_servers;
           case 3:
               return R.drawable.illustration_no_logs;
           default:
               return null;
       }
    });

    public void setIndex(int index) {
        mIndex.setValue(index);
    }

    public LiveData<Integer> getText() {
        return mText;
    }

    public LiveData<Integer> getImage() {
        return mImage;
    }
}