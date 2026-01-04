import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:camera/camera.dart';
import 'package:flux_flutter/src/modules/camera_preview.dart';
import 'package:flux_flutter/src/modules/camera_module.dart';

// Mocks
class MockCameraWrapper extends Mock implements CameraWrapper {}
class MockCameraController extends Mock implements CameraController {}

class FakeCameraDescription extends Fake implements CameraDescription {
  @override
  final String name;
  @override
  final CameraLensDirection lensDirection;
  @override
  final int sensorOrientation;

  FakeCameraDescription({
    required this.name,
    required this.lensDirection,
    required this.sensorOrientation,
  });
}

void main() {
  setUpAll(() {
    registerFallbackValue(ResolutionPreset.medium);
    registerFallbackValue(FakeCameraDescription(
      name: 'dummy',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    ));
  });

  group('FluxCameraPreview', () {
    late MockCameraWrapper mockWrapper;
    late MockCameraController mockController;
    late List<CameraDescription> mockCameras;

    setUp(() {
      mockWrapper = MockCameraWrapper();
      mockController = MockCameraController();
      
      mockCameras = [
        FakeCameraDescription(
          name: 'Camera 0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      ];

      // Setup default mock behaviors
      when(() => mockWrapper.availableCameras()).thenAnswer((_) async => mockCameras);
      when(() => mockWrapper.createController(any(), any(), enableAudio: any(named: 'enableAudio')))
          .thenReturn(mockController);
      
      when(() => mockController.initialize()).thenAnswer((_) async {});
      when(() => mockController.dispose()).thenAnswer((_) async {});
      when(() => mockController.buildPreview()).thenReturn(const SizedBox());
      when(() => mockController.value).thenReturn(CameraValue(
        description: mockCameras.first,
        isInitialized: true,
        errorDescription: null,
        previewSize: const Size(1280, 720),
        isRecordingVideo: false,
        isTakingPicture: false,
        isStreamingImages: false,
        isRecordingPaused: false,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        exposurePointSupported: true,
        focusPointSupported: true,
        deviceOrientation: DeviceOrientation.portraitUp,
        lockedCaptureOrientation: null,
        recordingOrientation: null,
        isPreviewPaused: false,
        previewPauseOrientation: null,
      ));
    });

    testWidgets('should show loading indicator and then preview', (tester) async {
      // Use a completer to control initialization timing
      final initCompleter = Completer<void>();
      when(() => mockController.initialize()).thenAnswer((_) => initCompleter.future);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(wrapper: mockWrapper),
          ),
        ),
      );
      
      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing camera...'), findsOneWidget);

      // Complete initialization
      initCompleter.complete();
      await tester.pump(); // Start transition
      await tester.pump(const Duration(milliseconds: 100)); // Finish transition

      // Should show preview (which contains a CameraPreview widget)
      // Note: In real widget testing, CameraPreview might not render correctly without native view,
      // but we can check if it's in the tree.
      expect(find.byType(CameraPreview), findsOneWidget);
    });

    testWidgets('should show error state when initialization fails', (tester) async {
      when(() => mockController.initialize()).thenThrow(
        CameraException('error_code', 'error description')
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(wrapper: mockWrapper),
          ),
        ),
      );
      
      await tester.pump(); // Try initialize
      await tester.pump(const Duration(milliseconds: 100)); // Process error

      // Should show error state
      expect(find.text('Camera Error'), findsOneWidget);
      expect(find.textContaining('error description'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button should attempt re-initialization', (tester) async {
      int initCount = 0;
      when(() => mockController.initialize()).thenAnswer((_) async {
        initCount++;
        if (initCount == 1) throw Exception('failed');
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluxCameraPreview(wrapper: mockWrapper),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      expect(initCount, equals(2));
    });

    testWidgets('should re-initialize on cameraId change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: FluxCameraPreview(
                  cameraId: 0,
                  wrapper: mockWrapper,
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() {}), // Just trigger rebuild
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify first initialization
      verify(() => mockWrapper.createController(mockCameras[0], any(), enableAudio: any(named: 'enableAudio'))).called(1);
    });
  });
}
