// Flux Language - Classes and OOP Example
// Demonstrates class definition, methods, inheritance, and instances

// Simple class with fields and methods
class Animal {
  var name;
  var age;
  
  fn init(n, a) {
    this.name = n;
    this.age = a;
  }
  
  fn speak() {
    print(this.name + " makes a sound");
  }
  
  fn describe() {
    print(this.name + " is " + this.age + " years old");
  }
}

// Inheritance
class Dog extends Animal {
  var breed;
  
  fn init(n, a, b) {
    super.init(n, a);
    this.breed = b;
  }
  
  fn speak() {
    print(this.name + " says: Woof!");
  }
  
  fn fetch() {
    print(this.name + " fetches the ball!");
  }
}

class Cat extends Animal {
  fn speak() {
    print(this.name + " says: Meow!");
  }
  
  fn climb() {
    print(this.name + " climbs a tree!");
  }
}

// Create instances
print("=== Creating Animals ===");
var dog = Dog("Buddy", 3, "Golden Retriever");
var cat = Cat("Whiskers", 5);

// Call methods
print("\n=== Animal Sounds ===");
dog.speak();
cat.speak();

print("\n=== Descriptions ===");
dog.describe();
cat.describe();

print("\n=== Special Abilities ===");
dog.fetch();
cat.climb();

// Class with computed properties
class Rectangle {
  var width;
  var height;
  
  fn init(w, h) {
    this.width = w;
    this.height = h;
  }
  
  fn area() {
    return this.width * this.height;
  }
  
  fn perimeter() {
    return 2 * (this.width + this.height);
  }
}

print("\n=== Rectangle Example ===");
var rect = Rectangle(10, 5);
print("Width: " + rect.width);
print("Height: " + rect.height);
print("Area: " + rect.area());
print("Perimeter: " + rect.perimeter());
