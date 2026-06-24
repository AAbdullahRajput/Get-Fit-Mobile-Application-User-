import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

// ─── accent helper ────────────────────────────────────────────────────────────
Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

const Color _challengeColor = Color(0xFFCCE600);
const Color _gymColor       = Color(0xFF4A90D9);
const Color _yogaColor      = Color(0xFFFF8C42);

// ─── Day model ────────────────────────────────────────────────────────────────
class _HistoryDay {
  final DateTime date;
  final int challengeKcal, gymKcal, yogaKcal, totalSecs;
  final List<Map<String, dynamic>> challengeRounds, gymSessions, yogaSessions;

  const _HistoryDay({
    required this.date,
    this.challengeKcal = 0,
    this.gymKcal       = 0,
    this.yogaKcal      = 0,
    this.totalSecs     = 0,
    this.challengeRounds = const [],
    this.gymSessions     = const [],
    this.yogaSessions    = const [],
  });

  int get totalKcal => challengeKcal + gymKcal + yogaKcal;
  bool get hasActivity => totalKcal > 0 || totalSecs > 0;

  String get formattedDate {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get shortDate {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ─── Week group ───────────────────────────────────────────────────────────────
class _WeekGroup {
  final DateTime weekStart, weekEnd;
  final List<_HistoryDay> days;
  bool isExpanded;

  _WeekGroup({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    this.isExpanded = false,
  });

  int get totalKcal  => days.fold(0, (s, d) => s + d.totalKcal);
  int get activeDays => days.where((d) => d.hasActivity).length;
  int get totalSecs  => days.fold(0, (s, d) => s + d.totalSecs);

  String get label {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[weekStart.month-1]} ${weekStart.day} – ${months[weekEnd.month-1]} ${weekEnd.day}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  RUNNER HISTORY PAGE
// ═════════════════════════════════════════════════════════════════════════════
class RunnerHistoryPage extends StatefulWidget {
  const RunnerHistoryPage({super.key});

  @override
  State<RunnerHistoryPage> createState() => _RunnerHistoryPageState();
}

class _RunnerHistoryPageState extends State<RunnerHistoryPage> {

  bool _isLoading = true;
  List<_HistoryDay>  _recent   = [];
  List<_WeekGroup>   _weeks    = [];
  bool _pdfGenerating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    SupabaseService.clearOldActivityHistory();

    final raw = await SupabaseService.getFullActivityHistory(days: 90);
    final allDays = raw.map((m) => _HistoryDay(
  date:             DateTime.parse(m['date'] as String),
  challengeKcal:    m['challengeKcal'] as int,
  gymKcal:          m['gymKcal'] as int,
  yogaKcal:         m['yogaKcal'] as int,
  totalSecs:        m['totalSecs'] as int,
  challengeRounds:  List<Map<String,dynamic>>.from(m['challengeRounds'] as List),
  gymSessions:      List<Map<String,dynamic>>.from(m['gymSessions'] as List),
  yogaSessions:     List<Map<String,dynamic>>.from(m['yogaSessions'] as List),
)).toList();

    final now           = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final thisWeekStart = todayMidnight.subtract(Duration(days: todayMidnight.weekday - 1));

    final recent = allDays.where((d) => !d.date.isBefore(thisWeekStart)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final past = allDays.where((d) => d.date.isBefore(thisWeekStart)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final List<_WeekGroup> weeks = [];
    if (past.isNotEmpty) {
      DateTime cursor = thisWeekStart.subtract(const Duration(days: 7));
      while (!cursor.isBefore(past.last.date)) {
        final wEnd   = cursor.add(const Duration(days: 6));
        final wDays  = past.where((d) =>
            !d.date.isBefore(cursor) && !d.date.isAfter(wEnd)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        if (wDays.any((d) => d.hasActivity)) {
          weeks.add(_WeekGroup(weekStart: cursor, weekEnd: wEnd, days: wDays));
        }
        cursor = cursor.subtract(const Duration(days: 7));
        if (cursor.isBefore(past.last.date.subtract(const Duration(days: 7)))) break;
      }
    }

    if (mounted) {
      setState(() { _recent = recent; _weeks = weeks; _isLoading = false; });
    }
  }

  // ── PDF export ──────────────────────────────────────────────────────────────
  Future<void> _exportWeekPdf(_WeekGroup week) async {
    setState(() => _pdfGenerating = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Get Fit — Activity Report',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(week.label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        ),
        build: (ctx) {
          final items = <pw.Widget>[];

          items.add(pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFCCE600),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStat('${week.totalKcal}', 'Total Kcal'),
                _pdfStat('${week.activeDays}/7', 'Active Days'),
                _pdfStat(_fmtDuration(week.totalSecs), 'Total Time'),
              ],
            ),
          ));
          items.add(pw.SizedBox(height: 24));

          for (final day in week.days) {
            if (!day.hasActivity) continue;
            items.add(_buildPdfDayCard(day));
            items.add(pw.SizedBox(height: 16));
          }

          return items;
        },
      ));

      final bytes = await pdf.save();
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/getfit_week_${week.weekStart.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'My activity report for ${week.label}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfGenerating = false);
    }
  }

  pw.Widget _pdfStat(String value, String label) => pw.Column(children: [
    pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
    pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
  ]);

  pw.Widget _buildPdfDayCard(_HistoryDay day) {
    final rows = <pw.Widget>[];

    rows.add(pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(day.formattedDate,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.Text('${day.totalKcal} kcal total',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
      ]),
    ));
    rows.add(pw.SizedBox(height: 8));

    if (day.challengeKcal > 0)
      rows.add(_pdfSourceRow('Weekly Challenge', day.challengeKcal, day.challengeRounds.length));
    if (day.gymKcal > 0)
      rows.add(_pdfSourceRow('Gym Sessions', day.gymKcal, day.gymSessions.length));
    if (day.yogaKcal > 0)
      rows.add(_pdfSourceRow('Yoga', day.yogaKcal, 0));

    if (day.challengeRounds.isNotEmpty) {
      rows.add(pw.SizedBox(height: 8));
      rows.add(pw.Text('Challenge Rounds',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)));
      for (int i = 0; i < day.challengeRounds.length; i++) {
        final r = day.challengeRounds[i];
        rows.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, top: 3),
          child: pw.Text(
            'Round ${i+1}  •  ${r['kcal']} kcal  •  ${_fmtDuration(r['secs'] as int)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ));
      }
    }

