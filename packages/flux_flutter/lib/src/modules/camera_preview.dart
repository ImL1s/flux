import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_module.dart';

/// A widget that displays the camera preview within a Flux script.
///
/// This widget can be used in Flux scripts to show a live camera preview:
/// ```flux
/// widget "CameraScreen" {
///   build: (context) {
///     return Scaffold(
///       body: CameraPreview({
///         cameraId: 0,
///         fit: "cover"
///       })
///     );
///   }
/// }
/// ```
class FluxCameraPreview extends StatefulWidget {
  /// The camera ID to display (0 = back, 1 = front typically)
  final int cameraId;

  /// How the preview should be fitted within the container
  final BoxFit fit;

  /// Resolution preset for the camera
  final String resolution;

  /// Whether to enable audio for video recording
  final bool enableAudio;

  /// Callback when the camera is initialized
  final VoidCallback? onInitialized;

  /// Callback when an error occurs
  final void Function(String error)? onError;

  /// The wrapper instance used for camera operations (for testing)
  final CameraWrapper? wrapper;

  const FluxCameraPreview({
    super.key,
    this.cameraId = 0,
    this.fit = BoxFit.cover,
    this.resolution = 'medium',
    this.enableAudio = true,
    this.onInitialized,
    this.onError,
    this.wrapper,
  });

  @override
  State<FluxCameraPreview> createState() => _FluxCameraPreviewState();
}

class _FluxCameraPreviewState extends State<FluxCameraPreview>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _error;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didUpdateWidget(FluxCameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize if camera ID or resolution changed
    if (oldWidget.cameraId != widget.cameraId ||
        oldWidget.resolution != widget.resolution) {
      _initializeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't process lifecycle changes if controller isn't ready
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    // Reset state
    setState(() {
      _isInitialized = false;
      _error = null;
    });

    try {
      // Dispose any existing controller
      await _controller?.dispose();
      _controller = null;

      final wrapper = widget.wrapper ?? CameraModule.instance.cameraWrapper;

      // Get available cameras
      _cameras = await wrapper.availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      // Validate camera ID
      final cameraIndex = widget.cameraId.clamp(0, _cameras!.length - 1);

      // Parse resolution
      final resolution = _parseResolutionPreset(widget.resolution);

      // Create controller via wrapper
      _controller = wrapper.createController(
        _cameras![cameraIndex],
        resolution,
        enableAudio: widget.enableAudio,
      );

      // Initialize controller
      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _error = null;
      });

      widget.onInitialized?.call();
    } on CameraException catch (e) {
      final errorMsg = 'Camera error: ${e.code} - ${e.description}';
      if (mounted) {
        setState(() {
          _error = errorMsg;
          _isInitialized = false;
        });
        widget.onError?.call(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitialized = false;
        });
        widget.onError?.call(e.toString());
      }
    }
  }

  Future<void> _disposeCamera() async {
    try {
      await _controller?.dispose();
      _controller = null;
    } catch (e) {
      debugPrint('[FluxCameraPreview] Error disposing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }
  }

  ResolutionPreset _parseResolutionPreset(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return ResolutionPreset.low;
      case 'medium':
        return ResolutionPreset.medium;
      case 'high':
        return ResolutionPreset.high;
      case 'veryhigh':
        return ResolutionPreset.veryHigh;
      case 'ultrahigh':
        return ResolutionPreset.ultraHigh;
      case 'max':
        return ResolutionPreset.max;
      default:
        return ResolutionPreset.medium;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _controller == null) {
      return _buildLoadingWidget();
    }

    return _buildPreviewWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewWidget() {
    final controller = _controller!;

    // Calculate aspect ratio
    final size = controller.value.previewSize;
    double aspectRatio = 16 / 9; // Default fallback
    if (size != null) {
      // Camera returns size as (width, height) where width > height for landscape
      // We need to swap for portrait orientation
      aspectRatio = size.height / size.width;
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: 1,
            height: aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
