import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

class ArmsExerciseDetail extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const ArmsExerciseDetail({super.key, required this.exercise});

  @override
  State<ArmsExerciseDetail> createState() => _ArmsExerciseDetailState();
}

class _ArmsExerciseDetailState extends State<ArmsExerciseDetail> {
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isToggling = false;

  // steps
  List<Map<String, dynamic>> _steps = [];
  bool _stepsLoading = true;
  bool _stepsExpanded = false;
  static const int _stepsPageSize = 2;
  int _stepsShown = 2;
  String _gender = 'Male';

  // workout state
  bool _workoutActive = false;
  bool _doneToday = false;
  bool _checkingDone = true;
  int _currentSet = 0;
  int _totalSets = 0;
  int _repsPerSet = 0;
  int _restSeconds = 0;
  int _timerSeconds = 0;
  bool _resting = false;
  bool _setDone = false;
  Timer? _timer;
  int _totalDurationSeconds = 0;
  int _totalCalories = 0;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _parseSetsReps();
    _checkDoneToday();
    _loadStepsAndGender();
  }

  void _parseSetsReps() {
    final setsStr = widget.exercise['sets'] ?? '3 sets';
    final repsStr = widget.exercise['reps'] ?? '10 reps';
    final restStr = widget.exercise['rest'] ?? 'Rest 45s';
    final kcalStr = widget.exercise['kcal'] ?? '200 Kcal';
    _totalSets = int.tryParse(RegExp(r'\d+').firstMatch(setsStr)?.group(0) ?? '3') ?? 3;
    _repsPerSet = int.tryParse(RegExp(r'\d+').firstMatch(repsStr)?.group(0) ?? '10') ?? 10;
    _restSeconds = int.tryParse(RegExp(r'\d+').firstMatch(restStr)?.group(0) ?? '45') ?? 45;
    _totalCalories = int.tryParse(RegExp(r'\d+').firstMatch(kcalStr)?.group(0) ?? '200') ?? 200;
  }

  Future<void> _loadStepsAndGender() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId != null) {
      final setup = await SupabaseService.getUserSetup(userId);
      if (mounted) setState(() => _gender = setup?['gender'] ?? 'Male');
    }
    final steps = await SupabaseService.getGymExerciseSteps(widget.exercise['id'] ?? '');
    if (mounted) setState(() { _steps = steps; _stepsLoading = false; });
  }

  Future<void> _checkDoneToday() async {
    final done = await SupabaseService.isGymExerciseDoneToday(widget.exercise['id'] ?? '');
    if (mounted) setState(() { _doneToday = done; _checkingDone = false; });
  }

  Future<void> _checkFavorite() async {
    try {
      final result = await SupabaseService.isFavorite(widget.exercise['id']);
      if (mounted) setState(() { _isFavorite = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      await SupabaseService.toggleFavorite(
        exerciseId: widget.exercise['id'],
        title: widget.exercise['title'],
        image: widget.exercise['image_url'],
        category: widget.exercise['category'],
        level: widget.exercise['level'],
        sets: widget.exercise['sets'],
        reps: widget.exercise['reps'],
        rest: widget.exercise['rest'],
        description: widget.exercise['description'],
      );
      final nowFav = !_isFavorite;
      if (mounted) {
        setState(() => _isFavorite = nowFav);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(nowFav ? 'Added to Favourites' : 'Removed from Favourites',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: themeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  void _startWorkout() {
    setState(() {
      _workoutActive = true;
      _currentSet = 1;
      _resting = false;
      _setDone = false;
      _timerSeconds = 0;
      _totalDurationSeconds = 0;
    });
    _startSetTimer();
  }

  void _startSetTimer() {
    _timer?.cancel();
    setState(() { _timerSeconds = 0; _setDone = false; _resting = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timerSeconds++);
    });
  }

  void _markSetDone() {
    _timer?.cancel();
    final setDurationSecs = _timerSeconds;
    final kcalPerSet = (_totalCalories / _totalSets).round();
    SupabaseService.logGymSet(
      exerciseId: widget.exercise['id'] ?? '',
      exerciseTitle: widget.exercise['title'] ?? '',
      category: widget.exercise['category'] ?? 'Arms',
      setNumber: _currentSet,
      repsCompleted: _repsPerSet,
      durationSeconds: setDurationSecs,
      caloriesBurned: kcalPerSet,
    );
    setState(() { _totalDurationSeconds += setDurationSecs; _setDone = true; });
    if (_currentSet >= _totalSets) {
      _showSuccessSheet();
    } else {
      _startRest();
    }
  }

  void _startRest() {
    setState(() { _resting = true; _timerSeconds = _restSeconds; _setDone = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timerSeconds <= 1) {
        _timer?.cancel();
        setState(() { _currentSet++; });
        _startSetTimer();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() { _currentSet++; });
    _startSetTimer();
  }

  void _showSuccessSheet() {
    setState(() { _workoutActive = false; _doneToday = true; });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        title: widget.exercise['title'] ?? '',
        totalSets: _totalSets,
        totalCalories: _totalCalories,
        totalSeconds: _totalDurationSeconds,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section('Description'),
                        const SizedBox(height: 8),
                        Text(widget.exercise['description'] ?? '',
                            style: TextStyle(color: context.subtextColor, fontSize: 15, height: 1.6)),
                        const SizedBox(height: 20),
                        _section('Workout Details'),
                        const SizedBox(height: 12),
                        Row(children: [
                          _detailChip(context, 'Sets', widget.exercise['sets'] ?? ''),
                          const SizedBox(width: 12),
                          _detailChip(context, 'Reps', widget.exercise['reps'] ?? ''),
                          const SizedBox(width: 12),
                          _detailChip(context, 'Rest', widget.exercise['rest'] ?? ''),
                        ]),
                        const SizedBox(height: 20),
                        _section('Target Muscles'),
                        const SizedBox(height: 8),
                        _buildMuscles(),
                        const SizedBox(height: 20),
                        _section('Equipment Needed'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(widget.exercise['equipment'] ?? 'See description',
                              style: TextStyle(color: context.textColor, fontSize: 14)),
                        ),
                        const SizedBox(height: 20),
                        _section('Step by Step Instructions'),
                        const SizedBox(height: 8),
                        _buildSteps(),
                        const SizedBox(height: 20),
                        if (_workoutActive) _buildWorkoutPanel() else _buildStartRow(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () { _timer?.cancel(); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps() {
    if (_stepsLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
        child: Center(child: CircularProgressIndicator(color: _accent(context), strokeWidth: 2)),
      );
    }
    if (_steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
        child: Text('No steps available.', style: TextStyle(color: context.subtextColor)),
      );
    }

    final isMale = _gender.toLowerCase() == 'male';
    final visibleSteps = _steps.take(_stepsShown).toList();
    final hasMore = _stepsShown < _steps.length;
    final hasLess = _stepsShown > _stepsPageSize;

    return Column(
      children: [
        ...visibleSteps.asMap().entries.map((e) {
          final step = e.value;
          final imgUrl = isMale
              ? (step['male_image_url'] ?? step['female_image_url'] ?? '')
              : (step['female_image_url'] ?? step['male_image_url'] ?? '');
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.cardBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imgUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Image.network(
                      imgUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              height: 180,
                              color: context.cardBgColor,
                              child: Center(child: CircularProgressIndicator(
                                  color: _accent(context), strokeWidth: 2)),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        color: context.cardBgColor,
                        child: Icon(Icons.fitness_center, color: _accent(context), size: 40),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(color: themeColor, shape: BoxShape.circle),
                        child: Center(child: Text('${step['step_number']}',
                            style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(step['instruction'] ?? '',
                          style: TextStyle(color: context.textColor, fontSize: 14, height: 1.5))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (hasMore)
          OutlinedButton(
            onPressed: () => setState(() => _stepsShown += _stepsPageSize),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent(context),
              side: BorderSide(color: _accent(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.expand_more, size: 18),
              const SizedBox(width: 6),
              Text('Show More Steps (${_steps.length - _stepsShown} left)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
        if (hasLess) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => _stepsShown = _stepsPageSize),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.expand_less, size: 18),
              SizedBox(width: 6),
              Text('Show Less', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      height: 280, width: double.infinity, color: context.cardBgColor,
      child: Stack(children: [
        Image.network(widget.exercise['image_url'] ?? '',
            width: double.infinity, height: 280, fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => Container(
                color: context.cardBgColor,
                child: Icon(Icons.fitness_center, color: _accent(context), size: 64))),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)]),
        ))),
        Positioned(bottom: 20, left: 20, right: 20, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _badge(_levelColor(widget.exercise['level'] ?? ''), widget.exercise['level'] ?? ''),
              const SizedBox(width: 8),
              _badge(Colors.white.withOpacity(0.2), widget.exercise['category'] ?? ''),
            ]),
            const SizedBox(height: 8),
            Text(widget.exercise['title'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          ],
        )),
      ]),
    );
  }

  Widget _buildMuscles() {
    final raw = widget.exercise['target_muscles'];
    List<String> muscles = [];
    if (raw is List) muscles = raw.map((e) => e.toString()).toList();
    else if (raw is String && raw.isNotEmpty) muscles = [raw];
    if (muscles.isEmpty) muscles = ['See description'];
    return Wrap(spacing: 8, runSpacing: 8,
        children: muscles.map((m) => _muscleChip(context, m)).toList());
  }

  Widget _buildStartRow() {
    return Row(children: [
      Expanded(
        child: _checkingDone
            ? Container(
                height: 52,
                decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
                child: Center(child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accent(context)))))
            : _doneToday
            ? Container(
                height: 52,
                decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, color: themeColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Done Today — Come Back Tomorrow',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              )
            : ElevatedButton(
                onPressed: _startWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Workout',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
      ),
      const SizedBox(width: 12),
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
        child: _isLoading
            ? Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _accent(context))))
            : IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? _accent(context) : context.textColor, size: 28),
                onPressed: _isToggling ? null : _toggleFavorite,
              ),
      ),
    ]);
  }

  Widget _buildWorkoutPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Set $_currentSet of $_totalSets',
              style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('$_repsPerSet reps',
              style: TextStyle(color: _accent(context), fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSets, (i) {
              final done = i < _currentSet - 1;
              final current = i == _currentSet - 1;
              return Column(children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: current ? 32 : 24,
                  height: current ? 32 : 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? themeColor : current ? themeColor.withOpacity(0.3) : context.bgColor,
                    border: Border.all(color: themeColor, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 13, color: Colors.black)
                      : Center(child: Text('${i + 1}',
                          style: TextStyle(
                            color: current ? themeColor : Colors.grey,
                            fontSize: 11, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 4),
                Text('Set ${i + 1}', style: TextStyle(
                  color: current ? themeColor : done ? Colors.grey.shade500 : Colors.grey.shade700,
                  fontSize: 10,
                  fontWeight: current ? FontWeight.bold : FontWeight.normal,
                )),
              ]);
            }),
          ),
        ),
        const SizedBox(height: 16),
        if (_resting) ...[
          Text('Rest before Set ${_currentSet + 1}',
              style: TextStyle(color: themeColor, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$_timerSeconds s',
              style: TextStyle(color: themeColor, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: OutlinedButton(
              onPressed: _skipRest,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent(context),
                side: BorderSide(color: _accent(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Skip Rest', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ] else ...[
          Text('Set $_currentSet of $_totalSets',
              style: TextStyle(color: themeColor, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${_timerSeconds ~/ 60}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(color: context.textColor, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _setDone ? null : _markSetDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                disabledBackgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentSet >= _totalSets ? 'Finish Workout' : 'Mark Set Done',
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: () { _timer?.cancel(); setState(() => _workoutActive = false); },
          child: Text('Cancel Workout', style: TextStyle(color: context.subtextColor, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _section(String title) =>
      Text(title, style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold));

  Widget _badge(Color color, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner': return Colors.green;
      case 'Intermediate': return Colors.orange;
      case 'Advanced': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _detailChip(BuildContext context, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: context.subtextColor, fontSize: 12)),
      ]),
    ),
  );

  Widget _muscleChip(BuildContext context, String muscle) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: context.isDark ? themeColor.withOpacity(0.2) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(muscle, style: TextStyle(
        color: context.isDark ? themeColor : Colors.black87,
        fontSize: 13, fontWeight: FontWeight.w500)),
  );
}

class _SuccessSheet extends StatelessWidget {
  final String title;
  final int totalSets;
  final int totalCalories;
  final int totalSeconds;
  const _SuccessSheet({required this.title, required this.totalSets,
      required this.totalCalories, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return Container(
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(width: 72, height: 72,
            decoration: const BoxDecoration(color: themeColor, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.black, size: 40)),
        const SizedBox(height: 16),
        Text('Workout Complete!',
            style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: context.subtextColor, fontSize: 14)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat(context, Icons.fitness_center, '$totalSets', 'Sets'),
          _stat(context, Icons.local_fire_department, '$totalCalories', 'Kcal'),
          _stat(context, Icons.timer, '${mins}m ${secs}s', 'Time'),
        ]),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done',
                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label) => Column(children: [
    Icon(icon, color: themeColor, size: 28),
    const SizedBox(height: 6),
    Text(value, style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: TextStyle(color: context.subtextColor, fontSize: 12)),
  ]);
}