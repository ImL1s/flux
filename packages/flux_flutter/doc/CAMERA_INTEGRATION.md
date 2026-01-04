# Camera Integration Guide

This document describes how to integrate the Flux Camera module in your Flutter application.

## Prerequisites

The `flux_flutter` package includes camera support via the `camera` package. To use camera features in your app, you must configure platform-specific permissions.

## Android Configuration

### 1. Minimum SDK Version

In `android/app/build.gradle`, ensure minimum SDK is 21 or higher:

```groovy
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### 2. Permissions

Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera permission -->
    <uses-permission android:name="android.permission.CAMERA"/>
    
    <!-- For video recording with audio -->
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    
    <!-- Recommended: Declare camera feature -->
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
    
    <application ...>
        ...
    </application>
</manifest>
```

## iOS Configuration

### 1. Info.plist

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access for capturing photos and videos.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access for recording videos with audio.</string>
```

### 2. Minimum iOS Version

In `ios/Podfile`, ensure iOS platform is 12.0 or higher:

```ruby
platform :ios, '12.0'
```

## Usage in Flux Scripts

### Camera Preview Widget

```flux
widget "CameraScreen" {
  build: (context) {
    return Scaffold(
      appBar: AppBar(title: Text("Camera")),
      body: CameraPreview({
        cameraId: 0,        // 0 = back, 1 = front
        fit: "cover",       // cover, contain, fill
        resolution: "high"  // low, medium, high, veryHigh, ultraHigh, max
      })
    );
  }
}
```

### Camera Module Functions

```flux
// Get available cameras
var cameras = await camera.availableCameras();
log("Found " + cameras.length + " cameras");

// Initialize camera
var result = await camera.initialize({
  cameraId: 0,
  resolution: "high",
  enableAudio: true
});

if (result.success) {
  log("Camera initialized");
  
  // Take a picture
  var photo = await camera.takePicture();
  if (photo.success) {
    log("Photo saved to: " + photo.path);
  }
  
  // Record video
  await camera.startVideoRecording();
  await delay(5000);  // Record for 5 seconds
  var video = await camera.stopVideoRecording();
  if (video.success) {
    log("Video saved to: " + video.path);
  }
  
  // Change flash mode
  await camera.setFlashMode("auto");  // off, auto, on, torch
  
  // Cleanup
  await camera.dispose();
}
```

## Resolution Presets

| Preset | Description |
|--------|-------------|
| `low` | 352x288 on iOS, 240p on Android |
| `medium` | 480p |
| `high` | 720p |
| `veryHigh` | 1080p |
| `ultraHigh` | 2160p (4K) |
| `max` | Highest available resolution |

## Flash Modes

| Mode | Description |
|------|-------------|
| `off` | Flash disabled |
| `auto` | Automatic flash |
| `on` or `always` | Flash always on when taking picture |
| `torch` | Continuous light (flashlight mode) |

## Error Handling

Always check the `success` field in the response:

```flux
var result = await camera.takePicture();
if (!result.success) {
  log("Error: " + result.error);
  showAlert("Camera Error", result.error);
}
```

## Best Practices

1. **Always dispose** the camera when done to free resources
2. **Check permissions** before using camera features
3. **Handle lifecycle** - camera is automatically paused when app goes to background
4. **Use appropriate resolution** - higher resolutions use more memory
5. **Test on real devices** - camera features don't work in simulators/emulators
