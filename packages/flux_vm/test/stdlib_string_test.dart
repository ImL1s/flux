import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('StdLib String Operations', () {
    late VM vm;
    late List<String> logs;

    setUp(() {
      vm = VM();
      logs = [];
      vm.onPrint = (msg) => logs.add(msg);
    });

    void runScript(String source) {
      final tokens = Lexer(source).tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();
      vm.runChunk(function.chunk);
    }

    test('string case conversion', () {
      runScript('''
        var s = "Hello World";
        print(upper(s));
        print(lower(s));
      ''');
      expect(logs[0], 'HELLO WORLD');
      expect(logs[1], 'hello world');
    });

    test('string.trim', () {
      runScript('''
        var s = "  flux  ";
        print(trim(s));
      ''');
      expect(logs[0], 'flux');
    });

    test('string.split', () {
      runScript('''
        var s = "a,b,c";
        var parts = split(s, ",");
        print(parts);
        print(len(parts));
      ''');
      expect(logs[0], '[a, b, c]');
      expect(logs[1], '3');
    });

    test('string.contains', () {
      runScript('''
        var s = "hello world";
        print(contains(s, "world"));
        print(contains(s, "flux"));
      ''');
      expect(logs[0], 'true');
      expect(logs[1], 'false');
    });

    test('string.replace', () {
      runScript('''
        var s = "banana";
        print(replace(s, "nan", "bat"));
      ''');
      expect(logs[0], 'babata'); // Dart replaceAll? "banana".replaceAll("nan", "bat") -> "a" is left? "ba" + "nan" + "a" -> "ba" + "bat" + "a" = babata. Wait. 
      // "banana" -> "b" "anana" -> "ba" "nana" -> "ban" "ana" ? "nan" matches at index 2.
      // b a n a n a 
      // 0 1 2 3 4 5
      //     ^ ^ ^
      // replaceAll replaces all occurrences.
    });

    test('string.substring', () {
      runScript('''
        var s = "hello";
        print(substring(s, 1, 4));
      ''');
      expect(logs[0], 'ell');
    });
    
    test('string conversions', () {
      runScript('''
         print(toInt("42") + 1);
         print(toDouble("3.14") + 0.01);
      ''');
      expect(logs[0], '43');
      expect(logs[1], '3.15'); // Floating point check might be fuzzy, but exact usage should work for simple cases
    });
  });
}
