import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/home/home_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Presentation/pages/yoga/challenge/challenge_detail_page.dart';

class SuccessPage extends StatefulWidget {
  final String exerciseTitle;
  final int caloriesBurned;
  final String muscleGroups;
  final int timeSpentSeconds;
  final String challengeId;
  final int dayNumber;

  const SuccessPage({
    super.key,
    required this.exerciseTitle,
    required this.caloriesBurned,
    required this.muscleGroups,
    required this.timeSpentSeconds,
    required this.challengeId,
    required this.dayNumber,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  Map<String, dynamic>? _nextExercise;
  Map<String, dynamic>? _nextRound;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    // Find the next incomplete exercise for today
    final challenge = await SupabaseService.getActiveChallengeForUser();
    if (challenge == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final todayDay = await SupabaseService.getTodayChallengeDayForUser(challenge['id']);
    if (todayDay == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final completedIds = await SupabaseService.getCompletedExerciseIds(
      challengeId: widget.challengeId,
      dayNumber: widget.dayNumber,
    );
    final completedSet = completedIds.toSet();

    final rounds = await SupabaseService.getRoundsForDay(todayDay['id']);
    for (final round in rounds) {
      final exercises = await SupabaseService.getExercisesForRound(round['id']);
      for (final ex in exercises) {
        if (!completedSet.contains(ex['id'] as String)) {
          if (mounted) {
            setState(() {
              _nextExercise = ex;
              _nextRound = round;
              _isLoading = false;
            });
          }
          return;
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Weekly Challenge',
          style: TextStyle(color: themeColor, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/challenge/success.png', height: 140, width: 140),
              ),
              const SizedBox(height: 24),
              Text(
                'Congratulations! 🎉',
                style: TextStyle(color: themeColor, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.exerciseTitle,
                style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBox(Icons.local_fire_department, '${widget.caloriesBurned}', 'kcal burned', Colors.orange),
                  _statBox(Icons.timer, _formatTime(widget.timeSpentSeconds), 'time spent', themeColor),
                ],
              ),
              if (widget.muscleGroups.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.cardBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '💪 Muscles worked: ${widget.muscleGroups}',
                    style: TextStyle(color: context.subtextColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              // Next exercise button
              if (_isLoading)
                const CircularProgressIndicator(color: themeColor)
              else if (_nextExercise != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChallengeDetailPageWrapper(
                            exercise: _nextExercise!,
                            challengeId: widget.challengeId,
                            dayNumber: widget.dayNumber,
                            roundTitle: _nextRound?['title'] ?? '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Next Exercise →',
                      style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    const Icon(Icons.emoji_events, color: themeColor, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      "You've completed today's challenge! 🏆",
                      style: TextStyle(color: themeColor, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: context.isDark ? Colors.white24 : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Home', style: TextStyle(color: context.textColor, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: context.subtextColor, fontSize: 11)),
        ],
      ),
    );
  }
}

// Wrapper so SuccessPage can navigate to next exercise without circular import
class ChallengeDetailPageWrapper extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final String challengeId;
  final int dayNumber;
  final String roundTitle;

  const ChallengeDetailPageWrapper({
    super.key,
    required this.exercise,
    required this.challengeId,
    required this.dayNumber,
    required this.roundTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Import challenge_detail_page inline to avoid circular dependency
    return _ChallengeDetailPageRouter(
      exercise: exercise,
      challengeId: challengeId,
      dayNumber: dayNumber,
      roundTitle: roundTitle,
    );
  }
}

class _ChallengeDetailPageRouter extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final String challengeId;
  final int dayNumber;
  final String roundTitle;

  const _ChallengeDetailPageRouter({
    required this.exercise,
    required this.challengeId,
    required this.dayNumber,
    required this.roundTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Lazy import via builder avoids circular dependency
    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.getActiveChallengeForUser(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: themeColor)),
          );
        }
        final challenge = snap.data!;
        return ChallengeDetailPage(
          exercise: exercise,
          challenge: challenge,
          dayNumber: dayNumber,
          roundTitle: roundTitle,
        );
      },
    );
  }
}