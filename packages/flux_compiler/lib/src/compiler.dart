/// Flux Language - Compiler
/// 
/// Compiles AST into Bytecode Chunks.

import 'ast.dart';
import 'token.dart';
import 'bytecode.dart';
import 'lexer.dart';
import 'parser.dart';
import 'optimizer.dart';
import 'source_map_generator.dart';

class Local {
  final String name;
  final int depth;
  bool isCaptured = false;
  Local(this.name, this.depth);
}

class CompilerUpvalue {
  final int index;
  final bool isLocal;
  CompilerUpvalue(this.index, this.isLocal);
}

/// Represents a compiled function or script
class CompiledFunction {
  final Chunk chunk;
  final String name;
  int arity;
  final bool isAsync;
  final String? moduleName;
  final List<String> paramNames;
  
  /// Debug info: names of local variables by slot index (index 0 is 'this' closure)
  List<String> localNames;
  
  CompiledFunction(this.name, this.chunk, {
    this.arity = 0, 
    this.isAsync = false, 
    this.moduleName, 
    this.paramNames = const [],
    List<String>? localNames,
    this.sourceMap,
  }) : localNames = localNames ?? [];

  /// Source Map v3 JSON string for this function's bytecode
  final String? sourceMap;
  
  @override
  String toString() => "<fn $name>";
}

/// Represents a Widget definition
class CompiledWidget {
    final String name;
    final CompiledFunction buildMethod;
    final List<String> stateFields;
    final List<CompiledFunction> stateInitializers;
    
    CompiledWidget(
      this.name, 
      this.buildMethod, {
      this.stateFields = const [],
      this.stateInitializers = const [],
    });
    
    @override
    String toString() => "<widget $name>";
}

/// Represents a Class definition
class CompiledClass {
    final String name;
    final Map<String, CompiledFunction> methods;
    final List<String> fields;
    final String? superclass;
    
    CompiledClass(
      this.name, {
      this.methods = const {},
      this.fields = const [],
      this.superclass,
    });
    
    @override
    String toString() => "<class $name>";
}

class Compiler {
  Chunk get chunk => _function.chunk;
  
  late CompiledFunction _function;
  Compiler? _enclosing;
  
  // Track enclosing TryStmts for return/break/continue handling
  final List<TryStmt> _enclosingTrys = [];
  
  final List<Local> _locals = [];
  final List<CompilerUpvalue> _upvalues = [];
  int _scopeDepth = 0;
  final String? _moduleName;
  
  /// State field names available in current widget context (for build method)
  List<String> _stateFields = [];
  
  SourceMapGenerator? _sourceMapGenerator;

  Compiler({CompilationUnit? unit, String? moduleName, bool generateSourceMap = false}) : _moduleName = moduleName {
      _function = CompiledFunction("script", Chunk(), moduleName: moduleName);
      
      if (generateSourceMap) {
        _sourceMapGenerator = SourceMapGenerator(file: moduleName ?? 'script');
        if (moduleName != null) {
          _sourceMapGenerator!.addSource(moduleName);
        }
      }
      
      // Reserve slot 0 for script closure
      _locals.add(Local("", 0));
      
      if (unit != null) {
          print('DEBUG COMPILER: Unit has ${unit.declarations.length} declarations');
          // compile everything
          for (final decl in unit.declarations) {
              print('DEBUG COMPILER: Compiling decl type: ${decl.runtimeType}');
              compile(decl);
          }
      }
  }
  
  // Internal constructor for inner functions
  Compiler._inner(this._enclosing, String name) : _moduleName = _enclosing?._moduleName {
      if (_enclosing?._sourceMapGenerator != null) {
        _sourceMapGenerator = SourceMapGenerator(file: _moduleName ?? 'script');
        // Copy sources/names or just add the file again (it handles dupes)
        if (_moduleName != null) _sourceMapGenerator!.addSource(_moduleName);
      }
      _function = CompiledFunction(name, Chunk(), moduleName: _moduleName);
  }

  /// Compiles a single expression in the context of specific local variables.
  /// 
  /// [source] is the expression to compile.
  /// [variableNames] is the list of local variables available in the scope,
  /// ordered by their stack slot index.
  void compile(Statement statement) {
    print('DEBUG COMPILER: Compiling statement type: ${statement.runtimeType} at line ${statement.line}');
    if (statement is BlockStmt) {
      _compileBlock(statement);
    } else if (statement is ExpressionStmt) {
      _compileExpression(statement.expression);
      _emit(OpCode.pop, statement.line, statement.column); 
    } else if (statement is VarDeclStmt) {
      _compileVarDecl(statement);
    } else if (statement is FunctionDecl) {
      _compileFunctionDecl(statement);
    } else if (statement is WidgetDecl) {
      _compileWidgetDecl(statement);
    } else if (statement is ClassDecl) {
      _compileClassDecl(statement);
    } else if (statement is ImportDecl) {
      _compileImportDecl(statement);
    } else if (statement is IfStmt) {
      _compileIfStmt(statement);
    } else if (statement is WhileStmt) {
      _compileWhileStmt(statement);
    } else if (statement is ForStmt) {
      _compileForStmt(statement);
    } else if (statement is ReturnStmt) {
      _compileReturnStmt(statement);
    } else if (statement is TryStmt) {
      _compileTryStmt(statement);
    } else if (statement is ThrowStmt) {
      _compileThrowStmt(statement);
    }
    // Handle others...
  }
  
