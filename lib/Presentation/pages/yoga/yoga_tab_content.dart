import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_motivation_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_schedule_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_challenge_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_feed_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_instructor_card.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_instructor_detail_page.dart';
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
  int _selectedTimeSlot = 0;
  final List<String> _timeSlots = ['Morning', 'Afternoon', 'Evening'];

  List<Map<String, dynamic>> _allInstructors = [];
  bool _isLoadingInstructors = true;
  int _visibleInstructorCount = 3;
  static const int _instructorPageSize = 3;
  int _feedRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    setState(() {
      _isLoadingInstructors = true;
      _visibleInstructorCount = _instructorPageSize;
    });
    final data = await SupabaseService.getYogaInstructors();
    if (mounted) {
      setState(() {
        _allInstructors = data;
        _isLoadingInstructors = false;
        _feedRefreshKey++;
      });
    }
  }

  void _loadMoreInstructors() {
    setState(() {
      _visibleInstructorCount =
          (_visibleInstructorCount + _instructorPageSize)
              .clamp(0, _allInstructors.length);
    });
  }

  void _openSearch(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _YogaSearchDialog(instructors: _allInstructors),
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
          onRefresh: _loadInstructors,
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
                _buildTimeSlotTabs(context),
                const SizedBox(height: 16),
                YogaScheduleCard(
                  key: ValueKey(_timeSlots[_selectedTimeSlot]),
                  timeSlot: _timeSlots[_selectedTimeSlot],
                ),
                const SizedBox(height: 24),
                _buildInstructorsSection(context),
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

  Widget _buildTimeSlotTabs(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: List.generate(_timeSlots.length, (index) {
          final isSelected = _selectedTimeSlot == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeSlot = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? themeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    _timeSlots[index],
                    style: TextStyle(
                      color: isSelected ? Colors.black : context.subtextColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInstructorsSection(BuildContext context) {
    final visibleInstructors =
        _allInstructors.take(_visibleInstructorCount).toList();
    final hasMore = _visibleInstructorCount < _allInstructors.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yoga Instructors',
              style: TextStyle(
                color: context.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_allInstructors.isNotEmpty)
              Text(
                '${_allInstructors.length} available',
                style: TextStyle(color: context.subtextColor, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 260,
          child: _isLoadingInstructors
              ? _buildInstructorSkeleton(context)
              : _allInstructors.isEmpty
                  ? Center(
                      child: Text(
                        'No instructors available',
                        style: TextStyle(color: context.subtextColor, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: visibleInstructors.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == visibleInstructors.length) {
                          return _buildInstructorLoadMore(context);
                        }
                        final instructor = visibleInstructors[index];
                        return YogaInstructorCard(
                          instructor: instructor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  YogaInstructorDetailPage(instructor: instructor),
                            ),
                          ).then((_) => _loadInstructors()),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInstructorLoadMore(BuildContext context) {
    final remaining = _allInstructors.length - _visibleInstructorCount;
    return GestureDetector(
      onTap: _loadMoreInstructors,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: themeColor, width: 1.5),
              ),
              child: const Icon(Icons.add, color: themeColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              '+$remaining more',
              style: const TextStyle(
                  color: themeColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'See more',
              style: TextStyle(color: context.subtextColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorSkeleton(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) => _ShimmerWidget(
        child: Container(
          width: 220,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xff3a3a3a)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SEARCH DIALOG
// ─────────────────────────────────────────────

class _YogaSearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> instructors;
  const _YogaSearchDialog({required this.instructors});

  @override
  State<_YogaSearchDialog> createState() => _YogaSearchDialogState();
}

class _YogaSearchDialogState extends State<_YogaSearchDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _classResults = [];
  List<Map<String, dynamic>> _instructorResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _classResults = [];
        _instructorResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final q = query.trim().toLowerCase();

    final allClasses = await SupabaseService.searchYogaClasses(q);

    final instructorResults = widget.instructors.where((i) {
      return (i['name'] ?? '').toString().toLowerCase().contains(q) ||
          (i['specialty'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    if (mounted) {
      setState(() {
        _classResults = allClasses;
        _instructorResults = instructorResults;
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  String _getClassLabel(Map<String, dynamic> yoga) {
    return 'Best ${yoga['time_slot']} Yoga · Free Exercise';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _classResults.isNotEmpty || _instructorResults.isNotEmpty;

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

            // Results
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
                                  // Classes section
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

                                  // Instructors section
                                  if (_instructorResults.isNotEmpty) ...[
                                    if (_classResults.isNotEmpty)
                                      const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline,
                                            color: themeColor, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Yoga Instructors',
                                            style: TextStyle(
                                                color: context.textColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ..._instructorResults
                                        .map((instructor) => GestureDetector(
                                              onTap: () {
                                                final nav = Navigator.of(context);
                                                nav.pop();
                                                nav.push(MaterialPageRoute(
                                                  builder: (_) =>
                                                      YogaInstructorDetailPage(
                                                          instructor: instructor),
                                                ));
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 10),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: context.cardBgColor,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 28,
                                                      backgroundColor: themeColor,
                                                      backgroundImage: (instructor[
                                                                      'image_url'] ??
                                                                  '')
                                                              .isNotEmpty
                                                          ? NetworkImage(instructor[
                                                              'image_url'])
                                                          : null,
                                                      child: (instructor[
                                                                      'image_url'] ??
                                                                  '')
                                                              .isEmpty
                                                          ? const Icon(
                                                              Icons.person,
                                                              color: Colors.black,
                                                              size: 24)
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              instructor['name'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                  color: context
                                                                      .textColor,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          const SizedBox(height: 4),
                                                          Container(
                                                            padding: const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: themeColor
                                                                  .withOpacity(
                                                                      0.15),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(6),
                                                            ),
                                                            child: Text(
                                                              'Yoga Instructors',
                                                              style: TextStyle(
                                                                  color: themeColor,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                              instructor[
                                                                      'specialty'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                  color: context
                                                                      .subtextColor,
                                                                  fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(
                                                        Icons.arrow_forward_ios,
                                                        size: 14,
                                                        color: Colors.grey),
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