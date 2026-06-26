import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:video_player/video_player.dart';

Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

class TrainerContentPage extends StatefulWidget {
  final Map<String, dynamic> trainer;
  final Map<String, dynamic>? activeBooking; // null = not booked

  const TrainerContentPage({
    super.key,
    required this.trainer,
    this.activeBooking,
  });

  @override
  State<TrainerContentPage> createState() => _TrainerContentPageState();
}

class _TrainerContentPageState extends State<TrainerContentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _dietPlans = [];
  List<Map<String, dynamic>> _guideSteps = [];
  Map<String, List<Map<String, dynamic>>> _dietItems = {};
  Map<String, bool> _stepDoneMap = {}; // stepId -> isDone
  bool _isLoading = true;

  String get _today =>
      DateTime.now().toIso8601String().substring(0, 10);

  String get _trainerId => widget.trainer['id'] as String;
  String get _bookingId =>
      widget.activeBooking?['id'] as String? ?? '';
  bool get _hasBooking => widget.activeBooking != null;

  // For diet tab toggle
  String _selectedPlanType = 'budget';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final videos = await SupabaseService.getTrainerVideos(_trainerId);
    final images = await SupabaseService.getTrainerImages(_trainerId);
    final dietPlans = await SupabaseService.getTrainerDietPlans(_trainerId);
    final steps = await SupabaseService.getTrainerGuideSteps(_trainerId);

    // Load diet items for each plan
    final Map<String, List<Map<String, dynamic>>> itemsMap = {};
    for (final plan in dietPlans) {
      final items =
          await SupabaseService.getTrainerDietItems(plan['id'] as String);
      itemsMap[plan['id'] as String] = items;
    }

    // Load today's guide logs
    final logs = await SupabaseService.getTrainerGuideLogsForDate(
      trainerId: _trainerId,
      date: _today,
    );
    final Map<String, bool> doneMap = {};
    for (final log in logs) {
      doneMap[log['step_id'] as String] = log['is_done'] as bool? ?? false;
    }

    if (mounted) {
      setState(() {
        _videos = videos;
        _images = images;
        _dietPlans = dietPlans;
        _guideSteps = steps;
        _dietItems = itemsMap;
        _stepDoneMap = doneMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStep(Map<String, dynamic> step) async {
    if (!_hasBooking) {
      _showBookingRequiredDialog();
      return;
    }
    final stepId = step['id'] as String;
    final stepNumber = step['step_number'] as int;

    // Lock check — can only do steps in order
    if (!_isStepUnlocked(stepNumber)) {
      _showLockedDialog(stepNumber);
      return;
    }

    final isDone = _stepDoneMap[stepId] ?? false;
    try {
      await SupabaseService.upsertTrainerGuideLog(
        stepId: stepId,
        trainerId: _trainerId,
        bookingId: _bookingId,
        date: _today,
        isDone: !isDone,
      );
      setState(() => _stepDoneMap[stepId] = !isDone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to update. Try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // Step N is unlocked if all previous steps are done (or it's step 1)
  bool _isStepUnlocked(int stepNumber) {
    if (stepNumber == 1) return true;
    for (final step in _guideSteps) {
      final n = step['step_number'] as int;
      if (n < stepNumber) {
        final done = _stepDoneMap[step['id'] as String] ?? false;
        if (!done) return false;
      }
    }
    return true;
  }

  void _showLockedDialog(int stepNumber) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [
          Icon(Icons.lock, color: Colors.orange, size: 48),
          SizedBox(height: 12),
          Text('Step Locked',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Complete Step ${stepNumber - 1} first to unlock this step.',
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBookingRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [
          Icon(Icons.calendar_today, color: themeColor, size: 48),
          SizedBox(height: 12),
          Text('Booking Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ]),
        content: const Text(
          'You need an active booking with this trainer to track your progress.',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final trainer = widget.trainer;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
            child: Row(children: [
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
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    trainer['name'] ?? 'Trainer',
                    style: TextStyle(
                        color: accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    trainer['training_type'] ?? '',
                    style: TextStyle(
                        color: context.subtextColor, fontSize: 12),
                  ),
                ]),
              ),
              // Booking status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _hasBooking
                      ? Colors.green.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hasBooking
                        ? Colors.green.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.4),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _hasBooking
                        ? Icons.check_circle
                        : Icons.lock_outline,
                    color: _hasBooking ? Colors.green : Colors.grey,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _hasBooking ? 'Active' : 'Not Booked',
                    style: TextStyle(
                      color: _hasBooking ? Colors.green : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: context.cardBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: context.subtextColor,
              labelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Guide'),
                Tab(text: 'Diet'),
                Tab(text: 'Steps'),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: accent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVideosTab(context, accent),
                      _buildImagesTab(context, accent),
                      _buildDietTab(context, accent),
                      _buildStepsTab(context, accent),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  // ── VIDEOS TAB ────────────────────────────────

  Widget _buildVideosTab(BuildContext context, Color accent) {
    if (_videos.isEmpty) {
      return _buildEmpty(context, Icons.videocam_off, 'No videos yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _videos.length,
      itemBuilder: (_, i) => _buildVideoCard(context, _videos[i], accent),
    );
  }

  Widget _buildVideoCard(BuildContext context,
      Map<String, dynamic> video, Color accent) {
    final duration = video['duration_seconds'] as int? ?? 0;
    final mins = duration ~/ 60;
    final secs = duration % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Thumbnail
        GestureDetector(
          onTap: () => _openVideoPlayer(context, video),
          child: Stack(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                video['thumbnail_url'] as String? ?? '',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: const Color(0xFF2C2C2C),
                  child: const Icon(Icons.play_circle_fill,
                      color: Colors.white38, size: 60),
                ),
              ),
            ),
            // Play button overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  color: Colors.black38,
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 56),
                ),
              ),
            ),
            // Duration badge
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$mins:${secs.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ]),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(video['title'] as String? ?? '',
                style: TextStyle(
                    color: context.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(video['description'] as String? ?? '',
                style: TextStyle(
                    color: context.subtextColor,
                    fontSize: 13,
                    height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  void _openVideoPlayer(
      BuildContext context, Map<String, dynamic> video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VideoPlayerPage(
          title: video['title'] as String? ?? '',
          videoUrl: video['video_url'] as String? ?? '',
        ),
      ),
    );
  }

  // ── IMAGES TAB ────────────────────────────────

  Widget _buildImagesTab(BuildContext context, Color accent) {
    if (_images.isEmpty) {
      return _buildEmpty(context, Icons.image_not_supported, 'No guides yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _images.length,
      itemBuilder: (_, i) => _buildImageCard(context, _images[i], accent),
    );
  }

  Widget _buildImageCard(BuildContext context,
      Map<String, dynamic> img, Color accent) {
    return GestureDetector(
      onTap: () => _openImageFullscreen(context, img),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              img['image_url'] as String? ?? '',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: const Color(0xFF2C2C2C),
                child: const Icon(Icons.image, color: Colors.white38, size: 60),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(img['title'] as String? ?? '',
                  style: TextStyle(
                      color: context.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(img['caption'] as String? ?? '',
                  style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 13,
                      height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _openImageFullscreen(
      BuildContext context, Map<String, dynamic> img) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageFullscreenPage(
          title: img['title'] as String? ?? '',
          caption: img['caption'] as String? ?? '',
          imageUrl: img['image_url'] as String? ?? '',
        ),
      ),
    );
  }

  // ── DIET TAB ─────────────────────────────────

  Widget _buildDietTab(BuildContext context, Color accent) {
    if (_dietPlans.isEmpty) {
      return _buildEmpty(context, Icons.restaurant_menu, 'No diet plans yet');
    }

    final budgetPlan = _dietPlans
        .where((p) => p['plan_type'] == 'budget')
        .toList();
    final premiumPlan = _dietPlans
        .where((p) => p['plan_type'] == 'premium')
        .toList();
    final activePlan =
        _selectedPlanType == 'budget' ? budgetPlan : premiumPlan;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.cardBgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            _dietToggle(context, 'budget', '🏠  Budget Plan', accent),
            _dietToggle(context, 'premium', '⭐  Premium Plan', accent),
          ]),
        ),
        const SizedBox(height: 16),

        if (activePlan.isEmpty)
          _buildEmpty(context, Icons.no_meals, 'No plan available')
        else
          ...activePlan.map((plan) {
            final planId = plan['id'] as String;
            final items = _dietItems[planId] ?? [];
            final cost =
                (plan['estimated_cost_per_day'] as num?)?.toDouble() ?? 0;

            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Plan header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedPlanType == 'budget'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedPlanType == 'budget'
                        ? Colors.green.withOpacity(0.3)
                        : Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(plan['title'] as String? ?? '',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(plan['description'] as String? ?? '',
                      style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.attach_money,
                        color: _selectedPlanType == 'budget'
                            ? Colors.green
                            : Colors.amber,
                        size: 16),
                    Text(
                      'Est. \$${cost.toStringAsFixed(2)} / day',
                      style: TextStyle(
                        color: _selectedPlanType == 'budget'
                            ? Colors.green
                            : Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              // Meals grouped
              ..._buildMealGroups(context, items, accent),
            ]);
          }),
      ]),
    );
  }

  Widget _dietToggle(BuildContext context, String type,
      String label, Color accent) {
    final isSelected = _selectedPlanType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlanType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? themeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : context.subtextColor,
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMealGroups(BuildContext context,
      List<Map<String, dynamic>> items, Color accent) {
    final groups = <String, List<Map<String, dynamic>>>{};
    const order = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
    for (final item in items) {
      final meal = item['meal_time'] as String? ?? 'Other';
      groups.putIfAbsent(meal, () => []).add(item);
    }

    return order
        .where((m) => groups.containsKey(m))
        .map((meal) {
      final mealItems = groups[meal]!;
      final totalCals = mealItems.fold<int>(
          0, (sum, i) => sum + ((i['calories'] as num?)?.toInt() ?? 0));

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Meal header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Row(children: [
                Text(_mealEmoji(meal),
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(meal,
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ]),
              Text('$totalCals kcal',
                  style: TextStyle(color: accent, fontSize: 12)),
            ]),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Items
          ...mealItems.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                        Expanded(
                          child: Text(
                            item['food_item'] as String? ?? '',
                            style: TextStyle(
                                color: context.textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${(item['calories'] as num?)?.toInt() ?? 0} kcal',
                          style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 11),
                        ),
                      ]),
                      if ((item['quantity'] as String?)?.isNotEmpty ==
                          true)
                        Text(item['quantity'] as String,
                            style: TextStyle(
                                color: context.subtextColor,
                                fontSize: 11)),
                      if ((item['notes'] as String?)?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '💡 ${item['notes']}',
                            style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 6),
                    ]),
                  ),
                ]),
              )),
          const SizedBox(height: 6),
        ]),
      );
    }).toList();
  }

  String _mealEmoji(String meal) {
    switch (meal) {
      case 'Breakfast': return '🌅';
      case 'Lunch': return '☀️';
      case 'Dinner': return '🌙';
      case 'Snack': return '🍎';
      default: return '🍽️';
    }
  }

  // ── STEPS TAB ────────────────────────────────

  Widget _buildStepsTab(BuildContext context, Color accent) {
    if (_guideSteps.isEmpty) {
      return _buildEmpty(context, Icons.list_alt, 'No guide steps yet');
    }

    final doneCount =
        _stepDoneMap.values.where((v) => v).length;
    final total = _guideSteps.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.cardBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text('Today\'s Progress',
                  style: TextStyle(
                      color: context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text('$doneCount / $total steps',
                  style: TextStyle(color: accent, fontSize: 13)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? doneCount / total : 0,
                minHeight: 8,
                backgroundColor: context.isDark
                    ? Colors.white12
                    : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                    doneCount == total ? Colors.green : themeColor),
              ),
            ),
            if (!_hasBooking) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.info_outline,
                    color: Colors.orange, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Book a session to track progress',
                  style: TextStyle(
                      color: Colors.orange, fontSize: 12),
                ),
              ]),
            ],
          ]),
        ),

        ..._guideSteps.map((step) =>
            _buildStepCard(context, step, accent)),
      ],
    );
  }

  Widget _buildStepCard(BuildContext context,
      Map<String, dynamic> step, Color accent) {
    final stepId = step['id'] as String;
    final stepNumber = step['step_number'] as int;
    final isDone = _stepDoneMap[stepId] ?? false;
    final isUnlocked = _isStepUnlocked(stepNumber);
    final duration = step['duration_minutes'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _toggleStep(step),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDone
              ? Colors.green.withOpacity(0.08)
              : !isUnlocked
                  ? context.cardBgColor.withOpacity(0.5)
                  : context.cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone
                ? Colors.green.withOpacity(0.4)
                : !isUnlocked
                    ? Colors.grey.withOpacity(0.2)
                    : context.isDark
                        ? Colors.white12
                        : Colors.black12,
            width: isDone ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Step header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              // Step number circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green
                      : !isUnlocked
                          ? Colors.grey.withOpacity(0.3)
                          : themeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 18)
                      : !isUnlocked
                          ? const Icon(Icons.lock,
                              color: Colors.grey, size: 16)
                          : Text(
                              '$stepNumber',
                              style: TextStyle(
                                color: accent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    step['title'] as String? ?? '',
                    style: TextStyle(
                      color: !isUnlocked
                          ? context.subtextColor
                          : context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (duration > 0)
                    Row(children: [
                      Icon(Icons.timer_outlined,
                          color: accent, size: 12),
                      const SizedBox(width: 4),
                      Text('$duration min',
                          style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 11)),
                    ]),
                ]),
              ),
              // Done/locked indicator
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.4)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              else if (!isUnlocked)
                const Icon(Icons.lock_outline,
                    color: Colors.grey, size: 18)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: themeColor.withOpacity(0.3)),
                  ),
                  child: const Text('Tap to do',
                      style: TextStyle(
                          color: themeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ]),
          ),

          // Image + description (only if unlocked)
          if (isUnlocked) ...[
            if ((step['image_url'] as String?)?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image.network(
                  step['image_url'] as String,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                step['description'] as String? ?? '',
                style: TextStyle(
                    color: context.subtextColor,
                    fontSize: 13,
                    height: 1.5),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'Complete the previous step to unlock this.',
                style: TextStyle(
                    color: context.subtextColor.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildEmpty(
      BuildContext context, IconData icon, String label) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: context.subtextColor, size: 48),
        const SizedBox(height: 12),
        Text(label,
            style: TextStyle(
                color: context.subtextColor, fontSize: 14)),
      ]),
    );
  }
}

// ── VIDEO PLAYER PAGE ─────────────────────────

class _VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  const _VideoPlayerPage(
      {required this.title, required this.videoUrl});
  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            if (mounted) setState(() => _initialized = true);
            _controller.play();
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: const TextStyle(fontSize: 15)),
      ),
      body: Center(
        child: _initialized
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                const SizedBox(height: 16),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: themeColor,
                      size: 52,
                    ),
                    onPressed: () => setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    }),
                  ),
                ]),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: themeColor,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ])
            : const CircularProgressIndicator(color: themeColor),
      ),
    );
  }
}

// ── IMAGE FULLSCREEN PAGE ─────────────────────

class _ImageFullscreenPage extends StatelessWidget {
  final String title;
  final String caption;
  final String imageUrl;
  const _ImageFullscreenPage(
      {required this.title,
      required this.caption,
      required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 15)),
      ),
      body: Column(children: [
        Expanded(
          child: InteractiveViewer(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white38,
                    size: 80),
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Text(
              caption,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
      ]),
    );
  }
}