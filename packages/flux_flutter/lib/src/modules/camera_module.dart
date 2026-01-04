import 'package:flutter/widgets.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:camera/camera.dart' as cam;

/// Wrapper interface for camera package static methods and factory functionality.
abstract class CameraWrapper {
  Future<List<cam.CameraDescription>> availableCameras();
  cam.CameraController createController(
    cam.CameraDescription description,
    cam.ResolutionPreset resolutionPreset, {
    bool enableAudio = true,
    cam.ImageFormatGroup? imageFormatGroup,
  });
}

/// Real implementation of CameraWrapper using the camera package.
class RealCameraWrapper implements CameraWrapper {
  @override
  Future<List<cam.CameraDescription>> availableCameras() => cam.availableCameras();

  @override
  cam.CameraController createController(
    cam.CameraDescription description,
    cam.ResolutionPreset resolutionPreset, {
    bool enableAudio = true,
    cam.ImageFormatGroup? imageFormatGroup,
  }) {
    return cam.CameraController(
      description,
      resolutionPreset,
      enableAudio: enableAudio,
      imageFormatGroup: imageFormatGroup,
    );
  }
}

/// Camera module for Flux scripting language.
class CameraModule extends FluxModule {
  static CameraModule? _instance;
  
  /// The wrapper instance used for camera operations.
  final CameraWrapper cameraWrapper;
  
  /// Singleton instance
  static CameraModule get instance => _instance ??= CameraModule._(RealCameraWrapper());
  
  /// The active camera controller
  cam.CameraController? _controller;
  
  /// Cached list of available cameras
  List<cam.CameraDescription>? _cameras;

  /// Constructor for testing with mock wrapper
  @visibleForTesting
  CameraModule.test(this.cameraWrapper) : super('camera') {
    _registerFunctions();
  }
  
  CameraModule._(this.cameraWrapper) : super('camera') {
    _registerFunctions();
  }

  void _registerFunctions() {
    register('availableCameras', AsyncNativeFunction('camera.availableCameras', 0, _availableCameras));
    register('initialize', AsyncNativeFunction('camera.initialize', 1, _initialize));
    register('takePicture', AsyncNativeFunction('camera.takePicture', 0, _takePicture));
    register('startVideoRecording', AsyncNativeFunction('camera.startVideoRecording', 0, _startVideoRecording));
    register('stopVideoRecording', AsyncNativeFunction('camera.stopVideoRecording', 0, _stopVideoRecording));
    register('setFlashMode', AsyncNativeFunction('camera.setFlashMode', 1, _setFlashMode));
    register('dispose', AsyncNativeFunction('camera.dispose', 0, _dispose));
  }
  
  /// Get the current camera controller (for preview widget)
  cam.CameraController? get controller => _controller;
  
  /// Check if camera is initialized
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  
  Future<Object?> _availableCameras(List<Object?> args) async {
    try {
      _cameras = await cameraWrapper.availableCameras();
      return _cameras!.asMap().entries.map((entry) => {
        'id': entry.key,
        'name': entry.value.name,
        'lensDirection': entry.value.lensDirection.name,
        'sensorOrientation': entry.value.sensorOrientation,
      }).toList();
    } catch (e) {
      debugPrint('[CameraModule] Error getting cameras: $e');
      return [];
    }
  }
  
