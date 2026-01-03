import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/camera_module.dart';

void main() {
  group('CameraModule', () {
    late CameraModule module;
    
    setUp(() {
      module = CameraModule.instance;
    });
    
    test('should be a singleton', () {
      final instance1 = CameraModule.instance;
      final instance2 = CameraModule.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should have correct module name', () {
      expect(module.name, equals('camera'));
    });

    test('should have all required functions registered', () {
      // Verify key camera functions are registered
      expect(module.get('availableCameras'), isNotNull);
      expect(module.get('initialize'), isNotNull);
      expect(module.get('takePicture'), isNotNull);
      expect(module.get('startVideoRecording'), isNotNull);
      expect(module.get('stopVideoRecording'), isNotNull);
      expect(module.get('setFlashMode'), isNotNull);
      expect(module.get('dispose'), isNotNull);
    });
    
    test('controller should be null initially', () {
      // Fresh instance should not have controller
      expect(module.controller, isNull);
    });
    
    test('isInitialized should be false initially', () {
      expect(module.isInitialized, isFalse);
    });
    
    group('availableCameras', () {
      test('should return a list', () async {
        // Note: In test environment without real cameras, this may return empty list
        final result = await module.get('availableCameras')?.call([]);
        expect(result, isA<List>());
      });
    });
    
    group('initialize without cameras', () {
      test('should handle initialization gracefully in test environment', () async {
        // In test environment, cameras may not be available
        final result = await module.get('initialize')?.call([
          {'cameraId': 0, 'resolution': 'medium'}
        ]);
        
        // Should return a Map with success/error info
        expect(result, isA<Map>());
      });
    });
    
    group('takePicture without initialization', () {
      test('should return error when camera not initialized', () async {
        // Reset state by disposing first
        await module.get('dispose')?.call([]);
        
        final result = await module.get('takePicture')?.call([]);
        
        expect(result, isA<Map>());
        final resultMap = result as Map;
        expect(resultMap['success'], isFalse);
        expect(resultMap['error'], contains('not initialized'));
      });
    });
    
    group('startVideoRecording without initialization', () {
      test('should return error when camera not initialized', () async {
        await module.get('dispose')?.call([]);
        
        final result = await module.get('startVideoRecording')?.call([]);
        
        expect(result, isA<Map>());
        final resultMap = result as Map;
        expect(resultMap['success'], isFalse);
        expect(resultMap['error'], contains('not initialized'));
      });
    });
    
    group('stopVideoRecording without initialization', () {
      test('should return error when camera not initialized', () async {
        await module.get('dispose')?.call([]);
        
        final result = await module.get('stopVideoRecording')?.call([]);
        
        expect(result, isA<Map>());
        final resultMap = result as Map;
        expect(resultMap['success'], isFalse);
        expect(resultMap['error'], contains('not initialized'));
      });
    });
    
    group('setFlashMode without initialization', () {
      test('should return error when camera not initialized', () async {
        await module.get('dispose')?.call([]);
        
        final result = await module.get('setFlashMode')?.call(['auto']);
        
        expect(result, isA<Map>());
        final resultMap = result as Map;
        expect(resultMap['success'], isFalse);
        expect(resultMap['error'], contains('not initialized'));
      });
    });
    
    group('dispose', () {
      test('should complete without error', () async {
        final result = await module.get('dispose')?.call([]);
        
        expect(result, isA<Map>());
        final resultMap = result as Map;
        expect(resultMap['success'], isTrue);
      });
      
      test('should be safe to call multiple times', () async {
        await module.get('dispose')?.call([]);
        final result = await module.get('dispose')?.call([]);
        
        expect(result, isA<Map>());
        final resultMap = result as Map;
        expect(resultMap['success'], isTrue);
      });
    });
  });
}
