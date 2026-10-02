import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FlutterForgeApp());

class FlutterForgeApp extends StatelessWidget {
  const FlutterForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Forge 2026',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090914),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5C8A),
          brightness: Brightness.dark,
        ),
      ),
      home: const ForgeScreen(),
    );
  }
}

class ForgeScreen extends StatefulWidget {
  const ForgeScreen({super.key});

  @override
  State<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends State<ForgeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _intro;
  late final AnimationController _celebration;
  late final AnimationController _buttonPulse;
  Timer? _timer;
  DateTime? _deadline;
  SharedPreferences? _prefs;
  static const _deadlineKey = 'flutter_forge_deadline_ms';
  static const _startedKey = 'flutter_forge_started';

  Duration _remaining = const Duration(hours: 4);
  bool _started = false;
  bool _opening = false;
  bool _celebrating = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _celebration = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _buttonPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _restoreTimer();
  }

  Future<void> _restoreTimer() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _prefs = prefs;

    final deadlineMs = prefs.getInt(_deadlineKey);
    final wasStarted = prefs.getBool(_startedKey) ?? false;

    if (!wasStarted || deadlineMs == null) return;

    final deadline = DateTime.fromMillisecondsSinceEpoch(deadlineMs);
    final left = deadline.difference(DateTime.now());

    setState(() {
      _started = true;
      _deadline = deadline;
      _remaining = left.isNegative ? Duration.zero : left;
      _finished = left <= Duration.zero;
    });

    if (!_finished) {
      _runCountdown();
    }
  }

  Future<void> _saveTimer(DateTime deadline) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_startedKey, true);
    await prefs.setInt(_deadlineKey, deadline.millisecondsSinceEpoch);
  }

  Future<void> _clearTimer() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.remove(_startedKey);
    await prefs.remove(_deadlineKey);
  }

  void _runCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _deadline == null) return;
      final left = _deadline!.difference(DateTime.now());
      if (left <= Duration.zero) {
        _timer?.cancel();
        setState(() {
          _remaining = Duration.zero;
          _finished = true;
        });
        return;
      }

      final shown = Duration(seconds: left.inSeconds);
      if (shown.inSeconds != _remaining.inSeconds) {
        setState(() => _remaining = shown);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ambient.dispose();
    _intro.dispose();
    _celebration.dispose();
    _buttonPulse.dispose();
    super.dispose();
  }

  void _startForge() async {
    if (_started) return;

    // Start and persist the real deadline immediately when the user presses
    // START. The opening animation is visual only; it must never delay the
    // four-hour challenge clock.
    final deadline = DateTime.now().add(const Duration(hours: 4));
    _deadline = deadline;
    _remaining = const Duration(hours: 4);
    _finished = false;
    await _saveTimer(deadline);
    if (!mounted) return;

    setState(() {
      _started = true;
      _opening = true;
      _celebrating = false;
    });

    _runCountdown();

    _intro.forward(from: 0).whenComplete(() {
      if (!mounted) return;

      setState(() {
        _opening = false;
        _celebrating = true;
      });

      _celebration.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _celebrating = false);
      });
    });
  }

  String _two(int value) => value.toString().padLeft(2, '0');
  String get _hours => _two(_remaining.inHours);
  String get _minutes => _two(_remaining.inMinutes.remainder(60));
  String get _seconds => _two(_remaining.inSeconds.remainder(60));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: _started ? 2.8 : 1.8, sigmaY: _started ? 2.8 : 1.8),
              child: Image.asset(
                'assets/background_campus.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          // Dark cinematic treatment keeps the supplied campus photograph,
          // while creating the deep-blue/purple neon atmosphere of the
          // reference screens.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _started
                      ? const [
                          Color(0x88202E58),
                          Color(0x99301D58),
                          Color(0xB2080A22),
                        ]
                      : const [
                          Color(0xDD05051B),
                          Color(0xCC0A0A2A),
                          Color(0xDD10051F),
                        ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color(0x3307050D)),
          ),
          AnimatedBuilder(
            animation: _ambient,
            builder: (_, __) => CustomPaint(
              painter: AuroraCampusPainter(_ambient.value),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: _started ? 12 : 0),
                if (_started) _header(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, viewport) {
                      final child = AnimatedSwitcher(
                        duration: const Duration(milliseconds: 700),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: .97, end: 1).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _started
                            ? KeyedSubtree(
                                key: const ValueKey('countdown-screen'),
                                child: _buildMainCard(),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('landing-screen'),
                                child: _buildLandingPage(),
                              ),
                      );

                      // IMPORTANT: FittedBox scales the complete composition
                      // before painting it. Transform.scale alone does not
                      // change the child's layout size, which caused the
                      // RenderFlex overflow shown in the browser screenshot.
                      // This keeps the entire page inside the viewport and
                      // prevents any vertical scrollbar/overflow warning.
                      return ClipRect(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_started) ...[
                  const SizedBox(height: 4),
                  _bottomCaption(),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          if (_opening) OpeningOverlay(controller: _intro),
          if (_celebrating) CelebrationOverlay(controller: _celebration),
        ],
      ),
    );
  }

  Widget _buildLandingPage() {
    // Starting page: use only the requested event content.
    // The visual treatment is intentionally different from the reference image.
    return SizedBox(
      width: 1100,
      height: 650,
      child: Center(
        child: Container(
          width: 980,
          height: 560,
          padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 34),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xE80C1738),
                Color(0xE51A1640),
                Color(0xE80B2344),
              ],
            ),
            border: Border.all(color: Color(0x6678D9FF), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 35, spreadRadius: 3),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: 870,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'LAKIREDDY BALI REDDY COLLEGE OF ENGINEERING',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9FEAFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8DA2FF), Color(0xFF25E0FF), Color(0xFFF06DFF)],
                ).createShader(bounds),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'FLUTTER FORGE 2026',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '4-HOUR MOBILE APP DEVELOPMENT HACKATHON',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: Color(0xFFFFD34E),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'Imagine  •  Innovate  •  Code  •  Deploy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Transform Ideas into Innovative Flutter Applications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFD5E5FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                width: 650,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0x331A2D63),
                  border: Border.all(color: const Color(0x6696CFFF)),
                ),
                child: Column(
                  children: const [
                    Text(
                      'INAUGURATED BY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFD34E),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Dr. S. Nagarjuna Reddy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Head of the Department',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF75FFAA),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Department of Computer Science & Engineering',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD5E5FF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _startForge,
                  child: Container(
                    width: 320,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16D9FF), Color(0xFF725CFF), Color(0xFFE84DFF)],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x6634DFFF), blurRadius: 22, spreadRadius: 1),
                      ],
                    ),
                    child: const Text(
                      'START HACKATHON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
                    const Text(
                      'Best Wishes to All Participants • Happy Coding! 🚀',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD5E5FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 92,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xEEFFFFFF),
                border: Border.all(
                  color: const Color(0x66FFFFFF),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x667A5CFF),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/college_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The complete college name is deliberately kept on ONE line.
                  // FittedBox scales the text down only when the browser viewport
                  // becomes narrow, so the name never wraps or causes overflow.
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'LAKIREDDY BALI REDDY COLLEGE OF ENGINEERING',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'MYLAVARAM  •  ESTD 1998',
                    style: TextStyle(
                      color: Color(0xFFD7F7FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1080),
      child: Column(
        children: [
          _brandHero(),
          const SizedBox(height: 18),
          _glassCommandDeck(),
          const SizedBox(height: 18),
          _journeyStrip(),
        ],
      ),
    );
  }

  Widget _brandHero() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (_, __) {
        final pulse = 0.98 + math.sin(_ambient.value * math.pi * 2) * 0.02;
        return Transform.scale(
          scale: pulse,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 700;
                  final logoSize = compact ? 72.0 : 118.0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FlutterLogo(
                        size: logoSize,
                        style: FlutterLogoStyle.markOnly,
                      ),
                      SizedBox(width: compact ? 12 : 22),
                      Flexible(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFF8FD8FF),
                              Color(0xFFFF79C8),
                              Color(0xFF35D8FF),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'FLUTTER\nFORGE 2026',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 42 : 70,
                              height: .9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x554A78FF), Color(0x775F2AFF), Color(0x55FF4F9A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x66FFD166)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x445F7CFF), blurRadius: 22, spreadRadius: -4),
                  ],
                ),
                child: const Text(
                  '〈/〉  4-HOUR FLUTTER HACKATHON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.1,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                'IMAGINE  •  INNOVATE  •  CODE  •  DEPLOY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFF1E7),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.1,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Transform Ideas into Innovative Flutter Applications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFD7F7FF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _glassCommandDeck() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xB525152C),
                Color(0x99181B38),
                Color(0x9932162F),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0x99FF6B8A), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x77FF5C8A), blurRadius: 42, spreadRadius: -10),
              BoxShadow(color: Color(0xAA05050C), blurRadius: 38, offset: Offset(0, 18)),
            ],
          ),
          child: Column(
            children: [
              _countdownBadge(),
              const SizedBox(height: 6),
              Text(
                _finished ? 'TIME IS UP' : 'TIME REMAINING',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 22),
              _countdown(),
              const SizedBox(height: 22),
              _actionButton(),
              const SizedBox(height: 17),
              _progressBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countdownBadge() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (_, __) {
        final glow = 0.55 + (math.sin(_ambient.value * math.pi * 2) + 1) * 0.18;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x553D8BFF), Color(0x775F2AFF), Color(0x66FF4F9A)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Color.fromRGBO(255, 255, 255, .24)),
            boxShadow: [
              BoxShadow(color: Color.fromRGBO(93, 116, 255, glow), blurRadius: 24, spreadRadius: -5),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFFFFD166), size: 18),
              SizedBox(width: 8),
              Text(
                'HACKATHON BEGINS IN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _countdown() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final cardWidth = compact ? 112.0 : 185.0;
        final cardHeight = compact ? 124.0 : 166.0;
        final digitSize = compact ? 48.0 : 72.0;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: compact ? 5 : 10,
          runSpacing: 10,
          children: [
            NormalTimeCard(value: _hours, label: 'HOURS', width: cardWidth, height: cardHeight, digitSize: digitSize),
            _separator(compact),
            NormalTimeCard(value: _minutes, label: 'MINUTES', width: cardWidth, height: cardHeight, digitSize: digitSize),
            _separator(compact),
            NormalTimeCard(value: _seconds, label: 'SECONDS', width: cardWidth, height: cardHeight, digitSize: digitSize),
          ],
        );
      },
    );
  }

  Widget _separator(bool compact) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 40 : 58),
      child: Text(
        ':',
        style: TextStyle(
          color: const Color(0xFFFFD166),
          fontSize: compact ? 38 : 48,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _actionButton() {
    if (_started) {
      return const Text(
        'MAKE IT BOLD. MAKE IT YOURS.',
        style: TextStyle(
          color: Color(0xFFD7F7FF),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.4,
        ),
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _startForge,
        child: AnimatedBuilder(
          animation: _buttonPulse,
          builder: (_, child) {
            final scale = .97 + _buttonPulse.value * .03;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4F86), Color(0xFF7A5CFF), Color(0xFFFFB84D)],
              ),
              border: Border.all(color: Colors.white.withOpacity(.45)),
              boxShadow: const [
                BoxShadow(color: Color(0x88FF5C8A), blurRadius: 28, spreadRadius: 1),
                BoxShadow(color: Color(0x667A5CFF), blurRadius: 45, spreadRadius: -8),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.double_arrow_rounded, size: 25),
                SizedBox(width: 10),
                Text(
                  'START THE 4-HOUR FORGE',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressBar() {
    final progress = 1 - (_remaining.inSeconds / const Duration(hours: 4).inSeconds);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MISSION PROGRESS',
              style: TextStyle(color: Color(0xFFFFD1A8), fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.7),
            ),
            Text(
              '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(height: 7, color: Colors.white.withOpacity(.10)),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 7,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFF5C8A), Color(0xFF7A5CFF), Color(0xFFFFB84D)]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _journeyStrip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xAA171125),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x66FF6B8A)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;
              final children = [
                const JourneyItem(icon: Icons.lightbulb_outline_rounded, title: 'SPARK', subtitle: 'RAW IDEAS'),
                const JourneyConnector(),
                const JourneyItem(icon: Icons.code_rounded, title: 'BUILD', subtitle: 'REAL THINGS'),
                const JourneyConnector(),
                const JourneyItem(icon: Icons.rocket_launch_rounded, title: 'IGNITE', subtitle: 'MAKE NOISE'),
              ];
              return compact
                  ? Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 12, children: children)
                  : Row(children: children);
            },
          ),
        ),
      ),
    );
  }

  Widget _bottomCaption() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'ALL THE BEST TO ALL PARTICIPANTS  •  HAPPY CODING  •  HAPPY BUILDING  •  HAPPY FLUTTER FORGE 2026',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFFFE5B8),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.25,
        ),
      ),
    );
  }
}


