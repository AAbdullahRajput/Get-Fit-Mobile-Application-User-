// appointment_booking_page.dart — full replacement

import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/payment/payment_page.dart';

Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

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
  List<Map<String, dynamic>> _weeklySlots = [];
  bool _isLoading = true;

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedSlot;

  // slotId -> booking count for selected date
  Map<String, int> _slotCounts = {};
  // slotIds that the current user has already booked on selected date
  Set<String> _userBookedSlotIds = {};
  bool _loadingCounts = false;

  final TextEditingController _notesController = TextEditingController();

  // days that have slots (1=Mon..7=Sun)
  Set<int> get _activeDays =>
      _weeklySlots.map((s) => s['day_of_week'] as int).toSet();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final slots = await SupabaseService.getTrainerWeeklySlots(widget.trainerId);
    if (!mounted) return;
    setState(() {
      _weeklySlots = slots;
      _isLoading = false;
    });
    // Auto-select today if today has available slots
    _tryAutoSelectToday();
  }

  void _tryAutoSelectToday() {
    final today = DateTime.now();
    final todayClean = DateTime(today.year, today.month, today.day);
    if (_activeDays.contains(today.weekday)) {
      setState(() {
        _selectedDate = todayClean;
        _focusedMonth = todayClean;
      });
      _loadSlotCounts(todayClean);
    }
  }

  Future<void> _loadSlotCounts(DateTime date) async {
    setState(() {
      _loadingCounts = true;
      _selectedSlot = null;
      _userBookedSlotIds = {};
    });
    final dateStr = _fmt(date);
    final slotsForDay = _slotsForDay(date.weekday);

    final Map<String, int> counts = {};
    final Set<String> userBooked = {};

    await Future.wait(slotsForDay.map((slot) async {
      final slotId = slot['id'] as String;
      final count = await SupabaseService.getSlotBookingCount(
        weeklySlotId: slotId,
        date: dateStr,
      );
      counts[slotId] = count;

      final alreadyBooked = await SupabaseService.hasBookedSlot(
        weeklySlotId: slotId,
        date: dateStr,
      );
      if (alreadyBooked) userBooked.add(slotId);
    }));

    if (!mounted) return;
    setState(() {
      _slotCounts = counts;
      _userBookedSlotIds = userBooked;
      _loadingCounts = false;
    });
  }

  List<Map<String, dynamic>> _slotsForDay(int weekday) =>
      _weeklySlots.where((s) => s['day_of_week'] == weekday).toList();

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
    return '$h12:$m $period';
  }

  String _fmtDisplayDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _monthName(int m) => [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m - 1];

  bool _isPast(DateTime date) {
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// Returns true if this slot's end time has already passed today.
  /// Only relevant when the selected date is today.
  bool _isSlotTimeExpired(Map<String, dynamic> slot) {
    if (_selectedDate == null || !_isToday(_selectedDate!)) return false;
    final now = DateTime.now();
    final parts = (slot['end_time'] as String).split(':');
    final slotEnd = DateTime(
      now.year, now.month, now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return now.isAfter(slotEnd);
  }

  /// Returns true if this slot's start time has already passed today
  /// (but end hasn't — slot is "in progress", still lock it for new bookings).
  bool _isSlotStartPast(Map<String, dynamic> slot) {
    if (_selectedDate == null || !_isToday(_selectedDate!)) return false;
    final now = DateTime.now();
    final parts = (slot['start_time'] as String).split(':');
    final slotStart = DateTime(
      now.year, now.month, now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return now.isAfter(slotStart);
  }

  void _proceed() {
    if (_selectedDate == null || _selectedSlot == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentPaymentPage(
          trainerId: widget.trainerId,
          trainerName: widget.trainerName,
          trainerType: widget.trainerType,
          date: _fmt(_selectedDate!),
          displayDate: _fmtDisplayDate(_selectedDate!),
          time:
              '${_fmtTime(_selectedSlot!['start_time'] as String)} → ${_fmtTime(_selectedSlot!['end_time'] as String)}',
          notes: _notesController.text.trim(),
          sessionPrice: (_selectedSlot!['price'] as num).toDouble(),
          trainerRating: widget.trainerRating,
          trainerAvatarUrl: widget.trainerAvatarUrl,
          weeklySlotId: _selectedSlot!['id'] as String,
          startTime: _selectedSlot!['start_time'] as String,
          endTime: _selectedSlot!['end_time'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
            child: Row(children: [
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
              Text('Book a Session',
                  style: TextStyle(
                      color: accent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ]),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTrainerCard(context, accent),
                          const SizedBox(height: 20),
                          _buildDayChips(context, accent),
                          const SizedBox(height: 20),
                          _buildCalendar(context, accent),
                          const SizedBox(height: 20),
                          if (_selectedDate != null) ...[
                            _buildSlotsSection(context, accent),
                            const SizedBox(height: 20),
                          ],
                          Text('Notes (Optional)',
                              style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: context.cardBgColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextField(
                              controller: _notesController,
                              maxLines: 3,
                              style: TextStyle(
                                  color: context.textColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText:
                                    'Any goals, health concerns, preferences...',
                                hintStyle:
                                    TextStyle(color: context.subtextColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_selectedDate == null ||
                                      _selectedSlot == null)
                                  ? null
                                  : _proceed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                disabledBackgroundColor: Colors.grey.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: Text(
                                _selectedSlot == null
                                    ? 'Select a date and time slot'
                                    : 'Proceed to Payment  •  \$${(_selectedSlot!['price'] as num).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: _selectedSlot == null
                                      ? Colors.grey.shade400
                                      : Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTrainerCard(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: themeColor,
          backgroundImage: widget.trainerAvatarUrl.isNotEmpty
              ? NetworkImage(widget.trainerAvatarUrl)
              : null,
          child: widget.trainerAvatarUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.black, size: 28)
              : null,
        ),
        const SizedBox(width: 14),
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
                style: TextStyle(
                    color: context.subtextColor, fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.calendar_month, color: accent, size: 13),
              const SizedBox(width: 4),
              Text(
                '${_activeDays.length} day${_activeDays.length == 1 ? '' : 's'}/week  •  ${_weeklySlots.length} slots available',
                style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.trainerRating.toStringAsFixed(1),
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildDayChips(BuildContext context, Color accent) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Available Days',
          style: TextStyle(
              color: context.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        children: List.generate(7, (i) {
          final day = i + 1;
          final isActive = _activeDays.contains(day);
          final slotCount =
              _weeklySlots.where((s) => s['day_of_week'] == day).length;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? themeColor.withOpacity(0.15)
                  : context.cardBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? themeColor
                    : context.isDark
                        ? Colors.white12
                        : Colors.black12,
              ),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                dayNames[i],
                style: TextStyle(
                  color: isActive ? themeColor : context.subtextColor,
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 2),
                Text(
                  '$slotCount slot${slotCount == 1 ? '' : 's'}',
                  style: TextStyle(color: accent, fontSize: 10),
                ),
              ],
            ]),
          );
        }),
      ),
    ]);
  }

  Widget _buildCalendar(BuildContext context, Color accent) {
    final firstDay =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _focusedMonth =
                    DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
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
                onTap: () => setState(() => _focusedMonth =
                    DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                child: Icon(Icons.chevron_right, color: context.textColor),
              ),
            ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
              .map((d) => SizedBox(
                    width: 36,
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        _buildCalendarGrid(daysInMonth, startOffset, accent),
      ]),
    );
  }

  Widget _buildCalendarGrid(
      int daysInMonth, int startOffset, Color accent) {
    final cells = <Widget>[];

    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date =
          DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final hasSlots = _activeDays.contains(date.weekday);
      final isPast = _isPast(date);
      final isToday = _isToday(date);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;

      // For today: check if ALL slots for this day have passed
      final bool allSlotsExpiredToday = isToday &&
          hasSlots &&
          _slotsForDay(date.weekday).every(_isSlotStartPast);

      final bool tappable = !isPast && !allSlotsExpiredToday && hasSlots;

      cells.add(GestureDetector(
        onTap: !tappable
            ? null
            : () {
                setState(() => _selectedDate = date);
                _loadSlotCounts(date);
              },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
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
                        : (!tappable && !isToday)
                            ? context.subtextColor.withOpacity(0.3)
                            : allSlotsExpiredToday
                                ? context.subtextColor.withOpacity(0.3)
                                : context.textColor,
                    fontWeight: isSelected || isToday || hasSlots
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (hasSlots && !isPast && !isSelected && !allSlotsExpiredToday)
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ));
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final end = (i + 7) > cells.length ? cells.length : i + 7;
      final rowCells = cells.sublist(i, end);
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

  Widget _buildSlotsSection(BuildContext context, Color accent) {
    final slots = _slotsForDay(_selectedDate!.weekday);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Available Slots  —  ${_fmtDisplayDate(_selectedDate!)}',
        style: TextStyle(
            color: context.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      if (_loadingCounts)
        Center(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(color: accent),
        ))
      else
        ...slots.map((slot) => _buildSlotCard(context, slot, accent)),
    ]);
  }

  Widget _buildSlotCard(
      BuildContext context, Map<String, dynamic> slot, Color accent) {
    final slotId = slot['id'] as String;
    final maxCapacity = slot['max_capacity'] as int;
    final booked = _slotCounts[slotId] ?? 0;
    final remaining = maxCapacity - booked;
    final isFull = remaining <= 0;
    final isSelected = _selectedSlot?['id'] == slotId;
    final price = (slot['price'] as num).toDouble();
    final startTime = _fmtTime(slot['start_time'] as String);
    final endTime = _fmtTime(slot['end_time'] as String);
    final duration = slot['duration_minutes'] as int;

    // ── New state checks ──────────────────────────────────
    final bool isExpired = _isSlotTimeExpired(slot);   // end time passed
    final bool isInProgress = !isExpired && _isSlotStartPast(slot); // started but not ended
    final bool isAlreadyBooked = _userBookedSlotIds.contains(slotId);
    // A slot is locked if full, expired, or in-progress
    final bool isLocked = isFull || isExpired || isInProgress;
    // ─────────────────────────────────────────────────────

    Color capacityColor;
    String capacityLabel;
    if (isFull) {
      capacityColor = Colors.red;
      capacityLabel = 'Full';
    } else if (remaining <= 3) {
      capacityColor = Colors.orange;
      capacityLabel = '$remaining spot${remaining == 1 ? '' : 's'} left';
    } else {
      capacityColor = Colors.green;
      capacityLabel = '$remaining spots left';
    }

    // Overlay color/icon for locked states
    Color? lockedBorderColor;
    String? lockedLabel;
    Color? lockedLabelColor;
    IconData? lockedIcon;

    if (isAlreadyBooked) {
      lockedBorderColor = themeColor.withOpacity(0.6);
      lockedLabel = 'Booked';
      lockedLabelColor = themeColor;
      lockedIcon = Icons.check_circle_outline;
    } else if (isExpired) {
      lockedBorderColor = Colors.grey.withOpacity(0.3);
      lockedLabel = 'Expired';
      lockedLabelColor = Colors.grey;
      lockedIcon = Icons.lock_clock;
    } else if (isInProgress) {
      lockedBorderColor = Colors.orange.withOpacity(0.4);
      lockedLabel = 'In Progress';
      lockedLabelColor = Colors.orange;
      lockedIcon = Icons.timelapse;
    } else if (isFull) {
      lockedBorderColor = Colors.red.withOpacity(0.3);
      lockedLabel = 'Full';
      lockedLabelColor = Colors.red;
      lockedIcon = Icons.event_busy;
    }

    final bool fullyDisabled = isLocked || isAlreadyBooked;

    return GestureDetector(
      onTap: fullyDisabled
          ? () {
              if (isAlreadyBooked) {
                _showAlreadyBookedDialog();
              } else if (isExpired || isInProgress) {
                _showExpiredDialog(isInProgress);
              } else if (isFull) {
                _showFullDialog();
              }
            }
          : () => setState(() => _selectedSlot = slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fullyDisabled
              ? context.cardBgColor.withOpacity(isAlreadyBooked ? 0.85 : 0.5)
              : isSelected
                  ? themeColor.withOpacity(0.12)
                  : context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: fullyDisabled
                ? (lockedBorderColor ?? Colors.grey.withOpacity(0.3))
                : isSelected
                    ? themeColor
                    : context.isDark
                        ? Colors.white12
                        : Colors.black12,
            width: isSelected || isAlreadyBooked ? 2 : 1,
          ),
        ),
        child: Row(children: [
          // Time block
          Opacity(
            opacity: fullyDisabled ? 0.45 : 1.0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeColor
                    : context.isDark
                        ? Colors.white10
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(startTime,
                    style: TextStyle(
                      color: isSelected ? Colors.black : context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    )),
                Text('↓',
                    style: TextStyle(
                        color: isSelected
                            ? Colors.black54
                            : context.subtextColor,
                        fontSize: 11)),
                Text(endTime,
                    style: TextStyle(
                      color: isSelected ? Colors.black : context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    )),
              ]),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Opacity(
              opacity: fullyDisabled ? 0.55 : 1.0,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Icon(Icons.timer_outlined,
                      color: isSelected ? themeColor : accent, size: 13),
                  const SizedBox(width: 4),
                  Text('$duration min',
                      style: TextStyle(
                          color: context.subtextColor, fontSize: 12)),
                ]),
                const SizedBox(height: 6),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Row(children: [
                      Icon(Icons.people_outline,
                          color: capacityColor, size: 13),
                      const SizedBox(width: 4),
                      Text(capacityLabel,
                          style: TextStyle(
                              color: capacityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                    Text('$booked/$maxCapacity',
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 11)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: booked / maxCapacity,
                      minHeight: 5,
                      backgroundColor: context.isDark
                          ? Colors.white12
                          : Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation(capacityColor),
                    ),
                  ),
                ]),
              ]),
            ),
          ),

          const SizedBox(width: 12),

          // Price + status badge
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '\$${price.toStringAsFixed(0)}',
              style: TextStyle(
                color: fullyDisabled
                    ? context.subtextColor
                    : isSelected
                        ? themeColor
                        : accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            if (lockedLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (lockedLabelColor ?? Colors.grey).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color:
                          (lockedLabelColor ?? Colors.grey).withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(lockedIcon,
                      color: lockedLabelColor, size: 10),
                  const SizedBox(width: 3),
                  Text(lockedLabel,
                      style: TextStyle(
                          color: lockedLabelColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ]),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color:
                      isSelected ? themeColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? themeColor
                        : context.subtextColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: Colors.black, size: 16)
                    : null,
              ),
          ]),
        ]),
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────

  void _showFullDialog() {
    showDialog(
      context: context,
      builder: (_) => _buildInfoDialog(
        icon: Icons.event_busy,
        iconColor: Colors.orange,
        title: 'Slot Full',
        message:
            'This time slot is fully booked for the selected date. Please try a different time or another date.',
        buttonColor: Colors.orange,
      ),
    );
  }

  void _showAlreadyBookedDialog() {
    showDialog(
      context: context,
      builder: (_) => _buildInfoDialog(
        icon: Icons.check_circle_outline,
        iconColor: themeColor,
        title: 'Already Booked',
        message:
            'You already have a booking for this slot on the selected date. Check your appointments to manage it.',
        buttonColor: themeColor,
        buttonTextColor: Colors.black,
      ),
    );
  }

  void _showExpiredDialog(bool isInProgress) {
    showDialog(
      context: context,
      builder: (_) => _buildInfoDialog(
        icon: isInProgress ? Icons.timelapse : Icons.lock_clock,
        iconColor: isInProgress ? Colors.orange : Colors.grey,
        title: isInProgress ? 'Session In Progress' : 'Slot Expired',
        message: isInProgress
            ? 'This session has already started and cannot be booked. Please select an upcoming slot.'
            : 'This time slot has already passed for today. Please select a future slot or another date.',
        buttonColor: isInProgress ? Colors.orange : Colors.grey,
      ),
    );
  }

  Widget _buildInfoDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required Color buttonColor,
    Color buttonTextColor = Colors.white,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(children: [
        Icon(icon, color: iconColor, size: 48),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ]),
      content: Text(message,
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('OK',
              style: TextStyle(
                  color: buttonTextColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}