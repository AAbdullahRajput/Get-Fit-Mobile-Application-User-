import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_fit/Services/call_service.dart';
import 'package:get_fit/Presentation/pages/call/video_call_page.dart';
import 'package:get_fit/Utils/constants.dart';

/// Shown to the receiving side when a call comes in. In production this
/// runs on the trainer's React dashboard — this Flutter version exists so
/// you can test the full call flow end-to-end with two logged-in test
/// accounts on two devices/emulators before the web side is built.
class IncomingCallPage extends StatefulWidget {
  final String callId;
  final String channelName;
  final String callerName;
  final String? callerImageUrl;

  const IncomingCallPage({
    super.key,
    required this.callId,
    required this.channelName,
    required this.callerName,
    this.callerImageUrl,
  });

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  final _callService = CallService();
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    debugPrint('\x1B[36m[INCOMING-CALL] Screen opened | callId=${widget.callId} from=${widget.callerName}\x1B[0m');
    _callService.onSessionUpdate = _onSessionUpdate;
    _callService.listenToCall(widget.callId);
  }

  void _onSessionUpdate(Map<String, dynamic> session) {
    final status = session['status'] as String?;
    debugPrint('\x1B[36m[INCOMING-CALL] Status changed -> $status\x1B[0m');
    if (!mounted) return;
    // Caller cancelled before we responded — close this screen.
    if (status == 'ended' && !_isResponding) {
      Navigator.pop(context);
    }
  }

  Future<void> _accept() async {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    debugPrint('\x1B[32m[INCOMING-CALL] Accepted\x1B[0m');
    await _callService.updateStatus(widget.callId, 'accepted');
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
    if (_isResponding) return;
    setState(() => _isResponding = true);
    debugPrint('\x1B[33m[INCOMING-CALL] Declined\x1B[0m');
    await _callService.updateStatus(widget.callId, 'declined');
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _callService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
                  backgroundImage: (widget.callerImageUrl ?? '').isNotEmpty
                      ? NetworkImage(widget.callerImageUrl!)
                      : null,
                  child: (widget.callerImageUrl ?? '').isEmpty
                      ? const Icon(Icons.person, size: 70, color: Colors.black)
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Incoming video call...',
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const Spacer(flex: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _decline,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_end,
                                color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Decline',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _accept,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: themeColor,
                              shape: BoxShape.circle,
                            ),
                            child: _isResponding
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                        color: Colors.black, strokeWidth: 2),
                                  )
                                : const Icon(Icons.videocam,
                                    color: Colors.black, size: 32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Accept',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}