import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class AppointmentPaymentPage extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final String trainerType;
  final String date;
  final String displayDate;
  final String time;
  final String notes;

  const AppointmentPaymentPage({
    super.key,
    required this.trainerId,
    required this.trainerName,
    required this.trainerType,
    required this.date,
    required this.displayDate,
    required this.time,
    required this.notes,
  });

  @override
  State<AppointmentPaymentPage> createState() => _AppointmentPaymentPageState();
}

class _AppointmentPaymentPageState extends State<AppointmentPaymentPage> {
  bool _isBooking = false;

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
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('unique') || e.toString().contains('duplicate')
          ? 'This slot was just booked by someone else. Please go back and pick another.'
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
              Navigator.pop(context); // dialog
              Navigator.pop(context); // payment
              Navigator.pop(context); // booking
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
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment',
                      style: TextStyle(color: themeColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Confirm your appointment',
                      style: TextStyle(color: context.subtextColor, fontSize: 15)),
                  const SizedBox(height: 24),

                  // Trainer card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: themeColor,
                          child: const Icon(Icons.person, color: Colors.black, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.trainerName,
                                  style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.bold)),
                              Text(widget.trainerType,
                                  style: TextStyle(color: context.subtextColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: context.subtextColor, size: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Details',
                            style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        Divider(color: context.isDark ? Colors.white12 : Colors.grey.shade200, height: 20),
                        _detailRow(context, 'Date', widget.displayDate),
                        const SizedBox(height: 10),
                        _detailRow(context, 'Time', widget.time),
                        if (widget.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _detailRow(context, 'Notes', widget.notes),
                        ],
                        Divider(color: context.isDark ? Colors.white12 : Colors.grey.shade200, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Estimated Cost', style: TextStyle(color: context.subtextColor, fontSize: 14)),
                            Text('\$50.00',
                                style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment method (static for now)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.credit_card, color: themeColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment Method', style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('•••• •••• •••• 4242', style: TextStyle(color: context.subtextColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        Text('Change', style: TextStyle(color: themeColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Confirm button
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
                              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back button
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

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(color: context.subtextColor, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value, style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}