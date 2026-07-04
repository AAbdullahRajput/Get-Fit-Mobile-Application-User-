import 'package:flutter/foundation.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles the "signaling" side of a call — creating the call_sessions row,
/// listening for status changes via Supabase Realtime, and updating status.
/// This is deliberately separate from AgoraService: this class only ever
/// talks to Postgres/Realtime, never to the video engine itself.
class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  RealtimeChannel? _channel;
  String? _activeCallId;

  void Function(Map<String, dynamic> session)? onSessionUpdate;

  /// Called by the caller (app user) to start a new call.
  /// Creates the call_sessions row with status='calling', then flips to
  /// 'ringing' once inserted (so listeners know the row is live).
  Future<Map<String, dynamic>?> startCall({
    required String trainerId,
    String? appointmentId,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return null;

      final channelName = 'call_${DateTime.now().millisecondsSinceEpoch}_$userId';

      debugPrint('\x1B[33m[CALL] Creating call session | trainer=$trainerId channel=$channelName\x1B[0m');

      final result = await SupabaseService.client
          .from('call_sessions')
          .insert({
            'trainer_id': trainerId,
            'appointment_id': appointmentId,
            'caller_user_id': userId,
            'channel_name': channelName,
            'status': 'calling',
          })
          .select()
          .single();

      _activeCallId = result['id'] as String;
      debugPrint('\x1B[32m[CALL] Session created | id=$_activeCallId\x1B[0m');

      // Immediately flip to 'ringing' — this is the signal the trainer's
      // dashboard listens for to show the incoming-call UI.
      await updateStatus(_activeCallId!, 'ringing');

      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('\x1B[31m[CALL] ERROR | startCall | $e\x1B[0m');
      return null;
    }
  }

  /// Subscribes to realtime updates for a specific call session row.
  /// Both caller and receiver use this to react to status changes
  /// (accepted, declined, ended) without polling.
  void listenToCall(String callId) {
    debugPrint('\x1B[35m[CALL] Listening to call_sessions | id=$callId\x1B[0m');
    _channel?.unsubscribe();

    final channel = SupabaseService.client.channel('call_session_$callId');
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
        debugPrint('\x1B[35m[CALL] Realtime update | status=${newRecord['status']}\x1B[0m');
        onSessionUpdate?.call(newRecord);
      },
    );
    channel.subscribe();
    _channel = channel;
  }

  Future<void> updateStatus(String callId, String status) async {
    try {
      debugPrint('\x1B[33m[CALL] Updating status | id=$callId -> $status\x1B[0m');
      final data = <String, dynamic>{'status': status};
      if (status == 'accepted') {
        data['connected_at'] = DateTime.now().toIso8601String();
      }
      if (status == 'ended' || status == 'declined' || status == 'missed') {
        data['ended_at'] = DateTime.now().toIso8601String();
      }
      await SupabaseService.client
          .from('call_sessions')
          .update(data)
          .eq('id', callId);
      debugPrint('\x1B[32m[CALL] Status updated -> $status\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[CALL] ERROR | updateStatus | $e\x1B[0m');
    }
  }

  /// Ends the call and records the duration if it was ever connected.
  Future<void> endCall(String callId, {DateTime? connectedAt}) async {
    try {
      int? durationSeconds;
      if (connectedAt != null) {
        durationSeconds = DateTime.now().difference(connectedAt).inSeconds;
      }
      debugPrint('\x1B[33m[CALL] Ending call | id=$callId duration=${durationSeconds}s\x1B[0m');
      await SupabaseService.client.from('call_sessions').update({
        'status': 'ended',
        'ended_at': DateTime.now().toIso8601String(),
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      }).eq('id', callId);
      debugPrint('\x1B[32m[CALL] Call ended and logged\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[CALL] ERROR | endCall | $e\x1B[0m');
    }
  }

  void stopListening() {
    debugPrint('\x1B[33m[CALL] Stopping realtime listener\x1B[0m');
    _channel?.unsubscribe();
    _channel = null;
    _activeCallId = null;
  }
}