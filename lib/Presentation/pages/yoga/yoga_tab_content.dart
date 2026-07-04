import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_motivation_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_challenge_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_feed_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_course_card.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_booking_page.dart';
import 'package:get_fit/Presentation/pages/yoga/instructor_class_detail_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_detail_page.dart';
import 'package:get_fit/Presentation/pages/setting/setting_home_page.dart';
import 'package:get_fit/Presentation/pages/setting/notifications_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaTabContent extends StatefulWidget {
  const YogaTabContent({super.key});

  @override
  State<YogaTabContent> createState() => _YogaTabContentState();
}

class _YogaTabContentState extends State<YogaTabContent> {
  List<Map<String, dynamic>> _allItems = [];
  Set<String> _purchasedIds = {};
  bool _isLoading = true;
  int _visibleCount = 5;
  static const int _pageSize = 5;
  int _selectedFilter = 0; // 0 = All, 1 = Free, 2 = Paid
  int _feedRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadYogas();
  }

  Future<void> _loadYogas() async {
    setState(() {
      _isLoading = true;
      _visibleCount = _pageSize;
    });

    final freeClasses = await SupabaseService.getAllYogaClasses();
    final paidCourses = await SupabaseService.getAllPaidClasses();
    final purchased = await SupabaseService.getPurchasedClassIds();

    final tagged = <Map<String, dynamic>>[
      ...freeClasses.map((c) => {...c, '_kind': 'free'}),
      ...paidCourses.map((c) => {...c, '_kind': 'paid'}),
    ];

    if (mounted) {
      setState(() {
        _allItems = tagged;
        _purchasedIds = purchased;
        _isLoading = false;
        _feedRefreshKey++;
      });
    }
  }

  void _loadMore() {
    setState(() {
      _visibleCount =
          (_visibleCount + _pageSize).clamp(0, _filteredItems.length);
    });
  }

  List<Map<String, dynamic>> get _filteredItems {
  if (_selectedFilter == 0) return _allItems;
  if (_selectedFilter == 1) {
    return _allItems.where((c) => c['_kind'] == 'free').toList();
  }
  if (_selectedFilter == 2) {
    // Paid tab: only show paid courses NOT yet purchased
    return _allItems
        .where((c) =>
            c['_kind'] == 'paid' && !_purchasedIds.contains(c['id'] as String))
        .toList();
  }
  // Owned tab: only purchased courses
  return _allItems
      .where((c) =>
          c['_kind'] == 'paid' && _purchasedIds.contains(c['id'] as String))
      .toList();
}

  void _openSearch(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _YogaSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: themeColor,
          backgroundColor: context.cardBgColor,
          displacement: 100,
          onRefresh: _loadYogas,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(context),
                const SizedBox(height: 20),
                const YogaMotivationCard(),
                const SizedBox(height: 24),
                _buildYogasSection(context),
                const SizedBox(height: 24),
                const YogaChallengeCard(),
                const SizedBox(height: 24),
                YogaFeedCard(key: ValueKey(_feedRefreshKey)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? themeColor : Colors.black;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Yoga',
          style: TextStyle(
            color: isDark ? themeColor : Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => _openSearch(context),
              icon: Icon(Icons.search, color: iconColor, size: 28),
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
              icon: Icon(Icons.notifications, color: iconColor, size: 28),
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingHomePage()),
              ),
              icon: Icon(Icons.settings, color: iconColor, size: 28),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYogasSection(BuildContext context) {
    final filtered = _filteredItems;
    final visibleItems = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < filtered.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yogas',
              style: TextStyle(
                color: context.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildFilterChips(context),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          _buildSkeleton(context)
        else if (filtered.isEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text(
        _selectedFilter == 3
            ? 'You haven\'t purchased any courses yet'
            : 'No yogas available',
        style: TextStyle(color: context.subtextColor, fontSize: 14),
      ),
    ),
  )
        else ...[
          ...visibleItems.map((item) {
            final kind = item['_kind'] as String;
            final isFree = kind == 'free';
            final classId = item['id'] as String;
            final isUnlocked = isFree || _purchasedIds.contains(classId);

            return YogaCourseCard(
              course: item,
              isUnlocked: isUnlocked,
              onTap: () {
                if (isFree) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => YogaDetailPage(yoga: item),
                    ),
                  );
                } else if (isUnlocked) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InstructorClassDetailPage(
                        classData: item,
                        instructorData: item['yoga_instructors']
                                as Map<String, dynamic>? ??
                            {},
                      ),
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline,
                              color: themeColor, size: 44),
                          const SizedBox(height: 12),
                          Text(
                            item['title'] ?? 'This course',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: Text(
                        'This is a paid course. Purchase it to unlock full access.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel',
                              style: TextStyle(color: Colors.grey.shade400)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => YogaBookingPage(course: item),
                              ),
                            ).then((_) => _loadYogas());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Buy Now',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          }),
          if (hasMore) _buildLoadMore(context),
        ],
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    const labels = ['All', 'Free', 'Paid', 'Owned'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(labels.length, (i) {
        final selected = _selectedFilter == i;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedFilter = i;
            _visibleCount = _pageSize;
          }),
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? themeColor : context.cardBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                color: selected ? Colors.black : context.subtextColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLoadMore(BuildContext context) {
    final remaining = _filteredItems.length - _visibleCount;
    return GestureDetector(
      onTap: _loadMore,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            'Load $remaining more',
            style: const TextStyle(
                color: themeColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => _ShimmerWidget(
          child: Container(
            height: 110,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xff3a3a3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SEARCH DIALOG (unchanged — leave exactly as-is)
// ─────────────────────────────────────────────

class _YogaSearchDialog extends StatefulWidget {
  const _YogaSearchDialog();

  @override
  State<_YogaSearchDialog> createState() => _YogaSearchDialogState();
}

class _YogaSearchDialogState extends State<_YogaSearchDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _classResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _classResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final q = query.trim().toLowerCase();

    final allClasses = await SupabaseService.searchYogaClasses(q);

    if (mounted) {
      setState(() {
        _classResults = allClasses;
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  String _getClassLabel(Map<String, dynamic> yoga) {
    return 'Yoga Practice · Free Exercise';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _classResults.isNotEmpty;

    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 80;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
      child: SizedBox(
        height: availableHeight.clamp(300.0, screenHeight * 0.88),
        child: Container(
          decoration: BoxDecoration(
            color: context.bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
          children: [
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
                          hintText: 'Search classes, instructors...',
                          hintStyle:
                              TextStyle(color: context.subtextColor, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: themeColor),
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
                              Icon(Icons.search, color: themeColor, size: 44),
                              const SizedBox(height: 10),
                              Text('Search anything yoga',
                                  style: TextStyle(
                                      color: context.subtextColor, fontSize: 14)),
                            ],
                          ),
                        )
                      : !hasResults
                          ? Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off,
                                      color: context.subtextColor, size: 44),
                                  const SizedBox(height: 10),
                                  Text('No results found',
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
                                  if (_classResults.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.self_improvement,
                                            color: themeColor, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Yoga Classes',
                                            style: TextStyle(
                                                color: context.textColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ..._classResults.map((yoga) => GestureDetector(
                                          onTap: () {
                                            final nav = Navigator.of(context);
                                            nav.pop();
                                            nav.push(MaterialPageRoute(
                                              builder: (_) =>
                                                  YogaDetailPage(yoga: yoga),
                                            ));
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(12),
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
                                                  child: Image.network(
                                                    yoga['image_url'] ?? '',
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        Container(
                                                      width: 56,
                                                      height: 56,
                                                      color: context.isDark
                                                          ? Colors.grey[800]
                                                          : Colors.grey[200],
                                                      child: Icon(
                                                          Icons.self_improvement,
                                                          color:
                                                              context.subtextColor,
                                                          size: 24),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(yoga['title'] ?? '',
                                                          style: TextStyle(
                                                              color:
                                                                  context.textColor,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight.bold)),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8,
                                                            vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: themeColor
                                                              .withOpacity(0.15),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  6),
                                                        ),
                                                        child: Text(
                                                          _getClassLabel(yoga),
                                                          style: TextStyle(
                                                              color: themeColor,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight.w600),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(yoga['level'] ?? '',
                                                          style: TextStyle(
                                                              color: context
                                                                  .subtextColor,
                                                              fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_forward_ios,
                                                    size: 14, color: Colors.grey),
                                              ],
                                            ),
                                          ),
                                        )),
                                  ],
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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _animation, child: widget.child);
}