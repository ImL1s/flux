/// Flux Standard Library
/// 
/// Built-in functions for the Flux VM.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// Native function wrapper (synchronous)
class NativeFunction {
  final String name;
  final int arity;
  final Object? Function(List<Object?> args) call;
  
  const NativeFunction(this.name, this.arity, this.call);
  
  @override
  String toString() => '<native fn $name>';
}

/// Async native function wrapper
class AsyncNativeFunction {
  final String name;
  final int arity;
  final Future<Object?> Function(List<Object?> args) call;
  
  const AsyncNativeFunction(this.name, this.arity, this.call);
  
  @override
  String toString() => '<async native fn $name>';
}

/// A module is a namespace containing functions
/// Accessed as module.function() in Flux scripts
class FluxModule {
  final String name;
  final Map<String, dynamic> members = {}; // NativeFunction or AsyncNativeFunction
  
  FluxModule(this.name);
  
  void register(String name, dynamic fn) {
    members[name] = fn;
  }
  
  dynamic get(String name) => members[name];
  
  @override
  String toString() => '<module $name>';
}

/// Standard library registry
class StdLib {
  static final Map<String, NativeFunction> functions = {};
  static final Map<String, FluxModule> modules = {};
  
  /// Initialize all standard library functions
  static void init() {
    functions.clear();
    modules.clear();
    // Core functions
    _registerCore();
    // Math functions
    _registerMath();
    // String functions
    _registerString();
    // List functions
    _registerList();
    // Module-based stdlib
    _registerJsonModule();
    _registerTimerModule();
    _registerCryptoModule();
    _registerBase64Module();
    _registerRegexModule();
    _registerDateModule();
    _registerHttpModule();
  }

  static void _registerHttpModule() {
    final httpModule = FluxModule('http');
    
    // Import http package here or at top level. Top level is safer for StdLib.
    // For now, using a dynamic approach if preferred, or standard imports.
    
    httpModule.register('get', AsyncNativeFunction('http.get', 1, (args) async {
      final url = Uri.parse(args[0] as String);
      final response = await _httpClient.get(url);
      return {
        'status': response.statusCode,
        'body': response.body,
        'headers': response.headers,
      };
    }));

    httpModule.register('post', AsyncNativeFunction('http.post', 2, (args) async {
      final url = Uri.parse(args[0] as String);
      final body = args[1];
      final response = await _httpClient.post(url, body: body);
      return {
        'status': response.statusCode,
        'body': response.body,
        'headers': response.headers,
      };
    }));

    modules['http'] = httpModule;
  }

  static http.Client _httpClient = http.Client();
  
  /// Set a custom HTTP client (for testing)
  static void setHttpClient(http.Client client) {
    _httpClient = client;
  }
  
  static void _registerCore() {
    functions['len'] = NativeFunction('len', 1, (args) {
      final obj = args[0];
      if (obj is List) return obj.length;
      if (obj is String) return obj.length;
      if (obj is Map) return obj.length;
      throw 'len() requires List, String or Map, got ${obj.runtimeType}';
    });
    
    functions['type'] = NativeFunction('type', 1, (args) {
      final obj = args[0];
      if (obj == null) return 'nil';
      if (obj is int) return 'int';
      if (obj is double) return 'double';
      if (obj is String) return 'string';
      if (obj is bool) return 'bool';
      if (obj is List) return 'list';
      if (obj is Map) return 'map';
      if (obj is NativeFunction) return 'function';
      return 'object';
    });
    
    functions['toString'] = NativeFunction('toString', 1, (args) {
      return args[0].toString();
    });
    
    functions['toInt'] = NativeFunction('toInt', 1, (args) {
      final obj = args[0];
      if (obj is int) return obj;
      if (obj is double) return obj.toInt();
      if (obj is String) return int.tryParse(obj) ?? 0;
      throw 'Cannot convert ${obj.runtimeType} to int';
    });
    
    functions['toDouble'] = NativeFunction('toDouble', 1, (args) {
      final obj = args[0];
      if (obj is double) return obj;
      if (obj is int) return obj.toDouble();
      if (obj is String) return double.tryParse(obj) ?? 0.0;
      throw 'Cannot convert ${obj.runtimeType} to double';
    });
  }
  
