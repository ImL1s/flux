// test_flutter - A Flux Flutter Project
// Created with: flux create test_flutter --template flutter

// Counter state
var counter = 0;

fn increment() {
  counter = counter + 1;
  rebuild();
}

fn render() {
  return Column(
    mainAxisAlignment: "center",
    children: [
      Text("Counter: " + counter.toString()),
      SizedBox(height: 16),
      FluxButton(
        label: "Increment",
        onTap: increment
      )
    ]
  );
}

render();
