import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get_fit/Presentation/pages/launch/launch_page.dart';
import 'package:get_fit/Services/call_service.dart';
import 'package:get_fit/Services/call_notification_service.dart';
import 'package:get_fit/Services/notification_service.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message received: ${message.data}');
  await _handleIncomingCallMessage(message);
}

Future<void> _handleIncomingCallMessage(RemoteMessage message) async {
  if (message.data['type'] != 'incoming_call') return;

  final callId = message.data['call_id'] as String?;
  final channelName = message.data['channel_name'] as String?;
  final callerName = message.data['caller_name'] as String? ?? 'Trainer';
  final callerImageUrl = message.data['caller_image_url'] as String?;
  if (callId == null || channelName == null) return;

  CallNotificationService.setDeclineCallback((id) {
    CallService().updateStatus(id, 'declined');
  });

  await CallNotificationService().showIncomingCall(
    callId: callId,
    channelName: channelName,
    callerName: callerName,
    callerImageUrl: callerImageUrl,
  );
}

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

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((message) {
    _handleIncomingCallMessage(message);
  });

  FlutterCallkitIncoming.onEvent.listen((event) {
    CallNotificationService.handleCallEvent(event);
  });

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session != null) {
      SupabaseService.registerFcmToken(session.user.id);
      // Realtime kept for status sync only — no longer navigates directly.
      CallService().listenForIncomingCalls(session.user.id, (call) {
        debugPrint('[CALL] Incoming call row detected (CallKit handles UI): ${call['id']}');
      });
    } else {
      CallService().stopListeningForIncomingCalls();
    }
  });

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
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          home: const LaunchPage(),
        );
      },
    );
  }
}