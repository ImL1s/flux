/// Flux Language - Parser
/// 
/// Converts a stream of tokens into an Abstract Syntax Tree (AST).

import 'token.dart';

import 'ast.dart';

/// Parse error exception
class ParseError implements Exception {
  final String message;
  final Token token;

  ParseError(this.message, this.token);

  @override
  String toString() => '$message at ${token.line}:${token.column}';
}

/// Parser for the Flux language
class Parser {
  final List<Token> _tokens;
  final List<ParseError> errors = [];
  int _current = 0;

  Parser(this._tokens);

  /// Parse the tokens into a list of declarations (compilation unit)

  CompilationUnit parse() {
    final statements = <Statement>[];
    while (!_isAtEnd) {
      try {
        statements.add(_declaration());
      } catch (e) {
        _synchronize();
      }
    }
    return CompilationUnit(statements, line: 1, column: 1);
  }

  // ==========================================================================
  // Declarations
  // ==========================================================================

  Statement _declaration() {
    if (_match(TokenType.fn)) {
      if (_check(TokenType.identifier) && _current + 1 < _tokens.length && _tokens[_current + 1].type == TokenType.identifier) {
        return _functionDeclaration(false);
      }
      return _functionDeclaration(false);
    }
    if (_match(TokenType.async_)) {
      _consume(TokenType.fn, 'Expect "fn" after "async".');
      return _functionDeclaration(true);
    }
    if (_match(TokenType.widget)) return _widgetDeclaration();
    if (_match(TokenType.class_)) return _classDeclaration();
    if (_match(TokenType.import_)) return _importDeclaration();
    if (_match(TokenType.var_) || _match(TokenType.let_)) return _varDeclaration();
    
    return _statement();
  }

  FunctionDecl _functionDeclaration(bool isAsync) {
    final name = _consume(TokenType.identifier, 'Expect function name.').lexeme;
    
    _consume(TokenType.leftParen, 'Expect "(" after function name.');
    final parameters = <Parameter>[];
    if (!_check(TokenType.rightParen)) {
      do {
        if (parameters.length >= 255) {
          _error(_peek, 'Can\'t have more than 255 parameters.');
        }
        
        final paramName = _consume(TokenType.identifier, 'Expect parameter name.').lexeme;
        String? type;
        if (_match(TokenType.colon)) {
           // Simple type parsing for now (just identifiers)
           type = _consume(TokenType.identifier, 'Expect parameter type.').lexeme;
        }

        Expression? defaultValue;
        if (_match(TokenType.equal)) {
          defaultValue = _expression();
        }

        parameters.add(Parameter(paramName, type: type, defaultValue: defaultValue));
      } while (_match(TokenType.comma));
    }
    _consume(TokenType.rightParen, 'Expect ")" after parameters.');

    String? returnType;
    if (_match(TokenType.arrow)) {
       returnType = _consume(TokenType.identifier, 'Expect return type.').lexeme;
    }

    _consume(TokenType.leftBrace, 'Expect "{" before function body.');
    final body = _block();

    return FunctionDecl(name, parameters, body, 
        returnType: returnType, isAsync: isAsync, line: _peek.line, column: _peek.column);
  }

  WidgetDecl _widgetDeclaration() {
    final name = _consume(TokenType.identifier, 'Expect widget name.').lexeme;
    _consume(TokenType.leftBrace, 'Expect "{" before widget body.');

    final props = <Parameter>[];
    final stateFields = <StateField>[];
    BuildBlock? buildBlock;

    while (!_check(TokenType.rightBrace) && !_isAtEnd) {
      if (_match(TokenType.state)) {
        // State field: state count = 0
        final fieldName = _consume(TokenType.identifier, 'Expect state variable name.').lexeme;
        String? type;
         if (_match(TokenType.colon)) {
           type = _consume(TokenType.identifier, 'Expect state type.').lexeme;
        }
        _consume(TokenType.equal, 'State fields must be initialized.');
        final initializer = _expression();
        _match(TokenType.semicolon); // Optional semicolon
        stateFields.add(StateField(fieldName, initializer, type: type));
      } else if (_match(TokenType.build)) {
        // Build block: build { ... }
        _consume(TokenType.leftBrace, 'Expect "{" after "build".');
        // The body of build is a single expression (usually a Widget constructor call)
        // that matches the DSL syntax like Column { ... }
        // For simplicity in parser, we parse it as an expression.
        final expr = _expression();
        _consume(TokenType.rightBrace, 'Expect "}" after build body.');
        if (buildBlock != null) {
          _error(_previous, 'Widget can only have one build block.');
        }
        buildBlock = BuildBlock(expr);
      } else if (_match(TokenType.semicolon)) {
          // Ignore stray semicolons
      } else {
        // Assuming it's a prop or helper method? 
        // For minimal MVP, let's just error or skip.
        // Or maybe props are defined in the head?
        // spec: widget Counter { ... }
        // Let's assume props might be passed in constructor syntax later, 
        // but for now let's just ignore other things or error.
        throw _error(_peek, 'Unexpected token in widget declaration.');
      }
    }
    _consume(TokenType.rightBrace, 'Expect "}" after widget body.');

    if (buildBlock == null) {
      throw _error(_previous, 'Widget must have a build block.');
    }

    return WidgetDecl(name, props, stateFields, buildBlock, line: _peek.line, column: _peek.column);
  }

