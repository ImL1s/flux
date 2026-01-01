// Flux Standard Library - Timer Module Example
// Demonstrates async timing operations

print("=== Timer Module Demo ===");

print("\n--- Simple Delay ---");
print("Starting timer...");
await timer.delay(1000);
print("1 second has passed!");

print("\n--- Countdown Timer ---");
for (var i = 3; i > 0; i = i - 1) {
  print(i + "...");
  await timer.delay(500);
}
print("Go!");

print("\n--- Sequential Operations ---");
var steps = ["Connecting", "Authenticating", "Loading data", "Complete"];
for (var i = 0; i < len(steps); i = i + 1) {
  print(steps[i] + "...");
  await timer.delay(300);
}

print("\n--- Timed Task Simulation ---");
async fn longRunningTask() {
  print("Task started...");
  await timer.delay(1500);
  print("Task completed!");
  return "result_data";
}

var result = await longRunningTask();
print("Got result: " + result);

print("\n--- Animation Frames (Simulated) ---");
var frames = ["|", "/", "-", "\\"];
for (var cycle = 0; cycle < 2; cycle = cycle + 1) {
  for (var i = 0; i < len(frames); i = i + 1) {
    print("Loading " + frames[i]);
    await timer.delay(150);
  }
}
print("Loading complete!");

print("\n=== Complete! ===");