  bool _isStateField(String name) {
    if (_stateFields.contains(name)) {
      return true;
    }
    if (_enclosing != null) {
      return _enclosing!._isStateField(name);
    }
    return false;
  }
  
  CompiledFunction endCompiler([int line = 0]) {
    // Only write implicit return if the last instruction isn't already a return or throw
    bool needsReturn = true;
    if (chunk.code.isNotEmpty) {
      final lastOp = OpCode.values[chunk.code.last];
      if (lastOp == OpCode.return_ || lastOp == OpCode.throw_) {
        needsReturn = false;
      }
    }

    if (needsReturn) {
      chunk.writeOp(OpCode.nil, line);
      chunk.writeOp(OpCode.return_, line);
    }
    
    // Run Post-Pass Optimization
    BytecodeOptimizer.optimize(chunk);
    
    // Generate Source Map if enabled
    if (_sourceMapGenerator != null) {
      // Re-create CompiledFunction with source map because fields are final
      return CompiledFunction(
        _function.name,
        _function.chunk,
        arity: _function.arity,
        isAsync: _function.isAsync,
        moduleName: _function.moduleName,
        paramNames: _function.paramNames,
        localNames: _function.localNames,
        sourceMap: _sourceMapGenerator!.toJson(),
      );
    }
    
    return _function;
  }

  /// Emits an opcode and records source mapping if generator is present
  void _emit(OpCode op, int line, int column) {
      if (_sourceMapGenerator != null) {
        _sourceMapGenerator!.addEntry(
          chunk.code.length, // generatedColumn (byte offset)
          1, // generatedLine (treat bytecode as line 1)
          sourceLine: line,
          sourceColumn: column,
          sourceIndex: 0, // Assuming single source file for now or handled by generator addSource logic
        );
      }
      chunk.writeOp(op, line);
  }

  void _compileWidgetDecl(WidgetDecl stmt) {
     // Collect state field names for the build compiler
     final stateNames = <String>[];
     
     // Compile state field initializers
     for (final stateField in stmt.stateFields) {
       stateNames.add(stateField.name);
     }
     
     // DEBUG
     print('Compiling Widget ${stmt.name}, State: $stateNames');
     
     // Create build method compiler with state context
      final buildCompiler = Compiler._inner(this, "${stmt.name}.build");
      buildCompiler._stateFields = stateNames;  // Inject state field names
      buildCompiler._function = CompiledFunction(
        "${stmt.name}.build", 
        buildCompiler.chunk,
        arity: stmt.props.length,
        moduleName: _moduleName,
        paramNames: stmt.props.map((p) => p.name).toList(),
      );
      
      // DEBUG
      print('BuildCompiler created. _stateFields: ${buildCompiler._stateFields}');
      
      // Begin scope and add props as local variables
      buildCompiler._beginScope();
      buildCompiler._locals.add(Local("", 0)); // Reserve slot 0 for closure
      for (final prop in stmt.props) {
        buildCompiler._addLocal(prop.name);
      }
      
      buildCompiler._compileExpression(stmt.buildBlock.body);
      buildCompiler._emit(OpCode.return_, stmt.line, stmt.column);
      final buildFunc = buildCompiler.endCompiler(stmt.line);
     
     // Create CompiledWidget with state field information
     final widgetObj = CompiledWidget(
       stmt.name, 
       buildFunc,
       stateFields: stmt.stateFields.map((f) => f.name).toList(),
       stateInitializers: stmt.stateFields.map((f) {
         // Compile each initializer to a separate chunk
         final initCompiler = Compiler._inner(this, "${stmt.name}.state.${f.name}");
         initCompiler._compileExpression(f.initialValue);
         initCompiler._emit(OpCode.return_, stmt.line, stmt.column);
          return initCompiler.endCompiler(stmt.line);
        }).toList(),
     );
     
     final idx = chunk.addConstant(widgetObj);
     chunk.writeOp(OpCode.constant, stmt.line);
     chunk.write(idx, stmt.line);
     
     final nameIdx = chunk.addConstant(stmt.name);
     chunk.writeOp(OpCode.setGlobal, stmt.line);
     chunk.write(nameIdx, stmt.line);
     chunk.writeOp(OpCode.pop, stmt.line);
  }
  
