import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/bindings.dart';

void main() {
  setUpAll(() {
    FluxBindings.initDefaults();
  });

  group('Flux Generic Widgets', () {
    testWidgets('Icon renders properties properly', (tester) async {
      final builder = FluxBindings.get('Icon')!;
      // Use numeric size as int to test cast to double
      final icon = builder({'name': 'favorite', 'size': 36, 'color': 'red'}, []) as Icon;
      
      expect(icon.icon, Icons.favorite);
      expect(icon.size, 36.0);
      expect(icon.color, Colors.red);
    });

    testWidgets('Image renders properties (Asset)', (tester) async {
       // Note: We can only verify properties of the widget, not actual loading in checking
       final builder = FluxBindings.get('Image')!;
       final image = builder({
         'src': 'assets/logo.png',
         'alignment': 'bottomRight',
         'color': '#AA0000',
         'width': 100,
         'height': 100
       }, []) as Image;
       
       expect(image.image, isA<AssetImage>());
       expect(image.alignment, Alignment.bottomRight);
       expect(image.color, const Color(0xFFAA0000));
       expect(image.width, 100.0);
       expect(image.height, 100.0);
    });
    
    testWidgets('Image renders properties (Network)', (tester) async {
       final builder = FluxBindings.get('Image')!;
       final image = builder({
         'src': 'https://example.com/logo.png',
         'fit': 'cover',
       }, []) as Image;
       
       expect(image.image, isA<NetworkImage>());
       expect(image.fit, BoxFit.cover);
       // Alignment defaults to center if not provided (checked in our impl)
       expect(image.alignment, Alignment.center);
    });
  });
}
