// Flux Standard Library - Storage Module Example
// Demonstrates persistent storage using the storage module

print("=== Storage Module Demo ===");

// Store simple values
print("\n--- Storing Values ---");
storage.set("username", "flux_user");
storage.set("login_count", "5");
storage.set("theme", "dark");

print("Stored: username, login_count, theme");

// Retrieve values
print("\n--- Retrieving Values ---");
var username = storage.get("username");
var loginCount = storage.get("login_count");
var theme = storage.get("theme");

print("Username: " + username);
print("Login Count: " + loginCount);
print("Theme: " + theme);

// Store complex data as JSON
print("\n--- Storing Complex Data ---");
var userSettings = {
  "notifications": true,
  "language": "en",
  "fontSize": 14,
  "favorites": ["home", "profile", "settings"]
};

storage.set("user_settings", json.stringify(userSettings));
print("Stored user settings as JSON");

// Retrieve and parse complex data
print("\n--- Retrieving Complex Data ---");
var settingsJson = storage.get("user_settings");
var settings = json.parse(settingsJson);

print("Notifications: " + settings.notifications);
print("Language: " + settings.language);
print("Font Size: " + settings.fontSize);
print("Favorites: " + settings.favorites);

// Check for non-existent key
print("\n--- Handling Missing Keys ---");
var missing = storage.get("nonexistent_key");
if (missing == nil) {
  print("Key 'nonexistent_key' not found (returns nil)");
}

// Update existing value
print("\n--- Updating Values ---");
var count = storage.get("login_count");
var newCount = count + 1;
storage.set("login_count", newCount);
print("Updated login_count to: " + storage.get("login_count"));

print("\n=== Complete! ===");
