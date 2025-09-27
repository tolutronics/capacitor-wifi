# @tolutronics/capacitor-wifi

A powerful Capacitor plugin for WiFi management with real-time monitoring capabilities. Perfect for IoT device connections, network provisioning, and WiFi state management in mobile applications.

## 🚀 Features

- **📶 WiFi Network Scanning** - Discover available networks with signal strength and security info
- **🔗 Smart Connection Management** - Connect by exact SSID or prefix matching (perfect for IoT devices)
- **⚡ Real-time Event Monitoring** - Get notified of connection/disconnection events instantly
- **🛡️ Permission Handling** - Seamless location and network permission management
- **📱 Cross-Platform** - Native iOS and Android implementations
- **🔌 IoT Device Support** - Specialized features for connecting to IoT devices with dynamic SSIDs

> **⚠️ Platform Support**: This plugin only works on native iOS and Android platforms. WiFi operations are not available in web browsers due to security restrictions.

## 📦 Quick Start

```bash
npm install @tolutronics/capacitor-wifi
npx cap sync
```

### Basic Usage

```typescript
import { Wifi } from '@tolutronics/capacitor-wifi';

// Scan for networks
const { wifis } = await Wifi.scanWifi();

// Connect to a network
await Wifi.connectToWifiBySsidAndPassword({
  ssid: 'MyNetwork',
  password: 'password123'
});

// Monitor connection changes
const listener = await Wifi.addListener('wifiConnectionChange', (event) => {
  console.log('WiFi state:', event.isConnected ? 'Connected' : 'Disconnected');
});
```

## 📋 Quick Reference

| Method | Description |
|--------|-------------|
| `scanWifi()` | Scan for available WiFi networks |
| `getCurrentWifi()` | Get current connected network info |
| `connectToWifiBySsidAndPassword()` | Connect to network by exact SSID |
| `connectToWifiBySsidPrefixAndPassword()` | Connect to network by SSID prefix (IoT devices) |
| `addListener('wifiConnectionChange', callback)` | Monitor WiFi connection changes |
| `checkPermissions()` / `requestPermissions()` | Handle WiFi and location permissions |
| `disconnectAndForget()` | Disconnect from current network |

## 💡 Common Use Cases

- **📱 Mobile App WiFi Management** - Let users connect to networks within your app
- **🏠 Smart Home Setup** - Connect users to IoT devices during setup flows
- **🏭 Industrial IoT** - Provision devices with dynamic or prefix-based SSIDs
- **📊 Network Monitoring** - Track WiFi connectivity for analytics or UX
- **🔄 Automatic Reconnection** - Handle network switching and failover scenarios

## 📖 Detailed Examples

### Basic Setup

```typescript
import { Wifi } from '@tolutronics/capacitor-wifi';
import { Capacitor } from '@capacitor/core';

// Platform check helper
const isNativePlatform = () => {
  return Capacitor.isNativePlatform();
};

// Check and request permissions first
const checkWifiPermissions = async () => {
  if (!isNativePlatform()) {
    console.warn('WiFi operations are only available on native platforms');
    return false;
  }

  const status = await Wifi.checkPermissions();

  if (status.LOCATION !== 'granted' || status.NETWORK !== 'granted') {
    const result = await Wifi.requestPermissions();
    return result.LOCATION === 'granted' && result.NETWORK === 'granted';
  }

  return true;
};
```

### Scanning for WiFi Networks

```typescript
const scanForNetworks = async () => {
  try {
    const hasPermissions = await checkWifiPermissions();
    if (!hasPermissions) {
      console.error('WiFi permissions not granted');
      return;
    }

    const result = await Wifi.scanWifi();
    console.log('Available networks:', result.wifis);

    // Display networks to user
    result.wifis.forEach(wifi => {
      console.log(`SSID: ${wifi.ssid}, Signal: ${wifi.level}, Current: ${wifi.isCurrentWifi}`);
    });
  } catch (error) {
    console.error('Failed to scan WiFi:', error);
  }
};
```

### Connecting to WiFi Networks

```typescript
// Connect to a specific network
const connectToWifi = async (ssid: string, password: string) => {
  try {
    const result = await Wifi.connectToWifiBySsidAndPassword({
      ssid,
      password
    });

    if (result.wasSuccess) {
      console.log('Connected successfully!', result.wifi);
    }
  } catch (error) {
    console.error('Failed to connect:', error);
  }
};

// Connect to IoT device by SSID prefix (useful for devices with dynamic names)
const connectToIoTDevice = async (devicePrefix: string, password: string) => {
  try {
    const result = await Wifi.connectToWifiBySsidPrefixAndPassword({
      ssidPrefix: devicePrefix, // e.g., "MyCamera_"
      password
    });

    if (result.wasSuccess) {
      console.log('Connected to IoT device!', result.wifi);
    }
  } catch (error) {
    console.error('Failed to connect to IoT device:', error);
  }
};
```

