import 'package:flutter/material.dart';
import 'package:get_fit/Domain/models/exercise_model.dart';
import 'package:get_fit/Utils/constants.dart';

class GymPage extends StatefulWidget {
  const GymPage({super.key});

  @override
  State<GymPage> createState() => _GymPageState();
}

class _GymPageState extends State<GymPage> {
  static bool _hasLoaded = false;
  bool _isLoading = true;
  int selectedCategory = 0;

  final List<String> categories = [
    'All', 'Chest', 'Back', 'Shoulders', 'Legs', 'Arms', 'Core'
  ];

  List<Exercise> get filteredExercises {
    if (selectedCategory == 0) return dummyExercises;
    return dummyExercises
        .where((e) => e.category == categories[selectedCategory])
        .toList();
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) _loadData();
  }

  Future<void> _loadData() async {
    if (_hasLoaded) {
      setState(() => _isLoading = false);
      return;
    }
    // Precache all exercise images
    await Future.wait(
      dummyExercises.map(
        (e) => precacheImage(NetworkImage(e.imageUrl), context),
      ),
    );
    if (mounted) {
      _hasLoaded = true;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 800)),
      ...dummyExercises.map(
        (e) => precacheImage(NetworkImage(e.imageUrl), context),
      ),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gym',
                    style: TextStyle(
                      color: context.isDark ? themeColor : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.local_fire_department,
                            color: Colors.black, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '5 Day Streak',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category Filter
            SizedBox(
              height: 35,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final selected = selectedCategory == index;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => selectedCategory = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? themeColor : context.cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? null
                            : Border.all(
                                color: context.isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                      ),
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: selected ? Colors.black : context.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Exercise count
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                '${filteredExercises.length} exercises',
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Exercise Cards
            Expanded(
              child: RefreshIndicator(
                color: context.subtextColor,
                backgroundColor: context.cardBgColor,
                onRefresh: _onRefresh,
                child: _isLoading
                ? _buildSkeleton(context)
                : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return _exerciseCard(context, exercise);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _ShimmerWidget(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xff3a3a3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _exerciseCard(BuildContext context, Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image - using cacheWidth for better performance
            Positioned.fill(
              child: Image.network(
                exercise.imageUrl,
                fit: BoxFit.cover,
                cacheWidth: 600, // Limit cache size
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: context.cardBgColor,
                    child: const Center(
                      child: CircularProgressIndicator(color: themeColor),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  color: context.cardBgColor,
                  child: const Icon(Icons.fitness_center,
                      color: themeColor, size: 48),
                ),
              ),
            ),

            // Dark gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _levelColor(exercise.level).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exercise.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      exercise.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      exercise.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Sets / Reps / Rest chips + Arrow
                    Row(
                      children: [
                        _chip(exercise.sets),
                        const SizedBox(width: 8),
                        _chip(exercise.reps),
                        const SizedBox(width: 8),
                        _chip(exercise.rest),
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}