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

  const YogaPaymentPage({
    super.key,
    required this.instructor,
    required this.startDate,
    required this.displayDate,
    required this.numSessions,
    required this.totalPrice,
    required this.notes,
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

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      await SupabaseService.bookYogaSession(
        instructorId: widget.instructor['id'],
        startDate: widget.startDate,
        numSessions: widget.numSessions,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to book. Please try again.',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
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
                    child:
                        const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Payment',
                    style: TextStyle(
                        color: themeColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment method
                    Text(
                      'Payment Method',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Card selector
                    _loadingCards
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: themeColor))
                        : SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _cards.length + 1,
                              itemBuilder: (ctx, i) {
                                if (i == 0) {
                                  return GestureDetector(
                                    onTap: () async {
                                      final added =
                                          await Navigator.push(
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
                                    final edited =
                                        await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    EditCardPage(
                                                        card: card)));
                                    if (edited == true) _loadCards();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    width: 200,
                                    margin: const EdgeInsets.only(
                                        right: 12),
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
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                const Text('Name',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .white54,
                                                        fontSize: 9)),
                                                Text(
                                                    card['holder_name'] ??
                                                        '',
                                                    style: const TextStyle(
                                                        color:
                                                            Colors.white,
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
                                                        color: Colors
                                                            .white54,
                                                        fontSize: 9)),
                                                Text(
                                                    card['expiry'] ?? '',
                                                    style: const TextStyle(
                                                        color:
                                                            Colors.white,
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
                    Text(
                      'Order Details',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    Divider(
                        color: context.isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        height: 20),

                    // Instructor row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: themeColor,
                          backgroundImage: (widget.instructor['image_url'] ??
                                      '')
                                  .isNotEmpty
                              ? NetworkImage(
                                  widget.instructor['image_url'])
                              : null,
                          child: (widget.instructor['image_url'] ?? '')
                                  .isEmpty
                              ? const Icon(Icons.self_improvement,
                                  color: Colors.black, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.instructor['name'] ?? '',
                                style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                widget.instructor['specialty'] ?? '',
                                style: TextStyle(
                                    color: context.subtextColor,
                                    fontSize: 13),
                              ),
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
                            (widget.instructor['rating'] as num?)
                                    ?.toStringAsFixed(1) ??
                                '0.0',
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

                    // Start date
                    Text('Start Date',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      widget.displayDate,
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600),
                    ),
                    Divider(
                        color: context.isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        height: 24),

                    // Sessions
                    Text('Sessions',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.numSessions} sessions',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600),
                    ),
                    Divider(
                        color: context.isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        height: 24),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount',
                            style: TextStyle(
                                color: context.subtextColor,
                                fontSize: 15)),
                        Text(
                          '\$${widget.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: themeColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isBooking ? null : _confirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          disabledBackgroundColor: Colors.grey,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isBooking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black))
                            : const Text(
                                'Confirm & Book',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
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
        return Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                  color: Color(0xFFEB001B), shape: BoxShape.circle),
            ),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFF79E1B).withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
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
        return const Icon(Icons.credit_card,
            color: Colors.white54, size: 22);
    }
  }
}