  ClassDecl _classDeclaration() {
    final name = _consume(TokenType.identifier, 'Expect class name.').lexeme;
    
    String? superclass;
    if (_match(TokenType.extends_)) {
      superclass = _consume(TokenType.identifier, 'Expect superclass name.').lexeme;
    }

    // implements ...

    _consume(TokenType.leftBrace, 'Expect "{" before class body.');
    final members = <Declaration>[];
    while (!_check(TokenType.rightBrace) && !_isAtEnd) {
      // Parse methods, fields
      if (_match(TokenType.fn)) {
         members.add(_functionDeclaration(false)); // Methods look like functions
      } else if (_match(TokenType.async_)) {
         _consume(TokenType.fn, 'Expect "fn" after "async".');
         members.add(_functionDeclaration(true));
      } else {
        // Fields? 
        // var x = 1;
        // For now, only methods.
        _advance();
      }
    }
    _consume(TokenType.rightBrace, 'Expect "}" after class body.');

    return ClassDecl(name, members, superclass: superclass, line: _peek.line, column: _peek.column);
  }

  ImportDecl _importDeclaration() {
    final pathToken = _consume(TokenType.string, 'Expect import path.');
    final path = pathToken.literal as String;
    // ... alias, show, hide logic
    _consume(TokenType.semicolon, 'Expect ";" after import.');
    return ImportDecl(path, line: pathToken.line, column: pathToken.column);
  }

  // ==========================================================================
  // Statements
  // ==========================================================================

  Statement _statement() {
    if (_match(TokenType.if_)) return _ifStatement();
    if (_match(TokenType.for_)) return _forStatement();
    if (_match(TokenType.while_)) return _whileStatement();
    if (_match(TokenType.return_)) return _returnStatement();
    if (_match(TokenType.leftBrace)) return _block();
    if (_match(TokenType.fn)) return _functionDeclaration(false);
    if (_match(TokenType.async_)) {
      _consume(TokenType.fn, 'Expect "fn" after "async".');
      return _functionDeclaration(true);
    }
    if (_match(TokenType.var_) || _match(TokenType.let_)) return _varDeclaration();
    if (_match(TokenType.try_)) return _tryStatement();
    if (_match(TokenType.throw_)) return _throwStatement();

    return _expressionStatement();
  }
  
  Statement _tryStatement() {
    final line = _previous.line;
    final column = _previous.column;
    
    // Parse try block
    _consume(TokenType.leftBrace, 'Expect "{" after "try".');
    final tryBlock = _block();
    
    // Parse optional catch block
    String? catchVariable;
    Statement? catchBlock;
    if (_match(TokenType.catch_)) {
      _consume(TokenType.leftParen, 'Expect "(" after "catch".');
      catchVariable = _consume(TokenType.identifier, 'Expect exception variable name.').lexeme;
      _consume(TokenType.rightParen, 'Expect ")" after exception variable.');
      _consume(TokenType.leftBrace, 'Expect "{" after catch clause.');
      catchBlock = _block();
    }
    
    // Parse optional finally block
    Statement? finallyBlock;
    if (_match(TokenType.finally_)) {
      _consume(TokenType.leftBrace, 'Expect "{" after "finally".');
      finallyBlock = _block();
    }
    
    // Must have at least catch or finally
    if (catchBlock == null && finallyBlock == null) {
      throw _error(_peek, 'Try statement must have catch or finally block.');
    }
    
    return TryStmt(tryBlock,
      catchVariable: catchVariable,
      catchBlock: catchBlock,
      finallyBlock: finallyBlock,
      line: line,
      column: column,
    );
  }
  
  Statement _throwStatement() {
    final keyword = _previous;
    final value = _expression();
    _consume(TokenType.semicolon, 'Expect ";" after throw value.');
    return ThrowStmt(value, line: keyword.line, column: keyword.column);
  }

