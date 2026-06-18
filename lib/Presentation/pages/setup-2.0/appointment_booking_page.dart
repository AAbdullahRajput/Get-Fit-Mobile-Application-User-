import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/payment_page.dart';
import 'package:get_fit/Presentation/widgets/fitness_trainer_card.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class AppointmentBookingPage extends StatefulWidget {
  const AppointmentBookingPage({super.key});

  @override
  State<AppointmentBookingPage> createState() =>
      _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
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
          SafeArea(
            child: RefreshIndicator(
              color: themeColor,
              backgroundColor: context.cardBgColor,
              displacement: 100,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(8, 60, 8, 16),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      80,
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
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
      children: [
        FitnessTrainerCard(),
        const SizedBox(height: 16),
        ReuseableButton(
          title: "Pick Date and Time",
          onPressed: () async => await showOmniDateTimePicker(
            context: context,
            theme: ThemeData(
              colorScheme: context.isDark
                  ? const ColorScheme.dark(
                      primary: themeColor,
                      onPrimary: Colors.black,
                    )
                  : const ColorScheme.light(
                      primary: Colors.black,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
            ),
          ),
        ),
        const Spacer(),
        ReuseableButton(
          title: "Next",
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PaymentPage(),
            ));
          },
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: [
        // Trainer card skeleton
        _ShimmerWidget(
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xff3a3a3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pick Date button skeleton
        _ShimmerWidget(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 50,
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xff3a3a3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        const Spacer(),

        // Next button skeleton
        _ShimmerWidget(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 50,
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xff3a3a3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ],
    );
  }
}

// Shimmer animation widget
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