import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({super.key});

  @override
  State<NewsfeedPage> createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  bool _isLoading = true;

  // All instructor paid classes with instructor info joined
  List<Map<String, dynamic>> _allClasses = [];

  // Instructors the user has booked — set of instructor IDs
  Set<String> _bookedInstructorIds = {};

  // Classes already in user's feed
  Set<String> _feedClassIds = {};

  // Filter
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Unlocked', 'Locked'];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 1. Get all instructors
    final instructors = await SupabaseService.getYogaInstructors(pageSize: 100);

    // 2. Get all paid classes for each instructor
    final List<Map<String, dynamic>> allClasses = [];
    for (final instructor in instructors) {
      final classes = await SupabaseService.getInstructorPaidClasses(
          instructor['id'] as String);
      for (final cls in classes) {
        allClasses.add({
          ...cls,
          'instructor': instructor,
        });
      }
    }

    // 3. Get user's bookings to know which instructors are unlocked
    final bookings = await SupabaseService.getMyYogaBookings();
    final bookedIds = bookings
        .map((b) => b['instructor_id'] as String)
        .toSet();

    // 4. Get user's feed classes
    final feedClasses = await SupabaseService.getUserFeedClasses();
    final feedIds = feedClasses
        .map((f) => f['class_id'] as String)
        .toSet();

    if (mounted) {
      setState(() {
        _allClasses = allClasses;
        _bookedInstructorIds = bookedIds;
        _feedClassIds = feedIds;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredClasses {
    var result = _allClasses;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((cls) {
        final title = (cls['title'] ?? '').toString().toLowerCase();
        final level = (cls['level'] ?? '').toString().toLowerCase();
        final instructorName =
            ((cls['instructor'] as Map?)?['name'] ?? '').toString().toLowerCase();
        final specialty =
            ((cls['instructor'] as Map?)?['specialty'] ?? '').toString().toLowerCase();
        return title.contains(q) ||
            level.contains(q) ||
            instructorName.contains(q) ||
            specialty.contains(q);
      }).toList();
    }

    // Lock/unlock filter
    if (_selectedFilter == 1) {
      // Unlocked only
      result = result.where((cls) {
        final instructorId =
            (cls['instructor'] as Map?)?['id'] as String? ?? '';
        return _bookedInstructorIds.contains(instructorId);
      }).toList();
    } else if (_selectedFilter == 2) {
      // Locked only
      result = result.where((cls) {
        final instructorId =
            (cls['instructor'] as Map?)?['id'] as String? ?? '';
        return !_bookedInstructorIds.contains(instructorId);
      }).toList();
    }

    return result;
  }

  Future<void> _toggleFeed(String classId, String instructorId) async {
    try {
      if (_feedClassIds.contains(classId)) {
        await SupabaseService.removeClassFromFeed(classId);
        setState(() => _feedClassIds.remove(classId));
      } else {
        await SupabaseService.addClassToFeed(
          classId: classId,
          instructorId: instructorId,
        );
        setState(() => _feedClassIds.add(classId));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClasses;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
                      backgroundColor: Colors.black54,
                      elevation: 0,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Instructor Classes',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    hintText: 'Search classes or instructors...',
                    hintStyle:
                        TextStyle(color: context.subtextColor, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: themeColor, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter tabs ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final selected = _selectedFilter == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? themeColor : context.cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? null
                            : Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.lock_open,
                                  size: 12,
                                  color: selected
                                      ? Colors.black
                                      : Colors.green),
                            )
                          else if (i == 2)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.lock,
                                  size: 12,
                                  color: selected
                                      ? Colors.black
                                      : Colors.orange),
                            ),
                          Text(
                            _filters[i],
                            style: TextStyle(
                              color: selected
                                  ? Colors.black
                                  : context.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),

            // ── Result count ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _isLoading
                    ? 'Loading...'
                    : '${filtered.length} class${filtered.length == 1 ? '' : 'es'}',
                style:
                    TextStyle(color: context.subtextColor, fontSize: 12),
              ),
            ),

            // ── List ──
            Expanded(
              child: _isLoading
                  ? _buildSkeleton(context)
                  : filtered.isEmpty
                      ? _buildEmpty(context)
                      : RefreshIndicator(
                          color: themeColor,
                          backgroundColor: context.cardBgColor,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                16, 4, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildClassCard(
                                    context, filtered[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(
      BuildContext context, Map<String, dynamic> cls) {
    final classId = cls['id'] as String;
    final instructor = cls['instructor'] as Map<String, dynamic>?;
    final instructorId = instructor?['id'] as String? ?? '';
    final isUnlocked = _bookedInstructorIds.contains(instructorId);
    final isInFeed = _feedClassIds.contains(classId);

    final imageUrl = cls['image_url'] ?? '';
    final title = cls['title'] ?? '';
    final description = cls['description'] ?? '';
    final level = cls['level'] ?? '';
    final duration = cls['duration_minutes']?.toString() ?? '';
    final classType = cls['class_type'] ?? 'guide';
    final instructorName = instructor?['name'] ?? '';
    final instructorSpecialty = instructor?['specialty'] ?? '';
    final instructorImage = instructor?['image_url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(color: themeColor.withOpacity(0.25))
            : Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + overlays
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imageFallback(context),
                      )
                    : _imageFallback(context),
              ),

              // Lock overlay
              if (!isUnlocked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white30, width: 1.5),
                            ),
                            child: const Icon(Icons.lock_outline,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Book this instructor to unlock',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Level badge — top left
              Positioned(
                top: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(level,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              // Duration badge — bottom left
              Positioned(
                bottom: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Colors.white70, size: 11),
                      const SizedBox(width: 3),
                      Text('$duration min',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

              // Class type badge — bottom right
              Positioned(
                bottom: 8,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(classType,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ),
              ),

              // Feed badge — top right (if added)
              if (isInFeed)
                Positioned(
                  top: 8,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 10),
                        SizedBox(width: 3),
                        Text('In Feed',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUnlocked
                        ? context.textColor
                        : context.subtextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                        color: context.subtextColor,
                        fontSize: 12,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                // Instructor row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: themeColor,
                      backgroundImage: instructorImage.isNotEmpty
                          ? NetworkImage(instructorImage)
                          : null,
                      child: instructorImage.isEmpty
                          ? const Icon(Icons.person,
                              color: Colors.black, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(instructorName,
                              style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          Text(instructorSpecialty,
                              style: TextStyle(
                                  color: context.subtextColor,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: isUnlocked
                      ? ElevatedButton.icon(
                          onPressed: () =>
                              _toggleFeed(classId, instructorId),
                          icon: Icon(
                              isInFeed
                                  ? Icons.remove_circle_outline
                                  : Icons.add_circle_outline,
                              size: 16),
                          label: Text(isInFeed
                              ? 'Remove from Feed'
                              : 'Add to My Feed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInFeed
                                ? Colors.red.withOpacity(0.15)
                                : themeColor,
                            foregroundColor: isInFeed
                                ? Colors.redAccent
                                : Colors.black,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_outline,
                              size: 14, color: Colors.orange),
                          label: const Text('Book to Unlock',
                              style:
                                  TextStyle(color: Colors.orange)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.orange, width: 1),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(BuildContext context) {
    return Container(
      height: 160,
      color: context.isDark
          ? const Color(0xff3a3a3a)
          : Colors.grey[200],
      child: Icon(Icons.play_circle_outline,
          color: context.subtextColor, size: 48),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: context.subtextColor),
          const SizedBox(height: 12),
          Text('No classes found',
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Try a different search or filter',
              style: TextStyle(
                  color: context.subtextColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 3,
      itemBuilder: (_, __) => _ShimmerWidget(
        child: Container(
          height: 280,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xff3a3a3a)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
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
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller, curve: Curves.easeInOut));
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