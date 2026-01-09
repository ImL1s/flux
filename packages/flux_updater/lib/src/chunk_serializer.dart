import 'dart:convert';
import 'dart:typed_data';

import 'package:flux_compiler/flux_compiler.dart';

/// Serializes and deserializes [Chunk] objects to/from binary format.
///
/// Binary format:
/// ```
/// [MAGIC: 4 bytes "FLUX"]
/// [VERSION: 1 byte]
/// [CODE_LENGTH: 4 bytes, big-endian]
/// [CODE: CODE_LENGTH bytes]
/// [LINES_LENGTH: 4 bytes, big-endian]
/// [LINES: LINES_LENGTH * 4 bytes, each int as big-endian]
/// [CONSTANTS_LENGTH: 4 bytes, big-endian]
/// [CONSTANTS: variable length, each constant prefixed with type byte]
/// ```
class ChunkSerializer {
  static const _magic = [0x46, 0x4C, 0x55, 0x58]; // "FLUX"
  static const _version = 1;

  // Constant type markers
  static const _typeNull = 0;
  static const _typeInt = 1;
  static const _typeDouble = 2;
  static const _typeString = 3;
  static const _typeBool = 4;
  static const _typeFunction = 5; // CompiledFunction
  static const _typeList = 6;
  static const _typeMap = 7;
  static const _typeWidget = 8;
  static const _typeClass = 9;

  /// Serialize a [Chunk] to binary format.
  static Uint8List serialize(Chunk chunk) {
    final buffer = BytesBuilder();

    // Magic header
    buffer.add(_magic);

    // Version
    buffer.addByte(_version);

    // Code bytes
    _writeInt32(buffer, chunk.code.length);
    buffer.add(Uint8List.fromList(chunk.code));

    // Lines (RLE encoded)
    _writeInt32(buffer, chunk.lines.length);
    for (final line in chunk.lines) {
      _writeInt32(buffer, line);
    }

    // Constants
    _writeInt32(buffer, chunk.constants.length);
    for (final constant in chunk.constants) {
      _writeConstant(buffer, constant);
    }

    return buffer.toBytes();
  }

  /// Deserialize a [Chunk] from binary format.
  static Chunk deserialize(Uint8List bytes) {
    final reader = _ByteReader(bytes);

    // Verify magic
    final magic = reader.readBytes(4);
    if (magic[0] != _magic[0] ||
        magic[1] != _magic[1] ||
        magic[2] != _magic[2] ||
        magic[3] != _magic[3]) {
      throw FormatException('Invalid Flux chunk: bad magic header');
    }

    // Version check
    final version = reader.readByte();
    if (version != _version) {
      throw FormatException(
          'Unsupported Flux chunk version: $version (expected $_version)');
    }

    final chunk = Chunk();

    // Code bytes
    final codeLength = reader.readInt32();
    final codeBytes = reader.readBytes(codeLength);
    for (final byte in codeBytes) {
      chunk.code.add(byte);
    }

    // Lines
    final linesLength = reader.readInt32();
    for (int i = 0; i < linesLength; i++) {
      chunk.lines.add(reader.readInt32());
    }

    // Constants
    final constantsLength = reader.readInt32();
    for (int i = 0; i < constantsLength; i++) {
      chunk.constants.add(_readConstant(reader));
    }

    return chunk;
  }

  static void _writeInt32(BytesBuilder buffer, int value) {
    buffer.addByte((value >> 24) & 0xFF);
    buffer.addByte((value >> 16) & 0xFF);
    buffer.addByte((value >> 8) & 0xFF);
    buffer.addByte(value & 0xFF);
  }

  static void _writeConstant(BytesBuilder buffer, Object? value) {
    if (value == null) {
      buffer.addByte(_typeNull);
    } else if (value is int) {
      buffer.addByte(_typeInt);
      // Write as 8-byte signed big-endian
      final bytes = ByteData(8);
      bytes.setInt64(0, value, Endian.big);
      buffer.add(bytes.buffer.asUint8List());
    } else if (value is double) {
      buffer.addByte(_typeDouble);
      final bytes = ByteData(8);
      bytes.setFloat64(0, value, Endian.big);
      buffer.add(bytes.buffer.asUint8List());
    } else if (value is String) {
      buffer.addByte(_typeString);
      final encoded = utf8.encode(value);
      _writeInt32(buffer, encoded.length);
      buffer.add(encoded);
    } else if (value is bool) {
      buffer.addByte(_typeBool);
      buffer.addByte(value ? 1 : 0);
    } else if (value is CompiledFunction) {
      buffer.addByte(_typeFunction);
      _writeCompiledFunction(buffer, value);
    } else if (value is CompiledWidget) {
      buffer.addByte(_typeWidget);
      _writeCompiledWidget(buffer, value);
    } else if (value is CompiledClass) {
      buffer.addByte(_typeClass);
      _writeCompiledClass(buffer, value);
    } else if (value is List) {
      buffer.addByte(_typeList);
      _writeInt32(buffer, value.length);
      for (final item in value) {
        _writeConstant(buffer, item);
      }
    } else if (value is Map) {
      buffer.addByte(_typeMap);
      _writeInt32(buffer, value.length);
      for (final entry in value.entries) {
        _writeConstant(buffer, entry.key);
        _writeConstant(buffer, entry.value);
      }
    } else {
      // Fallback: serialize as string representation
      buffer.addByte(_typeString);
      final encoded = utf8.encode(value.toString());
      _writeInt32(buffer, encoded.length);
      buffer.add(encoded);
    }
  }

