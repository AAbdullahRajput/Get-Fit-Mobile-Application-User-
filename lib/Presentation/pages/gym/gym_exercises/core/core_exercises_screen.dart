import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/core/core_exercise_detail.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

Color _accent(BuildContext context) {
  return context.isDark ? themeColor : const Color(0xFF6B7A00);
}

class CoreExercisesScreen extends StatefulWidget {
  const CoreExercisesScreen({super.key});

  @override
  State<CoreExercisesScreen> createState() => _CoreExercisesScreenState();
}

class _CoreExercisesScreenState extends State<CoreExercisesScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 7;
  List<Map<String, dynamic>> _exercises = [];

  bool get _hasLess => _exercises.length > _pageSize;

  @override
  bool get wantKeepAlive => true;

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner': return Colors.green;
      case 'Intermediate': return Colors.orange;
      case 'Advanced': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() { _isLoading = true; _page = 0; _hasMore = true; _exercises = []; });
    final data = await SupabaseService.getGymExercises(category: 'Core', page: 0, pageSize: _pageSize);
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
    final data = await SupabaseService.getGymExercises(category: 'Core', page: _page, pageSize: _pageSize);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Core Exercises',
          style: TextStyle(
            color: context.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: _accent(context),
backgroundColor: context.cardBgColor,
        displacement: 100,
        onRefresh: _onRefresh,
        child: _isLoading ? _buildSkeleton(context) : _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: context.subtextColor),
            const SizedBox(height: 16),
            Text('No core exercises available', style: TextStyle(color: context.subtextColor, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  child: Center(child: SizedBox(width: 28, height: 28,
    child: CircularProgressIndicator(color: _accent(context), strokeWidth: 2.5))),
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
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.expand_more, size: 18), SizedBox(width: 6),
                        Text('Show More', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
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
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.expand_less, size: 18), SizedBox(width: 6),
                        Text('Show Less', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
                  ),
              ],
            ),
          );
        }
        final exercise = _exercises[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoreExerciseDetail(exercise: exercise),
                ),
              );
            },
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        exercise['image_url'] ?? '',
                        fit: BoxFit.cover,
                        cacheWidth: 600,
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
                                    color: _levelColor(exercise['level'] ?? '').withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(exercise['level'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text(exercise['category'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(exercise['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(exercise['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _chip(exercise['sets'] ?? ''),
                                const SizedBox(width: 8),
                                _chip(exercise['reps'] ?? ''),
                                const SizedBox(width: 8),
                                _chip(exercise['rest'] ?? ''),
                                const Spacer(),
                                Container(
                                  width: 32, height: 32,
                                  decoration: const BoxDecoration(color: themeColor, shape: BoxShape.circle),
                                  child: const Icon(Icons.arrow_forward, color: Colors.black, size: 16),
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
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ShimmerWidget(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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