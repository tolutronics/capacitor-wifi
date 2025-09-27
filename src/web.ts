import { WebPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';

import type {
  ConnectToWifiResult,
  GetCurrentWifiResult,
  ScanWifiResult,
  WifiPlugin,
  PermissionStatus,
  WifiConnectionListener,
} from './definitions';

export class WifiWeb extends WebPlugin implements WifiPlugin {
  async scanWifi(): Promise<ScanWifiResult> {
    console.warn(
      'WiFi scanning is not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    throw this.unavailable(
      'WiFi operations are not available in web browsers. Please run on iOS or Android.',
    );
  }

  async getCurrentWifi(): Promise<GetCurrentWifiResult> {
    console.warn(
      'WiFi access is not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    throw this.unavailable(
      'WiFi operations are not available in web browsers. Please run on iOS or Android.',
    );
  }

  async connectToWifiBySsidAndPassword(): Promise<ConnectToWifiResult> {
    console.warn(
      'WiFi connection is not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    throw this.unavailable(
      'WiFi operations are not available in web browsers. Please run on iOS or Android.',
    );
  }

  async connectToWifiBySsidPrefixAndPassword(): Promise<ConnectToWifiResult> {
    console.warn(
      'WiFi connection is not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    throw this.unavailable(
      'WiFi operations are not available in web browsers. Please run on iOS or Android.',
    );
  }

  async requestPermissions(): Promise<PermissionStatus> {
    console.warn(
      'WiFi permissions are not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    throw this.unavailable(
      'WiFi operations are not available in web browsers. Please run on iOS or Android.',
    );
  }

  async checkPermissions(): Promise<PermissionStatus> {
    console.warn(
      'WiFi permissions are not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    throw this.unavailable(
      'WiFi operations are not available in web browsers. Please run on iOS or Android.',
    );
  }

  async disconnect(): Promise<void> {
    console.warn(
      'WiFi operations are not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    throw this.unavailable(
      'WiFi operations are not available in web browsers. Please run on iOS or Android.',
    );
  }

  async disconnectAndForget(): Promise<void> {
    console.warn(
      'WiFi operations are not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    throw this.unavailable(
      'WiFi operations are not available in web browsers. Please run on iOS or Android.',
    );
  }

  addListener(
    eventName: 'wifiConnectionChange',
    listenerFunc: WifiConnectionListener,
  ): Promise<PluginListenerHandle> & PluginListenerHandle {
    console.warn(
      'WiFi event listeners are not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    return super.addListener(
      eventName,
      listenerFunc,
    ) as Promise<PluginListenerHandle> & PluginListenerHandle;
  }

  async removeAllListeners(): Promise<void> {
    console.warn(
      'WiFi event listeners are not supported in web browsers. This plugin only works on native iOS/Android platforms.',
    );
    return super.removeAllListeners();
  }
}
