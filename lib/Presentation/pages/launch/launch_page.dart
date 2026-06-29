import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/auth/auth_landing_page.dart';
import 'package:get_fit/Presentation/pages/home/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_fit/Presentation/pages/setup/setup_page.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> with TickerProviderStateMixin {
  // Phase 1: Drop from top + slide down & fade out
  late AnimationController _dropController;
  late Animation<Offset> _dropSlide;
  late Animation<double> _dropFade;

  // Phase 2: Slide in from left to center
  late AnimationController _enterController;
  late Animation<Offset> _enterSlide;
  late Animation<double> _enterFade;

  // Phase 3: Idle pulse while loading
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseGlow;

  // Progress bar
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Which phase is visible
  bool _showDrop = false;
  bool _showEnter = false;
  bool _showIdle = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runSequence();
  }

  void _setupAnimations() {
    // --- Phase 1: Drop from top, slide down, fade out ---
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    // Comes from top (Offset(0, -1.5)) → center (0,0) → slides further down (0, 1.5)
    _dropSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1.5), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, 0.05))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.05), end: const Offset(0, 1.8))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
    ]).animate(_dropController);

    _dropFade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_dropController);

    // --- Phase 2: Slide in from left to center ---
    _enterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _enterSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-1.5, 0), end: const Offset(0.06, 0))
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_enterController);

    _enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // --- Phase 3: Idle pulse ---
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // --- Progress bar ---
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await _navigate();
      }
    });
  }

  Future<void> _runSequence() async {
    // Phase 1: drop in + drop out
    if (!mounted) return;
    setState(() => _showDrop = true);
    await _dropController.forward();

    if (!mounted) return;
    setState(() {
      _showDrop = false;
      _showEnter = true;
    });

    // Phase 2: slide in from left
    await _enterController.forward();

    if (!mounted) return;
    setState(() {
      _showEnter = false;
      _showIdle = true;
    });

    // Phase 3: pulse + start progress
    _pulseController.repeat(reverse: true);
    _progressController.forward();
  }

  Future<void> _navigate() async {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    if (!mounted) return;

    if (isLoggedIn) {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final setup = await Supabase.instance.client
          .from('user_setup')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => setup != null ? const HomePage() : const SetupPage(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthLandingPage()),
      );
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    _enterController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Image.asset(
            'assets/launch/bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Phase 1: Drop from top → slide down & fade out
          if (_showDrop)
            Center(
              child: AnimatedBuilder(
                animation: _dropController,
                builder: (_, child) => FadeTransition(
                  opacity: _dropFade,
                  child: SlideTransition(
                    position: _dropSlide,
                    child: child,
                  ),
                ),
                child: Image.asset('assets/launch/logo.png', height: 140),
              ),
            ),

          // Phase 2: Slide in from left to center
          if (_showEnter)
            Center(
              child: AnimatedBuilder(
                animation: _enterController,
                builder: (_, child) => FadeTransition(
                  opacity: _enterFade,
                  child: SlideTransition(
                    position: _enterSlide,
                    child: child,
                  ),
                ),
                child: Image.asset('assets/launch/logo.png', height: 140),
              ),
            ),

          // Phase 3: Idle pulse with soft glow while loading
          if (_showIdle)
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, child) {
                  return Transform.scale(
                    scale: _pulseScale.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white
                                .withOpacity(0.18 * _pulseGlow.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: Image.asset('assets/launch/logo.png', height: 140),
              ),
            ),

          // Progress bar + percentage
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (_, __) => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 46,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading... ${(_progressAnimation.value * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}