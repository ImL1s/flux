import 'package:flutter/material.dart';

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
  
  /// Callback when the camera is initialized
  final VoidCallback? onInitialized;
  
  /// Callback when an error occurs
  final void Function(String error)? onError;
  
  const FluxCameraPreview({
    super.key,
    this.cameraId = 0,
    this.fit = BoxFit.cover,
    this.onInitialized,
    this.onError,
  });
  
  @override
  State<FluxCameraPreview> createState() => _FluxCameraPreviewState();
}

class _FluxCameraPreviewState extends State<FluxCameraPreview> with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _error;
  
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for camera resource management
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    if (!mounted) return;
    
    try {
      // TODO: Initialize camera controller
      // final cameras = await availableCameras();
      // _controller = CameraController(cameras[widget.cameraId], ResolutionPreset.high);
      // await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
        widget.onInitialized?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        widget.onError?.call(e.toString());
      }
    }
  }
  
  Future<void> _disposeCamera() async {
    // TODO: Dispose camera controller
    // await _controller?.dispose();
    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    // TODO: Return actual CameraPreview widget
    // return FittedBox(
    //   fit: widget.fit,
    //   child: SizedBox(
    //     width: _controller.value.previewSize?.height,
    //     height: _controller.value.previewSize?.width,
    //     child: CameraPreview(_controller),
    //   ),
    // );
    
    // Placeholder preview
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.cameraId == 0 ? Icons.camera_rear : Icons.camera_front,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Preview (ID: ${widget.cameraId})',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add camera package to enable',
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