  void _compileFunctionDecl(FunctionDecl stmt) {
    // Compile function body with a nested compiler
    final funcCompiler = Compiler._inner(this, stmt.name);
    funcCompiler._function = CompiledFunction(
      stmt.name, 
      funcCompiler.chunk,
      arity: stmt.parameters.length,
      isAsync: stmt.isAsync,
      moduleName: _moduleName,
      paramNames: stmt.parameters.map((p) => p.name).toList(),
    );
    
    // Begin a scope for parameters
    funcCompiler._beginScope();
    
    // Reserve slot 0 for the function instance (closure) or 'this'
    funcCompiler._locals.add(Local("", 0));
    
    // Add parameters as local variables
    for (final param in stmt.parameters) {
      funcCompiler._addLocal(param.name);
    }
    
    // Compile the function body
    for (final s in stmt.body.statements) {
      funcCompiler.compile(s);
    }
    
    // Capture local variable names for debugger inspection
    funcCompiler._function.localNames = funcCompiler._locals.map((l) => l.name).toList();
    
    // Closure creation
    final funcObj = funcCompiler.endCompiler(stmt.line);
    final idx = chunk.addConstant(funcObj);
    _emit(OpCode.closure, stmt.line, stmt.column);
    chunk.write(idx, stmt.line);
    
    // Emit upvalue info
    chunk.write(funcCompiler._upvalues.length, stmt.line);
    for (final upvalue in funcCompiler._upvalues) {
      chunk.write(upvalue.isLocal ? 1 : 0, stmt.line);
      chunk.write(upvalue.index, stmt.line);
    }
    
    // Define as global variable (if top level) or local variable
    // Define as global variable (if top level) or local variable
    if (_scopeDepth > 0) {
      _addLocal(stmt.name);
    } else {
      final nameIdx = chunk.addConstant(stmt.name);
      _emit(OpCode.setGlobal, stmt.line, stmt.column);
      chunk.write(nameIdx, stmt.line);
      _emit(OpCode.pop, stmt.line, stmt.column); // Pop the closure instance
    }
  }
  
  void _compileLambda(LambdaExpr expr) {
    // Compile lambda body
    final funcCompiler = Compiler._inner(this, "lambda");
    funcCompiler._function = CompiledFunction(
      "lambda", 
      funcCompiler.chunk,
      arity: expr.parameters.length,
      isAsync: expr.isAsync,
      moduleName: _moduleName,
      paramNames: expr.parameters.map((p) => p.name).toList(),
    );
    
    // Begin scope for parameters
    funcCompiler._beginScope();
    funcCompiler._locals.add(Local("", 0)); // Reserve slot 0
    for (final param in expr.parameters) {
      funcCompiler._addLocal(param.name);
    }
    
    // Compile body
    if (expr.body is BlockStmt) {
      funcCompiler._compileBlock(expr.body as BlockStmt);
    } else if (expr.body is Statement) {
      funcCompiler.compile(expr.body as Statement);
    } else if (expr.body is Expression) {
      // Expression lambda? (e.g. arrow function)
      funcCompiler._compileExpression(expr.body as Expression);
      // If expression body, the result IS the return value?
      // But standard block returns returnOp.
      // If we implement expression lambdas later, we need 'return' opcode here.
      // For now, Flux doesn't seem to produce Expression-bodied lambdas in parser.
    }
    
    // Capture local variable names for debugger inspection
    funcCompiler._function.localNames = funcCompiler._locals.map((l) => l.name).toList();
    
    // Ensure return logic
    funcCompiler.chunk.writeOp(OpCode.nil, expr.line);
    funcCompiler.chunk.writeOp(OpCode.return_, expr.line);
    
    // Emit closure creation
    final funcObj = funcCompiler._function;
    final idx = chunk.addConstant(funcObj);
    _emit(OpCode.closure, expr.line, expr.column);
    chunk.write(idx, expr.line);
    
    // Emit upvalues
    chunk.write(funcCompiler._upvalues.length, expr.line);
    for (final upvalue in funcCompiler._upvalues) {
      chunk.write(upvalue.isLocal ? 1 : 0, expr.line);
      chunk.write(upvalue.index, expr.line);
    }
    
    // Result (Closure) is left on stack
  }
  
  void _compileWhileStmt(WhileStmt stmt) {
    int loopStart = chunk.code.length;
    
    _compileExpression(stmt.condition);
    int exitJump = _emitJump(OpCode.jumpIfFalse, stmt.line, stmt.column);
    _emit(OpCode.pop, stmt.line, stmt.column); // Pop true condition
    
    compile(stmt.body);
    
    _emitLoop(loopStart, stmt.line, stmt.column);
    
    _patchJump(exitJump);
    _emit(OpCode.pop, stmt.line, stmt.column); // Pop false condition
  }
  
  void _compileReturnStmt(ReturnStmt stmt) {
    // 1. Compile return value (pushes to stack)
    if (stmt.value != null) {
      _compileExpression(stmt.value!);
    } else {
      chunk.writeOp(OpCode.nil, stmt.line);
    }
    
    // 2. Execute all enclosing finally blocks (from inside out)
    // Note: finally blocks are compiled as statements, so they preserve stack height (mostly).
    // The return value is ON TOP OF STACK.
    // Finally blocks must not consume it.
    // Since finally blocks are usually just expression statements or helper calls, they push/pop cleanly.
    for (final tryStmt in _enclosingTrys.reversed) {
      if (tryStmt.finallyBlock != null) {
        compile(tryStmt.finallyBlock!);
      }
    }
    
    // 3. Return
    _emit(OpCode.return_, stmt.line, stmt.column);
  }

