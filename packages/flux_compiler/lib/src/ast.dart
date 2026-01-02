/// Flux Language - Abstract Syntax Tree (AST) definitions
/// 
/// This file defines all AST node types for the Flux language.

import 'token.dart';

/// Base class for all AST nodes
sealed class AstNode {
  final int line;
  final int column;

  const AstNode({required this.line, required this.column});
}

// ============================================================================
// Expressions
// ============================================================================

/// Base class for all expressions
sealed class Expression extends AstNode {
  const Expression({required super.line, required super.column});
}

/// Literal expression (numbers, strings, booleans, null)
class LiteralExpr extends Expression {
  final Object? value;

  const LiteralExpr(this.value, {required super.line, required super.column});
}

/// Variable reference
class VariableExpr extends Expression {
  final String name;

  const VariableExpr(this.name, {required super.line, required super.column});
}

/// Binary operation (a + b, a == b, etc.)
class BinaryExpr extends Expression {
  final Expression left;
  final Token operator_;
  final Expression right;

  const BinaryExpr(this.left, this.operator_, this.right,
      {required super.line, required super.column});
}

/// Unary operation (!a, -a)
class UnaryExpr extends Expression {
  final Token operator_;
  final Expression operand;

  const UnaryExpr(this.operator_, this.operand,
      {required super.line, required super.column});
}

/// Grouping expression (parentheses)
class GroupingExpr extends Expression {
  final Expression expression;

  const GroupingExpr(this.expression,
      {required super.line, required super.column});
}

/// Assignment expression (a = b)
class AssignExpr extends Expression {
  final String name;
  final int? nameLine;
  final int? nameColumn;
  final Expression value;

  const AssignExpr(this.name, this.value,
      {this.nameLine, this.nameColumn, required super.line, required super.column});
}

/// Function call expression
class CallExpr extends Expression {
  final Expression callee;
  final List<Expression> arguments;
  final Map<String, Expression> namedArguments;

  const CallExpr(this.callee, this.arguments,
      {this.namedArguments = const {}, required super.line, required super.column});
}

/// Property access (a.b)
class GetExpr extends Expression {
  final Expression object;
  final String name;

  const GetExpr(this.object, this.name,
      {required super.line, required super.column});
}

/// Property set (a.b = c)
class SetExpr extends Expression {
  final Expression object;
  final String name;
  final int? nameLine;
  final int? nameColumn;
  final Expression value;

  const SetExpr(this.object, this.name, this.value,
      {this.nameLine, this.nameColumn, required super.line, required super.column});
}

/// Index access (a[b])
class IndexExpr extends Expression {
  final Expression object;
  final Expression index;

  const IndexExpr(this.object, this.index,
      {required super.line, required super.column});
}

/// Index assignment (a[b] = c)
class IndexAssignExpr extends Expression {
  final Expression object;
  final Expression index;
  final Expression value;

  const IndexAssignExpr(this.object, this.index, this.value,
      {required super.line, required super.column});
}

/// List literal [a, b, c]
class ListExpr extends Expression {
  final List<Expression> elements;

  const ListExpr(this.elements, {required super.line, required super.column});
}

/// Map literal {a: b, c: d}
class MapExpr extends Expression {
  final List<MapEntry<Expression, Expression>> entries;

  const MapExpr(this.entries, {required super.line, required super.column});
}

/// Lambda/anonymous function
class LambdaExpr extends Expression {
  final List<Parameter> parameters;
  final AstNode body; // Expression or BlockStmt
  final bool isAsync;

  const LambdaExpr(this.parameters, this.body,
      {this.isAsync = false, required super.line, required super.column});
}

/// Await expression
class AwaitExpr extends Expression {
  final Expression expression;

  const AwaitExpr(this.expression, {required super.line, required super.column});
}

/// Ternary/conditional expression (a ? b : c)
class ConditionalExpr extends Expression {
  final Expression condition;
  final Expression thenBranch;
  final Expression elseBranch;

  const ConditionalExpr(this.condition, this.thenBranch, this.elseBranch,
      {required super.line, required super.column});
}

/// String interpolation expression
class InterpolationExpr extends Expression {
  final List<Expression> parts;

  const InterpolationExpr(this.parts,
      {required super.line, required super.column});
}

/// This expression
class ThisExpr extends Expression {
  const ThisExpr({required super.line, required super.column});
}

/// Super expression
class SuperExpr extends Expression {
  final String? method;

  const SuperExpr({this.method, required super.line, required super.column});
}

// ============================================================================
// Statements
// ============================================================================

/// Base class for all statements
sealed class Statement extends AstNode {
  const Statement({required super.line, required super.column});
}

/// Expression statement
class ExpressionStmt extends Statement {
  final Expression expression;

  const ExpressionStmt(this.expression,
      {required super.line, required super.column});
}

/// Variable declaration
class VarDeclStmt extends Statement {
  final String name;
  final int? nameLine;
  final int? nameColumn;
  final String? type;
  final Expression? initializer;
  final bool isMutable;

