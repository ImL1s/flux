import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flux_flutter/src/modules/camera_module.dart';
import 'package:camera/camera.dart';

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
    registerFallbackValue(FlashMode.off);
    registerFallbackValue(FakeCameraDescription(
      name: 'dummy',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    ));
  });

  group('CameraModule', () {
    late CameraModule module;
    late MockCameraWrapper mockWrapper;
    late MockCameraController mockController;
    late List<CameraDescription> mockCameras;

    setUp(() {
      mockWrapper = MockCameraWrapper();
      mockController = MockCameraController();
      module = CameraModule.test(mockWrapper);

      mockCameras = [
        FakeCameraDescription(
          name: 'Camera 0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      ];

      // Setup default mock behaviors
      when(() => mockWrapper.availableCameras())
          .thenAnswer((_) async => mockCameras);
      when(() => mockWrapper.createController(any(), any(),
          enableAudio: any(named: 'enableAudio'))).thenReturn(mockController);

      when(() => mockController.initialize()).thenAnswer((_) async {});
      when(() => mockController.dispose()).thenAnswer((_) async {});
      when(() => mockController.value).thenReturn(CameraValue(
        description: mockCameras.first,
        isInitialized: true,
        errorDescription: null,
        previewSize: null,
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
    test('availableCameras returns mapped data', () async {
      final result = await module.get('availableCameras')?.call([]);
      expect(result, isA<List>());
      final list = result as List;
      expect(list.length, 1);
      expect(list[0]['name'], equals('Camera 0'));
    });

    test('initialize creates and initializes controller', () async {
      final result = await module.get('initialize')?.call([
        {'cameraId': 0, 'resolution': 'high'}
      ]);

      verify(() => mockWrapper.createController(any(), ResolutionPreset.high,
          enableAudio: true)).called(1);
      verify(() => mockController.initialize()).called(1);

      expect((result as Map)['success'], isTrue);
      expect(module.controller, equals(mockController));
    });

    test('takePicture returns path on success', () async {
      final mockFile = XFile('test_path.jpg', name: 'test_path.jpg');
      when(() => mockController.takePicture())
          .thenAnswer((_) async => mockFile);

      // Initialize first
      await module.get('initialize')?.call([{}]);

      final result = await module.get('takePicture')?.call([]);

      verify(() => mockController.takePicture()).called(1);
      expect((result as Map)['success'], isTrue);
      expect(result['path'], equals('test_path.jpg'));
    });

    group('Video Recording', () {
      setUp(() async {
        await module.get('initialize')?.call([{}]);
      });

      test('startVideoRecording calls controller', () async {
        when(() => mockController.startVideoRecording())
            .thenAnswer((_) async {});

        final result = await module.get('startVideoRecording')?.call([]);

        verify(() => mockController.startVideoRecording()).called(1);
        expect((result as Map)['success'], isTrue);
      });

      test('stopVideoRecording returns video file', () async {
        // Mock recording state
        when(() => mockController.value).thenReturn(CameraValue(
          description: mockCameras.first,
          isInitialized: true,
          errorDescription: null,
          previewSize: null,
          isRecordingVideo: true, // Recording!
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

        final mockFile = XFile('video.mp4', name: 'video.mp4');
        when(() => mockController.stopVideoRecording())
            .thenAnswer((_) async => mockFile);

        final result = await module.get('stopVideoRecording')?.call([]);

        verify(() => mockController.stopVideoRecording()).called(1);
        expect((result as Map)['success'], isTrue);
        expect(result['path'], equals('video.mp4'));
      });
    });

    test('setFlashMode mapping', () async {
      await module.get('initialize')?.call([{}]);
      when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});

      registerFallbackValue(FlashMode.always);

      final result = await module.get('setFlashMode')?.call(['torch']);

      verify(() => mockController.setFlashMode(FlashMode.torch)).called(1);
      expect((result as Map)['success'], isTrue);
    });

    test('dispose cleans up controller', () async {
      await module.get('initialize')?.call([{}]);

      final result = await module.get('dispose')?.call([]);

      verify(() => mockController.dispose()).called(1);
      expect((result as Map)['success'], isTrue);
      expect(module.controller, isNull);
    });
  });
}
