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
  // Logo animation controller
  late AnimationController _logoController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoFadeAnimation;

  // Progress bar controller
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // ── Logo: slides in from left, bounces, fades in ──
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-1.5, 0), end: const Offset(0.08, 0))
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.08, 0), end: const Offset(-0.05, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.05, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_logoController);

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // ── Progress bar starts after logo lands ──
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

    // Start logo, then trigger progress bar
    _logoController.forward().then((_) {
      if (mounted) _progressController.forward();
    });
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
    _logoController.dispose();
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

          // Animated Logo
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (_, child) => FadeTransition(
                opacity: _logoFadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: child,
                ),
              ),
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
                      minHeight: 6,
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