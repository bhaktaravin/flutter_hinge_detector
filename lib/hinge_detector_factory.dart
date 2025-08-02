import 'dart:io';
import 'package:flutter/material.dart';
import 'hinge_detector_service.dart';
import 'ios_hinge_detector_service.dart';
import 'camera_hinge_detector_service.dart';

enum HingeDetectionMethod {
  sensors,
  camera,
  hybrid, // Use both sensors and camera
  auto, // Auto-select best method
}

class HingeDetectorFactory {
  static HingeDetectorService create({
    HingeDetectionMethod method = HingeDetectionMethod.auto,
  }) {
    switch (method) {
      case HingeDetectionMethod.sensors:
        return _createSensorBasedDetector();

      case HingeDetectionMethod.camera:
        return CameraHingeDetectorService();

      case HingeDetectionMethod.hybrid:
        return HybridHingeDetectorService();

      case HingeDetectionMethod.auto:
        return _createAutoDetector();
    }
  }

  static HingeDetectorService _createSensorBasedDetector() {
    if (Platform.isIOS) {
      return IOSHingeDetectorService();
    } else {
      return HingeDetectorService();
    }
  }

  static HingeDetectorService _createAutoDetector() {
    // On iOS, prefer camera detection since sensors are limited
    if (Platform.isIOS) {
      return CameraHingeDetectorService();
    }

    // On Android, use hybrid approach for better accuracy
    return HybridHingeDetectorService();
  }
}

class HybridHingeDetectorService extends HingeDetectorService {
  late HingeDetectorService _sensorService;
  late CameraHingeDetectorService _cameraService;

  HingeData? _lastSensorData;
  HingeData? _lastCameraData;

  @override
  Future<void> initialize() async {
    // Initialize both services
    _sensorService =
        Platform.isIOS ? IOSHingeDetectorService() : HingeDetectorService();
    _cameraService = CameraHingeDetectorService();

    // Initialize sensor service first (faster)
    await _sensorService.initialize();

    // Try to initialize camera service
    try {
      await _cameraService.initialize();
    } catch (e) {
      print('Camera service initialization failed, using sensors only: $e');
    }

    // Listen to both streams
    _sensorService.hingeStateStream.listen((data) {
      _lastSensorData = data;
      _fuseData();
    });

    _cameraService.hingeStateStream.listen((data) {
      _lastCameraData = data;
      _fuseData();
    });
  }

  void _fuseData() {
    HingeData? fusedData;

    // Data fusion logic
    if (_lastCameraData != null && _lastSensorData != null) {
      // Both sources available - use weighted average
      final cameraWeight = 0.7; // Camera is more accurate
      final sensorWeight = 0.3;

      final fusedAngle =
          (_lastCameraData!.angle * cameraWeight) +
          (_lastSensorData!.angle * sensorWeight);

      // Use camera state if confidence is high, otherwise sensor state
      final cameraConfidence = _lastCameraData!.rawData['confidence'] ?? 0.5;
      final state =
          cameraConfidence > 0.6
              ? _lastCameraData!.state
              : _lastSensorData!.state;

      fusedData = HingeData(
        state: state,
        angle: fusedAngle,
        deviceType: _lastCameraData!.deviceType,
        isPostureSupported: true,
        timestamp: DateTime.now(),
        rawData: {
          'fusion_method': 'camera_sensor_hybrid',
          'camera_confidence': cameraConfidence,
          'camera_angle': _lastCameraData!.angle,
          'sensor_angle': _lastSensorData!.angle,
        },
      );
    } else if (_lastCameraData != null) {
      // Only camera data available
      fusedData = _lastCameraData;
    } else if (_lastSensorData != null) {
      // Only sensor data available
      fusedData = _lastSensorData;
    }

    if (fusedData != null) {
      updateHingeState(fusedData);
    }
  }

  // Expose camera preview widgets for debugging
  Widget? getFrontCameraPreview() {
    return _cameraService.getFrontCameraPreview();
  }

  Widget? getBackCameraPreview() {
    return _cameraService.getBackCameraPreview();
  }

  Future<void> calibrateCamera({
    required double deviceWidthMm,
    required double hingePositionRatio,
  }) async {
    await _cameraService.calibrateDetector(
      deviceWidthMm: deviceWidthMm,
      hingePositionRatio: hingePositionRatio,
    );
  }

  @override
  void dispose() {
    _sensorService.dispose();
    _cameraService.dispose();
    super.dispose();
  }
}
