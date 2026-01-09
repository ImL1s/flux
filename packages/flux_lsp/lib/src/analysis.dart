/// Flux source code analyzer
///
/// Wraps the flux_compiler to provide analysis services for the LSP

import 'package:flux_compiler/flux_compiler.dart';
import 'protocol.dart';
import 'scope_analysis.dart';

/// Analysis result containing AST, diagnostics, and scope info
class AnalysisResult {
  final CompilationUnit? ast;
  final List<Diagnostic> diagnostics;
  final ScopeAnalysisResult? scopeResult;

  AnalysisResult({this.ast, this.diagnostics = const [], this.scopeResult});
}

/// Analyzes Flux source code and provides symbol information
class FluxAnalyzer {
  /// Cache scope result to avoid re-parsing for every hover/def request
  /// In a real server this should be better managed per URI
  final Map<String, ScopeAnalysisResult> _scopeCache = {};

  /// Parse source code and return analysis result with diagnostics
  AnalysisResult analyze(String source, String uri) {
    final lexer = Lexer(source);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final ast = parser.parse();

    final diagnostics = <Diagnostic>[];

    for (final error in parser.errors) {
      if (error.token.line == 0) continue; // Skip if no line info

      int line = error.token.line - 1;
      int column = error.token.column - 1;

      diagnostics.add(Diagnostic(
        range: Range(
          Position(line, column),
          Position(line, column + error.token.lexeme.length),
        ),
        severity: DiagnosticSeverity.error,
        message: error.message,
        source: 'flux',
      ));
    }

    // Run Scope Analysis
    final scopeAnalyzer = ScopeAnalyzer();
    try {
      scopeAnalyzer.analyze(ast);
      _scopeCache[uri] = scopeAnalyzer.result;
      return AnalysisResult(
          ast: ast,
          diagnostics: diagnostics,
          scopeResult: scopeAnalyzer.result);
    } catch (e) {
      // If scope analysis fails (e.g. malformed AST), just return diagnostics
      // print('Scope analysis failed: $e');
      return AnalysisResult(ast: ast, diagnostics: diagnostics);
    }
  }

  /// Get definition location for symbol at position
  Location? getDefinition(String source, String uri, Position position) {
    final result = _scopeCache[uri];
    if (result == null) return null;

    // Find usage at this position
    for (final entry in result.usages.entries) {
      final loc = entry.key;
      // Check if position is within usage range
      if (loc.line == position.line &&
          position.character >= loc.column &&
          position.character <= loc.column + loc.length) {
        final def = entry.value;
        return Location(
          uri: uri,
          range: def.location.toRange(),
        );
      }
    }

    return null;
  }

  /// Get all references for symbol at position
  List<Location>? getReferences(String source, String uri, Position position) {
    final result = _scopeCache[uri];
    if (result == null) return null;

    Symbol? targetSymbol;

    // 1. Is cursor on usage?
    for (final entry in result.usages.entries) {
      final loc = entry.key;
      if (loc.line == position.line &&
          position.character >= loc.column &&
          position.character <= loc.column + loc.length) {
        targetSymbol = entry.value;
        break;
      }
    }

    // 2. Is cursor on definition?
    if (targetSymbol == null) {
      for (final def in result.definitions) {
        final loc = def.location;
        if (loc.line == position.line &&
            position.character >= loc.column &&
            position.character <= loc.column + loc.length) {
          targetSymbol = def;
          break;
        }
      }
    }

    if (targetSymbol == null) return null;

    final locations = <Location>[];

    // Add definition itself
    locations.add(Location(uri: uri, range: targetSymbol.location.toRange()));

    // Add all usages
    for (final entry in result.usages.entries) {
      if (entry.value == targetSymbol) {
        locations.add(Location(uri: uri, range: entry.key.toRange()));
      }
    }

    return locations;
  }

