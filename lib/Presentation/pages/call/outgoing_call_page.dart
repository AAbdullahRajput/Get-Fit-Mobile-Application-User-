import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_fit/Services/call_service.dart';
import 'package:get_fit/Presentation/pages/call/video_call_page.dart';
import 'package:get_fit/Utils/constants.dart';

/// Shown to the caller (app user) right after they tap the call button.
/// Displays "Calling {trainer}..." and listens for the trainer to accept,
/// decline, or for the call to time out (missed).
class OutgoingCallPage extends StatefulWidget {
  final String callId;
  final String channelName;
  final String trainerName;
  final String? trainerImageUrl;

  const OutgoingCallPage({
    super.key,
    required this.callId,
    required this.channelName,
    required this.trainerName,
    this.trainerImageUrl,
  });

  @override
  State<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage> {
  final _callService = CallService();
  Timer? _timeoutTimer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    debugPrint('\x1B[36m[OUTGOING-CALL] Screen opened | callId=${widget.callId}\x1B[0m');

    _callService.onSessionUpdate = _onSessionUpdate;
    _callService.listenToCall(widget.callId);

    // 45-second ring timeout — if the trainer hasn't answered by then,
    // mark it missed and close this screen automatically.
    _timeoutTimer = Timer(const Duration(seconds: 45), () async {
      debugPrint('\x1B[33m[OUTGOING-CALL] Ring timeout reached — marking missed\x1B[0m');
      await _callService.updateStatus(widget.callId, 'missed');
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _onSessionUpdate(Map<String, dynamic> session) {
    final status = session['status'] as String?;
    debugPrint('\x1B[36m[OUTGOING-CALL] Status changed -> $status\x1B[0m');

    if (!mounted) return;

    if (status == 'accepted') {
      _timeoutTimer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VideoCallPage(
            callId: widget.callId,
            channelName: widget.channelName,
            remoteName: widget.trainerName,
          ),
        ),
      );
    } else if (status == 'declined') {
      _timeoutTimer?.cancel();
      _showEndedMessage('${widget.trainerName} declined the call');
      Navigator.pop(context);
    } else if (status == 'ended') {
      _timeoutTimer?.cancel();
      Navigator.pop(context);
    }
  }

  void _showEndedMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2C2C2C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cancelCall() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    debugPrint('\x1B[33m[OUTGOING-CALL] User cancelled outgoing call\x1B[0m');
    _timeoutTimer?.cancel();
    await _callService.updateStatus(widget.callId, 'ended');
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _callService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _cancelCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              children: [
                const Spacer(flex: 2),
                CircleAvatar(
                  radius: 70,
                  backgroundColor: themeColor,
                  backgroundImage: (widget.trainerImageUrl ?? '').isNotEmpty
                      ? NetworkImage(widget.trainerImageUrl!)
                      : null,
                  child: (widget.trainerImageUrl ?? '').isEmpty
                      ? const Icon(Icons.person, size: 70, color: Colors.black)
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.trainerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Calling...',
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const Spacer(flex: 3),
                GestureDetector(
                  onTap: _cancelCall,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: _isCancelling
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.call_end,
                            color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}