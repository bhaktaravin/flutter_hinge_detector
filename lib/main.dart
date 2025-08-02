import 'package:flutter/material.dart';
import 'hinge_detector_screen.dart';

void main() {
  runApp(const HingeDetectorApp());
}

class HingeDetectorApp extends StatelessWidget {
  const HingeDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hinge Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const HingeDetectorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
