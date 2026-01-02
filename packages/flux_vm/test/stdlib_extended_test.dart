/// Tests for extended standard library modules (crypto, base64, regex, date)
import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  late VM vm;
  late List<String> logs;

  void runScript(String source) {
    logs = [];
    vm = VM();
    vm.onPrint = (msg) => logs.add(msg);
    
    final tokens = Lexer(source).tokenize();
    final ast = Parser(tokens).parse();
    final compiler = Compiler(unit: ast);
    final function = compiler.endCompiler();
    vm.runChunk(function.chunk);
  }

  group('Base64 Module', () {
    test('base64.encode', () {
      runScript('''
        var encoded = base64.encode("Hello, World!");
        print(encoded);
      ''');
      expect(logs[0], 'SGVsbG8sIFdvcmxkIQ==');
    });

    test('base64.decode', () {
      runScript('''
        var decoded = base64.decode("SGVsbG8sIFdvcmxkIQ==");
        print(decoded);
      ''');
      expect(logs[0], 'Hello, World!');
    });

    test('base64 round-trip', () {
      runScript('''
        var original = "Test string 123!";
        var encoded = base64.encode(original);
        var decoded = base64.decode(encoded);
        print(decoded);
      ''');
      expect(logs[0], 'Test string 123!');
    });
  });

  group('Regex Module', () {
    test('regex.test matches', () {
      runScript('''
        print(regex.test("[0-9]+", "abc123def"));
        print(regex.test("[0-9]+", "abcdef"));
      ''');
      expect(logs[0], 'true');
      expect(logs[1], 'false');
    });

    test('regex.match', () {
      runScript('''
        var result = regex.match("[0-9]+", "abc123def");
        print(result);
      ''');
      expect(logs[0], '123');
    });

    test('regex.matchAll', () {
      runScript('''
        var matches = regex.matchAll("[0-9]+", "a1b22c333");
        print(len(matches));
        print(matches[0]);
        print(matches[1]);
        print(matches[2]);
      ''');
      expect(logs[0], '3');
      expect(logs[1], '1');
      expect(logs[2], '22');
      expect(logs[3], '333');
    });

    test('regex.replace', () {
      runScript('''
        var result = regex.replace("[0-9]+", "a1b2c3", "X");
        print(result);
      ''');
      expect(logs[0], 'aXbXcX');
    });
  });

  group('Date Module', () {
    test('date.now returns timestamp', () {
      runScript('''
        var ts = date.now();
        print(ts > 0);
      ''');
      expect(logs[0], 'true');
    });

    test('date.format', () {
      // Test with a known timestamp: 2024-01-15 10:30:45
      runScript('''
        var ts = date.parse("2024-01-15T10:30:45");
        var formatted = date.format(ts, "yyyy-MM-dd");
        print(formatted);
      ''');
      expect(logs[0], '2024-01-15');
    });

    test('date.parse', () {
      runScript('''
        var ts1 = date.parse("2024-01-01");
        var ts2 = date.parse("2024-12-31");
        print(ts2 > ts1);
      ''');
      expect(logs[0], 'true');
    });

    test('date.year/month/day', () {
      runScript('''
        var ts = date.parse("2024-06-15");
        print(date.year(ts));
        print(date.month(ts));
        print(date.day(ts));
      ''');
      expect(logs[0], '2024');
      expect(logs[1], '6');
      expect(logs[2], '15');
    });
  });

  group('Crypto Module', () {
    test('crypto.randomBytes generates hex', () {
      runScript('''
        var bytes = crypto.randomBytes(16);
        print(len(bytes));
      ''');
      // 16 bytes = 32 hex characters
      expect(logs[0], '32');
    });

    test('crypto.randomBytes different each time', () {
      runScript('''
        var a = crypto.randomBytes(8);
        var b = crypto.randomBytes(8);
        print(a != b);
      ''');
      expect(logs[0], 'true');
    });

    test('crypto.sha256 produces hash', () {
      runScript('''
        var hash = crypto.sha256("hello");
        print(len(hash) > 0);
      ''');
      expect(logs[0], 'true');
    });

    test('crypto.sha256 same input same output', () {
      runScript('''
        var h1 = crypto.sha256("test");
        var h2 = crypto.sha256("test");
        print(h1 == h2);
      ''');
      expect(logs[0], 'true');
    });
  });
}
