import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'hinge_detector_service.dart';

class CameraHingeDetectorService extends ChangeNotifier {
  CameraController? _primaryCamera;
  Timer? _analysisTimer;
  bool _isAnalyzing = false;
  bool _isInitialized = false;

  List<Map<String, dynamic>> _detectedScrewHoles = [];
  Map<String, dynamic> _hingeMeasurements = {};

  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get detectedScrewHoles => _detectedScrewHoles;
  Map<String, dynamic> get hingeMeasurements => _hingeMeasurements;

  Stream<HingeData> get hingeStateStream async* {
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      if (_isInitialized && !_isAnalyzing) {
        yield await _performAnalysis();
      }
    }
  }

  Future<void> initializeCamera() async {
    try {
      print('Initializing camera for hinge detection...');

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available');
        return;
      }

      // Use the first available camera
      _primaryCamera = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _primaryCamera!.initialize();

      // Disable flash to prevent iOS errors
      await _primaryCamera!.setFlashMode(FlashMode.off);

      _isInitialized = true;
      notifyListeners();

      print('Camera initialized successfully');
    } catch (e) {
      print('Camera initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<void> startAnalysis() async {
    if (!_isInitialized) {
      await initializeCamera();
    }

    if (_isInitialized && _analysisTimer == null) {
      print('Starting hinge analysis...');
      _analysisTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (!_isAnalyzing) {
          await _performAnalysis();
        }
      });
    }
  }

  Future<void> stopAnalysis() async {
    print('Stopping hinge analysis...');
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  Future<HingeData> _performAnalysis() async {
    if (_isAnalyzing || !_isInitialized) {
      return HingeData(
        angle: 90.0,
        state: HingeState.unknown,
        deviceType: FoldableType.generic,
        isPostureSupported: true,
        timestamp: DateTime.now(),
        rawData: {},
      );
    }

    _isAnalyzing = true;

    try {
      print('Analyzing camera preview for hinge detection...');

      // Simulate screw hole detection
      await _simulateScrewHoleDetection();

      // Simulate hinge detection
      final angle = _simulateHingeDetection();
      print('Simulated camera angle detected: ${angle.toStringAsFixed(1)}°');

      // Calculate hinge measurements
      _calculateHingeSize();

      final hingeData = HingeData(
        angle: angle,
        state: _angleToHingeState(angle),
        deviceType: FoldableType.generic,
        isPostureSupported: true,
        timestamp: DateTime.now(),
        rawData: Map.from(_hingeMeasurements),
      );

      notifyListeners();
      return hingeData;
    } catch (e) {
      print('Analysis error: $e');
      return HingeData(
        angle: 90.0,
        state: HingeState.unknown,
        deviceType: FoldableType.generic,
        isPostureSupported: true,
        timestamp: DateTime.now(),
        rawData: {},
      );
    } finally {
      _isAnalyzing = false;
    }
  }

  Future<void> _simulateScrewHoleDetection() async {
    print('Simulating screw hole detection...');

    _detectedScrewHoles.clear();

    // Simulate a standard 3.5" x 3.5" hinge with 4 screw holes
    _detectedScrewHoles.addAll([
      {'x': 50, 'y': 100, 'radius': 8, 'confidence': 0.9, 'type': 'screw_hole'},
      {
        'x': 150,
        'y': 100,
        'radius': 8,
        'confidence': 0.85,
        'type': 'screw_hole',
      },
      {
        'x': 50,
        'y': 200,
        'radius': 8,
        'confidence': 0.88,
        'type': 'screw_hole',
      },
      {
        'x': 150,
        'y': 200,
        'radius': 8,
        'confidence': 0.92,
        'type': 'screw_hole',
      },
    ]);

    print('Simulated ${_detectedScrewHoles.length} screw holes');
  }

  double _simulateHingeDetection() {
    // Simulate various hinge angles for demonstration
    final angles = [0.0, 45.0, 90.0, 135.0, 180.0];
    final randomIndex = DateTime.now().millisecond % angles.length;
    return angles[randomIndex];
  }

  void _calculateHingeSize() {
    if (_detectedScrewHoles.length < 2) {
      print('Not enough screw holes detected for measurement');
      return;
    }

    _measureHingeDimensions();
    _classifyHingeType();
  }

  void _measureHingeDimensions() {
    if (_detectedScrewHoles.length < 2) return;

    // Calculate dimensions based on screw hole positions
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final hole in _detectedScrewHoles) {
      final x = hole['x'].toDouble();
      final y = hole['y'].toDouble();

      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }

    final width = maxX - minX;
    final height = maxY - minY;

    // Convert pixels to approximate inches (rough estimation)
    final pixelsPerInch = 100.0; // Approximate
    final widthInches = width / pixelsPerInch;
    final heightInches = height / pixelsPerInch;

    _hingeMeasurements.addAll({
      'width_pixels': width,
      'height_pixels': height,
      'width_inches': widthInches,
      'height_inches': heightInches,
      'screw_count': _detectedScrewHoles.length,
      'confidence':
          _detectedScrewHoles
              .map((h) => h['confidence'])
              .reduce((a, b) => a + b) /
          _detectedScrewHoles.length,
    });
  }

  void _classifyHingeType() {
    if (!_hingeMeasurements.containsKey('width_inches')) return;

    final width = _hingeMeasurements['width_inches'];
    final height = _hingeMeasurements['height_inches'];

    // Standard hinge sizes (approximate)
    final standardSizes = [
      {'size': '2" x 2"', 'width': 2.0, 'height': 2.0},
      {'size': '2.5" x 2.5"', 'width': 2.5, 'height': 2.5},
      {'size': '3" x 3"', 'width': 3.0, 'height': 3.0},
      {'size': '3.5" x 3.5"', 'width': 3.5, 'height': 3.5},
      {'size': '4" x 4"', 'width': 4.0, 'height': 4.0},
      {'size': '4.5" x 4.5"', 'width': 4.5, 'height': 4.5},
      {'size': '5" x 5"', 'width': 5.0, 'height': 5.0},
    ];

    // Find closest standard size
    double minDistance = double.infinity;
    String closestSize = 'Unknown';

    for (final standard in standardSizes) {
      final distance = math.sqrt(
        math.pow(width - standard['width']!, 2) +
            math.pow(height - standard['height']!, 2),
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestSize = standard['size'] as String;
      }
    }

    _hingeMeasurements.addAll({
      'hinge_type': closestSize,
      'standard_match_confidence': math.max(0.0, 1.0 - (minDistance / 2.0)),
    });
  }

  HingeState _angleToHingeState(double angle) {
    if (angle < 15) return HingeState.closed;
    if (angle < 45) return HingeState.halfOpen;
    if (angle < 135) return HingeState.open;
    if (angle < 165) return HingeState.laptop;
    return HingeState.flat;
  }

  CameraController? get cameraController => _primaryCamera;

  @override
  void dispose() {
    print('Disposing camera hinge detector service...');
    _analysisTimer?.cancel();
    _primaryCamera?.dispose();
    super.dispose();
  }
}