    if (day.gymSessions.isNotEmpty) {
      rows.add(pw.SizedBox(height: 8));
      rows.add(pw.Text('Gym Sessions',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)));
      for (final s in day.gymSessions) {
        rows.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, top: 3),
          child: pw.Text(
            '${s['title']}  •  ${s['kcal']} kcal  •  ${_fmtDuration(s['secs'] as int)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ));
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows),
    );
  }

  pw.Widget _pdfSourceRow(String label, int kcal, int count) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
      pw.Text('$kcal kcal${count > 0 ? '  ($count sessions)' : ''}',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    ]),
  );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              if (_isLoading)
                SliverToBoxAdapter(child: _buildSkeleton(context))
              else ...[
                if (_recent.any((d) => d.hasActivity)) ...[
                  _sectionHeader(context, 'This Week'),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final day = _recent[i];
                          if (!day.hasActivity) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DayCard(day: day, accent: _accent(context)),
                          );
                        },
                        childCount: _recent.length,
                      ),
                    ),
                  ),
                ],

                if (_weeks.isNotEmpty) ...[
                  _sectionHeader(context, 'Past Weeks'),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _WeekBar(
                            week: _weeks[i],
                            accent: _accent(context),
                            onExport: () => _exportWeekPdf(_weeks[i]),
                            onToggle: () => setState(() =>
                                _weeks[i].isExpanded = !_weeks[i].isExpanded),
                          ),
                        ),
                        childCount: _weeks.length,
                      ),
                    ),
                  ),
                ],

                if (!_isLoading && _recent.every((d) => !d.hasActivity) && _weeks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmpty(context),
                  ),
              ],
            ],
          ),

          if (_pdfGenerating)
            Container(
              color: Colors.black54,
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: themeColor),
                const SizedBox(height: 16),
                Text('Generating PDF…',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              ])),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) => SliverAppBar(
    pinned: true,
    floating: false,
    backgroundColor: context.bgColor,
    elevation: 0,
    automaticallyImplyLeading: false,
    titleSpacing: 0,
    title: Row(children: [
      IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      Text('Activity History',
        style: TextStyle(
          color: _accent(context), fontSize: 20,
          fontWeight: FontWeight.bold, letterSpacing: -0.3)),
    ]),
  );

  Widget _sectionHeader(BuildContext context, String label) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    sliver: SliverToBoxAdapter(
      child: Row(children: [
        Container(width: 3, height: 18,
          decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(
          color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    ),
  );

  Widget _buildSkeleton(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _sh(context, 220), const SizedBox(height: 14),
      _sh(context, 180), const SizedBox(height: 14),
      _sh(context, 100), const SizedBox(height: 14),
      _sh(context, 100),
    ]),
  );

  Widget _sh(BuildContext context, double h) => _ShimmerBox(child: Container(
    height: h,
    decoration: BoxDecoration(
      color: context.isDark ? const Color(0xff2e2e2e) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(16),
    ),
  ));

  Widget _buildEmpty(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history_toggle_off_rounded, color: context.subtextColor, size: 64),
      const SizedBox(height: 16),
      Text('No activity recorded yet',
        style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text('Complete workouts to see your history here',
        style: TextStyle(color: context.subtextColor, fontSize: 13)),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  DAY CARD
// ═════════════════════════════════════════════════════════════════════════════
class _DayCard extends StatefulWidget {
  final _HistoryDay day;
  final Color accent;
  const _DayCard({required this.day, required this.accent});

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final day    = widget.day;
    final today  = DateTime.now();
    final isToday = day.date.year == today.year &&
        day.date.month == today.month && day.date.day == today.day;

    // Card: themeColor in dark, #1A1A1A in light
    final cardBg = context.isDark ? const Color(0xFF2A2A2A) : Colors.white;


    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.07),
            blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: [
          // ── Header row ──────────────────────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                // Date box — black in dark (themeColor card), themeColor in light (dark card)
                Container(
                  width: 46, height: 52,
                  decoration: BoxDecoration(
                    color: context.isDark ? Colors.black : themeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${day.date.day}',
                      style: TextStyle(
                        color: context.isDark ? themeColor : Colors.black,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(_monthAbbr(day.date.month),
                      style: TextStyle(
                        color: context.isDark
                            ? themeColor.withOpacity(0.7)
                            : Colors.black87,
                        fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(_weekdayName(day.date.weekday),
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 15, fontWeight: FontWeight.bold)),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20)),
                        child: Text('Today',
                          style: TextStyle(
                            color: context.isDark ? themeColor : Colors.white,
                            fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    _miniChip(Icons.local_fire_department_rounded,
                      '${day.totalKcal} kcal', context.textColor),
                    const SizedBox(width: 8),
                    _miniChip(Icons.timer_rounded,
                      _fmtDuration(day.totalSecs), context.textColor),
                  ]),
                ])),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: context.textColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: context.textColor, size: 18),
                  ),
                ),
              ]),
            ),
          ),

          // ── Source pills row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 8, runSpacing: 6,
              children: [
                if (day.challengeKcal > 0)
                  _sourcePill(Icons.emoji_events_rounded,
                    'Challenge', day.challengeKcal),
                if (day.gymKcal > 0)
                  _sourcePill(Icons.fitness_center_rounded,
                    'Gym', day.gymKcal),
                if (day.yogaKcal > 0)
                  _sourcePill(Icons.self_improvement_rounded,
                    'Yoga', day.yogaKcal),
              ],
            ),
          ),

          // ── Expanded detail — WHITE section, black text ──────────────────
          SizeTransition(
            sizeFactor: _anim,
            child: Container(
              color: context.isDark ? const Color(0xFF1A1A1A) : Colors.white,
              child: Column(children: [
                const SizedBox(height: 14),

                if (day.challengeRounds.isNotEmpty) ...[
                  _detailSection(context, Icons.emoji_events_rounded,
                    'Challenge Rounds', _challengeColor,
                    day.challengeRounds.asMap().entries.map((e) =>
                      _RoundRow(
                        index: e.key + 1,
                        kcal: e.value['kcal'] as int,
                        secs: e.value['secs'] as int,
                        color: _challengeColor,
                      )
                    ).toList()
                  ),
                  const SizedBox(height: 12),
                ],

                if (day.gymSessions.isNotEmpty) ...[
                  ..._buildGymCategorySections(context, day.gymSessions),
                  const SizedBox(height: 12),
                ],

                if (day.yogaKcal > 0) ...[
                  _detailSection(context, Icons.self_improvement_rounded,
                    'Yoga', _yogaColor,
                    [
                      _RoundRow(
                        index: 1,
                        label: 'Yoga Session',
                        kcal: day.yogaKcal,
                        secs: 0,
                        color: _yogaColor,
                      ),
                    ]
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 4),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, color: color, size: 13),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(
      color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  ]);

  Widget _sourcePill(IconData icon, String label, int kcal) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: context.textColor, size: 13),
        const SizedBox(width: 5),
        Text('$label  $kcal kcal',
          style: TextStyle(
            color: context.textColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );

  Widget _detailSection(BuildContext context, IconData icon, String title,
      Color color, List<Widget> rows) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(
            color: context.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ...rows,
      ]),
    );

  List<Widget> _buildGymCategorySections(BuildContext context,
      List<Map<String, dynamic>> sessions) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final s in sessions) {
      final cat = s['category'] as String? ?? 'Gym';
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    final categoryIcons = {
      'Arms':      Icons.fitness_center_rounded,
      'Back':      Icons.accessibility_new_rounded,
      'Chest':     Icons.self_improvement_rounded,
      'Shoulders': Icons.sports_gymnastics_rounded,
      'Legs':      Icons.directions_run_rounded,
      'Core':      Icons.rotate_right_rounded,
    };

    return grouped.entries.map((entry) {
      final cat    = entry.key;
      final exList = entry.value;
      final icon   = categoryIcons[cat] ?? Icons.fitness_center_rounded;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _detailSection(
          context, icon, cat, _gymColor,
          exList.map((session) {
            final sets = (session['sets'] as List? ?? []);
            return _GymExerciseBlock(
              title: session['title'] as String,
              totalKcal: session['kcal'] as int,
              totalSecs: session['secs'] as int,
              sets: sets.cast<Map<String, dynamic>>(),
              color: _gymColor,
            );
          }).toList(),
        ),
      );
    }).toList();
  }
}

