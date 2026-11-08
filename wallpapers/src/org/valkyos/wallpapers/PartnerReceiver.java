/*
 * SPDX-FileCopyrightText: 2026 The ValkyOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.valkyos.wallpapers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Marker receiver: only its intent filter is used, nothing is done here. */
public class PartnerReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
    }
}
