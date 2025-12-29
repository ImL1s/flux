/// Flux Language - Compiler
/// 
/// Compiles AST into Bytecode Chunks.

import 'ast.dart';
import 'token.dart';
import 'bytecode.dart';

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
  final int arity;
  final bool isAsync;
  
  CompiledFunction(this.name, this.chunk, {this.arity = 0, this.isAsync = false});
  
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
  
  final List<Local> _locals = [];
  final List<CompilerUpvalue> _upvalues = [];
  int _scopeDepth = 0;
  
  /// State field names available in current widget context (for build method)
  List<String> _stateFields = [];

  Compiler({CompilationUnit? unit}) {
      _function = CompiledFunction("script", Chunk());
      if (unit != null) {
          // compile everything
          for (final decl in unit.declarations) {
              compile(decl);
          }
      }
  }
  
  // Internal constructor for inner functions
  Compiler._inner(this._enclosing, String name) {
      _function = CompiledFunction(name, Chunk());
  }

  void compile(Statement statement) {
    if (statement is BlockStmt) {
      _compileBlock(statement);
    } else if (statement is ExpressionStmt) {
      _compileExpression(statement.expression);
      chunk.writeOp(OpCode.pop, statement.line); 
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
  
  CompiledFunction endCompiler() {
      chunk.writeOp(OpCode.nil, 0);
      chunk.writeOp(OpCode.return_, 0);
      return _function;
  }

  void _compileWidgetDecl(WidgetDecl stmt) {
     // Collect state field names for the build compiler
     final stateNames = <String>[];
     
     // Compile state field initializers
     for (final stateField in stmt.stateFields) {
       stateNames.add(stateField.name);
     }
     
     // Create build method compiler with state context
     final buildCompiler = Compiler._inner(this, "${stmt.name}.build");
     buildCompiler._stateFields = stateNames;  // Inject state field names
     
     buildCompiler._compileExpression(stmt.buildBlock.body);
     buildCompiler.chunk.writeOp(OpCode.return_, stmt.line);
     
     final buildFunc = buildCompiler._function;
     
     // Create CompiledWidget with state field information
     final widgetObj = CompiledWidget(
       stmt.name, 
       buildFunc,
       stateFields: stmt.stateFields.map((f) => f.name).toList(),
       stateInitializers: stmt.stateFields.map((f) {
         // Compile each initializer to a separate chunk
         final initCompiler = Compiler._inner(this, "${stmt.name}.state.${f.name}");
         initCompiler._compileExpression(f.initialValue);
         initCompiler.chunk.writeOp(OpCode.return_, stmt.line);
         return initCompiler._function;
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
    );
    
    // Begin a scope for parameters
    funcCompiler._beginScope();
    
    // Add parameters as local variables
    for (final param in stmt.parameters) {
      funcCompiler._addLocal(param.name);
    }
    
    // Compile the function body
    for (final s in stmt.body.statements) {
      funcCompiler.compile(s);
    }
    
    // Ensure function returns nil if no explicit return
    funcCompiler.chunk.writeOp(OpCode.nil, stmt.line);
    funcCompiler.chunk.writeOp(OpCode.return_, stmt.line);
    
    // End scope (parameters)
    // Note: We don't pop locals at end since return handles cleanup
    
    // Store compiled function as constant
    final funcObj = funcCompiler._function;
    final idx = chunk.addConstant(funcObj);
    chunk.writeOp(OpCode.closure, stmt.line);
    chunk.write(idx, stmt.line);
    
    // Emit upvalue info
    chunk.write(funcCompiler._upvalues.length, stmt.line);
    for (final upvalue in funcCompiler._upvalues) {
      chunk.write(upvalue.isLocal ? 1 : 0, stmt.line);
      chunk.write(upvalue.index, stmt.line);
    }
    
    // Define as global variable (if top level) or local variable
    if (_scopeDepth > 0) {
      _addLocal(stmt.name);
    } else {
      final nameIdx = chunk.addConstant(stmt.name);
      chunk.writeOp(OpCode.setGlobal, stmt.line);
      chunk.write(nameIdx, stmt.line);
      chunk.writeOp(OpCode.pop, stmt.line); // Pop the closure instance
    }
  }
  
  void _compileWhileStmt(WhileStmt stmt) {
    int loopStart = chunk.code.length;
    
    _compileExpression(stmt.condition);
    int exitJump = _emitJump(OpCode.jumpIfFalse, stmt.line);
    chunk.writeOp(OpCode.pop, stmt.line); // Pop true condition
    
    compile(stmt.body);
    
    _emitLoop(loopStart, stmt.line);
    
    _patchJump(exitJump);
    chunk.writeOp(OpCode.pop, stmt.line); // Pop false condition
  }
  
  void _compileReturnStmt(ReturnStmt stmt) {
    if (stmt.value != null) {
      _compileExpression(stmt.value!);
    } else {
      chunk.writeOp(OpCode.nil, stmt.line);
    }
    chunk.writeOp(OpCode.return_, stmt.line);
  }

  void _compileBlock(BlockStmt stmt) {
    _beginScope();
    for (final s in stmt.statements) {
      compile(s);
    }
    _endScope(stmt.line);
  }
  
  void _compileTryStmt(TryStmt stmt) {
    // Emit try_ opcode with placeholder absolute addresses
    chunk.writeOp(OpCode.try_, stmt.line);
    final catchAddrOffset = chunk.code.length;
    chunk.write(0, stmt.line); // Placeholder for catch address (low byte)
    chunk.write(0, stmt.line); // Placeholder for catch address (high byte)
    final finallyAddrOffset = chunk.code.length;
    chunk.write(0, stmt.line); // Placeholder for finally address (low byte)
    chunk.write(0, stmt.line); // Placeholder for finally address (high byte)
    
    // Compile try block
    compile(stmt.tryBlock);
    
    // Success path: remove handler and jump over catch block
    chunk.writeOp(OpCode.endTry, stmt.line);  // Remove handler on success
    chunk.writeOp(OpCode.jump, stmt.line);
    final successJumpOffset = chunk.code.length;
    chunk.write(0, stmt.line);
    chunk.write(0, stmt.line);
    
    // Record catch block start address and patch it
    final catchBlockAddr = chunk.code.length;
    chunk.code[catchAddrOffset] = catchBlockAddr & 0xff;
    chunk.code[catchAddrOffset + 1] = (catchBlockAddr >> 8) & 0xff;
    
    // Compile catch block (if present)
    if (stmt.catchBlock != null) {
      chunk.writeOp(OpCode.catch_, stmt.line);
      
      // Create local variable for exception
      _beginScope();
      if (stmt.catchVariable != null) {
        _addLocal(stmt.catchVariable!);
        // The exception is already on the stack from the VM's catch handler
      }
      
      compile(stmt.catchBlock!);
      _endScope(stmt.line);
    }
    
    // Patch success jump to skip to finally/end
    final afterCatchAddr = chunk.code.length;
    final jumpOffset = afterCatchAddr - successJumpOffset - 2;
    chunk.code[successJumpOffset] = jumpOffset & 0xff;
    chunk.code[successJumpOffset + 1] = (jumpOffset >> 8) & 0xff;
    
    // Record finally block start address and patch it
    final finallyBlockAddr = chunk.code.length;
    chunk.code[finallyAddrOffset] = finallyBlockAddr & 0xff;
    chunk.code[finallyAddrOffset + 1] = (finallyBlockAddr >> 8) & 0xff;
    
    // Compile finally block (if present)
    if (stmt.finallyBlock != null) {
      compile(stmt.finallyBlock!);
    }
    // Note: No endTry here since it's either already done (success) or handler was removed by _handleException
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
      chunk.writeOp(OpCode.setGlobal, stmt.line);
      chunk.write(nameIdx, stmt.line);
      chunk.writeOp(OpCode.pop, stmt.line); 
    }
  }

  void _compileIfStmt(IfStmt stmt) {
    _compileExpression(stmt.condition);
    final thenJump = _emitJump(OpCode.jumpIfFalse, stmt.line);
    chunk.writeOp(OpCode.pop, stmt.line); 
    compile(stmt.thenBranch);
    final elseJump = _emitJump(OpCode.jump, stmt.line);
    _patchJump(thenJump);
    chunk.writeOp(OpCode.pop, stmt.line); 
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
          exitJump = _emitJump(OpCode.jumpIfFalse, stmt.condition!.line);
          chunk.writeOp(OpCode.pop, stmt.condition!.line);
      }
      compile(stmt.body);
      if (stmt.increment != null) {
          _compileExpression(stmt.increment!);
          chunk.writeOp(OpCode.pop, stmt.increment!.line);
      }
      _emitLoop(loopStart, stmt.line);
      if (exitJump != -1) {
          _patchJump(exitJump);
          chunk.writeOp(OpCode.pop, stmt.line); 
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
    }
  }
  
  void _compileList(ListExpr expr) {
    // Compile all elements onto stack
    for (final element in expr.elements) {
      _compileExpression(element);
    }
    // Emit newList with element count
    chunk.writeOp(OpCode.newList, expr.line);
    chunk.write(expr.elements.length, expr.line);
  }
  
  void _compileMap(MapExpr expr) {
    // Compile all key-value pairs onto stack
    for (final entry in expr.entries) {
      _compileExpression(entry.key);
      _compileExpression(entry.value);
    }
    // Emit newMap with pair count
    chunk.writeOp(OpCode.newMap, expr.line);
    chunk.write(expr.entries.length, expr.line);
  }
  
  void _compileIndex(IndexExpr expr) {
    // Compile object and index
    _compileExpression(expr.object);
    _compileExpression(expr.index);
    // Emit getIndex
    chunk.writeOp(OpCode.getIndex, expr.line);
  }
  
  void _compileIndexAssign(IndexAssignExpr expr) {
    // Compile object, index, and value
    _compileExpression(expr.object);
    _compileExpression(expr.index);
    _compileExpression(expr.value);
    // Emit setIndex
    chunk.writeOp(OpCode.setIndex, expr.line);
  }
  
  void _compileAwait(AwaitExpr expr) {
    // Compile the expression being awaited
    _compileExpression(expr.expression);
    // Emit await opcode
    chunk.writeOp(OpCode.await_, expr.line);
  }

  void _compileBinary(BinaryExpr expr) {
    _compileExpression(expr.left);
    _compileExpression(expr.right);
    switch (expr.operator_.type) {
      case TokenType.plus: chunk.writeOp(OpCode.add, expr.line); break;
      case TokenType.minus: chunk.writeOp(OpCode.sub, expr.line); break;
      case TokenType.star: chunk.writeOp(OpCode.mul, expr.line); break;
      case TokenType.slash: chunk.writeOp(OpCode.div, expr.line); break;
      case TokenType.equalEqual: chunk.writeOp(OpCode.equal, expr.line); break;
      case TokenType.bangEqual: 
        chunk.writeOp(OpCode.equal, expr.line); 
        chunk.writeOp(OpCode.not, expr.line);
        break;
      case TokenType.less: chunk.writeOp(OpCode.less, expr.line); break;
      case TokenType.greater: chunk.writeOp(OpCode.greater, expr.line); break;
      default: break; 
    }
  }

  void _compileLiteral(LiteralExpr expr) {
      if (expr.value == null) {
        chunk.writeOp(OpCode.nil, expr.line);
      } else if (expr.value is bool) {
        chunk.writeOp((expr.value as bool) ? OpCode.true_ : OpCode.false_, expr.line);
      } else { 
          final idx = chunk.addConstant(expr.value);
          chunk.writeOp(OpCode.constant, expr.line);
          chunk.write(idx, expr.line);
      }
  }
  
  void _compileUnary(UnaryExpr expr) {
    _compileExpression(expr.operand);
    switch (expr.operator_.type) {
      case TokenType.minus: chunk.writeOp(OpCode.negate, expr.line); break;
      case TokenType.not: chunk.writeOp(OpCode.not, expr.line); break;
      default: break;
    }
  }

  void _compileVariable(VariableExpr expr) {
      // Check if this is a state field access
      if (_stateFields.contains(expr.name)) {
          final idx = chunk.addConstant(expr.name);
          chunk.writeOp(OpCode.getState, expr.line);
          chunk.write(idx, expr.line);
          return;
      }
      
      int arg = _resolveLocal(expr.name);
      if (arg != -1) {
          chunk.writeOp(OpCode.getLocal, expr.line);
          chunk.write(arg, expr.line);
      } else {
          arg = _resolveUpvalue(expr.name);
          if (arg != -1) {
            chunk.writeOp(OpCode.getUpvalue, expr.line);
            chunk.write(arg, expr.line);
          } else {
            final idx = chunk.addConstant(expr.name);
            chunk.writeOp(OpCode.getGlobal, expr.line);
            chunk.write(idx, expr.line);
          }
      }
  }
  
  void _compileAssign(AssignExpr expr) {
    // Check if state field
    if (_stateFields.contains(expr.name)) {
      _compileExpression(expr.value);
      final idx = chunk.addConstant(expr.name);
      chunk.writeOp(OpCode.setState, expr.line);
      chunk.write(idx, expr.line);
      return;
    }

    _compileExpression(expr.value);
    
    int arg = _resolveLocal(expr.name);
    if (arg != -1) {
      chunk.writeOp(OpCode.setLocal, expr.line);
      chunk.write(arg, expr.line);
    } else {
      arg = _resolveUpvalue(expr.name);
      if (arg != -1) {
        chunk.writeOp(OpCode.setUpvalue, expr.line);
        chunk.write(arg, expr.line);
      } else {
        final idx = chunk.addConstant(expr.name);
        chunk.writeOp(OpCode.setGlobal, expr.line);
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

       _compileExpression(expr.callee);
       for (final arg in expr.arguments) {
           _compileExpression(arg);
       }
       chunk.writeOp(OpCode.call, expr.line);
       chunk.write(expr.arguments.length, expr.line);
  }

  int _emitJump(OpCode op, int line) {
    chunk.writeOp(op, line);
    chunk.write(0xff, line); 
    return chunk.code.length - 1;
  }

  void _patchJump(int offset) {
    int jump = chunk.code.length - offset - 1;
    if (jump > 255) throw Exception("Jump too large!");
    chunk.code[offset] = jump;
  }
  
  void _emitLoop(int loopStart, int line) {
      chunk.writeOp(OpCode.loop, line);
      int offset = chunk.code.length + 1 - loopStart;
      if (offset > 255) throw Exception("Loop body too large.");
      chunk.write(offset, line);
  }

  int _resolveUpvalue(String name) {
    if (_enclosing == null) return -1;
    
    final local = _enclosing!._resolveLocal(name);
    if (local != -1) {
      _enclosing!._locals[local].isCaptured = true;
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
    while (_locals.isNotEmpty && _locals.last.depth > _scopeDepth) {
      final local = _locals.removeLast();

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
    _locals.add(Local(name, _scopeDepth));
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
    chunk.writeOp(OpCode.import_, stmt.line);
    chunk.write(pathIdx, stmt.line);
  }
  
  /// Compile class declaration
  void _compileClassDecl(ClassDecl stmt) {
    // Create a class constant with methods
    final methods = <String, CompiledFunction>{};
    
    for (final member in stmt.members) {
      if (member is FunctionDecl) {
        // Compile method
        final methodCompiler = Compiler._inner(this, '${stmt.name}.${member.name}');
        methodCompiler._function = CompiledFunction(
          member.name,
          methodCompiler.chunk,
          arity: member.parameters.length,
        );
        
        // Begin scope for 'this' and parameters
        methodCompiler._beginScope();
        
        // Add 'this' as first local (slot 0)
        methodCompiler._addLocal('this');
        
        // Add parameters
        for (final param in member.parameters) {
          methodCompiler._addLocal(param.name);
        }
        
        // Compile method body
        for (final s in member.body.statements) {
          methodCompiler.compile(s);
        }
        
        // Implicit nil return
        methodCompiler.chunk.writeOp(OpCode.nil, member.line);
        methodCompiler.chunk.writeOp(OpCode.return_, member.line);
        
        methods[member.name] = methodCompiler._function;
      }
      // TODO: Add field support when FieldDecl is available
    }
    
    // Create CompiledClass object
    final classObj = CompiledClass(
      stmt.name,
      methods: methods,
      superclass: stmt.superclass,
    );
    
    // Store as global
    final classIdx = chunk.addConstant(classObj);
    chunk.writeOp(OpCode.constant, stmt.line);
    chunk.write(classIdx, stmt.line);
    
    final nameIdx = chunk.addConstant(stmt.name);
    chunk.writeOp(OpCode.setGlobal, stmt.line);
    chunk.write(nameIdx, stmt.line);
    chunk.writeOp(OpCode.pop, stmt.line);
  }
}

