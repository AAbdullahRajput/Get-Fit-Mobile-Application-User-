import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_fit/Presentation/pages/launch/launch_page.dart';
import 'package:get_fit/Presentation/widgets/test_incoming_call_listener.dart';
import 'package:get_fit/Services/notification_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Stripe.instance.applySettings();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    debug: false,
  );

  await NotificationService.init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          // TEMPORARY — for testing incoming calls only, before the React
          // trainer dashboard exists. Remove this wrapper (keep just
          // `home: const LaunchPage()`) once the web side is built.
          // home: const TestIncomingCallListener(
          //   trainerId: '41d83b59-9b0c-4e4e-9464-08ce145945a2', // Mei Lin
          //   child: LaunchPage(),
          // ),
          
          home: const LaunchPage(),
        );
      },
    );
  }
}