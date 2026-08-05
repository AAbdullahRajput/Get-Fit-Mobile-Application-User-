import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:get_fit/Services/call_service.dart';
import 'package:get_fit/Presentation/pages/call/video_call_page.dart';
import 'package:get_fit/main.dart' show navigatorKey;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallNotificationService {
  static final CallNotificationService _instance = CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  static void Function(String callId)? _onDeclineCallback;

  static void setDeclineCallback(void Function(String callId) callback) {
    _onDeclineCallback = callback;
  }

  // Watches call_sessions for a specific ringing call, independent of
  // whether any UI page is open, so CallKit auto-dismisses the instant the
  // other side hangs up/declines/times out.
  static final Map<String, RealtimeChannel> _dismissWatchers = {};

  static void _watchForRemoteEnd(String callId) {
    final client = Supabase.instance.client;
    final channel = client.channel('callkit_dismiss_$callId');
    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'call_sessions',
        filter: 'id=eq.$callId',
      ),
      (payload, [ref]) {
        final newRecord = Map<String, dynamic>.from(payload['new'] as Map);
        final status = newRecord['status'] as String?;
        debugPrint('[CallNotificationService] Remote watcher | status=$status');
        if (status == 'ended' || status == 'missed' || status == 'declined') {
          FlutterCallkitIncoming.endCall(callId);
          _stopWatching(callId);
        }
      },
    );
    channel.subscribe();
    _dismissWatchers[callId] = channel;
  }

  static void _stopWatching(String callId) {
    _dismissWatchers[callId]?.unsubscribe();
    _dismissWatchers.remove(callId);
  }

  Future<void> showIncomingCall({
    required String callId,
    required String channelName,
    required String callerName,
    String? callerImageUrl,
  }) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Get Fit',
      avatar: callerImageUrl,
      handle: callerName,
      type: 1, // video
      duration: 45000,
      extra: {'channel_name': channelName, 'caller_name': callerName},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0F0F0F',
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('\x1B[32m[CallNotificationService] Shown incoming call for $callerName\x1B[0m');
    _watchForRemoteEnd(callId);
  }

  Future<void> cancelIncomingCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }

  static Future<void> handleCallEvent(CallEvent? event) async {
    if (event == null) return;
    final callId = event.body['id'] as String?;
    if (callId == null) return;

    switch (event.event) {
      case Event.actionCallAccept:
        _stopWatching(callId);
        final extra = event.body['extra'] as Map? ?? {};
        final channelName = extra['channel_name'] as String? ?? '';
        final callerName = extra['caller_name'] as String? ?? 'Trainer';
        debugPrint('\x1B[32m[CallNotificationService] Accepted -> $callId\x1B[0m');
        await CallService().updateStatus(callId, 'accepted');
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoCallPage(
              callId: callId,
              channelName: channelName,
              remoteName: callerName,
            ),
          ),
        );
        break;
      case Event.actionCallDecline:
        _stopWatching(callId);
        debugPrint('\x1B[33m[CallNotificationService] Declined -> $callId\x1B[0m');
        _onDeclineCallback?.call(callId);
        FlutterCallkitIncoming.endCall(callId);
        break;
      case Event.actionCallEnded:
        _stopWatching(callId);
        debugPrint('\x1B[33m[CallNotificationService] Ended -> $callId\x1B[0m');
        FlutterCallkitIncoming.endCall(callId);
        break;
      case Event.actionCallTimeout:
        _stopWatching(callId);
        // Do NOT call endCall here — plugin auto-shows missed call.
        break;
      default:
        break;
    }
  }
}