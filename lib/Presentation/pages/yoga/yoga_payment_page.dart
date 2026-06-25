import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/payment/add_card_page.dart';
import 'package:get_fit/Presentation/pages/payment/edit_card_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_booking_confirmation_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaPaymentPage extends StatefulWidget {
  final Map<String, dynamic> instructor;
  final String startDate;
  final String displayDate;
  final int numSessions;
  final double totalPrice;
  final String notes;
final List<String> selectedSessionIds;

  const YogaPaymentPage({
  super.key,
  required this.instructor,
  required this.startDate,
  required this.displayDate,
  required this.numSessions,
  required this.totalPrice,
  required this.notes,
  required this.selectedSessionIds,
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
    if (mounted) {
      setState(() {
        _cards = cards;
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

  Future<void> _confirmBooking() async {
    if (_cards.isEmpty) {
      _showDialog(
        icon: Icons.credit_card_off_outlined,
        iconColor: Colors.orangeAccent,
        title: 'No Payment Method',
        message:
            'Please add a payment card before confirming your booking.',
        buttonText: 'Add Card',
        onPressed: () async {
          final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCardPage()));
          if (added == true) _loadCards();
        },
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      await SupabaseService.bookInstructorSessions(
  instructorId: widget.instructor['id'],
  sessionIds: widget.selectedSessionIds,
  sessionCount: widget.numSessions,
  totalPrice: widget.totalPrice,
  notes: widget.notes,
);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => YogaBookingConfirmationPage(
            instructor: widget.instructor,
            displayDate: widget.displayDate,
            numSessions: widget.numSessions,
            totalPrice: widget.totalPrice,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      final errMsg = e.toString();
      if (errMsg.contains('unique') || errMsg.contains('duplicate')) {
        _showDialog(
          icon: Icons.event_busy,
          iconColor: Colors.orangeAccent,
          title: 'Already Booked',
          message:
              'You already have a booking on ${widget.displayDate}. Please go back and choose a different date.',
          buttonText: 'OK',
        );
      } else {
        _showDialog(
          icon: Icons.wifi_off_outlined,
          iconColor: Colors.redAccent,
          title: 'Booking Failed',
          message:
              'Something went wrong while processing your booking. Please try again.',
          buttonText: 'Try Again',
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
                                        final edited = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    EditCardPage(card: card)));
                                        if (edited == true) _loadCards();
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

                    // Order details
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
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: themeColor,
                          backgroundImage:
                              (widget.instructor['image_url'] ?? '').isNotEmpty
                                  ? NetworkImage(widget.instructor['image_url'])
                                  : null,
                          child: (widget.instructor['image_url'] ?? '').isEmpty
                              ? const Icon(Icons.self_improvement,
                                  color: Colors.black, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.instructor['name'] ?? '',
                                  style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold)),
                              Text(widget.instructor['specialty'] ?? '',
                                  style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            double.parse(widget.instructor['rating'].toString())
                                .toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    Divider(
                        color: context.isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        height: 24),

                    Text('Start Date',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(widget.displayDate,
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
                    Divider(
                        color: context.isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        height: 24),

                    Text('Sessions',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('${widget.numSessions} sessions',
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
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
                        Text('\$${widget.totalPrice.toStringAsFixed(2)}',
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
                        onPressed: _isBooking ? null : _confirmBooking,
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
                            : const Text('Confirm & Book',
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