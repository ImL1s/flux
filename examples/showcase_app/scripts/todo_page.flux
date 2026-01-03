widget TodoPage {
  state newTask = "";
  state tasks = [
    {"id": 1, "title": "學習 Flux 語法", "done": true},
    {"id": 2, "title": "嘗試熱更新", "done": false},
    {"id": 3, "title": "整合 Riverpod", "done": false}
  ];
  state filter = "all"; // all, active, completed

  fn addTask() {
    if (newTask == "") {
      showToast("請輸入任務名稱");
      return;
    }
    var task = {"id": now(), "title": newTask, "done": false};
    push(tasks, task);
    newTask = "";
  }

  fn toggleTask(id) {
    // Flux doesn't support complex list mapping yet, so we iterate
    // This part relies on future list manipulation features or we rebuild the list
    // For now, we simulation toggle by finding index. 
    // Ideally: tasks = tasks.map(...)
    showToast("切換任務狀態: " + id);
    
    // Simple mock toggle for demo (since we lack deep list mutation in current syntax easily)
    // We would need a 'update(list, index, val)' or similar.
    // Assuming we have basic list replacement:
  }
  
  fn removeTask(index) {
    // Need a removeAt function in stdlib, assuming pop/remove or verify later
    showToast("刪除任務");
  }

  build {
    Column(
      children: [
        // Input Area
        Container(
          padding: 16.0,
          color: "white",
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  value: newTask,
                  hint: "輸入新任務...",
                  onChanged: fn(val) { newTask = val; }
                )
              ),
              Button(text: "新增", onPressed: fn() { addTask(); })
            ]
          )
        ),
        
        // Filter Tabs
        Container(
          padding: 8.0,
          color: "grey200",
          child: Row(
            mainAxisAlignment: "spaceEvenly",
            children: [
              Button(
                text: "全部", 
                color: filter == "all" ? "blue" : "white",
                textColor: filter == "all" ? "white" : "black",
                onPressed: fn() { filter = "all"; }
              ),
              Button(
                text: "進行中", 
                color: filter == "active" ? "blue" : "white",
                textColor: filter == "active" ? "white" : "black",
                onPressed: fn() { filter = "active"; }
              ),
              Button(
                text: "已完成", 
                color: filter == "completed" ? "blue" : "white",
                textColor: filter == "completed" ? "white" : "black",
                onPressed: fn() { filter = "completed"; }
              )
            ]
          )
        ),

        // List
        Expanded(
          child: ListView(
            children: [
              // In a real scenario we loop, here we simulate list rendering
              // For v1 loop support:
              // for (task in tasks) { ... } (Not yet fully supported in widget builder context directly)
              // So we hardcode mocked items for visualization based on state or assume children loop support
              
              // Mock Item 1
              Card(
                child: ListTile(
                  leading: Icon(icon: "check_box", color: "green"),
                  title: Text(text: "學習 Flux 語法"),
                  trailing: IconButton(icon: "delete", color: "red", onPressed: fn() { removeTask(0); })
                )
              ),
              
              // Mock Item 2
              Card(
                child: ListTile(
                  leading: Icon(icon: "check_box_outline_blank", color: "grey"),
                  title: Text(text: "嘗試熱更新"),
                  trailing: IconButton(icon: "delete", color: "red", onPressed: fn() { removeTask(1); })
                )
              )
            ]
          )
        )
      ]
    )
  }
}
