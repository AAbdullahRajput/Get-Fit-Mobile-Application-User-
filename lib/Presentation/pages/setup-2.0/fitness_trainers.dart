import 'package:flutter/material.dart';
import 'package:get_fit/Domain/models/fitness_trainer_model.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/fitness_tainer_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class FitnessTrainers extends StatefulWidget {
  const FitnessTrainers({super.key});

  @override
  State<FitnessTrainers> createState() => _FitnessTrainersState();
}

class _FitnessTrainersState extends State<FitnessTrainers> {
  static bool _hasLoaded = false;
  bool _isLoading = true;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 60, 14, 14),
              child: Column(
                children: [
                  Text(
                    'Fitness Trainers',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RefreshIndicator(
                      color: themeColor,
                      backgroundColor: context.cardBgColor,
                      displacement: 100,
                      onRefresh: _onRefresh,
                      child: _isLoading
                          ? _buildSkeleton(context)
                          : _buildList(context),
                    ),
                  ),
                ],
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

  Widget _buildList(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final trainer = contents[index];
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Card(
            color: context.cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: context.isDark ? 0 : 2,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: themeColor,
                radius: 30,
                backgroundImage: NetworkImage(trainer.image),
              ),
              title: Text(
                trainer.name,
                style: TextStyle(color: context.textColor, fontSize: 18),
              ),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer.trainingType,
                    style:
                        TextStyle(color: context.subtextColor, fontSize: 14),
                  ),
                  Text(
                    '${trainer.experience} years experience',
                    style: TextStyle(color: context.textColor, fontSize: 14),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.arrow_forward, color: context.textColor),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      trainer.rating,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FitnessTrainerDetailPage(
                      bgImg: trainer.bg_img,
                      trainerName: trainer.name,
                      trainerExp: trainer.experience,
                      trainerType: trainer.trainingType,
                      trainerClients: trainer.active_clients,
                      trainingCompleted: trainer.training_completed,
                      trainerRating: trainer.rating,
                    ),
                  ),
                );
              },
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
          padding: const EdgeInsets.all(4.0),
          child: _ShimmerWidget(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xff3a3a3a)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
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