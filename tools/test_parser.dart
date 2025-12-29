import 'dart:io';
import '../packages/flux_compiler/lib/flux_compiler.dart';

void main() {
  final file = File('examples/hello.flux');
  if (!file.existsSync()) {
    print('File not found: ${file.path}');
    return;
  }

  final source = file.readAsStringSync();
  print('--- Source ---');
  print(source);
  print('\n--- Lexer ---');

  final lexer = Lexer(source);
  final tokens = lexer.tokenize();

  for (final token in tokens) {
    print(token);
  }

  if (lexer.errors.isNotEmpty) {
    print('\nLexer errors:');
    for (final error in lexer.errors) {
      print(error);
    }
    return;
  }

  print('\n--- Parser ---');
  final parser = Parser(tokens);
  try {
    final root = parser.parse();
    print('Parse successful!');
    
    if (root is BlockStmt) {
        print('Statements: ${root.statements.length}');
        for (final stmt in root.statements) {
          print(' - ${stmt.runtimeType}');
          if (stmt is FunctionDecl) {
            print('   Function: ${stmt.name}, Async: ${stmt.isAsync}');
          } else if (stmt is WidgetDecl) {
            print('   Widget: ${stmt.name}');
          } else if (stmt is VarDeclStmt) {
            print('   Var: ${stmt.name}');
          }
        }
    }

  } catch (e) {
    print('Parse error: $e');
    for (final error in parser.errors) {
      print(error);
    }
  }
}
