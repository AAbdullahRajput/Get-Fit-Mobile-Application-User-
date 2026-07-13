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
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedSlot;
  bool _acknowledgedNoRefund = false;
  final TextEditingController _notesController = TextEditingController();

  late DateTime _todayClean;
  late DateTime _focusedMonth;
  late DateTime _maxMonth; // 2 months ahead cap
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayClean = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month, 1);
    _maxMonth = DateTime(now.year + 1, now.month, 1);
    _loadTemplatesOnly();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final slots =
        await SupabaseService.getTrainerCalendarSlots(widget.trainerId);
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _selectedSlot = null;
      _isLoading = false;
    });
    _tryAutoSelectFirstAvailable();
  }
  Future<void> _loadTemplatesOnly() async {
  setState(() => _isLoading = true);
  final slots =
      await SupabaseService.getTrainerCalendarSlots(widget.trainerId);
  if (!mounted) return;
  setState(() {
    _slots = slots;
    _selectedSlot = null;
    _isLoading = false;
    _selectedDate = _todayClean; // auto-select today by default
    _focusedMonth = DateTime(_todayClean.year, _todayClean.month, 1);
  });
}

Future<void> _loadSlotsForDate(DateTime date) async {
  // Filter slots to only this date
  final dateStr = _fmt(date);
  final slotsForDate = _slots.where((s) => s['slot_date'] == dateStr).toList();
  
  if (slotsForDate.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No slots available on this date')),
    );
  }
}

  void _tryAutoSelectFirstAvailable() {
    if (_slots.isEmpty) return;
    final availableOnly = _slots.where((s) => s['status'] == 'available');
    final dates = availableOnly.isNotEmpty
        ? (availableOnly.map((s) => s['slot_date'] as String).toSet().toList()
          ..sort())
        : (_groupedByDate.keys.toList()..sort());
    if (dates.isEmpty) return;
    final firstDate = DateTime.parse(dates.first);
    setState(() {
      _selectedDate = firstDate;
      _focusedMonth = DateTime(firstDate.year, firstDate.month, 1);
    });
  }

  String _fmtTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
    return '$h12:$m $period';
  }

  Color _getSlotDotColor(List<Map<String, dynamic>> slotsForDate, Color accent) {
  if (slotsForDate.isEmpty) return Colors.transparent;
  final hasAvailable = slotsForDate.any((s) => s['status'] == 'available');
  final hasBooked = slotsForDate.any((s) => s['status'] != 'available');
  return (hasBooked && !hasAvailable) ? Colors.redAccent : accent;
}

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDisplayDate(String dateStr) {
    final d = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _monthName(int m) => [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m - 1];

  Map<String, List<Map<String, dynamic>>> get _groupedByDate {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final slot in _slots) {
      final date = slot['slot_date'] as String;
      map.putIfAbsent(date, () => []).add(slot);
    }
    return map;
  }

  bool get _canGoPrevMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1)
              .isBefore(DateTime(_todayClean.year, _todayClean.month, 1)) ==
          false;

  bool get _canGoNextMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1)
          .isBefore(DateTime(_maxMonth.year, _maxMonth.month + 1, 1));

  void _proceed() {
    if (_selectedSlot == null) return;
    final slot = _selectedSlot!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentPaymentPage(
          trainerId: widget.trainerId,
          trainerName: widget.trainerName,
          trainerType: widget.trainerType,
          date: slot['slot_date'] as String,
          displayDate: _fmtDisplayDate(slot['slot_date'] as String),
          time:
              '${_fmtTime(slot['start_time'] as String)} → ${_fmtTime(slot['end_time'] as String)}',
          notes: _notesController.text.trim(),
          sessionPrice: (slot['price'] as num).toDouble(),
          trainerRating: widget.trainerRating,
          trainerAvatarUrl: widget.trainerAvatarUrl,
          slotId: slot['id'] as String,
          startTime: slot['start_time'] as String,
          endTime: slot['end_time'] as String,
          noRefundAcknowledged: _acknowledgedNoRefund,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(children: [
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
                : RefreshIndicator(
                    color: accent,
                    backgroundColor: context.cardBgColor,
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTrainerCard(context, accent),
                            const SizedBox(height: 20),
                            _buildCalendar(context, accent),
                            const SizedBox(height: 20),
                            if (_selectedDate != null) ...[
                              _buildSlotsSection(context, accent),
                              const SizedBox(height: 20),
                            ],
                            _buildNoRefundNotice(context),
                            const SizedBox(height: 20),
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
                                onPressed:
                                    (_selectedSlot == null || !_acknowledgedNoRefund)
                                        ? null
                                        : _proceed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  disabledBackgroundColor:
                                      Colors.grey.shade700,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30)),
                                ),
                                child: Text(
                                  _selectedSlot == null
                                      ? 'Select a date and time slot'
                                      : !_acknowledgedNoRefund
                                          ? 'Please confirm the no-refund policy above'
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
          ),
        ]),
      ),
    );
  }

  Widget _buildNoRefundNotice(BuildContext context) {
    final slotChosen = _selectedSlot != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(slotChosen ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(slotChosen ? 0.4 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.orange.withOpacity(slotChosen ? 1 : 0.5), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  slotChosen
                      ? 'This session is non-refundable. If you\'re unavailable at your booked time, the session will be marked as missed and the payment will not be refunded.'
                      : 'Select a date and time slot above to review the refund policy.',
                  style: TextStyle(
                    color: (context.isDark ? Colors.orange.shade300 : Colors.orange.shade800)
                        .withOpacity(slotChosen ? 1 : 0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          IgnorePointer(
            ignoring: !slotChosen,
            child: Opacity(
              opacity: slotChosen ? 1 : 0.4,
              child: GestureDetector(
                onTap: () => setState(() => _acknowledgedNoRefund = !_acknowledgedNoRefund),
                child: Row(
                  children: [
                    Checkbox(
                      value: _acknowledgedNoRefund,
                      onChanged: !slotChosen
                          ? null
                          : (v) => setState(() => _acknowledgedNoRefund = v ?? false),
                      activeColor: Colors.orange,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'I understand this booking is non-refundable',
                        style: TextStyle(
                          color: context.isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              Icon(Icons.event_available, color: accent, size: 13),
              const SizedBox(width: 4),
              Text(
                '${_slots.where((s) => s['status'] == 'available').length} slot'
                '${_slots.where((s) => s['status'] == 'available').length == 1 ? '' : 's'} available',
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

  Widget _buildCalendar(BuildContext context, Color accent) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final grouped = _groupedByDate;

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
                onTap: !_canGoPrevMonth
                    ? null
                    : () => setState(() => _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                child: Icon(Icons.chevron_left,
                    color: !_canGoPrevMonth
                        ? context.subtextColor.withOpacity(0.3)
                        : context.textColor),
              ),
              Text(
                '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: TextStyle(
                    color: context.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: !_canGoNextMonth
                    ? null
                    : () => setState(() => _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                child: Icon(Icons.chevron_right,
                    color: !_canGoNextMonth
                        ? context.subtextColor.withOpacity(0.3)
                        : context.textColor),
              ),
            ]),
        const SizedBox(height: 4),
        Text('You can book up to 2 months in advance',
            style: TextStyle(color: context.subtextColor, fontSize: 11)),
        const SizedBox(height: 12),
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
        _buildCalendarGrid(daysInMonth, startOffset, accent, grouped),
      ]),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int startOffset, Color accent,
      Map<String, List<Map<String, dynamic>>> grouped) {
    final cells = <Widget>[];

    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final dateKey = _fmt(date);
      final hasSlots = grouped.containsKey(dateKey);
      final isPast = date.isBefore(_todayClean);
      final beyondLimit = date.isAfter(
          DateTime(_maxMonth.year, _maxMonth.month + 1, 0));
      final isToday = date.year == _todayClean.year &&
          date.month == _todayClean.month &&
          date.day == _todayClean.day;
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;

      final tappable = !isPast && !beyondLimit && hasSlots;

cells.add(GestureDetector(
  onTap: !tappable ? null : () {
    setState(() => _selectedDate = date);
    _loadSlotsForDate(date);
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
                        : !tappable
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
            if (hasSlots && !isSelected)
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _getSlotDotColor(grouped[dateKey] ?? [], accent),
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
    final dateKey = _fmt(_selectedDate!);
    final slots = _groupedByDate[dateKey] ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Available Slots  —  ${_fmtDisplayDate(dateKey)}',
        style: TextStyle(
            color: context.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      if (slots.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text('No slots on this date',
                style: TextStyle(color: context.subtextColor, fontSize: 13)),
          ),
        )
      else
        ...(slots
              ..sort((a, b) => (a['start_time'] as String)
                  .compareTo(b['start_time'] as String)))
            .map((slot) => _buildSlotCard(context, slot, accent)),
    ]);
  }

  Widget _buildSlotCard(
      BuildContext context, Map<String, dynamic> slot, Color accent) {
    final slotId = slot['id'] as String;
    final status = slot['status'] as String? ?? 'available';
    final isBooked = status != 'available';
    final isSelected = _selectedSlot?['id'] == slotId;
    final price = (slot['price'] as num).toDouble();
    final startTime = _fmtTime(slot['start_time'] as String);
    final endTime = _fmtTime(slot['end_time'] as String);

    return GestureDetector(
      onTap: isBooked
          ? null
          : () => setState(() {
                _selectedSlot = isSelected ? null : slot;
                _acknowledgedNoRefund = false; // require re-confirmation on slot change
              }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isBooked
              ? (context.isDark ? Colors.white10 : Colors.black12)
              : isSelected
                  ? themeColor.withOpacity(0.12)
                  : context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBooked
                ? Colors.transparent
                : isSelected
                    ? themeColor
                    : context.isDark
                        ? Colors.white12
                        : Colors.black12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Text(
            '$startTime → $endTime',
            style: TextStyle(
              color: isBooked ? context.subtextColor : context.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration: isBooked ? TextDecoration.lineThrough : null,
            ),
          ),
          const Spacer(),
          if (isBooked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Booked',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )
          else ...[
            Text(
              '\$${price.toStringAsFixed(0)}',
              style: TextStyle(
                color: isSelected ? themeColor : accent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? themeColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? themeColor : context.subtextColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.black, size: 15)
                  : null,
            ),
          ],
        ]),
      ),
    );
  }
}