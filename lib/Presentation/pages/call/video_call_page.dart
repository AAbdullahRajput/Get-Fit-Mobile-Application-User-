import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get_fit/Services/agora_service.dart';
import 'package:get_fit/Services/call_service.dart';
import 'package:get_fit/Utils/constants.dart';

/// The actual active-call screen: local + remote video, mute/camera/end
/// controls, and a running timer that starts once both sides are joined.
class VideoCallPage extends StatefulWidget {
  final String callId;
  final String channelName;
  final String remoteName;

  const VideoCallPage({
    super.key,
    required this.callId,
    required this.channelName,
    required this.remoteName,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final _agoraService = AgoraService();
  final _callService = CallService();

  bool _isJoined = false;
  bool _remoteJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  String? _errorMessage;

  DateTime? _connectedAt;
  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    debugPrint('\x1B[36m[VIDEO-CALL] Screen opened | callId=${widget.callId} channel=${widget.channelName}\x1B[0m');
    _setupCallbacks();
    _join();
  }

  void _setupCallbacks() {
    _agoraService.onLocalJoinSuccess = () {
      debugPrint('\x1B[32m[VIDEO-CALL] Local join success\x1B[0m');
      if (mounted) setState(() => _isJoined = true);
    };

    _agoraService.onRemoteUserJoined = () {
      debugPrint('\x1B[32m[VIDEO-CALL] Remote joined — starting timer\x1B[0m');
      _connectedAt = DateTime.now();
      _startTimer();
      if (mounted) setState(() => _remoteJoined = true);
    };

    _agoraService.onRemoteUserLeft = () {
      debugPrint('\x1B[33m[VIDEO-CALL] Remote left — ending call\x1B[0m');
      _endCall();
    };

    _agoraService.onError = (msg) {
      debugPrint('\x1B[31m[VIDEO-CALL] Error: $msg\x1B[0m');
      if (mounted) setState(() => _errorMessage = msg);
    };
  }

  Future<void> _join() async {
    final success = await _agoraService.joinChannel(widget.channelName);
    if (!success && mounted) {
      _showErrorAndExit(_errorMessage ?? 'Failed to join call');
    }
  }

  void _startTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) return;
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_connectedAt!));
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showErrorAndExit(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _agoraService.toggleMute(_isMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() => _isCameraOff = !_isCameraOff);
    await _agoraService.toggleCamera(_isCameraOff);
  }

  Future<void> _endCall() async {
    debugPrint('\x1B[33m[VIDEO-CALL] Ending call | elapsed=${_elapsed.inSeconds}s\x1B[0m');
    _tickTimer?.cancel();
    await _callService.endCall(widget.callId, connectedAt: _connectedAt);
    await _agoraService.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _agoraService.leaveChannel();
    _callService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Remote video — fills the screen
            _remoteJoined && _agoraService.engine != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _agoraService.engine!,
                      canvas: VideoCanvas(uid: _agoraService.remoteUid ?? 0),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: themeColor),
                        const SizedBox(height: 16),
                        Text(
                          _isJoined
                              ? 'Waiting for ${widget.remoteName} to join...'
                              : 'Connecting...',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

            // Local video — small preview, top-right
            if (_isJoined && _agoraService.engine != null)
              Positioned(
                top: 50,
                right: 16,
                child: Container(
                  width: 110,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _isCameraOff
                      ? Container(
                          color: const Color(0xFF2C2C2C),
                          child: const Icon(Icons.videocam_off,
                              color: Colors.white38),
                        )
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _agoraService.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                ),
              ),

            // Top bar — name + timer
            Positioned(
              top: 50,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.remoteName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Text(
                      _remoteJoined ? _formatDuration(_elapsed) : 'Ringing...',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onTap: _toggleMute,
                    active: _isMuted,
                  ),
                  _controlButton(
                    icon: Icons.call_end,
                    onTap: _endCall,
                    background: Colors.redAccent,
                  ),
                  _controlButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    onTap: _toggleCamera,
                    active: _isCameraOff,
                  ),
                  _controlButton(
                    icon: Icons.cameraswitch,
                    onTap: () => _agoraService.switchCamera(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    Color? background,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: background ?? (active ? themeColor : Colors.white24),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: background != null
              ? Colors.white
              : (active ? Colors.black : Colors.white),
          size: 24,
        ),
      ),
    );
  }
}