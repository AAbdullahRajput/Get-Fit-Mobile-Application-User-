import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Presentation/pages/call/incoming_call_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// TEMPORARY testing helper — simulates what the React trainer dashboard
/// will eventually do: listen for new incoming calls for a given trainer
/// and pop up the incoming-call screen.
///
/// Wrap this around any page (e.g. HomePage) on your SECOND test device,
/// logged in as a different test account, and pass in the trainer id you
/// want that device to "answer calls for". Remove this once the real
/// React dashboard handles incoming calls instead.
class TestIncomingCallListener extends StatefulWidget {
  final String trainerId;
  final Widget child;

  const TestIncomingCallListener({
    super.key,
    required this.trainerId,
    required this.child,
  });

  @override
  State<TestIncomingCallListener> createState() =>
      _TestIncomingCallListenerState();
}

class _TestIncomingCallListenerState extends State<TestIncomingCallListener> {
  RealtimeChannel? _channel;
  final Set<String> _handledCallIds = {};

  @override
  void initState() {
    super.initState();
    debugPrint(
        '\x1B[36m[TEST-LISTENER] Listening for incoming calls | trainerId=${widget.trainerId}\x1B[0m');
    _subscribe();
  }

  void _subscribe() {
    final channel = SupabaseService.client.channel('trainer_incoming_calls_${widget.trainerId}');
    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'call_sessions',
        filter: 'trainer_id=eq.${widget.trainerId}',
      ),
      (payload, [ref]) {
        final record = Map<String, dynamic>.from(payload['new'] as Map);
        _handleNewCall(record);
      },
    );
    // Also listen for UPDATE in case status flips to 'ringing' right after
    // insert (matches how CallService.startCall works).
    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'call_sessions',
        filter: 'trainer_id=eq.${widget.trainerId}',
      ),
      (payload, [ref]) {
        final record = Map<String, dynamic>.from(payload['new'] as Map);
        if (record['status'] == 'ringing') {
          _handleNewCall(record);
        }
      },
    );
    channel.subscribe();
    _channel = channel;
  }

  Future<void> _handleNewCall(Map<String, dynamic> record) async {
    final callId = record['id'] as String;
    final status = record['status'] as String?;
    if (status != 'ringing' && status != 'calling') return;
    if (_handledCallIds.contains(callId)) return;
    _handledCallIds.add(callId);

    debugPrint('\x1B[32m[TEST-LISTENER] Incoming call detected | id=$callId\x1B[0m');

    final callerUserId = record['caller_user_id'] as String;
    // Fetch the caller's name for display — since this is test-only,
    // a plain lookup against users table is fine here.
    String callerName = 'Someone';
    String? callerImage;
    try {
      final caller = await SupabaseService.client
          .from('users')
          .select('username, avatar_url')
          .eq('id', callerUserId)
          .maybeSingle();
      callerName = caller?['username'] as String? ?? 'Someone';
      callerImage = caller?['avatar_url'] as String?;
    } catch (e) {
      debugPrint('\x1B[31m[TEST-LISTENER] ERROR fetching caller info | $e\x1B[0m');
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => IncomingCallPage(
          callId: callId,
          channelName: record['channel_name'] as String,
          callerName: callerName,
          callerImageUrl: callerImage,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}