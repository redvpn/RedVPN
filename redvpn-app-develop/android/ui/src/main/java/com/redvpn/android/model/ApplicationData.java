/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android.model;

import android.graphics.drawable.Drawable;

import com.redvpn.android.BR;
import com.redvpn.util.Keyed;
import com.redvpn.util.NonNullForAll;

import androidx.databinding.BaseObservable;
import androidx.databinding.Bindable;

@NonNullForAll
public class ApplicationData extends BaseObservable implements Keyed<String> {
    private final Drawable icon;
    private final String name;
    private final String packageName;
    private boolean excludedFromTunnel;

    public ApplicationData(final Drawable icon, final String name, final String packageName, final boolean excludedFromTunnel) {
        this.icon = icon;
        this.name = name;
        this.packageName = packageName;
        this.excludedFromTunnel = excludedFromTunnel;
    }

    public Drawable getIcon() {
        return icon;
    }

    @Override
    public String getKey() {
        return name;
    }

    public String getName() {
        return name;
    }

    public String getPackageName() {
        return packageName;
    }

    @Bindable
    public boolean isExcludedFromTunnel() {
        return excludedFromTunnel;
    }

    public void setExcludedFromTunnel(final boolean excludedFromTunnel) {
        this.excludedFromTunnel = excludedFromTunnel;
        notifyPropertyChanged(BR.excludedFromTunnel);
    }
}
