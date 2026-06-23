import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/setting/profile_page.dart';
import 'package:get_fit/Presentation/pages/setting/notifications_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/arms/arms_exercise_detail.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/back/back_exercise_detail.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/chest/chest_exercise_detail.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/core/core_exercise_detail.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/legs/legs_exercise_detail.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/shoulders/shoulders_exercise_detail.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _favorites = [];
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Video', 'Article'];
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getFavorites();
    if (mounted) setState(() { _favorites = data; _isLoading = false; });
  }

  Future<void> _removeFavorite(String exerciseId) async {
    try {
      await SupabaseService.toggleFavorite(
        exerciseId: exerciseId,
        title: '', image: '', category: '',
        level: '', sets: '', reps: '', rest: '', description: '',
      );
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from Favourites',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: themeColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[FAV] remove error: $e');
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _favorites;
    if (_selectedFilter == 1) {
      list = list.where((e) => (e['exercise_category'] ?? '').toString().toLowerCase().contains('video')).toList();
    } else if (_selectedFilter == 2) {
      list = list.where((e) => (e['exercise_category'] ?? '').toString().toLowerCase().contains('article')).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((e) =>
        (e['exercise_title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (e['exercise_category'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff111111) : const Color(0xffF2F2F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
                      backgroundColor: Colors.black54,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Favorites',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _isSearching = !_isSearching),
                    child: Icon(Icons.search, color: themeColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
                    child: Icon(Icons.notifications, color: themeColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
                    child: Icon(Icons.person, color: themeColor, size: 26),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter row
            // Filter row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Sort By',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...List.generate(_filters.length, (index) {
                    final selected = _selectedFilter == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = index),
                        child: Container(
                          margin: EdgeInsets.only(
                            left: index == 0 ? 0 : 6,
                          ),
                          height: 38,
                          decoration: BoxDecoration(
                            color: selected ? themeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: selected
                                  ? themeColor
                                  : (isDark ? Colors.white38 : Colors.grey.shade400),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _filters[index],
                              style: TextStyle(
                                color: selected ? Colors.black : context.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: TextStyle(color: context.subtextColor),
                    prefixIcon: Icon(Icons.search, color: themeColor),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() { _searchQuery = ''; _isSearching = false; });
                      },
                      child: Icon(Icons.close, color: context.subtextColor),
                    ),
                    filled: true,
                    fillColor: context.cardBgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading
                  ? _buildSkeleton(context)
                  : _favorites.isEmpty
                      ? _buildEmpty(context)
                      : RefreshIndicator(
                          color: themeColor,
                          backgroundColor: context.cardBgColor,
                          onRefresh: _loadFavorites,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                          itemBuilder: (context, index) =>
                              _buildCard(context, _filtered[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

 void _navigateToDetail(BuildContext context, Map<String, dynamic> exercise) {
    switch (exercise['category']) {
      case 'Arms':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ArmsExerciseDetail(exercise: exercise)));
        break;
      case 'Back':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BackExerciseDetail(exercise: exercise)));
        break;
      case 'Chest':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChestExerciseDetail(exercise: exercise)));
        break;
      case 'Core':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CoreExerciseDetail(exercise: exercise)));
        break;
      case 'Legs':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => LegsExerciseDetail(exercise: exercise)));
        break;
      case 'Shoulders':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ShouldersExerciseDetail(exercise: exercise)));
        break;
    }
  }

 Widget _buildCard(BuildContext context, Map<String, dynamic> item) {
  final isDark = context.isDark;
  return GestureDetector(
    onTap: () {
      final exercise = {
        'id': item['exercise_id'] ?? '',
        'title': item['exercise_title'] ?? '',
        'category': item['exercise_category'] ?? '',
        'description': item['exercise_description'] ?? '',
        'image_url': item['exercise_image'] ?? '',
        'sets': item['exercise_sets'] ?? '',
        'reps': item['exercise_reps'] ?? '',
        'rest': item['exercise_rest'] ?? '',
        'level': item['exercise_level'] ?? '',
      };
      _navigateToDetail(context, exercise);
    },
    child: Container(
    margin: const EdgeInsets.only(bottom: 16),
    height: 130,
    decoration: BoxDecoration(
      color: isDark ? Colors.white : const Color(0xff1E1E1E),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: [
        // Text side
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['exercise_title'] ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: themeColor, size: 13),
                    const SizedBox(width: 4),
                   Text(item['exercise_duration'] ?? '30 Minutes',
                        style: TextStyle(
                            color: isDark ? Colors.black54 : Colors.white70,
                            fontSize: 16)),
                    const SizedBox(width: 12),
                    Icon(Icons.local_fire_department, color: themeColor, size: 13),
                    const SizedBox(width: 4),
                    Text(item['exercise_kcal'] ?? '320 Kcal',
                        style: TextStyle(
                            color: isDark ? Colors.black54 : Colors.white70,
                            fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/running_man.svg',
                      width: 13,
                      height: 13,
                      colorFilter: const ColorFilter.mode(themeColor, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 4),
                    Text(item['exercise_count'] ?? '5 Exercises',
                        style: TextStyle(
                            color: isDark ? Colors.black54 : Colors.white70,
                            fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Image fills full right side, only right corners rounded via ClipRRect
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(30),
                topLeft: Radius.circular(30),

              ),
              child: Image.network(
                item['exercise_image'] ?? '',
                width: 190,
                height: 130,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stack) => Container(
                  width: 130,
                  height: 130,
                  color: isDark ? Colors.grey.shade200 : const Color(0xff3a3a3a),
                  child: Icon(Icons.fitness_center, color: themeColor, size: 36),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 130,
                    height: 130,
                    color: isDark ? Colors.grey.shade200 : const Color(0xff3a3a3a),
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: themeColor, strokeWidth: 2)),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeFavorite(item['exercise_id']),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: themeColor, size: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  );
}

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: context.subtextColor),
          const SizedBox(height: 16),
          Text('No favourites yet',
              style: TextStyle(
                  color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap the heart on any exercise to save it here',
              style: TextStyle(color: context.subtextColor, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ShimmerWidget(
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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