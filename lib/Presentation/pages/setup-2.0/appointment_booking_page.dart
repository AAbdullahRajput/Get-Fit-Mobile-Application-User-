import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/payment_page.dart';
class AppointmentBookingPage extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final String trainerType;

  const AppointmentBookingPage({
    super.key,
    required this.trainerId,
    required this.trainerName,
    this.trainerType = '',
  });

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  List<String> _bookedSlots = [];
  bool _loadingSlots = false;
  bool _isBooking = false;
  final _notesController = TextEditingController();

  // Generate 30-min slots from 9 AM to 6 PM
  final List<String> _allSlots = List.generate(18, (i) {
    final totalMinutes = 9 * 60 + i * 30;
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : h == 0 ? 12 : h;
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  });

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

  Future<void> _book() async {
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
    setState(() => _isBooking = true);
    try {
      await SupabaseService.bookAppointment(
        trainerId: widget.trainerId,
        date: _dateToStr(_selectedDate!),
        time: _selectedTime!,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('unique') || e.toString().contains('duplicate')
          ? 'This slot was just booked by someone else. Please pick another.'
          : 'Failed to book. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      // Refresh slots in case someone just booked
      if (_selectedDate != null) _loadSlots(_selectedDate!);
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
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Book Appointment',
                      style: TextStyle(color: themeColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('with ${widget.trainerName}',
                      style: TextStyle(color: context.subtextColor, fontSize: 15)),
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

                  // Time slots
                  if (_selectedDate != null) ...[
                    Text('Available Slots',
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _loadingSlots
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(color: themeColor),
                            ))
                        : _buildTimeSlots(),
                    const SizedBox(height: 20),
                  ],

                  // Notes
                  Text('Notes (optional)',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(color: context.textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Any specific goals, injuries, or requests...',
                        hintStyle: TextStyle(color: context.subtextColor, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

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
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allSlots.length,
        itemBuilder: (context, index) {
          final slot = _allSlots[index];
          final isBooked = _bookedSlots.contains(slot);
          final isSelected = _selectedTime == slot;
          return GestureDetector(
            onTap: isBooked
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('This slot is already booked.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                : () => setState(() => _selectedTime = slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeColor
                    : isBooked
                        ? (context.isDark ? const Color(0xff2a2a2a) : Colors.grey.shade200)
                        : context.cardBgColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? themeColor
                      : isBooked
                          ? Colors.transparent
                          : context.isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                slot,
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : isBooked
                          ? context.subtextColor.withOpacity(0.35)
                          : context.textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  decoration: isBooked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _monthName(int m) => [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m - 1];
}