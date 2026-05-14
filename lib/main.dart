import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/onboarding/onboarding_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: const Color(0xff232323),
      home: const OnboardingPage(),
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xff232323)),
    );
  }
}
