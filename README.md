# @tolutronics/capacitor-wifi

Connect to Wifi through your capacitor plugin. Good for IoT device connections.

## Install

```bash
npm install @tolutronics/capacitor-wifi
npx cap sync
```

## Example Implementation

### Basic Setup

```typescript
import { Wifi } from '@tolutronics/capacitor-wifi';

// Check and request permissions first
const checkWifiPermissions = async () => {
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
