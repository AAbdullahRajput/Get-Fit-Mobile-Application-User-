import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaDetailPage extends StatefulWidget {
  final Map<String, dynamic> yoga;

  const YogaDetailPage({super.key, required this.yoga});

  @override
  State<YogaDetailPage> createState() => _YogaDetailPageState();
}

class _YogaDetailPageState extends State<YogaDetailPage> {
  List<Map<String, dynamic>> _steps = [];
  List<Map<String, dynamic>> _dos = [];
  List<Map<String, dynamic>> _donts = [];
  bool _isLoading = true;
  int _visibleSteps = 2;
  static const int _stepsPageSize = 2;

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    final data =
        await SupabaseService.getYogaClassSteps(widget.yoga['id']);
    if (mounted) {
      setState(() {
        _steps = data.where((s) => s['type'] == 'step').toList();
        _dos = data.where((s) => s['type'] == 'do').toList();
        _donts = data.where((s) => s['type'] == 'dont').toList();
        _isLoading = false;
      });
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return themeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final yoga = widget.yoga;
    final level = yoga['level'] ?? '';
    final rating = double.parse(yoga['rating'].toString());
    final visibleSteps = _steps.take(_visibleSteps).toList();
    final hasMoreSteps = _visibleSteps < _steps.length;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    const Text(
                      'Yoga Classes',
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Stack(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Image.network(
                    yoga['image_url'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 280,
                      color: const Color(0xFF2C2C2C),
                      child: const Icon(Icons.self_improvement,
                          color: Colors.white38, size: 80),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, context.bgColor],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('FREE',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(yoga['title'] ?? '',
                      style: const TextStyle(
                          color: themeColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Badges + rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _levelColor(level).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _levelColor(level).withOpacity(0.5)),
                        ),
                        child: Text(level,
                            style: TextStyle(
                                color: _levelColor(level),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      if ((yoga['category'] ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: themeColor.withOpacity(0.3)),
                          ),
                          child: Text(yoga['category'],
                              style: const TextStyle(
                                  color: themeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      const Spacer(),
                      const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1),
                          style: TextStyle(
                              color: context.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Duration only (no time)
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          color: themeColor, size: 15),
                      const SizedBox(width: 6),
                      Text('${yoga['duration_minutes']} min',
                          style: TextStyle(
                              color: context.subtextColor, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('About',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(yoga['description'] ?? '',
                      style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 14,
                          height: 1.6)),
                  const SizedBox(height: 20),

                  // Free note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: themeColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_open_outlined,
                            color: themeColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Free guide — no booking required. Follow the steps below at your own pace.',
                            style: TextStyle(
                                color: context.subtextColor,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_isLoading)
                    _buildSkeletonSection(context)
                  else ...[
                    // STEPS
                    if (_steps.isNotEmpty) ...[
                      _sectionHeader(context, 'Step-by-Step Guide',
                          Icons.format_list_numbered, themeColor),
                      const SizedBox(height: 16),
                      ...visibleSteps.asMap().entries.map(
                            (e) => _buildStepCard(
                                context, e.key + 1, e.value),
                          ),
                      if (hasMoreSteps)
                        _buildLoadMoreSteps(context),
                      const SizedBox(height: 28),
                    ],

                    // DO's
                    if (_dos.isNotEmpty) ...[
                      _sectionHeader(context, 'What To Do',
                          Icons.check_circle_outline, Colors.green),
                      const SizedBox(height: 16),
                      ..._dos.map(
                          (d) => _buildDoCard(context, d, isdo: true)),
                      const SizedBox(height: 28),
                    ],

                    // DON'Ts
                    if (_donts.isNotEmpty) ...[
                      _sectionHeader(context, 'What To Avoid',
                          Icons.cancel_outlined, Colors.redAccent),
                      const SizedBox(height: 16),
                      ..._donts.map(
                          (d) => _buildDoCard(context, d, isdo: false)),
                      const SizedBox(height: 28),
                    ],

                    if (_steps.isEmpty && _dos.isEmpty && _donts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.self_improvement,
                                color: themeColor, size: 48),
                            const SizedBox(height: 12),
                            Text('Guide coming soon',
                                style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                              'Step-by-step instructions for this session will be added shortly.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: context.subtextColor,
                                  fontSize: 13,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreSteps(BuildContext context) {
    final remaining = _steps.length - _visibleSteps;
    return GestureDetector(
      onTap: () => setState(() {
        _visibleSteps = (_visibleSteps + _stepsPageSize)
            .clamp(0, _steps.length);
      }),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: themeColor, width: 1.5),
              ),
              child: const Icon(Icons.add, color: themeColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'Load $remaining more step${remaining > 1 ? 's' : ''}',
              style: const TextStyle(
                  color: themeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title,
      IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                color: context.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStepCard(
      BuildContext context, int number, Map<String, dynamic> step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title at top of card
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$number',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(step['title'] ?? '',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Image below title
          if ((step['image_url'] ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                step['image_url'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: context.isDark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  child: Icon(Icons.image_outlined,
                      color: context.subtextColor, size: 40),
                ),
              ),
            ),

          // Description below image
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(step['description'] ?? '',
                style: TextStyle(
                    color: context.subtextColor,
                    fontSize: 13,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildDoCard(BuildContext context, Map<String, dynamic> item,
      {required bool isdo}) {
    final color = isdo ? Colors.green : Colors.redAccent;
    final icon = isdo ? Icons.check_circle : Icons.cancel;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title at top
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item['title'] ?? '',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Image
          if ((item['image_url'] ?? '').isNotEmpty)
            Image.network(
              item['image_url'],
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: context.isDark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                child: Icon(Icons.image_outlined,
                    color: context.subtextColor, size: 40),
              ),
            ),

          // Description
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(item['description'] ?? '',
                style: TextStyle(
                    color: context.subtextColor,
                    fontSize: 13,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmer(context, width: 160, height: 20),
        const SizedBox(height: 16),
        _shimmer(context, width: double.infinity, height: 260),
        const SizedBox(height: 12),
        _shimmer(context, width: double.infinity, height: 260),
        const SizedBox(height: 28),
        _shimmer(context, width: 140, height: 20),
        const SizedBox(height: 16),
        _shimmer(context, width: double.infinity, height: 200),
        const SizedBox(height: 12),
        _shimmer(context, width: double.infinity, height: 200),
      ],
    );
  }

  Widget _shimmer(BuildContext context,
      {required double width, required double height}) {
    return _ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xff3a3a3a)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
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