import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

enum FocusPhase { idle, inhale, hold1, exhale, hold2 }

enum FocusMode { breathing, pomodoro }

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  // Animações
  late AnimationController _breathController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _circleScale;
  late Animation<double> _pulseAnim;

  // Áudio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioOn = true;
  bool _carregandoAudio = false;
  bool _usandoPython = false;

  // Estado respiração
  FocusPhase _phase = FocusPhase.idle;
  bool _isBreathing = false;
  int _countdown = 0;
  int _cycleCount = 0;

  // Estado Pomodoro
  FocusMode _mode = FocusMode.breathing;
  bool _pomodoroRunning = false;
  bool _isPomodoroBreak = false;
  int _pomodoroSeconds = 25 * 60;
  int _pomodoroRound = 1;
  Timer? _pomodoroTimer;

  // Box Breathing: 4-4-4-4
  final int _boxSeconds = 4;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _circleScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(0.4);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  // ── ÁUDIO ───────────────────────────────────────

  Future<void> _startAudio() async {
    if (!_audioOn) return;
    setState(() => _carregandoAudio = true);
    try {
      final servidorOnline = await ApiService.verificarServidor();
      if (servidorOnline) {
        final caminho = await ApiService.baixarBinauralFoco(duracao: 300);
        if (caminho != null && mounted) {
          await _audioPlayer.play(DeviceFileSource(caminho));
          setState(() => _usandoPython = true);
          return;
        }
      }
      await _audioPlayer.play(AssetSource('audio/focus_binaural.mp3'));
      if (mounted) setState(() => _usandoPython = false);
    } catch (e) {
      try {
        await _audioPlayer.play(AssetSource('audio/focus_binaural.mp3'));
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _carregandoAudio = false);
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) setState(() => _usandoPython = false);
  }

  void _toggleAudio() {
    setState(() => _audioOn = !_audioOn);
    if (_audioOn && _isBreathing) {
      _startAudio();
    } else {
      _stopAudio();
    }
  }

  // ── VIBRAÇÃO ────────────────────────────────────

  Future<void> _vibrateInhale() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    Vibration.vibrate(pattern: [0, 150, 80, 150], intensities: [0, 80, 0, 120]);
  }

  Future<void> _vibrateHold() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    Vibration.vibrate(pattern: [0, 80], intensities: [0, 60]);
  }

  Future<void> _vibrateExhale() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    Vibration.vibrate(
      pattern: [0, 300, 100, 200],
      intensities: [0, 160, 0, 80],
    );
  }

  // ── RESPIRAÇÃO BOX ──────────────────────────────

  void _startBreathing() {
    setState(() {
      _isBreathing = true;
      _cycleCount = 0;
    });
    _startAudio();
    _runBoxInhale();
  }

  void _stopBreathing() {
    _breathController.stop();
    _breathController.reset();
    Vibration.cancel();
    _stopAudio();
    setState(() {
      _isBreathing = false;
      _phase = FocusPhase.idle;
      _countdown = 0;
    });
  }

  Future<void> _runBoxInhale() async {
    if (!_isBreathing || !mounted) return;
    setState(() {
      _phase = FocusPhase.inhale;
      _countdown = _boxSeconds;
    });
    _breathController.duration = Duration(seconds: _boxSeconds);
    _breathController.forward(from: 0);
    _vibrateInhale();
    for (int i = _boxSeconds; i > 0; i--) {
      if (!_isBreathing || !mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (_isBreathing && mounted) _runBoxHold1();
  }

  Future<void> _runBoxHold1() async {
    if (!_isBreathing || !mounted) return;
    setState(() {
      _phase = FocusPhase.hold1;
      _countdown = _boxSeconds;
    });
    _breathController.stop();
    _vibrateHold();
    for (int i = _boxSeconds; i > 0; i--) {
      if (!_isBreathing || !mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (_isBreathing && mounted) _runBoxExhale();
  }

  Future<void> _runBoxExhale() async {
    if (!_isBreathing || !mounted) return;
    setState(() {
      _phase = FocusPhase.exhale;
      _countdown = _boxSeconds;
    });
    _breathController.duration = Duration(seconds: _boxSeconds);
    _breathController.reverse();
    _vibrateExhale();
    for (int i = _boxSeconds; i > 0; i--) {
      if (!_isBreathing || !mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (_isBreathing && mounted) _runBoxHold2();
  }

  Future<void> _runBoxHold2() async {
    if (!_isBreathing || !mounted) return;
    setState(() {
      _phase = FocusPhase.hold2;
      _countdown = _boxSeconds;
    });
    _breathController.stop();
    _vibrateHold();
    for (int i = _boxSeconds; i > 0; i--) {
      if (!_isBreathing || !mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (_isBreathing && mounted) {
      setState(() => _cycleCount++);
      _runBoxInhale();
    }
  }

  // ── POMODORO ────────────────────────────────────

  void _startPomodoro() {
    setState(() {
      _pomodoroRunning = true;
      _isPomodoroBreak = false;
      _pomodoroSeconds = 25 * 60;
    });
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_pomodoroSeconds > 0) {
          _pomodoroSeconds--;
        } else {
          if (!_isPomodoroBreak) {
            _isPomodoroBreak = true;
            _pomodoroSeconds = 5 * 60;
            HapticFeedback.heavyImpact();
            Vibration.vibrate(duration: 800);
          } else {
            _isPomodoroBreak = false;
            _pomodoroRound++;
            _pomodoroSeconds = 25 * 60;
            HapticFeedback.heavyImpact();
            Vibration.vibrate(duration: 800);
          }
        }
      });
    });
  }

  void _stopPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _pomodoroRunning = false;
      _pomodoroSeconds = 25 * 60;
      _isPomodoroBreak = false;
    });
  }

  String get _pomodoroLabel {
    final min = (_pomodoroSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_pomodoroSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  double get _pomodoroProgress {
    final total = _isPomodoroBreak ? 5 * 60 : 25 * 60;
    return 1 - (_pomodoroSeconds / total);
  }

  // ── HELPERS ─────────────────────────────────────

  String get _phaseLabel {
    switch (_phase) {
      case FocusPhase.inhale:
        return 'Inspire';
      case FocusPhase.hold1:
        return 'Segure';
      case FocusPhase.exhale:
        return 'Expire';
      case FocusPhase.hold2:
        return 'Segure';
      case FocusPhase.idle:
        return 'Pronto para focar';
    }
  }

  String get _phaseInstruction {
    switch (_phase) {
      case FocusPhase.inhale:
        return 'Inspire pelo nariz\nenchendo o abdômen';
      case FocusPhase.hold1:
        return 'Segure o ar\nmantendo a tensão';
      case FocusPhase.exhale:
        return 'Expire pela boca\nesvaziando completamente';
      case FocusPhase.hold2:
        return 'Segure vazio\nprepare para o próximo ciclo';
      case FocusPhase.idle:
        return 'Box Breathing ativa o\ncórtex pré-frontal';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case FocusPhase.inhale:
        return AppTheme.focusPrimary;
      case FocusPhase.hold1:
      case FocusPhase.hold2:
        return const Color(0xFFFFD54F);
      case FocusPhase.exhale:
        return AppTheme.focusAccent;
      case FocusPhase.idle:
        return AppTheme.focusPrimary.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.focusBackground,
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
                      _stopBreathing();
                      _stopPomodoro();
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppTheme.focusPrimary,
                    ),
                  ),
                  const Text(
                    'FOCO E MEMÓRIA',
                    style: TextStyle(
                      color: AppTheme.focusPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleAudio,
                    icon: Icon(
                      _audioOn
                          ? Icons.headphones_rounded
                          : Icons.headphones_outlined,
                      color: _audioOn
                          ? AppTheme.focusPrimary
                          : AppTheme.focusPrimary.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Respiração',
                    isActive: _mode == FocusMode.breathing,
                    color: AppTheme.focusPrimary,
                    onTap: () => setState(() => _mode = FocusMode.breathing),
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Pomodoro',
                    isActive: _mode == FocusMode.pomodoro,
                    color: AppTheme.focusPrimary,
                    onTap: () => setState(() => _mode = FocusMode.pomodoro),
                  ),
                  if (_isBreathing && !_carregandoAudio) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (_usandoPython
                                    ? Colors.greenAccent
                                    : AppTheme.focusPrimary)
                                .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _usandoPython ? '🐍 puro' : '📱 local',
                        style: TextStyle(
                          color: _usandoPython
                              ? Colors.greenAccent
                              : AppTheme.focusPrimary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: _mode == FocusMode.breathing
                  ? _buildBreathing()
                  : _buildPomodoro(),
            ),
          ],
        ),
      ),
    );
  }

  // ── TELA RESPIRAÇÃO ─────────────────────────────

  Widget _buildBreathing() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Box Breathing · 4 · 4 · 4 · 4',
            style: TextStyle(
              color: AppTheme.focusPrimary.withOpacity(0.6),
              fontSize: 13,
              letterSpacing: 3,
            ),
          ),
        ),

        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _circleScale,
                _rotateController,
                _pulseAnim,
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
                            color: AppTheme.focusPrimary.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _FocusRingPainter(
                            color: AppTheme.focusPrimary,
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _phase == FocusPhase.idle
                          ? _pulseAnim.value * 0.7
                          : _circleScale.value,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _phaseColor.withOpacity(0.07),
                          border: Border.all(
                            color: _phaseColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _phase == FocusPhase.idle
                          ? _pulseAnim.value * 0.45
                          : _circleScale.value * 0.65,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _phaseColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_phase != FocusPhase.idle)
                          Text(
                            '$_countdown',
                            style: TextStyle(
                              color: _phaseColor,
                              fontSize: 52,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        if (_phase == FocusPhase.idle)
                          Icon(
                            Icons.psychology_rounded,
                            color: AppTheme.focusPrimary.withOpacity(0.6),
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
          duration: const Duration(milliseconds: 400),
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

        const SizedBox(height: 10),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
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

        const SizedBox(height: 24),

        if (_isBreathing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BoxPhaseIndicator(
                  label: '4',
                  sublabel: 'Inspire',
                  isActive: _phase == FocusPhase.inhale,
                  color: AppTheme.focusPrimary,
                ),
                _BoxLine(isActive: _phase != FocusPhase.idle),
                _BoxPhaseIndicator(
                  label: '4',
                  sublabel: 'Segure',
                  isActive: _phase == FocusPhase.hold1,
                  color: const Color(0xFFFFD54F),
                ),
                _BoxLine(
                  isActive:
                      _phase == FocusPhase.exhale || _phase == FocusPhase.hold2,
                ),
                _BoxPhaseIndicator(
                  label: '4',
                  sublabel: 'Expire',
                  isActive: _phase == FocusPhase.exhale,
                  color: AppTheme.focusAccent,
                ),
                _BoxLine(isActive: _phase == FocusPhase.hold2),
                _BoxPhaseIndicator(
                  label: '4',
                  sublabel: 'Segure',
                  isActive: _phase == FocusPhase.hold2,
                  color: const Color(0xFFFFD54F),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        GestureDetector(
          onTap: _isBreathing ? _stopBreathing : _startBreathing,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 180,
            height: 56,
            decoration: BoxDecoration(
              color: _isBreathing
                  ? Colors.transparent
                  : AppTheme.focusPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _isBreathing
                    ? AppTheme.focusPrimary.withOpacity(0.3)
                    : AppTheme.focusPrimary,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _isBreathing ? 'Pausar' : 'Iniciar',
                style: const TextStyle(
                  color: AppTheme.focusPrimary,
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
    );
  }

  // ── TELA POMODORO ───────────────────────────────

  Widget _buildPomodoro() {
    return Column(
      children: [
        const SizedBox(height: 16),

        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color:
                (_isPomodoroBreak
                        ? AppTheme.destressAccent
                        : AppTheme.focusPrimary)
                    .withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  (_isPomodoroBreak
                          ? AppTheme.destressAccent
                          : AppTheme.focusPrimary)
                      .withOpacity(0.3),
            ),
          ),
          child: Text(
            _isPomodoroBreak ? '☕  Pausa — descanse' : '🎯  Sessão de foco',
            style: TextStyle(
              color: _isPomodoroBreak
                  ? AppTheme.destressAccent
                  : AppTheme.focusPrimary,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),

        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CustomPaint(
                        painter: _PomodoroProgressPainter(
                          progress: _pomodoroProgress,
                          color: _isPomodoroBreak
                              ? AppTheme.destressAccent
                              : AppTheme.focusPrimary,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _pomodoroRunning ? _pulseAnim.value : 1.0,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (_isPomodoroBreak
                                      ? AppTheme.destressAccent
                                      : AppTheme.focusPrimary)
                                  .withOpacity(0.06),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pomodoroLabel,
                          style: TextStyle(
                            color: _isPomodoroBreak
                                ? AppTheme.destressAccent
                                : AppTheme.focusPrimary,
                            fontSize: 48,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isPomodoroBreak ? 'pausa' : 'foco',
                          style: TextStyle(
                            color:
                                (_isPomodoroBreak
                                        ? AppTheme.destressAccent
                                        : AppTheme.focusPrimary)
                                    .withOpacity(0.6),
                            fontSize: 13,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _isPomodoroBreak
                ? 'Levante, alongue, beba água.\nSeu cérebro está consolidando memórias.'
                : 'Elimine distrações.\nFoque em uma tarefa de cada vez.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final done = i < (_pomodoroRound - 1);
            final current = i == (_pomodoroRound - 1);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: done || current
                    ? AppTheme.focusPrimary
                    : AppTheme.focusPrimary.withOpacity(0.2),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        GestureDetector(
          onTap: _pomodoroRunning ? _stopPomodoro : _startPomodoro,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 180,
            height: 56,
            decoration: BoxDecoration(
              color: _pomodoroRunning
                  ? Colors.transparent
                  : AppTheme.focusPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _pomodoroRunning
                    ? AppTheme.focusPrimary.withOpacity(0.3)
                    : AppTheme.focusPrimary,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _pomodoroRunning ? 'Pausar' : 'Iniciar',
                style: const TextStyle(
                  color: AppTheme.focusPrimary,
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
    );
  }
}

// ── WIDGETS AUXILIARES ───────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : color.withOpacity(0.4),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _BoxPhaseIndicator extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isActive;
  final Color color;

  const _BoxPhaseIndicator({
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.25),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? color : color.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          sublabel,
          style: TextStyle(
            color: isActive ? color : AppTheme.textSecondary.withOpacity(0.3),
            fontSize: 9,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _BoxLine extends StatelessWidget {
  final bool isActive;
  const _BoxLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 1,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive
            ? AppTheme.focusPrimary.withOpacity(0.4)
            : AppTheme.focusPrimary.withOpacity(0.1),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  final Color color;
  _FocusRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.35)
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
  bool shouldRepaint(_FocusRingPainter old) => old.color != color;
}

class _PomodoroProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PomodoroProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final trackPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_PomodoroProgressPainter old) =>
      old.progress != progress || old.color != color;
}
