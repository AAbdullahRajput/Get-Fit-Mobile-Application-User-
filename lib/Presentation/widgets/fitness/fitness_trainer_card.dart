import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/fitnes_trainer/fitness_tainer_detail_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class FitnessTrainerCard extends StatefulWidget {
  const FitnessTrainerCard({super.key});

  @override
  State<FitnessTrainerCard> createState() => _FitnessTrainerCardState();
}

class _FitnessTrainerCardState extends State<FitnessTrainerCard> {
  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getTrainers();
    if (mounted) setState(() { _trainers = data; _isLoading = false; });
  }

  Future<void> _onRefresh() async => _loadData();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: themeColor,
      backgroundColor: context.cardBgColor,
      displacement: 100,
      onRefresh: _onRefresh,
      child: _isLoading ? _buildSkeleton(context) : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _trainers.length,
      itemBuilder: (context, index) => _buildCard(context, _trainers[index]),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> trainer) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        color: context.cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: context.isDark ? 0 : 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: themeColor,
            radius: 30,
            child: ClipOval(
              child: Image.network(
                trainer['image_url'] ?? '',
                width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.black, size: 30),
              ),
            ),
          ),
          title: Text(trainer['name'] ?? '',
              style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trainer['training_type'] ?? '',
                  style: TextStyle(color: context.subtextColor, fontSize: 14)),
              Text('${trainer['experience']} experience',
                  style: TextStyle(color: themeColor, fontSize: 13)),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.arrow_forward, color: context.textColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  trainer['rating'].toString(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FitnessTrainerDetailPage(trainer: trainer),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(4.0),
        child: _ShimmerWidget(
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(width: 56, height: 56,
                    decoration: BoxDecoration(
                        color: context.isDark ? const Color(0xff4a4a4a) : Colors.grey.shade400,
                        shape: BoxShape.circle)),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14,
                        decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xff4a4a4a) : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 10,
                        decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xff4a4a4a) : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ],
            ),
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _animation, child: widget.child);
}