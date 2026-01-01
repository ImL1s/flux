// Flux Standard Library - Device & Dialog Module Example
// Demonstrates native platform features (requires Flutter runtime)

print("=== Device & Dialog Module Demo ===");
print("Note: This example requires Flutter runtime for full functionality");

// --- Device Information ---
print("\n--- Device Information ---");

async fn showDeviceInfo() {
  var info = await device.getDeviceInfo();
  
  print("Platform: " + info.os);
  print("Version: " + info.version);
  print("Model: " + info.model);
  
  if (info.os == "android") {
    print("Brand: " + info.brand);
    print("Device ID: " + info.id);
  } else if (info.os == "ios") {
    print("Device Name: " + info.name);
  }
  
  print("Is Physical Device: " + info.isPhysical);
}

await showDeviceInfo();

// --- Package Information ---
print("\n--- Package Information ---");

async fn showPackageInfo() {
  var pkg = await device.getPackageInfo();
  
  print("App Name: " + pkg.appName);
  print("Version: " + pkg.version);
  print("Build Number: " + pkg.buildNumber);
  print("Package Name: " + pkg.packageName);
}

await showPackageInfo();

// --- Dialog Examples ---
print("\n--- Dialog Examples ---");

// Alert dialog
async fn showAlert() {
  await dialog.alert("Welcome!", "Hello from Flux!");
  print("Alert dismissed");
}

await showAlert();

// Confirmation dialog
async fn askConfirmation() {
  var result = await dialog.confirm("Delete Item", "Are you sure you want to delete this?");
  
  if (result) {
    print("User confirmed deletion");
    dialog.toast("Item deleted!");
  } else {
    print("User cancelled");
    dialog.toast("Cancelled");
  }
}

await askConfirmation();

// Toast notifications
print("\n--- Toast Notifications ---");
dialog.toast("This is an info message");
await timer.delay(1500);
dialog.toast("Operation successful!");

print("\n=== Complete! ===");
