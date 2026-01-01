import 'package:flux_vm/flux_vm.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage module for Flux
/// 
/// Usage:
/// await storage.set("key", "value");
/// var val = await storage.get("key");
class StorageModule extends FluxModule {
  StorageModule() : super('storage') {
    register('get', AsyncNativeFunction('storage.get', 1, _get));
    register('set', AsyncNativeFunction('storage.set', 2, _set));
    register('remove', AsyncNativeFunction('storage.remove', 1, _remove));
    register('clear', AsyncNativeFunction('storage.clear', 0, _clear));
    register('containsKey', AsyncNativeFunction('storage.containsKey', 1, _containsKey));
  }

  Future<Object?> _get(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<Object?> _set(List<Object?> args) async {
    final key = args[0] as String;
    final value = args[1] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    return null;
  }

  Future<Object?> _remove(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    return null;
  }

  Future<Object?> _clear(List<Object?> args) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    return null;
  }
  
  Future<Object?> _containsKey(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}
