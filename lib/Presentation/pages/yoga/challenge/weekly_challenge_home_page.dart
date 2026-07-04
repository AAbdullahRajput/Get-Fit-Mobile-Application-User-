import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/challenge/challenge_detail_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

// Darker accent used in LIGHT mode wherever themeColor would otherwise be
// used as TEXT/ICON color directly on a light background (low contrast).
// In DARK mode this returns themeColor, unchanged from before.
Color _accent(BuildContext context) {
  return context.isDark ? themeColor : const Color(0xFF6B7A00);
}

class WeeklyChallengeHomePage extends StatefulWidget {
  const WeeklyChallengeHomePage({super.key});

  @override
  State<WeeklyChallengeHomePage> createState() => _WeeklyChallengeHomePageState();
}

class _WeeklyChallengeHomePageState extends State<WeeklyChallengeHomePage> {
  bool _isLoading = true;

  Map<String, dynamic>? _challenge;
  Map<String, dynamic>? _todayDay;
  List<Map<String, dynamic>> _rounds = [];
  Map<String, List<Map<String, dynamic>>> _exercisesByRound = {};
  Set<String> _completedIds = {};
  int _todayCalories = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final challenge = await SupabaseService.getActiveChallengeForUser();
    if (challenge == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final todayDay = await SupabaseService.getTodayChallengeDayForUser(challenge['id']);
    if (todayDay == null) {
      if (mounted) setState(() {
        _challenge = challenge;
        _isLoading = false;
      });
      return;
    }

    final rounds = await SupabaseService.getRoundsForDay(todayDay['id']);

    final Map<String, List<Map<String, dynamic>>> exercisesByRound = {};
    for (final round in rounds) {
      final exercises = await SupabaseService.getExercisesForRound(round['id']);
      exercisesByRound[round['id']] = exercises;
    }

    final completedIds = await SupabaseService.getCompletedExerciseIds(
      challengeId: challenge['id'],
      dayNumber: todayDay['day_number'],
    );

    final calories = await SupabaseService.getDayTotalCalories(
      challengeId: challenge['id'],
      dayNumber: todayDay['day_number'],
    );

    final streakInfo = await SupabaseService.getStreakInfo();

    if (mounted) {
      setState(() {
        _challenge = challenge;
        _todayDay = todayDay;
        _rounds = rounds;
        _exercisesByRound = exercisesByRound;
        _completedIds = completedIds.toSet();
        _todayCalories = calories;
        _currentStreak = (streakInfo['current_streak'] as int?) ?? 0;
        _longestStreak = (streakInfo['longest_streak'] as int?) ?? 0;
        _isLoading = false;
      });
    }
  }