  void _compileBlock(BlockStmt stmt) {
    _beginScope();
    for (int i = 0; i < stmt.statements.length; i++) {
      final s = stmt.statements[i];
      compile(s);
    }
    _endScope(stmt.line);
  }
  
  void _compileTryStmt(TryStmt stmt) {
    _enclosingTrys.add(stmt);
    
    // Emit try_ opcode with placeholder absolute addresses
    chunk.writeOp(OpCode.try_, stmt.line);
    final catchAddrOffset = chunk.code.length;
    chunk.write(0, stmt.line); // Placeholder for catch address (low byte)
    chunk.write(0, stmt.line); // Placeholder for catch address (high byte)
    final finallyAddrOffset = chunk.code.length;
    chunk.write(0, stmt.line); // Placeholder for finally address (low byte)
    chunk.write(0, stmt.line); // Placeholder for finally address (high byte)
    
    // 1. Compile TRY block
    compile(stmt.tryBlock);
    
    _enclosingTrys.removeLast();
    
    // 2. Success Path
    _emit(OpCode.endTry, stmt.line, stmt.column);  // Remove handler on success
    
    // Execute finally block on success
    if (stmt.finallyBlock != null) {
      compile(stmt.finallyBlock!);
    }
    
    _emit(OpCode.jump, stmt.line, stmt.column);
    final successJumpOffset = chunk.code.length;
    chunk.write(0, stmt.line); // Placeholder for jump to end
    chunk.write(0, stmt.line);
    
    // 3. Exception Path (Compiler jumps here on error)
    final catchHandlerAddr = chunk.code.length;
    chunk.code[catchAddrOffset] = catchHandlerAddr & 0xff;
    chunk.code[catchAddrOffset + 1] = (catchHandlerAddr >> 8) & 0xff;
    
    // Note: finallyAddr is mostly for debug/introspection in current VM implementation
    // as the VM jumps to catchAddr on exception.
    chunk.code[finallyAddrOffset] = catchHandlerAddr & 0xff;
    chunk.code[finallyAddrOffset + 1] = (catchHandlerAddr >> 8) & 0xff;
    
    if (stmt.catchBlock != null) {
      // -- Try-Catch or Try-Catch-Finally --
      _emit(OpCode.catch_, stmt.line, stmt.column);
      
      _beginScope();
      if (stmt.catchVariable != null) {
        _addLocal(stmt.catchVariable!);
      }
      
      compile(stmt.catchBlock!);
      _endScope(stmt.line);
      
      // Execute finally after catch
      if (stmt.finallyBlock != null) {
        compile(stmt.finallyBlock!);
      }
      // Fallthrough to end
    } else {
      // -- Try-Finally (Synthesized Catch) --
      // Exception is on stack
      _emit(OpCode.catch_, stmt.line, stmt.column);
      
      // Execute finally
      if (stmt.finallyBlock != null) {
        compile(stmt.finallyBlock!);
      }
      
      // Rethrow exception
      _emit(OpCode.throw_, stmt.line, stmt.column);
    }
    
    // Patch Success Jump to here (End)
    final endAddr = chunk.code.length;
    final jumpDist = endAddr - successJumpOffset - 2;
    chunk.code[successJumpOffset] = jumpDist & 0xff;
    chunk.code[successJumpOffset + 1] = (jumpDist >> 8) & 0xff;
  }
  
  void _compileThrowStmt(ThrowStmt stmt) {
    _compileExpression(stmt.value);
    chunk.writeOp(OpCode.throw_, stmt.line);
  }

  void _compileVarDecl(VarDeclStmt stmt) {
    if (stmt.initializer != null) {
      _compileExpression(stmt.initializer!);
    } else {
      chunk.writeOp(OpCode.nil, stmt.line);
    }

    if (_scopeDepth > 0) {
      _addLocal(stmt.name);
    } else {
      final nameIdx = chunk.addConstant(stmt.name);
      _emit(OpCode.setGlobal, stmt.line, stmt.column);
      chunk.write(nameIdx, stmt.line);
      _emit(OpCode.pop, stmt.line, stmt.column); 
    }
  }

  void _compileIfStmt(IfStmt stmt) {
    _compileExpression(stmt.condition);
    final thenJump = _emitJump(OpCode.jumpIfFalse, stmt.line, stmt.column);
    _emit(OpCode.pop, stmt.line, stmt.column); 
    compile(stmt.thenBranch);
    final elseJump = _emitJump(OpCode.jump, stmt.line, stmt.column);
    _patchJump(thenJump);
    _emit(OpCode.pop, stmt.line, stmt.column); 
    if (stmt.elseBranch != null) {
      compile(stmt.elseBranch!);
    }
    _patchJump(elseJump);
  }

