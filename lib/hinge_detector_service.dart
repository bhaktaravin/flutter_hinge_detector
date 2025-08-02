import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum HingeState { unknown, closed, halfOpen, open, flat, laptop, book, tent }

enum FoldableType { unknown, surfaceDuo, galaxyFold, pixelFold, generic }

class HingeData {
  final HingeState state;
  final double angle;
  final FoldableType deviceType;
  final bool isPostureSupported;
  final DateTime timestamp;
  final Map<String, dynamic> rawData;

  const HingeData({
    required this.state,
    required this.angle,
    required this.deviceType,
    required this.isPostureSupported,
    required this.timestamp,
    this.rawData = const {},
  });

  @override
  String toString() {
    return 'HingeData(state: $state, angle: ${angle.toStringAsFixed(1)}°, type: $deviceType)';
  }
}

class HingeDetectorService {
  static const MethodChannel _channel = MethodChannel('hinge_detector');

  final StreamController<HingeData> _hingeStateController =
      StreamController<HingeData>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  HingeData _currentHingeData = HingeData(
    state: HingeState.unknown,
    angle: 0.0,
    deviceType: FoldableType.unknown,
    isPostureSupported: false,
    timestamp: DateTime.now(),
  );

  FoldableType _deviceType = FoldableType.unknown;
  bool _isInitialized = false;

  Stream<HingeData> get hingeStateStream => _hingeStateController.stream;
  HingeData get currentHingeData => _currentHingeData;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _detectDeviceType();
    await _setupSensorListeners();
    await _setupNativeHingeDetection();

    _isInitialized = true;
  }

  Future<void> _detectDeviceType() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      final model = androidInfo.model.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();

      if (manufacturer.contains('microsoft') && model.contains('surface')) {
        _deviceType = FoldableType.surfaceDuo;
      } else if (manufacturer.contains('samsung') &&
          (model.contains('fold') || model.contains('flip'))) {
        _deviceType = FoldableType.galaxyFold;
      } else if (manufacturer.contains('google') && model.contains('fold')) {
        _deviceType = FoldableType.pixelFold;
      } else {
        _deviceType = FoldableType.generic;
      }
    } catch (e) {
      _deviceType = FoldableType.generic;
    }
  }

  Future<void> _setupNativeHingeDetection() async {
    try {
      // Try to get hinge angle from native Android API
      final result = await _channel.invokeMethod('getHingeAngle');
      if (result != null) {
        _updateHingeData(result.toDouble(), true);
      }

      // Set up periodic native hinge checks
      Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        try {
          final angle = await _channel.invokeMethod('getHingeAngle');
          if (angle != null) {
            _updateHingeData(angle.toDouble(), true);
          }
        } catch (e) {
          // Native hinge detection not available, rely on sensors
        }
      });
    } catch (e) {
      // Native hinge detection not available
    }
  }

  Future<void> _setupSensorListeners() async {
    // Listen to accelerometer for device orientation changes
    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      _processSensorData(event.x, event.y, event.z);
    });

    // Listen to gyroscope for rotation detection
    _gyroscopeSubscription = gyroscopeEventStream().listen((
      GyroscopeEvent event,
    ) {
      _processGyroscopeData(event.x, event.y, event.z);
    });
  }

  void _processSensorData(double x, double y, double z) {
    // Calculate device orientation based on accelerometer data
    final double magnitude = sqrt(x * x + y * y + z * z);
    if (magnitude < 0.1) return; // Ignore very small movements

    // Normalize the values
    final normalizedX = x / magnitude;
    final normalizedY = y / magnitude;
    final normalizedZ = z / magnitude;

    // Estimate hinge angle based on orientation
    double estimatedAngle = _estimateHingeAngle(
      normalizedX,
      normalizedY,
      normalizedZ,
    );

    _updateHingeData(estimatedAngle, false);
  }

  void _processGyroscopeData(double x, double y, double z) {
    // Use gyroscope data to detect rapid hinge movements
    final rotationMagnitude = sqrt(x * x + y * y + z * z);

    if (rotationMagnitude > 2.0) {
      // Rapid rotation detected - possibly opening/closing hinge
      _updateHingeData(
        _currentHingeData.angle,
        _currentHingeData.isPostureSupported,
        isRapidMovement: true,
      );
    }
  }

  double _estimateHingeAngle(double x, double y, double z) {
    // This is a simplified hinge angle estimation
    // In a real implementation, this would be calibrated for specific devices

    switch (_deviceType) {
      case FoldableType.surfaceDuo:
        return _estimateSurfaceDuoAngle(x, y, z);
      case FoldableType.galaxyFold:
        return _estimateGalaxyFoldAngle(x, y, z);
      case FoldableType.pixelFold:
        return _estimatePixelFoldAngle(x, y, z);
      default:
        return _estimateGenericAngle(x, y, z);
    }
  }

  double _estimateSurfaceDuoAngle(double x, double y, double z) {
    // Surface Duo specific angle calculation
    final angle = atan2(y, z) * 180 / pi;
    return (angle + 180).clamp(0, 360);
  }

  double _estimateGalaxyFoldAngle(double x, double y, double z) {
    // Galaxy Fold specific angle calculation
    final angle = atan2(x, z) * 180 / pi;
    return (angle + 180).clamp(0, 180);
  }

  double _estimatePixelFoldAngle(double x, double y, double z) {
    // Pixel Fold specific angle calculation
    final angle = atan2(y, x) * 180 / pi;
    return (angle + 180).clamp(0, 180);
  }

  double _estimateGenericAngle(double x, double y, double z) {
    // Generic foldable angle calculation
    final angle = atan2((x).abs(), (z).abs()) * 180 / pi;
    return angle.clamp(0, 180);
  }

  void _updateHingeData(
    double angle,
    bool isPostureSupported, {
    bool isRapidMovement = false,
  }) {
    final hingeState = _determineHingeState(angle);

    final newHingeData = HingeData(
      state: hingeState,
      angle: angle,
      deviceType: _deviceType,
      isPostureSupported: isPostureSupported,
      timestamp: DateTime.now(),
      rawData: {
        'rapidMovement': isRapidMovement,
        'confidence': isPostureSupported ? 0.9 : 0.6,
      },
    );

    // Only emit if there's a significant change
    if (_shouldEmitUpdate(newHingeData)) {
      _currentHingeData = newHingeData;
      _hingeStateController.add(_currentHingeData);
    }
  }

  bool _shouldEmitUpdate(HingeData newData) {
    // Emit if state changed or angle changed significantly
    return _currentHingeData.state != newData.state ||
        (newData.angle - _currentHingeData.angle).abs() > 5.0;
  }

  HingeState _determineHingeState(double angle) {
    // Determine hinge state based on angle
    if (angle <= 10) {
      return HingeState.closed;
    } else if (angle <= 45) {
      return HingeState.halfOpen;
    } else if (angle <= 90) {
      return HingeState.open;
    } else if (angle <= 120) {
      return HingeState.laptop;
    } else if (angle <= 160) {
      return HingeState.book;
    } else if (angle <= 170) {
      return HingeState.tent;
    } else {
      return HingeState.flat;
    }
  }

  // Simulate hinge angle changes for testing on non-foldable devices
  void simulateHingeChange(double angle) {
    _updateHingeData(angle, false);
  }

  // Update hinge state (for use by camera or other detection services)
  void updateHingeState(HingeData hingeData) {
    if (_shouldEmitUpdate(hingeData)) {
      _currentHingeData = hingeData;
      _hingeStateController.add(_currentHingeData);
    }
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _hingeStateController.close();
  }
}
