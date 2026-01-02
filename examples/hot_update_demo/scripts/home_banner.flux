// === 可熱更新的首頁 Banner ===
// 修改 theme 變量來切換主題，無需重新編譯 App！

widget HomeBanner {
  // 🔄 修改這裡的值來觸發熱更新！
  // 可選值: "spring", "mother", "dragon"
  state theme = "spring";
  
  build {
    // 根據 theme 動態決定顏色和文字
    var color = "green";
    var title = "🌸 春季特賣";
    var subtitle = "全場 30% OFF";
    
    if (theme == "mother") {
      color = "pink";
      title = "💐 母親節快樂";
      subtitle = "為媽媽準備一份驚喜";
    }
    
    if (theme == "dragon") {
      color = "orange";
      title = "🐲 端午節";
      subtitle = "粽子禮盒 5 折起";
    }
    
    return Container(
      color: color,
      padding: 24,
      child: Column(
        children: [
          Text(text: title, style: {"fontSize": 28, "fontWeight": "bold", "color": "white"}),
          Text(text: subtitle, style: {"fontSize": 18, "color": "white"}),
          Button(
            text: "立即查看",
            onTap: fn() { print("用戶點擊了 Banner"); }
          )
        ]
      )
    );
  }
}