### Getting Current WiFi Information

```typescript
const getCurrentNetwork = async () => {
  try {
    const result = await Wifi.getCurrentWifi();

    if (result.currentWifi) {
      console.log('Current WiFi:', {
        ssid: result.currentWifi.ssid,
        bssid: result.currentWifi.bssid,
        signal: result.currentWifi.level
      });
    } else {
      console.log('Not connected to any WiFi network');
    }
  } catch (error) {
    console.error('Failed to get current WiFi:', error);
  }
};
```

### Complete IoT Setup Flow

```typescript
const setupIoTDevice = async (devicePrefix: string, devicePassword: string) => {
  try {
    // 1. Check permissions
    const hasPermissions = await checkWifiPermissions();
    if (!hasPermissions) {
      throw new Error('WiFi permissions required');
    }

    // 2. Get current WiFi (to restore later if needed)
    const currentWifi = await Wifi.getCurrentWifi();
    console.log('Current network:', currentWifi.currentWifi?.ssid);

    // 3. Scan for available networks
    const scanResult = await Wifi.scanWifi();
    const deviceNetworks = scanResult.wifis.filter(wifi =>
      wifi.ssid.startsWith(devicePrefix)
    );

    if (deviceNetworks.length === 0) {
      throw new Error(`No devices found with prefix: ${devicePrefix}`);
    }

    console.log(`Found ${deviceNetworks.length} device(s)`);

    // 4. Connect to device
    const connectResult = await Wifi.connectToWifiBySsidPrefixAndPassword({
      ssidPrefix: devicePrefix,
      password: devicePassword
    });

    if (!connectResult.wasSuccess) {
      throw new Error('Failed to connect to device');
    }

    console.log('Successfully connected to device:', connectResult.wifi?.ssid);

    // 5. Perform device configuration here
    // ... your device setup logic ...

    // 6. Optionally disconnect and return to original network
    // await Wifi.disconnectAndForget();

  } catch (error) {
    console.error('IoT setup failed:', error);
  }
};

// Usage
setupIoTDevice('MyCamera_', 'device123');
```

### WiFi Connection Event Monitoring

Monitor WiFi connection state changes in real-time to detect when the device connects, disconnects, or switches between networks.

```typescript
import { Wifi } from '@tolutronics/capacitor-wifi';
import { PluginListenerHandle } from '@capacitor/core';

let wifiListener: PluginListenerHandle;

const startWifiMonitoring = async () => {
  try {
    // Set up event listener for WiFi connection changes
    wifiListener = await Wifi.addListener('wifiConnectionChange', (event) => {
      console.log('WiFi connection state changed:', {
        isConnected: event.isConnected,
        timestamp: new Date(event.timestamp).toLocaleString(),
        wifi: event.wifi
      });

      if (event.isConnected && event.wifi) {
        console.log(`Connected to: ${event.wifi.ssid} (${event.wifi.bssid})`);
        console.log(`Signal strength: ${event.wifi.level} dBm`);
      } else {
        console.log('Disconnected from WiFi network');
      }

      // Handle the event in your app logic
      handleWifiStateChange(event);
    });

    console.log('WiFi monitoring started');
  } catch (error) {
    console.error('Failed to start WiFi monitoring:', error);
  }
};

const stopWifiMonitoring = async () => {
  if (wifiListener) {
    await wifiListener.remove();
    console.log('WiFi monitoring stopped');
  }
};

// Handle WiFi state changes in your app
const handleWifiStateChange = (event) => {
  if (event.isConnected) {
    // Device connected to WiFi
    onWifiConnected(event.wifi);
  } else {
    // Device disconnected from WiFi
    onWifiDisconnected();
  }
};

const onWifiConnected = (wifiInfo) => {
  // Update UI, sync data, etc.
  console.log('WiFi connected - enabling online features');
};

const onWifiDisconnected = () => {
  // Handle offline state, show offline banner, etc.
  console.log('WiFi disconnected - switching to offline mode');
};

// Start monitoring when app initializes
startWifiMonitoring();

// Remember to stop monitoring when the component/app is destroyed
// stopWifiMonitoring();
```

### React Hook with Event Monitoring

