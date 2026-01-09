import 'dart:convert';

/// Generates Source Maps v3.
///
/// See: https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit
class SourceMapGenerator {
  final String file;
  final String? sourceRoot;
  final List<String> sources = [];
  final List<String> names = [];

  // Mappings are stored as a list of entries, which will be encoded to VLQ
  final List<SourceMapEntry> _entries = [];

  SourceMapGenerator({required this.file, this.sourceRoot});

  int addSource(String url) {
    print('DEBUG: Adding source url: $url');
    var index = sources.indexOf(url);
    if (index == -1) {
      sources.add(url);
      index = sources.length - 1;
    }
    return index;
  }

  int addName(String name) {
    var index = names.indexOf(name);
    if (index == -1) {
      names.add(name);
      index = names.length - 1;
    }
    return index;
  }

  void addEntry(int generatedLine, int generatedColumn,
      {int? sourceIndex, int? sourceLine, int? sourceColumn, int? nameIndex}) {
    _entries.add(SourceMapEntry(
      generatedLine: generatedLine,
      generatedColumn: generatedColumn,
      sourceIndex: sourceIndex,
      sourceLine: sourceLine,
      sourceColumn: sourceColumn,
      nameIndex: nameIndex,
    ));
  }

  /// Encodes the mappings into a JSON string.
  String toJson() {
    final buffer = StringBuffer();

    // Sort entries by generated line and column
    _entries.sort((a, b) {
      if (a.generatedLine != b.generatedLine) {
        return a.generatedLine.compareTo(b.generatedLine);
      }
      return a.generatedColumn.compareTo(b.generatedColumn);
    });

    int prevGeneratedLine = 0;
    int prevGeneratedColumn = 0;
    int prevSourceIndex = 0;
    int prevSourceLine = 0;
    int prevSourceColumn = 0;
    int prevNameIndex = 0;

    for (int i = 0; i < _entries.length; i++) {
      final entry = _entries[i];

      if (entry.generatedLine > prevGeneratedLine) {
        for (int l = prevGeneratedLine; l < entry.generatedLine; l++) {
          buffer.write(';');
        }
        prevGeneratedLine = entry.generatedLine;
        prevGeneratedColumn = 0;
      } else if (i > 0) {
        buffer.write(',');
      }

      // 1. Generated Column
      _encodeVlq(buffer, entry.generatedColumn - prevGeneratedColumn);
      prevGeneratedColumn = entry.generatedColumn;

      if (entry.sourceIndex != null) {
        // 2. Source Index
        _encodeVlq(buffer, entry.sourceIndex! - prevSourceIndex);
        prevSourceIndex = entry.sourceIndex!;

        // 3. Source Line
        _encodeVlq(buffer, entry.sourceLine! - prevSourceLine);
        prevSourceLine = entry.sourceLine!;

        // 4. Source Column
        _encodeVlq(buffer, entry.sourceColumn! - prevSourceColumn);
        prevSourceColumn = entry.sourceColumn!;

        if (entry.nameIndex != null) {
          // 5. Name Index
          _encodeVlq(buffer, entry.nameIndex! - prevNameIndex);
          prevNameIndex = entry.nameIndex!;
        }
      }
    }

    // Fill remaining semicolons if needed (though usually not strictly required by consumers)

    return jsonEncode({
      'version': 3,
      'file': file,
      'sourceRoot': sourceRoot,
      'sources': sources,
      'names': names,
      'mappings': buffer.toString(),
    });
  }

  static const String _base64Digits =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  void _encodeVlq(StringBuffer buffer, int value) {
    int vlq = value < 0 ? ((-value) << 1) + 1 : (value << 1);
    do {
      int digit = vlq & 31;
      vlq >>= 5;
      if (vlq > 0) {
        digit |= 32;
      }
      buffer.write(_base64Digits[digit]);
    } while (vlq > 0);
  }
}

class SourceMapEntry {
  final int generatedLine;
  final int generatedColumn;
  final int? sourceIndex;
  final int? sourceLine;
  final int? sourceColumn;
  final int? nameIndex;

  SourceMapEntry({
    required this.generatedLine,
    required this.generatedColumn,
    this.sourceIndex,
    this.sourceLine,
    this.sourceColumn,
    this.nameIndex,
  });
}