  Future<Object?> _initialize(List<Object?> args) async {
    final options = args.isNotEmpty && args[0] is Map ? args[0] as Map : {};
    final cameraId = (options['cameraId'] as num?)?.toInt() ?? 0;
    final resolutionStr = options['resolution']?.toString() ?? 'medium';
    
    try {
      // Dispose existing controller if any
      await _controller?.dispose();
      
      // Get cameras if not cached
      _cameras ??= await cameraWrapper.availableCameras();
      
      if (_cameras!.isEmpty) {
        debugPrint('[CameraModule] No cameras available');
        return {'success': false, 'error': 'No cameras available'};
      }
      
      // Validate camera ID
      final cameraIndex = cameraId.clamp(0, _cameras!.length - 1);
      
      // Parse resolution preset
      final resolution = _parseResolutionPreset(resolutionStr);
      
      // Create and initialize controller via wrapper
      _controller = cameraWrapper.createController(
        _cameras![cameraIndex],
        resolution,
        enableAudio: options['enableAudio'] != false,
      );
      
      await _controller!.initialize();
      
      debugPrint('[CameraModule] Initialized camera $cameraIndex with $resolutionStr resolution');
      return {
        'success': true,
        'cameraId': cameraIndex,
        'resolution': resolutionStr,
        'previewSize': {
          'width': _controller!.value.previewSize?.width,
          'height': _controller!.value.previewSize?.height,
        },
      };
    } catch (e) {
      debugPrint('[CameraModule] Error initializing camera: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _takePicture(List<Object?> args) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return {'success': false, 'error': 'Camera not initialized'};
    }
    
    try {
      final cam.XFile image = await _controller!.takePicture();
      debugPrint('[CameraModule] Picture taken: ${image.path}');
      return {
        'success': true,
        'path': image.path,
        'name': image.name,
      };
    } catch (e) {
      debugPrint('[CameraModule] Error taking picture: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _startVideoRecording(List<Object?> args) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return {'success': false, 'error': 'Camera not initialized'};
    }
    
    if (_controller!.value.isRecordingVideo) {
      return {'success': false, 'error': 'Already recording'};
    }
    
    try {
      await _controller!.startVideoRecording();
      debugPrint('[CameraModule] Started video recording');
      return {'success': true};
    } catch (e) {
      debugPrint('[CameraModule] Error starting video recording: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _stopVideoRecording(List<Object?> args) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return {'success': false, 'error': 'Camera not initialized'};
    }
    
    if (!_controller!.value.isRecordingVideo) {
      return {'success': false, 'error': 'Not recording'};
    }
    
    try {
      final cam.XFile video = await _controller!.stopVideoRecording();
      debugPrint('[CameraModule] Stopped video recording: ${video.path}');
      return {
        'success': true,
        'path': video.path,
        'name': video.name,
      };
    } catch (e) {
      debugPrint('[CameraModule] Error stopping video recording: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _setFlashMode(List<Object?> args) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return {'success': false, 'error': 'Camera not initialized'};
    }
    
    final modeStr = args.isNotEmpty ? args[0].toString() : 'off';
    
    try {
      final flashMode = _parseFlashMode(modeStr);
      await _controller!.setFlashMode(flashMode);
      debugPrint('[CameraModule] Set flash mode to $modeStr');
      return {'success': true, 'mode': modeStr};
    } catch (e) {
      debugPrint('[CameraModule] Error setting flash mode: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _dispose(List<Object?> args) async {
    try {
      await _controller?.dispose();
      _controller = null;
      debugPrint('[CameraModule] Disposed camera');
      return {'success': true};
    } catch (e) {
      debugPrint('[CameraModule] Error disposing camera: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  cam.ResolutionPreset _parseResolutionPreset(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return cam.ResolutionPreset.low;
      case 'medium':
        return cam.ResolutionPreset.medium;
      case 'high':
        return cam.ResolutionPreset.high;
      case 'veryhigh':
        return cam.ResolutionPreset.veryHigh;
      case 'ultrahigh':
        return cam.ResolutionPreset.ultraHigh;
      case 'max':
        return cam.ResolutionPreset.max;
      default:
        return cam.ResolutionPreset.medium;
    }
  }
  
  cam.FlashMode _parseFlashMode(String value) {
    switch (value.toLowerCase()) {
      case 'off':
        return cam.FlashMode.off;
      case 'auto':
        return cam.FlashMode.auto;
      case 'on':
      case 'always':
        return cam.FlashMode.always;
      case 'torch':
        return cam.FlashMode.torch;
      default:
        return cam.FlashMode.off;
    }
  }
}
