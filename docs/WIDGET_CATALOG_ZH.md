# Flux 組件清單 (Widget Catalog)

[English Documentation](WIDGET_CATALOG.md)

此目錄列出了 Flutter 執行時目前支援的所有 Flux 組件。

## 佈局組件 (Layout Widgets)

| 組件 | 說明 |
| --- | --- |
| `Scaffold` | 實現 Material Design 基本佈局結構的頂層容器。 |
| `AppBar` | Material Design 應用程式欄。 |
| `Column` | 在垂直方向排列子組件。 |
| `Row` | 在水平方向排列子組件。 |
| `Container` | 結合了繪畫、定位和尺寸調整組件的便捷組件。 |
| `Padding` | 為其子組件添加內邊距。 |
| `Center` | 將其子組件居中顯示。 |
| `SingleChildScrollView` | 可滾動單個組件的框。 |
| `Expanded` | 擴展 Row、Column 或 Flex 子組件的組件。 |
| `SizedBox` | 具有指定尺寸的框。 |
| `Stack` | 相對於框邊緣定位子組件。 |
| `ListView` | 線性排列的可滾動組件列表。 |
| `ListTile` | 通常包含文字以及前導或尾隨圖標的固定高度行。 |
| `Divider` | 帶有邊距的水平細線。 |
| `Drawer` | 從 Scaffold 邊緣水平滑出的 Material Design 面板。 |
| `FloatingActionButton` | 懸浮在內容上方的圓形圖標按鈕。 |
| `BottomNavigationBar` | 顯示在底部，用於在少數視圖間切換的 Material 組件。 |
| `TabBar` | 顯示一橫行標籤的 Material Design 組件。 |
| `TabBarView` | 顯示與當前選定標籤相對應的組件的頁面視圖。 |

## 動畫組件 (Animation Widgets)

| 組件 | 說明 |
| --- | --- |
| `AnimatedContainer` | 在一段時間內逐漸改變其值的容器。 |
| `AnimatedOpacity` | Opacity 的動畫版本，在給定時間內自動轉變子組件的透明度。 |
| `AnimatedSwitcher` | 在新舊組件之間進行淡入淡出切換的組件。 |
| `Hero` | 讓圖片在不同路由間「飛行」的動畫組件。 |

## 輸入組件 (Input Widgets)

| 組件 | 說明 |
| --- | --- |
| `Text` | 具有單一背樣式的文字行。 |
| `TextField` | Material Design 文字輸入框。 |
| `TextFormField` | 與 Form 整合的文字輸入框。 |
| `Button` / `ElevatedButton` | Material Design 凸起按鈕。 |
| `OutlinedButton` | Material Design 輪廓按鈕。 |
| `IconButton` | 點擊時顯示顏色反應的圖標按鈕。 |
| `Slider` | 用於從範圍中選擇值的滑塊。 |
| `Switch` | 雙狀態開關。 |
| `Checkbox` | 複選框。 |
| `Radio` | 單選按鈕。 |
| `DropdownButton` | 用於從列表中選擇項目的下拉按鈕。 |
| `Form` | 用於將多個表單欄位組件分組的可選容器。 |
| `showDatePicker` | 顯示日期選擇器對話框的函式。 |
| `showTimePicker` | 顯示時間選擇器對話框的函式。 |

## 反饋與其他 (Feedback & Misc)

| 組件 | 說明 |
| --- | --- |
| `AlertDialog` | Material Design 警報對話框。 |
| `SimpleDialog` | 簡單的 Material Design 對話框。 |
| `SnackBar` | 在螢幕底部簡短顯示的輕量級訊息。 |
| `Card` | Material Design 卡片組件。 |
| `Chip` | Material Design 標籤 (Chip)。 |
| `CircularProgressIndicator` | 圓形進度指示器。 |
| `LinearProgressIndicator` | 線性進度指示器。 |
| `Icon` | 圖形圖標組件。 |
| `Image` | 顯示圖片的組件。 |
| `FutureBuilder` | 根據 Future 狀態構建 UI 的組件（參數：`future`, `builder`）。 |
