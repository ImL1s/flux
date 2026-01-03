widget SettingsPage {
  state notificationsEnabled = true;
  state volume = 0.8;
  state language = "zh_TW";
  state themeColor = "indigo";

  fn saveSettings() {
    saveToStorage("notifications", toString(notificationsEnabled));
    saveToStorage("volume", toString(volume));
    showToast("設定已儲存 ✅");
  }

  build {
    Column(
      children: [
        // Section 1
        Padding(
          padding: 16.0,
          child: Text(text: "一般設定", style: {"fontSize": 18.0, "fontWeight": "bold", "color": themeColor})
        ),
        
        ListTile(
          leading: Icon(icon: "notifications"),
          title: Text(text: "接收通知"),
          trailing: Switch(
            value: notificationsEnabled,
            onChanged: fn(val) { notificationsEnabled = val; }
          )
        ),
        
        ListTile(
          leading: Icon(icon: "volume_up"),
          title: Text(text: "音量: " + toString(toInt(volume * 100)) + "%"),
          subtitle: Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            onChanged: fn(val) { volume = val; }
          )
        ),

        Divider(),

        // Section 2
        Padding(
          padding: 16.0,
          child: Text(text: "個人化", style: {"fontSize": 18.0, "fontWeight": "bold", "color": themeColor})
        ),
       
        ListTile(
          leading: Icon(icon: "palette"),
          title: Text(text: "主題顏色"),
          subtitle: Row(
            children: [
              Button(text: "靛藍", color: "indigo", textColor: "white", onPressed: fn() { themeColor = "indigo"; }),
              SizedBox(width: 8.0),
              Button(text: "深紅", color: "red", textColor: "white", onPressed: fn() { themeColor = "red"; }),
              SizedBox(width: 8.0),
              Button(text: "森林綠", color: "green", textColor: "white", onPressed: fn() { themeColor = "green"; }),
            ]
          )
        ),

        SizedBox(height: 32.0),
        
        Padding(
          padding: 16.0,
          child: Button(
            text: "儲存所有變更",
            color: themeColor,
            textColor: "white",
            onPressed: fn() { saveSettings(); }
          )
        )
      ]
    )
  }
}