  BlockStmt _block() {
    final statements = <Statement>[];
    while (!_check(TokenType.rightBrace) && !_isAtEnd) {
      statements.add(_statement());
    }
    _consume(TokenType.rightBrace, 'Expect "}" after block.');
    return BlockStmt(statements, line: _peek.line, column: _peek.column);
  }

  Statement _ifStatement() {
    _consume(TokenType.leftParen, 'Expect "(" after "if".');
    final condition = _expression();
    _consume(TokenType.rightParen, 'Expect ")" after if condition.');

    final thenBranch = _statement();
    Statement? elseBranch;
    if (_match(TokenType.else_)) {
      elseBranch = _statement();
    }

    return IfStmt(condition, thenBranch, elseBranch, line: _peek.line, column: _peek.column);
  }

  Statement _whileStatement() {
    _consume(TokenType.leftParen, 'Expect "(" after "while".');
    final condition = _expression();
    _consume(TokenType.rightParen, 'Expect ")" after while condition.');
    final body = _statement();

    return WhileStmt(condition, body, line: _peek.line, column: _peek.column);
  }

  Statement _forStatement() {
    _consume(TokenType.leftParen, 'Expect "(" after "for".');

    // Initializer
    Statement? initializer;
    if (_match(TokenType.semicolon)) {
      initializer = null;
    } else if (_match(TokenType.var_) || _match(TokenType.let_)) {
      initializer = _varDeclaration();
    } else {
      initializer = _expressionStatement();
    }

    // Condition
    Expression? condition;
    if (!_check(TokenType.semicolon)) {
      condition = _expression();
    }
    _consume(TokenType.semicolon, 'Expect ";" after loop condition.');

    // Increment
    Expression? increment;
    if (!_check(TokenType.rightParen)) {
      increment = _expression();
    }
    _consume(TokenType.rightParen, 'Expect ")" after for clauses.');

    Statement body = _statement();

    return ForStmt(initializer, condition, increment, body, line: _peek.line, column: _peek.column);
  }

  Statement _returnStatement() {
    final keyword = _previous;
    Expression? value;
    if (!_check(TokenType.semicolon)) {
      value = _expression();
    }
    _consume(TokenType.semicolon, 'Expect ";" after return value.');
    return ReturnStmt(value, line: keyword.line, column: keyword.column);
  }

  Statement _varDeclaration() {
    final keyword = _previous;
    final isMutable = keyword.type == TokenType.var_;
    
    final name = _consume(TokenType.identifier, 'Expect variable name.').lexeme;
    
    String? type;
    if (_match(TokenType.colon)) {
      type = _consume(TokenType.identifier, 'Expect variable type.').lexeme;
    }

    Expression? initializer;
    if (_match(TokenType.equal)) {
      initializer = _expression();
    }

    _match(TokenType.semicolon); // Optional semicolon
    return VarDeclStmt(name, type: type, initializer: initializer, isMutable: isMutable, line: keyword.line, column: keyword.column);
  }

  Statement _expressionStatement() {
    final expr = _expression();
    _match(TokenType.semicolon); // Optional semicolon
    return ExpressionStmt(expr, line: expr.line, column: expr.column);
  }

  // ==========================================================================
  // Expressions
  // ==========================================================================

  Expression _expression() {
    return _assignment();
  }

  Expression _assignment() {
    final expr = _or();

    if (_match(TokenType.equal)) {
      final equals = _previous;
      final value = _assignment();

      if (expr is VariableExpr) {
        return AssignExpr(expr.name, value, line: equals.line, column: equals.column);
      } else if (expr is GetExpr) {
        return SetExpr(expr.object, expr.name, value, line: equals.line, column: equals.column);
      } else if (expr is IndexExpr) {
        return IndexAssignExpr(expr.object, expr.index, value, line: equals.line, column: equals.column);
      }

      throw _error(equals, 'Invalid assignment target.');
    }
    
    // +=, -= ...

    return expr;
  }

  Expression _or() {
    var expr = _and();
    while (_match(TokenType.or)) {
      final operator = _previous;
      final right = _and();
      expr = BinaryExpr(expr, operator, right, line: operator.line, column: operator.column);
    }
    return expr;
  }

  Expression _and() {
    var expr = _equality();
    while (_match(TokenType.and)) {
      final operator = _previous;
      final right = _equality();
      expr = BinaryExpr(expr, operator, right, line: operator.line, column: operator.column);
    }
    return expr;
  }