  static void _writeCompiledFunction(
      BytesBuilder buffer, CompiledFunction func) {
    // Name
    final nameBytes = utf8.encode(func.name);
    _writeInt32(buffer, nameBytes.length);
    buffer.add(nameBytes);

    // Arity
    _writeInt32(buffer, func.arity);

    // isAsync
    buffer.addByte(func.isAsync ? 1 : 0);

    // ModuleName
    if (func.moduleName == null) {
      buffer.addByte(0);
    } else {
      buffer.addByte(1);
      final moduleBytes = utf8.encode(func.moduleName!);
      _writeInt32(buffer, moduleBytes.length);
      buffer.add(moduleBytes);
    }

    // Param names
    _writeInt32(buffer, func.paramNames.length);
    for (final param in func.paramNames) {
      final paramBytes = utf8.encode(param);
      _writeInt32(buffer, paramBytes.length);
      buffer.add(paramBytes);
    }

    // Local names
    _writeInt32(buffer, func.localNames.length);
    for (final name in func.localNames) {
      final nameBytes = utf8.encode(name);
      _writeInt32(buffer, nameBytes.length);
      buffer.add(nameBytes);
    }

    // Source Map
    if (func.sourceMap == null) {
      buffer.addByte(0);
    } else {
      buffer.addByte(1);
      final mapBytes = utf8.encode(func.sourceMap!);
      _writeInt32(buffer, mapBytes.length);
      buffer.add(mapBytes);
    }

    // Chunk (recursive)
    final chunkBytes = serialize(func.chunk);
    _writeInt32(buffer, chunkBytes.length);
    buffer.add(chunkBytes);
  }

  static void _writeCompiledWidget(BytesBuilder buffer, CompiledWidget widget) {
    final nameBytes = utf8.encode(widget.name);
    _writeInt32(buffer, nameBytes.length);
    buffer.add(nameBytes);

    _writeCompiledFunction(buffer, widget.buildMethod);

    _writeInt32(buffer, widget.stateFields.length);
    for (final field in widget.stateFields) {
      final fieldBytes = utf8.encode(field);
      _writeInt32(buffer, fieldBytes.length);
      buffer.add(fieldBytes);
    }

    _writeInt32(buffer, widget.stateInitializers.length);
    for (final init in widget.stateInitializers) {
      _writeCompiledFunction(buffer, init);
    }
  }

  static void _writeCompiledClass(BytesBuilder buffer, CompiledClass clazz) {
    final nameBytes = utf8.encode(clazz.name);
    _writeInt32(buffer, nameBytes.length);
    buffer.add(nameBytes);

    _writeInt32(buffer, clazz.methods.length);
    for (final entry in clazz.methods.entries) {
      final keyBytes = utf8.encode(entry.key);
      _writeInt32(buffer, keyBytes.length);
      buffer.add(keyBytes);
      _writeCompiledFunction(buffer, entry.value);
    }

    _writeInt32(buffer, clazz.fields.length);
    for (final field in clazz.fields) {
      final fieldBytes = utf8.encode(field);
      _writeInt32(buffer, fieldBytes.length);
      buffer.add(fieldBytes);
    }

    if (clazz.superclass == null) {
      buffer.addByte(0);
    } else {
      buffer.addByte(1);
      final superBytes = utf8.encode(clazz.superclass!);
      _writeInt32(buffer, superBytes.length);
      buffer.add(superBytes);
    }
  }

  static Object? _readConstant(_ByteReader reader) {
    final type = reader.readByte();
    switch (type) {
      case _typeNull:
        return null;
      case _typeInt:
        return reader.readInt64();
      case _typeDouble:
        return reader.readFloat64();
      case _typeString:
        final length = reader.readInt32();
        final bytes = reader.readBytes(length);
        return utf8.decode(bytes);
      case _typeBool:
        return reader.readByte() == 1;
      case _typeFunction:
        return _readCompiledFunction(reader);
      case _typeWidget:
        return _readCompiledWidget(reader);
      case _typeClass:
        return _readCompiledClass(reader);
      case _typeList:
        final length = reader.readInt32();
        final list = <Object?>[];
        for (int i = 0; i < length; i++) {
          list.add(_readConstant(reader));
        }
        return list;
      case _typeMap:
        final length = reader.readInt32();
        final map = <Object?, Object?>{};
        for (int i = 0; i < length; i++) {
          final key = _readConstant(reader);
          final value = _readConstant(reader);
          map[key] = value;
        }
        return map;
      default:
        throw FormatException('Unknown constant type: $type');
    }
  }

