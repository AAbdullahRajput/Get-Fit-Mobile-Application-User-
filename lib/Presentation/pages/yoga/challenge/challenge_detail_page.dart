import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/yoga/challenge/success_page.dart';

class ChallengeDetailPage extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final Map<String, dynamic> challenge;
  final int dayNumber;
  final String roundTitle;

  const ChallengeDetailPage({
    super.key,
    required this.exercise,
    required this.challenge,
    required this.dayNumber,
    required this.roundTitle,
  });

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;
  bool _isStarted = false;
  bool _isDone = false;
  bool _isSaving = false;

  int get _durationSeconds => widget.exercise['duration_seconds'] as int? ?? 60;
  int get _caloriesFull => widget.exercise['calories_full'] as int? ?? 0;
  int get _secondsRemaining => (_durationSeconds - _secondsElapsed).clamp(0, _durationSeconds);
  bool get _timerFinished => _secondsElapsed >= _durationSeconds;

  double get _progress => (_secondsElapsed / _durationSeconds).clamp(0.0, 1.0);

  int get _caloriesSoFar {
    final ratio = _durationSeconds > 0
        ? (_secondsElapsed / _durationSeconds).clamp(0.0, 1.0)
        : 1.0;
    return (_caloriesFull * ratio).round();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isStarted = true;
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsElapsed++);
      if (_secondsElapsed >= _durationSeconds) {
        t.cancel();
        setState(() => _isRunning = false);
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    if (_isDone) return;
    _showSuccessDialog(markedEarly: false);
  }

  Future<void> _markDone({bool markedEarly = false}) async {
    if (_isDone || _isSaving) return;
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isDone = true;
      _isSaving = true;
    });

    await SupabaseService.markExerciseDone(
      exerciseId: widget.exercise['id'] as String,
      challengeId: widget.challenge['id'] as String,
      dayNumber: widget.dayNumber,
      timeSpentSeconds: _secondsElapsed,
      caloriesFull: _caloriesFull,
      durationSeconds: _durationSeconds,
      markedEarly: markedEarly,
    );

    if (mounted) setState(() => _isSaving = false);

    _showSuccessDialog(markedEarly: markedEarly);
  }

  void _showSuccessDialog({required bool markedEarly}) {
    if (!mounted) return;
    final calories = markedEarly ? _caloriesSoFar : _caloriesFull;
    final muscles = (widget.exercise['muscle_groups'] as List?)
            ?.map((m) => m.toString())
            .join(', ') ??
        '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: context.cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: themeColor, size: 56),
              ),
              const SizedBox(height: 16),
              Text(
                'Exercise Complete!',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.exercise['title'] ?? '',
                style: TextStyle(color: themeColor, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _dialogStat(Icons.local_fire_department, '$calories', 'kcal', Colors.orange),
                  _dialogStat(Icons.timer, _formatTime(_secondsElapsed), 'time', themeColor),
                  if (muscles.isNotEmpty)
                    _dialogStat(Icons.fitness_center, muscles.split(',').length.toString(), 'muscles', Colors.blue),
                ],
              ),
              if (muscles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💪 Worked: $muscles',
                    style: TextStyle(color: context.subtextColor, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                markedEarly
                    ? 'Great effort! Every rep counts. 🔥'
                    : 'Full session completed! Incredible work! 🏆',
                style: TextStyle(color: context.subtextColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuccessPage(
                          exerciseTitle: widget.exercise['title'] ?? '',
                          caloriesBurned: calories,
                          muscleGroups: muscles,
                          timeSpentSeconds: _secondsElapsed,
                          challengeId: widget.challenge['id'] as String,
                          dayNumber: widget.dayNumber,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Next Exercise',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: context.subtextColor, fontSize: 11)),
      ],
    );
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
          widget.roundTitle,
          style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.exercise['image_url'] ?? '',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: context.cardBgColor,
                  child: Icon(Icons.fitness_center, color: themeColor, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title + level
            Text(
              widget.exercise['title'] ?? '',
              style: TextStyle(
                color: context.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.exercise['level'] ?? '',
                style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoChip(Icons.timer_outlined, _formatTime(_durationSeconds), 'Duration'),
                _buildInfoChip(Icons.repeat, widget.exercise['repetitions'] ?? '-', 'Reps'),
                _buildInfoChip(Icons.local_fire_department, '$_caloriesFull kcal', 'Calories'),
              ],
            ),

            const SizedBox(height: 24),

            // Timer circle
            _buildTimerCircle(),

            const SizedBox(height: 12),

            // Live calories counter
            if (_isStarted)
              Text(
                '🔥 $_caloriesSoFar kcal burned so far',
                style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600),
              ),

            const SizedBox(height: 24),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to do it',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.exercise['description'] ?? '',
                    style: TextStyle(color: context.subtextColor, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Muscle groups
            if ((widget.exercise['muscle_groups'] as List?)?.isNotEmpty == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muscles Worked',
                      style: TextStyle(color: themeColor, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.exercise['muscle_groups'] as List)
                          .map((m) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  m.toString(),
                                  style: TextStyle(
                                      color: themeColor, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Start / Mark done buttons
            if (!_isStarted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text(
                    'Start Challenge',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

            if (_isStarted && !_isDone) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _markDone(markedEarly: !_timerFinished),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline, color: Colors.black),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Mark as Done',
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],

            if (_isDone && !_isSaving)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: themeColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: themeColor),
                    const SizedBox(width: 8),
                    Text('Completed!', style: TextStyle(color: themeColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCircle() {
    final remaining = _secondsRemaining;
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: _isStarted ? _progress : 0,
              strokeWidth: 10,
              backgroundColor: context.cardBgColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                _timerFinished ? Colors.green : themeColor,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isStarted ? _formatTime(remaining) : _formatTime(_durationSeconds),
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isStarted
                    ? (_timerFinished ? 'Done!' : 'remaining')
                    : 'duration',
                style: TextStyle(color: context.subtextColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: themeColor, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: context.subtextColor, fontSize: 11)),
      ],
    );
  }
}