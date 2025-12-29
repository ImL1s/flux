/// Flux Language - Token definitions
/// 
/// This file defines all token types used by the Flux lexer.

/// Token types for the Flux language
enum TokenType {
  // Literals
  integer,
  double_,
  string,
  boolean,
  null_,

  // Identifiers
  identifier,

  // Keywords
  var_,
  let_,
  fn,
  async_,
  await_,
  if_,
  else_,
  for_,
  while_,
  return_,
  widget,
  state,
  build,
  import_,
  export_,
  class_,
  extends_,
  implements_,
  this_,
  super_,
  new_,
  true_,
  false_,
  try_,
  catch_,
  finally_,
  throw_,

  // Operators
  plus, // +
  minus, // -
  star, // *
  slash, // /
  percent, // %
  equal, // =
  equalEqual, // ==
  notEqual, // !=
  less, // <
  lessEqual, // <=
  greater, // >
  greaterEqual, // >=
  and, // &&
  or, // ||
  not, // !
  plusEqual, // +=
  minusEqual, // -=
  starEqual, // *=
  slashEqual, // /=
  arrow, // ->
  fatArrow, // =>
  dot, // .
  dotDot, // ..
  question, // ?
  questionDot, // ?.
  colon, // :

  // Delimiters
  leftParen, // (
  rightParen, // )
  leftBrace, // {
  rightBrace, // }
  leftBracket, // [
  rightBracket, // ]
  comma, // ,
  semicolon, // ;

  // Special
  interpolationStart, // ${
  newline,
  eof,
  error,
  
  // Aliases for compatibility/clarity
  bangEqual, // != (alias for notEqual)
}

/// Represents a single token in the source code
class Token {
  final TokenType type;
  final String lexeme;
  final Object? literal;
  final int line;
  final int column;

  const Token({
    required this.type,
    required this.lexeme,
    this.literal,
    required this.line,
    required this.column,
  });

  @override
  String toString() => 'Token($type, "$lexeme", $literal, line: $line, col: $column)';
}

/// Keywords map for quick lookup
const keywords = <String, TokenType>{
  'var': TokenType.var_,
  'let': TokenType.let_,
  'fn': TokenType.fn,
  'async': TokenType.async_,
  'await': TokenType.await_,
  'if': TokenType.if_,
  'else': TokenType.else_,
  'for': TokenType.for_,
  'while': TokenType.while_,
  'return': TokenType.return_,
  'widget': TokenType.widget,
  'state': TokenType.state,
  'build': TokenType.build,
  'import': TokenType.import_,
  'export': TokenType.export_,
  'class': TokenType.class_,
  'extends': TokenType.extends_,
  'implements': TokenType.implements_,
  'this': TokenType.this_,
  'super': TokenType.super_,
  'new': TokenType.new_,
  'true': TokenType.true_,
  'false': TokenType.false_,
  'null': TokenType.null_,
  'try': TokenType.try_,
  'catch': TokenType.catch_,
  'finally': TokenType.finally_,
  'throw': TokenType.throw_,
};
