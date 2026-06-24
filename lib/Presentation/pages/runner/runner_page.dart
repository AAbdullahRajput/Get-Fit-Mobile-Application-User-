import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/runner/runner_history_page.dart';

// ─── accent ────────────────────────────────────────────────────────────────────
Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

const Color _challengeColor = Color(0xFFCCE600);
const Color _gymColor       = Color(0xFF4A90D9);
const Color _yogaColor      = Color(0xFFFF8C42);

// ─── Day model ─────────────────────────────────────────────────────────────────
class _DayStat {
  final String   label;
  final DateTime date;
  final int challengeKcal, gymKcal, yogaKcal, challengeSec, gymSec;

  const _DayStat({
    required this.label, required this.date,
    this.challengeKcal = 0, this.gymKcal = 0, this.yogaKcal = 0,
    this.challengeSec  = 0, this.gymSec  = 0,
  });

  int get totalKcal => challengeKcal + gymKcal + yogaKcal;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RUNNER PAGE
// ═══════════════════════════════════════════════════════════════════════════════
class RunnerPage extends StatefulWidget {
  const RunnerPage({super.key});
  @override
  State<RunnerPage> createState() => _RunnerPageState();
}

class _RunnerPageState extends State<RunnerPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── filter ─────────────────────────────────────────────────────────────────
  static const _filters    = ['1D', '7D', '14D', '1M'];
  static const _filterDays = [1, 7, 14, 30, 90];
  int _filterIdx = 1; // default 7D

  // ── state ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  List<_DayStat> _stats = [];
  int? _selectedIdx;

  // ── derived ────────────────────────────────────────────────────────────────
  int get _days => _filterDays[_filterIdx];

  int get _todayAutoIdx {
    if (_stats.isEmpty) return -1;
    final t = DateTime.now();
    final i = _stats.indexWhere(
        (d) => d.date.year == t.year && d.date.month == t.month && d.date.day == t.day);
    return i >= 0 ? i : _stats.length - 1;
  }

  _DayStat? get _selectedStat {
    if (_stats.isEmpty) return null;
    final idx = _selectedIdx ?? _todayAutoIdx;
    if (idx < 0 || idx >= _stats.length) return null;
    return _stats[idx];
  }

  int get _effectiveIdx  => _selectedIdx ?? _todayAutoIdx;
  int get _selKcal       => _selectedStat?.totalKcal  ?? 0;
  int get _selSeconds    => (_selectedStat?.challengeSec ?? 0) + (_selectedStat?.gymSec ?? 0);
  int get _totalKcal     => _stats.fold(0, (s, d) => s + d.totalKcal);
  int get _totalSeconds  => _stats.fold(0, (s, d) => s + d.challengeSec + d.gymSec);
  int get _activeDays    => _stats.where((d) => d.totalKcal > 0).length;

  @override
  void initState() {
    super.initState();
    if (_filterIdx >= _filters.length) _filterIdx = 1;
    _load();
  }

  Future<void> _load() async {
    final currentDays = _days;
    setState(() { _isLoading = true; _selectedIdx = null; });
    final raw = await SupabaseService.getActivityStats(days: currentDays);
    final stats = raw.map((m) => _DayStat(
      label:         m['label']         as String,
      date:          DateTime.parse(m['date'] as String),
      challengeKcal: m['challengeKcal'] as int,
      gymKcal:       m['gymKcal']       as int,
      yogaKcal:      m['yogaKcal']      as int,
      challengeSec:  m['challengeSec']  as int,
      gymSec:        m['gymSec']        as int,
    )).toList();
    if (mounted) setState(() { _stats = stats; _isLoading = false; });
  }

  void _tapBar(int i) {
    if (_selectedIdx == i) return;
    setState(() => _selectedIdx = i);
  }

