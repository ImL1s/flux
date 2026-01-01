import 'dart:convert';
import 'dart:typed_data';
import 'compiler.dart';
import 'bytecode.dart';

class BytecodeSerializer {
  final BytesBuilder _buffer = BytesBuilder();

  Uint8List serialize(CompiledFunction root) {
    _buffer.clear();
    
    // Header
    _buffer.add(utf8.encode('FLUX'));
    _buffer.addByte(1); // Version 1

    _writeConstant(root);
    
    return _buffer.toBytes();
  }

  void _writeConstant(Object? value) {
    if (value == null) {
      _buffer.addByte(0); // Null
    } else if (value is bool) {
      _buffer.addByte(1);
      _buffer.addByte(value ? 1 : 0);
    } else if (value is num) {
      _buffer.addByte(2);
      final list = Float64List(1);
      list[0] = value.toDouble();
      _buffer.add(list.buffer.asUint8List());
    } else if (value is String) {
      _buffer.addByte(3);
      _writeString(value);
    } else if (value is CompiledFunction) {
      _buffer.addByte(4);
      _writeFunction(value);
    } else if (value is CompiledClass) {
      _buffer.addByte(5);
      _writeClass(value);
    } else if (value is CompiledWidget) {
      _buffer.addByte(6);
      _writeWidget(value);
    } else {
      throw Exception('Unsupported constant type: ${value.runtimeType}');
    }
  }

  void _writeFunction(CompiledFunction fn) {
    _writeString(fn.name);
    _writeInt(fn.arity);
    _buffer.addByte(fn.isAsync ? 1 : 0);
    _writeString(fn.moduleName ?? '');
    
    // Write param names
    _writeInt(fn.paramNames.length);
    for (final p in fn.paramNames) {
      _writeString(p);
    }

    _writeChunk(fn.chunk);
  }

  void _writeClass(CompiledClass cls) {
    _writeString(cls.name);
    _writeString(cls.superclass ?? '');
    
    // Methods
    _writeInt(cls.methods.length);
    for (final entry in cls.methods.entries) {
      _writeString(entry.key);
      _writeFunction(entry.value);
    }
    
    // Fields
    _writeInt(cls.fields.length);
    for (final f in cls.fields) {
      _writeString(f);
    }
  }

  void _writeWidget(CompiledWidget widget) {
    _writeString(widget.name);
    _writeFunction(widget.buildMethod);
    
    _writeInt(widget.stateFields.length);
    for (final f in widget.stateFields) {
      _writeString(f);
    }
    
    _writeInt(widget.stateInitializers.length);
    for (final init in widget.stateInitializers) {
      _writeFunction(init); 
    }
  }

  void _writeChunk(Chunk chunk) {
    _writeInt(chunk.code.length);
    _buffer.add(chunk.code);

    _writeInt(chunk.constants.length);
    for (final c in chunk.constants) {
      _writeConstant(c);
    }
    
    _writeInt(chunk.lines.length);
    for (final l in chunk.lines) {
      _writeInt(l);
    }
  }

  void _writeString(String s) {
    final bytes = utf8.encode(s);
    _writeInt(bytes.length);
    _buffer.add(bytes);
  }

  void _writeInt(int value) {
     _buffer.addByte(value & 0xFF);
     _buffer.addByte((value >> 8) & 0xFF);
     _buffer.addByte((value >> 16) & 0xFF);
     _buffer.addByte((value >> 24) & 0xFF);
  }
}
