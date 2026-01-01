import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('Class System', () {
    test('Class instantiation and method call', () {
      const source = '''
        class Box {
          fn init(val) {
            this.value = val;
          }
          fn open() {
            print("Opened: " + this.value);
          }
        }
        
        var b = Box("Gold");
        b.open();
      ''';
      
      final logs = <String>[];
      
      final tokens = Lexer(source).tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();
      
      final vm = VM();
      vm.onPrint = (msg) => logs.add(msg);
      vm.runChunk(function.chunk);
      
      expect(logs.length, 1);
      expect(logs[0], 'Opened: Gold');
    });

    test('Inheritance and super calls', () {
      const source = '''
        class Animal {
          fn init(name) {
            this.name = name;
          }
          fn speak() {
            print(this.name + " makes a sound");
          }
        }
        
        class Dog extends Animal {
          fn init(name, breed) {
            super.init(name);
            this.breed = breed;
          }
          fn speak() {
            print(this.name + " the " + this.breed + " woofs");
          }
        }
        
        var d = Dog("Buddy", "Golden");
        d.speak();
      ''';
      
      final logs = <String>[];
      
      final tokens = Lexer(source).tokenize();
      final ast = Parser(tokens).parse();
      final function = Compiler(unit: ast).endCompiler();
      
      final vm = VM();
      vm.onPrint = (msg) => logs.add(msg);
      vm.runChunk(function.chunk);
      
      expect(logs[0], 'Buddy the Golden woofs');
    });
  });
}
