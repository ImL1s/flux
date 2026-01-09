/// Flux Language - Lexer (Tokenizer)
///
/// Converts source code into a stream of tokens.

import 'token.dart';

/// Lexer for the Flux language
class Lexer {
  final String source;
  final List<Token> tokens = [];
  final List<LexerError> errors = [];

  int _start = 0;
  int _current = 0;
  int _line = 1;
  int _column = 1;

  Lexer(this.source);

  /// Tokenize the entire source code
  List<Token> tokenize() {
    while (!_isAtEnd) {
      _start = _current;
      _scanToken();
    }

    tokens.add(Token(
      type: TokenType.eof,
      lexeme: '',
      line: _line,
      column: _column,
    ));

    return tokens;
  }

  void _scanToken() {
    final c = _advance();

    switch (c) {
      // Single character tokens
      case '(':
        _addToken(TokenType.leftParen);
      case ')':
        _addToken(TokenType.rightParen);
      case '{':
        _addToken(TokenType.leftBrace);
      case '}':
        _addToken(TokenType.rightBrace);
      case '[':
        _addToken(TokenType.leftBracket);
      case ']':
        _addToken(TokenType.rightBracket);
      case ',':
        _addToken(TokenType.comma);
      case ';':
        _addToken(TokenType.semicolon);
      case ':':
        _addToken(TokenType.colon);

      // One or two character tokens
      case '+':
        _addToken(_match('=') ? TokenType.plusEqual : TokenType.plus);
      case '-':
        _addToken(_match('>')
            ? TokenType.arrow
            : (_match('=') ? TokenType.minusEqual : TokenType.minus));
      case '*':
        _addToken(_match('=') ? TokenType.starEqual : TokenType.star);
      case '%':
        _addToken(TokenType.percent);
      case '=':
        _addToken(_match('=')
            ? TokenType.equalEqual
            : (_match('>') ? TokenType.fatArrow : TokenType.equal));
      case '!':
        _addToken(_match('=') ? TokenType.notEqual : TokenType.not);
      case '<':
        _addToken(_match('=') ? TokenType.lessEqual : TokenType.less);
      case '>':
        _addToken(_match('=') ? TokenType.greaterEqual : TokenType.greater);
      case '&':
        if (_match('&')) {
          _addToken(TokenType.and);
        } else {
          _error('Unexpected character: &');
        }
      case '|':
        if (_match('|')) {
          _addToken(TokenType.or);
        } else {
          _error('Unexpected character: |');
        }
      case '.':
        _addToken(_match('.') ? TokenType.dotDot : TokenType.dot);
      case '?':
        _addToken(_match('.') ? TokenType.questionDot : TokenType.question);

      // Slash or comment
      case '/':
        if (_match('/')) {
          // Single-line comment
          while (_peek != '\n' && !_isAtEnd) {
            _advance();
          }
        } else if (_match('*')) {
          // Multi-line comment
          _multiLineComment();
        } else if (_match('=')) {
          _addToken(TokenType.slashEqual);
        } else {
          _addToken(TokenType.slash);
        }

      // Whitespace
      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace
        break;
      case '\n':
        _line++;
        _column = 1;

      // String literals
      case '"':
        _string('"');
      case "'":
        _string("'");

      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          _error('Unexpected character: $c');
        }
    }
  }

  void _string(String quote) {
    final buffer = StringBuffer();

    while (_peek != quote && !_isAtEnd) {
      if (_peek == '\n') {
        _line++;
        _column = 1;
      }

      if (_peek == '\\') {
        _advance();
        switch (_peek) {
          case 'n':
            buffer.write('\n');
          case 't':
            buffer.write('\t');
          case 'r':
            buffer.write('\r');
          case '\\':
            buffer.write('\\');
          case '"':
            buffer.write('"');
          case "'":
            buffer.write("'");
          case '\$':
            buffer.write('\$');
          default:
            buffer.write(_peek);
        }
        _advance();
      } else if (_peek == '\$' && _peekNext == '{') {
        // String interpolation
        if (buffer.isNotEmpty) {
          _addTokenWithLiteral(TokenType.string, buffer.toString());
          buffer.clear();
        }
        _advance(); // $
        _advance(); // {
        _addToken(TokenType.interpolationStart);
        // The parser will handle the expression inside
        return;
      } else {
        buffer.write(_peek);
        _advance();
      }
    }

    if (_isAtEnd) {
      _error('Unterminated string');
      return;
    }

    _advance(); // Closing quote
    _addTokenWithLiteral(TokenType.string, buffer.toString());
  }

  void _number() {
    while (_isDigit(_peek)) {
      _advance();
    }

    // Look for decimal part
    if (_peek == '.' && _isDigit(_peekNext)) {
      _advance(); // Consume '.'
      while (_isDigit(_peek)) {
        _advance();
      }
      final value = double.parse(source.substring(_start, _current));
      _addTokenWithLiteral(TokenType.double_, value);
    } else {
      final value = int.parse(source.substring(_start, _current));
      _addTokenWithLiteral(TokenType.integer, value);
    }
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek)) {
      _advance();
    }

    final text = source.substring(_start, _current);
    final type = keywords[text] ?? TokenType.identifier;

    if (type == TokenType.true_) {
      _addTokenWithLiteral(type, true);
    } else if (type == TokenType.false_) {
      _addTokenWithLiteral(type, false);
    } else {
      _addToken(type);
    }
  }

  void _multiLineComment() {
    int nesting = 1;
    while (nesting > 0 && !_isAtEnd) {
      if (_peek == '/' && _peekNext == '*') {
        _advance();
        _advance();
        nesting++;
      } else if (_peek == '*' && _peekNext == '/') {
        _advance();
        _advance();
        nesting--;
      } else {
        if (_peek == '\n') {
          _line++;
          _column = 1;
        }
        _advance();
      }
    }
  }

  // Helper methods
  bool get _isAtEnd => _current >= source.length;

  String _advance() {
    final c = source[_current++];
    _column++;
    return c;
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (source[_current] != expected) return false;
    _current++;
    _column++;
    return true;
  }

  String get _peek => _isAtEnd ? '\x00' : source[_current];

  String get _peekNext {
    if (_current + 1 >= source.length) return '\x00';
    return source[_current + 1];
  }

  void _addToken(TokenType type) {
    final text = source.substring(_start, _current);
    tokens.add(Token(
      type: type,
      lexeme: text,
      line: _line,
      column: _column - text.length,
    ));
  }

  void _addTokenWithLiteral(TokenType type, Object literal) {
    final text = source.substring(_start, _current);
    tokens.add(Token(
      type: type,
      lexeme: text,
      literal: literal,
      line: _line,
      column: _column - text.length,
    ));
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122) || // a-z
        c == '_';
  }

  bool _isAlphaNumeric(String c) => _isAlpha(c) || _isDigit(c);

  void _error(String message) {
    errors.add(LexerError(message, _line, _column));
    tokens.add(Token(
      type: TokenType.error,
      lexeme: source.substring(_start, _current),
      line: _line,
      column: _column,
    ));
  }
}

/// Represents a lexer error
class LexerError {
  final String message;
  final int line;
  final int column;

  LexerError(this.message, this.line, this.column);

  @override
  String toString() => 'LexerError: $message at line $line, column $column';
}
