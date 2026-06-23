import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_motivation_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_schedule_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_challenge_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_feed_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_instructor_card.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_instructor_detail_page.dart';
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

  List<Map<String, dynamic>> _instructors = [];
  bool _isLoadingInstructors = true;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    setState(() => _isLoadingInstructors = true);
    final data = await SupabaseService.getYogaInstructors();
    if (mounted) {
      setState(() {
        _instructors = data;
        _isLoadingInstructors = false;
      });
    }
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
                YogaScheduleCard(timeSlot: _timeSlots[_selectedTimeSlot]),
                const SizedBox(height: 24),
                _buildInstructorsSection(context),
                const SizedBox(height: 24),
                const YogaChallengeCard(),
                const SizedBox(height: 24),
                const YogaFeedCard(),
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
    final textColor = isDark ? Colors.white : Colors.black87;

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
              onPressed: () {},
              icon: Icon(Icons.search, color: textColor, size: 28),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications_outlined, color: textColor, size: 28),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.settings_outlined, color: textColor, size: 28),
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
            if (_instructors.isNotEmpty)
              Text(
                '${_instructors.length} available',
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Horizontal scroll list
        SizedBox(
          height: 260,
          child: _isLoadingInstructors
              ? _buildInstructorSkeleton()
              : _instructors.isEmpty
                  ? Center(
                      child: Text(
                        'No instructors available',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _instructors.length,
                      itemBuilder: (context, index) {
                        final instructor = _instructors[index];
                        return YogaInstructorCard(
                          instructor: instructor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => YogaInstructorDetailPage(
                                instructor: instructor,
                              ),
                            ),
                          ).then((_) => _loadInstructors()),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInstructorSkeleton() {
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