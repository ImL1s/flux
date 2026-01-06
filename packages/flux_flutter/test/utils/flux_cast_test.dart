import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/utils/flux_cast.dart';

/// Unit Tests for FluxCast Helper Methods
/// Focus on edge cases and type conversion robustness
void main() {
  group('FluxCast.toEdgeInsets', () {
    test('returns null for null input', () {
      expect(FluxCast.toEdgeInsets(null), isNull);
    });

    test('returns EdgeInsets.all for single number', () {
      expect(FluxCast.toEdgeInsets(10), EdgeInsets.all(10.0));
      expect(FluxCast.toEdgeInsets(10.5), EdgeInsets.all(10.5));
    });

    test('returns EdgeInsets.all for single-element list', () {
      expect(FluxCast.toEdgeInsets([8]), EdgeInsets.all(8.0));
      expect(FluxCast.toEdgeInsets([16.0]), EdgeInsets.all(16.0));
    });

    test('returns EdgeInsets.symmetric for 2-element list', () {
      // Implementation: [horizontal, vertical]
      expect(
        FluxCast.toEdgeInsets([10, 20]),
        EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      );
    });

    test('returns EdgeInsets.fromLTRB for 4-element list', () {
      expect(
        FluxCast.toEdgeInsets([1, 2, 3, 4]),
        EdgeInsets.fromLTRB(1.0, 2.0, 3.0, 4.0),
      );
    });

    test('returns null for 3-element list (unsupported)', () {
      expect(FluxCast.toEdgeInsets([1, 2, 3]), isNull);
    });

    test('returns null for empty list', () {
      expect(FluxCast.toEdgeInsets([]), isNull);
    });

    test('returns null for invalid types', () {
      expect(FluxCast.toEdgeInsets('invalid'), isNull);
      expect(FluxCast.toEdgeInsets({'key': 'value'}), isNull);
    });

    test('passes through existing EdgeInsets', () {
      const existing = EdgeInsets.all(42.0);
      expect(FluxCast.toEdgeInsets(existing), existing);
    });
  });

  group('FluxCast.toAlignment', () {
    test('returns null for null input', () {
      expect(FluxCast.toAlignment(null), isNull);
    });

    test('parses string alignment names (case-sensitive)', () {
      // Implementation uses exact case matching
      expect(FluxCast.toAlignment('center'), Alignment.center);
      expect(FluxCast.toAlignment('topLeft'), Alignment.topLeft);
      expect(FluxCast.toAlignment('bottomRight'), Alignment.bottomRight);
      // Case-insensitive is NOT supported
      expect(FluxCast.toAlignment('CENTER'), isNull);
      expect(FluxCast.toAlignment('TOPLEFT'), isNull);
    });

    test('returns null for unknown string', () {
      // No fallback to center - returns null for unknown
      expect(FluxCast.toAlignment('unknownValue'), isNull);
    });

    test('creates Alignment from 2-element list', () {
      expect(FluxCast.toAlignment([0.5, -0.5]), Alignment(0.5, -0.5));
      expect(FluxCast.toAlignment([-1, 1]), Alignment(-1.0, 1.0));
    });

    test('returns null for invalid list lengths', () {
      expect(FluxCast.toAlignment([1]), isNull);
      expect(FluxCast.toAlignment([1, 2, 3]), isNull);
    });

    test('returns null for invalid types', () {
      expect(FluxCast.toAlignment(123), isNull);
      expect(FluxCast.toAlignment({'x': 1, 'y': 2}), isNull);
    });

    test('passes through existing Alignment', () {
      const existing = Alignment.bottomLeft;
      expect(FluxCast.toAlignment(existing), existing);
    });
  });

  group('FluxCast.toColor edge cases', () {
    test('returns null for null input', () {
      expect(FluxCast.toColor(null), isNull);
    });

    test('parses common color names', () {
      expect(FluxCast.toColor('red'), Colors.red);
      expect(FluxCast.toColor('blue'), Colors.blue);
      expect(FluxCast.toColor('green'), Colors.green);
      expect(FluxCast.toColor('white'), Colors.white);
      expect(FluxCast.toColor('black'), Colors.black);
    });

    test('parses hex colors with #', () {
      expect(FluxCast.toColor('#FF0000'), const Color(0xFFFF0000));
      expect(FluxCast.toColor('#00FF00'), const Color(0xFF00FF00));
    });

    test('parses int color values', () {
      // FluxCast.toColor may not support '0x' string format
      // It supports int values directly or named colors
      expect(FluxCast.toColor(0xFF0000FF), const Color(0xFF0000FF));
    });

    test('returns null for invalid color strings', () {
      expect(FluxCast.toColor('notacolor'), isNull);
      expect(FluxCast.toColor(''), isNull);
    });
  });

  group('FluxCast.toDouble edge cases', () {
    test('returns null for null', () {
      expect(FluxCast.toDouble(null), isNull);
    });

    test('handles int input', () {
      expect(FluxCast.toDouble(42), 42.0);
    });

    test('handles double input', () {
      expect(FluxCast.toDouble(3.14), 3.14);
    });

    test('parses string numbers', () {
      expect(FluxCast.toDouble('123.45'), 123.45);
      expect(FluxCast.toDouble('100'), 100.0);
    });

    test('returns null for non-numeric strings', () {
      expect(FluxCast.toDouble('abc'), isNull);
    });
  });

  group('FluxCast.toInt edge cases', () {
    test('returns null for null', () {
      expect(FluxCast.toInt(null), isNull);
    });

    test('handles int input directly', () {
      expect(FluxCast.toInt(42), 42);
    });

    test('converts double to int (truncates)', () {
      expect(FluxCast.toInt(3.9), 3);
    });

    test('parses string integers', () {
      expect(FluxCast.toInt('500'), 500);
    });
  });
}
