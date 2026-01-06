import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/bindings.dart';

void main() {
  setUpAll(() {
    FluxBindings.initDefaults();
  });

  group('Flux Scrollable Widgets', () {
    testWidgets('SingleChildScrollView renders properties', (tester) async {
      final builder = FluxBindings.get('SingleChildScrollView')!;
      final scrollView = builder({
        'scrollDirection': 'horizontal',
        'padding': 16,
      }, [
        const Text('Content')
      ]) as SingleChildScrollView;

      expect(scrollView.scrollDirection, Axis.horizontal);
      expect(scrollView.padding, const EdgeInsets.all(16.0));
    });

    testWidgets('ListView renders children (static)', (tester) async {
      final builder = FluxBindings.get('ListView')!;
      final listView = builder({
        'scrollDirection': 'vertical',
        'padding': 8,
      }, [
        const Text('Item 1'),
        const Text('Item 2')
      ]) as ListView;

      expect(listView.scrollDirection, Axis.vertical);
      expect(listView.padding, const EdgeInsets.all(8.0));
      expect(listView.childrenDelegate, isA<SliverChildListDelegate>());
      // (listView.childrenDelegate as SliverChildListDelegate).children should have 2 items
    });

    testWidgets('ListView.builder renders (dynamic)', (tester) async {
      final builder = FluxBindings.get('ListView')!;

      // Mock builder function
      Widget mockBuilder(List<dynamic> args) {
        return Text('Item ${args[0]}');
      }

      final listView = builder({
        'itemCount': 5,
        'itemBuilder': mockBuilder,
      }, []) as ListView;

      expect(listView.childrenDelegate, isA<SliverChildBuilderDelegate>());
      final delegate = listView.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.estimatedChildCount, 5);

      // Verify builder execution
      // We need a BuildContext context.
      final context = MockBuildContext();
      final widget = delegate.builder(context, 0);
      expect(widget, isA<Text>());
      expect((widget as Text).data, 'Item 0');
    });
  });
}

class MockBuildContext extends Fake implements BuildContext {}