  void _compileForStmt(ForStmt stmt) {
      _beginScope();
      if (stmt.initializer != null) compile(stmt.initializer!);
      int loopStart = chunk.code.length;
      int exitJump = -1;
      if (stmt.condition != null) {
          _compileExpression(stmt.condition!);
          exitJump = _emitJump(OpCode.jumpIfFalse, stmt.condition!.line, stmt.condition!.column);
          _emit(OpCode.pop, stmt.condition!.line, stmt.condition!.column);
      }
      compile(stmt.body);
      if (stmt.increment != null) {
          _compileExpression(stmt.increment!);
          _emit(OpCode.pop, stmt.increment!.line, stmt.increment!.column);
      }
      _emitLoop(loopStart, stmt.line, stmt.column);
      if (exitJump != -1) {
          _patchJump(exitJump);
          _emit(OpCode.pop, stmt.line, stmt.column); 
      }
      _endScope(stmt.line);
  }

  void _compileExpression(Expression expr) {
    if (expr is BinaryExpr) {
      _compileBinary(expr);
    } else if (expr is LiteralExpr) {
      _compileLiteral(expr);
    } else if (expr is VariableExpr) {
      _compileVariable(expr);
    } else if (expr is AssignExpr) {
      _compileAssign(expr);
    } else if (expr is CallExpr) {
       _compileCall(expr);
    } else if (expr is UnaryExpr) {
       _compileUnary(expr);
    } else if (expr is GroupingExpr) {
       _compileExpression(expr.expression);
    } else if (expr is AwaitExpr) {
       _compileAwait(expr);
    } else if (expr is ListExpr) {
       _compileList(expr);
    } else if (expr is MapExpr) {
       _compileMap(expr);
    } else if (expr is IndexExpr) {
       _compileIndex(expr);
    } else if (expr is IndexAssignExpr) {
       _compileIndexAssign(expr);
    } else if (expr is LambdaExpr) {
       _compileLambda(expr);
    } else if (expr is GetExpr) {
       _compileGetExpr(expr);
    } else if (expr is SetExpr) {
       _compileSetExpr(expr);
    } else if (expr is ThisExpr) {
      _compileThis(expr);
    } else if (expr is SuperExpr) {
      _compileSuper(expr);
    }
  }
  
  void _compileThis(ThisExpr expr) {
    _emit(OpCode.getLocal, expr.line, expr.column);
    chunk.write(0, expr.line); // 'this' is always at slot 0 in methods
  }

  void _compileSuper(SuperExpr expr) {
  if (expr.method == null) {
    throw 'Super must be followed by a method name.';
  }
  
  // For super.method(...), we just push 'this'.
  // The call handling will emit invokeSuper.
  _compileThis(ThisExpr(line: expr.line, column: expr.column));
}
  
  void _compileGetExpr(GetExpr expr) {
    // Compile the object first
    _compileExpression(expr.object);
    // Emit getProperty with property name
    final nameIdx = chunk.addConstant(expr.name);
    _emit(OpCode.getProperty, expr.line, expr.column);
    chunk.write(nameIdx, expr.line);
  }

  void _compileSetExpr(SetExpr expr) {
    // Compile object and value
    _compileExpression(expr.object);
    _compileExpression(expr.value);
    
    // Emit setProperty with property name
    final nameIdx = chunk.addConstant(expr.name);
    _emit(OpCode.setProperty, expr.line, expr.column);
    chunk.write(nameIdx, expr.line);
  }
  
  void _compileList(ListExpr expr) {
    // Compile all elements onto stack
    for (final element in expr.elements) {
      _compileExpression(element);
    }
    // Emit newList with element count
    _emit(OpCode.newList, expr.line, expr.column);
    chunk.write(expr.elements.length, expr.line);
  }
  
  void _compileMap(MapExpr expr) {
    // Compile all key-value pairs onto stack
    for (final entry in expr.entries) {
      _compileExpression(entry.key);
      _compileExpression(entry.value);
    }
    // Emit newMap with pair count
    _emit(OpCode.newMap, expr.line, expr.column);
    chunk.write(expr.entries.length, expr.line);
  }
  
  void _compileIndex(IndexExpr expr) {
    // Compile object and index
    _compileExpression(expr.object);
    _compileExpression(expr.index);
    // Emit getIndex
    _emit(OpCode.getIndex, expr.line, expr.column);
  }
  
  void _compileIndexAssign(IndexAssignExpr expr) {
    // Compile object, index, and value
    _compileExpression(expr.object);
    _compileExpression(expr.index);
    _compileExpression(expr.value);
    // Emit setIndex
    _emit(OpCode.setIndex, expr.line, expr.column);
  }
  
  void _compileAwait(AwaitExpr expr) {
    // Compile the expression being awaited
    _compileExpression(expr.expression);
    // Emit await opcode
    _emit(OpCode.await_, expr.line, expr.column);
  }

