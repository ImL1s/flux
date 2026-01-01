// Flux Language - Exception Handling Example
// Demonstrates try-catch-finally blocks and error handling

print("=== Basic Try-Catch ===");

fn divide(a, b) {
  if (b == 0) {
    throw "Division by zero error";
  }
  return a / b;
}

try {
  var result = divide(10, 2);
  print("10 / 2 = " + result);
  
  var bad = divide(10, 0);
  print("This won't print");
} catch (e) {
  print("Caught error: " + e);
}

print("\n=== Try-Catch-Finally ===");

fn riskyOperation() {
  print("Starting risky operation...");
  throw "Something went wrong!";
}

try {
  riskyOperation();
} catch (e) {
  print("Error handled: " + e);
} finally {
  print("Cleanup completed (always runs)");
}

print("\n=== Nested Try-Catch ===");

fn outerFunction() {
  try {
    innerFunction();
  } catch (e) {
    print("Outer caught: " + e);
    throw "Re-thrown from outer";
  }
}

fn innerFunction() {
  throw "Error from inner function";
}

try {
  outerFunction();
} catch (e) {
  print("Top-level caught: " + e);
}

print("\n=== Error Recovery ===");

fn parseNumber(str) {
  if (type(str) != "String") {
    throw "Expected string input";
  }
  // Simulated parsing
  if (str == "42") {
    return 42;
  }
  throw "Cannot parse: " + str;
}

var inputs = ["42", "invalid", "100"];
for (var i = 0; i < len(inputs); i = i + 1) {
  var input = inputs[i];
  try {
    var num = parseNumber(input);
    print("Parsed '" + input + "' -> " + num);
  } catch (e) {
    print("Failed to parse '" + input + "': " + e);
  }
}

print("\n=== Complete! ===");
