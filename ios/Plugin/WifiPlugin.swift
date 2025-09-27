import Foundation
import Capacitor
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import NetworkExtension
import Network

struct WifiEntry {
    var bssid: String
    var ssid: String = "[HIDDEN_SSID]"
    var level: Int = -1
    var isCurrentWify: Bool = false
    var capabilities: [String] = []
}

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(WifiPlugin)
public class WifiPlugin: CAPPlugin, CLLocationManagerDelegate {

    var _currentCall: CAPPluginCall?
    var _locationManager: CLLocationManager = CLLocationManager()

    private let wifi = Wifi()
    private var pathMonitor: Network.NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "WiFiMonitor")
    private var isMonitoringStarted = false
    private var lastConnectionState: Bool = false
    private var lastWifiEntry: WifiEntry?

    override public func load() {
        super.load()
        startWifiMonitoring()
    }

    deinit {
        stopWifiMonitoring()
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var locationState = "granted"

        if _currentCall == nil {
            return
        }

        let call: CAPPluginCall = _currentCall! as CAPPluginCall
        _currentCall = nil

        if status != .authorizedAlways && status != .authorizedWhenInUse {
            locationState = "denied"
        } else if status == .restricted {
            locationState = "prompt"
        }

        call.resolve([
            "LOCATION": locationState,
            "NETWORK": "granted"
        ])
    }

    @objc override public func checkPermissions(_ call: CAPPluginCall) {

        var locationState = "granted"

        let locationStatus = CLLocationManager.authorizationStatus()
        if locationStatus != .authorizedAlways && locationStatus != .authorizedWhenInUse {
            locationState = "denied"
        } else if locationStatus == .restricted {
            locationState = "prompt"
        }

        call.resolve([
            "LOCATION": locationState,
            "NETWORK": "granted"
        ])
    }

    @objc override public func requestPermissions(_ call: CAPPluginCall) {

        let locationStatus = CLLocationManager.authorizationStatus()
        if locationStatus != .authorizedAlways && locationStatus != .authorizedWhenInUse {
            _currentCall = call
            _locationManager.delegate = self
            _locationManager.requestWhenInUseAuthorization()
            return
        }

        call.resolve([
            "LOCATION": "granted",
            "NETWORK": "granted"
        ])
    }

    @objc public func connectToWifiBySsidPrefixAndPassword(_ call: CAPPluginCall) {
        let ssidPrefix: String = call.getString("ssidPrefix", "")
        let _: String? = call.getString("password")

        print("CONNECTING", ssidPrefix)

        let hotspotConfig = NEHotspotConfiguration(
            ssidPrefix: ssidPrefix
        )

        hotspotConfig.joinOnce = true

        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { (error) in
            if let error = error {
                print("error = ", error)
                call.reject("MISSING_SSID_CONNECT_WIFI")
                return
            } else {
                print("Success!")
            }

            let currentWifi: WifiEntry? = self.getCurrentWifiInfo()

            call.resolve([
                "wasSuccess": true,
                "wifi": self.wifiEntryToWifiDict(wifiEntry: currentWifi) as Any
            ])
        }
    }

    @objc public func connectToWifiBySsidAndPassword(_ call: CAPPluginCall) {
        guard let ssid = call.getString("ssid"), !ssid.isEmpty else {
            call.reject("MISSING_SSID", "SSID is required")
            return
        }

        let password = call.getString("password", "")

        let hotspotConfig = NEHotspotConfiguration(
            ssid: ssid,
            passphrase: password,
            isWEP: false
        )

        // Don't use joinOnce for regular connections - allows saving the network
        hotspotConfig.joinOnce = false

        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { (error) in
            if let error = error {
                print("WiFi connection error: \(error)")
                let errorCode = (error as NSError).code
                let errorMessage = error.localizedDescription

                // Handle specific error cases
                switch errorCode {
                case 1: // NEHotspotConfigurationErrorInvalid
                    call.reject("INVALID_CONFIG", "Invalid WiFi configuration: \(errorMessage)")
                case 2: // NEHotspotConfigurationErrorInvalidSSID
                    call.reject("INVALID_SSID", "Invalid SSID: \(errorMessage)")
                case 3: // NEHotspotConfigurationErrorInvalidWPAPassphrase
                    call.reject("INVALID_PASSWORD", "Invalid password: \(errorMessage)")
                case 4: // NEHotspotConfigurationErrorInvalidWEPPassphrase
                    call.reject("INVALID_WEP_PASSWORD", "Invalid WEP password: \(errorMessage)")
                case 5: // NEHotspotConfigurationErrorInvalidEAPSettings
                    call.reject("INVALID_EAP", "Invalid EAP settings: \(errorMessage)")
                case 6: // NEHotspotConfigurationErrorInvalidHS20Settings
                    call.reject("INVALID_HS20", "Invalid Hotspot 2.0 settings: \(errorMessage)")
                case 7: // NEHotspotConfigurationErrorInvalidHS20DomainName
                    call.reject("INVALID_HS20_DOMAIN", "Invalid Hotspot 2.0 domain: \(errorMessage)")
                case 8: // NEHotspotConfigurationErrorUserDenied
                    call.reject("USER_DENIED", "User denied WiFi configuration: \(errorMessage)")
                case 9: // NEHotspotConfigurationErrorInternal
                    call.reject("INTERNAL_ERROR", "Internal iOS error - try restarting the app: \(errorMessage)")
                case 10: // NEHotspotConfigurationErrorPending
                    call.reject("PENDING", "Another WiFi operation is pending: \(errorMessage)")
                case 11: // NEHotspotConfigurationErrorSystemConfiguration
                    call.reject("SYSTEM_CONFIG_ERROR", "System configuration error: \(errorMessage)")
                case 12: // NEHotspotConfigurationErrorUnknown
                    call.reject("UNKNOWN_ERROR", "Unknown error: \(errorMessage)")
                case 13: // NEHotspotConfigurationErrorJoinOnceNotSupported
                    call.reject("JOIN_ONCE_NOT_SUPPORTED", "Join once not supported: \(errorMessage)")
                case 14: // NEHotspotConfigurationErrorAlreadyAssociated
                    call.reject("ALREADY_CONNECTED", "Already connected to this network: \(errorMessage)")
                case 15: // NEHotspotConfigurationErrorApplicationIsNotInForeground
                    call.reject("APP_NOT_FOREGROUND", "App must be in foreground for WiFi operations: \(errorMessage)")
                default:
                    call.reject("WIFI_CONNECTION_FAILED", "Failed to connect: \(errorMessage)")
                }
                return
            }

            print("WiFi connection initiated successfully")

            // Get current WiFi info after connection
            let currentWifi = self.getCurrentWifiInfo()

            call.resolve([
                "wasSuccess": true,
                "wifi": self.wifiEntryToWifiDict(wifiEntry: currentWifi) as Any
            ])
        }
    }

    @objc public func scanWifi(_ call: CAPPluginCall) {
        // Check location permission first
        let locationStatus = CLLocationManager.authorizationStatus()
        if locationStatus != .authorizedAlways && locationStatus != .authorizedWhenInUse {
            call.reject("LOCATION_PERMISSION_DENIED", "Location permission required for WiFi scanning on iOS")
            return
        }

        // iOS limitations: We can only get current connected WiFi
        // Full network scanning is not available due to iOS security restrictions
        if let _: NSArray = CNCopySupportedInterfaces() {
            let currentWifi: WifiEntry? = getCurrentWifiInfo()

            if let wifi = currentWifi {
                let wifiDictionary: [String: Any] = wifiEntryToWifiDict(wifiEntry: wifi)!
                call.resolve([
                    "wifis": [wifiDictionary]
                ] as PluginCallResultData)
            } else {
                // No current WiFi connection
                print("No current WiFi connection found - iOS can only detect connected network")
                call.resolve([
                    "wifis": [] as [[String: Any]]
                ])
            }
            return
        }

        // CNCopySupportedInterfaces failed
        print("CNCopySupportedInterfaces returned nil - no supported interfaces")
        call.resolve([
            "wifis": [] as [[String: Any]]
        ])
    }

    @objc public func getCurrentWifi(_ call: CAPPluginCall) {
        let wifiEntry: WifiEntry? = getCurrentWifiInfo()

        if wifiEntry == nil {
            call.resolve(["currentWifi": ""])
        } else {
            call.resolve([
                "currentWifi": wifiEntryToWifiDict(wifiEntry: wifiEntry) as Any
            ])
        }

    }

    func getCurrentWifiInfo() -> WifiEntry? {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    let wifiEntry: WifiEntry = WifiEntry(
                        bssid: interfaceInfo[kCNNetworkInfoKeyBSSID as String] as? String ?? "",
                        ssid: interfaceInfo[kCNNetworkInfoKeySSID as String] as? String ?? "[HIDDEN_SSID]",
                        isCurrentWify: true
                    )
                    return wifiEntry
                }
            }
        }
        return nil
    }

    func wifiEntryToWifiDict(wifiEntry: WifiEntry?) -> [String: Any]? {
        if wifiEntry == nil {
            return nil
        }

        return [
            "bssid": wifiEntry?.bssid ?? "",
            "ssid": wifiEntry?.ssid ?? "[HIDDEN_SSID]",
            "isCurrentWifi": wifiEntry?.isCurrentWify ?? false,
            "level": -1,
            "capabilities": [String]()
        ] as [String: Any]
    }

    @objc public func disconnectAndForget(_ call: CAPPluginCall) {
        call.resolve()
    }

    @objc public func disconnect(_ call: CAPPluginCall) {
        // On iOS, we cannot programmatically disconnect from WiFi networks without
        // removing the configuration entirely. This is a platform limitation.
        // The NEHotspotConfigurationManager doesn't provide a "disconnect only" option.
        // However, we can simulate this by removing and immediately re-adding the configuration
        // with a temporary setting that causes a disconnect.

        // For now, we'll resolve successfully but the behavior will be similar to disconnectAndForget
        // since iOS doesn't allow true "disconnect without forgetting" functionality.

        call.resolve()
    }

    // MARK: - WiFi Connection Monitoring

    private func startWifiMonitoring() {
        guard !isMonitoringStarted else { return }

        pathMonitor = Network.NWPathMonitor(requiredInterfaceType: Network.NWInterface.InterfaceType.wifi)
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkPathUpdate(path: path)
        }
        pathMonitor?.start(queue: monitorQueue)
        isMonitoringStarted = true

        // Initialize with current state
        let currentWifi = getCurrentWifiInfo()
        lastWifiEntry = currentWifi
        lastConnectionState = currentWifi != nil
    }

    private func stopWifiMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
        isMonitoringStarted = false
    }

    private func handleNetworkPathUpdate(path: Network.NWPath) {
        let isConnected = path.status == .satisfied && path.usesInterfaceType(Network.NWInterface.InterfaceType.wifi)
        let currentWifi = getCurrentWifiInfo()

        // Check if connection state changed or WiFi network changed
        let connectionStateChanged = isConnected != lastConnectionState
        let wifiNetworkChanged = !areWifiEntriesEqual(currentWifi, lastWifiEntry)

        if connectionStateChanged || wifiNetworkChanged {
            lastConnectionState = isConnected
            lastWifiEntry = currentWifi

            DispatchQueue.main.async { [weak self] in
                self?.notifyWifiConnectionChange(isConnected: isConnected, wifi: currentWifi)
            }
        }
    }

    private func areWifiEntriesEqual(_ first: WifiEntry?, _ second: WifiEntry?) -> Bool {
        guard let first = first, let second = second else {
            return first == nil && second == nil
        }
        return first.ssid == second.ssid && first.bssid == second.bssid
    }

    private func notifyWifiConnectionChange(isConnected: Bool, wifi: WifiEntry?) {
        var data: [String: Any] = [
            "isConnected": isConnected,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        if let wifiEntry = wifi {
            data["wifi"] = wifiEntryToWifiDict(wifiEntry: wifiEntry)
        }

        notifyListeners("wifiConnectionChange", data: data)
    }
}
