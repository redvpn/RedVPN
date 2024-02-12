/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android.util;

import com.redvpn.util.Keyed;
import com.redvpn.util.KeyedList;
import com.redvpn.util.NonNullForAll;

import androidx.databinding.ObservableList;

/**
 * A list that is both keyed and observable.
 */

@NonNullForAll
public interface ObservableKeyedList<K, E extends Keyed<? extends K>>
        extends KeyedList<K, E>, ObservableList<E> {
}