  void _goHistory() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const RunnerHistoryPage()),
  );

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: themeColor,
          backgroundColor: context.cardBgColor,
          displacement: 80,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildFilterTabs(context),
              const SizedBox(height: 18),
              if (_isLoading)
                _buildSkeleton(context)
              else ...[
                _buildCaloriesCard(context),
                const SizedBox(height: 14),
                _buildSelectedDayCard(context),
                const SizedBox(height: 14),
                _buildDurationCard(context),
                const SizedBox(height: 14),
                _buildSourceCard(context),
                const SizedBox(height: 14),
                _buildRangeOverview(context),
                const SizedBox(height: 22),
                _buildDivider(context, 'Stopwatch'),
                const SizedBox(height: 14),
                const _StopwatchCard(),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ── header — 3-dots replaces history icon button ───────────────────────────
  Widget _buildHeader(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Activities',
        style: TextStyle(
          color: _accent(context), fontSize: 26, fontWeight: FontWeight.bold)),
      Text('Tap a bar to see that day\'s breakdown',
        style: TextStyle(color: context.subtextColor, fontSize: 12)),
    ])),
    PopupMenuButton<String>(
      onSelected: (val) { if (val == 'history') _goHistory(); },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: context.isDark ? const Color(0xFF2A2A2A) : Colors.white,
      icon: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_vert_rounded,
            color: context.isDark ? Colors.white : Colors.black, size: 20),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'history',
          child: Row(children: [
            Icon(Icons.history_rounded, color: _accent(context), size: 18),
            const SizedBox(width: 10),
            Text('View History',
                style: TextStyle(
                    color: context.isDark ? Colors.white : Colors.black,
                    fontSize: 14)),
          ]),
        ),
      ],
    ),
  ]);

  // ── filter tabs ────────────────────────────────────────────────────────────
  Widget _buildFilterTabs(BuildContext context) => Container(
    height: 42,
    decoration: BoxDecoration(
      color: context.cardBgColor, borderRadius: BorderRadius.circular(24)),
    child: Row(
      children: List.generate(_filters.length, (i) {
        final sel = _filterIdx == i;
        return Expanded(child: GestureDetector(
          onTap: () async { if (_filterIdx != i) { setState(() { _filterIdx = i; _selectedIdx = null; }); await _load(); } },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: sel ? themeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Text(_filters[i],
              style: TextStyle(
                color: sel ? Colors.black : context.subtextColor,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ))),
          ),
        ));
      }),
    ),
  );

  // ── calories card — themeColor bg, striped unselected bars, solid black selected ──
  Widget _buildCaloriesCard(BuildContext context) {
    final maxKcal = _stats.isEmpty ? 1 :
        _stats.map((d) => d.totalKcal.toDouble()).fold<double>(0, (a, b) => a > b ? a : b);
    final count     = _stats.length;
    final showEvery = count <= 7 ? 1 : count <= 14 ? 2 : 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: themeColor, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // title row — filled fire icon, 3-dots history button
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.local_fire_department_rounded, color: Colors.black, size: 22),
            const SizedBox(width: 8),
            const Text('Calories Burn',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          GestureDetector(
            onTap: _goHistory,
            child: Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: RichText(
            key: ValueKey(_selKcal),
            text: TextSpan(children: [
              TextSpan(text: '$_selKcal',
                style: const TextStyle(
                  color: Colors.black, fontSize: 38, fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto')),
              const TextSpan(text: '  Kcal',
                style: TextStyle(color: Color(0xFF556600), fontSize: 16, fontFamily: 'Roboto')),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        // bars
        if (_stats.isEmpty)
          const SizedBox(height: 100,
            child: Center(child: Text('No data yet',
              style: TextStyle(color: Color(0xFF556600)))))
        else SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(count, (i) {
              final d    = _stats[i];
              final frac = maxKcal > 0 ? d.totalKcal / maxKcal : 0.0;
              final isSel = i == _effectiveIdx;
              return Expanded(child: GestureDetector(
                onTap: () => _tapBar(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      height: (110 * frac).clamp(6.0, 110.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isSel
                            ? Container(color: Colors.black)
                            : CustomPaint(painter: _StripePainter(), child: Container()),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (i % showEvery == 0)
                      Text(d.label, style: TextStyle(
                        color: isSel ? Colors.black : const Color(0xFF556600),
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ))
                    else const SizedBox(height: 13),
                  ]),
                ),
              ));
            }),
          ),
        ),
      ]),
    );
  }

  // ── selected day card — solid bg, filled icon boxes, no glass ─────────────
  Widget _buildSelectedDayCard(BuildContext context) {
    final stat  = _selectedStat;
    final mins  = _selSeconds ~/ 60;
    final hrs   = mins ~/ 60;
    final remM  = mins % 60;
    final tStr  = hrs > 0 ? '${hrs}h ${remM}m' : '${mins}m';
    final today = DateTime.now();
    final selD  = stat?.date;
    final isToday = selD != null &&
        selD.year == today.year && selD.month == today.month && selD.day == today.day;
    const dayNames = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    String dayLabel = 'Today';
    if (selD != null && !isToday) {
      dayLabel = _days <= 7
          ? dayNames[selD.weekday - 1]
          : '${selD.day}/${selD.month}/${selD.year}';
    }

    // solid card colors
    final cardBg  = context.isDark ? Colors.white       : const Color(0xFF1A1A1A);
    final textCol = context.isDark ? Colors.black        : Colors.white;
    final subCol  = context.isDark ? Colors.black54      : Colors.white60;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(_effectiveIdx),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: themeColor, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.black, size: 15),
              ),
              const SizedBox(width: 8),
              Text(dayLabel, style: TextStyle(
                color: textCol, fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.isDark ? Colors.black : themeColor,
                  borderRadius: BorderRadius.circular(20)),
                child: Text('Today',
                  style: TextStyle(
                    color: context.isDark ? themeColor : Colors.black,
                    fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _dayPill(context, Icons.local_fire_department_rounded,
              '$_selKcal', 'kcal', Colors.orange, textCol, subCol),
            const SizedBox(width: 10),
            _dayPill(context, Icons.timer_rounded,
              tStr, 'active', themeColor, textCol, subCol),
            const SizedBox(width: 10),
            _dayPill(context, Icons.fitness_center_rounded,
              '${stat?.gymKcal ?? 0}', 'gym kcal', _gymColor, textCol, subCol),
          ]),
        ]),
      ),
    );
  }

  Widget _dayPill(BuildContext context, IconData icon, String value,
      String unit, Color color, Color textCol, Color subCol) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.18 : 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
          color: textCol, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(unit, style: TextStyle(color: subCol, fontSize: 10)),
      ]),
    ));

  // ── duration card — solid bg, filled icon box ──────────────────────────────
  Widget _buildDurationCard(BuildContext context) {
    if (_stats.isEmpty) return const SizedBox.shrink();
    final selMins  = _selSeconds ~/ 60;
    final maxMins  = _stats
        .map((d) => (d.challengeSec + d.gymSec) / 60.0)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final count     = _stats.length;
    final showEvery = count <= 7 ? 1 : count <= 14 ? 2 : 5;
    final accent    = _accent(context);

    final cardBg = context.isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // filled square icon box
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.timer_rounded, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Workout Duration',
              style: TextStyle(
                color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text('${selMins}m selected',
                key: ValueKey(selMins),
                style: TextStyle(color: context.subtextColor, fontSize: 11)),
            ),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(count, (i) {
              final d    = _stats[i];
              final mins = (d.challengeSec + d.gymSec) / 60.0;
              final frac = maxMins > 0 ? mins / maxMins : 0.0;
              final isSel = i == _effectiveIdx;
              return Expanded(child: GestureDetector(
                onTap: () => _tapBar(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      height: (90 * frac).clamp(4.0, 90.0),
                      decoration: BoxDecoration(
                        color: isSel ? accent : accent.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (i % showEvery == 0)
                      Text(d.label, style: TextStyle(
                        color: isSel ? accent : context.subtextColor,
                        fontSize: 9,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ))
                    else const SizedBox(height: 12),
                  ]),
                ),
              ));
            }),
          ),
        ),
      ]),
    );
  }

  // ── source card — solid bg, filled icon boxes, progress bars ──────────────
  Widget _buildSourceCard(BuildContext context) {
    final stat  = _selectedStat;
    final c = stat?.challengeKcal ?? 0;
    final g = stat?.gymKcal       ?? 0;
    final y = stat?.yogaKcal      ?? 0;
    final total = c + g + y;

    final cardBg = context.isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey('src_$_effectiveIdx'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: context.isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Calories by Source',
            style: TextStyle(
              color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _sourceRow(context, Icons.emoji_events_rounded,
            'Weekly Challenge', c, total, _challengeColor),
          const SizedBox(height: 14),
          _sourceRow(context, Icons.fitness_center_rounded,
            'Gym Exercises', g, total, _gymColor),
          const SizedBox(height: 14),
          _sourceRow(context, Icons.self_improvement_rounded,
            'Yoga', y, total, _yogaColor),
        ]),
      ),
    );
  }

  Widget _sourceRow(BuildContext context, IconData icon, String label,
      int kcal, int total, Color color) {
    final pct = total > 0 ? kcal / total : 0.0;
    return Row(children: [
      // filled square icon box
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(
            color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
          Text('$kcal kcal', style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct, minHeight: 6,
            backgroundColor: context.isDark ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ])),
    ]);
  }

  // ── range overview — solid bg, filled icons ────────────────────────────────
  Widget _buildRangeOverview(BuildContext context) {
    final mins  = _totalSeconds ~/ 60;
    final hrs   = mins ~/ 60;
    final remM  = mins % 60;
    final tStr  = hrs > 0 ? '${hrs}h ${remM}m' : '${mins}m';

    final cardBg  = context.isDark ? const Color(0xFF222222) : Colors.grey.shade100;
    final headCol = context.isDark ? Colors.white : Colors.black;
    final subCol  = context.isDark ? Colors.white60 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(22),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_filterIdx < _filters.length ? _filters[_filterIdx] : _filters.last} Overview',
          style: TextStyle(
            color: headCol, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(children: [
          _overviewStat(context, Icons.local_fire_department_rounded,
            '$_totalKcal', 'Total kcal', Colors.orange),
          _vSep(context),
          _overviewStat(context, Icons.timer_rounded, tStr, 'Total time', _accent(context)),
          _vSep(context),
          _overviewStat(context, Icons.event_available_rounded,
            '$_activeDays', 'Active days', _gymColor),
        ]),
      ]),
    );
  }

  Widget _overviewStat(BuildContext context, IconData icon, String value,
      String label, Color color) =>
    Expanded(child: Column(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(
        color: context.textColor, fontSize: 17, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: context.subtextColor, fontSize: 10)),
    ]));

  Widget _vSep(BuildContext context) => Container(
    width: 1, height: 50,
    color: context.isDark ? Colors.grey[800] : Colors.grey[300]);

  Widget _buildDivider(BuildContext context, String label) => Row(children: [
    Expanded(child: Divider(
      color: context.isDark ? Colors.grey[800] : Colors.grey[300])),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(label, style: TextStyle(
        color: _accent(context), fontSize: 14,
        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    ),
    Expanded(child: Divider(
      color: context.isDark ? Colors.grey[800] : Colors.grey[300])),
  ]);

  Widget _buildSkeleton(BuildContext context) => Column(children: [
    _sh(context, 220), const SizedBox(height: 14),
    _sh(context, 100), const SizedBox(height: 14),
    _sh(context, 160), const SizedBox(height: 14),
    _sh(context, 140),
  ]);

  Widget _sh(BuildContext context, double h) => _ShimmerBox(child: Container(
    height: h,
    decoration: BoxDecoration(
      color: context.isDark ? const Color(0xff2e2e2e) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
    ),
  ));
}