  /// Get the token at the given offset in the source
  ///
  /// Properly calculates offset by tracking line positions and matching
  /// against token line/column information.
  Token? getTokenAt(String source, int offset) {
    final lexer = Lexer(source);
    final tokens = lexer.tokenize();

    // Calculate line offsets for offset-to-position conversion
    final lines = source.split('\n');
    final lineOffsets = <int>[0];
    for (int i = 0; i < lines.length - 1; i++) {
      lineOffsets.add(lineOffsets.last + lines[i].length + 1); // +1 for newline
    }

    // Convert offset to line and column
    int targetLine = 0;
    int targetColumn = 0;
    for (int i = 0; i < lineOffsets.length; i++) {
      if (i == lineOffsets.length - 1 || offset < lineOffsets[i + 1]) {
        targetLine = i + 1; // 1-indexed
        targetColumn = offset - lineOffsets[i]; // 0-indexed
        break;
      }
    }

    // Find the token at this position
    for (final token in tokens) {
      if (token.line == targetLine) {
        final tokenStart = token.column - 1; // Convert to 0-indexed
        final tokenEnd = tokenStart + token.lexeme.length;
        if (targetColumn >= tokenStart && targetColumn < tokenEnd) {
          return token;
        }
      }
    }

    return null;
  }

  /// Get hover information for a position
  Hover? getHover(String source, Position position) {
    final lines = source.split('\n');
    if (position.line >= lines.length) return null;

    final line = lines[position.line];
    final word = _getWordAt(line, position.character);

    if (word == null) return null;

    // Check for keyword documentation
    final doc = _keywordDocs[word];
    if (doc != null) {
      return Hover(contents: doc);
    }

    // Check for built-in widget documentation
    final widgetDoc = _widgetDocs[word];
    if (widgetDoc != null) {
      return Hover(contents: widgetDoc);
    }

    return null;
  }

  /// Get word at character position in line
  String? _getWordAt(String line, int character) {
    if (character >= line.length) return null;

    // Find word boundaries
    int start = character;
    int end = character;

    while (start > 0 && _isWordChar(line[start - 1])) {
      start--;
    }
    while (end < line.length && _isWordChar(line[end])) {
      end++;
    }

    if (start == end) return null;
    return line.substring(start, end);
  }

