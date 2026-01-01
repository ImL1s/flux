import 'dart:convert';
import 'dart:typed_data';
import 'compiler.dart';
import 'bytecode.dart';

class BytecodeDeserializer {
  late Uint8List _data;
  int _offset = 0;

  CompiledFunction deserialize(Uint8List bytes) {
    _data = bytes;
    _offset = 0;

    // Verify header
    final header = utf8.decode(_data.sublist(0, 4));
    if (header != 'FLUX') {
      throw FormatException('Invalid FLUX bytecode header: $header');
    }
    _offset = 4;

    final version = _readByte();
    if (version != 1) {
      throw FormatException('Unsupported FLUX bytecode version: $version');
    }

    final root = _readConstant();
    if (root is! CompiledFunction) {
      throw FormatException('Root constant must be a CompiledFunction');
    }
    return root;
  }

  int _readByte() {
    return _data[_offset++];
  }

  int _readInt() {
    final b0 = _data[_offset++];
    final b1 = _data[_offset++];
    final b2 = _data[_offset++];
    final b3 = _data[_offset++];
    return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
  }

  String _readString() {
    final length = _readInt();
    final bytes = _data.sublist(_offset, _offset + length);
    _offset += length;
    return utf8.decode(bytes);
  }

  Object? _readConstant() {
    final tag = _readByte();
    switch (tag) {
      case 0: // Null
        return null;
      case 1: // Bool
        return _readByte() != 0;
      case 2: // Num (double)
        // Read 8 bytes manually to avoid alignment issues
        final bytes = Uint8List(8);
        for (var i = 0; i < 8; i++) {
          bytes[i] = _data[_offset++];
        }
        final list = Float64List.view(bytes.buffer);
        return list[0];
      case 3: // String
        return _readString();
      case 4: // CompiledFunction
        return _readFunction();
      case 5: // CompiledClass
        return _readClass();
      case 6: // CompiledWidget
        return _readWidget();
      default:
        throw FormatException('Unknown constant tag: $tag');
    }
  }

  CompiledFunction _readFunction() {
    final name = _readString();
    final arity = _readInt();
    final isAsync = _readByte() != 0;
    final moduleName = _readString();

    final paramCount = _readInt();
    final paramNames = <String>[];
    for (var i = 0; i < paramCount; i++) {
      paramNames.add(_readString());
    }

    final chunk = _readChunk();

    return CompiledFunction(
      name,
      chunk,
      arity: arity,
      isAsync: isAsync,
      moduleName: moduleName.isEmpty ? null : moduleName,
      paramNames: paramNames,
    );
  }

  CompiledClass _readClass() {
    final name = _readString();
    final superclass = _readString();

    final methodCount = _readInt();
    final methods = <String, CompiledFunction>{};
    for (var i = 0; i < methodCount; i++) {
      final methodName = _readString();
      final method = _readFunction();
      methods[methodName] = method;
    }

    final fieldCount = _readInt();
    final fields = <String>[];
    for (var i = 0; i < fieldCount; i++) {
      fields.add(_readString());
    }

    return CompiledClass(
      name,
      methods: methods,
      fields: fields,
      superclass: superclass.isEmpty ? null : superclass,
    );
  }

  CompiledWidget _readWidget() {
    final name = _readString();
    final buildMethod = _readFunction();

    final stateFieldCount = _readInt();
    final stateFields = <String>[];
    for (var i = 0; i < stateFieldCount; i++) {
      stateFields.add(_readString());
    }

    final initializerCount = _readInt();
    final stateInitializers = <CompiledFunction>[];
    for (var i = 0; i < initializerCount; i++) {
      stateInitializers.add(_readFunction());
    }

    return CompiledWidget(
      name,
      buildMethod,
      stateFields: stateFields,
      stateInitializers: stateInitializers,
    );
  }

  Chunk _readChunk() {
    final codeLength = _readInt();
    final code = _data.sublist(_offset, _offset + codeLength);
    _offset += codeLength;

    final constantCount = _readInt();
    final constants = <Object?>[];
    for (var i = 0; i < constantCount; i++) {
      constants.add(_readConstant());
    }

    final lineCount = _readInt();
    final lines = <int>[];
    for (var i = 0; i < lineCount; i++) {
      lines.add(_readInt());
    }

    final chunk = Chunk();
    // Populate chunk
    for (final byte in code) {
      chunk.code.add(byte);
    }
    for (final c in constants) {
      chunk.constants.add(c);
    }
    for (final l in lines) {
      chunk.lines.add(l);
    }

    return chunk;
  }
}
