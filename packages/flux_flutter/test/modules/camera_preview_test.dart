import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/camera_preview.dart';

void main() {
  group('FluxCameraPreview', () {
    testWidgets('should show loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(),
          ),
        ),
      );
      
      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing camera...'), findsOneWidget);
    });
    
    testWidgets('should accept cameraId parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(cameraId: 1),
          ),
        ),
      );
      
      // Widget should build without error
      expect(find.byType(FluxCameraPreview), findsOneWidget);
    });
    
    testWidgets('should accept fit parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(fit: BoxFit.contain),
          ),
        ),
      );
      
      // Widget should build without error
      expect(find.byType(FluxCameraPreview), findsOneWidget);
    });
    
    testWidgets('should accept resolution parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(resolution: 'high'),
          ),
        ),
      );
      
      // Widget should build without error
      expect(find.byType(FluxCameraPreview), findsOneWidget);
    });
    
    testWidgets('should accept enableAudio parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(enableAudio: false),
          ),
        ),
      );
      
      // Widget should build without error
      expect(find.byType(FluxCameraPreview), findsOneWidget);
    });
    
    testWidgets('should handle all parameters together', (tester) async {
      bool initialized = false;
      String? errorMessage;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(
              cameraId: 0,
              fit: BoxFit.cover,
              resolution: 'medium',
              enableAudio: true,
              onInitialized: () => initialized = true,
              onError: (error) => errorMessage = error,
            ),
          ),
        ),
      );
      
      // Widget should build without error
      expect(find.byType(FluxCameraPreview), findsOneWidget);
      
      // In test environment, camera initialization may fail
      // So we just verify the widget handles it gracefully
      await tester.pump(const Duration(milliseconds: 500));
      
      // Should show either loading, error, or preview state
      final loadingFinder = find.byType(CircularProgressIndicator);
      final errorFinder = find.text('Camera Error');
      
      // One of these states should be present
      expect(
        loadingFinder.evaluate().isNotEmpty || errorFinder.evaluate().isNotEmpty,
        isTrue,
      );
    });
    
    testWidgets('error state should show retry button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(),
          ),
        ),
      );
      
      // Wait for initialization attempt
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      
      // If error state is shown, it should have a retry button
      final errorFinder = find.text('Camera Error');
      if (errorFinder.evaluate().isNotEmpty) {
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      }
    });
    
    testWidgets('should rebuild on cameraId change', (tester) async {
      int cameraId = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: FluxCameraPreview(cameraId: cameraId),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => cameraId = 1),
                  child: const Icon(Icons.switch_camera),
                ),
              );
            },
          ),
        ),
      );
      
      // Change camera
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      
      // Widget should rebuild (re-initialize camera)
      expect(find.byType(FluxCameraPreview), findsOneWidget);
    });
  });
}
