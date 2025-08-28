import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/splash_viewmodel.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashViewModel>().initApp(context);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF2B1B15),
      body: Stack(
        children: [
          // Background patterns
          _buildBackgroundPatterns(),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(flex: 2),

                // Logo with enhanced glow
                // Logo with round shape + glow
                Hero(
                  tag: 'logo',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.shade600.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: Colors.orange.shade400.withOpacity(0.2),
                          blurRadius: 80,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb,
                              color: Colors.white,
                              size: 70,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Brand name with enhanced gradient
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(seconds: 1),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.orange.shade600,
                        Colors.deepOrange.shade400,
                        Colors.orange.shade600,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: const Text(
                      "Darshan Trip",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Bottom tagline
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(seconds: 1, milliseconds: 500),
                    child: Column(
                      children: [
                        Container(
                          height: 2,
                          width: 40,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade600,
                                Colors.deepOrange.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Text(
                          "Your Sacred Journey Begins",
                          style: TextStyle(
                            color: Colors.orange.shade300.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPatterns() {
    return Stack(
      children: [
        // Bus silhouettes in background
        Positioned(
          top: 80,
          right: -60,
          child: Transform.rotate(
            angle: 0.2,
            child: _buildBusPattern(Colors.orange.withOpacity(0.04), 100),
          ),
        ),
        Positioned(
          top: 200,
          left: -80,
          child: Transform.rotate(
            angle: -0.15,
            child: _buildBusPattern(Colors.deepOrange.withOpacity(0.03), 80),
          ),
        ),
        Positioned(
          bottom: 180,
          right: -40,
          child: Transform.rotate(
            angle: 0.1,
            child: _buildBusPattern(Colors.orange.withOpacity(0.035), 90),
          ),
        ),
        Positioned(
          bottom: 60,
          left: -70,
          child: Transform.rotate(
            angle: -0.25,
            child: _buildBusPattern(Colors.orange.withOpacity(0.025), 70),
          ),
        ),

        // Road lines pattern
        ...List.generate(6, (index) => _buildRoadLine(index)),

        // Wheel patterns
        ...List.generate(8, (index) => _buildWheelPattern(index)),

        // Subtle radial gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                Colors.orange.shade900.withOpacity(0.1),
                Colors.transparent,
                Colors.black.withOpacity(0.1),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusPattern(Color color, double size) {
    return Container(
      width: size,
      height: size * 0.6,
      child: CustomPaint(painter: BusPainter(color)),
    );
  }

  Widget _buildRoadLine(int index) {
    final positions = [
      const Alignment(-1.2, -0.8),
      const Alignment(-0.8, 0.2),
      const Alignment(0.9, -0.5),
      const Alignment(1.1, 0.7),
      const Alignment(-1.0, 0.9),
      const Alignment(0.7, 0.1),
    ];

    final angles = [0.3, -0.2, 0.4, -0.3, 0.1, -0.4];
    final lengths = [60.0, 80.0, 70.0, 90.0, 50.0, 75.0];

    return Align(
      alignment: positions[index % positions.length],
      child: Transform.rotate(
        angle: angles[index % angles.length],
        child: Container(
          width: lengths[index % lengths.length],
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.orange.withOpacity(0.08),
                Colors.orange.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildWheelPattern(int index) {
    final positions = [
      const Alignment(-0.9, -0.7),
      const Alignment(0.8, -0.3),
      const Alignment(-0.7, 0.4),
      const Alignment(0.9, 0.8),
      const Alignment(-0.8, 0.9),
      const Alignment(0.6, -0.9),
      const Alignment(-0.4, -0.8),
      const Alignment(0.7, 0.3),
    ];

    final sizes = [12.0, 16.0, 10.0, 14.0, 11.0, 18.0, 9.0, 13.0];

    return Align(
      alignment: positions[index % positions.length],
      child: Container(
        width: sizes[index % sizes.length],
        height: sizes[index % sizes.length],
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.orange.withOpacity(0.06),
            width: 1.5,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.03),
          ),
        ),
      ),
    );
  }
}

class BusPainter extends CustomPainter {
  final Color color;

  BusPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Bus body outline
    final busBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.5,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(busBody, paint);
    canvas.drawRRect(busBody, fillPaint);

    // Windows
    final window1 = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.25,
      size.width * 0.15,
      size.height * 0.2,
    );
    final window2 = Rect.fromLTWH(
      size.width * 0.35,
      size.height * 0.25,
      size.width * 0.15,
      size.height * 0.2,
    );
    final window3 = Rect.fromLTWH(
      size.width * 0.55,
      size.height * 0.25,
      size.width * 0.15,
      size.height * 0.2,
    );

    canvas.drawRect(window1, paint);
    canvas.drawRect(window2, paint);
    canvas.drawRect(window3, paint);

    // Wheels
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.8),
      size.height * 0.1,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.8),
      size.height * 0.1,
      paint,
    );

    // Door
    final door = Rect.fromLTWH(
      size.width * 0.75,
      size.height * 0.35,
      size.width * 0.1,
      size.height * 0.35,
    );
    canvas.drawRect(door, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
