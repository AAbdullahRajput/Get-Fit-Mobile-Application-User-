import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/write_review_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Presentation/widgets/review_card.dart';
import 'package:get_fit/Utils/constants.dart';

// Dummy review data — replace with Supabase fetch later
class ReviewModel {
  final String name;
  final String avatarUrl;
  final double rating;
  final String comment;
  final String timeAgo;

  const ReviewModel({
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.timeAgo,
  });
}

final List<ReviewModel> dummyReviews = [
  ReviewModel(
    name: 'Emma Wilson',
    avatarUrl: 'https://randomuser.me/api/portraits/women/1.jpg',
    rating: 5.0,
    comment: 'Absolutely amazing trainer! My fitness level improved drastically in just 3 months.',
    timeAgo: '2d ago',
  ),
  ReviewModel(
    name: 'Liam Johnson',
    avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg',
    rating: 4.5,
    comment: 'Very professional and knowledgeable. Always pushes me to do better.',
    timeAgo: '5d ago',
  ),
  ReviewModel(
    name: 'Sophia Martinez',
    avatarUrl: 'https://randomuser.me/api/portraits/women/3.jpg',
    rating: 4.0,
    comment: 'Great sessions, very motivating. Would highly recommend to anyone starting out.',
    timeAgo: '1w ago',
  ),
  ReviewModel(
    name: 'Noah Brown',
    avatarUrl: 'https://randomuser.me/api/portraits/men/4.jpg',
    rating: 5.0,
    comment: 'Best investment I made for my health. Results speak for themselves.',
    timeAgo: '2w ago',
  ),
  ReviewModel(
    name: 'Olivia Davis',
    avatarUrl: 'https://randomuser.me/api/portraits/women/5.jpg',
    rating: 4.5,
    comment: 'Incredibly patient and supportive. Perfect for beginners like me.',
    timeAgo: '3w ago',
  ),
  ReviewModel(
    name: 'James Lee',
    avatarUrl: 'https://randomuser.me/api/portraits/men/6.jpg',
    rating: 4.0,
    comment: 'Solid trainer with great exercise variety. Never get bored in sessions.',
    timeAgo: '1mo ago',
  ),
];

class ReviewsPage extends StatefulWidget {
  final String rating;

  const ReviewsPage({super.key, required this.rating});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  static bool _hasLoaded = false;
  bool _isLoading = false;
  int selectedIndex = 0;

  final List<String> categories = ['Recent', 'Critical', 'Favourables'];

  @override
    @override
  void initState() {
    super.initState();
    _precacheImages();
  }

  Future<void> _precacheImages() async {
    await Future.wait(
      dummyReviews.map(
        (r) => precacheImage(NetworkImage(r.avatarUrl), context),
      ),
    );
    if (mounted) {
      _hasLoaded = true;
    }
  }

      Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 800)),
      ...dummyReviews.map(
        (r) => precacheImage(NetworkImage(r.avatarUrl), context),
      ),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 56),

                // Category Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: context.cardBgColor,
                  ),
                  height: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedIndex = index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                decoration: BoxDecoration(
                                  color: selectedIndex == index
                                      ? themeColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Text(
                                    categories[index],
                                    style: TextStyle(
                                      color: selectedIndex == index
                                          ? Colors.black
                                          : context.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rating Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      widget.rating,
                      style: TextStyle(
                        color: context.isDark ? themeColor : Colors.black87,
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ratingBar(context, 177),
                        _ratingBar(context, 145),
                        _ratingBar(context, 100),
                        _ratingBar(context, 50),
                        _ratingBar(context, 30),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Reviews List
                Expanded(
                  child: RefreshIndicator(
                    color: context.subtextColor,
                    backgroundColor: context.cardBgColor,
                    displacement: 100,
                    onRefresh: _onRefresh,
                    child: _isLoading
                        ? _buildSkeleton(context)
                        : _buildList(context),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ReuseableButton(
                    title: "Write a Review",
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => WriteReviewPage()));
                    },
                  ),
                ),
              ],
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

  Widget _buildList(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: dummyReviews.length,
      itemBuilder: (context, index) {
        final review = dummyReviews[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Card(
            color: context.cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: context.isDark ? 0 : 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: themeColor,
                        child: ClipOval(
                          child: Image.network(
                            review.avatarUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.person,
                                    color: Colors.black, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${review.name} (${review.rating})',
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < review.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: themeColor,
                                  size: 14,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        review.timeAgo,
                        style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    review.comment,
                    style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _ShimmerWidget(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xff3a3a3a)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xff4a4a4a)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? const Color(0xff4a4a4a)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 200,
                          height: 10,
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? const Color(0xff4a4a4a)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 160,
                          height: 10,
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? const Color(0xff4a4a4a)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
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

  Widget _ratingBar(BuildContext context, double width) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      color: context.isDark ? Colors.white : context.textColor,
      height: 5,
      width: width,
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