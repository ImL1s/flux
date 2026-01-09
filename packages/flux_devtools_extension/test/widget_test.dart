@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flux_devtools_extension/main.dart';

void main() {
  testWidgets('Extension loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FluxDevToolsExtensionApp());
    expect(find.textContaining('Ready to Connect'), findsOneWidget);
  });
}
