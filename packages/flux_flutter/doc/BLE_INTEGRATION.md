# BLE Integration Guide

This document describes how to integrate the Flux BLE module in your Flutter application.

## Prerequisites

The `flux_flutter` package includes Bluetooth Low Energy support via `flutter_blue_plus`.

## Android Configuration

### 1. Permissions (Android 12+)

For Android 12 (API 31) and higher, you must use the new Bluetooth permissions. Add these to your `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Request legacy Bluetooth permissions on older devices. -->
    <uses-permission android:name="android.permission.BLUETOOTH"
                     android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
                     android:maxSdkVersion="30" />

    <!-- Needed only if your app looks for Bluetooth devices.
         You must add an attribute to this permission, or declare the
         ACCESS_FINE_LOCATION permission, depending on the results when you
         check location usage in your app. -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                     android:usesPermissionFlags="neverForLocation" /> 

    <!-- Needed only if your app makes the device discoverable to Bluetooth
         devices. -->
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />

    <!-- Needed only if your app communicates with already-paired Bluetooth
         devices. -->
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

    <!-- Legacy location permission for Android 11 and lower -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
                     android:maxSdkVersion="30" />
</manifest>
```

> **Note**: `neverForLocation` flag allows scanning without Location permission on Android 12+. If you need physical location from beacons, remove this flag and request `ACCESS_FINE_LOCATION`.

### 2. build.gradle

Ensure `minSdkVersion` is at least 21.

## iOS Configuration

Add these keys to `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app requires Bluetooth to connect to devices.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app requires Bluetooth to connect to devices.</string>
```

## Usage in Flux Scripts

### Scanning

```flux
// Check availability
if (await ble.isAvailable()) {
  log("Scanning for devices...");
  
  // Start scan
  var result = await ble.startScan({
    timeout: 5000,
    serviceUuids: ["180d"] // Optional filter
  });
  
  // Get results
  var devices = ble.getDiscoveredDevices();
  foreach (d in devices) {
    log("Found: " + d.name + " (" + d.id + ")");
  }
}
```

### Connection & Interaction

```flux
var deviceId = "REMOTE-DEVICE-ID";

// Connect
var result = await ble.connect(deviceId);
if (result.success) {
  log("Connected!");
  
  // Discover services
  var services = await ble.discoverServices(deviceId);
  
  // Read Battery Level (Service 180f, Char 2a19)
  var battery = await ble.read(deviceId, "180f", "2a19");
  log("Battery: " + battery.value[0] + "%");
  
  // Subscribe to Heart Rate (Service 180d, Char 2a37)
  await ble.subscribe(deviceId, "180d", "2a37", (data) => {
    log("Heart Rate: " + data[1] + " bpm");
  });
  
  // Disconnect later
  // await ble.disconnect(deviceId);
}
```