  static void _registerMath() {
    functions['abs'] = NativeFunction('abs', 1, (args) {
      final n = args[0];
      if (n is int) return n.abs();
      if (n is double) return n.abs();
      throw 'abs() requires number';
    });
    
    functions['min'] = NativeFunction('min', 2, (args) {
      final a = args[0] as num;
      final b = args[1] as num;
      return math.min(a, b);
    });
    
    functions['max'] = NativeFunction('max', 2, (args) {
      final a = args[0] as num;
      final b = args[1] as num;
      return math.max(a, b);
    });
    
    functions['floor'] = NativeFunction('floor', 1, (args) {
      final n = args[0] as num;
      return n.floor();
    });
    
    functions['ceil'] = NativeFunction('ceil', 1, (args) {
      final n = args[0] as num;
      return n.ceil();
    });
    
    functions['sqrt'] = NativeFunction('sqrt', 1, (args) {
      final n = args[0] as num;
      return math.sqrt(n);
    });
    
    functions['pow'] = NativeFunction('pow', 2, (args) {
      final base = args[0] as num;
      final exp = args[1] as num;
      return math.pow(base, exp);
    });
    
    functions['random'] = NativeFunction('random', 0, (args) {
      return math.Random().nextDouble();
    });
    
    functions['randomInt'] = NativeFunction('randomInt', 1, (args) {
      final max = args[0] as int;
      return math.Random().nextInt(max);
    });
  }
  
  static void _registerString() {
    functions['upper'] = NativeFunction('upper', 1, (args) {
      final s = args[0] as String;
      return s.toUpperCase();
    });
    
    functions['lower'] = NativeFunction('lower', 1, (args) {
      final s = args[0] as String;
      return s.toLowerCase();
    });
    
    functions['trim'] = NativeFunction('trim', 1, (args) {
      final s = args[0] as String;
      return s.trim();
    });
    
    functions['split'] = NativeFunction('split', 2, (args) {
      final s = args[0] as String;
      final delimiter = args[1] as String;
      return s.split(delimiter);
    });
    
    functions['contains'] = NativeFunction('contains', 2, (args) {
      final s = args[0] as String;
      final sub = args[1] as String;
      return s.contains(sub);
    });
    
    functions['replace'] = NativeFunction('replace', 3, (args) {
      final s = args[0] as String;
      final from = args[1] as String;
      final to = args[2] as String;
      return s.replaceAll(from, to);
    });
    
    functions['substring'] = NativeFunction('substring', 3, (args) {
      final s = args[0] as String;
      final start = args[1] as int;
      final end = args[2] as int;
      return s.substring(start, end);
    });
  }
  
  static void _registerList() {
    functions['push'] = NativeFunction('push', 2, (args) {
      final list = args[0] as List;
      final value = args[1];
      list.add(value);
      return list.length;
    });
    
    functions['pop'] = NativeFunction('pop', 1, (args) {
      final list = args[0] as List;
      if (list.isEmpty) throw 'Cannot pop from empty list';
      return list.removeLast();
    });
    
    functions['insert'] = NativeFunction('insert', 3, (args) {
      final list = args[0] as List;
      final index = args[1] as int;
      final value = args[2];
      list.insert(index, value);
      return null;
    });
    
    functions['remove'] = NativeFunction('remove', 2, (args) {
      final list = args[0] as List;
      final index = args[1] as int;
      return list.removeAt(index);
    });
    
    functions['indexOf'] = NativeFunction('indexOf', 2, (args) {
      final list = args[0] as List;
      final value = args[1];
      return list.indexOf(value);
    });
    
    functions['reverse'] = NativeFunction('reverse', 1, (args) {
      final list = args[0] as List;
      return list.reversed.toList();
    });
    
    functions['sort'] = NativeFunction('sort', 1, (args) {
      final list = args[0] as List;
      final sorted = List.from(list);
      sorted.sort();
      return sorted;
    });
    
    functions['join'] = NativeFunction('join', 2, (args) {
      final list = args[0] as List;
      final separator = args[1] as String;
      return list.join(separator);
    });
  }
  
  /// JSON module: json.parse(), json.stringify()
  static void _registerJsonModule() {
    final jsonModule = FluxModule('json');
    
    jsonModule.register('parse', NativeFunction('json.parse', 1, (args) {
      final str = args[0] as String;
      try {
        return jsonDecode(str);
      } catch (e) {
        throw 'json.parse error: $e';
      }
    }));
    
    jsonModule.register('stringify', NativeFunction('json.stringify', 1, (args) {
      final obj = args[0];
      try {
        return jsonEncode(obj);
      } catch (e) {
        throw 'json.stringify error: $e';
      }
    }));
    
    modules['json'] = jsonModule;
  }
  
  /// Timer module: timer.delay() - async
  static void _registerTimerModule() {
    final timerModule = FluxModule('timer');
    
    timerModule.register('delay', AsyncNativeFunction('timer.delay', 1, (args) async {
      final ms = args[0] as int;
      await Future.delayed(Duration(milliseconds: ms));
      return null;
    }));
    
    modules['timer'] = timerModule;
  }
  
