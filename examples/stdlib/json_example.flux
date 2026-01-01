// Flux Standard Library - JSON Module Example
// Demonstrates JSON parsing and serialization

print("=== JSON Module Demo ===");

// --- Parsing JSON ---
print("\n--- Parsing JSON Strings ---");

var jsonString = '{"name": "Flux", "version": 2, "features": ["fast", "simple", "powerful"]}';
var obj = json.parse(jsonString);

print("Name: " + obj.name);
print("Version: " + obj.version);
print("Features:");
for (var i = 0; i < len(obj.features); i = i + 1) {
  print("  - " + obj.features[i]);
}

// --- Complex Nested JSON ---
print("\n--- Nested JSON ---");

var complexJson = '{
  "user": {
    "id": 123,
    "name": "Alice",
    "email": "alice@example.com"
  },
  "posts": [
    {"id": 1, "title": "Hello World"},
    {"id": 2, "title": "Flux is awesome"}
  ],
  "meta": {
    "total": 2,
    "page": 1
  }
}';

var data = json.parse(complexJson);
print("User: " + data.user.name + " (" + data.user.email + ")");
print("Posts:");
for (var i = 0; i < len(data.posts); i = i + 1) {
  var post = data.posts[i];
  print("  [" + post.id + "] " + post.title);
}

// --- Stringifying Objects ---
print("\n--- Serializing to JSON ---");

var newData = {
  "message": "Hello from Flux!",
  "timestamp": 1704067200,
  "tags": ["greeting", "test"],
  "metadata": {
    "source": "flux_script",
    "version": "1.0"
  }
};

var jsonOutput = json.stringify(newData);
print("JSON Output:");
print(jsonOutput);

// --- Round-trip Test ---
print("\n--- Round-trip Test ---");

var original = {"a": 1, "b": [2, 3], "c": {"d": true}};
var serialized = json.stringify(original);
var restored = json.parse(serialized);

print("Original: " + original);
print("Serialized: " + serialized);
print("Restored.a: " + restored.a);
print("Restored.b[1]: " + restored.b[1]);
print("Restored.c.d: " + restored.c.d);

// --- Error Handling ---
print("\n--- Error Handling ---");

try {
  var invalid = json.parse("not valid json {{{");
} catch (e) {
  print("Parse error caught: " + e);
}

print("\n=== Complete! ===");