  String _dayLabel() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final n = (_todayDay?['day_number'] as int? ?? 1) - 1;
    return days[n.clamp(0, 6)];
  }

  int _totalExercises() {
    return _exercisesByRound.values.fold(0, (s, list) => s + list.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Weekly Challenge',
          style: TextStyle(
            color: _accent(context),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accent(context)))
          : _challenge == null
              ? _buildNoChallenge()
              : RefreshIndicator(
                  color: _accent(context),
                  backgroundColor: context.cardBgColor,
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBanner(),
                        if (_todayDay != null) ...[
                          _buildDayHeader(),
                          _buildStatsRow(),
                          const SizedBox(height: 8),
                          if (_todayDay!['is_rest_day'] == true)
                            _buildRestDay()
                          else
                            ..._rounds.map((round) => _buildRoundSection(round)),
                        ] else
                          _buildNoDay(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBanner() {
    // Banner sits on top of a dark image with darkening overlay,
    // so themeColor/white stay as-is in both themes — already readable.
    return Container(
      height: 460,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/challenge/bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.45),
            BlendMode.darken,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: themeColor, size: 42),
              const SizedBox(height: 8),
              Text(
                _challenge?['title'] ?? '7 Day Challenge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                _challenge?['description'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            // Solid themeColor pill with BLACK text — fine in both themes.
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.black),
                const SizedBox(width: 5),
                Text(
                  'TODAY · ${_dayLabel()}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _todayDay?['theme'] ?? '',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _todayDay?['theme_description'] ?? '',
                  style: TextStyle(color: context.subtextColor, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final completed = _completedIds.length;
    final total = _totalExercises();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_currentStreak > 0)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildStatChip(
                    Icons.whatshot_rounded, '$_currentStreak day streak', Colors.deepOrange),
              ),
            _buildStatChip(Icons.local_fire_department_rounded, '$_todayCalories kcal', Colors.orange),
            const SizedBox(width: 10),
            _buildStatChip(Icons.access_time_rounded, '$completed/$total done', _accent(context)),
            const SizedBox(width: 10),
            _buildStatChip(Icons.directions_run_rounded, '${_rounds.length} rounds', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.12 : 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundSection(Map<String, dynamic> round) {
    final exercises = _exercisesByRound[round['id']] ?? [];
    final doneInRound = exercises.where((e) => _completedIds.contains(e['id'])).length;
    final allDone = doneInRound == exercises.length && exercises.isNotEmpty;
    final accent = _accent(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (allDone)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.check_circle_rounded, color: accent, size: 18),
                          ),
                        Expanded(
                          child: Text(
                            round['title'] ?? '',
                            style: TextStyle(
                              fontSize: 17,
                              color: allDone ? accent : context.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((round['description'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          round['description'],
                          style: TextStyle(color: context.subtextColor, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allDone
                      ? themeColor.withOpacity(context.isDark ? 0.15 : 0.18)
                      : context.cardBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$doneInRound/${exercises.length}',
                  style: TextStyle(
                    color: allDone ? accent : context.subtextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...exercises.map((exercise) => _buildExerciseTile(exercise, round)),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(Map<String, dynamic> exercise, Map<String, dynamic> round) {
    final isDone = _completedIds.contains(exercise['id'] as String);
    final calories = exercise['calories_full'] as int? ?? 0;
    final duration = exercise['duration_seconds'] as int? ?? 0;
    final mins = duration ~/ 60;
    final secs = duration % 60;
    final timeStr = mins > 0
        ? (secs > 0 ? '${mins}m ${secs}s' : '${mins}m')
        : '${secs}s';
    final accent = _accent(context);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeDetailPage(
              exercise: exercise,
              challenge: _challenge!,
              dayNumber: _todayDay!['day_number'] as int,
              roundTitle: round['title'] ?? '',
            ),
          ),
        );
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isDone
              ? themeColor.withOpacity(context.isDark ? 0.07 : 0.10)
              : context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: isDone
              ? Border.all(color: themeColor.withOpacity(0.25), width: 1)
              : Border.all(color: Colors.transparent),
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    exercise['image_url'] ?? '',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.fitness_center_rounded, color: context.subtextColor, size: 24),
                    ),
                  ),
                ),
                if (isDone)
                  // Dark overlay + themeColor check — already high-contrast in both themes.
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_rounded, color: themeColor, size: 26),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['title'] ?? '',
                    style: TextStyle(
                      color: isDone ? context.subtextColor : context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: context.subtextColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: context.subtextColor),
                      const SizedBox(width: 3),
                      Text(timeStr, style: TextStyle(color: context.subtextColor, fontSize: 11)),
                      const SizedBox(width: 10),
                      Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.orange),
                      const SizedBox(width: 3),
                      Text('$calories kcal', style: TextStyle(color: context.subtextColor, fontSize: 11)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(context.isDark ? 0.13 : 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exercise['level'] ?? '',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((exercise['repetitions'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      exercise['repetitions'],
                      style: TextStyle(color: context.subtextColor, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action icon
            isDone
                ? Icon(Icons.check_circle_rounded, color: accent, size: 28)
                : Icon(
                    Icons.play_circle_filled_rounded,
                    color: accent,
                    size: 32,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDay() {
    final accent = _accent(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(context.isDark ? 0.1 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.self_improvement_rounded, color: accent, size: 56),
          ),
          const SizedBox(height: 16),
          Text(
            'Rest Day',
            style: TextStyle(
              color: context.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _todayDay?['theme_description'] ??
                'Take it easy today. Recovery is where muscles grow.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.subtextColor, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChallenge() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_rounded, color: context.subtextColor, size: 64),
            const SizedBox(height: 16),
            Text(
              'No active challenge found',
              style: TextStyle(color: context.subtextColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDay() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, color: context.subtextColor, size: 48),
          const SizedBox(height: 12),
          Text(
            'No exercises scheduled for today.',
            style: TextStyle(color: context.subtextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}