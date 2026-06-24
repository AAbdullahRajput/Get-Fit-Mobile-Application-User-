import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

// ─── accent helper ────────────────────────────────────────────────────────────
Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

// ─── source colors ────────────────────────────────────────────────────────────
const Color _challengeColor = Color(0xFFCCE600);
const Color _gymColor       = Color(0xFF4A90D9);
const Color _yogaColor      = Color(0xFFFF8C42);

// ============================================================================
//  RunnerPage
// ============================================================================
class RunnerPage extends StatefulWidget {
  const RunnerPage({super.key});
  @override
  State<RunnerPage> createState() => _RunnerPageState();
}

class _RunnerPageState extends State<RunnerPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── filter ──────────────────────────────────────────────────────────────
  static const List<String> _filters    = ['1D', '7D', '14D', '1M', '3M'];
  static const List<int>    _filterDays = [1, 7, 14, 30, 90];
  int _filterIdx = 1;

  // ── data ────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  List<_DayStat> _stats = [];

  // ── selected bar ────────────────────────────────────────────────────────
  // null = today (auto), otherwise index into _stats
  int? _selectedIdx;

  _DayStat? get _selectedStat {
    if (_stats.isEmpty) return null;
    if (_selectedIdx != null) return _stats[_selectedIdx!];
    // auto: find today
    final today = DateTime.now();
    final idx = _stats.indexWhere((d) =>
        d.date.year == today.year &&
        d.date.month == today.month &&
        d.date.day == today.day);
    return idx >= 0 ? _stats[idx] : _stats.last;
  }

  int get _todayAutoIdx {
    if (_stats.isEmpty) return -1;
    final today = DateTime.now();
    final idx = _stats.indexWhere((d) =>
        d.date.year == today.year &&
        d.date.month == today.month &&
        d.date.day == today.day);
    return idx >= 0 ? idx : _stats.length - 1;
  }

  // Totals across full range (for overview cards)
  int get _totalKcal =>
      _stats.fold(0, (s, d) => s + d.challengeKcal + d.gymKcal + d.yogaKcal);
  int get _totalSeconds =>
      _stats.fold(0, (s, d) => s + d.challengeSec + d.gymSec);
  int get _activeDays => _stats.where((d) => d.totalKcal > 0).length;

  // Selected day values
  int get _selKcal    => _selectedStat?.totalKcal    ?? 0;
  int get _selSeconds => (_selectedStat?.challengeSec ?? 0) + (_selectedStat?.gymSec ?? 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _days => _filterDays[_filterIdx];

  Future<void> _load() async {
    setState(() { _isLoading = true; _selectedIdx = null; });
    final raw = await SupabaseService.getActivityStats(days: _days);
    final stats = raw.map((m) => _DayStat(
      label:         m['label'] as String,
      date:          DateTime.parse(m['date'] as String),
      challengeKcal: m['challengeKcal'] as int,
      gymKcal:       m['gymKcal']       as int,
      yogaKcal:      m['yogaKcal']      as int,
      challengeSec:  m['challengeSec']  as int,
      gymSec:        m['gymSec']        as int,
    )).toList();
    if (mounted) setState(() { _stats = stats; _isLoading = false; });
  }

  void _onBarTap(int idx) {
    setState(() => _selectedIdx = idx);
  }

  // ── 3-dot menu ──────────────────────────────────────────────────────────
  void _showMenu(BuildContext context) {
    final accent = _accent(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          _menuItem(context, Icons.share_outlined,         'Share Progress',    accent, () { Navigator.pop(context); }),
          _menuItem(context, Icons.flag_outlined,          'Set Calorie Goal',  accent, () { Navigator.pop(context); }),
          _menuItem(context, Icons.history_rounded,        'View Full History', accent, () { Navigator.pop(context); }),
          _menuItem(context, Icons.file_download_outlined, 'Export Data',       accent, () { Navigator.pop(context); }),
        ]),
      ),
    );
  }

  Widget _menuItem(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(color: ctx.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.arrow_forward_ios, size: 13, color: ctx.subtextColor),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildFilterTabs(),
                const SizedBox(height: 18),
                if (_isLoading)
                  _buildSkeleton()
                else ...[
                  // ── FIGMA: yellow calories card with interactive bars ──
                  _CaloriesCard(
                    stats:        _stats,
                    days:         _days,
                    selectedIdx:  _selectedIdx ?? _todayAutoIdx,
                    todayIdx:     _todayAutoIdx,
                    onBarTap:     _onBarTap,
                    onMenuTap:    () => _showMenu(context),
                  ),
                  const SizedBox(height: 14),
                  // ── Selected day summary ──
                  _buildSelectedDayCard(),
                  const SizedBox(height: 14),
                  // ── Duration card (also bar-interactive) ──
                  _DurationCard(
                    stats:       _stats,
                    days:        _days,
                    selectedIdx: _selectedIdx ?? _todayAutoIdx,
                    todayIdx:    _todayAutoIdx,
                    onBarTap:    _onBarTap,
                    accent:      _accent(context),
                  ),
                  const SizedBox(height: 14),
                  // ── Source breakdown for selected day ──
                  _buildSourceCard(),
                  const SizedBox(height: 14),
                  // ── Range overview ──
                  _buildRangeOverviewCard(),
                  const SizedBox(height: 22),
                  _buildDivider('Stopwatch'),
                  const SizedBox(height: 14),
                  const _StopwatchCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activities',
              style: TextStyle(color: _accent(context), fontSize: 26, fontWeight: FontWeight.bold)),
            Text('Tap any bar to explore that day',
              style: TextStyle(color: context.subtextColor, fontSize: 12)),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(context.isDark ? 0.15 : 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.bar_chart_rounded, color: _accent(context), size: 24),
      ),
    ],
  );

  // ── filter tabs ───────────────────────────────────────────────────────────
  Widget _buildFilterTabs() => Container(
    height: 42,
    decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(24)),
    child: Row(
      children: List.generate(_filters.length, (i) {
        final sel = _filterIdx == i;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (_filterIdx != i) { setState(() => _filterIdx = i); _load(); }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: sel ? themeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(_filters[i],
                  style: TextStyle(
                    color: sel ? Colors.black : context.subtextColor,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  )),
              ),
            ),
          ),
        );
      }),
    ),
  );

  // ── selected day detail card ───────────────────────────────────────────────
  Widget _buildSelectedDayCard() {
    final stat   = _selectedStat;
    final mins   = _selSeconds ~/ 60;
    final hrs    = mins ~/ 60;
    final remMin = mins % 60;
    final timeStr = hrs > 0 ? '${hrs}h ${remMin}m' : '${mins}m';

    final today   = DateTime.now();
    final selDate = stat?.date;
    final isToday = selDate != null &&
        selDate.year  == today.year &&
        selDate.month == today.month &&
        selDate.day   == today.day;

    // day label
    const dayNames = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    String dayLabel = 'Today';
    if (selDate != null && !isToday) {
      dayLabel = _days <= 7
          ? dayNames[selDate.weekday - 1]
          : '${selDate.day}/${selDate.month}/${selDate.year}';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(_selectedIdx ?? -1),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
          boxShadow: context.isDark ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: themeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.calendar_today_rounded, color: _accent(context), size: 14),
              ),
              const SizedBox(width: 8),
              Text(dayLabel,
                style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(20)),
                child: const Text('Today', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _dayStatPill(Icons.local_fire_department_outlined, '$_selKcal', 'kcal', Colors.orange),
            const SizedBox(width: 10),
            _dayStatPill(Icons.timer_outlined, timeStr, 'active', _accent(context)),
            const SizedBox(width: 10),
            _dayStatPill(
              Icons.fitness_center_outlined,
              '${(stat?.gymKcal ?? 0)}',
              'gym kcal',
              _gymColor,
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _dayStatPill(IconData icon, String value, String unit, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.1 : 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(unit, style: TextStyle(color: context.subtextColor, fontSize: 10)),
      ]),
    ),
  );

  // ── source breakdown (selected day) ──────────────────────────────────────
  Widget _buildSourceCard() {
    final stat          = _selectedStat;
    final challengeKcal = stat?.challengeKcal ?? 0;
    final gymKcal       = stat?.gymKcal       ?? 0;
    final yogaKcal      = stat?.yogaKcal      ?? 0;
    final total         = challengeKcal + gymKcal + yogaKcal;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey('src_${_selectedIdx ?? -1}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.isDark ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Calories by Source',
            style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          _sourceRow(Icons.emoji_events_outlined,   'Weekly Challenge', challengeKcal, total, _challengeColor),
          const SizedBox(height: 10),
          _sourceRow(Icons.fitness_center_outlined, 'Gym Exercises',    gymKcal,       total, _gymColor),
          const SizedBox(height: 10),
          _sourceRow(Icons.self_improvement_outlined,'Yoga',            yogaKcal,      total, _yogaColor),
        ]),
      ),
    );
  }

  Widget _sourceRow(IconData icon, String label, int kcal, int total, Color color) {
    final pct = total > 0 ? kcal / total : 0.0;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
          Text('$kcal kcal', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct, minHeight: 5,
            backgroundColor: context.isDark ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ])),
    ]);
  }

  // ── range overview card ───────────────────────────────────────────────────
  Widget _buildRangeOverviewCard() {
    final mins   = _totalSeconds ~/ 60;
    final hrs    = mins ~/ 60;
    final remMin = mins % 60;
    final timeStr = hrs > 0 ? '${hrs}h ${remMin}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.isDark ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_filters[_filterIdx]} Overview',
          style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [
          _overviewStat(Icons.local_fire_department_outlined, '$_totalKcal', 'Total kcal', Colors.orange),
          _vSep(),
          _overviewStat(Icons.timer_outlined, timeStr, 'Total time', _accent(context)),
          _vSep(),
          _overviewStat(Icons.calendar_today_outlined, '$_activeDays', 'Active days', _gymColor),
        ]),
      ]),
    );
  }

  Widget _overviewStat(IconData icon, String value, String label, Color color) => Expanded(
    child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: context.subtextColor, fontSize: 10)),
    ]),
  );

  Widget _vSep() => Container(
    width: 1, height: 40,
    color: context.isDark ? Colors.grey[800] : Colors.grey[300],
  );

  Widget _buildDivider(String label) => Row(children: [
    Expanded(child: Divider(color: context.isDark ? Colors.grey[800] : Colors.grey[300])),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(label, style: TextStyle(color: _accent(context), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    ),
    Expanded(child: Divider(color: context.isDark ? Colors.grey[800] : Colors.grey[300])),
  ]);

  // ── skeleton ──────────────────────────────────────────────────────────────
  Widget _buildSkeleton() => Column(children: [
    _sh(context, 220),
    const SizedBox(height: 14),
    _sh(context, 100),
    const SizedBox(height: 14),
    _sh(context, 160),
    const SizedBox(height: 14),
    _sh(context, 140),
  ]);

  Widget _sh(BuildContext context, double h) => _ShimmerBox(
    child: Container(
      height: h,
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xff2e2e2e) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

// ============================================================================
//  CALORIES CARD — Figma replica + interactive bars
// ============================================================================
class _CaloriesCard extends StatelessWidget {
  final List<_DayStat> stats;
  final int days;
  final int selectedIdx;
  final int todayIdx;
  final ValueChanged<int> onBarTap;
  final VoidCallback onMenuTap;

  const _CaloriesCard({
    required this.stats, required this.days,
    required this.selectedIdx, required this.todayIdx,
    required this.onBarTap, required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final selKcal = selectedIdx >= 0 && selectedIdx < stats.length
        ? stats[selectedIdx].totalKcal : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFCCE600),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.local_fire_department_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            const Text('Calories Burn',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: RichText(
            key: ValueKey(selKcal),
            text: TextSpan(children: [
              TextSpan(text: '$selKcal',
                style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
              const TextSpan(text: '  Kcal',
                style: TextStyle(color: Color(0xFF556600), fontSize: 16, fontFamily: 'Roboto')),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        // interactive bar chart
        _InteractiveDiagonalBars(
          stats: stats, days: days,
          selectedIdx: selectedIdx, todayIdx: todayIdx,
          onBarTap: onBarTap,
        ),
      ]),
    );
  }
}

// ─── Interactive Diagonal Bar Chart ──────────────────────────────────────────
class _InteractiveDiagonalBars extends StatelessWidget {
  final List<_DayStat> stats;
  final int days;
  final int selectedIdx;
  final int todayIdx;
  final ValueChanged<int> onBarTap;

  const _InteractiveDiagonalBars({
    required this.stats, required this.days,
    required this.selectedIdx, required this.todayIdx,
    required this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox(height: 130);
    final maxVal = stats.map((d) => d.totalKcal.toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox(height: 130, child: Center(child: Text('No data yet', style: TextStyle(color: Color(0xFF556600)))));

    final count  = stats.length;
    final showEvery = count <= 7 ? 1 : count <= 14 ? 2 : 5;

    return Column(children: [
      SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(count, (i) {
            final d         = stats[i];
            final isSelected = i == selectedIdx;
            final isToday   = i == todayIdx;
            final frac      = maxVal > 0 ? d.totalKcal / maxVal : 0.0;

            return Expanded(
              child: GestureDetector(
                onTap: () => onBarTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    // bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      height: (110 * frac).clamp(6.0, 110.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isSelected
                            ? Container(color: Colors.black)
                            : _DiagonalStripeBar(
                                baseColor:   const Color(0xFFB8CC00),
                                stripeColor: const Color(0xFFCCE600),
                                isActive:    isSelected,
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // label
                    if (i % showEvery == 0)
                      Text(d.label,
                        style: TextStyle(
                          color: isSelected ? Colors.black : const Color(0xFF556600),
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ))
                    else
                      const SizedBox(height: 13),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    ]);
  }
}

// ─── Diagonal stripe bar (CustomPainter) ─────────────────────────────────────
class _DiagonalStripeBar extends StatelessWidget {
  final Color baseColor;
  final Color stripeColor;
  final bool isActive;

  const _DiagonalStripeBar({
    required this.baseColor, required this.stripeColor, this.isActive = false,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StripePainter(baseColor: baseColor, stripeColor: stripeColor),
    child: Container(),
  );
}

class _StripePainter extends CustomPainter {
  final Color baseColor;
  final Color stripeColor;
  _StripePainter({required this.baseColor, required this.stripeColor});

  @override
  void paint(Canvas canvas, Size size) {
    // background
    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);
    // diagonal stripes
    final p = Paint()
      ..color = stripeColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    const spacing = 10.0;
    final span    = size.width + size.height;
    for (double s = -size.height; s < span; s += spacing) {
      canvas.drawLine(Offset(s, 0), Offset(s + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}

// ============================================================================
//  DURATION CARD — also interactive
// ============================================================================
class _DurationCard extends StatelessWidget {
  final List<_DayStat> stats;
  final int days;
  final int selectedIdx;
  final int todayIdx;
  final ValueChanged<int> onBarTap;
  final Color accent;

  const _DurationCard({
    required this.stats, required this.days,
    required this.selectedIdx, required this.todayIdx,
    required this.onBarTap, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final selMins = selectedIdx >= 0 && selectedIdx < stats.length
        ? (stats[selectedIdx].challengeSec + stats[selectedIdx].gymSec) ~/ 60 : 0;

    final maxMins = stats.map((d) => (d.challengeSec + d.gymSec) / 60.0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    final count     = stats.length;
    final showEvery = count <= 7 ? 1 : count <= 14 ? 2 : 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.isDark ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.timer_outlined, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Workout Duration',
              style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text('$selMins min today',
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
              final d          = stats[i];
              final mins       = (d.challengeSec + d.gymSec) / 60.0;
              final frac       = maxMins > 0 ? mins / maxMins : 0.0;
              final isSelected = i == selectedIdx;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onBarTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        height: (90 * frac).clamp(4.0, 90.0),
                        decoration: BoxDecoration(
                          color: isSelected ? accent : accent.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (i % showEvery == 0)
                        Text(d.label,
                          style: TextStyle(
                            color: isSelected ? accent : context.subtextColor,
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ))
                      else
                        const SizedBox(height: 12),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

// ============================================================================
//  STOPWATCH CARD
// ============================================================================
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
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _running = false;
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
    _sw.stop();
    _ticker?.cancel();
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
    if (h > 0) return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
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
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: context.isDark ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // ── dial ─────────────────────────────────────────────────────────────
        SizedBox(
          width: 200, height: 200,
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
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
              const SizedBox(height: 4),
              Text(
                _running ? 'Running' : isZero ? 'Ready' : 'Paused',
                style: TextStyle(
                  color: _running ? themeColor : context.subtextColor,
                  fontSize: 12, fontWeight: FontWeight.w600,
                )),
            ]),
          ]),
        ),
        const SizedBox(height: 28),

        // ── controls ─────────────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _swBtn(Icons.refresh_rounded,
            context.isDark ? Colors.grey[800]! : Colors.grey[200]!,
            context.subtextColor, 56, isZero ? null : _reset, isZero),
          const SizedBox(width: 16),
          _swBtn(_running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            themeColor, Colors.black, 76, _running ? _pause : _start, false, shadow: true),
          const SizedBox(width: 16),
          _swBtn(Icons.flag_outlined,
            context.isDark ? Colors.grey[800]! : Colors.grey[200]!,
            _running ? accent : context.subtextColor, 56, _running ? _lap : null, !_running),
        ]),
        const SizedBox(height: 20),

        // ── quick stats ───────────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _swStat(context, 'Hours',   '${_elapsed.inHours}',          accent),
          _vDiv(context),
          _swStat(context, 'Minutes', '${_elapsed.inMinutes % 60}',   accent),
          _vDiv(context),
          _swStat(context, 'Seconds', '${_elapsed.inSeconds % 60}',   accent),
        ]),

        // ── lap list ─────────────────────────────────────────────────────────
        if (_laps.isNotEmpty) ...[
          const SizedBox(height: 20),
          Divider(color: context.isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 6),
          ...List.generate(math.min(_laps.length, 5), (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.flag_outlined, color: accent, size: 14),
                const SizedBox(width: 6),
                Text('Lap ${_laps.length - i}',
                  style: TextStyle(color: context.subtextColor, fontSize: 13)),
              ]),
              Text(_fmt(_laps[i]),
                style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          )),
          if (_laps.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+ ${_laps.length - 5} more laps',
                style: TextStyle(color: context.subtextColor, fontSize: 11)),
            ),
        ],
      ]),
    );
  }

  Widget _swBtn(IconData icon, Color bg, Color iconColor, double size,
      VoidCallback? onTap, bool disabled, {bool shadow = false}) =>
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

  Widget _swStat(BuildContext context, String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
    Text(label, style: TextStyle(color: context.subtextColor, fontSize: 11)),
  ]);

  Widget _vDiv(BuildContext context) => Container(
    width: 1, height: 36,
    color: context.isDark ? Colors.grey[800] : Colors.grey[300],
  );
}

// ============================================================================
//  DayStat model
// ============================================================================
class _DayStat {
  final String   label;
  final DateTime date;
  final int      challengeKcal;
  final int      gymKcal;
  final int      yogaKcal;
  final int      challengeSec;
  final int      gymSec;

  const _DayStat({
    required this.label, required this.date,
    this.challengeKcal = 0, this.gymKcal = 0, this.yogaKcal = 0,
    this.challengeSec  = 0, this.gymSec  = 0,
  });

  int get totalKcal => challengeKcal + gymKcal + yogaKcal;
}

// ============================================================================
//  Shimmer
// ============================================================================
class _ShimmerBox extends StatefulWidget {
  final Widget child;
  const _ShimmerBox({required this.child});
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _anim, child: widget.child);
}