import 'package:flux_compiler/flux_compiler.dart';
import 'protocol.dart';

/// Represents a source code location
class ParsedLocation {
  final int line; // 0-indexed
  final int column; // 0-indexed
  final int length;

  ParsedLocation(this.line, this.column, this.length);

  Range toRange() {
    return Range(
      Position(line, column),
      Position(line, column + length),
    );
  }
}

/// A symbol definition (variable, function, parameter)
class Symbol {
  final String name;
  final ParsedLocation location;
  final String kind; // 'var', 'fn', 'param', 'widget', 'prop', 'state'

  Symbol(this.name, this.location, this.kind);
}

/// A scope containing defined symbols
class Scope {
  final Scope? parent;
  final Map<String, Symbol> symbols = {};

  Scope(this.parent);

  void define(Symbol symbol) {
    symbols[symbol.name] = symbol;
  }

  Symbol? resolve(String name) {
    if (symbols.containsKey(name)) {
      return symbols[name];
    }
    return parent?.resolve(name);
  }
}

/// Result of scope analysis
class ScopeAnalysisResult {
  /// Map from usage location (line, col) to definition symbol
  final Map<ParsedLocation, Symbol> usages = {};

  /// All definitions found
  final List<Symbol> definitions = [];

  void addUsage(ParsedLocation outputLoc, Symbol definition) {
    usages[outputLoc] = definition;
  }

  void addDefinition(Symbol symbol) {
    definitions.add(symbol);
  }
}

/// Visitor that builds scope tree and resolves references
class ScopeAnalyzer {
  final ScopeAnalysisResult result = ScopeAnalysisResult();
  Scope _currentScope = Scope(null);

  void analyze(CompilationUnit unit) {
    _enterScope(); // Global scope
    for (final stmt in unit.declarations) {
      _visitStmt(stmt);
    }
    _exitScope();
  }

  void _enterScope() {
    _currentScope = Scope(_currentScope);
  }

  void _exitScope() {
    if (_currentScope.parent != null) {
      _currentScope = _currentScope.parent!;
    }
  }

  void _define(String name, int line, int col, String kind) {
    // Flux AST line/col are 1-based, convert to 0-based
    final loc = ParsedLocation(line - 1, col - 1, name.length);
    final symbol = Symbol(name, loc, kind);
    _currentScope.define(symbol);
    result.addDefinition(symbol);
  }

  Symbol? _resolve(String name) {
    return _currentScope.resolve(name);
  }

  void _recordUsage(String name, int line, int col) {
    final symbol = _resolve(name);
    if (symbol != null) {
      final loc = ParsedLocation(line - 1, col - 1, name.length);
      result.addUsage(loc, symbol);
    }
  }

  // --- Visitors ---

  void _visitDeclaration(Declaration decl) {
    if (decl is FunctionDecl) {
      _visitFunctionDecl(decl);
    } else if (decl is ClassDecl) {
      _visitClassDecl(decl);
    } else if (decl is WidgetDecl) {
      _visitWidgetDecl(decl);
    }
  }

  void _visitStmt(Statement stmt) {
    if (stmt is Declaration) {
      _visitDeclaration(stmt);
    } else if (stmt is VarDeclStmt) {
      _visitVarDecl(stmt);
    } else if (stmt is ExpressionStmt) {
      _visitExpression(stmt.expression);
    } else if (stmt is BlockStmt) {
      _visitBlock(stmt);
    } else if (stmt is IfStmt) {
      _visitIf(stmt);
    } else if (stmt is WhileStmt) {
      _visitWhile(stmt);
    } else if (stmt is ForStmt) {
      _visitFor(stmt);
    } else if (stmt is ReturnStmt) {
      if (stmt.value != null) _visitExpression(stmt.value!);
    }
  }

  void _visitVarDecl(VarDeclStmt stmt) {
    if (stmt.initializer != null) {
      _visitExpression(stmt.initializer!);
    }
    _define(stmt.name, stmt.nameLine ?? stmt.line,
        stmt.nameColumn ?? stmt.column, 'var');
  }

