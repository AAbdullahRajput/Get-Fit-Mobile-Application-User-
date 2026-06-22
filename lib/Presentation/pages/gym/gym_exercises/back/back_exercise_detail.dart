import 'package:flutter/material.dart';
import 'package:get_fit/Domain/models/exercise_model.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class BackExerciseDetail extends StatefulWidget {
  final Exercise exercise;
  const BackExerciseDetail({super.key, required this.exercise});

  @override
  State<BackExerciseDetail> createState() => _BackExerciseDetailState();
}

class _BackExerciseDetailState extends State<BackExerciseDetail> {
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final result = await SupabaseService.isFavorite(widget.exercise.id);
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
        exerciseId: widget.exercise.id,
        title: widget.exercise.title,
        image: widget.exercise.imageUrl,
        category: widget.exercise.category,
        level: widget.exercise.level,
        sets: widget.exercise.sets,
        reps: widget.exercise.reps,
        rest: widget.exercise.rest,
        description: widget.exercise.description,
      );
      final nowFavorite = !_isFavorite;
      if (mounted) {
        setState(() => _isFavorite = nowFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowFavorite ? 'Added to Favourites' : 'Removed from Favourites',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            backgroundColor: themeColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('\x1B[31m[FAV] _toggleFavorite error: $e\x1B[0m');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFF4A5240),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
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
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(color: context.cardBgColor),
                    child: Stack(
                      children: [
                        Image.network(
                          widget.exercise.imageUrl,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            color: context.cardBgColor,
                            child: Icon(Icons.fitness_center, color: themeColor, size: 64),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20, left: 20, right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: _levelColor(widget.exercise.level), borderRadius: BorderRadius.circular(8)),
                                    child: Text(widget.exercise.level, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                    child: Text(widget.exercise.category, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(widget.exercise.title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.exercise.description, style: TextStyle(color: context.subtextColor, fontSize: 15, height: 1.6)),
                        const SizedBox(height: 20),
                        Text('Workout Details', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _detailChip(context, 'Sets', widget.exercise.sets),
                            const SizedBox(width: 12),
                            _detailChip(context, 'Reps', widget.exercise.reps),
                            const SizedBox(width: 12),
                            _detailChip(context, 'Rest', widget.exercise.rest),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Target Muscles', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _muscleChip(context, 'Latissimus Dorsi'),
                            _muscleChip(context, 'Rhomboids'),
                            _muscleChip(context, 'Trapezius'),
                            _muscleChip(context, 'Erector Spinae'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Equipment Needed', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
                          child: Text('Pull-up Bar', style: TextStyle(color: context.textColor, fontSize: 14)),
                        ),
                        const SizedBox(height: 20),
                        Text('Video Tutorial', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_circle_filled, size: 64, color: themeColor),
                                const SizedBox(height: 8),
                                Text('Tap to play video', style: TextStyle(color: context.subtextColor, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Step by Step Instructions', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              _instructionItem(context, '1', 'Hang from the bar with an overhand grip'),
                              _instructionItem(context, '2', 'Pull your body up until your chin passes the bar'),
                              _instructionItem(context, '3', 'Lower yourself back down with control'),
                              _instructionItem(context, '4', 'Repeat for desired reps'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Start Workout', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
                              child: _isLoading
                                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: themeColor)))
                                  : IconButton(
                                      icon: Icon(
                                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: _isFavorite ? themeColor : context.textColor,
                                        size: 28,
                                      ),
                                      onPressed: _isToggling ? null : _toggleFavorite,
                                    ),
                            ),
                          ],
                        ),
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
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner': return Colors.green;
      case 'Intermediate': return Colors.orange;
      case 'Advanced': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _detailChip(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: context.cardBgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: context.subtextColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _muscleChip(BuildContext context, String muscle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? themeColor.withOpacity(0.2) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(muscle, style: TextStyle(color: isDark ? themeColor : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _instructionItem(BuildContext context, String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: themeColor, shape: BoxShape.circle),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(instruction, style: TextStyle(color: context.textColor, fontSize: 14))),
        ],
      ),
    );
  }
}