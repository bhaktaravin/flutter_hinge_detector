# Flutter Hinge Detector

A comprehensive Flutter application that detects and responds to hinge states on foldable devices. This app provides real-time hinge angle detection, visual feedback, and simulation capabilities for testing on non-foldable devices.

## Features

🔄 **Real-time Hinge Detection**: Monitors hinge angle changes using device sensors and native APIs
📱 **Multi-Device Support**: Works with various foldable devices (Surface Duo, Galaxy Fold, Pixel Fold, etc.)
🎨 **Visual Feedback**: Animated hinge visualizer showing current state and angle
🎮 **Simulation Mode**: Test different hinge positions on regular devices
📊 **Comprehensive UI**: Detailed information about device type, angles, and sensor data
🔧 **Native Integration**: Uses Android's WindowManager API for accurate hinge detection

## Supported Hinge States

- **Closed** (0°-10°): Device completely closed
- **Half Open** (10°-45°): Partially open, ideal for notifications
- **Open** (45°-90°): Dual screen mode
- **Laptop** (90°-120°): Perfect for typing
- **Book** (120°-160°): Great for reading
- **Tent** (160°-170°): Ideal for presentations
- **Flat** (170°-180°): Tablet mode

## Requirements

- Flutter 3.8.1 or higher
- Android API level 24 or higher (for foldable device features)
- Kotlin support

## Dependencies

- `sensors_plus`: For accelerometer and gyroscope data
- `device_info_plus`: For device identification
- `dual_screen`: For foldable device features

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
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

## Usage

### Basic Usage

The app automatically detects hinge changes and displays:
- Current hinge state with color-coded status
- Precise angle measurement
- Device type identification
- Visual hinge representation

### Simulation Mode

For testing on non-foldable devices:
1. Toggle "Simulation Mode" switch
2. Use the slider to adjust hinge angle (0°-180°)
3. Try preset positions with quick buttons
4. Observe real-time state changes

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# flutter_hinge_detector