  void _compileBinary(BinaryExpr expr) {
    _compileExpression(expr.left);
    _compileExpression(expr.right);
    switch (expr.operator_.type) {
      case TokenType.plus: _emit(OpCode.add, expr.line, expr.column); break;
      case TokenType.minus: _emit(OpCode.sub, expr.line, expr.column); break;
      case TokenType.star: _emit(OpCode.mul, expr.line, expr.column); break;
      case TokenType.slash: _emit(OpCode.div, expr.line, expr.column); break;
      case TokenType.percent: _emit(OpCode.mod, expr.line, expr.column); break;
      case TokenType.equalEqual: _emit(OpCode.equal, expr.line, expr.column); break;
      case TokenType.notEqual: 
        _emit(OpCode.equal, expr.line, expr.column); 
        _emit(OpCode.not, expr.line, expr.column);
        break;
      case TokenType.less: _emit(OpCode.less, expr.line, expr.column); break;
      case TokenType.greater: _emit(OpCode.greater, expr.line, expr.column); break;
      case TokenType.lessEqual: _emit(OpCode.lessEqual, expr.line, expr.column); break;
      case TokenType.greaterEqual: _emit(OpCode.greaterEqual, expr.line, expr.column); break;
      default: break; 
    }
  }

  void _compileLiteral(LiteralExpr expr) {
      if (expr.value == null) {
        _emit(OpCode.nil, expr.line, expr.column);
      } else if (expr.value is bool) {
        _emit((expr.value as bool) ? OpCode.true_ : OpCode.false_, expr.line, expr.column);
      } else { 
          final idx = chunk.addConstant(expr.value);
          _emit(OpCode.constant, expr.line, expr.column);
          chunk.write(idx, expr.line);
      }
  }
  
  void _compileUnary(UnaryExpr expr) {
    _compileExpression(expr.operand);
    switch (expr.operator_.type) {
      case TokenType.minus: _emit(OpCode.negate, expr.line, expr.column); break;
      case TokenType.not: _emit(OpCode.not, expr.line, expr.column); break;
      default: break;
    }
  }

  void _compileVariable(VariableExpr expr) {
      final isState = _isStateField(expr.name);
      print('DEBUG COMPILER: Compiling variable: ${expr.name}, isState: $isState');
      if (isState) {
        _emit(OpCode.getState, expr.line, expr.column);
        chunk.write(chunk.addConstant(expr.name), expr.line);
        return;
      }
      
      int arg = _resolveLocal(expr.name);
      if (arg != -1) {
          _emit(OpCode.getLocal, expr.line, expr.column);
          chunk.write(arg, expr.line);
      } else {
          arg = _resolveUpvalue(expr.name);
          if (arg != -1) {
            _emit(OpCode.getUpvalue, expr.line, expr.column);
            chunk.write(arg, expr.line);
          } else {
            final idx = chunk.addConstant(expr.name);
            _emit(OpCode.getGlobal, expr.line, expr.column);
            chunk.write(idx, expr.line);
          }
      }
  }
  
  void _compileAssign(AssignExpr expr) {
    // Check if state field
    if (_isStateField(expr.name)) {
      _compileExpression(expr.value);
      final idx = chunk.addConstant(expr.name);
      chunk.writeOp(OpCode.setState, expr.line);
      chunk.write(idx, expr.line);
      return;
    }

    _compileExpression(expr.value);
    
    int arg = _resolveLocal(expr.name);
    if (arg != -1) {
      _emit(OpCode.setLocal, expr.line, expr.column);
      chunk.write(arg, expr.line);
    } else {
      arg = _resolveUpvalue(expr.name);
      if (arg != -1) {
        _emit(OpCode.setUpvalue, expr.line, expr.column);
        chunk.write(arg, expr.line);
      } else {
        final idx = chunk.addConstant(expr.name);
        _emit(OpCode.setGlobal, expr.line, expr.column);
        chunk.write(idx, expr.line);
      }
    }
  }

  void _compileCall(CallExpr expr) {
  if (expr.callee is VariableExpr && (expr.callee as VariableExpr).name == 'print') {
    if (expr.arguments.length != 1) throw Exception("print() takes 1 argument.");
    _compileExpression(expr.arguments[0]);
    chunk.writeOp(OpCode.print, expr.line);
    chunk.writeOp(OpCode.nil, expr.line); 
    return;
  }

  if (expr.callee is SuperExpr) {
    final superExpr = expr.callee as SuperExpr;
    if (superExpr.method == null) throw 'Super must be followed by a method name.';
    
    // Load 'this'
    _compileThis(ThisExpr(line: expr.line, column: expr.column));
    
    // Positional arguments
    for (final arg in expr.arguments) {
      _compileExpression(arg);
    }
    
    // Emit invokeSuper
    _emit(OpCode.invokeSuper, expr.line, expr.column);
    final nameIdx = chunk.addConstant(superExpr.method!);
    chunk.write(nameIdx, expr.line);
    chunk.write(expr.arguments.length, expr.line);
    return;
  }

  // Optimization for method calls (obj.method(...))
  if (expr.callee is GetExpr && expr.namedArguments.isEmpty) {
    final getExpr = expr.callee as GetExpr;
    
    // 1. Compile object (receiver)
    _compileExpression(getExpr.object);
    
    // 2. Compile arguments
    for (final arg in expr.arguments) {
      _compileExpression(arg);
    }
    
    // 3. Emit invoke
    _emit(OpCode.invoke, expr.line, expr.column);
    final nameIdx = chunk.addConstant(getExpr.name);
    chunk.write(nameIdx, expr.line);
    chunk.write(expr.arguments.length, expr.line);
    return;
  }

  _compileExpression(expr.callee);
    
    // Positional arguments
    for (final arg in expr.arguments) {
      _compileExpression(arg);
    }
    
    // Named arguments
    if (expr.namedArguments.isEmpty) {
      chunk.writeOp(OpCode.call, expr.line);
      chunk.write(expr.arguments.length, expr.line);
    } else {
      // Push named argument pairs (name, value)
      for (final entry in expr.namedArguments.entries) {
        _emit(OpCode.constant, expr.line, expr.column);
        chunk.write(chunk.addConstant(entry.key), expr.line);
        _compileExpression(entry.value);
      }
      _emit(OpCode.callNamed, expr.line, expr.column);
      chunk.write(expr.arguments.length, expr.line);
      chunk.write(expr.namedArguments.length, expr.line);
    }
  }

