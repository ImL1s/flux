// Test async/await functionality

// Function that returns a value (simulating async)
fn getValue() {
  return 42
}

// Test await expression
let result = await getValue()
print("Awaited result: " + result)

// Test with computed value
let doubled = await getValue() * 2
print("Doubled: " + doubled)