  bool _isWordChar(String c) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(c);
  }

  /// Get completion context at position
  CompletionContext getCompletionContext(String source, Position position) {
    final lines = source.split('\n');
    if (position.line >= lines.length) return CompletionContext();

    // Look back to find if we are in a widget property context
    // heurstic: look for "WidgetName {" or "WidgetName("

    String textBefore = "";
    for (int i = 0; i < position.line; i++) {
      textBefore += lines[i] + "\n";
    }
    textBefore += lines[position.line].substring(0, position.character);

    // Check if we are inside a brace
    int braceCount = 0;
    for (int i = 0; i < textBefore.length; i++) {
      if (textBefore[i] == '{') braceCount++;
      if (textBefore[i] == '}') braceCount--;
    }

    if (braceCount > 0) {
      // Find the last opening brace and what comes before it
      int lastBrace = textBefore.lastIndexOf('{');
      if (lastBrace > 0) {
        String beforeBrace = textBefore.substring(0, lastBrace).trim();
        // Get the last word before {
        final matches = RegExp(r'([a-zA-Z0-9_]+)\s*$').allMatches(beforeBrace);
        if (matches.isNotEmpty) {
          String widgetName = matches.last.group(1)!;
          // Simple check: starts with uppercase -> Widget
          if (widgetName.isNotEmpty &&
              widgetName[0].toUpperCase() == widgetName[0]) {
            return CompletionContext(
                isWidgetProperty: true, widgetName: widgetName);
          }
        }
      }
    }

    return CompletionContext();
  }

  /// Keyword documentation
  static const _keywordDocs = <String, String>{
    'widget': '''
**widget** - Widget Declaration

Declares a new Flux widget with optional state and props.

```flux
widget MyWidget {
  state count = 0;
  props title;
  
  build {
    Column {
      Text(title)
      Button("Click", onPressed: fn() {
        count = count + 1;
      })
    }
  }
}
```
''',
    'fn': '''
**fn** - Function Declaration

Declares a function with optional parameters.

```flux
fn greet(name) {
  return "Hello, " + name;
}
```
''',
    'async': '''
**async** - Async Function Modifier

Marks a function as asynchronous.

```flux
async fn fetchData() {
  var response = await http.get("https://api.example.com");
  return response;
}
```
''',
    'await': '''
**await** - Await Expression

Suspends execution until the awaited Future completes.

```flux
var result = await someAsyncFunction();
```
''',
    'state': '''
**state** - State Declaration

Declares a reactive state variable in a widget.

```flux
widget Counter {
  state count = 0;
  
  build {
    Text("Count: " + count)
  }
}
```
''',
    'props': '''
**props** - Props Declaration

Declares a property that must be passed to the widget.

```flux
widget Greeting {
  props name;
  
  build {
    Text("Hello, " + name)
  }
}
```
''',
    'build': '''
**build** - Build Block

Defines the widget's UI tree.

```flux
widget MyWidget {
  build {
    Column {
      Text("Hello")
    }
  }
}
```
''',
    'var': '''
**var** - Variable Declaration

Declares a mutable local variable.

```flux
var x = 10;
var name = "Flux";
```
''',
    'if': '''
**if** - Conditional Statement

Executes code conditionally.

```flux
if (condition) {
  // then branch
} else {
  // else branch
}
```
''',
    'while': '''
**while** - While Loop

Repeats code while condition is true.

```flux
while (count < 10) {
  count = count + 1;
}
```
''',
    'for': '''
**for** - For Loop

Repeats code with initialization, condition, and increment.

```flux
for (var i = 0; i < 10; i = i + 1) {
  print(i);
}
```
''',
    'try': '''
**try** - Exception Handling

Catches exceptions thrown in the try block.

```flux
try {
  riskyOperation();
} catch (e) {
  print("Error: " + e);
}
```
''',
    'throw': '''
**throw** - Throw Exception

Throws an exception.

```flux
throw "Something went wrong";
```
''',
    'return': '''
**return** - Return Statement

Returns a value from a function.

```flux
fn add(a, b) {
  return a + b;
}
```
''',
    'class': '''
**class** - Class Declaration

Declares a class with methods.

```flux
class Person {
  fn greet() {
    return "Hello!";
  }
}
```
''',
    'import': '''
**import** - Import Module

Imports another Flux module.

```flux
import "utils.flux";
```
''',
  };

  /// Widget documentation
  static const _widgetDocs = <String, String>{
    'Column': '''
**Column** - Vertical Layout

Arranges children vertically.

```flux
Column {
  Text("First")
  Text("Second")
}
```
''',
    'Row': '''
**Row** - Horizontal Layout

Arranges children horizontally.

```flux
Row {
  Icon("star")
  Text("Rating")
}
```
''',
    'Text': '''
**Text** - Text Display

Displays text content.

```flux
Text("Hello, World!")
Text(variable)
```
''',
    'Button': '''
**Button** - Interactive Button

A tappable button with optional handler.

```flux
Button("Click Me", onPressed: fn() {
  // handle tap
})
```
''',
    'TextField': '''
**TextField** - Text Input

A text input field.

```flux
TextField(hint: "Enter name", onChanged: fn(value) {
  name = value;
})
```
''',
    'Container': '''
**Container** - Box Container

A box with optional styling.

```flux
Container(color: "#FF0000", padding: 16) {
  Text("Styled box")
}
```
''',
    'ListView': '''
**ListView** - Scrollable List

A scrollable list of items.

```flux
ListView(items: myList, builder: fn(item) {
  ListTile(title: item.name)
})
```
''',
    'Scaffold': '''
**Scaffold** - App Structure

Basic app structure with appBar and body.

```flux
Scaffold(
  appBar: AppBar(title: "My App"),
  body: Column {
    // content
  }
)
```
''',
  };
}
