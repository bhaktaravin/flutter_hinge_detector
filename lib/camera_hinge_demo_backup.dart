import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:async';
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
  bool _isInitializing = false; // Add this to prevent multiple initializations
  String _cameraStatus = 'Checking cameras...';
  bool _hasBackCamera = false;
  bool _hasFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissionStatus();
  }

  Future<void> _checkInitialPermissionStatus() async {
    final permissionStatus = await Permission.camera.status;
    setState(() {
      _status =
          'Permission status: ${permissionStatus.toString()}. Use green button to initialize cameras.';
      _cameraStatus = 'Cameras not initialized - use INITIALIZE CAMERAS button';
    });
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing || _isInitialized) {
      print('Camera initialization already in progress or completed');
      return;
    }

    try {
      setState(() {
        _isInitializing = true;
        _status = 'Initializing cameras...';
      });

      // Dispose existing service if any
      _cameraService?.dispose();
      _cameraService = null;

      _cameraService = CameraHingeDetectorService();
      await _cameraService!.initializeCamera();
      await _cameraService!.startAnalysis();

      setState(() {
        _hasBackCamera = true; // Simplified - we have one camera
        _hasFrontCamera = false;
        _cameraStatus = 'Camera: ${_cameraService!.isInitialized ? "✓" : "✗"}';
        _isInitialized = _cameraService!.isInitialized;
        _isInitializing = false;
        _status = 'Camera initialized successfully';
      });

      _cameraService!.hingeStateStream.listen((hingeData) {
        if (mounted) {
          setState(() {
            _detectedAngle = hingeData.angle;
            _status =
                'CAMERA DETECTING: ${hingeData.state.name} at ${hingeData.angle.toStringAsFixed(1)}°';
          });
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize camera: $e';
        _cameraStatus = 'Camera initialization failed';
        _isInitialized = false;
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    print('Disposing camera service...');
    _cameraService?.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    final cameraController = _cameraService?.cameraController;

    if (cameraController != null && cameraController.value.isInitialized) {
      return Card(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Camera Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 200,
              child: CameraPreview(cameraController),
            ),
          ],
        ),
      );
    }
                    ),
                  ),
                  SizedBox(height: 200, child: backPreview),
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
                  SizedBox(height: 200, child: frontPreview),
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
            SizedBox(height: 250, child: backPreview),
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
            SizedBox(height: 250, child: frontPreview),
          ],
        ),
      );
    } else {
      // No camera available
      return Card(
        child: SizedBox(
          height: 250,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
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
                      Text(
                        _status,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
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
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.yellow[100],
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.camera_alt,
                                color: Colors.orange,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Force Camera Permission',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'This will trigger iOS to add Camera to Settings',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  print(
                                    '=== FORCE PERMISSION BUTTON PRESSED ===',
                                  );
                                  try {
                                    // First check current status
                                    final currentStatus =
                                        await Permission.camera.status;
                                    print(
                                      'Current status before request: $currentStatus',
                                    );

                                    if (currentStatus.isPermanentlyDenied) {
                                      setState(() {
                                        _status =
                                            'Permission permanently denied. You MUST manually enable camera permission in iOS Settings > Privacy & Security > Camera > Flutter Hinge Detector';
                                      });

                                      // Open settings directly
                                      await openAppSettings();
                                      return;
                                    }

                                    // This should definitely trigger the iOS permission dialog
                                    final status =
                                        await Permission.camera.request();
                                    print('Force permission result: $status');

                                    setState(() {
                                      _status =
                                          'Permission request result: $status';
                                    });

                                    if (status.isGranted) {
                                      setState(() {
                                        _status =
                                            'SUCCESS! Camera permission granted!';
                                      });
                                      await _initializeCamera();
                                    } else if (status.isPermanentlyDenied) {
                                      setState(() {
                                        _status =
                                            'Permission permanently denied. Opening Settings...';
                                      });
                                      await openAppSettings();
                                    } else {
                                      setState(() {
                                        _status = 'Permission denied: $status';
                                      });
                                    }
                                  } catch (e) {
                                    print('Force permission error: $e');
                                    setState(() {
                                      _status = 'Permission error: $e';
                                    });
                                  }
                                },
                                child: const Text('FORCE CAMERA PERMISSION'),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                color: Colors.red[100],
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.warning,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'iOS Permission Reset Required',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Delete app, restart device, reinstall app',
                                        style: TextStyle(fontSize: 11),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () async {
                                          setState(() {
                                            _status =
                                                'INSTRUCTIONS: 1) Delete this app from iOS, 2) Restart your device, 3) Run "flutter run" again to reinstall';
                                          });
                                        },
                                        child: const Text(
                                          'Show Reset Instructions',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isInitialized) ...[
                        TextButton(
                          onPressed: _initializeCamera,
                          child: const Text('Retry Camera Setup'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            print('Test button tapped successfully!');
                            setState(() {
                              _status =
                                  'Button interactions working perfectly!';
                            });
                          },
                          child: const Text('Test Button (Tap Me)'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            print('=== CAMERA TEST START ===');
                            try {
                              // First check permission status
                              final permissionStatus =
                                  await Permission.camera.status;
                              print('Permission status: $permissionStatus');

                              // Try to get available cameras regardless of permission
                              print('Getting cameras...');
                              final cameras = await availableCameras();
                              print('Found ${cameras.length} cameras');

                              // Log camera details
                              for (int i = 0; i < cameras.length; i++) {
                                print(
                                  'Camera $i: ${cameras[i].name} - ${cameras[i].lensDirection}',
                                );
                              }

                              // Update state safely
                              if (mounted) {
                                setState(() {
                                  _status =
                                      'Camera test: Found ${cameras.length} cameras';
                                });
                              }

                              print('=== CAMERA TEST SUCCESS ===');
                            } catch (e, stackTrace) {
                              print('=== CAMERA TEST ERROR ===');
                              print('Error: $e');
                              print('Stack: $stackTrace');

                              if (mounted) {
                                setState(() {
                                  _status = 'Camera test failed: $e';
                                });
                              }
                            }
                          },
                          child: const Text('Ultra Safe Camera Test'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            print('=== BYPASS PERMISSION TEST START ===');
                            try {
                              // Try to access cameras WITHOUT permission check
                              print('Trying direct camera access bypass...');
                              final cameras = await availableCameras();
                              print('BYPASS: Found ${cameras.length} cameras');

                              // Log camera details
                              for (int i = 0; i < cameras.length; i++) {
                                print(
                                  'BYPASS Camera $i: ${cameras[i].name} - ${cameras[i].lensDirection}',
                                );
                              }

                              if (mounted) {
                                setState(() {
                                  _status =
                                      'BYPASS SUCCESS: Found ${cameras.length} cameras! Cameras are accessible.';
                                });
                              }

                              print('=== BYPASS TEST SUCCESS ===');
                            } catch (e, stackTrace) {
                              print('=== BYPASS TEST ERROR ===');
                              print('Error: $e');
                              print('Stack: $stackTrace');

                              if (mounted) {
                                setState(() {
                                  _status = 'BYPASS FAILED: $e';
                                });
                              }
                            }
                          },
                          child: const Text('BYPASS Permission Test'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _initializeCamera,
                          child: const Text('🎯 INITIALIZE CAMERAS'),
                        ),
                        const SizedBox(height: 8),
                        if (_isInitialized) ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              print('=== RESETTING CAMERA SERVICE ===');
                              try {
                                setState(() {
                                  _status = 'Resetting camera service...';
                                });

                                // Dispose existing service
                                _cameraService?.dispose();
                                _cameraService = null;

                                setState(() {
                                  _isInitialized = false;
                                  _isInitializing = false;
                                  _hasBackCamera = false;
                                  _hasFrontCamera = false;
                                  _detectedAngle = 0.0;
                                  _cameraStatus =
                                      'Cameras reset - use INITIALIZE CAMERAS button';
                                  _status =
                                      'Camera service reset. Ready to initialize again.';
                                });

                                print('=== CAMERA SERVICE RESET COMPLETE ===');
                              } catch (e) {
                                print('Reset error: $e');
                                setState(() {
                                  _status = 'Reset failed: $e';
                                });
                              }
                            },
                            child: const Text('🔄 RESET CAMERAS'),
                          ),
                          const SizedBox(height: 8),
                          // Pause/Resume Analysis buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    if (_cameraService != null) {
                                      _cameraService!.pauseAnalysis();
                                      setState(() {
                                        _status =
                                            'Camera analysis PAUSED - no more flashing';
                                      });
                                    }
                                  },
                                  child: const Text('⏸️ PAUSE ANALYSIS'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    if (_cameraService != null) {
                                      _cameraService!.resumeAnalysis();
                                      setState(() {
                                        _status =
                                            'Camera analysis RESUMED - detecting hinge';
                                      });
                                    }
                                  },
                                  child: const Text('▶️ RESUME ANALYSIS'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
                SizedBox(
                  height: 300, // Fixed height instead of Expanded
                  child: _buildCameraPreview(),
                ),
              ] else ...[
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              const SizedBox(height: 16),
              if (_cameraService != null) ...[
                // Hinge Measurements Card
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.straighten, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Hinge Measurements',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<Map<String, dynamic>>(
                          future: Future.value(
                            _cameraService!.getHingeMeasurements(),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              final measurements = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (measurements.containsKey(
                                    'standard_size',
                                  )) ...[
                                    Text(
                                      'Standard Size: ${measurements['standard_size']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (measurements.containsKey(
                                    'estimated_width_mm',
                                  ))
                                    Text(
                                      'Width: ${measurements['estimated_width_mm']?.toStringAsFixed(1) ?? 'N/A'} mm',
                                    ),
                                  if (measurements.containsKey(
                                    'estimated_height_mm',
                                  ))
                                    Text(
                                      'Height: ${measurements['estimated_height_mm']?.toStringAsFixed(1) ?? 'N/A'} mm',
                                    ),
                                  if (measurements.containsKey(
                                    'screw_spacing_mm',
                                  ))
                                    Text(
                                      'Screw Spacing: ${measurements['screw_spacing_mm']?.toStringAsFixed(1) ?? 'N/A'} mm',
                                    ),
                                  if (measurements.containsKey('hinge_type'))
                                    Text('Type: ${measurements['hinge_type']}'),
                                  if (measurements.containsKey(
                                    'screw_hole_count',
                                  ))
                                    Text(
                                      'Screw Holes: ${measurements['screw_hole_count']}',
                                    ),
                                  if (measurements.containsKey('confidence'))
                                    Text(
                                      'Confidence: ${(measurements['confidence'] * 100).toStringAsFixed(0)}%',
                                    ),
                                  if (measurements.containsKey('status'))
                                    Text(
                                      'Status: ${measurements['status']}',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  if (measurements.containsKey('message'))
                                    Text(
                                      measurements['message'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              );
                            } else {
                              return const Text(
                                'No hinge measurements available yet.\nTake pictures to detect screw holes and measure hinge size.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Camera Permissions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _cameraService!.getPermissionStatus(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final data = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...data.entries.map(
                                    (e) => Text('${e.key}: ${e.value}'),
                                  ),
                                  const SizedBox(height: 8),
                                  if (!data['is_granted'])
                                    Column(
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                print(
                                                  'Request Permission button pressed',
                                                );
                                                try {
                                                  // First check current status
                                                  final currentStatus =
                                                      await Permission
                                                          .camera
                                                          .status;
                                                  print(
                                                    'Current camera permission: $currentStatus',
                                                  );

                                                  // Force a fresh permission request
                                                  print(
                                                    'Requesting camera permission directly...',
                                                  );
                                                  final newStatus =
                                                      await Permission.camera
                                                          .request();
                                                  print(
                                                    'New permission status: $newStatus',
                                                  );

                                                  setState(() {
                                                    _status =
                                                        'Permission status: $newStatus';
                                                  });

                                                  if (newStatus.isGranted) {
                                                    print(
                                                      'Permission granted! Initializing camera...',
                                                    );
                                                    await _initializeCamera();
                                                  } else if (newStatus
                                                      .isPermanentlyDenied) {
                                                    print(
                                                      'Permission permanently denied',
                                                    );
                                                    setState(() {
                                                      _status =
                                                          'Permission permanently denied. Please enable in Settings.';
                                                    });
                                                  } else {
                                                    print('Permission denied');
                                                    setState(() {
                                                      _status =
                                                          'Permission denied';
                                                    });
                                                  }
                                                } catch (e) {
                                                  print(
                                                    'Error requesting permission: $e',
                                                  );
                                                  setState(() {
                                                    _status = 'Error: $e';
                                                  });
                                                }
                                              },
                                              child: const Text(
                                                'Request Permission',
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => openAppSettings(),
                                              child: const Text(
                                                'Open Settings',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            print(
                                              'Trying SAFER camera access...',
                                            );
                                            try {
                                              // First check permission again
                                              final permissionStatus =
                                                  await Permission
                                                      .camera
                                                      .status;
                                              print(
                                                'Current permission before access: $permissionStatus',
                                              );

                                              if (!permissionStatus.isGranted) {
                                                setState(() {
                                                  _status =
                                                      'Permission not granted: $permissionStatus. Please restart app after enabling permission.';
                                                });
                                                return;
                                              }

                                              // Try to access cameras with timeout
                                              print(
                                                'Getting available cameras...',
                                              );
                                              final cameras =
                                                  await availableCameras().timeout(
                                                    const Duration(seconds: 5),
                                                    onTimeout: () {
                                                      throw TimeoutException(
                                                        'Camera access timed out',
                                                        const Duration(
                                                          seconds: 5,
                                                        ),
                                                      );
                                                    },
                                                  );

                                              print(
                                                'Found ${cameras.length} cameras via safer access',
                                              );

                                              if (cameras.isNotEmpty) {
                                                setState(() {
                                                  _status =
                                                      'SUCCESS: Found ${cameras.length} cameras! Permission working.';
                                                });
                                                print(
                                                  'Safer camera access successful!',
                                                );
                                              } else {
                                                setState(() {
                                                  _status =
                                                      'No cameras available';
                                                });
                                              }
                                            } catch (e) {
                                              print(
                                                'Safer camera access error: $e',
                                              );
                                              setState(() {
                                                _status =
                                                    'Camera access failed: $e. Try restarting app.';
                                              });
                                            }
                                          },
                                          child: const Text('Safe Camera Test'),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            print(
                                              'Direct permission request button pressed',
                                            );
                                            try {
                                              final status =
                                                  await Permission.camera
                                                      .request();
                                              print(
                                                'Direct permission result: $status',
                                              );
                                              setState(() {});
                                            } catch (e) {
                                              print(
                                                'Direct permission error: $e',
                                              );
                                            }
                                          },
                                          child: const Text(
                                            'Direct Camera Request (Debug)',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Card(
                                          color: Colors.amber[100],
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.info,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Permission Issue Fix',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'If camera permission is enabled in Settings but app still shows denied, restart the app.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    print(
                                                      'User requested app restart for permission fix',
                                                    );
                                                    setState(() {
                                                      _status =
                                                          'Please hot restart the app (r in terminal) or restart from VS Code to refresh permissions.';
                                                    });
                                                  },
                                                  child: const Text(
                                                    'Need Restart?',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            }
                            return const Text('Loading permission status...');
                          },
                        ),
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
                      Text('• Detects screw holes to measure hinge size'),
                      Text(
                        '• Identifies standard hinge sizes (2", 3", 4", etc.)',
                      ),
                      Text(
                        '• Single camera mode (iOS-optimized, no conflicts)',
                      ),
                      Text('• Flash disabled, analysis every 5 seconds'),
                      Text('• Estimates angles based on visual cues'),
                      Text('• More accurate than sensor-only detection'),
                      Text('• Use pause/resume to control camera activity'),
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
      ),
    );
  }
}