// ── Round row ─────────────────────────────────────────────────────────────────
class _RoundRow extends StatelessWidget {
  final int index, kcal, secs;
  final Color color;
  final String? label;

  const _RoundRow({
    required this.index,
    required this.kcal,
    required this.secs,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,

        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7)),
          child: Center(child: Text('$index',
            style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label ?? 'Round $index',
          style: TextStyle(
            color: context.textColor, fontSize: 12, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
        Row(children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 13),
          const SizedBox(width: 3),
          Text('$kcal kcal',
            style: TextStyle(
              color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Icon(Icons.timer_rounded, color: color, size: 13),
          const SizedBox(width: 3),
          Text(_fmtDuration(secs),
            style: TextStyle(color: color, fontSize: 12)),
        ]),
      ]),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  WEEK BAR
// ═════════════════════════════════════════════════════════════════════════════
class _WeekBar extends StatelessWidget {
  final _WeekGroup week;
  final Color accent;
  final VoidCallback onExport, onToggle;

  const _WeekBar({
    required this.week,
    required this.accent,
    required this.onExport,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final maxKcal = week.days.isEmpty ? 1 :
        week.days.map((d) => d.totalKcal).fold(0, (a, b) => a > b ? a : b);

    // Card: themeColor in dark, #1A1A1A in light
    final cardBg = context.isDark ? const Color(0xFF2A2A2A) : Colors.white;


    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.07),
            blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: [
          // ── Week summary bar ─────────────────────────────────────────────
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(children: [
                // Mini bar chart
                SizedBox(
                  width: 60, height: 36,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: week.days.map((d) {
                      final frac = maxKcal > 0 ? d.totalKcal / maxKcal : 0.0;
                      return Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: (30 * frac).clamp(2.0, 30.0),
                          decoration: BoxDecoration(
                            color: d.hasActivity
                                ? themeColor
                                : context.textColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ));
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(week.label,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text('${week.activeDays} active days  •  ${week.totalKcal} kcal',
                    style: TextStyle(
                      color: context.subtextColor, fontSize: 11)),
                ])),
                // PDF button
                GestureDetector(
                  onTap: onExport,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.picture_as_pdf_rounded,
                      color: context.textColor, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: week.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: context.textColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: context.textColor, size: 18),
                  ),
                ),
              ]),
            ),
          ),

