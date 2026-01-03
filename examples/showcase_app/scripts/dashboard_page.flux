widget DashboardPage {
  state loading = false;
  state data = {"visitors": 0, "sales": 0, "orders": 0};
  state lastUpdate = "從未";

  async fn refreshData() {
    loading = true;
    try {
      // Create artificial delay for UX
      // await delay(1000); 
      
      // Call native Dio function
      var result = await fetchData();
      
      if (result != null) {
         data = result;
         lastUpdate = now(); // Needs timestamp formatting
         showToast("數據已更新");
      }
    } catch (e) {
      showToast("更新失敗: " + toString(e));
    }
    loading = false;
  }

  build {
    Column(
      children: [
        // Header
        Container(
          padding: 20.0,
          color: "blueGrey",
          width: "infinity",
          child: Column(
             children: [
               Text(text: "營運總覽", style: {"color": "white", "fontSize": 24.0}),
               SizedBox(height: 8.0),
               Text(text: "最後更新: " + lastUpdate, style: {"color": "white70"})
             ]
          )
        ),
        
        // Refresh Button
        if (loading) {
           Padding(padding: 20.0, child: CircularProgressIndicator())
        } else {
           Padding(
             padding: 10.0, 
             child: Button(text: "立即刷新數據", onPressed: async fn() { await refreshData(); })
           )
        }
        ,

        // Stats Grid
        Padding(
          padding: 16.0,
          child: Column(
            children: [
              // Row 1
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: "blue50",
                      child: Container(
                        padding: 16.0,
                        child: Column(
                          children: [
                            Icon(icon: "people", size: 32.0, color: "blue"),
                            Text(text: toString(data["visitors"]), style: {"fontSize": 24.0, "fontWeight": "bold"}),
                            Text(text: "今日訪客")
                          ]
                        )
                      )
                    )
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Card(
                      color: "green50",
                      child: Container(
                        padding: 16.0,
                        child: Column(
                          children: [
                            Icon(icon: "attach_money", size: 32.0, color: "green"),
                            Text(text: "$" + toString(data["sales"]), style: {"fontSize": 24.0, "fontWeight": "bold"}),
                            Text(text: "今日營收")
                          ]
                        )
                      )
                    )
                  )
                ]
              ),
              
              SizedBox(height: 16.0),
              
              // Row 2
              Card(
                color: "orange50",
                child: Container(
                  padding: 16.0,
                  width: "infinity",
                  child: Row(
                    mainAxisAlignment: "center",
                    children: [
                      Icon(icon: "shopping_cart", size: 32.0, color: "orange"),
                      SizedBox(width: 16.0),
                      Column(
                        children: [
                          Text(text: toString(data["orders"]), style: {"fontSize": 24.0, "fontWeight": "bold"}),
                          Text(text: "待處理訂單")
                        ]
                      )
                    ]
                  )
                )
              )
            ]
          )
        )
      ]
    )
  }
}
