import 'vm.dart';
import 'stdlib.dart';

/// Standard permission identifiers for the Flux ecosystem.
class FluxPermissions {
  /// Allows network access (HTTP, WebSocket).
  static const String network = 'flux.permission.NETWORK';

  /// Allows local file system access.
  static const String fileSystem = 'flux.permission.FILE_SYSTEM';

  /// Allows spawning external processes.
  static const String process = 'flux.permission.PROCESS';

  /// Allows reading environment variables.
  static const String env = 'flux.permission.ENV';

  /// Allows Bluetooth Low Energy operations.
  static const String ble = 'flux.permission.BLE';

  /// Allows Camera access.
  static const String camera = 'flux.permission.CAMERA';
}

/// Base class for all Flux plugins
abstract class FluxPlugin {
  /// Unique identifier for the plugin (e.g. 'com.example.myplugin')
  String get id;

  /// Human-readable name
  String get name;

  /// Plugin version
  String get version;

  /// Required permissions (e.g. ['file', 'network'])
  List<String> get permissions => const [];

  /// Called when the plugin is loaded into the VM
  void onLoad(VM vm);

  /// Called when the plugin is unloaded (optional cleanup)
  void onUnload(VM vm) {}
}

/// Registry to manage loaded plugins
class PluginRegistry {
  final VM vm;
  final Map<String, FluxPlugin> _plugins = {};
  
  /// List of permissions allowed by the host application.
  /// If null, all permissions are allowed (insecure mode).
  final List<String>? allowedPermissions;

  PluginRegistry(this.vm, {this.allowedPermissions});

  /// Register and load a plugin
  void register(FluxPlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw 'Plugin ${plugin.id} is already registered';
    }

    // Security Check
    if (allowedPermissions != null) {
      for (final permission in plugin.permissions) {
        if (!allowedPermissions!.contains(permission)) {
          throw 'Security Error: Plugin ${plugin.id} requested unauthorized permission: $permission';
        }
      }
    }

    try {
      plugin.onLoad(vm);
      _plugins[plugin.id] = plugin;
    } catch (e) {
      throw 'Failed to load plugin ${plugin.id}: $e';
    }
  }

  /// Unregister and unload a plugin
  void unregister(String id) {
    final plugin = _plugins[id];
    if (plugin != null) {
      try {
        plugin.onUnload(vm);
      } catch (e) {
        print('Error unloading plugin $id: $e');
      }
      _plugins.remove(id);
    }
  }

  /// Get a registered plugin by ID
  FluxPlugin? get(String id) => _plugins[id];

  /// Get all registered plugins
  List<FluxPlugin> get all => _plugins.values.toList();
}
