import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_booking_page.dart';
import 'package:get_fit/Presentation/pages/yoga/instructor_class_detail_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_instructor_detail_page.dart';

// ─── Pagination constants ──────────────────────────────────────────────────────
const int _kInstructorPageSize = 9;
const int _kSessionPageSize = 3;

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({super.key});

  @override
  State<NewsfeedPage> createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  // ── Loading flags ────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isLoadingMoreInstructors = false;

  // ── Instructor pagination ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _instructors = [];
  int _instructorPage = 0;
  bool _hasMoreInstructors = true;

  // ── Per-instructor data ──────────────────────────────────────────────────────
  /// sessions for instructor (all fetched when expanded, but displayed in pages)
  Map<String, List<Map<String, dynamic>>> _sessionsByInstructor = {};

  /// How many sessions are currently visible per instructor
  Map<String, int> _visibleSessionCount = {};

  /// classes per session
  Map<String, List<Map<String, dynamic>>> _classesBySession = {};

  /// slots per session-class
  Map<String, List<Map<String, dynamic>>> _slotsByClass = {};

  /// which instructors have had their sessions fetched
  final Set<String> _fetchedInstructors = {};

  /// which instructors are loading sessions right now
  final Set<String> _loadingInstructors = {};

  // ── Bookings / feed ──────────────────────────────────────────────────────────
  Set<String> _bookedSessionIds = {};
  Set<String> _feedClassIds = {};

  // ── UI state ─────────────────────────────────────────────────────────────────
  final Set<String> _expandedInstructors = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Unlocked', 'Locked'];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll → auto-load next instructor page ──────────────────────────────────
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreInstructors &&
        _hasMoreInstructors &&
        _searchQuery.isEmpty) {
      _loadMoreInstructors();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Initial load: page 0 instructors + bookings + feed in parallel
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _instructors = [];
      _instructorPage = 0;
      _hasMoreInstructors = true;
      _sessionsByInstructor = {};
      _visibleSessionCount = {};
      _classesBySession = {};
      _slotsByClass = {};
      _fetchedInstructors.clear();
      _expandedInstructors.clear();
    });

    // Run instructor fetch + bookings + feed in parallel
    final results = await Future.wait([
      SupabaseService.getYogaInstructors(
          pageSize: _kInstructorPageSize, page: 0),
      SupabaseService.getMyYogaBookings(),
      SupabaseService.getUserFeedClasses(),
    ]);

    final instructors = results[0] as List<Map<String, dynamic>>;
    final bookings = results[1] as List<Map<String, dynamic>>;
    final feedClasses = results[2] as List<Map<String, dynamic>>;

    if (!mounted) return;
    setState(() {
      _instructors = instructors;
      _instructorPage = 1;
      _hasMoreInstructors = instructors.length >= _kInstructorPageSize;

      _bookedSessionIds = bookings
          .map((b) => b['session_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      _feedClassIds =
          feedClasses.map((f) => f['class_id'] as String).toSet();

      _isLoading = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Load next page of instructors (append)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _loadMoreInstructors() async {
    if (_isLoadingMoreInstructors || !_hasMoreInstructors) return;
    setState(() => _isLoadingMoreInstructors = true);

    final more = await SupabaseService.getYogaInstructors(
        pageSize: _kInstructorPageSize, page: _instructorPage);

    if (!mounted) return;
    setState(() {
      _instructors.addAll(more);
      _instructorPage++;
      _hasMoreInstructors = more.length >= _kInstructorPageSize;
      _isLoadingMoreInstructors = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Lazy-load sessions + classes + slots for ONE instructor (called on expand)
  // All parallel — no waterfall
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _fetchInstructorData(String iid) async {
    if (_fetchedInstructors.contains(iid)) return;
    if (_loadingInstructors.contains(iid)) return;

    setState(() => _loadingInstructors.add(iid));

    // 1. Fetch sessions
    final sessions = await SupabaseService.getInstructorSessions(iid);

    // 2. Fetch all session-classes in parallel
    final classFutures = sessions
        .map((s) => SupabaseService.getSessionClasses(s['id'] as String));
    final classResults = await Future.wait(classFutures);

    // Build classesBySession map
    final Map<String, List<Map<String, dynamic>>> classesBySession = {};
    for (var i = 0; i < sessions.length; i++) {
      classesBySession[sessions[i]['id'] as String] = classResults[i];
    }

    // 3. Collect all unique session-class IDs and fetch their slots in parallel
    final allClassIds = classResults.expand((list) => list).map((c) => c['id'] as String).toList();
    final slotFutures = allClassIds.map((cid) => SupabaseService.getClassSlots(cid));
    final slotResults = await Future.wait(slotFutures);

    final Map<String, List<Map<String, dynamic>>> slotsByClass = {};
    for (var i = 0; i < allClassIds.length; i++) {
      slotsByClass[allClassIds[i]] = slotResults[i];
    }

    if (!mounted) return;
    setState(() {
      _sessionsByInstructor[iid] = sessions;
      _visibleSessionCount[iid] = _kSessionPageSize;
      for (final entry in classesBySession.entries) {
        _classesBySession[entry.key] = entry.value;
      }
      for (final entry in slotsByClass.entries) {
        _slotsByClass[entry.key] = entry.value;
      }
      _fetchedInstructors.add(iid);
      _loadingInstructors.remove(iid);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Toggle expand / collapse instructor
  // ─────────────────────────────────────────────────────────────────────────────
  void _toggleInstructor(String iid) {
    if (_expandedInstructors.contains(iid)) {
      setState(() => _expandedInstructors.remove(iid));
    } else {
      setState(() => _expandedInstructors.add(iid));
      _fetchInstructorData(iid); // no-op if already fetched
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Pull-to-refresh — full reset
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _onRefresh() => _loadInitial();

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────────
  bool _isSlotActive(Map<String, dynamic> slot) {
    final dateStr = slot['slot_date'] as String? ?? '';
    final startStr = slot['start_time'] as String? ?? '';
    final endStr = slot['end_time'] as String? ?? '';
    if (dateStr.isEmpty || startStr.isEmpty || endStr.isEmpty) return false;
    try {
      final now = DateTime.now();
      final start = DateTime.parse('${dateStr}T$startStr');
      final end = DateTime.parse('${dateStr}T$endStr');
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  bool _isSessionExpired(Map<String, dynamic> session) {
    final endStr = session['session_end'] as String? ?? '';
    if (endStr.isEmpty) return false;
    final end = DateTime.tryParse(endStr);
    if (end == null) return false;
    return DateTime.now().isAfter(end.add(const Duration(days: 1)));
  }

  String _fmtTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:$m $period';
  }

  String _fmtDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  String _dayAbbr(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  String _dayNum(String dateStr) {
    try {
      return DateTime.parse(dateStr).day.toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> _toggleFeed(String paidClassId, String instructorId) async {
    try {
      if (_feedClassIds.contains(paidClassId)) {
        await SupabaseService.removeClassFromFeed(paidClassId);
        setState(() => _feedClassIds.remove(paidClassId));
      } else {
        await SupabaseService.addClassToFeed(
          classId: paidClassId,
          instructorId: instructorId,
        );
        setState(() => _feedClassIds.add(paidClassId));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Filtered instructor list (search only — filter by booked requires sessions)
  // ─────────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _displayedInstructors {
    if (_searchQuery.isEmpty && _selectedFilter == 0) return _instructors;

    return _instructors.where((instructor) {
      final iid = instructor['id'] as String;
      final q = _searchQuery.toLowerCase();

      // Name / specialty match
      if (q.isNotEmpty) {
        final name = (instructor['name'] ?? '').toString().toLowerCase();
        final spec = (instructor['specialty'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !spec.contains(q)) {
          // Check sessions / class titles if already fetched
          final sessions = _sessionsByInstructor[iid] ?? [];
          final anyMatch = sessions.any((s) {
            if ((s['title'] ?? '').toString().toLowerCase().contains(q)) return true;
            final classes = _classesBySession[s['id'] as String] ?? [];
            return classes.any((cls) {
              final paid = cls['instructor_paid_classes'] as Map<String, dynamic>?;
              final t = (paid?['title'] ?? cls['title'] ?? '').toString().toLowerCase();
              return t.contains(q);
            });
          });
          if (!anyMatch) return false;
        }
      }

      // Filter: Unlocked / Locked — only apply if sessions fetched
      if (_selectedFilter != 0) {
        final sessions = _sessionsByInstructor[iid] ?? [];
        if (sessions.isEmpty) return true; // not yet fetched — show anyway
        final hasBooked = sessions.any((s) => _bookedSessionIds.contains(s['id'] as String));
        if (_selectedFilter == 1 && !hasBooked) return false;
        if (_selectedFilter == 2 && hasBooked) return false;
      }

      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
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

            // ── Search ──────────────────────────────────────────────────────
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
                    hintText: 'Search instructors, sessions or classes...',
                    hintStyle: TextStyle(color: context.subtextColor, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: themeColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: context.subtextColor, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter tabs ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final selected = _selectedFilter == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? themeColor : context.cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: selected ? null : Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.lock_open,
                                  size: 12,
                                  color: selected ? Colors.black : Colors.green),
                            )
                          else if (i == 2)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.lock,
                                  size: 12,
                                  color: selected ? Colors.black : Colors.orange),
                            ),
                          Text(
                            _filters[i],
                            style: TextStyle(
                              color: selected ? Colors.black : context.textColor,
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

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildSkeleton(context)
                  : _displayedInstructors.isEmpty
                      ? _buildEmpty(context)
                      : RefreshIndicator(
                          color: themeColor,
                          backgroundColor: context.cardBgColor,
                          onRefresh: _onRefresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            // +1 for the load-more footer
                            itemCount: _displayedInstructors.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _displayedInstructors.length) {
                                return _buildLoadMoreFooter(context);
                              }
                              return _buildInstructorCard(
                                  context, _displayedInstructors[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Load-more footer (at bottom of instructor list)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLoadMoreFooter(BuildContext context) {
    if (!_hasMoreInstructors || _searchQuery.isNotEmpty) {
      return const SizedBox(height: 16);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _isLoadingMoreInstructors
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: themeColor,
                  strokeWidth: 2,
                ),
              ),
            )
          : GestureDetector(
              onTap: _loadMoreInstructors,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: themeColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.expand_more, color: themeColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Load more instructors',
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Instructor card (collapsible)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildInstructorCard(
      BuildContext context, Map<String, dynamic> instructor) {
    final iid = instructor['id'] as String;
    final isExpanded = _expandedInstructors.contains(iid);
    final isLoading = _loadingInstructors.contains(iid);
    final sessions = _sessionsByInstructor[iid] ?? [];
    final imageUrl = instructor['image_url'] as String? ?? '';
    final name = instructor['name'] as String? ?? '';
    final specialty = instructor['specialty'] as String? ?? '';

    final bookedCount =
        sessions.where((s) => _bookedSessionIds.contains(s['id'] as String)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bookedCount > 0 ? themeColor.withOpacity(0.25) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Instructor header ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => _toggleInstructor(iid),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bookedCount > 0
                    ? themeColor.withOpacity(0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(18),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            YogaInstructorDetailPage(instructor: instructor),
                      ),
                    ).then((_) => _onRefresh()),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: themeColor,
                      backgroundImage:
                          imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.self_improvement,
                              color: Colors.black, size: 22)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        Text(specialty,
                            style: TextStyle(
                                color: context.subtextColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(children: [
                          if (sessions.isNotEmpty) ...[
                            _miniChip('${sessions.length} sessions', themeColor),
                            const SizedBox(width: 6),
                          ],
                          if (bookedCount > 0)
                            _miniChip('$bookedCount booked', Colors.green),
                        ]),
                      ],
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: themeColor, strokeWidth: 2),
                    )
                  else
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: context.subtextColor,
                    ),
                ],
              ),
            ),
          ),

          // ── Sessions (lazy, paginated) ─────────────────────────────────────
          if (isExpanded) ...[
            Divider(
                color: context.isDark ? Colors.white10 : Colors.black12,
                height: 1),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                      color: themeColor, strokeWidth: 2),
                ),
              )
            else if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No sessions available',
                    style:
                        TextStyle(color: context.subtextColor, fontSize: 13),
                  ),
                ),
              )
            else
              _buildSessionsList(context, sessions, instructor),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Sessions list with local "load more" pagination
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSessionsList(
    BuildContext context,
    List<Map<String, dynamic>> allSessions,
    Map<String, dynamic> instructor,
  ) {
    final iid = instructor['id'] as String;
    final visibleCount = _visibleSessionCount[iid] ?? _kSessionPageSize;

    // Apply locked/unlocked filter
    final filteredSessions = _selectedFilter == 0
        ? allSessions
        : allSessions.where((s) {
            final booked = _bookedSessionIds.contains(s['id'] as String);
            if (_selectedFilter == 1) return booked;
            if (_selectedFilter == 2) return !booked;
            return true;
          }).toList();

    if (filteredSessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text('No sessions match the filter',
              style: TextStyle(color: context.subtextColor, fontSize: 13)),
        ),
      );
    }

    final displayedSessions = filteredSessions.take(visibleCount).toList();
    final hasMore = filteredSessions.length > visibleCount;

    return Column(
      children: [
        ...displayedSessions.map((session) =>
            _buildSessionSection(context, session, instructor)),

        // ── Load more sessions button ────────────────────────────────────────
        if (hasMore)
          GestureDetector(
            onTap: () => setState(() {
              _visibleSessionCount[iid] = visibleCount + _kSessionPageSize;
            }),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.expand_more, color: themeColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Load ${(filteredSessions.length - visibleCount).clamp(0, _kSessionPageSize)} more sessions',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Individual session section
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSessionSection(
    BuildContext context,
    Map<String, dynamic> session,
    Map<String, dynamic> instructor,
  ) {
    final sid = session['id'] as String;
    final isBooked = _bookedSessionIds.contains(sid);
    final isExpired = _isSessionExpired(session);
    final classes = _classesBySession[sid] ?? [];
    final title = session['title'] as String? ?? 'Session';
    final startDate = session['session_start'] as String? ?? '';
    final endDate = session['session_end'] as String? ?? '';
    final totalCls = session['total_classes'] as int? ?? classes.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBooked && !isExpired
              ? themeColor.withOpacity(0.35)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Date badge
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isBooked && !isExpired
                        ? themeColor
                        : isExpired
                            ? Colors.grey
                            : context.isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayAbbr(startDate),
                        style: TextStyle(
                          color: isBooked || isExpired
                              ? Colors.black
                              : context.subtextColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _dayNum(startDate),
                        style: TextStyle(
                          color: isBooked || isExpired
                              ? Colors.black
                              : context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: context.textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmtDate(startDate)} → ${_fmtDate(endDate)}',
                        style:
                            TextStyle(color: context.subtextColor, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.class_outlined,
                            size: 11, color: context.subtextColor),
                        const SizedBox(width: 3),
                        Text('$totalCls classes',
                            style: TextStyle(
                                color: context.subtextColor, fontSize: 10)),
                      ]),
                    ],
                  ),
                ),
                if (isExpired)
                  _chip('Expired', Colors.grey)
                else if (isBooked)
                  _chip('Booked', themeColor)
                else
                  _chip('Locked', Colors.orange),
              ],
            ),
          ),

          // Classes
          if (classes.isNotEmpty) ...[
            Divider(
                color: context.isDark ? Colors.white10 : Colors.black12,
                height: 1,
                indent: 12,
                endIndent: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: classes
                    .map((cls) => _buildClassCard(
                          context,
                          cls,
                          session,
                          instructor,
                          isBooked: isBooked,
                          isExpired: isExpired,
                        ))
                    .toList(),
              ),
            ),
          ],

          // Bottom action strip — book CTA
          if (!isBooked && !isExpired)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YogaBookingPage(instructor: instructor),
                ),
              ).then((_) => _onRefresh()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(14)),
                  border:
                      Border(top: BorderSide(color: Colors.orange.withOpacity(0.2))),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.orange, size: 13),
                    SizedBox(width: 6),
                    Text('Tap to book this session',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Class card (unchanged logic, same UI)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildClassCard(
    BuildContext context,
    Map<String, dynamic> cls,
    Map<String, dynamic> session,
    Map<String, dynamic> instructor, {
    required bool isBooked,
    required bool isExpired,
  }) {
    final sessionClassId = cls['id'] as String;
    final paidClass = cls['instructor_paid_classes'] as Map<String, dynamic>?;
    final paidClassId = paidClass?['id'] as String? ?? '';
    final title = paidClass?['title'] as String? ?? cls['title'] as String? ?? '';
    final imageUrl = paidClass?['image_url'] as String? ?? '';
    final level = paidClass?['level'] as String? ?? '';
    final duration = (cls['duration_minutes'] as num?)?.toString() ?? '60';
    final isInFeed = _feedClassIds.contains(paidClassId);

    final slots = _slotsByClass[sessionClassId] ?? [];
    final hasActiveSlot = slots.any((s) => _isSlotActive(s));
    final sortedUpcoming = slots.where((s) {
      try {
        final start = DateTime.parse(
            '${s['slot_date']}T${s['start_time']}');
        return DateTime.now().isBefore(start);
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) =>
          '${a['slot_date']}T${a['start_time']}'
              .compareTo('${b['slot_date']}T${b['start_time']}'));
    final upcomingSlot =
        sortedUpcoming.isNotEmpty ? sortedUpcoming.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActiveSlot && isBooked
              ? Colors.green.withOpacity(0.5)
              : isBooked
                  ? themeColor.withOpacity(0.2)
                  : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + overlays
          if (imageUrl.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(context),
                  ),
                ),
                if (!isBooked)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        color: Colors.black.withOpacity(0.65),
                        child: const Center(
                          child: Icon(Icons.lock_outline,
                              color: Colors.white54, size: 28),
                        ),
                      ),
                    ),
                  ),
                if (hasActiveSlot && isBooked)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 7),
                          SizedBox(width: 4),
                          Text('Live Now',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                if (level.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(level,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text('$duration min',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: isBooked
                            ? context.textColor
                            : context.subtextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),

                if (upcomingSlot != null && isBooked && !isExpired) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time,
                        size: 11, color: context.subtextColor),
                    const SizedBox(width: 4),
                    Text(
                      'Next: ${_fmtTime(upcomingSlot['start_time'] as String)} → ${_fmtTime(upcomingSlot['end_time'] as String)}',
                      style:
                          TextStyle(color: context.subtextColor, fontSize: 10),
                    ),
                  ]),
                ],

                const SizedBox(height: 8),

                if (isBooked && !isExpired)
                  Row(children: [
                    if (paidClassId.isNotEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _toggleFeed(paidClassId, instructor['id'] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: isInFeed
                                  ? Colors.red.withOpacity(0.1)
                                  : themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isInFeed
                                      ? Colors.red.withOpacity(0.3)
                                      : themeColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    isInFeed
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                    size: 13,
                                    color: isInFeed ? Colors.red : themeColor),
                                const SizedBox(width: 4),
                                Text(
                                    isInFeed ? 'Remove' : 'Add to Feed',
                                    style: TextStyle(
                                        color:
                                            isInFeed ? Colors.red : themeColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (paidClassId.isNotEmpty) const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (paidClass != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InstructorClassDetailPage(
                                  classData: paidClass,
                                  instructorData: instructor,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: hasActiveSlot ? Colors.green : themeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  hasActiveSlot
                                      ? Icons.play_arrow
                                      : Icons.visibility_outlined,
                                  size: 13,
                                  color: hasActiveSlot
                                      ? Colors.white
                                      : Colors.black),
                              const SizedBox(width: 4),
                              Text(
                                  hasActiveSlot ? 'Join' : 'View',
                                  style: TextStyle(
                                      color: hasActiveSlot
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ])
                else if (!isBooked)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            YogaBookingPage(instructor: instructor),
                      ),
                    ).then((_) => _onRefresh()),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 12, color: Colors.orange),
                          SizedBox(width: 5),
                          Text('Book to Unlock',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Small helpers
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _miniChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _imageFallback(BuildContext context) => Container(
        height: 110,
        color: context.isDark ? const Color(0xff3a3a3a) : Colors.grey[200],
        child: Icon(Icons.play_circle_outline,
            color: context.subtextColor, size: 36),
      );

  Widget _buildEmpty(BuildContext context) => Center(
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
                style: TextStyle(color: context.subtextColor, fontSize: 13)),
          ],
        ),
      );

  Widget _buildSkeleton(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: 4,
        itemBuilder: (_, __) => _ShimmerWidget(
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xff3a3a3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer widget (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
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
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
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