          // ── Week stats strip ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _statChip(context, Icons.local_fire_department_rounded,
                '${week.totalKcal}', 'kcal'),
              const SizedBox(width: 8),
              _statChip(context, Icons.timer_rounded,
                _fmtDuration(week.totalSecs), 'time'),
              const SizedBox(width: 8),
              _statChip(context, Icons.calendar_today_rounded,
                '${week.activeDays}/7', 'days'),
            ]),
          ),

          // ── Expanded day list — WHITE section ────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              color: context.isDark ? const Color(0xFF1A1A1A) : Colors.white,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Column(
                    children: week.days.where((d) => d.hasActivity).map((day) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DayCard(day: day, accent: accent),
                      )
                    ).toList(),
                  ),
                ),
              ]),
            ),
            crossFadeState: week.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ]),
      ),
    );
  }

    Widget _statChip(BuildContext context, IconData icon, String value, String unit) =>

    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, color: context.textColor, size: 13),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(
            color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(
            color: context.subtextColor, fontSize: 9)),
        ]),
      ]),
    ));
}

// ─── Gym exercise block ───────────────────────────────────────────────────────
class _GymExerciseBlock extends StatelessWidget {
  final String title;
  final int totalKcal, totalSecs;
  final List<Map<String, dynamic>> sets;
  final Color color;

