import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/payment/add_card_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/payment/edit_card_page.dart';
import 'package:get_fit/Presentation/pages/booking/booking_confirmation_page.dart';
class AppointmentPaymentPage extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final String trainerType;
  final String date;
  final String displayDate;
  final String time;
  final String notes;
  final double sessionPrice;
  final double trainerRating;
  final String trainerAvatarUrl;

  const AppointmentPaymentPage({
    super.key,
    required this.trainerId,
    required this.trainerName,
    required this.trainerType,
    required this.date,
    required this.displayDate,
    required this.time,
    required this.notes,
    this.sessionPrice = 50.00,
    this.trainerRating = 0.0,
    this.trainerAvatarUrl = '',
  });

  @override
  State<AppointmentPaymentPage> createState() => _AppointmentPaymentPageState();
}

class _AppointmentPaymentPageState extends State<AppointmentPaymentPage> {
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
    if (mounted) setState(() { _cards = cards; _loadingCards = false; });
  }

  List<Color> _cardGradient(String network) {
    switch (network) {
      case 'Visa': return [const Color(0xFFB8860B), const Color(0xFFDAA520)];
      case 'Mastercard': return [const Color(0xFF8B0000), const Color(0xFFEB001B)];
      case 'Amex': return [const Color(0xFF007BC1), const Color(0xFF00BFFF)];
      default: return [const Color(0xFF1a1a2e), const Color(0xFF16213e)];
    }
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      await SupabaseService.bookAppointment(
        trainerId: widget.trainerId,
        date: widget.date,
        time: widget.time,
        notes: widget.notes,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(
            trainerName: widget.trainerName,
            trainerType: widget.trainerType,
            trainerRating: widget.trainerRating,
            trainerAvatarUrl: widget.trainerAvatarUrl,
            displayDate: widget.displayDate,
            time: widget.time,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('unique') || e.toString().contains('duplicate')
          ? 'This slot was just booked. Please go back and pick another.'
          : 'Failed to book. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [
          Icon(Icons.check_circle_outline, color: themeColor, size: 56),
          SizedBox(height: 8),
          Text('Appointment Booked!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.trainerName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: themeColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${widget.displayDate}  •  ${widget.time}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          const Text('Pending confirmation from the trainer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(12)),
              child: const Text('Done',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCard = _cards.isNotEmpty ? _cards[_selectedCardIndex] : null;

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
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text('Payment',
                      style: TextStyle(color: themeColor, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method
                    Text('Payment Method',
                        style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),

                    // Card selector
                    _loadingCards
                        ? const Center(child: CircularProgressIndicator(color: themeColor))
                        :
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cards.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            return GestureDetector(
                              onTap: () async {
                                final added = await Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const AddCardPage()));
                                if (added == true) _loadCards();
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: context.cardBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Icon(Icons.add, color: Colors.white54, size: 32),
                              ),
                            );
                          }
                          final card = _cards[i - 1];
                          final isSelected = _selectedCardIndex == i - 1;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCardIndex = i - 1),
                            onLongPress: () async {
                              final edited = await Navigator.push(context,
                                  MaterialPageRoute(
                                    builder: (_) => EditCardPage(card: card),
                                  ));
                              if (edited == true) _loadCards();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 200,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _cardGradient(card['card_network'] ?? ''),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? themeColor : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Top row: chip + network
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(Icons.sim_card, color: Colors.amber, size: 22),
                                      _buildNetworkBadge(card['card_network'] ?? ''),
                                    ],
                                  ),
                                  // Card number
                                  Text(
                                    '•••• •••• •••• ${card['last4']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  // Name + expiry
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Name',
                                              style: TextStyle(color: Colors.white54, fontSize: 9)),
                                          Text(card['holder_name'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Expired Date',
                                              style: TextStyle(color: Colors.white54, fontSize: 9)),
                                          Text(card['expiry'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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

                    // Order Details
                    Text('Order Details',
                        style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.bold)),
                    Divider(color: context.isDark ? Colors.white12 : Colors.grey.shade200, height: 20),

                    // Trainer row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: themeColor,
                          backgroundImage: widget.trainerAvatarUrl.isNotEmpty
                              ? NetworkImage(widget.trainerAvatarUrl) : null,
                          child: widget.trainerAvatarUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.black, size: 28) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.trainerName,
                                  style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold)),
                              Text(widget.trainerType,
                                  style: TextStyle(color: context.subtextColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (widget.trainerRating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.trainerRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                    Divider(color: context.isDark ? Colors.white12 : Colors.grey.shade200, height: 24),

                    // Date
                    Text('Date', style: TextStyle(color: context.subtextColor, fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(widget.displayDate,
                        style: TextStyle(
                            color: context.textColor, fontSize: 20, fontWeight: FontWeight.w600)),
                    Divider(color: context.isDark ? Colors.white12 : Colors.grey.shade200, height: 24),

                    // Time
                    Text('Time', style: TextStyle(color: context.subtextColor, fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(widget.time,
                        style: TextStyle(
                            color: context.textColor, fontSize: 20, fontWeight: FontWeight.w600)),
                    Divider(color: context.isDark ? Colors.white12 : Colors.grey.shade200, height: 24),

                    // Estimated Cost
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated Cost',
                            style: TextStyle(color: context.subtextColor, fontSize: 15)),
                        Text('\$ ${widget.sessionPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: context.textColor,
                                fontSize: 20,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isBooking
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
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
        return Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Container(
                width: 22, height: 22,
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
        return const Icon(Icons.credit_card, color: Colors.white54, size: 22);
    }
  }
}