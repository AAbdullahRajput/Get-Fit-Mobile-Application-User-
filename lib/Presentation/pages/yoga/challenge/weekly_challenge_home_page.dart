import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/challenge/challenge_detail_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

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

  // roundId -> list of exercises
  Map<String, List<Map<String, dynamic>>> _exercisesByRound = {};

  // completed exercise IDs for today
  Set<String> _completedIds = {};

  int _todayCalories = 0;

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

    if (mounted) {
      setState(() {
        _challenge = challenge;
        _todayDay = todayDay;
        _rounds = rounds;
        _exercisesByRound = exercisesByRound;
        _completedIds = completedIds.toSet();
        _todayCalories = calories;
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
            color: themeColor,
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
          ? const Center(child: CircularProgressIndicator(color: themeColor))
          : _challenge == null
              ? _buildNoChallenge()
              : RefreshIndicator(
                  color: themeColor,
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
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/challenge/bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: themeColor, size: 44),
            const SizedBox(height: 8),
            Text(
              _challenge?['title'] ?? '7 Day Challenge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _challenge?['description'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'TODAY · ${_dayLabel()}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
      child: Row(
        children: [
          _buildStatChip(Icons.local_fire_department, '$_todayCalories kcal', Colors.orange),
          const SizedBox(width: 10),
          _buildStatChip(Icons.check_circle_outline, '$completed/$total done', themeColor),
          const SizedBox(width: 10),
          _buildStatChip(Icons.fitness_center, '${_rounds.length} rounds', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRoundSection(Map<String, dynamic> round) {
    final exercises = _exercisesByRound[round['id']] ?? [];
    final doneInRound = exercises.where((e) => _completedIds.contains(e['id'])).length;

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
                    Text(
                      round['title'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((round['description'] ?? '').isNotEmpty)
                      Text(
                        round['description'],
                        style: TextStyle(color: context.subtextColor, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Text(
                '$doneInRound/${exercises.length}',
                style: TextStyle(color: context.subtextColor, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
    final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

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
        // Refresh after returning to pick up any newly completed exercise
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDone
              ? themeColor.withOpacity(0.08)
              : context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: isDone
              ? Border.all(color: themeColor.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                exercise['image_url'] ?? '',
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 54,
                  height: 54,
                  color: context.isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.fitness_center, color: context.subtextColor),
                ),
              ),
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
                      color: context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: context.subtextColor),
                      const SizedBox(width: 3),
                      Text(timeStr, style: TextStyle(color: context.subtextColor, fontSize: 12)),
                      const SizedBox(width: 10),
                      Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                      const SizedBox(width: 3),
                      Text('$calories kcal', style: TextStyle(color: context.subtextColor, fontSize: 12)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exercise['level'] ?? '',
                          style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold),
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
            // Done indicator or play icon
            isDone
                ? const Icon(Icons.check_circle, color: themeColor, size: 28)
                : const Icon(Icons.play_circle_fill, color: themeColor, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDay() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.self_improvement, color: themeColor, size: 64),
          const SizedBox(height: 16),
          Text(
            'Rest Day 🌿',
            style: TextStyle(
              color: context.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _todayDay?['theme_description'] ?? 'Take it easy today. Recovery is where muscles grow.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.subtextColor, fontSize: 14),
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
            Icon(Icons.fitness_center, color: context.subtextColor, size: 64),
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
      child: Text(
        'No exercises scheduled for today.',
        style: TextStyle(color: context.subtextColor, fontSize: 14),
      ),
    );
  }
}