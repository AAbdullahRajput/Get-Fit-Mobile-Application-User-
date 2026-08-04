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

class CallNotificationService {
  static final CallNotificationService _instance = CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  static void Function(String callId)? _onDeclineCallback;

  static void setDeclineCallback(void Function(String callId) callback) {
    _onDeclineCallback = callback;
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
        debugPrint('\x1B[33m[CallNotificationService] Declined -> $callId\x1B[0m');
        _onDeclineCallback?.call(callId);
        break;
      case Event.actionCallEnded:
        debugPrint('\x1B[33m[CallNotificationService] Ended -> $callId\x1B[0m');
        break;
      case Event.actionCallTimeout:
        // Do NOT call endCall here — plugin auto-shows missed call.
        break;
      default:
        break;
    }
  }
}