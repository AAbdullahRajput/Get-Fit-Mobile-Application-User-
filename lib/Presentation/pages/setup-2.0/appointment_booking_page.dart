import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/payment_page.dart';
class AppointmentBookingPage extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final String trainerType;
  final String trainerExperience;
  final String trainerAvatarUrl;
  final double sessionPrice;
  final double trainerRating;

  const AppointmentBookingPage({
    super.key,
    required this.trainerId,
    required this.trainerName,
    this.trainerType = '',
    this.trainerExperience = '',
    this.trainerAvatarUrl = '',
    this.sessionPrice = 50.00,
    this.trainerRating = 0.0,
  });

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  double _selectedPrice = 0.0;
  List<String> _bookedSlots = [];
  bool _loadingSlots = false;
  List<Map<String, dynamic>> _trainerSlots = [];
  bool _loadingTrainerSlots = true;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTrainerSlots();
  }

  Future<void> _loadTrainerSlots() async {
    final slots = await SupabaseService.getTrainerSlots(widget.trainerId);
    if (mounted) setState(() { _trainerSlots = slots; _loadingTrainerSlots = false; });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() { _loadingSlots = true; _selectedTime = null; });
    final dateStr = _dateToStr(date);
    final booked = await SupabaseService.getBookedSlots(
      trainerId: widget.trainerId,
      date: dateStr,
    );
    if (mounted) setState(() { _bookedSlots = booked; _loadingSlots = false; });
  }

  String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
          Text(
            '${_formatDisplayDate(_selectedDate!)}  •  $_selectedTime',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text('Pending confirmation from the trainer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
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

  String _formatDisplayDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${months[d.month - 1]} ${d.day}, ${d.year} - ${days[d.weekday - 1]}';
  }

  void _prevMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

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
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text('Appointment',
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
                  // Trainer card — Figma style
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: themeColor,
                        backgroundImage: widget.trainerAvatarUrl.isNotEmpty
                            ? NetworkImage(widget.trainerAvatarUrl) : null,
                        child: widget.trainerAvatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.black, size: 30) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(widget.trainerName,
                                      style: TextStyle(
                                          color: context.textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Icon(Icons.arrow_forward, color: themeColor, size: 18),
                              ],
                            ),
                            Text(widget.trainerType,
                                style: TextStyle(color: context.subtextColor, fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (widget.trainerExperience.isNotEmpty)
                                  Text('${widget.trainerExperience} years experience',
                                      style: TextStyle(color: themeColor, fontSize: 12)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.trainerRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Calendar
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Month header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _prevMonth,
                              child: Icon(Icons.chevron_left, color: context.textColor),
                            ),
                            Text(
                              '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                              style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: _nextMonth,
                              child: Icon(Icons.chevron_right, color: context.textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Day headers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['Mo','Tu','We','Th','Fr','Sa','Su'].map((d) =>
                            SizedBox(
                              width: 36,
                              child: Text(d,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            )
                          ).toList(),
                        ),
                        const SizedBox(height: 8),
                        // Day grid
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected date display
                  if (_selectedDate != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: themeColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: themeColor, size: 16),
                          const SizedBox(width: 8),
                          Text(_formatDisplayDate(_selectedDate!),
                              style: TextStyle(
                                  color: context.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Time slots — always shown, Figma style horizontal
                  Text('Time',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _loadingSlots
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: themeColor)))
                      : _buildTimeSlots(),
                  const SizedBox(height: 20),

                  // Confirm button
                  // Next button → Payment
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedDate == null || _selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Select a date and time slot first.',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentPaymentPage(
                              trainerId: widget.trainerId,
                              trainerName: widget.trainerName,
                              trainerType: widget.trainerType,
                              date: _dateToStr(_selectedDate!),
                              displayDate: _formatDisplayDate(_selectedDate!),
                              time: _selectedTime!,
                              notes: _notesController.text.trim(),
                              sessionPrice: _selectedPrice,
                              trainerRating: widget.trainerRating,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Next',
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      )
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // weekday: 1=Mon, 7=Sun
    final startOffset = firstDay.weekday - 1;
    final today = DateTime.now();

    final cells = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      cells.add(GestureDetector(
        onTap: isPast ? null : () {
          setState(() => _selectedDate = date);
          _loadSlots(date);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? themeColor
                : isToday
                    ? themeColor.withOpacity(0.25)
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : isPast
                        ? context.subtextColor.withOpacity(0.3)
                        : context.textColor,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ));
    }

    // Build rows of 7
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final rowCells = cells.sublist(i, i + 7 > cells.length ? cells.length : i + 7);
      // Pad last row
      while (rowCells.length < 7) {
        rowCells.add(const SizedBox(width: 36, height: 36));
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: rowCells,
        ),
      ));
    }

    return Column(children: rows);
  }

  Widget _buildTimeSlots() {
    if (_loadingTrainerSlots) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(color: themeColor),
      ));
    }
    if (_trainerSlots.isEmpty) {
      return Text('No slots available.', style: TextStyle(color: context.subtextColor));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _trainerSlots.map((slot) {
        final time = slot['slot_time'] as String;
        final price = (slot['price'] as num).toDouble();
        final isBooked = _bookedSlots.contains(time);
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: isBooked
              ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('This slot is already booked.'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ))
              : () => setState(() {
                    _selectedTime = time;
                    _selectedPrice = price;
                  }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? themeColor
                  : isBooked
                      ? (context.isDark ? const Color(0xff2a2a2a) : Colors.grey.shade200)
                      : context.cardBgColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? themeColor
                    : isBooked ? Colors.transparent
                    : context.isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? Colors.black
                        : isBooked ? context.subtextColor.withOpacity(0.35)
                        : context.textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                    decoration: isBooked ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : themeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _monthName(int m) => [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m - 1];
}