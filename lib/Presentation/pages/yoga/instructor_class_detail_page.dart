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

  bool get _isDone => _todayLog?['is_done'] == true;

  bool get _allStepsChecked =>
      _steps.isEmpty || _doneSteps.length == _steps.length;

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
        // If already done, pre-check all steps
        if (log?['is_done'] == true) {
          _doneSteps.addAll(List.generate(steps.length, (i) => i));
        }
      });
    }
  }

  Future<void> _toggleDone() async {
    if (_toggling) return;

    if (!_isDone && !_allStepsChecked) {
      _showStepsWarning();
      return;
    }

    setState(() => _toggling = true);
    try {
      if (_isDone) {
        await SupabaseService.deleteInstructorClassLog(
          classId: widget.classData['id'] as String,
          date: _todayDate,
        );
        if (mounted) {
          setState(() {
            _todayLog = null;
            _doneSteps.clear(); // unlock steps
          });
        }
      } else {
        await SupabaseService.upsertInstructorClassLog(
          classId: widget.classData['id'] as String,
          instructorId: widget.classData['instructor_id'] as String,
          date: _todayDate,
          isDone: true,
          sessionDurationMinutes:
              (widget.classData['duration_minutes'] as num?)?.toInt() ?? 0,
        );
        final log = await SupabaseService.getInstructorClassLog(
          classId: widget.classData['id'] as String,
          date: _todayDate,
        );
        if (mounted) setState(() => _todayLog = log);
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  void _showStepsWarning() {
    final remaining = _steps.length - _doneSteps.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Complete $remaining more step${remaining == 1 ? '' : 's'} first',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
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

    final accent = _accent(context);
    final bgColor =
        context.isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final cardColor =
        context.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = context.isDark ? Colors.white : Colors.black87;
    final subColor = context.isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : CustomScrollView(
              slivers: [
                // ── Hero banner ──
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: accent.withOpacity(0.2)),
                              )
                            : Container(color: accent.withOpacity(0.2)),
                      ),
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
                              backgroundColor: accent.withOpacity(0.2),
                              child: insImage.isEmpty
                                  ? Icon(Icons.person, color: accent)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(insName,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    )),
                                Text(insSpecialty,
                                    style: TextStyle(
                                      color: accent,
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
                                  color: accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 13, color: accent),
                                    const SizedBox(width: 4),
                                    Text(scheduledTime,
                                        style: TextStyle(
                                          color: accent,
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
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        Text(description,
                            style: TextStyle(
                              color: subColor,
                              fontSize: 14,
                              height: 1.6,
                            )),

                        const SizedBox(height: 28),

                        // ── Video placeholder ──
                        _videoPlaceholder(context, imageUrl, accent),

                        const SizedBox(height: 28),

                        // ── Steps header ──
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Session Guide',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isDone
                                        ? 'Session completed — steps locked'
                                        : '${_steps.length} steps — check each before marking done',
                                    style: TextStyle(
                                      color: _isDone
                                          ? accent
                                          : subColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_steps.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _isDone
                                      ? accent.withOpacity(0.15)
                                      : _allStepsChecked
                                          ? accent.withOpacity(0.15)
                                          : Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isDone
                                        ? accent.withOpacity(0.4)
                                        : _allStepsChecked
                                            ? accent.withOpacity(0.4)
                                            : Colors.orange.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isDone
                                          ? Icons.lock
                                          : Icons.lock_open,
                                      size: 11,
                                      color: _isDone
                                          ? accent
                                          : _allStepsChecked
                                              ? accent
                                              : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_doneSteps.length}/${_steps.length}',
                                      style: TextStyle(
                                        color: _isDone
                                            ? accent
                                            : _allStepsChecked
                                                ? accent
                                                : Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ..._steps.asMap().entries.map((e) => _stepCard(
                            context,
                            e.key,
                            e.value,
                            accent,
                            cardColor,
                            textColor,
                            subColor)),

                        const SizedBox(height: 32),

                        // ── Progress bar (only when not done) ──
                        if (!_isDone && _steps.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _steps.isEmpty
                                  ? 0
                                  : _doneSteps.length / _steps.length,
                              backgroundColor: context.isDark
                                  ? Colors.white12
                                  : Colors.black12,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accent),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!_allStepsChecked)
                            Center(
                              child: Text(
                                'Check all ${_steps.length} steps to unlock',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],

                        // ── Mark done / undone button ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: !_toggling ? _toggleDone : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDone
                                  ? Colors.red.shade700
                                  : _allStepsChecked
                                      ? accent
                                      : Colors.grey.withOpacity(0.4),
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
                                            : _allStepsChecked
                                                ? Icons.check_circle_outline
                                                : Icons.lock_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isDone
                                            ? 'Mark as Not Done'
                                            : _allStepsChecked
                                                ? 'Mark Session as Done'
                                                : 'Complete all steps first',
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

                        if (_isDone)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: accent, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Session completed today — only your instructor can view this',
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                style: const TextStyle(
                    color: Colors.white, fontSize: 11)),
          ],
        ),
      );

  Widget _videoPlaceholder(
          BuildContext context, String thumb, Color accent) =>
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
          image: thumb.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(thumb),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.45), BlendMode.darken),
                )
              : null,
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow,
                color: Colors.white, size: 34),
          ),
        ),
      );

  Widget _stepCard(
    BuildContext context,
    int idx,
    Map<String, dynamic> step,
    Color accent,
    Color cardColor,
    Color textColor,
    Color subColor,
  ) {
    final stepNum =
        (step['step_number'] as num?)?.toInt() ?? idx + 1;
    final instruction = step['instruction'] as String? ?? '';
    final tip = step['tip'] as String? ?? '';
    final doTip = step['do_tip'] as String? ?? '';
    final dontTip = step['dont_tip'] as String? ?? '';
    final imageUrl = step['image_url'] as String? ?? '';
    final isChecked = _doneSteps.contains(idx);
    final isSessionDone = _isDone; // freeze when submitted

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isChecked
            ? Border.all(color: accent, width: 1.5)
            : Border.all(
                color: context.isDark
                    ? Colors.white10
                    : Colors.black12),
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
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Step number bubble
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? accent
                            : accent.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$stepNum',
                            style: TextStyle(
                              color: isChecked
                                  ? Colors.white
                                  : context.isDark
                                      ? Colors.white70
                                      : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(instruction,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          )),
                    ),
                    // Checkbox / lock icon
                    GestureDetector(
                      onTap: isSessionDone
                          ? null // locked after submit
                          : () => setState(() {
                                if (isChecked) {
                                  _doneSteps.remove(idx);
                                } else {
                                  _doneSteps.add(idx);
                                }
                              }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: isSessionDone
                            ? Icon(
                                Icons.lock,
                                color: accent,
                                size: 22,
                              )
                            : Icon(
                                isChecked
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isChecked
                                    ? accent
                                    : (context.isDark
                                        ? Colors.white38
                                        : Colors.black26),
                                size: 24,
                              ),
                      ),
                    ),
                  ],
                ),

                if (tip.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(tip, Icons.lightbulb_outline,
                      Colors.amber, subColor),
                ],
                if (doTip.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(doTip, Icons.check_circle_outline,
                      Colors.green, subColor),
                ],
                if (dontTip.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(dontTip, Icons.cancel_outlined,
                      Colors.red, subColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
          String text, IconData icon, Color iconColor, Color textColor) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  height: 1.4,
                )),
          ),
        ],
      );
}