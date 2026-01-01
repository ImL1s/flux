// Flux Language - Functions & Closures Example
// Demonstrates function definitions, higher-order functions, and closures

print("=== Standard Functions ===");

fn add(a, b) {
  return a + b;
}

print("add(2, 3) = " + add(2, 3));

print("\n=== Recursion ===");

fn fib(n) {
  if (n < 2) return n;
  return fib(n - 1) + fib(n - 2);
}

print("fib(10) = " + fib(10));

print("\n=== Higher-Order Functions ===");

fn map(list, transformFn) {
  var result = [];
  for (var i = 0; i < len(list); i = i + 1) {
    var item = list[i];
    result = result + [transformFn(item)];
  }
  return result;
}

fn double(x) { return x * 2; }
fn square(x) { return x * x; }

var nums = [1, 2, 3, 4, 5];
print("Original: " + nums);

var doubled = map(nums, double);
print("Doubled: " + doubled);

var squared = map(nums, square);
print("Squared: " + squared);

print("\n=== Closures ===");

fn makeCounter(start) {
  var count = start;
  
  fn increment() {
    count = count + 1;
    return count;
  }
  
  return increment;
}

var counterA = makeCounter(0);
var counterB = makeCounter(100);

print("Counter A: " + counterA()); // 1
print("Counter A: " + counterA()); // 2
print("Counter B: " + counterB()); // 101
print("Counter A: " + counterA()); // 3

print("\n=== Lambda-like Functions (Anonymous) ===");
// Flux supports assigning functions to variables

var multiply = fn(a, b) {
  return a * b;
};

print("multiply(5, 4) = " + multiply(5, 4));

var operations = {
  "add": add,
  "mul": multiply
};

print("dict['add'](10, 20) = " + operations["add"](10, 20));

print("\n=== Complete! ===");
