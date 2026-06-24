import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/legs/legs_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/shoulders/shoulders_exercises_screen.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/chest/chest_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/back/back_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/arms/arms_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/core/core_exercises_screen.dart';
import 'package:flutter/foundation.dart';

Color _accent(BuildContext context) {
  return context.isDark ? themeColor : const Color(0xFF6B7A00);
}

class GymPage extends StatefulWidget {
  const GymPage({super.key});

  @override
  State<GymPage> createState() => _GymPageState();
}

class _GymPageState extends State<GymPage> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 7;
  int selectedCategory = 0;
  List<Map<String, dynamic>> _exercises = [];

  final List<String> categories = const [
    'All', 'Chest', 'Back', 'Shoulders', 'Legs', 'Arms', 'Core'
  ];

  @override
  bool get wantKeepAlive => true;

  String? get _selectedCategory =>
      selectedCategory == 0 ? null : categories[selectedCategory];

  bool get _hasLess => _exercises.length > _pageSize;

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
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() { _isLoading = true; _page = 0; _hasMore = true; _exercises = []; });
    final data = await SupabaseService.getGymExercises(
      category: _selectedCategory,
      page: 0,
      pageSize: _pageSize,
    );
    if (mounted) setState(() {
      _exercises = data;
      _isLoading = false;
      _hasMore = data.length == _pageSize;
      _page = 1;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final data = await SupabaseService.getGymExercises(
      category: _selectedCategory,
      page: _page,
      pageSize: _pageSize,
    );
    if (mounted) setState(() {
      _exercises.addAll(data);
      _isLoadingMore = false;
      _hasMore = data.length == _pageSize;
      _page++;
    });
  }

  Future<void> _onRefresh() async {
    _loadExercises();
  }

  void _navigateToCategoryScreen(String category) {
    switch(category) {
      case 'Chest':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChestExercisesScreen()));
        break;
      case 'Back':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BackExercisesScreen()));
        break;
      case 'Shoulders':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ShouldersExercisesScreen()));
        break;
      case 'Legs':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LegsExercisesScreen()));
        break;
      case 'Arm':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ArmsExercisesScreen()));
        break;
      case 'Core':
        case 'Core':
        Navigator.push(context,MaterialPageRoute(builder: (context) => const CoreExercisesScreen(),),);
        break;
      default:
        _showComingSoon(category);
    }
  }

  void _showComingSoon(String category) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: context.bgColor,
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fitness_center, color: _accent(context), size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon!',
                  style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$category exercises are being added.\nStay tuned for updates!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.subtextColor, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Got it!', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.isDark;
    
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
                      color: isDark ? themeColor : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.black, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '5 Day Streak',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
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
                    onTap: () {
                      setState(() { selectedCategory = index; });
                      _loadExercises();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? themeColor : context.cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? null
                            : Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
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
                '${_exercises.length} exercises',
                style: TextStyle(color: context.subtextColor, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            
            // Exercise Cards
            Expanded(
              child: RefreshIndicator(
                color: _accent(context),
backgroundColor: context.cardBgColor,
                onRefresh: _onRefresh,
                child: _isLoading
                    ? _buildSkeleton(context)
                    : RefreshIndicator(
                        color: _accent(context),
backgroundColor: context.cardBgColor,
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _exercises.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _exercises.length) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  children: [
                                    if (_isLoadingMore)
                                      Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: Center(child: SizedBox(
                                            width: 28, height: 28,
                                            child: CircularProgressIndicator(color: _accent(context), strokeWidth: 2.5),
                                          )),
                                        ),
                                    if (!_isLoadingMore && _hasMore)
                                      OutlinedButton(
                                        onPressed: _loadMore,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _accent(context),
side: BorderSide(color: _accent(context)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          minimumSize: const Size(double.infinity, 0),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.expand_more, size: 18),
                                            SizedBox(width: 6),
                                            Text('Show More', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    if (!_isLoadingMore && _hasMore && _hasLess) const SizedBox(height: 8),
                                    if (!_isLoadingMore && _hasLess)
                                      OutlinedButton(
                                        onPressed: _loadExercises,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                          side: const BorderSide(color: Colors.grey),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          minimumSize: const Size(double.infinity, 0),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.expand_less, size: 18),
                                            SizedBox(width: 6),
                                            Text('Show Less', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    if (!_isLoadingMore && !_hasMore && !_hasLess)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text('All exercises loaded',
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                      ),
                                  ],
                                ),
                              );
                            }
                            final e = _exercises[index];
                            return _exerciseCard(context, e);
                          },
                        ),
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
            height: 180,
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _exerciseCard(BuildContext context, Map<String, dynamic> exercise) {
    final isDark = context.isDark;
    final category = exercise['category'] ?? '';
    final level = exercise['level'] ?? '';
    final title = exercise['title'] ?? '';
    final description = exercise['description'] ?? '';
    final imageUrl = exercise['image_url'] ?? '';

    return GestureDetector(
      onTap: () => _navigateToCategoryScreen(category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
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
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.fill,
                  cacheWidth: 600,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: context.cardBgColor,
                      child: const Center(child: CircularProgressIndicator(color: Colors.black)),
                    );
                  },
                  errorBuilder: (context, error, stack) => Container(
                    color: context.cardBgColor,
                    child: Icon(Icons.fitness_center, color: _accent(context), size: 48),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _levelColor(level).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(level, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('View $category Exercises →', style: TextStyle(color: _accent(context), fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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