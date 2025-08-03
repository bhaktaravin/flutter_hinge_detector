import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'hinge_detector_service.dart';
import 'hinge_detector_factory.dart';
import 'camera_hinge_detector_service.dart';
import 'camera_hinge_demo.dart';

class HingeDetectorScreen extends StatefulWidget {
  const HingeDetectorScreen({super.key});

  @override
  State<HingeDetectorScreen> createState() => _HingeDetectorScreenState();
}

class _HingeDetectorScreenState extends State<HingeDetectorScreen>
    with TickerProviderStateMixin {
  HingeDetectorService? _hingeService;
  HingeData _currentHingeData = HingeData(
    state: HingeState.unknown,
    angle: 0.0,
    deviceType: FoldableType.unknown,
    isPostureSupported: false,
    timestamp: DateTime.now(),
  );

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSimulationMode = false;
  double _simulationAngle = 0.0;
  HingeDetectionMethod _detectionMethod = HingeDetectionMethod.auto;
  bool _showCameraPreview = false;

  @override
  void initState() {
    super.initState();

    // Use factory to create the appropriate detector
    _hingeService = HingeDetectorFactory.create(method: _detectionMethod);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeHingeDetection();
  }

  Future<void> _initializeHingeDetection() async {
    try {
      await _hingeService?.initialize();
      _hingeService?.hingeStateStream.listen((hingeData) {
        if (mounted) {
          setState(() {
            _currentHingeData = hingeData;
          });
          _animationController.forward(from: 0);
        }
      });
    } catch (e) {
      print('Failed to initialize hinge detection: $e');
      // Continue with app startup even if hinge detection fails
      if (mounted) {
        setState(() {
          _currentHingeData = HingeData(
            state: HingeState.unknown,
            angle: 0.0,
            deviceType: FoldableType.unknown,
            isPostureSupported: false,
            timestamp: DateTime.now(),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _hingeService?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getStateColor(HingeState state) {
    switch (state) {
      case HingeState.closed:
        return Colors.red;
      case HingeState.halfOpen:
        return Colors.orange;
      case HingeState.open:
        return Colors.yellow;
      case HingeState.laptop:
        return Colors.green;
      case HingeState.book:
        return Colors.blue;
      case HingeState.tent:
        return Colors.purple;
      case HingeState.flat:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(HingeState state) {
    switch (state) {
      case HingeState.closed:
        return Icons.tablet;
      case HingeState.halfOpen:
        return Icons.stay_current_portrait;
      case HingeState.open:
        return Icons.stay_current_landscape;
      case HingeState.laptop:
        return Icons.laptop;
      case HingeState.book:
        return Icons.menu_book;
      case HingeState.tent:
        return Icons.roofing;
      case HingeState.flat:
        return Icons.tablet_mac;
      default:
        return Icons.device_unknown;
    }
  }

  String _getStateDescription(HingeState state) {
    switch (state) {
      case HingeState.closed:
        return 'Device is completely closed';
      case HingeState.halfOpen:
        return 'Device is partially open - ideal for notifications';
      case HingeState.open:
        return 'Device is open - dual screen mode';
      case HingeState.laptop:
        return 'Laptop mode - perfect for typing';
      case HingeState.book:
        return 'Book mode - great for reading';
      case HingeState.tent:
        return 'Tent mode - ideal for presentations';
      case HingeState.flat:
        return 'Completely flat - tablet mode';
      default:
        return 'Unknown state';
    }
  }

  Widget _buildHingeVisualizer() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: CustomPaint(
            painter: HingePainter(
              angle: _currentHingeData.angle,
              state: _currentHingeData.state,
              animation: _animation.value,
            ),
            size: const Size.square(200),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getStateIcon(_currentHingeData.state),
                  size: 48,
                  color: _getStateColor(_currentHingeData.state),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentHingeData.state.name.toUpperCase(),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: _getStateColor(_currentHingeData.state),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStateDescription(_currentHingeData.state),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(
                  'Angle',
                  '${_currentHingeData.angle.toStringAsFixed(1)}°',
                ),
                _buildInfoChip('Type', _currentHingeData.deviceType.name),
                _buildInfoChip(
                  'Native Support',
                  _currentHingeData.isPostureSupported ? 'Yes' : 'No',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Simulation Mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Switch(
                  value: _isSimulationMode,
                  onChanged: (value) {
                    setState(() {
                      _isSimulationMode = value;
                    });
                  },
                ),
              ],
            ),
            if (_isSimulationMode) ...[
              const SizedBox(height: 16),
              Text(
                'Simulate Hinge Angle: ${_simulationAngle.toStringAsFixed(0)}°',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Slider(
                value: _simulationAngle,
                min: 0,
                max: 180,
                divisions: 18,
                onChanged: (value) {
                  setState(() {
                    _simulationAngle = value;
                  });
                  _hingeService?.simulateHingeChange(value);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPresetButton('Closed', 0),
                  _buildPresetButton('Half', 45),
                  _buildPresetButton('Open', 90),
                  _buildPresetButton('Laptop', 120),
                  _buildPresetButton('Flat', 180),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, double angle) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _simulationAngle = angle;
        });
        _hingeService?.simulateHingeChange(angle);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _buildDetectionMethodControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Detection Method',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HingeDetectionMethod>(
              value: _detectionMethod,
              decoration: const InputDecoration(
                labelText: 'Detection Method',
                border: OutlineInputBorder(),
              ),
              items:
                  HingeDetectionMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(_getMethodName(method)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _switchDetectionMethod(value);
                }
              },
            ),
            if (_detectionMethod == HingeDetectionMethod.camera ||
                _detectionMethod == HingeDetectionMethod.hybrid) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Show Camera Preview'),
                  const Spacer(),
                  Switch(
                    value: _showCameraPreview,
                    onChanged: (value) {
                      setState(() {
                        _showCameraPreview = value;
                      });
                    },
                  ),
                ],
              ),
              if (_showCameraPreview) ...[
                const SizedBox(height: 16),
                _buildCameraPreview(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _getMethodName(HingeDetectionMethod method) {
    switch (method) {
      case HingeDetectionMethod.sensors:
        return 'Sensors Only';
      case HingeDetectionMethod.camera:
        return 'Camera Vision';
      case HingeDetectionMethod.hybrid:
        return 'Hybrid (Camera + Sensors)';
      case HingeDetectionMethod.auto:
        return 'Auto-Select Best';
    }
  }

  Widget _buildCameraPreview() {
    if (_hingeService is HybridHingeDetectorService) {
      final hybridService = _hingeService as HybridHingeDetectorService;
      final frontPreview = hybridService.getFrontCameraPreview();
      final backPreview = hybridService.getBackCameraPreview();

      return SizedBox(
        height: 200,
        child: Row(
          children: [
            if (backPreview != null)
              Expanded(
                child: Column(
                  children: [
                    const Text('Back Camera'),
                    Expanded(child: backPreview),
                  ],
                ),
              ),
            if (frontPreview != null && backPreview != null)
              const SizedBox(width: 8),
            if (frontPreview != null)
              Expanded(
                child: Column(
                  children: [
                    const Text('Front Camera'),
                    Expanded(child: frontPreview),
                  ],
                ),
              ),
          ],
        ),
      );
    } else if (_hingeService is CameraHingeDetectorService) {
      final cameraService = _hingeService as CameraHingeDetectorService;
      final backPreview = cameraService.getBackCameraPreview();

      return SizedBox(
        height: 200,
        child: backPreview ?? const Center(child: Text('Camera not available')),
      );
    }

    return const SizedBox(
      height: 200,
      child: Center(child: Text('Camera preview not available')),
    );
  }

  Future<void> _switchDetectionMethod(HingeDetectionMethod newMethod) async {
    setState(() {
      _detectionMethod = newMethod;
    });

    // Dispose current service
    _hingeService?.dispose();

    // Create new service
    final newService = HingeDetectorFactory.create(method: newMethod);
    _hingeService = newService;

    try {
      await newService.initialize();
      newService.hingeStateStream.listen((hingeData) {
        if (mounted) {
          setState(() {
            _currentHingeData = hingeData;
          });
          _animationController.forward(from: 0);
        }
      });
    } catch (e) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Detection Method Error'),
                content: Text(
                  'Failed to initialize ${_getMethodName(newMethod)}: $e',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hinge Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CameraHingeDemo(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('About Hinge Detector'),
                      content: const Text(
                        'This app detects the hinge state of foldable devices using sensors and native APIs. '
                        'Use simulation mode to test different hinge positions on regular devices.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHingeVisualizer(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildSimulationControls(),
            const SizedBox(height: 16),
            _buildDetectionMethodControls(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentHingeData.timestamp.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
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

class HingePainter extends CustomPainter {
  final double angle;
  final HingeState state;
  final double animation;

  HingePainter({
    required this.angle,
    required this.state,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final fillPaint =
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 3;

    // Draw the base (first screen)
    final baseRect = Rect.fromCenter(
      center: center - Offset(radius / 2, 0),
      width: radius,
      height: radius * 1.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(8)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(8)),
      paint,
    );

    // Calculate the position of the hinged screen
    final radians = (angle * animation) * math.pi / 180;

    canvas.save();
    canvas.translate(center.dx + radius / 2, center.dy);
    canvas.rotate(radians);
    canvas.translate(-radius / 2, -radius * 0.75);

    final rotatedRect = Rect.fromLTWH(0, 0, radius, radius * 1.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rotatedRect, const Radius.circular(8)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rotatedRect, const Radius.circular(8)),
      paint,
    );

    canvas.restore();

    // Draw the hinge
    canvas.drawLine(
      center + Offset(radius / 2, -radius * 0.75),
      center + Offset(radius / 2, radius * 0.75),
      Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 4,
    );

    // Draw angle arc
    canvas.drawArc(
      Rect.fromCenter(
        center: center + Offset(radius / 2, 0),
        width: 40,
        height: 40,
      ),
      0,
      radians,
      false,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Draw angle text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(angle * animation).toStringAsFixed(0)}°',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, center + Offset(radius / 2 + 30, -10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
