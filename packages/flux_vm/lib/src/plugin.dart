/// Flux Plugin System
///
/// Defines the interface for extending Flux functionality via plugins.

import 'vm.dart';
import 'stdlib.dart';

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

  PluginRegistry(this.vm);

  /// Register and load a plugin
  void register(FluxPlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw 'Plugin ${plugin.id} is already registered';
    }

    // TODO: content security policy check based on permissions

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