// ─── Stripe painter (diagonal hatching for unselected bars) ────────────────────
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
      Paint()..color = const Color(0xFFB8CC00));
    final p = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    const spacing = 10.0;
    final span    = size.width + size.height;
    for (double s = -size.height; s < span; s += spacing) {
      canvas.drawLine(Offset(s, 0), Offset(s + size.height, size.height), p);
    }
  }
  @override
  bool shouldRepaint(_StripePainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STOPWATCH CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _StopwatchCard extends StatefulWidget {
  const _StopwatchCard();
  @override
  State<_StopwatchCard> createState() => _StopwatchCardState();
}

class _StopwatchCardState extends State<_StopwatchCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Stopwatch _sw = Stopwatch();
  Timer?   _ticker;
  Duration _elapsed = Duration.zero;
  bool     _running = false;
  final List<Duration> _laps = [];

  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }

  void _start() {
    _sw.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _elapsed = _sw.elapsed);
    });
    setState(() => _running = true);
  }

  void _pause() {
    _sw.stop(); _ticker?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _sw.stop(); _sw.reset(); _ticker?.cancel();
    setState(() { _elapsed = Duration.zero; _running = false; _laps.clear(); });
  }

  void _lap() {
    if (_running) setState(() => _laps.insert(0, _sw.elapsed));
  }

  String _fmt(Duration d) {
    final h  = d.inHours;
    final m  = d.inMinutes % 60;
    final s  = d.inSeconds % 60;
    final ms = (d.inMilliseconds % 1000) ~/ 10;
    if (h > 0)
      return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}.${ms.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final accent = _accent(context);
    final isZero = _elapsed == Duration.zero;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardBgColor, borderRadius: BorderRadius.circular(24),
        boxShadow: context.isDark ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // dial
        SizedBox(width: 200, height: 200,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 200, height: 200,
              child: CircularProgressIndicator(value: 1, strokeWidth: 10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.isDark ? Colors.grey[800]! : Colors.grey[200]!))),
            SizedBox(width: 200, height: 200,
              child: CircularProgressIndicator(
                value: (_elapsed.inMilliseconds % 60000) / 60000,
                strokeWidth: 10, strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _running ? themeColor : accent.withOpacity(0.5)),
              )),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_fmt(_elapsed),
                style: TextStyle(
                  color: context.textColor,
                  fontSize: isZero ? 32 : 28,
                  fontWeight: FontWeight.bold, letterSpacing: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
              const SizedBox(height: 4),
              Text(_running ? 'Running' : isZero ? 'Ready' : 'Paused',
                style: TextStyle(
                  color: _running ? themeColor : context.subtextColor,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ])),
        const SizedBox(height: 28),
        // controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _swBtn(context, Icons.refresh_rounded,
            context.isDark ? Colors.grey[800]! : Colors.grey[200]!,
            context.subtextColor, 56, isZero ? null : _reset, isZero),
          const SizedBox(width: 16),
          _swBtn(context,
            _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            themeColor, Colors.black, 76, _running ? _pause : _start, false, shadow: true),
          const SizedBox(width: 16),
          _swBtn(context, Icons.flag_rounded,
            context.isDark ? Colors.grey[800]! : Colors.grey[200]!,
            _running ? accent : context.subtextColor,
            56, _running ? _lap : null, !_running),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _swStat(context, 'Hours',   '${_elapsed.inHours}',        accent),
          _vDivider(context),
          _swStat(context, 'Minutes', '${_elapsed.inMinutes % 60}', accent),
          _vDivider(context),
          _swStat(context, 'Seconds', '${_elapsed.inSeconds % 60}', accent),
        ]),
        if (_laps.isNotEmpty) ...[
          const SizedBox(height: 20),
          Divider(color: context.isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 6),
          ...List.generate(math.min(_laps.length, 5), (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.flag_rounded, color: accent, size: 14),
                const SizedBox(width: 6),
                Text('Lap ${_laps.length - i}',
                  style: TextStyle(color: context.subtextColor, fontSize: 13)),
              ]),
              Text(_fmt(_laps[i]),
                style: TextStyle(
                  color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          )),
          if (_laps.length > 5)
            Padding(padding: const EdgeInsets.only(top: 4),
              child: Text('+ ${_laps.length - 5} more laps',
                style: TextStyle(color: context.subtextColor, fontSize: 11))),
        ],
      ]),
    );
  }

  Widget _swBtn(BuildContext context, IconData icon, Color bg, Color iconColor,
      double size, VoidCallback? onTap, bool disabled, {bool shadow = false}) =>
    GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.3 : 1.0,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: bg, shape: BoxShape.circle,
            boxShadow: shadow
                ? [BoxShadow(color: bg.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: Icon(icon, color: iconColor, size: size * 0.46),
        ),
      ),
    );

  Widget _swStat(BuildContext context, String label, String value, Color color) =>
    Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: context.subtextColor, fontSize: 11)),
    ]);

  Widget _vDivider(BuildContext context) => Container(
    width: 1, height: 36,
    color: context.isDark ? Colors.grey[800] : Colors.grey[300]);
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
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _anim, child: widget.child);
}