```typescript
import { useState, useEffect } from 'react';
import { Wifi, WifiConnectionStateChangeEvent } from '@tolutronics/capacitor-wifi';
import { PluginListenerHandle } from '@capacitor/core';

interface WifiState {
  isConnected: boolean;
  currentWifi: any | null;
  connectionHistory: WifiConnectionStateChangeEvent[];
}

export const useWifiMonitoring = () => {
  const [wifiState, setWifiState] = useState<WifiState>({
    isConnected: false,
    currentWifi: null,
    connectionHistory: []
  });

  useEffect(() => {
    let listener: PluginListenerHandle;

    const setupWifiMonitoring = async () => {
      try {
        // Get initial state
        const current = await Wifi.getCurrentWifi();
        setWifiState(prev => ({
          ...prev,
          isConnected: !!current.currentWifi,
          currentWifi: current.currentWifi
        }));

        // Set up event listener
        listener = await Wifi.addListener('wifiConnectionChange', (event) => {
          setWifiState(prev => ({
            isConnected: event.isConnected,
            currentWifi: event.wifi || null,
            connectionHistory: [event, ...prev.connectionHistory.slice(0, 9)] // Keep last 10 events
          }));
        });
      } catch (error) {
        console.error('Failed to setup WiFi monitoring:', error);
      }
    };

    setupWifiMonitoring();

    return () => {
      if (listener) {
        listener.remove();
      }
    };
  }, []);

  const refreshCurrentWifi = async () => {
    try {
      const result = await Wifi.getCurrentWifi();
      setWifiState(prev => ({
        ...prev,
        isConnected: !!result.currentWifi,
        currentWifi: result.currentWifi
      }));
    } catch (error) {
      console.error('Failed to refresh WiFi state:', error);
    }
  };

  return {
    ...wifiState,
    refreshCurrentWifi
  };
};

// Usage in component
const WiFiStatusComponent = () => {
  const { isConnected, currentWifi, connectionHistory } = useWifiMonitoring();

  return (
    <div>
      <h2>WiFi Status</h2>
      <p>Status: {isConnected ? 'Connected' : 'Disconnected'}</p>
      {currentWifi && (
        <div>
          <p>Network: {currentWifi.ssid}</p>
          <p>Signal: {currentWifi.level} dBm</p>
          <p>BSSID: {currentWifi.bssid}</p>
        </div>
      )}

      <h3>Connection History</h3>
      <ul>
        {connectionHistory.map((event, index) => (
          <li key={index}>
            {new Date(event.timestamp).toLocaleTimeString()}: {' '}
            {event.isConnected ? `Connected to ${event.wifi?.ssid}` : 'Disconnected'}
          </li>
        ))}
      </ul>
    </div>
  );
};
```

### IoT Device Monitoring Example

Monitor connection status when working with IoT devices to handle reconnection scenarios:

```typescript
const setupIoTDeviceWithMonitoring = async (devicePrefix: string, devicePassword: string) => {
  let isSetupComplete = false;

  // Set up monitoring before connecting
  const listener = await Wifi.addListener('wifiConnectionChange', (event) => {
    if (!event.isConnected) {
      console.log('Lost connection to device');
      if (!isSetupComplete) {
        console.log('Setup interrupted - may need to retry');
      }
    } else if (event.wifi?.ssid.startsWith(devicePrefix)) {
      console.log(`Connected to device: ${event.wifi.ssid}`);
    } else {
      console.log(`Connected to different network: ${event.wifi?.ssid}`);
    }
  });

  try {
    // Connect to device
    await Wifi.connectToWifiBySsidPrefixAndPassword({
      ssidPrefix: devicePrefix,
      password: devicePassword
    });

    // Perform device configuration
    await configureDevice();
    isSetupComplete = true;

    console.log('Device setup completed successfully');
  } catch (error) {
    console.error('Device setup failed:', error);
  } finally {
    // Clean up listener
    await listener.remove();
  }
};

const configureDevice = async () => {
  // Your device configuration logic here
  // This might include HTTP requests to the device's local IP
  return new Promise(resolve => setTimeout(resolve, 5000)); // Simulated delay
};
```

### React/Vue Component Example

