# Kotlin Integration – ESP-IDF Provisioning Manager

This guide shows how to provision the ESP32-S3 with a native Android/Kotlin app using Espressif's provisioning libraries. The firmware in this repo exposes the standard ESP-IDF provisioning service (BLE transport + Security 1).

## 1. Dependencies

```gradle
implementation "com.espressif.provisioning:espressif_prov:3.0.0"
implementation "com.google.code.gson:gson:2.10.1"
```

Add Bluetooth + location permissions to `AndroidManifest.xml` (Android 12+ also needs `android.permission.BLUETOOTH_CONNECT` and `android.permission.BLUETOOTH_SCAN`). Prompt for runtime permissions before scanning.

## 2. Provisioning Parameters

| Item | Value |
|------|-------|
| BLE device name | `kc-<last-3-bytes-of-mac>` (e.g., `kc-12ABCD`) |
| Transport | BLE |
| Security | 1 (X25519 + Proof-of-Possession) |
| Proof-of-Possession | `sumppop` |
| Wi-Fi pop fields | Standard ESP-IDF fields (`ssid`, `passphrase`) |

## 3. Sample Flow

```kotlin
class ProvisionViewModel : ViewModel() {
    private val provisionManager = ESPProvisionManager.getInstance(App.instance)

    fun startScan(onDevices: (List<ESPDevice>) -> Unit, onError: (Throwable) -> Unit) {
        provisionManager.searchBleEspDevices(
            securityType = ESPConstants.SecurityType.SECURITY_1,
            transportType = ESPConstants.TransportType.TRANSPORT_BLE,
            deviceNamePrefix = "kc-",
            callback = object : ESPDeviceSearchListener {
                override fun onDeviceFound(device: ESPDevice) { onDevices(listOf(device)) }
                override fun onFailure(e: Exception?) { onError(e ?: Exception("Scan failed")) }
                override fun scanCompleted() { }
            }
        )
    }

    fun provision(device: ESPDevice, ssid: String, password: String,
                  onSuccess: () -> Unit, onError: (Throwable) -> Unit) {
        device.provision(ssid, password, "sumppop",
            object : ProvisionListener {
                override fun createSessionFailed(e: Exception?) = onError(e ?: Exception("Session"))
                override fun wifiConfigFailed(e: Exception?) = onError(e ?: Exception("Config"))
                override fun wifiConfigApplied() { /* wait for completion */ }
                override fun provisioningFailedFromDevice(e: ProvisionFailure?) =
                    onError(Exception("Device failure: ${e?.failureReason}"))
                override fun provisioningApplyFailed(e: Exception?) = onError(e ?: Exception("Apply"))
                override fun provisioningSuccess() = onSuccess()
            }
        )
    }
}
```

## 4. UI Checklist

1. Request Bluetooth + location permissions
2. Enable Bluetooth (and GPS on some OEMs) before scanning
3. Display discovered devices whose names start with `kc-`
4. Prompt user for Wi-Fi SSID/password
5. Trigger the provisioning flow with PoP `sumppop`
6. Show progress updates from `ProvisionListener` callbacks
7. Inform the user when provisioning succeeds and they can exit the app

    ### 🎨 Modern UI
    - Material Design 3
    - Bottom navigation
    - Real-time status updates
    - Color-coded indicators
    - Form validation
    - Responsive layouts

## 5. Troubleshooting

| Symptom | Fix |
|---------|-----|
| Device not found | Ensure ESP32 is in provisioning mode (clear credentials with GPIO0 short press); confirm BLE + location permissions are granted. |
| "Create session failed" | Wrong PoP or device already provisioned; clear credentials and retry. |
| Provisioning stuck on "Applying" | Check serial monitor for Wi-Fi failures; incorrect SSID/password propagate back as `ProvisionFailure` with reason `AP_NOT_FOUND` or `AUTH_FAILED`. |
| Android 12+ scan crash | Request `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` + `ACCESS_FINE_LOCATION` at runtime. |

## 6. Testing Checklist

- [ ] Short press GPIO0 to clear Wi-Fi credentials before each test
- [ ] `idf.py monitor` shows `Provisioning started (service kc-XXXXXX)`
- [ ] App scan lists the same device name
- [ ] Enter PoP `sumppop` and Wi-Fi credentials
- [ ] Observe `WIFI_PROV_CRED_SUCCESS` then `WIFI_PROV_END` in the monitor output
- [ ] Device connects to Wi-Fi and BLE stops advertising

This guide intentionally avoids the deprecated custom GATT service/UUID workflow; the Android app should always rely on Espressif's provisioning library to match the firmware.

