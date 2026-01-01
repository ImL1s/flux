// Flux Language - Async/Await Example
// Demonstrates asynchronous programming

print("=== Async Functions ===");

async fn fetchData(id) {
  print("  [Fetch] Starting request for ID: " + id);
  // Simulate network delay
  await timer.delay(500); 
  print("  [Fetch] Data received for ID: " + id);
  return "Data-" + id;
}

async fn processData(data) {
  print("  [Process] Processing " + data);
  await timer.delay(300);
  return "Processed(" + data + ")";
}

print("Starting pipeline...");
var raw = await fetchData(101);
var result = await processData(raw);
print("Final Result: " + result);

print("\n=== Parallel Execution (Simulated) ===");
// Note: Flux runs single-threaded, but concurrent async tasks can be interleaved

async fn task1() {
  for (var i = 1; i <= 3; i = i + 1) {
    print("Task 1 - Step " + i);
    await timer.delay(200);
  }
}

async fn task2() {
  for (var i = 1; i <= 3; i = i + 1) {
    print("Task 2 - Step " + i);
    await timer.delay(200);
  }
}

print("Running tasks...");
// In a real concurrent runtime, we would use Future.wait([])
// Here we just await them sequentially to show syntax
await task1();
await task2();

print("\n=== Complete! ===");
