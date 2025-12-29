// Test List and Map support

// List literal
let list = [1, 2, 3, 4, 5]
print("List: ")
print(list)
print("First element: ")
print(list[0])
print("Length: ")
print(len(list))

// Map literal
let person = {"name": "Flux", "version": 2, "awesome": true}
print("Map: ")
print(person)
print("Name: ")
print(person["name"])

// Standard library functions
print("\n--- Math Functions ---")
print("abs(-5): ")
print(abs(-5))
print("max(3, 7): ")
print(max(3, 7))
print("sqrt(16): ")
print(sqrt(16))

print("\n--- String Functions ---")
let greeting = "  Hello World  "
print("Original: ")
print(greeting)
print("Trimmed: ")
print(trim(greeting))
print("Upper: ")
print(upper("hello"))

print("\n--- List Functions ---")
let nums = [3, 1, 4, 1, 5, 9]
print("Original: ")
print(nums)
print("Reversed: ")
print(reverse(nums))

print("\n--- Type Checking ---")
print("type(42): ")
print(type(42))
print("type('hello'): ")
print(type("hello"))
print("type([1,2]): ")
print(type(list))
