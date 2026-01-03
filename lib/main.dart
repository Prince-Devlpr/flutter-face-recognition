import 'package:flutter/material.dart';
import 'dart:math';
import 'screens/login_screen.dart';
import 'storage/student_storage.dart'; // ✅ Import StudentStorage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StudentStorage.init(); // Initialize Hive
  runApp(const RollBookApp());
}

class RollBookApp extends StatelessWidget {
  const RollBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.blue;
    return MaterialApp(
      title: 'RollBook', // ✅ Updated app name
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // ✅ Start with splash animation
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController circleController;
  late AnimationController fadeController;

  @override
  void initState() {
    super.initState();

    // Circle drawing controller
    circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Logo fade controller
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Sequence: draw circle -> fade logo -> go to LoginScreen
    circleController.forward().whenComplete(() {
      fadeController.forward().whenComplete(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    circleController.dispose();
    fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: circleController,
          builder: (context, child) {
            return CustomPaint(
              painter: CirclePainter(circleController.value),
              child: FadeTransition(
                opacity: fadeController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.all(4), // ✅ white border padding
                    decoration: BoxDecoration(
                      color: Colors.white, // border color
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/rollbook_logo.png', // ✅ Your logo
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final double progress;
  CirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2193b0)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final radius = min(size.width, size.height) / 2.2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: radius);

    // Draw only part of the circle based on animation progress
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}