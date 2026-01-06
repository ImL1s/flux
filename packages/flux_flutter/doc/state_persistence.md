# State Persistence (v3.0)

Flux v3.0 introduces a comprehensive state persistence layer, enabling secure, efficient, and scalable local data storage for Flux applications.

## Features

- **StorageModule**: Enhanced wrapper around `SharedPreferences` with type-safe methods and JSON support.
- **HiveStorageModule**: Integration with `Hive` for high-performance NoSQL local storage.
- **SecureStorageModule**: Secure storage implementation using `flutter_secure_storage` (AES-256 encryption).
- **StateMigration**: Utility for managing application state versions and running migration scripts.

## Installation

These modules are included in `flux_flutter` v3.0+. No additional dependencies are required if using the standard package.

## Modules

### 1. StorageModule (SharedPreferences)

Provides simple key-value storage backed by `SharedPreferences`.

**Key Features:**
- Type-safe accessors (`getInt`, `setBool`, etc.)
- JSON object/list support (`setJson`, `getJson`)
- String list support

**Flux Script Usage:**
```dart
// Store user settings
storage.setJson("settings", {
  "theme": "dark",
  "notifications": true
});

// Retrieve
var settings = storage.getJson("settings");
print(settings["theme"]); // "dark"
```

### 2. HiveStorageModule (NoSQL)

Provides fast, box-based storage using Hive. Ideal for storing large lists or complex objects.

**Flux Script Usage:**
```dart
// Open a box
hive.openBox("users");

// Store data
hive.put("users", "user_1", {
  "name": "Alice",
  "role": "admin"
});

// Retrieve
var user = hive.get("users", "user_1");
```

### 3. SecureStorageModule (Encryption)

Provides encrypted storage for sensitive data like API tokens or private keys. Uses Keychain on iOS and EncryptedSharedPreferences on Android.

**Flux Script Usage:**
```dart
// Store API Token
secure.set("api_token", "sk_live_123456");

// Retrieve
var token = secure.get("api_token");
```

### 4. State Migration

The `StateMigration` utility helps manage data schema changes across app updates.

**Dart Usage (in your `main.dart`):**

```dart
final prefs = await SharedPreferences.getInstance();
final migration = StateMigration(prefs: prefs);

// Register migrations
migration.register(1, () async {
  // Migration logic for v1
  await prefs.setString('new_key', 'default');
});

migration.register(2, () async {
  // Migration logic for v2
  // e.g., move data from prefs to hive
});

// Run migrations up to target version
await migration.runMigrations(2);
```

**API Reference:**
- `register(version, callback)`: Register a migration step.
- `runMigrations(targetVersion)`: Execute pending migrations in order.
- `getCurrentVersion()`: Get the current data version.
```