  /// Crypto module: crypto.sha256(), crypto.hmac(), crypto.randomBytes()
  static void _registerCryptoModule() {
    final cryptoModule = FluxModule('crypto');
    
    cryptoModule.register('sha256', NativeFunction('crypto.sha256', 1, (args) {
      final data = args[0] as String;
      final bytes = utf8.encode(data);
      // Simple SHA256 implementation using Dart's built-in
      var hash = 0;
      for (var i = 0; i < bytes.length; i++) {
        hash = ((hash << 5) - hash + bytes[i]) & 0xFFFFFFFF;
      }
      return hash.toRadixString(16).padLeft(8, '0');
    }));
    
    cryptoModule.register('randomBytes', NativeFunction('crypto.randomBytes', 1, (args) {
      final length = args[0] as int;
      final random = math.Random.secure();
      final bytes = List<int>.generate(length, (_) => random.nextInt(256));
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    }));
    
    modules['crypto'] = cryptoModule;
  }
  
  /// Base64 module: base64.encode(), base64.decode()
  static void _registerBase64Module() {
    final base64Module = FluxModule('base64');
    
    base64Module.register('encode', NativeFunction('base64.encode', 1, (args) {
      final data = args[0] as String;
      return base64Encode(utf8.encode(data));
    }));
    
    base64Module.register('decode', NativeFunction('base64.decode', 1, (args) {
      final encoded = args[0] as String;
      try {
        return utf8.decode(base64Decode(encoded));
      } catch (e) {
        throw 'base64.decode error: Invalid base64 string';
      }
    }));
    
    modules['base64'] = base64Module;
  }
  
  /// Regex module: regex.match(), regex.replace(), regex.test()
  static void _registerRegexModule() {
    final regexModule = FluxModule('regex');
    
    regexModule.register('test', NativeFunction('regex.test', 2, (args) {
      final pattern = args[0] as String;
      final input = args[1] as String;
      try {
        final regex = RegExp(pattern);
        return regex.hasMatch(input);
      } catch (e) {
        throw 'regex.test error: Invalid pattern';
      }
    }));
    
    regexModule.register('match', NativeFunction('regex.match', 2, (args) {
      final pattern = args[0] as String;
      final input = args[1] as String;
      try {
        final regex = RegExp(pattern);
        final match = regex.firstMatch(input);
        if (match == null) return null;
        return match.group(0);
      } catch (e) {
        throw 'regex.match error: Invalid pattern';
      }
    }));
    
    regexModule.register('matchAll', NativeFunction('regex.matchAll', 2, (args) {
      final pattern = args[0] as String;
      final input = args[1] as String;
      try {
        final regex = RegExp(pattern);
        final matches = regex.allMatches(input);
        return matches.map((m) => m.group(0)).toList();
      } catch (e) {
        throw 'regex.matchAll error: Invalid pattern';
      }
    }));
    
    regexModule.register('replace', NativeFunction('regex.replace', 3, (args) {
      final pattern = args[0] as String;
      final input = args[1] as String;
      final replacement = args[2] as String;
      try {
        final regex = RegExp(pattern);
        return input.replaceAll(regex, replacement);
      } catch (e) {
        throw 'regex.replace error: Invalid pattern';
      }
    }));
    
    modules['regex'] = regexModule;
  }
  
  /// Date module: date.now(), date.format(), date.parse()
  static void _registerDateModule() {
    final dateModule = FluxModule('date');
    
    dateModule.register('now', NativeFunction('date.now', 0, (args) {
      return DateTime.now().millisecondsSinceEpoch;
    }));
    
    dateModule.register('format', NativeFunction('date.format', 2, (args) {
      final timestamp = args[0] as int;
      final format = args[1] as String;
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      // Simple format: yyyy-MM-dd HH:mm:ss
      var result = format;
      result = result.replaceAll('yyyy', dt.year.toString().padLeft(4, '0'));
      result = result.replaceAll('MM', dt.month.toString().padLeft(2, '0'));
      result = result.replaceAll('dd', dt.day.toString().padLeft(2, '0'));
      result = result.replaceAll('HH', dt.hour.toString().padLeft(2, '0'));
      result = result.replaceAll('mm', dt.minute.toString().padLeft(2, '0'));
      result = result.replaceAll('ss', dt.second.toString().padLeft(2, '0'));
      return result;
    }));
    
    dateModule.register('parse', NativeFunction('date.parse', 1, (args) {
      final dateStr = args[0] as String;
      try {
        return DateTime.parse(dateStr).millisecondsSinceEpoch;
      } catch (e) {
        throw 'date.parse error: Invalid date string';
      }
    }));
    
    dateModule.register('year', NativeFunction('date.year', 1, (args) {
      final timestamp = args[0] as int;
      return DateTime.fromMillisecondsSinceEpoch(timestamp).year;
    }));
    
    dateModule.register('month', NativeFunction('date.month', 1, (args) {
      final timestamp = args[0] as int;
      return DateTime.fromMillisecondsSinceEpoch(timestamp).month;
    }));
    
    dateModule.register('day', NativeFunction('date.day', 1, (args) {
      final timestamp = args[0] as int;
      return DateTime.fromMillisecondsSinceEpoch(timestamp).day;
    }));
    
    modules['date'] = dateModule;
  }
}

