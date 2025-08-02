# Flutter Hinge Detector with Camera Vision

A comprehensive Flutter application that detects and responds to hinge states on foldable devices using multiple detection methods including **camera-based computer vision**.

## Features

### 🔍 Multi-Method Hinge Detection
- **Sensor-based detection**: Uses accelerometer and gyroscope data
- **Camera-based detection**: Computer vision approach using device cameras ✨
- **Hybrid detection**: Combines both methods for improved accuracy
- **Auto-selection**: Automatically chooses the best method for each device

### 📱 Device Support
- Samsung Galaxy Fold/Flip series
- Google Pixel Fold
- Microsoft Surface Duo
- Generic foldable devices
- iOS devices (simulation mode)

### 🎮 Interactive Features
- Real-time hinge angle visualization
- Multiple hinge states (closed, half-open, open, laptop, book, tent, flat)
- Simulation mode for testing on non-foldable devices
- Live camera preview for debugging computer vision

## Camera-Based Hinge Detection ✨

### How It Works

The camera-based detection system uses computer vision techniques to determine hinge angles:

1. **Dual Camera Analysis**: Uses both front and back cameras simultaneously to detect perspective differences
2. **Edge Detection**: Applies Sobel filters to detect the physical hinge line in camera feeds
3. **Horizon Analysis**: Finds horizontal lines that indicate the fold/hinge position
4. **Angle Estimation**: Converts visual cues to precise angle measurements

### Advantages Over Sensor-Only Detection

- **Direct Physical Measurement**: Detects actual hinge position rather than inferring from device orientation
- **Higher Accuracy**: Less affected by device orientation and movement
- **Works on More Devices**: Doesn't require specialized hinge sensors
- **Real-time Visual Feedback**: Can see what the system is detecting

### Implementation Details

```dart
// Example usage
final cameraService = CameraHingeDetectorService();
await cameraService.initialize();

cameraService.hingeStateStream.listen((hingeData) {
  print('Detected angle: ${hingeData.angle}°');
  print('Hinge state: ${hingeData.state}');
});
```

The computer vision pipeline includes:
- **Image Preprocessing**: Convert to grayscale, apply noise reduction
- **Edge Detection**: Sobel filter for horizontal edge detection
- **Feature Extraction**: Identify hinge line candidates
- **Angle Calculation**: Convert visual features to angle measurements
- **Confidence Scoring**: Assess reliability of detection

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Camera permissions for computer vision features
- Physical foldable device for best results (optional)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/bhaktaravin/flutter_hinge_detector.git
cd flutter_hinge_detector
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Permissions

The app requires camera permissions for computer vision features:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to detect hinge angles on foldable devices.</string>
```

## Usage

### Camera-Based Detection Demo

Access the camera demo through the camera icon in the app bar to see live computer vision hinge detection:

- **Real-time Processing**: See the camera feed being analyzed
- **Edge Detection**: Visual feedback of detected edges
- **Angle Calculation**: Live angle estimation from visual data

### Detection Method Selection

The app allows you to choose between different detection methods:

1. **Sensors Only**: Traditional accelerometer/gyroscope detection
2. **Camera Vision**: Pure computer vision approach
3. **Hybrid**: Combines camera and sensors for best accuracy
4. **Auto-Select**: Automatically chooses the best method

### Basic Hinge Detection
```dart
import 'package:flutter_hinge_detector/hinge_detector_factory.dart';

// Create detector with auto method selection
final detector = HingeDetectorFactory.create(
  method: HingeDetectionMethod.auto
);

await detector.initialize();

detector.hingeStateStream.listen((hingeData) {
  switch (hingeData.state) {
    case HingeState.closed:
      // Handle closed state
      break;
    case HingeState.laptop:
      // Handle laptop mode
      break;
    // ... other states
  }
});
```

### Camera-Only Detection
```dart
// Use camera-based detection specifically
final detector = HingeDetectorFactory.create(
  method: HingeDetectionMethod.camera
);

// Access camera preview for debugging
if (detector is CameraHingeDetectorService) {
  final preview = detector.getBackCameraPreview();
  // Display preview widget
}
```

### Hybrid Detection
```dart
// Combine sensors and camera for best accuracy
final detector = HingeDetectorFactory.create(
  method: HingeDetectionMethod.hybrid
);