class LandingEnergyPainter extends CustomPainter {
  final double t;
  LandingEnergyPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * .70, size.height * .45);
    final pulse = .92 + math.sin(t * math.pi * 2) * .05;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x5535D8FF), Color(0x221F64FF), Color(0x0010162F)],
      ).createShader(Rect.fromCircle(center: c, radius: 300 * pulse));
    canvas.drawCircle(c, 300 * pulse, glow);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x443FD9FF);
    for (int i = 0; i < 4; i++) {
      final rect = Rect.fromCenter(center: c, width: 380 + i * 72.0, height: 220 + i * 48.0);
      canvas.drawOval(rect, ring);
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x225B7CFF);
    for (int i = 0; i < 7; i++) {
      final y = size.height * (.18 + i * .1) + math.sin(t * math.pi * 2 + i) * 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 60), line);
    }

    final particle = Paint()..color = const Color(0xB3B4EFFF);
    for (int i = 0; i < 28; i++) {
      final x = (i * 83.0 + t * 180) % size.width;
      final y = (i * 47.0 + math.sin(t * math.pi * 2 + i) * 22) % size.height;
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 2.0 : 1.0, particle);
    }
  }

  @override
  bool shouldRepaint(covariant LandingEnergyPainter oldDelegate) => oldDelegate.t != t;
}

