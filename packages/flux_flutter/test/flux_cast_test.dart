import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/utils/flux_cast.dart';

void main() {
  group('FluxCast', () {
    group('toStr', () {
      test('handles strings', () {
        expect(FluxCast.toStr('hello'), 'hello');
      });
      test('handles null', () {
        expect(FluxCast.toStr(null), '');
      });
      test('handles objects', () {
        expect(FluxCast.toStr(123), '123');
        expect(FluxCast.toStr(true), 'true');
      });
    });

    group('toDouble', () {
      test('handles doubles', () {
        expect(FluxCast.toDouble(10.5), 10.5);
      });
      test('handles ints', () {
        expect(FluxCast.toDouble(10), 10.0);
      });
      test('handles string numbers', () {
        expect(FluxCast.toDouble('12.5'), 12.5);
        expect(FluxCast.toDouble('10'), 10.0);
      });
      test('handles null and invalid', () {
        expect(FluxCast.toDouble(null), null);
        expect(FluxCast.toDouble('abc'), null);
        expect(FluxCast.toDouble(false), null);
      });
      test('toDoubleOrZero', () {
        expect(FluxCast.toDoubleOrZero(null), 0.0);
        expect(FluxCast.toDoubleOrZero('invalid'), 0.0);
        expect(FluxCast.toDoubleOrZero(5), 5.0);
      });
    });

    group('toInt', () {
      test('handles ints', () {
        expect(FluxCast.toInt(100), 100);
      });
      test('handles doubles', () {
        expect(FluxCast.toInt(100.9), 100); // Truncates
      });
      test('handles string numbers', () {
        expect(FluxCast.toInt('42'), 42);
      });
      test('handles invalid', () {
        expect(FluxCast.toInt('abc'), null);
        expect(FluxCast.toInt(null), null);
      });
    });

    group('toBool', () {
      test('handles booleans', () {
        expect(FluxCast.toBool(true), true);
        expect(FluxCast.toBool(false), false);
      });
      test('handles null', () {
        expect(FluxCast.toBool(null), false);
      });
      test('handles strings', () {
        expect(FluxCast.toBool('true'), true);
        expect(FluxCast.toBool('TRUE'), true);
        expect(FluxCast.toBool('false'), false);
        expect(FluxCast.toBool('random'), false); // Default safe
      });
      test('handles numbers', () {
        expect(FluxCast.toBool(1), true);
        expect(FluxCast.toBool(0), false);
      });
    });

    group('toColor', () {
      test('handles int (0xAARRGGBB)', () {
        // Red with full alpha: 0xFFFF0000
        expect(FluxCast.toColor(0xFFFF0000), const Color(0xFFFF0000));
      });
      test('handles named colors', () {
        expect(FluxCast.toColor('red'), Colors.red);
        expect(FluxCast.toColor('Blue'), Colors.blue); // Case insensitive
        expect(FluxCast.toColor('TRANSPARENT'), Colors.transparent);
      });
      test('handles String hex (#RRGGBB)', () {
        // Red #FF0000 -> 0xFFFF0000
        expect(FluxCast.toColor('#FF0000'), const Color(0xFFFF0000));
      });
      test('handles String hex without hash (RRGGBB)', () {
        expect(FluxCast.toColor('FF0000'), const Color(0xFFFF0000));
      });
      test('handles String hex with Alpha (#AARRGGBB)', () {
        expect(FluxCast.toColor('#80FF0000'), const Color(0x80FF0000));
      });
      test('handles String hex with Alpha no hash (AARRGGBB)', () {
        expect(FluxCast.toColor('80FF0000'), const Color(0x80FF0000));
      });
      test('handles invalid', () {
        expect(FluxCast.toColor('not-a-color'), null);
        expect(FluxCast.toColor(null), null);
      });
    });

    group('toWidgetList', () {
      test('handles list of widgets', () {
        final list = [const SizedBox(), const Text('Hi')];
        expect(FluxCast.toWidgetList(list).length, 2);
      });
      test('filters non-widgets', () {
        final list = [const SizedBox(), 'Not a widget', 123, null];
        final result = FluxCast.toWidgetList(list);
        expect(result.length, 1);
        expect(result.first, isA<SizedBox>());
      });
      test('handles non-list', () {
        expect(FluxCast.toWidgetList('abc'), isEmpty);
        expect(FluxCast.toWidgetList(null), isEmpty);
      });
    });
  });
}
