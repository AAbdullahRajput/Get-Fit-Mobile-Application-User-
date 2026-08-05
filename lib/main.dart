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
import 'package:get_fit/Services/appointment_notification_service.dart';
import 'package:get_fit/Services/notification_service.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Presentation/pages/call/incoming_call_page.dart';
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

/// Foreground-only path — the app already owns the screen, so instead of
/// relying on CallKit's system overlay (which Android suppresses when the
/// requesting app is already focused), push our own full-screen call UI
/// directly. CallKit stays reserved for backgrounded/locked/killed states,
/// handled by _handleIncomingCallMessage via the background isolate.
Future<void> _handleAppointmentReminderMessage(RemoteMessage message) async {
  if (message.data['type'] != 'appointment_reminder') return;
  debugPrint('[APPT] Reminder received: ${message.data['body']}');
}

Future<void> _handleForegroundIncomingCall(RemoteMessage message) async {
  if (message.data['type'] != 'incoming_call') return;

  final callId = message.data['call_id'] as String?;
  final channelName = message.data['channel_name'] as String?;
  final callerName = message.data['caller_name'] as String? ?? 'Trainer';
  final callerImageUrl = message.data['caller_image_url'] as String?;
  if (callId == null || channelName == null) return;

  CallNotificationService.setDeclineCallback((id) {
    CallService().updateStatus(id, 'declined');
  });

  // Fire the CallKit notification too — Android suppresses the full-screen
  // takeover while the app is foregrounded, but the heads-up banner still
  // shows, matching how real dialer/calling apps surface both at once.
  await CallNotificationService().showIncomingCall(
    callId: callId,
    channelName: channelName,
    callerName: callerName,
    callerImageUrl: callerImageUrl,
  );

  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  navigator.push(
    MaterialPageRoute(
      builder: (_) => IncomingCallPage(
        callId: callId,
        channelName: channelName,
        callerName: callerName,
        callerImageUrl: callerImageUrl,
        playRingtone: false,
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Stripe.instance.applySettings();

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: false,
    );
  } catch (e) {
    debugPrint('[BOOT] Supabase initialize warning (likely stale session): $e');
  }

  await NotificationService.init();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((message) {
    _handleForegroundIncomingCall(message);
    _handleAppointmentReminderMessage(message);

    // Show appointment reminder banner
    if (message.data['type'] == 'appointment_reminder') {
      try {
        final context = navigatorKey.currentContext;
        if (context != null && Scaffold.maybeOf(context) != null) {
          AppointmentNotificationService.showAppointmentReminder(
            context: context,
            title: message.data['title'] ?? 'Appointment Reminder',
            body: message.data['body'] ?? 'Upcoming session',
            timeframe: message.data['notification_type'] ?? 'appointment',
          );
        }
      } catch (e) {
        debugPrint('[APPT] Error showing reminder: $e');
      }
    }
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