class AnimatedGradientText extends StatelessWidget {
  const AnimatedGradientText({
    super.key,
    required this.animation,
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.letterSpacing,
  });

  final Animation<double> animation;
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final rotation = animation.value * math.pi * 2;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => SweepGradient(
            colors: const [
              Color(0xFFFFD166),
              Color(0xFFFF6B8A),
              Color(0xFF9C7CFF),
              Color(0xFF69D7FF),
              Color(0xFFFFD166),
            ],
            transform: GradientRotation(rotation),
          ).createShader(bounds),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
            ),
          ),
        );
      },
    );
  }
}

class FlutterBadge extends StatelessWidget {
  final double size;
  const FlutterBadge({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .28),
        gradient: const LinearGradient(colors: [Color(0xFFFF5C8A), Color(0xFF7A5CFF), Color(0xFFFFB84D)]),
        boxShadow: const [BoxShadow(color: Color(0x66FF5C8A), blurRadius: 25)],
      ),
      alignment: Alignment.center,
      child: FlutterLogo(size: size * .67, style: FlutterLogoStyle.markOnly),
    );
  }
}

class HeaderOrbitMark extends StatelessWidget {
  const HeaderOrbitMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 38,
      child: CustomPaint(painter: HeaderOrbitPainter()),
    );
  }
}

class HeaderOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xAAFFB84D);
    final r = Rect.fromCenter(center: size.center(Offset.zero), width: size.width, height: 20);
    canvas.drawArc(r, math.pi * .08, math.pi * .84, false, p);
    p.color = const Color(0x887A5CFF);
    canvas.drawArc(r, math.pi * 1.08, math.pi * .84, false, p);
    canvas.drawCircle(Offset(size.width * .78, size.height * .47), 3, Paint()..color = const Color(0xFFFFD166));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JourneyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const JourneyItem({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFB84D), width: 1.2),
              boxShadow: const [BoxShadow(color: Color(0x55FFB84D), blurRadius: 16)],
            ),
            child: Icon(icon, color: const Color(0xFFFFD166), size: 22),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFFFFE4D0), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFFC8B8C7), fontSize: 8.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JourneyConnector extends StatelessWidget {
  const JourneyConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 54,
      child: Center(
        child: Icon(Icons.arrow_forward_rounded, color: Color(0xFFFF6B8A), size: 19),
      ),
    );
  }
}

class NormalTimeCard extends StatelessWidget {
  final String value;
  final String label;
  final double width;
  final double height;
  final double digitSize;

  const NormalTimeCard({
    super.key,
    required this.value,
    required this.label,
    required this.width,
    required this.height,
    required this.digitSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC1A1025), Color(0xDD10142A), Color(0xCC2B142A)],
        ),
        border: Border.all(color: const Color(0xAAFF6B8A), width: 1.1),
        boxShadow: const [
          BoxShadow(color: Color(0x66FF5C8A), blurRadius: 26, spreadRadius: -3),
          BoxShadow(color: Color(0xAA000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              reverseDuration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .90, end: 1.0).animate(curved),
                    child: child,
                  ),
                );
              },
              child: Text(
                value,
                key: ValueKey(value),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: digitSize,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  shadows: const [
                    Shadow(color: Color(0xCCFF5C8A), blurRadius: 18),
                    Shadow(color: Color(0xFF000000), blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 7,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFD166),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OpeningOverlay extends StatelessWidget {
  final Animation<double> controller;
  const OpeningOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final phase = t < .25 ? 0 : t < .5 ? 1 : t < .75 ? 2 : 3;
        final localStart = phase * .25;
        final local = ((t - localStart) / .25).clamp(0.0, 1.0);

        // The entire interface starts heavily defocused. During 3-2-1 the
        // foreground countdown stays crisp while the LBRCE scene and timer
        // underneath remain blurred. The final part smoothly removes the
        // blur so the real countdown is revealed instead of simply appearing.
        final reveal = Curves.easeInOutCubic.transform(
          ((t - .75) / .25).clamp(0.0, 1.0),
        );
        final blur = 18.0 * (1.0 - reveal);
        final tint = .30 * (1.0 - reveal);

        return Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                color: Color.fromRGBO(3, 12, 28, tint),
              ),
            ),
            if (phase < 3)
              Center(
                child: _OpeningNumber(
                  number: ['3', '2', '1'][phase],
                  progress: local,
                  stage: phase,
                ),
              ),
            if (reveal > .02)
              Align(
                alignment: Alignment.center,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: reveal,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x88FFB84D),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FFB84D),
                            blurRadius: 70,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OpeningNumber extends StatelessWidget {
  final String number;
  final double progress;
  final int stage;

  const _OpeningNumber({required this.number, required this.progress, required this.stage});

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutBack.transform(progress);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('FLUTTER FORGE 2026', style: TextStyle(color: Color(0xFFFFD1A8), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 4)),
        const SizedBox(height: 24),
        Transform.scale(
          scale: .75 + eased * .25,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, .0016)..rotateX((1 - eased) * -math.pi / 2),
            child: Container(
              width: 220,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [Color(0xFF3A1732), Color(0xFF171A3A), Color(0xFF341A2D)]),
                border: Border.all(color: const Color(0xAAFFB84D)),
                boxShadow: const [BoxShadow(color: Color(0x77FF5C8A), blurRadius: 55), BoxShadow(color: Color(0x88000000), blurRadius: 25, offset: Offset(0, 16))],
              ),
              alignment: Alignment.center,
              child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 145, fontWeight: FontWeight.w900, shadows: [Shadow(color: Color(0xCCFFB84D), blurRadius: 24)])),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(stage == 0 ? 'GET READY' : stage == 1 ? 'ALMOST THERE' : 'MAKE SOME NOISE', style: const TextStyle(color: Color(0xFFD9F8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3)),
      ],
    );
  }
}

