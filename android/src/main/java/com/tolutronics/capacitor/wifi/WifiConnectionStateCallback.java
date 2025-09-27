package com.tolutronics.capacitor.wifi;

import androidx.annotation.Nullable;

public abstract class WifiConnectionStateCallback {

    public abstract void onConnectionStateChanged(boolean isConnected, @Nullable WifiEntry wifiEntry);
}