  static CompiledFunction _readCompiledFunction(_ByteReader reader) {
    final nameLength = reader.readInt32();
    final name = utf8.decode(reader.readBytes(nameLength));

    final arity = reader.readInt32();
    final isAsync = reader.readByte() == 1;

    final hasModuleName = reader.readByte() == 1;
    String? moduleName;
    if (hasModuleName) {
      final moduleLength = reader.readInt32();
      moduleName = utf8.decode(reader.readBytes(moduleLength));
    }

    final paramCount = reader.readInt32();
    final paramNames = <String>[];
    for (int i = 0; i < paramCount; i++) {
      final length = reader.readInt32();
      paramNames.add(utf8.decode(reader.readBytes(length)));
    }

    final localCount = reader.readInt32();
    final localNames = <String>[];
    for (int i = 0; i < localCount; i++) {
      final length = reader.readInt32();
      localNames.add(utf8.decode(reader.readBytes(length)));
    }

    final hasSourceMap = reader.readByte() == 1;
    String? sourceMap;
    if (hasSourceMap) {
      final mapLength = reader.readInt32();
      sourceMap = utf8.decode(reader.readBytes(mapLength));
    }

    final chunkLength = reader.readInt32();
    final chunkBytes = reader.readBytes(chunkLength);
    final chunk = deserialize(Uint8List.fromList(chunkBytes));

    final func = CompiledFunction(
      name,
      chunk,
      arity: arity,
      isAsync: isAsync,
      moduleName: moduleName,
      paramNames: paramNames,
      localNames: localNames,
      sourceMap: sourceMap,
    );

    return func;
  }

  static CompiledWidget _readCompiledWidget(_ByteReader reader) {
    final nameLength = reader.readInt32();
    final name = utf8.decode(reader.readBytes(nameLength));

    final buildMethod = _readCompiledFunction(reader);

    final fieldCount = reader.readInt32();
    final stateFields = <String>[];
    for (int i = 0; i < fieldCount; i++) {
      final length = reader.readInt32();
      stateFields.add(utf8.decode(reader.readBytes(length)));
    }

    final initCount = reader.readInt32();
    final stateInitializers = <CompiledFunction>[];
    for (int i = 0; i < initCount; i++) {
      stateInitializers.add(_readCompiledFunction(reader));
    }

    return CompiledWidget(
      name,
      buildMethod,
      stateFields: stateFields,
      stateInitializers: stateInitializers,
    );
  }

  static CompiledClass _readCompiledClass(_ByteReader reader) {
    final nameLength = reader.readInt32();
    final name = utf8.decode(reader.readBytes(nameLength));

    final methodCount = reader.readInt32();
    final methods = <String, CompiledFunction>{};
    for (int i = 0; i < methodCount; i++) {
      final keyLength = reader.readInt32();
      final key = utf8.decode(reader.readBytes(keyLength));
      methods[key] = _readCompiledFunction(reader);
    }

    final fieldCount = reader.readInt32();
    final fields = <String>[];
    for (int i = 0; i < fieldCount; i++) {
      final length = reader.readInt32();
      fields.add(utf8.decode(reader.readBytes(length)));
    }

    final hasSuper = reader.readByte() == 1;
    String? superclass;
    if (hasSuper) {
      final length = reader.readInt32();
      superclass = utf8.decode(reader.readBytes(length));
    }

    return CompiledClass(
      name,
      methods: methods,
      fields: fields,
      superclass: superclass,
    );
  }
}

/// Helper class to read bytes sequentially.
class _ByteReader {
  final Uint8List _bytes;
  int _offset = 0;

  _ByteReader(this._bytes);

  int readByte() {
    if (_offset >= _bytes.length) {
      throw RangeError('Unexpected end of data');
    }
    return _bytes[_offset++];
  }

  List<int> readBytes(int count) {
    if (_offset + count > _bytes.length) {
      throw RangeError('Unexpected end of data');
    }
    final result = _bytes.sublist(_offset, _offset + count);
    _offset += count;
    return result;
  }

  int readInt32() {
    final b0 = readByte();
    final b1 = readByte();
    final b2 = readByte();
    final b3 = readByte();
    return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
  }

  int readInt64() {
    final bytes = Uint8List.fromList(readBytes(8));
    final data = ByteData.sublistView(bytes);
    return data.getInt64(0, Endian.big);
  }

  double readFloat64() {
    final bytes = Uint8List.fromList(readBytes(8));
    final data = ByteData.sublistView(bytes);
    return data.getFloat64(0, Endian.big);
  }
}
