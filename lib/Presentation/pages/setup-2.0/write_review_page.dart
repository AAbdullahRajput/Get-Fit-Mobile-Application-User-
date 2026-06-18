
import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Utils/constants.dart';

class WriteReviewPage extends StatefulWidget {
  const WriteReviewPage({super.key});

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  static bool _hasLoaded = false;
  bool _isLoading = true;
  double _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_hasLoaded) {
      setState(() => _isLoading = false);
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _hasLoaded = true;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    _hasLoaded = false;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _hasLoaded = true;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: context.subtextColor,
              backgroundColor: context.cardBgColor,
              displacement: 100,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                child: _isLoading
                    ? _buildSkeleton(context)
                    : _buildContent(context),
              ),
            ),
          ),

          // Back button overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Write a Review',
          style: TextStyle(
            color: context.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share your experience with this trainer',
          style: TextStyle(color: context.subtextColor, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Star rating selector
        Text(
          'Your Rating',
          style: TextStyle(
            color: context.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedRating = index + 1.0),
              child: Icon(
                index < _selectedRating ? Icons.star : Icons.star_border,
                color: themeColor,
                size: 36,
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Review text field
        Text(
          'Your Review',
          style: TextStyle(
            color: context.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.cardBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _reviewController,
              maxLines: 8,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Write your review here...',
                hintStyle: TextStyle(color: context.subtextColor),
              ),
              style: TextStyle(color: context.textColor),
            ),
          ),
        ),
        const SizedBox(height: 24),

        ReuseableButton(
          title: "Submit Review",
          onPressed: () {
            // TODO: send to Supabase
            // supabase.from('reviews').insert({
            //   'trainer_id': trainerId,
            //   'user_id': currentUser.id,
            //   'rating': _selectedRating,
            //   'comment': _reviewController.text,
            //   'created_at': DateTime.now().toIso8601String(),
            // });
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmer(context, width: 160, height: 24),
        const SizedBox(height: 8),
        _shimmer(context, width: 220, height: 14),
        const SizedBox(height: 20),
        _shimmer(context, width: 100, height: 14),
        const SizedBox(height: 8),
        _shimmer(context, width: 180, height: 36, radius: 6),
        const SizedBox(height: 20),
        _shimmer(context, width: 100, height: 14),
        const SizedBox(height: 8),
        _shimmer(context, width: double.infinity, height: 180, radius: 16),
        const SizedBox(height: 24),
        _shimmer(context, width: double.infinity, height: 50, radius: 25),
      ],
    );
  }

  Widget _shimmer(BuildContext context,
      {required double width,
      required double height,
      double radius = 8}) {
    return _ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xff3a3a3a)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
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