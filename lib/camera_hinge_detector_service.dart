import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'hinge_detector_service.dart';

class CameraHingeDetectorService extends HingeDetectorService {
  List<CameraDescription>? _cameras;
  CameraController? _frontCamera;
  CameraController? _backCamera;
  Timer? _analysisTimer;
  bool _isAnalyzing = false;

  // Reference measurements for calibration
  double _deviceWidthMm = 150.0; // Approximate device width in mm
  double _hingePositionRatio = 0.5; // Hinge position as ratio of device width

  @override
  Future<void> initialize() async {
    try {
      print('Starting camera hinge detector initialization...');

      // Request camera permission with better handling
      print('Requesting camera permissions...');
      final status = await Permission.camera.request();

      print('Camera permission status: $status');

      if (status.isDenied) {
        throw Exception(
          'Camera permission denied. Please enable camera access in Settings.',
        );
      } else if (status.isPermanentlyDenied) {
        throw Exception(
          'Camera permission permanently denied. Please enable camera access in Settings.',
        );
      } else if (!status.isGranted) {
        throw Exception('Camera permission not granted: $status');
      }

      print('Camera permission granted');

      // Initialize cameras
      print('Getting available cameras...');
      _cameras = await availableCameras();
      print('Found ${_cameras?.length ?? 0} cameras');

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras found on this device');
      }

      await _initializeCameras();

      // Start analysis timer
      print('Starting camera analysis...');
      _startCameraAnalysis();

      print('Camera hinge detector initialized successfully');
    } catch (e) {
      print('Camera hinge detector initialization failed: $e');
      // Fallback to parent initialization
      return super.initialize();
    }
  }

  Future<void> _initializeCameras() async {
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available on device');
    }

    print('Found ${_cameras!.length} cameras available');

    // Find front and back cameras
    CameraDescription? frontCamera;
    CameraDescription? backCamera;

    for (final camera in _cameras!) {
      print('Camera: ${camera.name}, direction: ${camera.lensDirection}');
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
      } else if (camera.lensDirection == CameraLensDirection.back) {
        backCamera = camera;
      }
    }

    // Initialize back camera
    if (backCamera != null) {
      try {
        print('Initializing back camera...');
        _backCamera = CameraController(
          backCamera,
          ResolutionPreset.low,
          enableAudio: false,
        );
        await _backCamera!.initialize();
        print('Back camera initialized successfully');
      } catch (e) {
        print('Failed to initialize back camera: $e');
        _backCamera?.dispose();
        _backCamera = null;
      }
    } else {
      print('No back camera found');
    }

    // Initialize front camera
    if (frontCamera != null) {
      try {
        print('Initializing front camera...');
        _frontCamera = CameraController(
          frontCamera,
          ResolutionPreset.low,
          enableAudio: false,
        );
        await _frontCamera!.initialize();
        print('Front camera initialized successfully');
      } catch (e) {
        print('Failed to initialize front camera: $e');
        _frontCamera?.dispose();
        _frontCamera = null;
      }
    } else {
      print('No front camera found');
    }

    // Check if at least one camera is working
    if (_backCamera == null && _frontCamera == null) {
      throw Exception('Failed to initialize any cameras');
    }
  }

  void _startCameraAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isAnalyzing &&
          (_frontCamera?.value.isInitialized == true ||
              _backCamera?.value.isInitialized == true)) {
        _analyzeHingeFromCamera();
      }
    });
  }

  Future<void> _analyzeHingeFromCamera() async {
    if (_isAnalyzing) return;
    _isAnalyzing = true;

    try {
      double estimatedAngle = 0.0;
      HingeState detectedState = HingeState.unknown;

      // Method 1: Dual camera analysis (if both cameras available)
      if (_frontCamera?.value.isInitialized == true &&
          _backCamera?.value.isInitialized == true) {
        estimatedAngle = await _analyzeDualCamera();
      }
      // Method 2: Single camera edge detection
      else if (_backCamera?.value.isInitialized == true) {
        estimatedAngle = await _analyzeSingleCamera(_backCamera!);
      } else if (_frontCamera?.value.isInitialized == true) {
        estimatedAngle = await _analyzeSingleCamera(_frontCamera!);
      }

      // Determine hinge state based on angle
      detectedState = _angleToHingeState(estimatedAngle);

      // Create hinge data
      final hingeData = HingeData(
        state: detectedState,
        angle: estimatedAngle,
        deviceType: FoldableType.generic,
        isPostureSupported: true,
        timestamp: DateTime.now(),
        rawData: {
          'detection_method': 'camera_vision',
          'confidence': _calculateConfidence(estimatedAngle),
        },
      );

      // Update the hinge state
      updateHingeState(hingeData);
    } catch (e) {
      print('Camera analysis error: $e');
    } finally {
      _isAnalyzing = false;
    }
  }

  Future<double> _analyzeDualCamera() async {
    try {
      // Take pictures from both cameras simultaneously
      final frontImage = await _frontCamera!.takePicture();
      final backImage = await _backCamera!.takePicture();

      // Process images to detect hinge angle
      final frontBytes = await frontImage.readAsBytes();
      final backBytes = await backImage.readAsBytes();

      final frontImg = img.decodeImage(frontBytes);
      final backImg = img.decodeImage(backBytes);

      if (frontImg != null && backImg != null) {
        // Analyze perspective difference between cameras
        final angle = _calculateAngleFromDualImages(frontImg, backImg);
        return angle;
      }
    } catch (e) {
      print('Dual camera analysis error: $e');
    }

    return 90.0; // Default to half-open if analysis fails
  }

  Future<double> _analyzeSingleCamera(CameraController camera) async {
    try {
      final image = await camera.takePicture();
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // Detect edges and estimate hinge position
        final angle = _detectHingeFromEdges(decodedImage);
        return angle;
      }
    } catch (e) {
      print('Single camera analysis error: $e');
    }

    return 90.0; // Default angle
  }

  double _calculateAngleFromDualImages(img.Image frontImg, img.Image backImg) {
    // This is a simplified approach - in practice, you'd need more sophisticated
    // computer vision algorithms

    try {
      // Convert to grayscale for easier processing
      final frontGray = img.grayscale(frontImg);
      final backGray = img.grayscale(backImg);

      // Find horizon lines in both images
      final frontHorizon = _findHorizonLine(frontGray);
      final backHorizon = _findHorizonLine(backGray);

      // Calculate angle based on horizon difference
      if (frontHorizon != null && backHorizon != null) {
        final angleDiff = (frontHorizon - backHorizon).abs();
        // Convert pixel difference to angle (this would need calibration)
        final angle = angleDiff * 0.5; // Simplified conversion
        return angle.clamp(0.0, 180.0);
      }
    } catch (e) {
      print('Dual image analysis error: $e');
    }

    return 90.0; // Default
  }

  double _detectHingeFromEdges(img.Image image) {
    try {
      // Convert to grayscale
      final grayImage = img.grayscale(image);

      // Apply edge detection (simplified Sobel filter)
      final edges = _applySobelFilter(grayImage);

      // Find the strongest horizontal edge (likely the hinge)
      final hingePosition = _findHingeEdge(edges);

      if (hingePosition != null) {
        // Estimate angle based on hinge position in frame
        final positionRatio = hingePosition / image.height;

        // Convert position to angle (this is a simplified heuristic)
        double angle;
        if (positionRatio < 0.3) {
          angle = 0.0; // Closed
        } else if (positionRatio > 0.7) {
          angle = 180.0; // Flat
        } else {
          angle = (positionRatio - 0.3) * (180.0 / 0.4); // Interpolate
        }

        return angle;
      }
    } catch (e) {
      print('Edge detection error: $e');
    }

    return 90.0; // Default
  }

  img.Image _applySobelFilter(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    // Simplified Sobel horizontal kernel
    final kernel = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double sum = 0;

        for (int ky = 0; ky < 3; ky++) {
          for (int kx = 0; kx < 3; kx++) {
            final pixel = image.getPixel(x + kx - 1, y + ky - 1);
            final gray = pixel.r; // Get red channel (already grayscale)
            sum += gray * kernel[ky][kx];
          }
        }

        final value = sum.abs().clamp(0, 255).toInt();
        result.setPixel(x, y, img.ColorRgb8(value, value, value));
      }
    }

    return result;
  }

  double? _findHorizonLine(img.Image image) {
    // Find the most prominent horizontal line
    final rowIntensities = <double>[];

    for (int y = 0; y < image.height; y++) {
      double intensity = 0;
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        intensity += pixel.r; // Get red channel
      }
      rowIntensities.add(intensity / image.width);
    }

    // Find row with maximum intensity change
    double maxChange = 0;
    int? horizonRow;

    for (int i = 1; i < rowIntensities.length - 1; i++) {
      final change = (rowIntensities[i + 1] - rowIntensities[i - 1]).abs();
      if (change > maxChange) {
        maxChange = change;
        horizonRow = i;
      }
    }

    return horizonRow?.toDouble();
  }

  double? _findHingeEdge(img.Image edges) {
    // Find the row with strongest horizontal edge response
    final rowIntensities = <double>[];

    for (int y = 0; y < edges.height; y++) {
      double intensity = 0;
      for (int x = 0; x < edges.width; x++) {
        final pixel = edges.getPixel(x, y);
        intensity += pixel.r; // Get red channel
      }
      rowIntensities.add(intensity);
    }

    // Find peak intensity row
    double maxIntensity = 0;
    int? hingeRow;

    for (int i = 0; i < rowIntensities.length; i++) {
      if (rowIntensities[i] > maxIntensity) {
        maxIntensity = rowIntensities[i];
        hingeRow = i;
      }
    }

    return hingeRow?.toDouble();
  }

  HingeState _angleToHingeState(double angle) {
    if (angle <= 10) return HingeState.closed;
    if (angle <= 45) return HingeState.halfOpen;
    if (angle <= 135) return HingeState.open;
    if (angle <= 170) return HingeState.laptop;
    return HingeState.flat;
  }

  double _calculateConfidence(double angle) {
    // Simple confidence based on how "stable" the angle is
    // In practice, you'd track angle stability over time
    return 0.7; // Placeholder
  }

  // Public method to calibrate the detector
  Future<void> calibrateDetector({
    required double deviceWidthMm,
    required double hingePositionRatio,
  }) async {
    _deviceWidthMm = deviceWidthMm;
    _hingePositionRatio = hingePositionRatio;
  }

  // Method to get camera preview widgets (for debugging/setup)
  Widget? getFrontCameraPreview() {
    if (_frontCamera?.value.isInitialized == true) {
      return CameraPreview(_frontCamera!);
    }
    return null;
  }

  Widget? getBackCameraPreview() {
    if (_backCamera?.value.isInitialized == true) {
      return CameraPreview(_backCamera!);
    }
    return null;
  }

  // Get detailed camera status for debugging
  Map<String, dynamic> getCameraStatus() {
    return {
      'cameras_available': _cameras?.length ?? 0,
      'front_camera_initialized': _frontCamera?.value.isInitialized ?? false,
      'back_camera_initialized': _backCamera?.value.isInitialized ?? false,
      'front_camera_error': _frontCamera?.value.errorDescription,
      'back_camera_error': _backCamera?.value.errorDescription,
      'analysis_running': _analysisTimer?.isActive ?? false,
    };
  }

  // Check current permission status
  Future<Map<String, dynamic>> getPermissionStatus() async {
    final cameraStatus = await Permission.camera.status;
    return {
      'camera_permission': cameraStatus.toString(),
      'is_granted': cameraStatus.isGranted,
      'is_denied': cameraStatus.isDenied,
      'is_permanently_denied': cameraStatus.isPermanentlyDenied,
    };
  }

  // Request permissions again
  Future<bool> requestPermissions() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _frontCamera?.dispose();
    _backCamera?.dispose();
    super.dispose();
  }
}