```typescript
// React Hook Example
import { useState, useEffect } from 'react';
import { Wifi } from '@tolutronics/capacitor-wifi';

export const useWifi = () => {
  const [networks, setNetworks] = useState([]);
  const [currentWifi, setCurrentWifi] = useState(null);
  const [loading, setLoading] = useState(false);

  const scanNetworks = async () => {
    setLoading(true);
    try {
      const result = await Wifi.scanWifi();
      setNetworks(result.wifis);
    } catch (error) {
      console.error('Scan failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const connectToNetwork = async (ssid: string, password: string) => {
    setLoading(true);
    try {
      await Wifi.connectToWifiBySsidAndPassword({ ssid, password });
      // Refresh current WiFi info
      const current = await Wifi.getCurrentWifi();
      setCurrentWifi(current.currentWifi);
    } catch (error) {
      console.error('Connection failed:', error);
    } finally {
      setLoading(false);
    }
  };

  return {
    networks,
    currentWifi,
    loading,
    scanNetworks,
    connectToNetwork
  };
};
```

## API

<docgen-index>

* [`scanWifi()`](#scanwifi)
* [`getCurrentWifi()`](#getcurrentwifi)
* [`connectToWifiBySsidAndPassword(...)`](#connecttowifibyssidandpassword)
* [`connectToWifiBySsidPrefixAndPassword(...)`](#connecttowifibyssidprefixandpassword)
* [`checkPermissions()`](#checkpermissions)
* [`requestPermissions()`](#requestpermissions)
* [`disconnectAndForget()`](#disconnectandforget)
* [`addListener('wifiConnectionChange', ...)`](#addlistenerwificonnectionchange-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)
* [Enums](#enums)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### scanWifi()

```typescript
scanWifi() => Promise<ScanWifiResult>
```

**Returns:** <code>Promise&lt;<a href="#scanwifiresult">ScanWifiResult</a>&gt;</code>

--------------------


### getCurrentWifi()

```typescript
getCurrentWifi() => Promise<GetCurrentWifiResult>
```

**Returns:** <code>Promise&lt;<a href="#getcurrentwifiresult">GetCurrentWifiResult</a>&gt;</code>

--------------------


### connectToWifiBySsidAndPassword(...)

```typescript
connectToWifiBySsidAndPassword(connectToWifiRequest: ConnectToWifiRequest) => Promise<ConnectToWifiResult>
```

| Param                      | Type                                                                  |
| -------------------------- | --------------------------------------------------------------------- |
| **`connectToWifiRequest`** | <code><a href="#connecttowifirequest">ConnectToWifiRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#connecttowifiresult">ConnectToWifiResult</a>&gt;</code>

--------------------


### connectToWifiBySsidPrefixAndPassword(...)

```typescript
connectToWifiBySsidPrefixAndPassword(connectToWifiPrefixRequest: ConnectToWifiPrefixRequest) => Promise<ConnectToWifiResult>
```

| Param                            | Type                                                                              |
| -------------------------------- | --------------------------------------------------------------------------------- |
| **`connectToWifiPrefixRequest`** | <code><a href="#connecttowifiprefixrequest">ConnectToWifiPrefixRequest</a></code> |

**Returns:** <code>Promise&lt;<a href="#connecttowifiresult">ConnectToWifiResult</a>&gt;</code>

--------------------


### checkPermissions()

```typescript
checkPermissions() => Promise<PermissionStatus>
```

**Returns:** <code>Promise&lt;<a href="#permissionstatus">PermissionStatus</a>&gt;</code>

--------------------


### requestPermissions()

```typescript
requestPermissions() => Promise<PermissionStatus>
```

**Returns:** <code>Promise&lt;<a href="#permissionstatus">PermissionStatus</a>&gt;</code>

--------------------


### disconnectAndForget()

```typescript
disconnectAndForget() => Promise<void>
```

--------------------


### addListener('wifiConnectionChange', ...)

```typescript
addListener(eventName: 'wifiConnectionChange', listenerFunc: WifiConnectionListener) => Promise<PluginListenerHandle> & PluginListenerHandle
```

Listen for WiFi connection state changes

| Param              | Type                                                                      | Description                                |
| ------------------ | ------------------------------------------------------------------------- | ------------------------------------------ |
| **`eventName`**    | <code>'wifiConnectionChange'</code>                                       | The event name to listen for               |
| **`listenerFunc`** | <code><a href="#wificonnectionlistener">WifiConnectionListener</a></code> | The function to call when the event occurs |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt; & <a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

Remove all listeners for this plugin

--------------------


### Interfaces


#### ScanWifiResult

| Prop        | Type                     |
| ----------- | ------------------------ |
| **`wifis`** | <code>WifiEntry[]</code> |


#### WifiEntry

| Prop                | Type                          |
| ------------------- | ----------------------------- |
| **`bssid`**         | <code>string</code>           |
| **`capabilities`**  | <code>WifiCapability[]</code> |
| **`ssid`**          | <code>string</code>           |
| **`level`**         | <code>number</code>           |
| **`isCurrentWifi`** | <code>boolean</code>          |


#### GetCurrentWifiResult

| Prop              | Type                                            |
| ----------------- | ----------------------------------------------- |
| **`currentWifi`** | <code><a href="#wifientry">WifiEntry</a></code> |


#### ConnectToWifiResult

| Prop             | Type                                            |
| ---------------- | ----------------------------------------------- |
| **`wasSuccess`** | <code>true</code>                               |
| **`wifi`**       | <code><a href="#wifientry">WifiEntry</a></code> |


#### ConnectToWifiRequest

| Prop           | Type                |
| -------------- | ------------------- |
| **`ssid`**     | <code>string</code> |
| **`password`** | <code>string</code> |


#### ConnectToWifiPrefixRequest

| Prop             | Type                |
| ---------------- | ------------------- |
| **`ssidPrefix`** | <code>string</code> |
| **`password`**   | <code>string</code> |


#### PermissionStatus

| Prop           | Type                                                        |
| -------------- | ----------------------------------------------------------- |
| **`LOCATION`** | <code><a href="#permissionstate">PermissionState</a></code> |
| **`NETWORK`**  | <code><a href="#permissionstate">PermissionState</a></code> |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### WifiConnectionListener


### Type Aliases


#### PermissionState

<code>'prompt' | 'prompt-with-rationale' | 'granted' | 'denied'</code>


### Enums


#### WifiCapability

| Members                 | Value                            |
| ----------------------- | -------------------------------- |
| **`WPA2_PSK_CCM`**      | <code>'WPA2-PSK-CCM'</code>      |
| **`RSN_PSK_CCMP`**      | <code>'RSN-PSK-CCMP'</code>      |
| **`RSN_SAE_CCM`**       | <code>'RSN-SAE-CCM'</code>       |
| **`WPA2_EAP_SHA1_CCM`** | <code>'WPA2-EAP/SHA1-CCM'</code> |
| **`RSN_EAP_SHA1_CCMP`** | <code>'RSN-EAP/SHA1-CCMP'</code> |
| **`ESS`**               | <code>'ESS'</code>               |
| **`ES`**                | <code>'ES'</code>                |
| **`WP`**                | <code>'WP'</code>                |


#### SpecialSsid

| Members      | Value                        |
| ------------ | ---------------------------- |
| **`HIDDEN`** | <code>'[HIDDEN_SSID]'</code> |

</docgen-api>

## 🔧 Troubleshooting & Tips

### Common Issues

**❌ "METHOD_UNIMPLEMENTED" Error**
- This occurs when running in a web browser. The plugin only works on native iOS/Android platforms.
- **Solution**: Test on device/emulator using `npx cap run ios` or `npx cap run android`

**❌ Permission Denied Errors**
- Location permissions are required for WiFi scanning on both platforms.
- **Solution**: Always call `checkPermissions()` and `requestPermissions()` before other operations.

**❌ Connection Failures**
- Some devices may have restrictions on programmatic WiFi connections.
- **Solution**: Test on multiple devices and handle errors gracefully.

### Platform-Specific Notes

**📱 iOS**
- Uses `NetworkExtension` framework for connections
- `joinOnce` is set to `true` for temporary connections
- Location permission required for WiFi scanning
- Works on iOS 13.0+

**🤖 Android**
- Uses `WifiManager` and `ConnectivityManager` for operations
- Requires multiple network permissions (see installation notes)
- Network callback monitoring for real-time events
- Works on Android API 26+

### Performance Tips

- **Event Listeners**: Remember to remove listeners when components unmount to prevent memory leaks
- **Background Monitoring**: WiFi monitoring automatically starts/stops with plugin lifecycle
- **Batch Operations**: Wait for connection completion before performing additional network operations
- **Error Handling**: Always wrap WiFi operations in try-catch blocks

### IoT Device Best Practices

- Use `connectToWifiBySsidPrefixAndPassword()` for devices with dynamic SSIDs
- Monitor connection events to detect when setup is complete
- Implement timeout logic for device configuration steps
- Test with actual IoT devices, not just WiFi hotspots

### Development Workflow

1. **Test Permissions First**: Always verify permissions work correctly
2. **Use Real Devices**: WiFi operations don't work in simulators/emulators reliably
3. **Monitor Events**: Use event listeners during development to understand timing
4. **Handle Edge Cases**: Network switching, airplane mode, etc.

---

## 📄 License

MIT

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

If you encounter any issues or have questions, please [create an issue](https://github.com/tolutronics/capacitor-wifi/issues) on GitHub.
