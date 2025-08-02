import 'package:flutter/material.dart';
import 'camera_hinge_detector_service.dart';

class CameraHingeDemo extends StatefulWidget {
  const CameraHingeDemo({super.key});

  @override
  State<CameraHingeDemo> createState() => _CameraHingeDemoState();
}

class _CameraHingeDemoState extends State<CameraHingeDemo> {
  CameraHingeDetectorService? _cameraService;
  String _status = 'Initializing...';
  double _detectedAngle = 0.0;
  bool _isInitialized = false;
  String _cameraStatus = 'Checking cameras...';
  bool _hasBackCamera = false;
  bool _hasFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _status = 'Requesting camera permissions...';
      });

      _cameraService = CameraHingeDetectorService();
      await _cameraService!.initialize();

      // Check camera availability
      final backPreview = _cameraService!.getBackCameraPreview();
      final frontPreview = _cameraService!.getFrontCameraPreview();
      final cameraStatus = _cameraService!.getCameraStatus();

      setState(() {
        _hasBackCamera = backPreview != null;
        _hasFrontCamera = frontPreview != null;
        _cameraStatus =
            'Back: ${_hasBackCamera ? "✓" : "✗"}, Front: ${_hasFrontCamera ? "✓" : "✗"} '
            '(${cameraStatus['cameras_available']} total)';
      });

      _cameraService!.hingeStateStream.listen((hingeData) {
        if (mounted) {
          setState(() {
            _detectedAngle = hingeData.angle;
            _status = 'Detecting: ${hingeData.state.name}';
            _isInitialized = true;
          });
        }
      });

      setState(() {
        _status = 'Camera initialized successfully';
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize camera: $e';
        _cameraStatus = 'Camera initialization failed';
      });
    }
  }

  @override
  void dispose() {
    _cameraService?.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    final backPreview = _cameraService?.getBackCameraPreview();
    final frontPreview = _cameraService?.getFrontCameraPreview();

    if (backPreview != null && frontPreview != null) {
      // Show both cameras side by side
      return Row(
        children: [
          Expanded(
            child: Card(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Back Camera',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: backPreview),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Front Camera',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: frontPreview),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (backPreview != null) {
      // Show only back camera
      return Card(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Back Camera',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: backPreview),
          ],
        ),
      );
    } else if (frontPreview != null) {
      // Show only front camera
      return Card(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Front Camera',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: frontPreview),
          ],
        ),
      );
    } else {
      // No camera available
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera preview not available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: $_cameraStatus',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeCamera,
                child: const Text('Retry Camera Setup'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Hinge Detection Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Camera-Based Hinge Detection',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(_status, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Text(
                      'Detected Angle: ${_detectedAngle.toStringAsFixed(1)}°',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera Status: $_cameraStatus',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (!_isInitialized)
                      TextButton(
                        onPressed: _initializeCamera,
                        child: const Text('Retry Camera Setup'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isInitialized && _cameraService != null) ...[
              const Text(
                'Camera Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildCameraPreview()),
            ] else ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
            const SizedBox(height: 16),
            if (_cameraService != null) ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(_cameraService!.getCameraStatus().entries.map(
                        (e) => Text('${e.key}: ${e.value}'),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              color: Colors.orange[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Camera Detection Works:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Uses edge detection to find the hinge line'),
                    Text('• Analyzes perspective differences between cameras'),
                    Text('• Estimates angles based on visual cues'),
                    Text('• More accurate than sensor-only detection'),
                    SizedBox(height: 8),
                    Text(
                      'Note: This is an experimental feature that requires camera permissions.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
