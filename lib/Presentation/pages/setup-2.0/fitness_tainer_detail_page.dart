
import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/appointment_booking_page.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/reviews_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Presentation/widgets/review_card.dart';
import 'package:get_fit/Utils/constants.dart';

class FitnessTrainerDetailPage extends StatefulWidget {
  final String bgImg;
  final String trainerName;
  final String trainerExp;
  final String trainerType;
  final String trainerRating;
  final String trainerClients;
  final String trainingCompleted;

  const FitnessTrainerDetailPage({
    super.key,
    required this.bgImg,
    required this.trainerName,
    required this.trainerExp,
    required this.trainerRating,
    required this.trainerType,
    required this.trainerClients,
    required this.trainingCompleted,
  });

  @override
  State<FitnessTrainerDetailPage> createState() =>
      _FitnessTrainerDetailPageState();
}

class _FitnessTrainerDetailPageState extends State<FitnessTrainerDetailPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Background Image
          Image.network(widget.bgImg, fit: BoxFit.fitHeight),

          // Content
          Positioned(
            top: 240,
            child: RefreshIndicator(
              color: context.subtextColor,
              backgroundColor: context.cardBgColor,
              displacement: 100,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 240,
                  ),
                  decoration: BoxDecoration(
                    color: context.bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: _isLoading
                      ? _buildSkeleton(context)
                      : _buildContent(context),
                ),
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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            widget.trainerName,
            style: TextStyle(
                color: context.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            widget.trainerType,
            style: TextStyle(color: context.subtextColor, fontSize: 16),
          ),
          trailing: CircleAvatar(
            radius: 15,
            backgroundColor: themeColor,
            child: const Icon(Icons.phone, color: Colors.black, size: 19),
          ),
        ),
        Card(
          color: context.cardBgColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(widget.trainerExp,
                        style: TextStyle(
                            color: context.textColor, fontSize: 25)),
                    Text('Experience',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text(widget.trainingCompleted,
                        style: TextStyle(
                            color: context.textColor, fontSize: 25)),
                    Text('Completed',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text(widget.trainerClients,
                        style: TextStyle(
                            color: context.textColor, fontSize: 25)),
                    Text('Active Clients',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          title: Text(
            'Reviews',
            style: TextStyle(
                color: context.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          subtitle: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.amberAccent,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundImage:
                          NetworkImage('https://picsum.photos/200'),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.pink,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage:
                            NetworkImage('https://picsum.photos/201'),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-20, 0),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.orange,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage:
                            NetworkImage('https://picsum.photos/202'),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: Text(
                      '+28 more',
                      style: TextStyle(
                          color: context.subtextColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(widget.trainerRating,
                    style: const TextStyle(color: Colors.black)),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          ReviewsPage(rating: widget.trainerRating)));
                },
                child: Text("Read all Reviews",
                    style: TextStyle(
                        color: context.subtextColor, fontSize: 12)),
              ),
            ],
          ),
        ),
        const ReviewCard(),
        const SizedBox(height: 20),
        ReuseableButton(
          title: "Book an Appointment",
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AppointmentBookingPage()));
          },
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trainer name + type
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(context, width: 160, height: 24),
                const SizedBox(height: 8),
                _shimmer(context, width: 100, height: 16),
              ],
            ),
            _shimmer(context, width: 30, height: 30, radius: 15),
          ],
        ),
        const SizedBox(height: 16),

        // Stats card
        _shimmer(context, width: double.infinity, height: 80, radius: 12),
        const SizedBox(height: 16),

        // Reviews header
        _shimmer(context, width: 100, height: 20),
        const SizedBox(height: 12),

        // Review avatars
        _shimmer(context, width: 200, height: 30, radius: 15),
        const SizedBox(height: 16),

        // Review card
        _shimmer(context, width: double.infinity, height: 100, radius: 16),
        const SizedBox(height: 20),

        // Button
        _shimmer(context, width: double.infinity, height: 50, radius: 25),
      ],
    );
  }

  Widget _shimmer(BuildContext context,
      {required double width, required double height, double radius = 8}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: _ShimmerWidget(
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
      ),
    );
  }
}

// ============================================================
// SHARED: _ShimmerWidget (add to bottom of BOTH files)
// ============================================================

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
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}