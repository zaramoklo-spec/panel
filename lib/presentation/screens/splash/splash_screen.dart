import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../main/main_screen.dart';
import '../devices/device_detail_screen.dart';
import '../tools/leak_lookup_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../core/utils/popup_helper.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late AnimationController _glitchController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      ApiService().init();
      final isServerHealthy = await ApiService().checkHealth();

      if (!isServerHealthy) {
        if (mounted) {
          _showErrorDialog('Connection Error', 'Unable to connect to server');
        }
        return;
      }

      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.initialize();
        await authProvider.checkAuthStatus();
      }

      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        final authProvider = context.read<AuthProvider>();

        if (kIsWeb) {
          final hash = getWindowHash();
          if (hash != null) {
            // Handle device route (in popup or new tab)
            if (hash.startsWith('#/device/')) {
              final deviceId = hash.substring('#/device/'.length);
              if (authProvider.isAuthenticated && deviceId.isNotEmpty) {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        DeviceDetailScreen.fromDeviceId(deviceId),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
                return;
              }
            }
            // Handle leak lookup route (in popup or new tab)
            if (hash.startsWith('#/leak-lookup')) {
              if (authProvider.isAuthenticated) {
                // Extract query parameter from hash
                String? query;
                if (hash.contains('?')) {
                  try {
                    final parts = hash.split('?');
                    if (parts.length > 1) {
                      final params = Uri.splitQueryString(parts[1]);
                      query = params['query'];
                    }
                  } catch (e) {
                    // Ignore parsing errors
                  }
                }
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        LeakLookupScreen(initialQuery: query),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
                return;
              }
            }
          }
        }

        if (authProvider.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Initialization Error', 'Failed to start application');
      }
    }
  }


  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1F2E), Color(0xFF0F1419)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF006E).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF006E).withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF006E), Color(0xFFFF5E78)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF006E).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F5FF), Color(0xFF0077FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _initializeApp();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Text(
                        'RETRY CONNECTION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
         decoration: const BoxDecoration(
           gradient: LinearGradient(
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
             colors: [
               Color(0xFF0B0F19),
               Color(0xFF1A1F2E),
               Color(0xFF111827),
             ],
             stops: [0.0, 0.6, 1.0],
           ),
         ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(20, (index) {
              return AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  final angle = (_orbitController.value * 2 * math.pi) + 
                               (index * 2 * math.pi / 20);
                  final radius = 150.0 + (index * 15);
                  final x = MediaQuery.of(context).size.width / 2 + 
                           math.cos(angle) * radius;
                  final y = MediaQuery.of(context).size.height / 2 + 
                           math.sin(angle) * radius;
                  
                  return Positioned(
                    left: x,
                    top: y,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5FF).withOpacity(0.6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F5FF).withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),

            // Glowing orbs
            Positioned(
              top: -100,
              right: -50,
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFFFF006E).withOpacity(0.15 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Positioned(
              bottom: -120,
              left: -80,
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF00F5FF).withOpacity(0.15 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: child,
                    );
                  },
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo container
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 220 + (_pulseController.value * 20),
                                  height: 220 + (_pulseController.value * 20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF00F5FF)
                                          .withOpacity(0.3 * (1 - _pulseController.value)),
                                      width: 3,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            // Middle ring
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00F5FF).withOpacity(0.1),
                                    const Color(0xFFFF006E).withOpacity(0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                            ),

                            // Center logo
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1E2538),
                                    Color(0xFF0F1419),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF00F5FF).withOpacity(0.5),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F5FF).withOpacity(0.3),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _glitchController,
                                builder: (context, child) {
                                  final glitchOffset = (_glitchController.value * 100).floor() % 10 == 0
                                      ? 2.0
                                      : 0.0;
                                  return Transform.translate(
                                    offset: Offset(glitchOffset, 0),
                                    child: Center(
                                      child: ShaderMask(
                                        shaderCallback: (bounds) {
                                          return const LinearGradient(
                                            colors: [
                                              Color(0xFF00F5FF),
                                              Color(0xFFFF006E),
                                              Color(0xFF00F5FF),
                                            ],
                                          ).createShader(bounds);
                                        },
                                        child: const Text(
                                          'Z',
                                          style: TextStyle(
                                            fontSize: 85,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Title with glitch effect
                        AnimatedBuilder(
                          animation: _glitchController,
                          builder: (context, child) {
                            final glitchOffset = (_glitchController.value * 100).floor() % 15 == 0
                                ? 1.5
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(glitchOffset, 0),
                              child: ShaderMask(
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xFF00F5FF),
                                      Color(0xFFFFFFFF),
                                      Color(0xFFFF006E),
                                    ],
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'ZERODAY',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 6,
                                    height: 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF00F5FF).withOpacity(0.25),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'ADVANCED CONTROL PANEL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00F5FF),
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 44),

                        // Loading animation
                        Stack(
                           alignment: Alignment.center,
                           children: [
                             SizedBox(
                               width: 52,
                               height: 52,
                               child: AnimatedBuilder(
                                 animation: _orbitController,
                                 builder: (context, child) {
                                   return CustomPaint(
                                     painter: HexagonLoadingPainter(
                                       progress: _orbitController.value,
                                     ),
                                   );
                                 },
                               ),
                             ),
                             const Icon(
                               Icons.lock_outline_rounded,
                               color: Color(0xFF00F5FF),
                               size: 22,
                             ),
                           ],
                         ),

                         const SizedBox(height: 18),

                         // Loading text
                         AnimatedBuilder(
                           animation: _orbitController,
                           builder: (context, child) {
                             final dots = '.' * ((_orbitController.value * 3).floor() + 1);
                             return Text(
                               'Initializing systems$dots',
                               style: TextStyle(
                                 fontSize: 10,
                                 fontWeight: FontWeight.w600,
                                 color: Colors.white.withOpacity(0.75),
                                 letterSpacing: 1.2,
                               ),
                             );
                           },
                         ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top status bar
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withOpacity(0.9),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Secure connection active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom version
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Column(
                  children: [
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'MILITARY GRADE ENCRYPTION',
                      style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
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

// Custom painter for hexagon loading animation
class HexagonLoadingPainter extends CustomPainter {
  final double progress;

  HexagonLoadingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw hexagon segments
    for (int i = 0; i < 6; i++) {
      final startAngle = (i * math.pi / 3) - math.pi / 2;
      final endAngle = ((i + 1) * math.pi / 3) - math.pi / 2;
      
      final startPoint = Offset(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      
      final endPoint = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      // Calculate if this segment should be highlighted
      final segmentProgress = (progress * 6) % 6;
      final isActive = segmentProgress >= i && segmentProgress < i + 1;

      paint.color = isActive
          ? const Color(0xFF00F5FF)
          : const Color(0xFF00F5FF).withOpacity(0.2);

      if (isActive) {
        paint.shader = LinearGradient(
          colors: [
            const Color(0xFF00F5FF),
            const Color(0xFFFF006E),
          ],
        ).createShader(Rect.fromPoints(startPoint, endPoint));
      } else {
        paint.shader = null;
      }

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(HexagonLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}