  Expression _equality() {
    var expr = _comparison();
    while (_match(TokenType.equalEqual) || _match(TokenType.notEqual)) {
      final operator = _previous;
      final right = _comparison();
      expr = BinaryExpr(expr, operator, right, line: operator.line, column: operator.column);
    }
    return expr;
  }

  Expression _comparison() {
    var expr = _term();
    while (_match(TokenType.greater) || _match(TokenType.greaterEqual) ||
           _match(TokenType.less) || _match(TokenType.lessEqual)) {
      final operator = _previous;
      final right = _term();
      expr = BinaryExpr(expr, operator, right, line: operator.line, column: operator.column);
    }
    return expr;
  }

  Expression _term() {
    var expr = _factor();
    while (_match(TokenType.minus) || _match(TokenType.plus)) {
      final operator = _previous;
      final right = _factor();
      expr = BinaryExpr(expr, operator, right, line: operator.line, column: operator.column);
    }
    return expr;
  }

  Expression _factor() {
    var expr = _unary();
    while (_match(TokenType.slash) || _match(TokenType.star) || _match(TokenType.percent)) {
      final operator = _previous;
      final right = _unary();
      expr = BinaryExpr(expr, operator, right, line: operator.line, column: operator.column);
    }
    return expr;
  }

  Expression _unary() {
    if (_match(TokenType.not) || _match(TokenType.minus)) {
      final operator = _previous;
      final right = _unary();
      return UnaryExpr(operator, right, line: operator.line, column: operator.column);
    }
    return _await();
  }
  
  Expression _await() {
    if (_match(TokenType.await_)) {
      final keyword = _previous;
      final expr = _unary(); // Right associativity? await await x
      return AwaitExpr(expr, line: keyword.line, column: keyword.column);
    }
    return _call();
  }

  Expression _call() {
    var expr = _primary();

    while (true) {
      if (_match(TokenType.leftParen)) {
        expr = _finishCall(expr);
      } else if (_match(TokenType.dot)) {
        final name = _consume(TokenType.identifier, 'Expect property name after ".".');
        expr = GetExpr(expr, name.lexeme, line: name.line, column: name.column);
      } else if (_match(TokenType.leftBrace)) {
         // DSL syntax: Column { ... } => CallExpr(Column, [child1, child2])
         final brace = _previous;
         final statements = <Statement>[];
         while (!_check(TokenType.rightBrace) && !_isAtEnd) {
           statements.add(_statement());
         }
         _consume(TokenType.rightBrace, 'Expect "}" after widget block.');
         
         final args = <Expression>[];
         for (final stmt in statements) {
           if (stmt is ExpressionStmt) {
             args.add(stmt.expression);
           } else {
             // Ignore non-expression statements or handle them?
             // For simple DSL, we ignore logic statements or treat them as valid logic building logic?
             // But CallExpr arguments must be Expressions.
             // If we have `if` inside Column, it should be an expression (ConditionalExpr) or flow.
             // We can't put `IfStmt` in `CallExpr` args.
             // So strict DSL: only expressions allowed in Widget blocks.
           }
         }
         
         expr = CallExpr(expr, args, line: brace.line, column: brace.column);
      } else if (_match(TokenType.leftBracket)) {
        // Index access: list[0], map["key"]
        final bracket = _previous;
        final index = _expression();
        _consume(TokenType.rightBracket, 'Expect "]" after index.');
        expr = IndexExpr(expr, index, line: bracket.line, column: bracket.column);
      } else {
        break;
      }
    }

    return expr;
  }

  Expression _finishCall(Expression callee) {
    final arguments = <Expression>[];
    if (!_check(TokenType.rightParen)) {
      do {
        if (arguments.length >= 255) {
          _error(_peek, 'Can\'t have more than 255 arguments.');
        }
        arguments.add(_expression());
      } while (_match(TokenType.comma));
    }
    final paren = _consume(TokenType.rightParen, 'Expect ")" after arguments.');

    // Trailing lambda? `Button("Click") { ... }`
    if (_match(TokenType.leftBrace)) {
        // Parse block
        final block = _block();
        // Convert block to LambdaExpr
        final lambda = LambdaExpr([], block, line: block.line, column: block.column);
        arguments.add(lambda);
    }

    return CallExpr(callee, arguments, line: paren.line, column: paren.column);
  }