  const _GymExerciseBlock({
    required this.title,
    required this.totalKcal,
    required this.totalSecs,
    required this.sets,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,

      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.fitness_center_rounded, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title,
          style: TextStyle(
            color: context.textColor, fontSize: 13, fontWeight: FontWeight.bold))),
        Row(children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 13),
          const SizedBox(width: 3),
          Text('$totalKcal kcal',
            style: TextStyle(
              color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Icon(Icons.timer_rounded, color: color, size: 13),
          const SizedBox(width: 3),
          Text(_fmtDuration(totalSecs),
            style: TextStyle(color: color, fontSize: 12)),
        ]),
      ]),
      if (sets.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(height: 1, color: color.withOpacity(0.12),
          margin: const EdgeInsets.only(bottom: 6)),
        ...sets.map((s) {
          final setNum = s['setNumber'] as int? ?? 0;
          final reps   = s['reps'] as int? ?? 0;
          final kcal   = s['kcal'] as int? ?? 0;
          final secs   = s['secs'] as int? ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('$setNum',
                  style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 8),
              Text('Set $setNum  •  $reps reps',
                style: TextStyle(color: context.subtextColor, fontSize: 11)),
              const Spacer(),
              Text('$kcal kcal',
                style: const TextStyle(
                  color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Text(_fmtDuration(secs),
                style: TextStyle(color: color, fontSize: 11)),
            ]),
          );
        }),
      ],
    ]),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _fmtDuration(int secs) {
  final h = secs ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  final s = secs % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}

String _weekdayName(int wd) {
  const names = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  return names[(wd - 1).clamp(0, 6)];
}

String _monthAbbr(int m) {
  const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
  return months[(m - 1).clamp(0, 11)];
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final Widget child;
  const _ShimmerBox({required this.child});
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _anim, child: widget.child);
}