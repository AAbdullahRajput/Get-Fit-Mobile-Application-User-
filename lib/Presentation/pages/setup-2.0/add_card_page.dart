import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:payment_card/payment_card.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
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
            child: RefreshIndicator(
              color: themeColor,
              backgroundColor: context.cardBgColor,
              displacement: 100,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                child: _isLoading
                    ? _buildSkeleton(context)
                    : _buildCardForm(context, isEdit: false),
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

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title skeleton
        _skeletonBox(context, width: 160, height: 22),
        const SizedBox(height: 16),

        // Card preview skeleton
        _skeletonBox(context, width: double.infinity, height: 200,
            radius: 16),
        const SizedBox(height: 24),

        // Text fields skeleton
        _skeletonBox(context, width: double.infinity, height: 56,
            radius: 12),
        const SizedBox(height: 16),
        _skeletonBox(context, width: double.infinity, height: 56,
            radius: 12),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _skeletonBox(context,
                    width: double.infinity, height: 56, radius: 12)),
            const SizedBox(width: 16),
            Expanded(
                child: _skeletonBox(context,
                    width: double.infinity, height: 56, radius: 12)),
          ],
        ),
        const SizedBox(height: 24),

        // Checkbox skeleton
        Row(
          children: [
            _skeletonBox(context, width: 24, height: 24, radius: 4),
            const SizedBox(width: 12),
            _skeletonBox(context, width: 200, height: 16),
          ],
        ),
        const SizedBox(height: 24),

        // Button skeleton
        _skeletonBox(context,
            width: double.infinity, height: 50, radius: 25),
      ],
    );
  }

  Widget _skeletonBox(
    BuildContext context, {
    required double width,
    required double height,
    double radius = 8,
  }) {
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

  Widget _buildCardForm(BuildContext context, {required bool isEdit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            color: context.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const PaymentCard(
          cardIssuerIcon: CardIcon(icon: Icons.credit_card),
          backgroundColor: Colors.blue,
          backgroundGradient: LinearGradient(
            colors: [Colors.purple, Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          currency: Text('USD'),
          cardNumber: '•••• •••• •••• ••••',
          validity: 'MM/YY',
          holder: 'CARD HOLDER',
          isStrict: false,
          cardNetwork: CardNetwork.visa,
          backgroundImage: null,
        ),
        const SizedBox(height: 24),
        _buildTextField(context, 'Card Holder Name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(context, 'Card Number', Icons.credit_card),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child:
                  _buildTextField(context, 'Expiry', Icons.calendar_today),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(context, 'CVC', Icons.lock_outline),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!isEdit) ...[
          Row(
            children: [
              Checkbox(
                value: false,
                onChanged: (value) {},
                fillColor: MaterialStateProperty.all(themeColor),
              ),
              Text(
                'Set as default payment method',
                style: TextStyle(color: context.textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        ReuseableButton(
          title: isEdit ? 'Save Changes' : 'Done',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTextField(
      BuildContext context, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        style: TextStyle(color: context.textColor),
        decoration: InputDecoration(
          icon: Icon(icon, color: context.subtextColor),
          labelText: label,
          labelStyle: TextStyle(color: context.subtextColor),
          border: InputBorder.none,
        ),
      ),
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