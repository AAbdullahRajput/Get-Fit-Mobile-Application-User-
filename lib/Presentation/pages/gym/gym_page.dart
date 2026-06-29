import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/legs/legs_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/shoulders/shoulders_exercises_screen.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/chest/chest_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/back/back_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/arms/arms_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/gym/gym_exercises/core/core_exercises_screen.dart';
import 'package:get_fit/Presentation/pages/setting/setting_home_page.dart';
import 'package:get_fit/Presentation/pages/setting/notifications_page.dart';
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

  void _openSearch(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 80;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _GymSearchDialog(
        exercises: _exercises,
        availableHeight: availableHeight.clamp(300.0, screenHeight * 0.88),
        onNavigate: _navigateToCategoryScreen,
      ),
    );
  }

  void _navigateToCategoryScreen(String category) {
    switch (category) {
      case 'Chest':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChestExercisesScreen()));
        break;
      case 'Back':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BackExercisesScreen()));
        break;
      case 'Shoulders':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ShouldersExercisesScreen()));
        break;
      case 'Legs':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LegsExercisesScreen()));
        break;
      case 'Arms':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ArmsExercisesScreen()));
        break;
      case 'Core':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CoreExercisesScreen()));
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
            // ── Header ──
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
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _openSearch(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.search,
                              color: isDark ? themeColor : Colors.black, size: 26),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsPage()),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.notifications,
                              color: isDark ? themeColor : Colors.black, size: 26),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingHomePage()),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.settings,
                              color: isDark ? themeColor : Colors.black, size: 26),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Category Filter ──
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

            // ── Exercise count ──
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                '${_exercises.length} exercises',
                style: TextStyle(color: context.subtextColor, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),

            // ── Exercise Cards ──
            Expanded(
              child: RefreshIndicator(
                color: _accent(context),
                backgroundColor: context.cardBgColor,
                onRefresh: _onRefresh,
                child: _isLoading
                    ? _buildSkeleton(context)
                    : ListView.builder(
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
                                        child: CircularProgressIndicator(
                                            color: _accent(context), strokeWidth: 2.5),
                                      )),
                                    ),
                                  if (!_isLoadingMore && _hasMore)
                                    OutlinedButton(
                                      onPressed: _loadMore,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _accent(context),
                                        side: BorderSide(color: _accent(context)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        minimumSize: const Size(double.infinity, 0),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.expand_more, size: 18),
                                          SizedBox(width: 6),
                                          Text('Show More',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  if (!_isLoadingMore && _hasMore && _hasLess)
                                    const SizedBox(height: 8),
                                  if (!_isLoadingMore && _hasLess)
                                    OutlinedButton(
                                      onPressed: _loadExercises,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey,
                                        side: const BorderSide(color: Colors.grey),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        minimumSize: const Size(double.infinity, 0),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.expand_less, size: 18),
                                          SizedBox(width: 6),
                                          Text('Show Less',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  if (!_isLoadingMore && !_hasMore && !_hasLess)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text('All exercises loaded',
                                          style: TextStyle(
                                              color: Colors.grey.shade500, fontSize: 13)),
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
                  fit: BoxFit.cover,
                  cacheWidth: 600,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: context.cardBgColor,
                      child: const Center(
                          child: CircularProgressIndicator(color: Colors.black)),
                    );
                  },
                  errorBuilder: (context, error, stack) => Container(
                    color: context.cardBgColor,
                    child: Icon(Icons.fitness_center,
                        color: _accent(context), size: 48),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black
                      ],
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _levelColor(level).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(level,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(category,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('View $category Exercises →',
                              style: TextStyle(
                                  color: _accent(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
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

// ─────────────────────────────────────────────
// GYM SEARCH DIALOG
// ─────────────────────────────────────────────

class _GymSearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final double availableHeight;
  final void Function(String category) onNavigate;

  const _GymSearchDialog({
    required this.exercises,
    required this.availableHeight,
    required this.onNavigate,
  });

  @override
  State<_GymSearchDialog> createState() => _GymSearchDialogState();
}

class _GymSearchDialogState extends State<_GymSearchDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    setState(() => _isLoading = true);
    final q = query.trim().toLowerCase();

    // Search from already-loaded exercises first, then fetch more
    final allExercises = await SupabaseService.getGymExercises(pageSize: 100);
    final filtered = allExercises.where((e) =>
        (e['title'] ?? '').toString().toLowerCase().contains(q) ||
        (e['category'] ?? '').toString().toLowerCase().contains(q) ||
        (e['level'] ?? '').toString().toLowerCase().contains(q) ||
        (e['description'] ?? '').toString().toLowerCase().contains(q)).toList();

    if (mounted) {
      setState(() {
        _results = filtered;
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner': return Colors.green;
      case 'Intermediate': return Colors.orange;
      case 'Advanced': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
      child: SizedBox(
        height: widget.availableHeight,
        child: Container(
          decoration: BoxDecoration(
            color: context.bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.cardBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: TextStyle(color: context.textColor),
                          decoration: InputDecoration(
                            hintText: 'Search exercises, categories...',
                            hintStyle: TextStyle(
                                color: context.subtextColor, fontSize: 13),
                            prefixIcon:
                                const Icon(Icons.search, color: themeColor),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: _search,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: themeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Flexible(
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: themeColor, strokeWidth: 2),
                      )
                    : !_hasSearched
                        ? Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fitness_center,
                                    color: themeColor, size: 44),
                                const SizedBox(height: 10),
                                Text('Search gym exercises',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 14)),
                                const SizedBox(height: 6),
                                Text('By name, category, or difficulty',
                                    style: TextStyle(
                                        color:
                                            context.subtextColor.withOpacity(0.6),
                                        fontSize: 12)),
                              ],
                            ),
                          )
                        : _results.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off,
                                        color: context.subtextColor, size: 44),
                                    const SizedBox(height: 10),
                                    Text('No exercises found',
                                        style: TextStyle(
                                            color: context.subtextColor,
                                            fontSize: 14)),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: themeColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const Icon(Icons.sports_gymnastics,
                                            color: themeColor, size: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${_results.length} results',
                                          style: TextStyle(
                                              color: context.textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold)),
                                    ]),
                                    const SizedBox(height: 12),
                                    ..._results.map((e) {
                                      final category = e['category'] ?? '';
                                      final level = e['level'] ?? '';
                                      final title = e['title'] ?? '';
                                      final imageUrl = e['image_url'] ?? '';

                                      return GestureDetector(
                                        onTap: () {
                                          final nav = Navigator.of(context);
                                          nav.pop();
                                          widget.onNavigate(category);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: context.cardBgColor,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: imageUrl.isNotEmpty
                                                    ? Image.network(imageUrl,
                                                        width: 62,
                                                        height: 62,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) =>
                                                            _imgFallback(context))
                                                    : _imgFallback(context),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(title,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            color:
                                                                context.textColor,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold)),
                                                    const SizedBox(height: 4),
                                                    Text(category,
                                                        style: TextStyle(
                                                            color: context
                                                                .subtextColor,
                                                            fontSize: 12)),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: _levelColor(level)
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                6),
                                                      ),
                                                      child: Text(level,
                                                          style: TextStyle(
                                                              color:
                                                                  _levelColor(level),
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight.bold)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_ios,
                                                  size: 14, color: Colors.grey),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
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

  Widget _imgFallback(BuildContext context) => Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xff3a3a3a),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.fitness_center, color: Colors.white38, size: 26),
      );
}

// ─────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────

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