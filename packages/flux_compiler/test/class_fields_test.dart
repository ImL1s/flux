import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

CompiledFunction compile(String source) {
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  final unit = parser.parse();
  return Compiler(unit: unit).endCompiler();
}

InterpretResult run(String source) {
  final vm = VM();
  return vm.interpret(source);
}

void main() {
  group('Class Fields - Basic', () {
    test('Field with initializer', () {
      final source = '''
        class Box {
          var value = 10;
        }
        var b = Box();
        if (b.value != 10) throw "Expected 10";
      ''';
      expect(run(source), InterpretResult.ok);
    });

    test('Field initialization order (fields before init body)', () {
      final source = '''
        class Point {
           var x = 1;
           var y = 2;
           
           fn init(start) {
             this.x = start;
           }
        }
        
        var p = Point(100);
        if (p.x != 100) throw "Error x";
        if (p.y != 2) throw "Error y";
      ''';
      expect(run(source), InterpretResult.ok);
    });

    test('Field without initializer parses correctly', () {
       final source = '''
         class Empty {
           var x;
         }
         var e = Empty();
       ''';
       compile(source); // Should not throw
    });
    
    test('Multiple fields', () {
      final source = '''
        class Config {
          var host = "localhost";
          var port = 8080;
          var debug = true;
        }
        var c = Config();
        if (c.host != "localhost") throw "host error";
        if (c.port != 8080) throw "port error";
        if (c.debug != true) throw "debug error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
  });

  group('Class Fields - Application Tests', () {
    test('Counter class with field', () {
      final source = '''
        class Counter {
          var count = 0;
          
          fn increment() {
            this.count = this.count + 1;
          }
          
          fn decrement() {
            this.count = this.count - 1;
          }
        }
        
        var c = Counter();
        c.increment();
        c.increment();
        c.increment();
        if (c.count != 3) throw "Expected 3";
        c.decrement();
        if (c.count != 2) throw "Expected 2";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('User model with fields and constructor', () {
      final source = '''
        class User {
          var id = 0;
          var name = "Guest";
          var isActive = false;
          
          fn init(userId, userName) {
            this.id = userId;
            this.name = userName;
            this.isActive = true;
          }
          
          fn deactivate() {
            this.isActive = false;
          }
        }
        
        var u = User(123, "Alice");
        if (u.id != 123) throw "id error";
        if (u.name != "Alice") throw "name error";
        if (u.isActive != true) throw "active error";
        
        u.deactivate();
        if (u.isActive != false) throw "deactivate error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Stack data structure with field', () {
      final source = '''
        class Stack {
          var items = [];
          
          fn push(item) {
            this.items = this.items + [item];
          }
          
          fn size() {
            return len(this.items);
          }
        }
        
        var s = Stack();
        s.push(1);
        s.push(2);
        s.push(3);
        if (s.size() != 3) throw "size error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Calculator with state field', () {
      final source = '''
        class Calculator {
          var result = 0;
          
          fn add(n) {
            this.result = this.result + n;
            return this;
          }
          
          fn sub(n) {
            this.result = this.result - n;
            return this;
          }
          
          fn mul(n) {
            this.result = this.result * n;
            return this;
          }
        }
        
        var calc = Calculator();
        calc.add(10).add(5).mul(2);
        if (calc.result != 30) throw "calc error: expected 30, got " + calc.result;
      ''';
      expect(run(source), InterpretResult.ok);
    });
  });

  group('Class Fields - Edge Cases', () {
    test('Field with expression initializer', () {
      final source = '''
        class Math {
          var pi = 3.14159;
          var doublepi = 3.14159 * 2;
        }
        var m = Math();
        if (m.doublepi < 6.28) throw "doublepi error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Field with list initializer', () {
      final source = '''
        class Container {
          var data = [1, 2, 3];
        }
        var c = Container();
        if (len(c.data) != 3) throw "len error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Field with map initializer', () {
      final source = '''
        class Settings {
          var config = {"theme": "dark", "fontSize": 14};
        }
        var s = Settings();
        if (s.config["theme"] != "dark") throw "theme error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Multiple instances have independent fields', () {
      final source = '''
        class Counter {
          var count = 0;
          fn inc() { this.count = this.count + 1; }
        }
        
        var a = Counter();
        var b = Counter();
        
        a.inc();
        a.inc();
        b.inc();
        
        if (a.count != 2) throw "a.count error";
        if (b.count != 1) throw "b.count error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Field overwritten in init', () {
      final source = '''
        class Wrapper {
          var value = "default";
          
          fn init(v) {
            this.value = v;
          }
        }
        
        var w = Wrapper("custom");
        if (w.value != "custom") throw "value error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Class with only fields (no methods)', () {
      final source = '''
        class Point {
          var x = 0;
          var y = 0;
        }
        var p = Point();
        p.x = 5;
        p.y = 10;
        if (p.x != 5) throw "x error";
        if (p.y != 10) throw "y error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Class with only init (no declared fields)', () {
      final source = '''
        class Dynamic {
          fn init(a, b) {
            this.a = a;
            this.b = b;
          }
        }
        var d = Dynamic(10, 20);
        if (d.a != 10) throw "a error";
        if (d.b != 20) throw "b error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Field with nil initializer', () {
      final source = '''
        class Nullable {
          var value = nil;
        }
        var n = Nullable();
        if (n.value != nil) throw "nil error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Field with boolean initializer', () {
      final source = '''
        class Flags {
          var enabled = true;
          var visible = false;
        }
        var f = Flags();
        if (f.enabled != true) throw "enabled error";
        if (f.visible != false) throw "visible error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Field accessing another field in method', () {
      final source = '''
        class Rectangle {
          var width = 10;
          var height = 5;
          
          fn area() {
            return this.width * this.height;
          }
        }
        var r = Rectangle();
        if (r.area() != 50) throw "area error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Chained field access after construction', () {
      final source = '''
        class Node {
          var value = 0;
          var next = nil;
          
          fn init(v) {
            this.value = v;
          }
        }
        
        var n1 = Node(1);
        var n2 = Node(2);
        n1.next = n2;
        
        if (n1.next.value != 2) throw "chain error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
  });
  
  group('Class Fields - Stress Tests', () {
    test('Many fields', () {
      final source = '''
        class BigClass {
          var a = 1;
          var b = 2;
          var c = 3;
          var d = 4;
          var e = 5;
          var f = 6;
          var g = 7;
          var h = 8;
          var i = 9;
          var j = 10;
        }
        var bc = BigClass();
        var sum = bc.a + bc.b + bc.c + bc.d + bc.e + bc.f + bc.g + bc.h + bc.i + bc.j;
        if (sum != 55) throw "sum error: " + str(sum);
      ''';
      expect(run(source), InterpretResult.ok);
    });
    
    test('Nested object creation', () {
      final source = '''
        class Inner {
          var value = 42;
        }
        
        class Outer {
          var inner = nil;
          
          fn init() {
            this.inner = Inner();
          }
        }
        
        var o = Outer();
        if (o.inner.value != 42) throw "nested error";
      ''';
      expect(run(source), InterpretResult.ok);
    });
  });
}
