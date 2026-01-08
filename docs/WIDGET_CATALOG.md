# Flux Widget Catalog

[漢文文檔](WIDGET_CATALOG_ZH.md)

This catalog lists all Flux widgets currently supported by the Flutter runtime.

## Layout Widgets

| Widget | Description |
| t --- | t --- |
| `Scaffold` | Top-level container implementing Material Design implementation layout structure. |
| `AppBar` | Material Design app bar. |
| `Column` | Layout a list of child widgets in the vertical direction. |
| `Row` | Layout a list of child widgets in the horizontal direction. |
| `Container` | A convenience widget that combines common painting, positioning, and sizing widgets. |
| `Padding` | Insets its child by the given padding. |
| `Center` | Centers its child within itself. |
| `SingleChildScrollView` | A box in which a single widget can be scrolled. |
| `Expanded` | A widget that expands a child of a Row, Column, or Flex. |
| `SizedBox` | A box with a specified size. |
| `Stack` | Position children relative to the edges of the box. |
| `ListView` | A scrollable list of widgets arranged linearly. |
| `ListTile` | A single fixed-height row that typically contains some text as well as a leading or trailing icon. |
| `Divider` | A thin horizontal line, with padding on either side. |
| `Drawer` | A Material Design panel that slides in horizontally from the edge of a Scaffold. |
| `FloatingActionButton` | A circular icon button that hovers over content. |
| `BottomNavigationBar` | A material widget that's displayed at the bottom of an app for selecting among a small number of views. |
| `TabBar` | A Material Design widget that displays a horizontal row of tabs. |
| `TabBarView` | A page view that displays the widget which corresponds to the currently selected tab. |

## Animation Widgets

| Widget | Description |
| t --- | t --- |
| `AnimatedContainer` | A container that gradually changes its values over a period of time. |
| `AnimatedOpacity` | Animated version of Opacity which automatically transitions the child's opacity over a given duration. |
| `AnimatedSwitcher` | A widget that by default does a CrossFade between a new widget and the widget previously set on the AnimatedSwitcher as a child. |
| `Hero` | A widget that flies an image from one route to another. |

## Input Widgets

| Widget | Description |
| t --- | t --- |
| `Text` | A run of text with a single style. |
| `TextField` | A material design text field. |
| `TextFormField` | A text field integrated with a Form. |
| `Button` / `ElevatedButton` | A Material Design elevated button. |
| `OutlinedButton` | A Material Design outlined button. |
| `IconButton` | A button printed on a Material widget that reacts to touches by filling with color. |
| `Slider` | A slider to select from a range of values. |
| `Switch` | A two-state toggle switch. |
| `Checkbox` | A checkbox. |
| `Radio` | A radio button. |
| `DropdownButton` | A button for selecting from a list of items. |
| `Form` | An optional container for grouping together multiple form field widgets. |
| `showDatePicker` | Function to show a date picker dialog. |
| `showTimePicker` | Function to show a time picker dialog. |

## Feedback & Misc

| Widget | Description |
| t --- | t --- |
| `AlertDialog` | A material design alert dialog. |
| `SimpleDialog` | A simple material design dialog. |
| `SnackBar` | A lightweight message with an optional action which briefly displays at the bottom of the screen. |
| `Card` | A material design card. |
| `Chip` | Material design chips. |
| `CircularProgressIndicator` | A material design circular progress indicator. |
| `LinearProgressIndicator` | A material design linear progress indicator. |
| `Icon` | A graphical icon widget. |
| `Image` | A widget that displays an image. |
| `FutureBuilder` | Parameters: `future`, `builder`. Build UI based on Future state. |
