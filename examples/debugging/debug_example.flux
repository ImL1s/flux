// Flux Debugging Example
// Use this script to practice setting breakpoints and stepping

print("=== Flux Debugger Demo ===");

// 1. Set a breakpoint inside this function
fn calculateSum(n) {
  var total = 0;
  print("Calculating sum for: " + n);
  
  for (var i = 1; i <= n; i = i + 1) {
    if (i % 2 == 0) {
      total = total + (i * 2); // Double even numbers
    } else {
      total = total + i;       // Add odd numbers normally
    }
  }
  
  return total;
}

// 2. Debugging Lists and Maps (Inspect these in Variables view)
var config = {
  "mode": "debug",
  "threshold": 10,
  "active": true
};

var data = [5, 10, 15];

// 3. Main Loop
for (var i = 0; i < len(data); i = i + 1) {
  var input = data[i];
  var result = calculateSum(input);
  print("Input: " + input + " -> Result: " + result);
}

print("=== Recursive Debugging ===");

// 4. Step through recursion
fn factorial(n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}

var fact5 = factorial(5);
print("Factorial(5) = " + fact5);
