import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

class InstructorClassDetailPage extends StatefulWidget {
  final Map<String, dynamic> classData;
  final Map<String, dynamic> instructorData;

  const InstructorClassDetailPage({
    super.key,
    required this.classData,
    required this.instructorData,
  });

  @override
  State<InstructorClassDetailPage> createState() =>
      _InstructorClassDetailPageState();
}

class _InstructorClassDetailPageState
    extends State<InstructorClassDetailPage> {
  List<Map<String, dynamic>> _steps = [];
  Map<String, dynamic>? _todayLog;
  bool _loading = true;
  bool _toggling = false;
  final Set<int> _doneSteps = {};

  String get _todayDate =>
      DateTime.now().toIso8601String().substring(0, 10);

  bool get _isToday => true; // always today's session context
  bool get _isDone => _todayLog?['is_done'] == true;

  // Can only unmark today — not previous days
  bool get _canToggle {
    if (!_isDone) return true; // can always mark done
    final logDate = _todayLog?['scheduled_date'] as String?;
    return logDate == _todayDate;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final classId = widget.classData['id'] as String;
    final steps = await SupabaseService.getInstructorClassSteps(classId);
    final log = await SupabaseService.getInstructorClassLog(
      classId: classId,
      date: _todayDate,
    );
    if (mounted) {
      setState(() {
        _steps = steps;
        _todayLog = log;
        _loading = false;
      });
    }
  }

  Future<void> _toggleDone() async {
    if (_toggling || !_canToggle) return;
    setState(() => _toggling = true);
    try {
      final newVal = !_isDone;
      await SupabaseService.upsertInstructorClassLog(
        classId: widget.classData['id'] as String,
        instructorId: widget.classData['instructor_id'] as String,
        date: _todayDate,
        isDone: newVal,
        sessionDurationMinutes:
            (widget.classData['duration_minutes'] as num?)?.toInt() ?? 0,
      );
      final log = await SupabaseService.getInstructorClassLog(
        classId: widget.classData['id'] as String,
        date: _todayDate,
      );
      if (mounted) setState(() => _todayLog = log);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.classData;
    final ins = widget.instructorData;
    final title = cls['title'] as String? ?? '';
    final description = cls['description'] as String? ?? '';
    final imageUrl = cls['image_url'] as String? ?? '';
    final durationMin = (cls['duration_minutes'] as num?)?.toInt() ?? 0;
    final level = cls['level'] as String? ?? '';
    final classType = cls['class_type'] as String? ?? '';
    final scheduledTime = cls['scheduled_time'] as String? ?? '';
    final insName = ins['name'] as String? ?? '';
    final insImage = ins['image_url'] as String? ?? '';
    final insSpecialty = ins['specialty'] as String? ?? '';

    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _accent(context)))
          : CustomScrollView(
              slivers: [
                // ── Hero banner ──
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Instructor hero image
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _accent(context).withOpacity(0.2),
                                ))
                            : Container(color: _accent(context).withOpacity(0.2)),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      // Title overlay
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                _chip(level, Icons.bar_chart),
                                _chip('$durationMin min', Icons.timer),
                                if (classType.isNotEmpty)
                                  _chip(classType, Icons.category),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Instructor row ──
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: insImage.isNotEmpty
                                  ? NetworkImage(insImage)
                                  : null,
                              backgroundColor:
                                  _accent(context).withOpacity(0.2),
                              child: insImage.isEmpty
                                  ? Icon(Icons.person,
                                      color: _accent(context))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(insName,
                                    style: TextStyle(
                                      color: context.isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    )),
                                Text(insSpecialty,
                                    style: TextStyle(
                                      color: _accent(context),
                                      fontSize: 12,
                                    )),
                              ],
                            ),
                            const Spacer(),
                            if (scheduledTime.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _accent(context).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 13, color: _accent(context)),
                                    const SizedBox(width: 4),
                                    Text(scheduledTime,
                                        style: TextStyle(
                                          color: _accent(context),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Description ──
                        Text('About this class',
                            style: TextStyle(
                              color: context.isDark
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        Text(description,
                            style: TextStyle(
                              color: context.isDark
                                  ? Colors.white60
                                  : Colors.black54,
                              fontSize: 14,
                              height: 1.6,
                            )),

                        const SizedBox(height: 28),

                        // ── Video placeholder ──
                        _videoPlaceholder(context, imageUrl),

                        const SizedBox(height: 28),

                        // ── Steps ──
                        Text('Session Guide',
                            style: TextStyle(
                              color: context.isDark
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 4),
                        Text('${_steps.length} steps — follow in order',
                            style: TextStyle(
                              color: context.isDark
                                  ? Colors.white38
                                  : Colors.black38,
                              fontSize: 12,
                            )),
                        const SizedBox(height: 16),

                        ..._steps.asMap().entries.map((e) =>
                            _stepCard(context, e.key, e.value)),

                        const SizedBox(height: 32),

                        // ── Mark done / undone button ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _canToggle && !_toggling
                                ? _toggleDone
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDone
                                  ? Colors.red.shade700
                                  : _accent(context),
                              disabledBackgroundColor:
                                  Colors.grey.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _toggling
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isDone
                                            ? Icons.close
                                            : Icons.check_circle_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isDone
                                            ? 'Mark as Not Done'
                                            : 'Mark Session as Done',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        // Lock notice for previous days
                        if (_isDone && !_canToggle)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Center(
                              child: Text(
                                'Previous sessions cannot be unmarked',
                                style: TextStyle(
                                  color: context.isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      );

  Widget _videoPlaceholder(BuildContext context, String thumb) => Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
          image: thumb.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(thumb),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(Colors.black.withOpacity(0.45), BlendMode.darken),
                )
              : null,
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _accent(context).withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 34),
          ),
        ),
      );

  Widget _stepCard(BuildContext context, int idx, Map<String, dynamic> step) {
    final stepNum = (step['step_number'] as num?)?.toInt() ?? idx + 1;
    final instruction = step['instruction'] as String? ?? '';
    final tip = step['tip'] as String? ?? '';
    final doTip = step['do_tip'] as String? ?? '';
    final dontTip = step['dont_tip'] as String? ?? '';
    final imageUrl = step['image_url'] as String? ?? '';
    final isChecked = _doneSteps.contains(idx);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isChecked
            ? Border.all(color: _accent(context), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number + check
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _accent(context),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$stepNum',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(instruction,
                          style: TextStyle(
                            color: context.isDark
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          )),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        isChecked
                            ? _doneSteps.remove(idx)
                            : _doneSteps.add(idx);
                      }),
                      child: Icon(
                        isChecked
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isChecked
                            ? _accent(context)
                            : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                if (tip.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(context, Icons.lightbulb_outline, tip,
                      Colors.amber),
                ],
                if (doTip.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(context, Icons.check, doTip, Colors.green),
                ],
                if (dontTip.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(context, Icons.close, dontTip, Colors.red),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
          BuildContext context, IconData icon, String text, Color color) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                  color: context.isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                  height: 1.4,
                )),
          ),
        ],
      );
}