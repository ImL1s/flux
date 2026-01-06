import 'package:flutter/material.dart';

/// Global navigator key to be used by Flux native modules when UI context is needed.
///
/// Add this to your MaterialApp:
/// ```dart
/// MaterialApp(
///   navigatorKey: fluxNavigatorKey,
///   ...
/// )
/// ```
final GlobalKey<NavigatorState> fluxNavigatorKey = GlobalKey<NavigatorState>();