  int _emitJump(OpCode op, int line, int column) {
    _emit(op, line, column);
    chunk.write(0xff, line); 
    chunk.write(0xff, line); 
    return chunk.code.length - 2;
  }

  void _patchJump(int offset) {
    // -2 to adjust for the bytecode for the jump offset itself.
    int jump = chunk.code.length - offset - 2;

    if (jump > 65535) {
      throw Exception("Jump too large!");
    }

    chunk.code[offset] = jump & 0xff;
    chunk.code[offset + 1] = (jump >> 8) & 0xff;
  }
  
  void _emitLoop(int loopStart, int line, int column) {
      _emit(OpCode.loop, line, column);
      int offset = chunk.code.length + 1 - loopStart;
      if (offset > 255) throw Exception("Loop body too large.");
      chunk.write(offset, line);
  }

  int _resolveUpvalue(String name) {
    if (_enclosing == null) return -1;
    
    final local = _enclosing!._resolveLocal(name);
    if (local != -1) {
      print('DEBUG COMPILER: Resolving upvalue "$name" -> enclosing local $local. Prev captured: ${_enclosing!._locals[local].isCaptured}');
      _enclosing!._locals[local].isCaptured = true;
      print('DEBUG COMPILER: Marked enclosing local $local as captured.');
      return _addUpvalue(local, true);
    }
    
    final upvalue = _enclosing!._resolveUpvalue(name);
    if (upvalue != -1) {
      return _addUpvalue(upvalue, false);
    }
    
    return -1;
  }
  
  int _addUpvalue(int index, bool isLocal) {
    // Check for existing upvalue
    for (int i = 0; i < _upvalues.length; i++) {
      final upvalue = _upvalues[i];
      if (upvalue.index == index && upvalue.isLocal == isLocal) {
        return i;
      }
    }
    
    _upvalues.add(CompilerUpvalue(index, isLocal));
    return _upvalues.length - 1;
  }

  void _beginScope() {
    _scopeDepth++;
  }

  void _endScope(int line) {
    _scopeDepth--;
    // print('DEBUG COMPILER: Ending scope depth $_scopeDepth');
    while (_locals.isNotEmpty && _locals.last.depth > _scopeDepth) {
      // Slot computation
      final slot = _locals.length - 1;
      final local = _locals.removeLast();
      print('DEBUG COMPILER: Pop/Close local "$local.name" at slot $slot (captured: ${local.isCaptured}) [Depth: ${local.depth}]');

      // If captured, close it using closeUpvalue. Otherwise just pop.
      // Note: closeUpvalue also pops the value from stack.
      if (local.isCaptured) {
        chunk.writeOp(OpCode.closeUpvalue, line);
      } else {
        chunk.writeOp(OpCode.pop, line);
      }
    }
  }

  void _addLocal(String name) {
    final slot = _locals.length;
    _locals.add(Local(name, _scopeDepth));
    print('DEBUG COMPILER: Added local "$name" at slot $slot [Depth: $_scopeDepth]');
  }

  int _resolveLocal(String name) {
    for (int i = _locals.length - 1; i >= 0; i--) {
      if (_locals[i].name == name) return i;
    }
    return -1;
  }
  
  /// Compile import declaration
  /// For now, imports are handled at VM level - we just emit an opcode
  void _compileImportDecl(ImportDecl stmt) {
    // Store the import path as a constant and emit import opcode
    final pathIdx = chunk.addConstant(stmt.path);
    _emit(OpCode.import_, stmt.line, stmt.column);
    chunk.write(pathIdx, stmt.line);
  }
  