// Calibrate camera detection for your device
if (detector is HybridHingeDetectorService) {
  await detector.calibrateCamera(
    deviceWidthMm: 150.0, // Your device width
    hingePositionRatio: 0.5, // Hinge position (0.0 to 1.0)
  );
}
```

## Detection Methods Comparison

| Method | Accuracy | Battery Usage | Device Support | Real-time | Use Case |
|--------|----------|---------------|----------------|-----------|----------|
| Sensors | Medium | Low | Most devices | ✅ | Basic detection |
| Camera | High | Medium | Camera required | ✅ | Precise measurement |
| Hybrid | Very High | Medium | Both required | ✅ | Production apps |
| Auto | Adaptive | Varies | All devices | ✅ | General use |

## Hinge States

The app detects the following hinge states:

- **Closed** (0°): Device completely closed
- **Half Open** (≤45°): Partially open, ideal for notifications
- **Open** (≤90°): Standard dual-screen mode
- **Laptop** (≤120°): Laptop-style positioning
- **Book** (≤160°): Book reading mode
- **Tent** (≤170°): Tent mode for presentations
- **Flat** (180°): Completely flat tablet mode

## Computer Vision Technical Details

### Edge Detection Algorithm

The camera-based detection uses a simplified Sobel filter for edge detection:

```dart
// Horizontal Sobel kernel for detecting horizontal edges (hinge line)
final kernel = [
  [-1, -2, -1],
  [0,   0,  0],
  [1,   2,  1],
];
```

### Image Processing Pipeline

1. **Capture**: Low-resolution images (320x240) for fast processing
2. **Grayscale**: Convert to single channel for edge detection
3. **Sobel Filter**: Apply horizontal edge detection
4. **Peak Detection**: Find strongest horizontal edges
5. **Angle Estimation**: Convert edge position to hinge angle

### Performance Optimizations

- **Low Resolution**: Uses 320x240 for 4x faster processing
- **Frame Skipping**: Processes every 500ms to balance accuracy/performance
- **Memory Efficient**: Minimal allocation during image processing
- **Fallback System**: Automatically switches to sensors if camera fails

## Performance Considerations

### Camera Detection Optimization
- Uses low resolution (320x240) for faster processing
- Processes frames every 500ms to balance accuracy and performance
- Implements edge detection optimizations
- Automatically falls back to sensor detection if camera fails

### Memory Usage
- Efficient image processing with minimal memory allocation
- Automatic cleanup of camera resources
- Stream management to prevent memory leaks

## Troubleshooting

### Camera Not Working
1. Ensure camera permissions are granted
2. Check device has both front/back cameras
3. Try restarting the app
4. Switch to sensor-only mode as fallback

### Poor Detection Accuracy
1. Ensure good lighting conditions
2. Keep camera lenses clean
3. Calibrate the detector for your specific device
4. Use hybrid mode for best results

### Performance Issues
1. Close other camera apps
2. Ensure sufficient device memory
3. Lower detection frequency if needed
4. Use sensor-only mode on older devices

## Architecture

```
┌─────────────────────────────────────┐
│         HingeDetectorFactory        │
│  (Creates appropriate detector)     │
└─────────────┬───────────────────────┘
              │
    ┌─────────┼─────────┐
    │         │         │
    ▼         ▼         ▼
┌─────────┐ ┌──────┐ ┌──────────┐
│ Sensor  │ │Camera│ │ Hybrid   │
│Detector │ │Vision│ │ Detector │
└─────────┘ └──────┘ └──────────┘
    │         │         │
    └─────────┼─────────┘
              │
              ▼
    ┌─────────────────┐
    │   HingeData     │
    │  (Unified API)  │
    └─────────────────┘
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

### Areas for Improvement
- Enhanced computer vision algorithms
- Machine learning-based angle detection
- Support for more device types
- Performance optimizations
- Additional calibration methods

## Future Enhancements

- **Machine Learning**: Train models for specific device types
- **Stereo Vision**: Use camera parallax for 3D angle measurement
- **AR Integration**: Augmented reality overlay for hinge visualization
- **Cloud Calibration**: Shared calibration data for device models

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the excellent framework
- Camera plugin contributors
- Computer vision community for edge detection algorithms
- Foldable device manufacturers for inspiring this project