  Expression _primary() {
    if (_match(TokenType.false_)) return LiteralExpr(false, line: _previous.line, column: _previous.column);
    if (_match(TokenType.true_)) return LiteralExpr(true, line: _previous.line, column: _previous.column);
    if (_match(TokenType.null_)) return LiteralExpr(null, line: _previous.line, column: _previous.column);

    if (_match(TokenType.integer)) return LiteralExpr(_previous.literal, line: _previous.line, column: _previous.column);
    if (_match(TokenType.double_)) return LiteralExpr(_previous.literal, line: _previous.line, column: _previous.column);
    if (_match(TokenType.string)) return LiteralExpr(_previous.literal, line: _previous.line, column: _previous.column);
    if (_match(TokenType.interpolationStart)) return _finishInterpolation();

    if (_match(TokenType.identifier)) {
      return VariableExpr(_previous.lexeme, line: _previous.line, column: _previous.column);
    }

    if (_match(TokenType.leftParen)) {
      final expr = _expression();
      _consume(TokenType.rightParen, 'Expect ")" after expression.');
      return GroupingExpr(expr, line: _previous.line, column: _previous.column);
    }

    if (_match(TokenType.leftBracket)) {
      // List literal
      final elements = <Expression>[];
      if (!_check(TokenType.rightBracket)) {
        do {
          elements.add(_expression());
        } while (_match(TokenType.comma));
      }
      final end = _consume(TokenType.rightBracket, 'Expect "]" after list elements.');
      return ListExpr(elements, line: end.line, column: end.column);
    }
    
    // Anonymous lambda: fn() { ... } or fn(a, b) { ... }
    if (_match(TokenType.fn)) {
      return _lambdaExpression();
    }

    throw _error(_peek, 'Expect expression.');
  }
  
  /// Parse anonymous lambda: fn(params) { body }
  Expression _lambdaExpression() {
    final fnToken = _previous;
    
    // Parse parameters
    _consume(TokenType.leftParen, 'Expect "(" after "fn".');
    final parameters = <Parameter>[];
    if (!_check(TokenType.rightParen)) {
      do {
        if (parameters.length >= 255) {
          _error(_peek, 'Can\'t have more than 255 parameters.');
        }
        
        final paramName = _consume(TokenType.identifier, 'Expect parameter name.').lexeme;
        String? type;
        if (_match(TokenType.colon)) {
          type = _consume(TokenType.identifier, 'Expect parameter type.').lexeme;
        }
        
        parameters.add(Parameter(paramName, type: type));
      } while (_match(TokenType.comma));
    }
    _consume(TokenType.rightParen, 'Expect ")" after parameters.');
    
    // Parse body
    _consume(TokenType.leftBrace, 'Expect "{" before lambda body.');
    final body = _block();
    
    return LambdaExpr(parameters, body, line: fnToken.line, column: fnToken.column);
  }
  
  Expression _finishInterpolation() {
      // already consumed ${
      // parse expression
      final expr = _expression();
      _consume(TokenType.rightBrace, 'Expect "}" after interpolation.');
      // This logic is simplified. Real String interpolation is complex in Lexer.
      // Our Lexer produces: STRING("Hello "), INTERPOLATION_START, ...
      // Parsing this requires the parser to know it's inside a string.
      // But for this simple implementation, let's assume standard handling.
      // Actually, AST for InterpolationExpr expects list of parts.
      // But _primary returns single Expression.
      return expr; 
  }

  // ==========================================================================
  // Helpers
  // ==========================================================================

  bool _match(TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek.type == type;
  }

  Token _advance() {
    if (!_isAtEnd) _current++;
    return _previous;
  }

  bool get _isAtEnd => _peek.type == TokenType.eof;

  Token get _peek => _tokens[_current];

  Token get _previous => _tokens[_current - 1];

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw _error(_peek, message);
  }

  ParseError _error(Token token, String message) {
    final error = ParseError(message, token);
    errors.add(error);
    return error;
  }

  void _synchronize() {
    // If the current token is a statement starter, we don't need to skip it.
    // However, if we just errored, we might need to discard SOMETHING.
    // But if the error was "missing semicolon" and we are at "var", 
    // we logically just finished the previous statement.
    
    // Check if we are already at a detailed sync point
    switch (_peek.type) {
        case TokenType.class_:
        case TokenType.fn:
        case TokenType.var_:
        case TokenType.for_:
        case TokenType.if_:
        case TokenType.while_:
        case TokenType.return_:
        case TokenType.widget:
        case TokenType.import_:
          return;
        default:
    }

    _advance();

    while (!_isAtEnd) {
      if (_previous.type == TokenType.semicolon) return;

      switch (_peek.type) {
        case TokenType.class_:
        case TokenType.fn:
        case TokenType.var_:
        case TokenType.for_:
        case TokenType.if_:
        case TokenType.while_:
        case TokenType.return_:
        case TokenType.widget:
        case TokenType.import_:
          return;
        default:
      }

      _advance();
    }
  }
}
