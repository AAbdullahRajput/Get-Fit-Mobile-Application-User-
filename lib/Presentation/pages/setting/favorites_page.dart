import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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
                  Icon(Icons.search, color: themeColor, size: 26),
                  const SizedBox(width: 16),
                  Icon(Icons.notifications_outlined, color: themeColor, size: 26),
                  const SizedBox(width: 16),
                  Icon(Icons.person_outline, color: themeColor, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Sort By',
                      style: TextStyle(
                          color: themeColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          final selected = _selectedFilter == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilter = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: selected ? themeColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? themeColor : (isDark ? Colors.white54 : Colors.grey.shade400),
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
                          );
                        },
                      ),
                    ),
                  ),
                ],
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
                            itemCount: _favorites.length,
                            itemBuilder: (context, index) =>
                                _buildCard(context, _favorites[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildCard(BuildContext context, Map<String, dynamic> item) {
  final isDark = context.isDark;
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    height: 130,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xff2C2C2C) : Colors.white,
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
                    color: isDark ? Colors.white : Colors.black,
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
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.local_fire_department, color: themeColor, size: 13),
                    const SizedBox(width: 4),
                    Text(item['exercise_kcal'] ?? '320 Kcal',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12)),
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
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12)),
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
                  color: isDark ? const Color(0xff3a3a3a) : Colors.grey.shade200,
                  child: Icon(Icons.fitness_center, color: themeColor, size: 36),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 130,
                    height: 130,
                    color: isDark ? const Color(0xff3a3a3a) : Colors.grey.shade200,
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