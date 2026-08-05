import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get_fit/Services/agora_service.dart';
import 'package:get_fit/Services/call_service.dart';
import 'package:get_fit/Presentation/widgets/call/call_widgets.dart';
import 'package:get_fit/Utils/constants.dart';

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
  bool _isEnding = false;
  String? _errorMessage;

  DateTime? _connectedAt;
  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;

  bool _hasEndedByRemote = false;

  @override
  void initState() {
    super.initState();
    debugPrint('\x1B[36m[VIDEO-CALL] Screen opened | callId=${widget.callId} channel=${widget.channelName}\x1B[0m');
    _setupCallbacks();
    _callService.onSessionUpdate = _onSessionUpdate;
    _callService.listenToCall(widget.callId);
    _join();
  }

  void _onSessionUpdate(Map<String, dynamic> session) {
    final status = session['status'] as String?;
    debugPrint('\x1B[36m[VIDEO-CALL] Session status update -> $status\x1B[0m');
    if (!mounted || _hasEndedByRemote || _isEnding) return;

    if (status == 'ended') {
      _hasEndedByRemote = true;
      _showErrorAndExit('${widget.remoteName} ended the call');
      _cleanupAndExit();
    } else if (status == 'declined') {
      _hasEndedByRemote = true;
      _showErrorAndExit('${widget.remoteName} declined the call');
      _cleanupAndExit();
    } else if (status == 'missed') {
      _hasEndedByRemote = true;
      _showErrorAndExit('Call not answered');
      _cleanupAndExit();
    }
  }

  Future<void> _cleanupAndExit() async {
    _tickTimer?.cancel();
    try {
      await _agoraService.leaveChannel();
      await FlutterCallkitIncoming.endCall(widget.callId);
    } catch (e) {
      debugPrint('\x1B[31m[VIDEO-CALL] ERROR | _cleanupAndExit | $e\x1B[0m');
    }
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
      if (_hasEndedByRemote) return;
      if (mounted) setState(() => _remoteJoined = false);
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
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_connectedAt!));
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showErrorAndExit(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFE5484D), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
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
    if (_isEnding || _hasEndedByRemote) return;
    setState(() => _isEnding = true);
    debugPrint('\x1B[33m[VIDEO-CALL] Ending call | elapsed=${_elapsed.inSeconds}s\x1B[0m');
    _tickTimer?.cancel();
    try {
      await _callService.endCall(widget.callId, connectedAt: _connectedAt);
      await _agoraService.leaveChannel();
      await FlutterCallkitIncoming.endCall(widget.callId);
    } catch (e) {
      debugPrint('\x1B[31m[VIDEO-CALL] ERROR | _endCall | $e\x1B[0m');
    }
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
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final localPreviewWidth = (screenSize.width * 0.28).clamp(96.0, 130.0);
    final localPreviewHeight = localPreviewWidth * 1.35;

    final statusText = _remoteJoined
        ? _formatDuration(_elapsed)
        : (_isJoined ? 'Ringing...' : 'Connecting...');

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _remoteJoined &&
                    _agoraService.engine != null &&
                    _agoraService.remoteUid != null &&
                    _agoraService.remoteUid != 0
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _agoraService.engine!,
                      canvas: VideoCanvas(uid: _agoraService.remoteUid!),
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
                          _isJoined ? 'Waiting for ${widget.remoteName} to join...' : 'Connecting...',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

            if (_isJoined && _agoraService.engine != null)
              Positioned(
                top: topPadding + 16,
                right: 16,
                child: Container(
                  width: localPreviewWidth,
                  height: localPreviewHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _isCameraOff
                      ? Container(
                          color: const Color(0xFF2C2C2C),
                          child: Center(
                            child: CallSvgIcon(svg: CallIcons.cameraOff, size: 26, color: Colors.white38),
                          ),
                        )
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _agoraService.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                ),
              ),

            Positioned(
              top: topPadding + 16,
              left: 16,
              right: localPreviewWidth + 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.remoteName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    CallStatusPill(text: statusText, showDot: !_remoteJoined, dotColor: themeColor),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CallActionButton(
                      svg: _isMuted ? CallIcons.micOff : CallIcons.mic,
                      onTap: _toggleMute,
                      active: _isMuted,
                    ),
                    CallActionButton(
                      svg: CallIcons.callEnd,
                      onTap: _endCall,
                      background: const Color(0xFFE5484D),
                      loading: _isEnding,
                      size: 62,
                    ),
                    CallActionButton(
                      svg: _isCameraOff ? CallIcons.cameraOff : CallIcons.camera,
                      onTap: _toggleCamera,
                      active: _isCameraOff,
                    ),
                    CallActionButton(
                      svg: CallIcons.switchCamera,
                      onTap: () => _agoraService.switchCamera(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}