  /// Compile class declaration
  void _compileClassDecl(ClassDecl stmt) {
    // Create a class constant with methods
    final methods = <String, CompiledFunction>{};
    
    // Separate constructor (init) and other methods
    FunctionDecl? initMethod;
    final otherMethods = <FunctionDecl>[];
    
    for (final member in stmt.members) {
      if (member is FunctionDecl) {
        if (member.name == 'init') {
          initMethod = member;
        } else {
          otherMethods.add(member);
        }
      }
    }

    // Compile 'init' method (constructor) with field initializers
    {
      final methodCompiler = Compiler._inner(this, '${stmt.name}.init');
      methodCompiler._beginScope(); // Start a scope for 'this' and parameters
      
      // For methods, slot 0 is reserved for 'this' (no empty slot like functions)
      // This matches how VM sets up the stack for method calls
      methodCompiler._addLocal('this'); // 'this' is slot 0
      
      // 1. Compile field initializers property assignments
      for (final field in stmt.fields) {
        if (field.initializer != null) {
          // this.field = initializer
          methodCompiler._emit(OpCode.getLocal, field.line, field.column);
          methodCompiler.chunk.write(0, field.line); // 'this' is slot 0
          
          methodCompiler._compileExpression(field.initializer!);
          
          final nameIdx = methodCompiler.chunk.addConstant(field.name);
          methodCompiler._emit(OpCode.setProperty, field.line, field.column);
          methodCompiler.chunk.write(nameIdx, field.line);
          methodCompiler._emit(OpCode.pop, field.line, field.column); // Clean up stack (setProperty pushes value)
        }
      }

      // 2. Compile explicit init body if it exists
      if (initMethod != null) {
          // Add parameters
          methodCompiler._function.arity = initMethod.parameters.length;
          for (final param in initMethod.parameters) {
             methodCompiler._addLocal(param.name);
          }
          // Compile body
          methodCompiler._compileBlock(initMethod.body);
      } else {
        // Default init just returns this
      }

      // 3. Ensure we return 'this' (implicit return)
      methodCompiler._emit(OpCode.getLocal, stmt.line, stmt.column);
      methodCompiler.chunk.write(0, stmt.line); // 'this' is slot 0
      methodCompiler._emit(OpCode.return_, stmt.line, stmt.column);

      methodCompiler._function = CompiledFunction(
        'init',
        methodCompiler.chunk,
        arity: initMethod?.parameters.length ?? 0, // Arity is based on explicit init method, or 0 for default
      );
      
      // Add local names for debugging
      methodCompiler._function.localNames = methodCompiler._locals.map((l) => l.name).toList();
      
      methods['init'] = methodCompiler._function;
      methodCompiler.endCompiler(stmt.line); // End the compiler for init
    }

    // Compile other methods
    for (final member in otherMethods) {
        final methodCompiler = Compiler._inner(this, '${stmt.name}.${member.name}');
        methodCompiler._beginScope(); // Start a scope for 'this' and parameters
        
        // For methods, slot 0 is 'this' (no empty slot like functions)
        methodCompiler._addLocal('this'); // 'this' is slot 0
        methodCompiler._function.arity = member.parameters.length;
        for (final param in member.parameters) {
           methodCompiler._addLocal(param.name);
        }
        
        methodCompiler._compileBlock(member.body);
        
        // Add default return for methods (nil) if not present
        if (methodCompiler.chunk.code.isEmpty || methodCompiler.chunk.code.last != OpCode.return_) {
           methodCompiler._emit(OpCode.nil, member.line, member.column);
           methodCompiler._emit(OpCode.return_, member.line, member.column);
        }

        methodCompiler._function = CompiledFunction(
          member.name,
          methodCompiler.chunk,
          arity: member.parameters.length,
        );
        methodCompiler._function.localNames = methodCompiler._locals.map((l) => l.name).toList();
        methods[member.name] = methodCompiler._function;
        methodCompiler.endCompiler(member.line); // End the compiler for this method
    }
    
    // Create CompiledClass object
    final classObj = CompiledClass(
      stmt.name,
      methods: methods,
      superclass: stmt.superclass,
    );
    
    // Store as global
    final classIdx = chunk.addConstant(classObj);
    _emit(OpCode.constant, stmt.line, stmt.column);
    chunk.write(classIdx, stmt.line);
    
    final nameIdx = chunk.addConstant(stmt.name);
    _emit(OpCode.setGlobal, stmt.line, stmt.column);
    chunk.write(nameIdx, stmt.line);
    _emit(OpCode.pop, stmt.line, stmt.column);
  }
}

/// Compiles a single expression in the context of specific local variables.
/// 
/// [source] is the expression to compile.
/// [variableNames] is the list of local variables available in the scope,
/// ordered by their stack slot index.
CompiledFunction compileFluxExpression(String source, List<String> variableNames, {bool generateSourceMap = false, String moduleName = '<eval>'}) {
  if (source.trim().isEmpty) return CompiledFunction("empty", Chunk());
  
  // Parse expression
  final lexer = Lexer(source);
  final parser = Parser(lexer.tokenize());
  final expr = parser.parseExpression();
  
  // Create compiler instance
  final compiler = Compiler(moduleName: moduleName, generateSourceMap: generateSourceMap);
  
  // Setup local variable context
  // We treat the provided variables as being already initialized in the current scope.
  compiler._scopeDepth = 1;
  
  for (final name in variableNames) {
    // Add local with depth 1 (initialized)
    // Even empty names (internal slots) are added to keep index alignment
    compiler._locals.add(Local(name, 1));
  }
  
  // Compile expression
  compiler._compileExpression(expr);
  
  // Emit return to end the chunk
  compiler.chunk.writeOp(OpCode.return_, 1);
  
  return compiler._function;
}

