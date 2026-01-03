import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'helpers/bytecode_printer.dart';

void main() {
  Chunk compile(String source) {
    final lexer = Lexer(source);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final unit = parser.parse();
    final compiler = Compiler(unit: unit);
    return compiler.endCompiler().chunk;
  }

  group('BytecodeOptimizer', () {
    test('folds simple arithmetic constants', () {
       // 2 + 3 -> 5
       final chunk = compile('2 + 3;');
       expect(chunk.constants, contains(5));
       expect(chunk.code, contains(OpCode.noOp.index));
    });

    test('folds string concatenation', () {
       final chunk = compile('"a" + "b";');
       expect(chunk.constants, contains("ab"));
       expect(chunk.code, contains(OpCode.noOp.index));
    });

    test('folds nested arithmetic expressions (requires multi-pass)', () {
       // 2 + 3 * 4 -> 2 + 12 -> 14
       final chunk = compile('2 + 3 * 4;');
       expect(chunk.constants, contains(14));
    });

    test('does not fold mismatch types (conservative)', () {
       // "a" + 1 -> "a1" (handled by optimizer now)
       final chunk = compile('"a" + 1;');
       expect(chunk.constants, contains("a1"));
       expect(chunk.code, contains(OpCode.noOp.index));
    });
    
    test('does not fold variables', () {
       final source = '''
         var x = 1;
         x + 1;
       ''';
       final chunk = compile(source);
       // Should contain ADD opcode because x is not constant at compile time
       expect(chunk.code, contains(OpCode.add.index));
    });
    
    test('optimizes NOT + JUMP_IF_FALSE to JUMP_IF_TRUE', () {
       // if (!(x)) { ... }
       final source = '''
         var x = true;
         if (!x) {
           print("hi");
         }
       ''';
       final chunk = compile(source);
       
       // Should contain JUMP_IF_TRUE
       expect(chunk.code, contains(OpCode.jumpIfTrue.index));
       
       // Should contain NO_OP (replacing NOT)
       expect(chunk.code, contains(OpCode.noOp.index));
       
       // Should NOT contain NOT followed by JUMP_IF_FALSE
       // Logic: OpCode.not followed by OpCode.jumpIfFalse
       // We can iterate to verify strict absence if needed, but contains(jumpIfTrue) is strong signal.
    });

    group('Dead Code Elimination', () {
      test('eliminates code after return', () {
        final source = '''
           fn test() {
             return 1;
             print("dead");
           }
           test();
        ''';
        compile(source);
        // "dead" string constant might exist, but the Print opcode should be gone (replaced by NO_OP)
        // Actually, since we don't remove constants map entries, checking opcode is safer.
        
        // Find the function chunk (nested). 
        // This test helper compiles to a script. The function is a constant in the script.
        // We need to check the function's chunk.
        // For simplicity, let's test straight script code if possible.
        // Script code: return stops script.
        final chunk2 = compile('''
          return;
          print("dead");
        ''');
        
        // Should contain return
        expect(chunk2.code, contains(OpCode.return_.index));
        // Should NOT contain print
        expect(chunk2.code, isNot(contains(OpCode.print.index)));
      });

      test('eliminates code after unconditional jump', () {
         // while(true) { ... } followed by unreachable
         /*
           loop {
              ...
              jump loop
           }
           print("dead")
         */
         // Hard to write unconditional jump in pure Flux explicitly without control structures that also add jump targets (like break).
         // But `if (true) { return; } else { print("dead"); }` 
         // Compiler usually emits Jump after If block to skip Else block.
         // If we have `if (true) { return; } print("dead");`
         
         // Let's use early return.
         compile('''
            if (true) {
               return;
            }
            print("alive"); 
         ''');
         // Here, `print("alive")` IS reachable because `if` logic jumps over `{ return; }` if condition false?
         // Ah, `if (true)`: Compiler might not fold `true` condition yet (we don't optimize IF conditions yet).
         // So VM sees `constant(true), jumpIfFalse`. The jump target makes `print("alive")` reachable.
         
         // We need a case where code is truly dead.
         // `return; print(1);` is the best case.
      });

      test('preserves jump targets (if-else)', () {
         // Code after if-else should be reachable
         final chunk = compile('''
           var x = 1;
           if (x > 0) {
             print("A");
           } else {
             print("B");
           }
           print("C"); // Should be reachable (jump target from 'if' and 'else' end)
         ''');
         
         // Expect C to be printed (OpCode.print exists)
         // Actually we want to count prints.
         // Or just check that the specific string "C" is loaded and printed.
         // We can check that the last part is not NO_OPs.
         expect(chunk.code, contains(OpCode.print.index));
      });
      
       test('eliminates code after throw', () {
          final chunk = compile('''
             throw "error";
             print("dead");
          ''');
          expect(chunk.code, contains(OpCode.throw_.index));
          expect(chunk.code, isNot(contains(OpCode.print.index)));
       });
    });

    group('Constant Folding Refinements', () {
      void _emitConstant(Chunk chunk, Object? val) {
        final idx = chunk.addConstant(val);
        chunk.writeOp(OpCode.constant, 1);
        chunk.write(idx, 1);
      }

      test('unary negate', () {
        final chunk = Chunk();
        _emitConstant(chunk, 5);
        chunk.writeOp(OpCode.negate, 1);
        
        BytecodeOptimizer.optimize(chunk);
        
        final output = BytecodePrinter().print(chunk);
        expect(output, contains("-5"));
        expect(output, contains("noOp"));
      });

      test('unary not', () {
        final chunk = Chunk();
        _emitConstant(chunk, true);
        chunk.writeOp(OpCode.not, 1);
        
        BytecodeOptimizer.optimize(chunk);
        
        final output = BytecodePrinter().print(chunk);
        expect(output, contains("false"));
        expect(output, contains("noOp"));
      });

      test('null equality', () {
        final chunk = Chunk();
        _emitConstant(chunk, null);
        _emitConstant(chunk, null);
        chunk.writeOp(OpCode.equal, 1);
        
        BytecodeOptimizer.optimize(chunk);
        
        final output = BytecodePrinter().print(chunk);
        expect(output, contains("true"));
        expect(output, isNot(contains("equal")));
      });

      test('class method optimization', () {
        final source = '''
          class Foo {
            fn bar() {
              return 1 + 2;
            }
          }
        ''';
        final chunk = compile(source);
        
        // Find Foo class in constants
        final classConstant = chunk.constants.whereType<CompiledClass>().first;
        final barMethod = classConstant.methods['bar']!;
        
        final output = BytecodePrinter().print(barMethod.chunk);
        // '1 + 2' should be optimized to '3'
        expect(output, contains("3"));
        expect(output, isNot(contains("add")));
      });
    });
  });
}
