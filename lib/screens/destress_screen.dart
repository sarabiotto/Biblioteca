import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

enum BreathPhase { idle, inhale, hold, exhale }

class DestressScreen extends StatefulWidget {
  const DestressScreen({super.key});

  @override
  State<DestressScreen> createState() => _DestressScreenState();
}

class _DestressScreenState extends State<DestressScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _colorController;
  late AnimationController _rotateController;
  late Animation<double> _circleScale;
  late Animation<Color?> _bgColor;
  late Animation<Color?> _circleColor;

  // Áudio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioOn = true;

  BreathPhase _phase = BreathPhase.idle;
  bool _isRunning = false;
  int _countdown = 0;
  int _cycleCount = 0;

  final int _inhaleSeconds = 4;
  final int _holdSeconds = 7;
  final int _exhaleSeconds = 8;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _circleScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _bgColor = ColorTween(
      begin: AppTheme.destressBackground,
      end: const Color(0xFF0A2030),
    ).animate(_colorController);

    _circleColor = ColorTween(
      begin: AppTheme.destressPrimary,
      end: AppTheme.destressAccent,
    ).animate(_colorController);

    // Configurar áudio em loop
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(0.4);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _colorController.dispose();
    _rotateController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── ÁUDIO ───────────────────────────────────────

  Future<void> _startAudio() async {
    if (!_audioOn) return;
    try {
      debugPrint('Tentando tocar áudio...');
      await _audioPlayer.setSource(AssetSource('audio/destress_binaural.mp3'));
      debugPrint('Source definido, iniciando...');
      await _audioPlayer.resume();
      debugPrint('Áudio iniciado!');
    } catch (e) {
      debugPrint('Erro de áudio: $e');
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  void _toggleAudio() async {
    setState(() => _audioOn = !_audioOn);
    if (_audioOn && _isRunning) {
      _startAudio();
    } else {
      _stopAudio();
    }
  }

  // ── VIBRAÇÃO ────────────────────────────────────

  Future<void> _vibrateInhale() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    Vibration.vibrate(
      pattern: [0, 200, 100, 200, 100, 200],
      intensities: [0, 80, 0, 100, 0, 128],
    );
  }

  Future<void> _vibrateHold() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    Vibration.vibrate(pattern: [0, 100], intensities: [0, 60]);
  }

  Future<void> _vibrateExhale() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    Vibration.vibrate(
      pattern: [0, 400, 200, 300, 200, 200],
      intensities: [0, 180, 0, 120, 0, 60],
    );
  }

  // ── RESPIRAÇÃO ──────────────────────────────────

  void _startSession() {
    setState(() {
      _isRunning = true;
      _cycleCount = 0;
    });
    _startAudio();
    _runInhale();
  }

  void _stopSession() {
    _breathController.stop();
    _colorController.stop();
    Vibration.cancel();
    _stopAudio();
    setState(() {
      _isRunning = false;
      _phase = BreathPhase.idle;
      _countdown = 0;
    });
    _breathController.reset();
    _colorController.reverse();
  }

  Future<void> _runInhale() async {
    if (!_isRunning || !mounted) return;
    setState(() {
      _phase = BreathPhase.inhale;
      _countdown = _inhaleSeconds;
    });
    _breathController.duration = Duration(seconds: _inhaleSeconds);
    _colorController.duration = Duration(seconds: _inhaleSeconds);
    _breathController.forward(from: 0);
    _colorController.forward(from: 0);
    _vibrateInhale();
    for (int i = _inhaleSeconds; i > 0; i--) {
      if (!_isRunning || !mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (_isRunning && mounted) _runHold();
  }

  Future<void> _runHold() async {
    if (!_isRunning || !mounted) return;
    setState(() {
      _phase = BreathPhase.hold;
      _countdown = _holdSeconds;
    });
    _breathController.stop();
    for (int i = _holdSeconds; i > 0; i--) {
      if (!_isRunning || !mounted) return;
      setState(() => _countdown = i);
      if (i % 2 == 0) _vibrateHold();
      await Future.delayed(const Duration(seconds: 1));
    }
    if (_isRunning && mounted) _runExhale();
  }

  Future<void> _runExhale() async {
    if (!_isRunning || !mounted) return;
    setState(() {
      _phase = BreathPhase.exhale;
      _countdown = _exhaleSeconds;
    });
    _breathController.duration = Duration(seconds: _exhaleSeconds);
    _colorController.duration = Duration(seconds: _exhaleSeconds);
    _breathController.reverse();
    _colorController.reverse();
    _vibrateExhale();
    for (int i = _exhaleSeconds; i > 0; i--) {
      if (!_isRunning || !mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (_isRunning && mounted) {
      setState(() => _cycleCount++);
      _runInhale();
    }
  }

  // ── HELPERS ─────────────────────────────────────

  String get _phaseLabel {
    switch (_phase) {
      case BreathPhase.inhale:
        return 'Inspire';
      case BreathPhase.hold:
        return 'Segure';
      case BreathPhase.exhale:
        return 'Expire';
      case BreathPhase.idle:
        return 'Pronto para começar';
    }
  }

  String get _phaseInstruction {
    switch (_phase) {
      case BreathPhase.inhale:
        return 'Respire fundo pelo nariz\nlentamente';
      case BreathPhase.hold:
        return 'Segure o ar\ncompletamente imóvel';
      case BreathPhase.exhale:
        return 'Solte o ar pela boca\nbem devagar';
      case BreathPhase.idle:
        return 'Use fones de ouvido\npara o efeito binaural completo';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case BreathPhase.inhale:
        return AppTheme.destressPrimary;
      case BreathPhase.hold:
        return const Color(0xFF80DEEA);
      case BreathPhase.exhale:
        return AppTheme.destressAccent;
      case BreathPhase.idle:
        return AppTheme.destressPrimary.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgColor,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _bgColor.value ?? AppTheme.destressBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          _stopSession();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppTheme.destressPrimary,
                        ),
                      ),
                      const Text(
                        'DESESTRESSAR',
                        style: TextStyle(
                          color: AppTheme.destressPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                      // Botão de áudio
                      IconButton(
                        onPressed: _toggleAudio,
                        icon: Icon(
                          _audioOn
                              ? Icons.headphones_rounded
                              : Icons.headphones_outlined,
                          color: _audioOn
                              ? AppTheme.destressPrimary
                              : AppTheme.destressPrimary.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtítulo
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Técnica 4 · 7 · 8',
                        style: TextStyle(
                          color: AppTheme.destressPrimary.withOpacity(0.6),
                          fontSize: 13,
                          letterSpacing: 3,
                        ),
                      ),
                      if (_isRunning) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.destressPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_cycleCount ciclos',
                            style: const TextStyle(
                              color: AppTheme.destressPrimary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Animação
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _circleScale,
                        _circleColor,
                        _rotateController,
                      ]),
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: _rotateController.value * 2 * math.pi,
                              child: Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (_circleColor.value ??
                                                AppTheme.destressPrimary)
                                            .withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: CustomPaint(
                                  painter: _RingDotsPainter(
                                    color:
                                        _circleColor.value ??
                                        AppTheme.destressPrimary,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _phase == BreathPhase.idle
                                  ? 0.7
                                  : _circleScale.value,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      (_circleColor.value ??
                                              AppTheme.destressPrimary)
                                          .withOpacity(0.08),
                                  border: Border.all(
                                    color:
                                        (_circleColor.value ??
                                                AppTheme.destressPrimary)
                                            .withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _phase == BreathPhase.idle
                                  ? 0.7
                                  : _circleScale.value * 0.65,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      (_circleColor.value ??
                                              AppTheme.destressPrimary)
                                          .withOpacity(0.12),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_phase != BreathPhase.idle)
                                  Text(
                                    '$_countdown',
                                    style: TextStyle(
                                      color:
                                          _circleColor.value ??
                                          AppTheme.destressPrimary,
                                      fontSize: 52,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                if (_phase == BreathPhase.idle)
                                  Icon(
                                    Icons.self_improvement_rounded,
                                    color: AppTheme.destressPrimary.withOpacity(
                                      0.6,
                                    ),
                                    size: 48,
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _phaseLabel,
                    key: ValueKey(_phase),
                    style: TextStyle(
                      color: _phaseColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _phaseInstruction,
                    key: ValueKey(_phase),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                if (_isRunning)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PhaseIndicator(
                          label: '4',
                          sublabel: 'Inspire',
                          isActive: _phase == BreathPhase.inhale,
                          color: AppTheme.destressPrimary,
                        ),
                        _PhaseLine(isActive: _phase != BreathPhase.idle),
                        _PhaseIndicator(
                          label: '7',
                          sublabel: 'Segure',
                          isActive: _phase == BreathPhase.hold,
                          color: const Color(0xFF80DEEA),
                        ),
                        _PhaseLine(isActive: _phase == BreathPhase.exhale),
                        _PhaseIndicator(
                          label: '8',
                          sublabel: 'Expire',
                          isActive: _phase == BreathPhase.exhale,
                          color: AppTheme.destressAccent,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _isRunning ? _stopSession : _startSession,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 180,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isRunning
                          ? Colors.transparent
                          : AppTheme.destressPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _isRunning
                            ? AppTheme.destressPrimary.withOpacity(0.3)
                            : AppTheme.destressPrimary,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _isRunning ? 'Pausar' : 'Iniciar',
                        style: const TextStyle(
                          color: AppTheme.destressPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isActive;
  final Color color;

  const _PhaseIndicator({
    required this.label,
    required this.sublabel,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? color : color.withOpacity(0.4),
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sublabel,
          style: TextStyle(
            color: isActive ? color : AppTheme.textSecondary.withOpacity(0.4),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _PhaseLine extends StatelessWidget {
  final bool isActive;
  const _PhaseLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 1,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive
            ? AppTheme.destressPrimary.withOpacity(0.4)
            : AppTheme.destressPrimary.withOpacity(0.1),
      ),
    );
  }
}

class _RingDotsPainter extends CustomPainter {
  final Color color;
  _RingDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const dots = 32;

    for (int i = 0; i < dots; i++) {
      final angle = (i / dots) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 3 : 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_RingDotsPainter old) => old.color != color;
}
