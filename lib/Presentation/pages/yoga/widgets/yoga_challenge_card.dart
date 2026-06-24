import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/yoga/challenge/weekly_challenge_landing_page.dart';
import 'package:get_fit/Presentation/pages/yoga/challenge/weekly_challenge_home_page.dart';
import 'package:get_fit/Services/supabase_service.dart';

// Darker accent used in LIGHT mode wherever themeColor would otherwise be
// used as a TEXT/ICON color directly on a light background (low contrast).
// In DARK mode this just returns themeColor (unchanged from before).
Color _accent(BuildContext context) {
  return context.isDark ? themeColor : const Color(0xFF6B7A00);
}

class YogaChallengeCard extends StatefulWidget {
  const YogaChallengeCard({super.key});

  @override
  State<YogaChallengeCard> createState() => _YogaChallengeCardState();
}

class _YogaChallengeCardState extends State<YogaChallengeCard> {
  int _completedToday = 0;
  int _totalToday = 0;
  int _todayCalories = 0;
  int _todayIndex = 0; // 0=Mon ... 6=Sun
  bool _isLoading = true;
  bool _todayFullyDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final challenge = await SupabaseService.getActiveChallengeForUser();
      if (challenge == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final todayDay =
          await SupabaseService.getTodayChallengeDayForUser(challenge['id']);
      if (todayDay == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final dayNumber = todayDay['day_number'] as int;
      final rounds = await SupabaseService.getRoundsForDay(todayDay['id']);

      int total = 0;
      for (final round in rounds) {
        final exercises =
            await SupabaseService.getExercisesForRound(round['id']);
        total += exercises.length;
      }

      final completedIds = await SupabaseService.getCompletedExerciseIds(
        challengeId: challenge['id'],
        dayNumber: dayNumber,
      );

      final calories = await SupabaseService.getDayTotalCalories(
        challengeId: challenge['id'],
        dayNumber: dayNumber,
      );

      if (mounted) {
        setState(() {
          _completedToday = completedIds.length;
          _totalToday = total;
          _todayCalories = calories;
          _todayIndex = DateTime.now().weekday - 1;
          _todayFullyDone = total > 0 && completedIds.length >= total;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDayTap(BuildContext context, int tappedIndex) {
    final today = _todayIndex;

    if (tappedIndex == today) {
      // Go to today's challenge
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeeklyChallengeHomePage()),
      ).then((_) => _load());
      return;
    }

    if (tappedIndex < today) {
      // Past day — already done, just show info (no countdown needed)
      _showDayDialog(
        context,
        title: 'Day ${tappedIndex + 1} Complete',
        message: 'You already completed this day. Keep up the momentum!',
        icon: Icons.check_circle_rounded,
        iconColor: _accent(context),
        showGoButton: false,
      );
      return;
    }

    // Future day — locked, show live countdown to midnight
    if (_todayFullyDone) {
      showDialog(
        context: context,
        builder: (_) => _CountdownLockDialog(
          title: 'Day ${tappedIndex + 1} Locked',
          message:
              'This day unlocks tomorrow. Come back then to continue your challenge!',
          icon: Icons.lock_rounded,
          iconColor: context.subtextColor,
          showGoButton: false,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => _CountdownLockDialog(
          title: 'Day ${tappedIndex + 1} Locked',
          message:
              'Complete today\'s remaining exercises first before this day unlocks.',
          icon: Icons.lock_rounded,
          iconColor: Colors.orange,
          showGoButton: true,
          goLabel: 'Go to Today\'s Challenge',
          onGo: () {
            Navigator.pop(dialogContext);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WeeklyChallengeHomePage()),
            ).then((_) => _load());
          },
        ),
      );
    }
  }

  void _showDayDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required bool showGoButton,
    String? goLabel,
    VoidCallback? onGo,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: context.cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (showGoButton && onGo != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onGo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      goLabel ?? 'Go',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: context.isDark
                          ? Colors.white24
                          : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalToday > 0 ? _completedToday / _totalToday : 0.0;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final accent = _accent(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeeklyChallengeLandingPage()),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: _isLoading
            ? const SizedBox(
                height: 160,
                child: Center(
                    child: CircularProgressIndicator(
                        color: themeColor, strokeWidth: 2)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(context.isDark ? 0.15 : 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.emoji_events_rounded,
                            color: accent, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Challenge',
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _todayFullyDone
                                  ? 'Today complete! Come back tomorrow.'
                                  : 'Complete today\'s exercises to progress',
                              style: TextStyle(
                                  color: context.subtextColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Day ${_todayIndex + 1}/7',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Stat chips ──
                  Row(
                    children: [
                      _statChip(context, Icons.local_fire_department_rounded,
                          '$_todayCalories kcal', Colors.orange),
                      const SizedBox(width: 8),
                      _statChip(context, Icons.access_time_rounded,
                          '$_completedToday/$_totalToday done', accent),
                      const SizedBox(width: 8),
                      _statChip(context, Icons.directions_run_rounded,
                          'Day ${_todayIndex + 1}', Colors.blue),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Progress bar ──
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: context.isDark
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Day circles ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final isPast = i < _todayIndex;
                      final isToday = i == _todayIndex;
                      final isFuture = i > _todayIndex;
                      return GestureDetector(
                        onTap: () => _onDayTap(context, i),
                        child: _dayChip(
                            context, days[i], isPast, isToday, isFuture),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // ── Footer ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Go to challenge button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const WeeklyChallengeHomePage()),
                        ).then((_) => _load()),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              _todayFullyDone
                                  ? 'View progress'
                                  : 'Continue challenge',
                              style: TextStyle(
                                color: accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Streak
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Streak: $_todayIndex days',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statChip(
      BuildContext context, IconData icon, String label, Color color) {
    final isThemeColorAccent = color == themeColor;
    final displayColor =
        isThemeColorAccent ? _accent(context) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(context.isDark ? 0.12 : 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: displayColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: displayColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(BuildContext context, String day, bool isPast, bool isToday,
      bool isFuture) {
    final accent = _accent(context);
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isPast) {
      bgColor = themeColor;
      borderColor = themeColor;
      textColor = Colors.black;
    } else if (isToday) {
      bgColor = themeColor.withOpacity(context.isDark ? 0.2 : 0.22);
      borderColor = themeColor;
      textColor = accent;
    } else {
      bgColor = Colors.transparent;
      borderColor = context.isDark ? Colors.grey[700]! : Colors.grey[300]!;
      textColor = context.subtextColor;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: isToday ? 2 : 1),
      ),
      child: Center(
        child: isFuture
            ? Icon(Icons.lock_rounded,
                size: 13,
                color: context.isDark ? Colors.grey[600] : Colors.grey[400])
            : Text(
                day,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight:
                      isPast || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
      ),
    );
  }
}

class _CountdownLockDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final bool showGoButton;
  final String? goLabel;
  final VoidCallback? onGo;

  const _CountdownLockDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.showGoButton,
    this.goLabel,
    this.onGo,
  });

  @override
  State<_CountdownLockDialog> createState() => _CountdownLockDialogState();
}

class _CountdownLockDialogState extends State<_CountdownLockDialog> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    if (mounted) {
      setState(() {
        _remaining = nextMidnight.difference(now);
        _currentTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return Dialog(
      backgroundColor: context.cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Live countdown block ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(context.isDark ? 0.1 : 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_bottom_rounded,
                          color: accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Unlocks in',
                        style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDuration(_remaining),
                    style: TextStyle(
                      color: accent,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current time: $_currentTime',
                    style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              style: TextStyle(
                color: context.textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: TextStyle(
                color: context.subtextColor,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (widget.showGoButton && widget.onGo != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onGo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.goLabel ?? 'Go',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color:
                        context.isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(color: context.textColor, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}