class _OpeningMessage extends StatelessWidget {
  const _OpeningMessage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FlutterBadge(size: 90),
        const SizedBox(height: 18),
        const Text('THE FORGE IS OPEN', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
        const SizedBox(height: 10),
        const Text('YOUR NEXT BIG BUILD STARTS HERE', style: TextStyle(color: Color(0xFFFFD166), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3)),
      ],
    );
  }
}

class CelebrationOverlay extends StatelessWidget {
  final Animation<double> controller;
  const CelebrationOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final fade = 1 - Curves.easeIn.transform(((controller.value - .42) / .58).clamp(0.0, 1.0));
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: CelebrationPainter(controller.value)),
              Center(
                child: Opacity(
                  opacity: fade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xE8171125),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x88FFB84D)),
                      boxShadow: const [BoxShadow(color: Color(0x66FF5C8A), blurRadius: 50)],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch_rounded, color: Color(0xFFFFB84D), size: 52),
                        SizedBox(height: 8),
                        Text('THE FORGE IS OPEN!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        SizedBox(height: 7),
                        Text('FLUTTER FORGE 2026  •  LBRCE', style: TextStyle(color: Color(0xFFFFD1A8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CelebrationPainter extends CustomPainter {
  final double progress;
  CelebrationPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(2026);
    const colors = [Color(0xFFFF5C8A), Color(0xFF7A5CFF), Color(0xFFFFB84D), Color(0xFFFF8A5C), Color(0xFFFFD166)];
    final paint = Paint();
    for (int i = 0; i < 180; i++) {
      final x = (random.nextDouble() + progress * .12 * (i % 3)) % 1.0;
      final y = (random.nextDouble() + progress * .8) % 1.1 - .05;
      final w = 3.0 + random.nextDouble() * 7;
      final h = 4.0 + random.nextDouble() * 12;
      paint.color = colors[i % colors.length].withOpacity(.8);
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(random.nextDouble() * math.pi * 2 + progress * 8);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(2)), paint);
      canvas.restore();
    }

    final centers = [
      Offset(size.width * .12, size.height * .24),
      Offset(size.width * .88, size.height * .22),
      Offset(size.width * .10, size.height * .78),
      Offset(size.width * .90, size.height * .74),
    ];
    final burst = Curves.easeOut.transform((progress * 1.9).clamp(0.0, 1.0));
    final radius = 8 + burst * 110;
    final alpha = (1 - burst).clamp(0.0, 1.0);
    for (int j = 0; j < centers.length; j++) {
      for (int k = 0; k < 22; k++) {
        final angle = math.pi * 2 * k / 22 + j * .25;
        final end = centers[j] + Offset(math.cos(angle), math.sin(angle)) * radius;
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = colors[(j + k) % colors.length].withOpacity(alpha);
        canvas.drawLine(centers[j], end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CelebrationPainter oldDelegate) => oldDelegate.progress != progress;
}

class AuroraCampusPainter extends CustomPainter {
  final double progress;
  AuroraCampusPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    final rng = math.Random(42026);

    final glows = [
      (Offset(size.width * (.14 + .04 * math.sin(t)), size.height * .22), 300.0, const Color(0x55FF5C8A)),
      (Offset(size.width * (.84 + .05 * math.cos(t * .7)), size.height * .72), 360.0, const Color(0x447A5CFF)),
      (Offset(size.width * (.55 + .08 * math.sin(t * .45)), size.height * .40), 300.0, const Color(0x33FFB84D)),
    ];
    for (final glow in glows) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [glow.$3, glow.$3.withOpacity(0)]).createShader(Rect.fromCircle(center: glow.$1, radius: glow.$2));
      canvas.drawCircle(glow.$1, glow.$2, paint);
    }

    final horizon = size.height * .64;
    final grid = Paint()
      ..color = const Color(0x22FF6B8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = -11; i <= 11; i++) {
      final bottomX = size.width / 2 + i * size.width * .12;
      canvas.drawLine(Offset(size.width / 2, horizon), Offset(bottomX, size.height), grid);
    }
    for (int i = 0; i < 9; i++) {
      final p = i / 8.0;
      final y = horizon + math.pow(p, 1.75) * size.height * .37;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x26FFB84D);
    final center = Offset(size.width * .5, size.height * .43);
    for (int i = 0; i < 5; i++) {
      final rect = Rect.fromCenter(center: center, width: size.width * (.48 + i * .15), height: size.height * (.18 + i * .07));
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(t * (.025 + i * .008));
      canvas.translate(-center.dx, -center.dy);
      canvas.drawArc(rect, -math.pi * .1, math.pi * 1.45, false, ringPaint);
      canvas.restore();
    }

    final particle = Paint();
    for (int i = 0; i < 125; i++) {
      final x = (rng.nextDouble() + progress * .08 * (i % 4)) % 1.0;
      final y = (rng.nextDouble() + math.sin(t + i) * .015) % 1.0;
      final radius = .7 + rng.nextDouble() * 2.4;
      final alpha = .18 + .42 * ((math.sin(t * 1.6 + i) + 1) / 2);
      particle.color = (i.isEven ? const Color(0xFFFFD166) : const Color(0xFFFFB84D)).withOpacity(alpha);
      canvas.drawCircle(Offset(x * size.width, y * size.height), radius, particle);
    }

    final beamX = ((progress * 1.35) - .15) * size.width;
    final beam = Paint()
      ..shader = LinearGradient(colors: [const Color(0x00FF5C8A), const Color(0x22FF5C8A), const Color(0x00FFB84D)]).createShader(Rect.fromLTWH(beamX - 150, 0, 300, size.height));
    canvas.drawRect(Rect.fromLTWH(beamX - 150, 0, 300, size.height), beam);

    final vignette = Paint()
      ..shader = RadialGradient(colors: [const Color(0x00000000), const Color(0x8805050C)]).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant AuroraCampusPainter oldDelegate) => true;
}
