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
  final List<Map<String, dynamic>> challengeRounds, gymSessions;

  const _HistoryDay({
    required this.date,
    this.challengeKcal = 0,
    this.gymKcal       = 0,
    this.yogaKcal      = 0,
    this.totalSecs     = 0,
    this.challengeRounds = const [],
    this.gymSessions     = const [],
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
  List<_HistoryDay>  _recent   = []; // days within current incomplete week
  List<_WeekGroup>   _weeks    = []; // past complete weeks, newest first
  bool _pdfGenerating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    // trigger 2-month auto-clear (fire-and-forget)
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
    )).toList();

    // Split: current partial week (from last Monday) vs complete past weeks
    final now          = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final thisWeekStart = todayMidnight.subtract(Duration(days: todayMidnight.weekday - 1));

    final recent = allDays.where((d) => !d.date.isBefore(thisWeekStart)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Past complete weeks
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

          // Summary header
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

          // Day cards
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

    // Source breakdown
    if (day.challengeKcal > 0)
      rows.add(_pdfSourceRow('Weekly Challenge', day.challengeKcal, day.challengeRounds.length));
    if (day.gymKcal > 0)
      rows.add(_pdfSourceRow('Gym Sessions', day.gymKcal, day.gymSessions.length));
    if (day.yogaKcal > 0)
      rows.add(_pdfSourceRow('Yoga', day.yogaKcal, 0));

    // Rounds detail
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
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              if (_isLoading)
                SliverToBoxAdapter(child: _buildSkeleton(context))
              else ...[
                // ── This Week ───────────────────────────────────────────────
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

                // ── Past Weeks ───────────────────────────────────────────────
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

          // PDF generating overlay
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
//  DAY CARD  (used for "this week" section)
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
    final accent = widget.accent;
    final today  = DateTime.now();
    final isToday = day.date.year == today.year &&
        day.date.month == today.month && day.date.day == today.day;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday ? themeColor.withOpacity(0.5) : Colors.transparent, width: 1.5),
        boxShadow: context.isDark ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
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
                // Date column
                Container(
                  width: 46, height: 52,
                  decoration: BoxDecoration(
                    color: isToday ? themeColor : themeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${day.date.day}',
                      style: TextStyle(
                        color: isToday ? Colors.black : accent,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(_monthAbbr(day.date.month),
                      style: TextStyle(
                        color: isToday ? Colors.black87 : context.subtextColor,
                        fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(_weekdayName(day.date.weekday),
                      style: TextStyle(
                        color: context.textColor, fontSize: 15,
                        fontWeight: FontWeight.bold)),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Today',
                          style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    _miniChip(Icons.local_fire_department_rounded,
                      '${day.totalKcal} kcal', Colors.orange),
                    const SizedBox(width: 6),
                    _miniChip(Icons.timer_rounded,
                      _fmtDuration(day.totalSecs), accent),
                  ]),
                ])),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: context.subtextColor, size: 22),
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
                  _sourcePill(context, Icons.emoji_events_rounded,
                    'Challenge', day.challengeKcal, _challengeColor),
                if (day.gymKcal > 0)
                  _sourcePill(context, Icons.fitness_center_rounded,
                    'Gym', day.gymKcal, _gymColor),
                if (day.yogaKcal > 0)
                  _sourcePill(context, Icons.self_improvement_rounded,
                    'Yoga', day.yogaKcal, _yogaColor),
              ],
            ),
          ),

          // ── Expanded detail ──────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _anim,
            child: Column(children: [
              Divider(height: 1, color: context.isDark ? Colors.grey[800] : Colors.grey[200]),
              const SizedBox(height: 12),

              if (day.challengeRounds.isNotEmpty) ...[
                _detailSection(context, Icons.emoji_events_rounded,
                  'Challenge Rounds', _challengeColor,
                  day.challengeRounds.asMap().entries.map((e) =>
                    _RoundRow(
                      context: context,
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
                _detailSection(context, Icons.fitness_center_rounded,
                  'Gym Sessions', _gymColor,
                  day.gymSessions.asMap().entries.map((e) =>
                    _RoundRow(
                      context: context,
                      index: e.key + 1,
                      label: e.value['title'] as String,
                      kcal: e.value['kcal'] as int,
                      secs: e.value['secs'] as int,
                      color: _gymColor,
                    )
                  ).toList()
                ),
                const SizedBox(height: 12),
              ],

              // Yoga — show total summary (no per-session breakdown stored)
              if (day.yogaKcal > 0) ...[
                _detailSection(context, Icons.self_improvement_rounded,
                  'Yoga', _yogaColor,
                  [
                    _RoundRow(
                      context: context,
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
        ]),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, color: color, size: 12),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  ]);

  Widget _sourcePill(BuildContext context, IconData icon, String label, int kcal, Color color) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text('$label  $kcal kcal',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );

  Widget _detailSection(BuildContext context, IconData icon, String title, Color color,
      List<Widget> rows) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(
            color: context.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ...rows,
      ]),
    );
}

// ── Round row ─────────────────────────────────────────────────────────────────
class _RoundRow extends StatelessWidget {
  final BuildContext context;
  final int index, kcal, secs;
  final Color color;
  final String? label;

  const _RoundRow({
    required this.context,
    required this.index,
    required this.kcal,
    required this.secs,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext _) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text('$index',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label ?? 'Round $index',
          style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
        Row(children: [
          Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 13),
          const SizedBox(width: 3),
          Text('$kcal kcal',
            style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
//  WEEK BAR  (collapsible past-week row)
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

    return Container(
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.isDark ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
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
                            color: d.hasActivity ? themeColor : themeColor.withOpacity(0.2),
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
                      color: context.textColor, fontSize: 14,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text('${week.activeDays} active days  •  ${week.totalKcal} kcal',
                    style: TextStyle(color: context.subtextColor, fontSize: 11)),
                ])),
                // PDF button
                GestureDetector(
                  onTap: onExport,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.picture_as_pdf_rounded, color: accent, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: week.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: context.subtextColor, size: 22),
                ),
              ]),
            ),
          ),

          // ── Week stats strip ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _statChip(context, Icons.local_fire_department_rounded,
                '${week.totalKcal}', 'kcal', Colors.orange),
              const SizedBox(width: 8),
              _statChip(context, Icons.timer_rounded,
                _fmtDuration(week.totalSecs), 'time', accent),
              const SizedBox(width: 8),
              _statChip(context, Icons.calendar_today_rounded,
                '${week.activeDays}/7', 'days', _gymColor),
            ]),
          ),

          // ── Expanded day list ────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(children: [
              Divider(height: 1, color: context.isDark ? Colors.grey[800] : Colors.grey[200]),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
            crossFadeState: week.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ]),
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String value, String unit, Color color) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.08 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(
            color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(color: context.subtextColor, fontSize: 9)),
        ]),
      ]),
    ));
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