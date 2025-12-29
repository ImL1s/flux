/// Flux Standard Library
/// 
/// Built-in functions for the Flux VM.

import 'dart:math' as math;

/// Native function wrapper
class NativeFunction {
  final String name;
  final int arity;
  final Object? Function(List<Object?> args) call;
  
  const NativeFunction(this.name, this.arity, this.call);
  
  @override
  String toString() => '<native fn $name>';
}

/// Standard library registry
class StdLib {
  static final Map<String, NativeFunction> functions = {};
  
  /// Initialize all standard library functions
  static void init() {
    // Core functions
    _registerCore();
    // Math functions
    _registerMath();
    // String functions
    _registerString();
    // List functions
    _registerList();
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
}