  void _visitFunctionDecl(FunctionDecl stmt) {
    _define(stmt.name, stmt.nameLine ?? stmt.line,
        stmt.nameColumn ?? stmt.column, 'fn');
    _enterScope();
    for (final param in stmt.parameters) {
      _define(param.name, param.line ?? stmt.line, param.column ?? stmt.column,
          'param');
    }
    // Manually visit body statements to keep same scope
    for (final s in stmt.body.statements) {
      _visitStmt(s);
    }
    _exitScope();
  }

  void _visitBlock(BlockStmt stmt) {
    _enterScope();
    for (final s in stmt.statements) {
      _visitStmt(s);
    }
    _exitScope();
  }

  void _visitIf(IfStmt stmt) {
    _visitExpression(stmt.condition);
    _visitStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) {
      _visitStmt(stmt.elseBranch!);
    }
  }

  void _visitWhile(WhileStmt stmt) {
    _visitExpression(stmt.condition);
    _visitStmt(stmt.body);
  }

  void _visitFor(ForStmt stmt) {
    _enterScope();
    if (stmt.initializer != null) _visitStmt(stmt.initializer!);
    if (stmt.condition != null) _visitExpression(stmt.condition!);
    if (stmt.increment != null) _visitExpression(stmt.increment!);
    _visitStmt(stmt.body);
    _exitScope();
  }

  void _visitWidgetDecl(WidgetDecl stmt) {
    _define(stmt.name, stmt.nameLine ?? stmt.line,
        stmt.nameColumn ?? stmt.column, 'widget');
    _enterScope();
    // Props
    for (final prop in stmt.props) {
      _define(prop.name, prop.line ?? stmt.line, prop.column ?? stmt.column,
          'prop');
    }
    // State
    for (final field in stmt.stateFields) {
      _visitExpression(field.initialValue);
      _define(field.name, field.line ?? stmt.line, field.column ?? stmt.column,
          'state');
    }
    // Build
    _visitExpression(stmt.buildBlock.body);
    _exitScope();
  }

  void _visitClassDecl(ClassDecl stmt) {
    _define(stmt.name, stmt.nameLine ?? stmt.line,
        stmt.nameColumn ?? stmt.column, 'class');
    _enterScope();
    for (final member in stmt.members) {
      _visitDeclaration(member);
    }
    _exitScope();
  }

  void _visitExpression(Expression expr) {
    if (expr is VariableExpr) {
      _recordUsage(expr.name, expr.line, expr.column);
    } else if (expr is BinaryExpr) {
      _visitExpression(expr.left);
      _visitExpression(expr.right);
    } else if (expr is CallExpr) {
      _visitExpression(expr.callee);
      for (final arg in expr.arguments) _visitExpression(arg);
      for (final arg in expr.namedArguments.values) _visitExpression(arg);
    } else if (expr is AssignExpr) {
      _recordUsage(expr.name, expr.nameLine ?? expr.line,
          expr.nameColumn ?? expr.column);
      _visitExpression(expr.value);
    } else if (expr is LiteralExpr) {
      // no-op
    } else if (expr is GroupingExpr) {
      _visitExpression(expr.expression);
    } else if (expr is UnaryExpr) {
      _visitExpression(expr.operand);
    } else if (expr is GetExpr) {
      _visitExpression(expr.object);
    } else if (expr is SetExpr) {
      _visitExpression(expr.object);
      _recordUsage(expr.name, expr.nameLine ?? expr.line,
          expr.nameColumn ?? expr.column);
      _visitExpression(expr.value);
    } else if (expr is ListExpr) {
      for (final e in expr.elements) _visitExpression(e);
    } else if (expr is MapExpr) {
      for (final e in expr.entries) {
        _visitExpression(e.key);
        _visitExpression(e.value);
      }
    } else if (expr is ConditionalExpr) {
      _visitExpression(expr.condition);
      _visitExpression(expr.thenBranch);
      _visitExpression(expr.elseBranch);
    } else if (expr is LambdaExpr) {
      _enterScope();
      for (final param in expr.parameters) {
        _define(param.name, param.line ?? expr.line,
            param.column ?? expr.column, 'param');
      }
      if (expr.body is BlockStmt) {
        for (final s in (expr.body as BlockStmt).statements) _visitStmt(s);
      } else if (expr.body is Expression) {
        _visitExpression(expr.body as Expression);
      }
      _exitScope();
    }
    // Interpolation, Await, etc...
  }
}
