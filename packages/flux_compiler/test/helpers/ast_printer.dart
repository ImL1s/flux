import 'package:flux_compiler/flux_compiler.dart';

/// Helper to print AST structure for golden tests
class AstPrinter {
  String print(AstNode node) {
    return _visit(node, "");
  }

  String _visit(AstNode node, String indent) {
    final sb = StringBuffer();

    if (node is CompilationUnit) {
      sb.writeln("${indent}CompilationUnit");
      for (final decl in node.declarations) {
        sb.write(_visit(decl, "$indent  "));
      }
    } else if (node is FunctionDecl) {
      sb.writeln("${indent}FunctionDecl(${node.name})");
      sb.writeln(
          "${indent}  Params: ${node.parameters.map((p) => p.name).join(", ")}");
      sb.writeln("${indent}  Body:");
      for (final stmt in node.body.statements) {
        sb.write(_visit(stmt, "$indent    "));
      }
    } else if (node is VarDeclStmt) {
      sb.writeln("${indent}VarDeclStmt(${node.name})");
      if (node.initializer != null) {
        sb.write(_visit(node.initializer!, "$indent  "));
      }
    } else if (node is ReturnStmt) {
      sb.writeln("${indent}ReturnStmt");
      if (node.value != null) {
        sb.write(_visit(node.value!, "$indent  "));
      }
    } else if (node is ExpressionStmt) {
      sb.writeln("${indent}ExpressionStmt");
      sb.write(_visit(node.expression, "$indent  "));
    } else if (node is BlockStmt) {
      sb.writeln("${indent}BlockStmt");
      for (final stmt in node.statements) {
        sb.write(_visit(stmt, "$indent  "));
      }
    } else if (node is IfStmt) {
      sb.writeln("${indent}IfStmt");
      sb.writeln("${indent}  Condition:");
      sb.write(_visit(node.condition, "$indent    "));
      sb.writeln("${indent}  Then:");
      sb.write(_visit(node.thenBranch, "$indent    "));
      if (node.elseBranch != null) {
        sb.writeln("${indent}  Else:");
        sb.write(_visit(node.elseBranch!, "$indent    "));
      }
    } else if (node is WhileStmt) {
      sb.writeln("${indent}WhileStmt");
      sb.writeln("${indent}  Condition:");
      sb.write(_visit(node.condition, "$indent    "));
      sb.writeln("${indent}  Body:");
      sb.write(_visit(node.body, "$indent    "));
    } else if (node is LiteralExpr) {
      sb.writeln("${indent}LiteralExpr(${node.value})");
    } else if (node is VariableExpr) {
      sb.writeln("${indent}VariableExpr(${node.name})");
    } else if (node is BinaryExpr) {
      sb.writeln("${indent}BinaryExpr(${node.operator_.lexeme})");
      sb.write(_visit(node.left, "$indent  "));
      sb.write(_visit(node.right, "$indent  "));
    } else if (node is UnaryExpr) {
      sb.writeln("${indent}UnaryExpr(${node.operator_.lexeme})");
      sb.write(_visit(node.operand, "$indent  "));
    } else if (node is CallExpr) {
      sb.writeln("${indent}CallExpr");
      sb.writeln("${indent}  Callee:");
      sb.write(_visit(node.callee, "$indent    "));
      sb.writeln("${indent}  Args:");
      for (final arg in node.arguments) {
        sb.write(_visit(arg, "$indent    "));
      }
    } else if (node is ImportDecl) {
      sb.writeln("${indent}ImportDecl(${node.path})");
    } else if (node is ClassDecl) {
      sb.writeln("${indent}ClassDecl(${node.name})");
      for (final member in node.members) {
        sb.write(_visit(member, "$indent  "));
      }
    } else {
      sb.writeln("${indent}Unknown Node: $node");
    }

    return sb.toString();
  }
}
