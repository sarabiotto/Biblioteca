import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'destress_screen.dart';
import 'focus_screen.dart';
import 'menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.homeBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PULSEBIO',
                        style: TextStyle(
                          color: AppTheme.homePrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bem-vindo',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MenuScreen()),
                    ),
                    icon: const Icon(Icons.menu_rounded,
                        color: AppTheme.textSecondary, size: 28),
                  ),
                ],
              ),
            ),

            // Animação central
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge(
                      [_pulseAnimation, _rotateController]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Anel externo girando
                        Transform.rotate(
                          angle: _rotateController.value * 2 * math.pi,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.homePrimary.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: CustomPaint(
                              painter: _DotRingPainter(
                                  color: AppTheme.homePrimary),
                            ),
                          ),
                        ),
                        // Círculo pulsante
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.homeAccent.withOpacity(0.08),
                              border: Border.all(
                                color: AppTheme.homePrimary.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Centro
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.homeAccent.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.self_improvement_rounded,
                            color: AppTheme.homePrimary,
                            size: 44,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Subtítulo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Restaure seu equilíbrio através da respiração, som e movimento',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),

            const SizedBox(height: 40),

            // Botões principais
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _ModuleButton(
                    label: 'Desestressar',
                    subtitle: 'Acalmar · Nervo Vago · Cortisol',
                    icon: Icons.waves_rounded,
                    color: AppTheme.destressPrimary,
                    backgroundColor: AppTheme.destressCircle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DestressScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ModuleButton(
                    label: 'Foco e Memória',
                    subtitle: 'Concentração · Estudo · Prova',
                    icon: Icons.psychology_rounded,
                    color: AppTheme.focusPrimary,
                    backgroundColor: AppTheme.focusCircle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FocusScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ModuleButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ModuleButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.6), size: 16),
          ],
        ),
      ),
    );
  }
}

class _DotRingPainter extends CustomPainter {
  final Color color;
  _DotRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const dots = 24;

    for (int i = 0; i < dots; i++) {
      final angle = (i / dots) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_DotRingPainter old) => false;
}