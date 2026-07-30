import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_fit/Services/call_service.dart';
import 'package:get_fit/Presentation/pages/call/video_call_page.dart';
import 'package:get_fit/Presentation/widgets/call/call_widgets.dart';
import 'package:get_fit/Utils/constants.dart';

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

class _OutgoingCallPageState extends State<OutgoingCallPage>
    with SingleTickerProviderStateMixin {
  final _callService = CallService();
  Timer? _timeoutTimer;
  bool _isCancelling = false;
  String _statusText = 'Calling...';
  bool _imageLoaded = false;

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    debugPrint(
        '\x1B[36m[OUTGOING-CALL] Screen opened | callId=${widget.callId} | trainer=${widget.trainerName} | image=${widget.trainerImageUrl}\x1B[0m');

    _callService.onSessionUpdate = _onSessionUpdate;
    _callService.listenToCall(widget.callId);

    // Preload image if available
    if ((widget.trainerImageUrl ?? '').isNotEmpty) {
      precacheImage(
        NetworkImage(widget.trainerImageUrl!),
        context,
      ).then((_) {
        if (mounted) setState(() => _imageLoaded = true);
      }).catchError((e) {
        debugPrint('\x1B[33m[OUTGOING-CALL] Image load error: $e\x1B[0m');
      });
    }

    _timeoutTimer = Timer(const Duration(seconds: 45), () async {
      debugPrint(
          '\x1B[33m[OUTGOING-CALL] Ring timeout reached — marking missed\x1B[0m');
      await _callService.updateStatus(widget.callId, 'missed');
      if (mounted) Navigator.pop(context);
    });
  }

  void _onSessionUpdate(Map<String, dynamic> session) {
    final status = session['status'] as String?;
    debugPrint('\x1B[36m[OUTGOING-CALL] Status changed -> $status\x1B[0m');
    if (!mounted) return;

    if (status == 'ringing') {
      setState(() => _statusText = 'Ringing...');
    } else if (status == 'accepted') {
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
        margin: const EdgeInsets.all(16),
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
    _fadeController.dispose();
    _callService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _cancelCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Top spacer
                const SizedBox(height: 20),

                /// Center content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Trainer avatar with pulsing rings
                      SizedBox(
                        width: isMobile ? 220 : 260,
                        height: isMobile ? 220 : 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            /// Pulsing rings (background)
                            ..._buildPulsingRings(
                              isMobile ? 110 : 130,
                              themeColor,
                            ),

                            /// Avatar image
                            Container(
                              width: isMobile ? 180 : 220,
                              height: isMobile ? 180 : 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1F1F1F),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: (widget.trainerImageUrl ?? '')
                                        .isNotEmpty
                                    ? Image.network(
                                        widget.trainerImageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            color:
                                                const Color(0xFF1F1F1F),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: themeColor,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: themeColor,
                                            child: Center(
                                              child: CallSvgIcon(
                                                svg:
                                                    CallIcons.personFallback,
                                                size: isMobile ? 90 : 110,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: themeColor,
                                        child: Center(
                                          child: CallSvgIcon(
                                            svg: CallIcons.personFallback,
                                            size: isMobile ? 90 : 110,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isMobile ? 36 : 48),

                      /// Trainer name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.trainerName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 28 : 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 16 : 20),

                      /// Status pill with blinking dot
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: Tween(begin: 0.3, end: 1.0)
                                  .animate(_fadeController),
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: themeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _statusText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// Bottom controls
                Padding(
                  padding: EdgeInsets.only(
                    bottom: isMobile ? 32 : 48,
                    left: 32,
                    right: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Cancel button
                      GestureDetector(
                        onTap: _isCancelling ? null : _cancelCall,
                        child: Container(
                          width: isMobile ? 76 : 88,
                          height: isMobile ? 76 : 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFFEF4444).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color:
                                    const Color(0xFFEF4444).withOpacity(0.2),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: _isCancelling
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Center(
                                  child: CallSvgIcon(
                                    svg: CallIcons.callEnd,
                                    size: isMobile ? 32 : 38,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Cancel label
                      Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds 2 pulsing rings for the avatar
  List<Widget> _buildPulsingRings(double baseRadius, Color color) {
    return List.generate(2, (i) {
      final delay = i * 0.5;
      return AnimatedBuilder(
        animation: _fadeController,
        builder: (context, _) {
          final t = (_fadeController.value + delay) % 1.0;
          final opacity = (1 - t) * 0.4;
          final size = baseRadius * 2 + (t * baseRadius * 0.8);

          return Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2.5,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}