import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Açılış ekranı: Brothers Teknoloji logosu 5 saniye gösterilir, ardından mağaza açılır.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(seconds: 5);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.duration, _openApp);
  }

  void _openApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const AppShell(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    final scale = Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: AppColors.navy.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: ClipOval(child: _logo()),
                    ),
                    const SizedBox(height: 28),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'Brothers', style: TextStyle(color: AppColors.navy)),
                        TextSpan(text: ' Teknoloji', style: TextStyle(color: AppColors.blue)),
                      ]),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Teknoloji Mağazası',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 14, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 3),
            FadeTransition(
              opacity: fade,
              child: const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.green),
              ),
            ),
            const SizedBox(height: 18),
            const Text('brothersteknoloji.com', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 24),
          ],
            ),
          ),
        ),
      ),
    );
  }

  /// Logo uygulamaya gömülüdür (assets/logo.jpg); yoksa internetten yüklenir.
  Widget _logo() => Image.asset(
        'assets/logo.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const NetImage(AppConfig.logoUrl),
      );
}
