import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_fit/Presentation/pages/payment/add_card_page.dart';
import 'package:get_fit/Presentation/pages/payment/edit_card_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_booking_confirmation_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaPaymentPage extends StatefulWidget {
  final Map<String, dynamic> course;
  final double price;

  const YogaPaymentPage({
    super.key,
    required this.course,
    required this.price,
  });

  @override
  State<YogaPaymentPage> createState() => _YogaPaymentPageState();
}

class _YogaPaymentPageState extends State<YogaPaymentPage> {
  bool _isBooking = false;
  int _selectedCardIndex = 0;
  List<Map<String, dynamic>> _cards = [];
  bool _loadingCards = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await SupabaseService.getUserCards();
    final realCards = cards.where((c) => c['stripe_pm_id'] != null).toList();
    if (mounted) {
      setState(() {
        _cards = realCards;
        _loadingCards = false;
      });
    }
  }

  List<Color> _cardGradient(String network) {
    switch (network) {
      case 'Visa':
        return [const Color(0xFFB8860B), const Color(0xFFDAA520)];
      case 'Mastercard':
        return [const Color(0xFF8B0000), const Color(0xFFEB001B)];
      case 'Amex':
        return [const Color(0xFF007BC1), const Color(0xFF00BFFF)];
      default:
        return [const Color(0xFF1a1a2e), const Color(0xFF16213e)];
    }
  }

  void _showDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(icon, color: iconColor, size: 52),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.5)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onPressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(buttonText,
                style: TextStyle(
                    color: iconColor == themeColor
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPurchase() async {
    setState(() => _isBooking = true);

    try {
      final selectedCard = (_cards.isNotEmpty && _selectedCardIndex < _cards.length)
          ? _cards[_selectedCardIndex]
          : null;
      final stripePmId = selectedCard?['stripe_pm_id'] as String?;

      // 1. Create PaymentIntent on backend
      final result = await SupabaseService.createPaymentIntent(
        widget.price,
        stripePmId: stripePmId,
      );
      final clientSecret = result['clientSecret'] as String;
      final status = result['status'] as String?;

      if (stripePmId != null) {
        // Saved card — off_session charge, only needs next-action for 3DS
        if (status != 'succeeded') {
          await Stripe.instance.handleNextAction(clientSecret);
        }
      } else {
        // New card — collect via Stripe's payment sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'GetFit',
            style: ThemeMode.dark,
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      }

      // 4. Payment succeeded — record the purchase
      final instructor =
          widget.course['yoga_instructors'] as Map<String, dynamic>?;
      await SupabaseService.purchaseClass(
        classId: widget.course['id'] as String,
        instructorId: widget.course['instructor_id'] as String? ??
            instructor?['id'] as String? ??
            '',
        price: widget.price,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => YogaBookingConfirmationPage(course: widget.course),
        ),
      );
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      if (e.error.code == FailureCode.Canceled) return;
      _showDialog(
        icon: Icons.credit_card_off_outlined,
        iconColor: Colors.redAccent,
        title: 'Payment Failed',
        message: e.error.localizedMessage ?? 'Payment was not completed.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      final errMsg = e.toString();
      if (errMsg.contains('unique') || errMsg.contains('duplicate')) {
        _showDialog(
          icon: Icons.event_busy,
          iconColor: Colors.orangeAccent,
          title: 'Already Purchased',
          message: 'You already own this course.',
        );
      } else {
        _showDialog(
          icon: Icons.wifi_off_outlined,
          iconColor: Colors.redAccent,
          title: 'Purchase Failed',
          message:
              'Something went wrong while processing your purchase. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
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
                  Text('Payment',
                      style: TextStyle(
                          color: themeColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Method',
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    _loadingCards
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: themeColor))
                        : _cards.isEmpty
                            ? GestureDetector(
                                onTap: () async {
                                  final added = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const AddCardPage()));
                                  if (added == true) _loadCards();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: context.cardBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: themeColor.withOpacity(0.3),
                                        style: BorderStyle.solid),
                                  ),
                                  child: Column(
                                    children: const [
                                      Icon(Icons.add_card,
                                          color: themeColor, size: 36),
                                      SizedBox(height: 8),
                                      Text('Tap to add a payment card',
                                          style: TextStyle(
                                              color: themeColor,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 140,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _cards.length + 1,
                                  itemBuilder: (ctx, i) {
                                    if (i == 0) {
                                      return GestureDetector(
                                        onTap: () async {
                                          final added = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const AddCardPage()));
                                          if (added == true) _loadCards();
                                        },
                                        child: Container(
                                          width: 80,
                                          margin: const EdgeInsets.only(
                                              right: 12),
                                          decoration: BoxDecoration(
                                            color: context.cardBgColor,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: Colors.white12),
                                          ),
                                          child: const Icon(Icons.add,
                                              color: Colors.white54,
                                              size: 32),
                                        ),
                                      );
                                    }
                                    final card = _cards[i - 1];
                                    final isSelected =
                                        _selectedCardIndex == i - 1;
                                    return GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedCardIndex = i - 1),
                                      onLongPress: () async {
                                        final action =
                                            await showDialog<String>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor:
                                                const Color(0xFF2C2C2C),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            title: const Text('Card Options',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            content: Text(
                                              '•••• •••• •••• ${card['last4']}',
                                              style: const TextStyle(
                                                  color: Colors.white70),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, 'edit'),
                                                child: const Text('Edit',
                                                    style: TextStyle(
                                                        color: themeColor)),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, 'delete'),
                                                child: const Text('Delete',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.redAccent)),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, 'cancel'),
                                                child: const Text('Cancel',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.white54)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (action == 'edit') {
                                          final edited = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditCardPage(
                                                          card: card)));
                                          if (edited == true) _loadCards();
                                        } else if (action == 'delete') {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              backgroundColor:
                                                  const Color(0xFF2C2C2C),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20)),
                                              title: const Text('Delete Card?',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              content: Text(
                                                'Remove •••• •••• •••• ${card['last4']} from your account?',
                                                style: const TextStyle(
                                                    color: Colors.white70),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancel',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white54)),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Delete',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .redAccent)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await SupabaseService
                                                .deleteUserCard(card['id']);
                                            _loadCards();
                                          }
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 200,
                                        margin:
                                            const EdgeInsets.only(right: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: _cardGradient(
                                                card['card_network'] ?? ''),
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? themeColor
                                                : Colors.transparent,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Icon(Icons.sim_card,
                                                    color: Colors.amber,
                                                    size: 22),
                                                _buildNetworkBadge(
                                                    card['card_network'] ??
                                                        ''),
                                              ],
                                            ),
                                            Text(
                                              '•••• •••• •••• ${card['last4']}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  letterSpacing: 2,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Name',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white54,
                                                            fontSize: 9)),
                                                    Text(
                                                        card['holder_name'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    const Text('Expires',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white54,
                                                            fontSize: 9)),
                                                    Text(card['expiry'] ?? '',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                    const SizedBox(height: 24),
                    Text('Order Details',
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    Divider(
                        color: context.isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        height: 20),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.course['image_url'] ?? '',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: context.isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              child: Icon(Icons.self_improvement,
                                  color: context.subtextColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.course['title'] ?? '',
                                  style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              if (((widget.course['yoga_instructors']
                                          as Map<String, dynamic>?)?['name'] ??
                                      '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  'by ${(widget.course['yoga_instructors'] as Map<String, dynamic>?)?['name']}',
                                  style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(
                        color: context.isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount',
                            style: TextStyle(
                                color: context.subtextColor, fontSize: 15)),
                        Text('\$${widget.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: themeColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isBooking ? null : _confirmPurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isBooking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.black))
                            : const Text('Confirm & Pay',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkBadge(String network) {
    switch (network) {
      case 'Visa':
        return const Text('VISA',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2));
      case 'Mastercard':
        return Row(children: [
          Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                  color: Color(0xFFEB001B), shape: BoxShape.circle)),
          Transform.translate(
            offset: const Offset(-8, 0),
            child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: const Color(0xFFF79E1B).withOpacity(0.9),
                    shape: BoxShape.circle)),
          ),
        ]);
      case 'Amex':
        return const Text('AMEX',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2));
      case 'Discover':
        return const Text('DISCOVER',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1));
      default:
        return const Icon(Icons.credit_card, color: Colors.white54, size: 22);
    }
  }
}