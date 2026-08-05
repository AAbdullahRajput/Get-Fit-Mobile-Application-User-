import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_fit/Services/call_service.dart';
import 'package:get_fit/Services/agora_service.dart';
import 'package:get_fit/Services/beep_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get_fit/Presentation/pages/call/video_call_page.dart';
import 'package:get_fit/Presentation/widgets/call/call_widgets.dart';
import 'package:get_fit/Utils/constants.dart';

class IncomingCallPage extends StatefulWidget {
  final String callId;
  final String channelName;
  final String callerName;
  final String? callerImageUrl;
  final bool playRingtone;

  const IncomingCallPage({
    super.key,
    required this.callId,
    required this.channelName,
    required this.callerName,
    this.callerImageUrl,
    this.playRingtone = true,
  });

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  final _callService = CallService();
  final _beepService = BeepService();
  bool _isResponding = false;
  bool _isDeclining = false;
  bool _hasEnded = false;

  void _showStyledSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.call_end_rounded,
              color: isError ? const Color(0xFFE5484D) : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    debugPrint('\x1B[36m[INCOMING-CALL] Screen opened | callId=${widget.callId} from=${widget.callerName}\x1B[0m');
    _callService.onSessionUpdate = _onSessionUpdate;
    _callService.listenToCall(widget.callId);
    if (widget.playRingtone) {
      _beepService.startRingtone();
    }
  }

  void _onSessionUpdate(Map<String, dynamic> session) {
    final status = session['status'] as String?;
    debugPrint('\x1B[36m[INCOMING-CALL] Status changed -> $status\x1B[0m');
    if (!mounted || _hasEnded) return;
    if (status == 'ended' && !_isResponding) {
      _hasEnded = true;
      _beepService.stopRingtone();
      _showStyledSnackBar('Missed call — the caller hung up');
      Navigator.pop(context);
    }
  }

  Future<void> _accept() async {
    if (_isResponding || _isDeclining) return;

    final hasPermissions = await AgoraService().requestPermissions();
    if (!hasPermissions) {
      _showStyledSnackBar(
        'Camera and microphone permission is required to accept the call',
        isError: true,
      );
      return;
    }

    setState(() => _isResponding = true);
    _hasEnded = true;
    _beepService.stopRingtone();
    debugPrint('\x1B[32m[INCOMING-CALL] Accepted\x1B[0m');
    await _callService.updateStatus(widget.callId, 'accepted');
    await FlutterCallkitIncoming.endCall(widget.callId);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VideoCallPage(
          callId: widget.callId,
          channelName: widget.channelName,
          remoteName: widget.callerName,
        ),
      ),
    );
  }

  Future<void> _decline() async {
    if (_isResponding || _isDeclining) return;
    setState(() => _isDeclining = true);
    _hasEnded = true;
    _beepService.stopRingtone();
    debugPrint('\x1B[33m[INCOMING-CALL] Declined\x1B[0m');
    await _callService.updateStatus(widget.callId, 'declined');
    await FlutterCallkitIncoming.endCall(widget.callId);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _callService.stopListening();
    _beepService.stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF141414),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: screenHeight * 0.04),
            child: Column(
              children: [
                const Spacer(flex: 2),
                PulsingAvatar(imageUrl: widget.callerImageUrl, ringColor: themeColor),
                const SizedBox(height: 28),
                Text(
                  widget.callerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const CallStatusPill(text: 'Incoming video call', showDot: true, dotColor: themeColor),
                const Spacer(flex: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CallActionButton(
                      svg: CallIcons.callEnd,
                      onTap: _decline,
                      background: const Color(0xFFE5484D),
                      loading: _isDeclining,
                      size: 68,
                      label: 'Decline',
                    ),
                    CallActionButton(
                      svg: CallIcons.callAccept,
                      onTap: _accept,
                      background: themeColor,
                      iconColor: Colors.black,
                      loading: _isResponding,
                      size: 68,
                      label: 'Accept',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}