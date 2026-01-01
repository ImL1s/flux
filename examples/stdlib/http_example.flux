// Flux Standard Library - HTTP Module Example
// Demonstrates making HTTP requests using the http module

print("=== HTTP GET Request ===");

// Simple GET request
async fn fetchUserData() {
  try {
    var response = await http.get("https://jsonplaceholder.typicode.com/users/1");
    
    if (response.status == 200) {
      var user = json.parse(response.body);
      print("User Name: " + user.name);
      print("Email: " + user.email);
      print("City: " + user.address.city);
    } else {
      print("Request failed with status: " + response.status);
    }
  } catch (e) {
    print("Network error: " + e);
  }
}

await fetchUserData();

print("\n=== HTTP POST Request ===");

async fn createPost() {
  var newPost = {
    "title": "Hello from Flux!",
    "body": "This post was created using Flux's HTTP module.",
    "userId": 1
  };
  
  try {
    var response = await http.post(
      "https://jsonplaceholder.typicode.com/posts",
      newPost
    );
    
    if (response.status == 201) {
      var created = json.parse(response.body);
      print("Created post with ID: " + created.id);
      print("Title: " + created.title);
    }
  } catch (e) {
    print("Failed to create post: " + e);
  }
}

await createPost();

print("\n=== Fetching Multiple Items ===");

async fn fetchTodos() {
  var response = await http.get("https://jsonplaceholder.typicode.com/todos?_limit=3");
  var todos = json.parse(response.body);
  
  print("First 3 TODOs:");
  for (var i = 0; i < len(todos); i = i + 1) {
    var todo = todos[i];
    var status = todo.completed ? "✓" : "○";
    print("  " + status + " " + todo.title);
  }
}

await fetchTodos();

print("\n=== Complete! ===");