  const VarDeclStmt(this.name,
      {this.nameLine, this.nameColumn, this.type, this.initializer, this.isMutable = true, required super.line, required super.column});
}

/// Block statement
class BlockStmt extends Statement {
  final List<Statement> statements;

  const BlockStmt(this.statements, {required super.line, required super.column});
}

/// If statement
class IfStmt extends Statement {
  final Expression condition;
  final Statement thenBranch;
  final Statement? elseBranch;

  const IfStmt(this.condition, this.thenBranch, this.elseBranch,
      {required super.line, required super.column});
}

/// While statement
class WhileStmt extends Statement {
  final Expression condition;
  final Statement body;

  const WhileStmt(this.condition, this.body,
      {required super.line, required super.column});
}

/// For statement
class ForStmt extends Statement {
  final Statement? initializer;
  final Expression? condition;
  final Expression? increment;
  final Statement body;

  const ForStmt(this.initializer, this.condition, this.increment, this.body,
      {required super.line, required super.column});
}

/// For-in statement
class ForInStmt extends Statement {
  final String variable;
  final Expression iterable;
  final Statement body;

  const ForInStmt(this.variable, this.iterable, this.body,
      {required super.line, required super.column});
}

/// Return statement
class ReturnStmt extends Statement {
  final Expression? value;

  const ReturnStmt(this.value, {required super.line, required super.column});
}

/// Break statement
class BreakStmt extends Statement {
  const BreakStmt({required super.line, required super.column});
}

/// Continue statement
class ContinueStmt extends Statement {
  const ContinueStmt({required super.line, required super.column});
}

/// Try-catch-finally statement
class TryStmt extends Statement {
  final Statement tryBlock;
  final String? catchVariable;  // Variable name for caught exception (e.g., "e" in catch(e))
  final Statement? catchBlock;
  final Statement? finallyBlock;

  const TryStmt(this.tryBlock, {
    this.catchVariable,
    this.catchBlock, 
    this.finallyBlock,
    required super.line, 
    required super.column,
  });
}

/// Throw statement
class ThrowStmt extends Statement {
  final Expression value;

  const ThrowStmt(this.value, {required super.line, required super.column});
}

// ============================================================================
// Declarations
// ============================================================================

/// Base class for declarations
sealed class Declaration extends Statement {
  const Declaration({required super.line, required super.column});
}

/// Function declaration
class FunctionDecl extends Declaration {
  final String name;
  final int? nameLine;
  final int? nameColumn;
  final List<Parameter> parameters;
  final String? returnType;
  final BlockStmt body;
  final bool isAsync;

  const FunctionDecl(this.name, this.parameters, this.body,
      {this.nameLine, this.nameColumn, this.returnType, this.isAsync = false, required super.line, required super.column});
}

/// Class declaration
class ClassDecl extends Declaration {
  final String name;
  final int? nameLine;
  final int? nameColumn;
  final String? superclass;
  final List<String> interfaces;
  final List<FieldDecl> fields;
  final List<Declaration> members;

  const ClassDecl(this.name, this.members,
      {this.nameLine, this.nameColumn, this.superclass, this.interfaces = const [], this.fields = const [], required super.line, required super.column});
}

/// Field declaration in a class
class FieldDecl extends Declaration {
  final String name;
  final Expression? initializer;

  const FieldDecl(this.name, this.initializer, {required super.line, required super.column});
}

/// Widget declaration (Flux-specific)
class WidgetDecl extends Declaration {
  final String name;
  final int? nameLine;
  final int? nameColumn;
  final List<Parameter> props;
  final List<StateField> stateFields;
  final BuildBlock buildBlock;

  const WidgetDecl(this.name, this.props, this.stateFields, this.buildBlock,
      {this.nameLine, this.nameColumn, required super.line, required super.column});
}

/// Import declaration
class ImportDecl extends Declaration {
  final String path;
  final String? alias;
  final List<String>? show;
  final List<String>? hide;

  const ImportDecl(this.path,
      {this.alias, this.show, this.hide, required super.line, required super.column});
}

// ============================================================================
// Helper types
// ============================================================================

/// Function parameter
class Parameter {
  final String name;
  final int? line;
  final int? column;
  final String? type;
  final Expression? defaultValue;
  final bool isRequired;

  const Parameter(this.name,
      {this.line, this.column, this.type, this.defaultValue, this.isRequired = true});
}

/// State field in a widget
class StateField {
  final String name;
  final int? line;
  final int? column;
  final String? type;
  final Expression initialValue;

  const StateField(this.name, this.initialValue, {this.line, this.column, this.type});
}

/// Build block in a widget
class BuildBlock {
  final Expression body;

  const BuildBlock(this.body);
}

/// Compilation unit (top-level)
class CompilationUnit extends AstNode {
  final List<Statement> declarations;

  const CompilationUnit(this.declarations,
      {required super.line, required super.column});
}
