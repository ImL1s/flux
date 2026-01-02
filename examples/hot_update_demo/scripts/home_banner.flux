widget HomeBanner {
  state count = 5
  state theme = "blue"
  state items = ["蘋果", "香蕉", "橘子"]

  build {
    Container(
      padding: 20.0,
      color: theme,
      child: Column(
        children: [
          Text(text: "🔥 Flux 動態 UI 展示", style: {"fontSize": 28.0, "color": "white", "fontWeight": "bold"}),
          SizedBox(height: 16.0),
          
          Text(text: "📊 計數器狀態管理", style: {"fontSize": 18.0, "color": "white"}),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: "center",
            children: [
              Button(text: "➖", onPressed: fn() { count = count - 1; }),
              SizedBox(width: 20.0),
              Text(text: count, style: {"fontSize": 32.0, "color": "white", "fontWeight": "bold"}),
              SizedBox(width: 20.0),
              Button(text: "➕", onPressed: fn() { count = count + 1; })
            ]
          ),
          SizedBox(height: 24.0),
          
          Text(text: "🎨 動態主題切換", style: {"fontSize": 18.0, "color": "white"}),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: "center",
            children: [
              Button(text: "🔵 藍色", onPressed: fn() { theme = "blue"; }),
              SizedBox(width: 8.0),
              Button(text: "🟢 綠色", onPressed: fn() { theme = "green"; }),
              SizedBox(width: 8.0),
              Button(text: "🟠 橘色", onPressed: fn() { theme = "orange"; }),
              SizedBox(width: 8.0),
              Button(text: "🟣 紫色", onPressed: fn() { theme = "purple"; })
            ]
          ),
          SizedBox(height: 24.0),
          
          Text(text: "📝 動態列表操作", style: {"fontSize": 18.0, "color": "white"}),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: "center",
            children: [
              Button(text: "➕ 芒果", onPressed: fn() { push(items, "芒果"); }),
              SizedBox(width: 8.0),
              Button(text: "➕ 草莓", onPressed: fn() { push(items, "草莓"); }),
              SizedBox(width: 8.0),
              Button(text: "🗑️ 清空", onPressed: fn() { items = []; })
            ]
          ),
          SizedBox(height: 8.0),
          Container(
            padding: 12.0,
            color: "white",
            child: Text(text: items, style: {"fontSize": 16.0, "color": "black"})
          ),
          SizedBox(height: 24.0),
          
          Container(
            padding: 12.0,
            color: "white",
            child: Column(
              children: [
                Text(text: "💡 修改此腳本試試！", style: {"fontSize": 14.0, "color": "grey"}),
                Text(text: "路徑: scripts/home_banner.flux", style: {"fontSize": 12.0, "color": "grey"})
              ]
            )
          )
        ]
      )
    )
  }
}
