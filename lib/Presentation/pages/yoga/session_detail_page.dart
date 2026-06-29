import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/yoga/instructor_class_detail_page.dart';


Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

class SessionDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> instructor;
  

  const SessionDetailPage({
    super.key,
    required this.booking,
    required this.instructor,
  });

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  List<Map<String, dynamic>> _classes = [];
  Map<String, List<Map<String, dynamic>>> _slotsByClass = {};
  Map<String, Map<String, dynamic>> _attendanceByClass = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _ticker;
  Set<String> _feedClassIds = {};

  String get _sessionId =>
      widget.booking['session_id'] as String? ?? '';
  String get _bookingId =>
      widget.booking['id'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _load();
    // tick every second for countdown
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    // First load: show full loader. Subsequent loads: background refresh (keep content visible)
    if (_classes.isEmpty) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    final classes = await SupabaseService.getSessionClasses(_sessionId);

    // load slots for each class
    final Map<String, List<Map<String, dynamic>>> slotsByClass = {};
    for (final cls in classes) {
      final slots = await SupabaseService.getClassSlots(cls['id'] as String);
      slotsByClass[cls['id'] as String] = slots;
    }

    // Check instructor_class_logs (what InstructorClassDetailPage writes)
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final Map<String, Map<String, dynamic>> attendanceByClass = {};
    for (final cls in classes) {
      final paidClass = cls['instructor_paid_classes'] as Map<String, dynamic>?;
      if (paidClass == null) continue;
      final paidClassId = paidClass['id'] as String;
      final log = await SupabaseService.getInstructorClassLog(
        classId: paidClassId,
        date: today,
      );
      if (log != null && log['is_done'] == true) {
        attendanceByClass[cls['id'] as String] = {'status': 'done'};
      }
    }

    final feedClasses = await SupabaseService.getUserFeedClasses();

    if (mounted) {
      setState(() {
        _classes = classes;
        _slotsByClass = slotsByClass;
        _attendanceByClass = attendanceByClass;
        _feedClassIds = feedClasses.map((f) => f['class_id'] as String).toSet();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  bool _isSlotActive(Map<String, dynamic> slot) {
    final now = DateTime.now();
    final dateStr = slot['slot_date'] as String;
    final startStr = slot['start_time'] as String;
    final endStr = slot['end_time'] as String;

    if (dateStr.length < 10) return false;
    final start = DateTime.tryParse('${dateStr.substring(0, 10)}T$startStr') ?? DateTime(2000);
    final end = DateTime.tryParse('${dateStr.substring(0, 10)}T$endStr') ?? DateTime(2000);

    return now.isAfter(start) && now.isBefore(end);
  }

  bool _isSlotExpired(Map<String, dynamic> slot) {
    final now = DateTime.now();
    final dateStr = slot['slot_date'] as String;
    final endStr = slot['end_time'] as String;
    if (dateStr.length < 10) return true;
    final end = DateTime.tryParse('${dateStr.substring(0, 10)}T$endStr') ?? DateTime(2000);
    return now.isAfter(end);
  }

  Duration _timeUntilSlot(Map<String, dynamic> slot) {
    final dateStr = slot['slot_date'] as String;
    final startStr = slot['start_time'] as String;
    if (dateStr.length < 10) return Duration.zero;
    final start = DateTime.tryParse('${dateStr.substring(0, 10)}T$startStr') ?? DateTime(2000);
    final diff = start.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String _fmtCountdown(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
    return '${d.inMinutes % 60}m ${d.inSeconds % 60}s';
  }

  String _fmtTime(String timeStr) {
    final parts = timeStr.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
    return '$h12:$m $period';
  }

  String _fmtDate(String dateStr) {
    if (dateStr.isEmpty) return '—';
    final dt = DateTime.tryParse(dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr) ?? DateTime(2000);
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }

  Future<void> _toggleDone(
    Map<String, dynamic> cls, Map<String, dynamic> slot) async {
  final classId = cls['id'] as String;
  final existing = _attendanceByClass[classId];
  final isDone = existing?['status'] == 'done';
  final paidClass = cls['instructor_paid_classes'] as Map<String, dynamic>?;
  if (paidClass == null) return;
  final today = DateTime.now().toIso8601String().substring(0, 10);

  try {
    if (isDone) {
      await SupabaseService.deleteInstructorClassLog(
        classId: paidClass['id'] as String,
        date: today,
      );
    } else {
      await SupabaseService.upsertInstructorClassLog(
        classId: paidClass['id'] as String,
        instructorId: paidClass['instructor_id'] as String,
        date: today,
        isDone: true,
        sessionDurationMinutes:
            (cls['duration_minutes'] as num?)?.toInt() ?? 60,
      );
    }
    await _load();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update. Try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

  bool _isSessionExpired() {
    final session = widget.booking['instructor_sessions'] as Map<String, dynamic>?;
    if (session == null) return false;
    final endStr = session['session_end'] as String?;
    if (endStr == null) return false;
    final end = DateTime.parse(endStr);
    return DateTime.now().isAfter(end.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.booking['instructor_sessions'] as Map<String, dynamic>?;
    final title = session?['title'] as String? ?? 'Session';
    final sessionStart = session?['session_start'] as String? 
    ?? session?['start_date'] as String? 
    ?? widget.booking['start_date'] as String? ?? '';
final sessionEnd = session?['session_end'] as String? 
    ?? session?['end_date'] as String? 
    ?? widget.booking['expires_at'] as String? ?? '';
    final accent = _accent(context);
    final isExpired = _isSessionExpired();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
            child: Row(children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10),
                  backgroundColor: Colors.black54,
                  elevation: 0,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: themeColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              // Background refresh indicator
              if (_isRefreshing)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  ),
                ),
              if (isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: const Text('Expired',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
            ]),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accent))
                : RefreshIndicator(
                    color: themeColor,
                    backgroundColor: context.cardBgColor,
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Session info card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.grey.withOpacity(0.1)
                                  : themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isExpired
                                    ? Colors.grey.withOpacity(0.3)
                                    : themeColor.withOpacity(0.3),
                              ),
                            ),
                            child: Column(children: [
                              Row(children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: themeColor,
                                  backgroundImage: (widget.instructor['image_url'] ?? '')
                                          .isNotEmpty
                                      ? NetworkImage(widget.instructor['image_url'])
                                      : null,
                                  child: (widget.instructor['image_url'] ?? '').isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.black)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.instructor['name'] ?? '',
                                        style: TextStyle(
                                            color: context.textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      Text(
                                        widget.instructor['specialty'] ?? '',
                                        style: TextStyle(
                                            color: context.subtextColor,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                _infoChip(context,
                                    Icons.calendar_today_rounded,
                                    _fmtDate(sessionStart), accent),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward,
                                    color: accent, size: 14),
                                const SizedBox(width: 8),
                                _infoChip(context,
                                    Icons.flag_rounded,
                                    _fmtDate(sessionEnd), accent),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                _infoChip(context,
                                    Icons.class_outlined,
                                    '${_classes.length} classes', accent),
                                const SizedBox(width: 8),
                                _infoChip(context,
                                    Icons.check_circle_outline,
                                    '${_attendanceByClass.values.where((a) => a['status'] == 'done').length} done',
                                    Colors.green),
                              ]),
                            ]),
                          ),
                          const SizedBox(height: 24),

                          Text('Classes',
                              style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),

                          if (_classes.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: context.cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(children: [
                                Icon(Icons.self_improvement,
                                    color: accent, size: 40),
                                const SizedBox(height: 12),
                                Text('No classes in this session yet',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 14)),
                              ]),
                            )
                          else
                            ..._classes.map((cls) =>
                                _buildClassCard(context, cls, accent, isExpired)),
                        ],
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

Widget _buildClassCard(BuildContext context, Map<String, dynamic> cls,
    Color accent, bool sessionExpired) {
  final classId   = cls['id'] as String;
  final slots     = _slotsByClass[classId] ?? [];
  final attendance = _attendanceByClass[classId];
  final isDone    = attendance?['status'] == 'done';

  // linked paid class data
  final paidClass = cls['instructor_paid_classes'] as Map<String, dynamic>?;
  final imageUrl  = paidClass?['image_url'] as String? ?? cls['image_url'] as String? ?? '';
  final level     = paidClass?['level'] as String? ?? '';
  final classType = paidClass?['class_type'] as String? ?? '';

  // find active slot
  final activeSlot = slots.firstWhere(
    (s) => _isSlotActive(s),
    orElse: () => {},
  );
  final hasActiveSlot = activeSlot.isNotEmpty;
  final isInFeed = _feedClassIds.contains(paidClass?['id'] as String? ?? '');

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: context.cardBgColor,
      borderRadius: BorderRadius.circular(18),
      border: isDone
          ? Border.all(color: accent, width: 1.5)
          : hasActiveSlot
              ? Border.all(color: Colors.green, width: 1.5)
              : Border.all(color: context.isDark ? Colors.white10 : Colors.black12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Image
      if (imageUrl.isNotEmpty)
        Stack(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          if (level.isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(level,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          if (classType.isNotEmpty)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(classType,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          if (isDone)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, color: Colors.black, size: 12),
                  const SizedBox(width: 4),
                  const Text('Done',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
        ]),

      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title
          Text(cls['title'] as String? ?? '',
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),

          if ((cls['description'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(cls['description'] as String,
                style: TextStyle(
                    color: context.subtextColor, fontSize: 12, height: 1.4)),
          ],

          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.calendar_today_rounded, color: accent, size: 13),
            const SizedBox(width: 6),
            Text(_fmtDate(cls['class_date'] as String? ?? ''),
                style: TextStyle(color: context.subtextColor, fontSize: 12)),
            const SizedBox(width: 14),
            Icon(Icons.timer_outlined, color: accent, size: 13),
            const SizedBox(width: 6),
            Text('${cls['duration_minutes']} min',
                style: TextStyle(color: context.subtextColor, fontSize: 12)),
          ]),

          const SizedBox(height: 14),
          Text('Time Slots',
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          if (slots.isEmpty)
            Text('No time slots defined',
                style: TextStyle(color: context.subtextColor, fontSize: 12))
          else
            ...slots.map((slot) => _buildSlotRow(
                context, cls, slot, accent, isDone, sessionExpired)),

          // Add to Feed + Join buttons — only if has active slot and paid class linked
          if (hasActiveSlot && paidClass != null && !sessionExpired) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final pid = paidClass['id'] as String;
                    try {
                      if (isInFeed) {
                        await SupabaseService.removeClassFromFeed(pid);
                        setState(() => _feedClassIds.remove(pid));
                      } else {
                        await SupabaseService.addClassToFeed(
                          classId: pid,
                          instructorId: paidClass['instructor_id'] as String,
                        );
                        setState(() => _feedClassIds.add(pid));
                      }
                    } catch (_) {}
                  },
                  icon: Icon(
                    isInFeed ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    size: 16,
                  ),
                  label: Text(isInFeed ? 'Remove' : 'Add to Feed'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isInFeed ? Colors.red : accent,
                    side: BorderSide(
                        color: isInFeed
                            ? Colors.red.withOpacity(0.5)
                            : accent.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InstructorClassDetailPage(
                        classData: paidClass,
                        instructorData: widget.instructor,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Join'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ],
        ]),
      ),
    ]),
  );
}

  Widget _buildSlotRow(BuildContext context, Map<String, dynamic> cls,
      Map<String, dynamic> slot, Color accent,
      bool classIsDone, bool sessionExpired) {
    final isActive = _isSlotActive(slot);
    final isExpired = _isSlotExpired(slot);
    final countdown = _timeUntilSlot(slot);
    final canInteract = isActive && !sessionExpired;

    Color slotColor;
    String statusLabel;
    IconData statusIcon;

    if (sessionExpired || isExpired) {
      slotColor = Colors.grey;
      statusLabel = 'Expired';
      statusIcon = Icons.lock_clock;
    } else if (isActive) {
      slotColor = Colors.green;
      statusLabel = 'Live Now';
      statusIcon = Icons.play_circle_fill;
    } else {
      slotColor = accent;
      statusLabel = _fmtCountdown(countdown);
      statusIcon = Icons.access_time;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.08)
            : context.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.4)
              : context.isDark
                  ? Colors.white12
                  : Colors.black12,
        ),
      ),
      child: Row(children: [
        // Time range
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${_fmtTime(slot['start_time'] as String)} → ${_fmtTime(slot['end_time'] as String)}',
            style: TextStyle(
                color: context.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Icon(statusIcon, color: slotColor, size: 12),
            const SizedBox(width: 4),
            Text(statusLabel,
                style: TextStyle(
                    color: slotColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ]),
        ]),

        const Spacer(),

        // Mark done button (only active slots)
        if (canInteract)
          GestureDetector(
            onTap: () => _toggleDone(cls, slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: classIsDone
                    ? Colors.red.withOpacity(0.15)
                    : themeColor,
                borderRadius: BorderRadius.circular(10),
                border: classIsDone
                    ? Border.all(color: Colors.red.withOpacity(0.4))
                    : null,
              ),
              child: Text(
                classIsDone ? 'Unmark' : 'Mark Done',
                style: TextStyle(
                    color: classIsDone ? Colors.red : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        else if (isActive && sessionExpired)
          const SizedBox.shrink()
        else if (!isExpired && !sessionExpired)
          // countdown pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label,
      Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}