/*
 * Copyright © 2017-2019 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package com.redvpn.android.util;

import com.redvpn.util.Keyed;
import com.redvpn.util.NonNullForAll;
import com.redvpn.util.SortedKeyedList;

/**
 * A list that is both sorted/keyed and observable.
 */

@NonNullForAll
public interface ObservableSortedKeyedList<K, E extends Keyed<? extends K>>
        extends ObservableKeyedList<K, E>, SortedKeyedList<K, E> {
}
