import 'dart:math' as math;
import 'authScreen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();

    // Controls the movement of the waves.
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Controls the movement of the bubbles.
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // We will connect this to Login once the Login screen is created.
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      // Login navigation will be added here.
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
      );
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2148B9),
              Color(0xFF1769F5),
              Color(0xFF3B82F6),
            ],
          ),
        ),
        child: Stack(
          children: [
            

            _buildBubble(
              left: 45,
              top: 120,
              size: 5,
              opacity: 0.7,
            ),

            _buildBubble(
              left: 120,
              top: 170,
              size: 4,
              opacity: 0.6,
            ),

            _buildBubble(
              right: 90,
              top: 145,
              size: 7,
              opacity: 0.5,
            ),

            _buildBubble(
              left: 80,
              top: 250,
              size: 8,
              opacity: 0.6,
            ),

            _buildBubble(
              right: 105,
              top: 300,
              size: 6,
              opacity: 0.5,
            ),

            _buildBubble(
              left: 155,
              top: 365,
              size: 9,
              opacity: 0.55,
            ),

            _buildBubble(
              right: 50,
              top: 400,
              size: 8,
              opacity: 0.5,
            ),

            

            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                   

                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),


                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.asset(
                            'assets/images/tasksurfLogo.jpg',
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                   

                    const Text(
                      'TaskSurf',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 5),

                    

                    const Text(
                      'Ride the wave to your next task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

           

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return SizedBox(
                    height: 100,
                    child: CustomPaint(
                      painter: SplashWavePainter(
                        animationValue: _waveController.value,
                      ),
                    ),
                  );
                },
              ),
            ),

           

            Positioned(
              bottom: 43,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _indicator(true),
                  const SizedBox(width: 8),
                  _indicator(false),
                  const SizedBox(width: 8),
                  _indicator(false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildBubble({
    double? left,
    double? right,
    required double top,
    required double size,
    required double opacity,
  }) {
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, child) {
        final movement =
            math.sin(_bubbleController.value * math.pi) * 8;

        return Positioned(
          left: left,
          right: right,
          top: top + movement,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }

 

  Widget _indicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 9 : 7,
      height: active ? 9 : 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? Colors.white
            : Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}



class SplashWavePainter extends CustomPainter {
  final double animationValue;

  SplashWavePainter({
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Back wave
    _drawWave(
      canvas,
      size,
      offset: 0,
      height: 50,
      opacity: 0.15,
    );

    // Middle wave
    _drawWave(
      canvas,
      size,
      offset: math.pi,
      height: 35,
      opacity: 0.20,
    );

    // Front wave
    _drawWave(
      canvas,
      size,
      offset: math.pi * 0.5,
      height: 20,
      opacity: 0.25,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double offset,
    required double height,
    required double opacity,
  }) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;

      final wave = math.sin(
        normalizedX * math.pi * 2 +
            animationValue * math.pi * 2 +
            offset,
      );

      final y = size.height - 35 + wave * height;

      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SplashWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}