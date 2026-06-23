import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_payment_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaBookingPage extends StatefulWidget {
  final Map<String, dynamic> instructor;

  const YogaBookingPage({super.key, required this.instructor});

  @override
  State<YogaBookingPage> createState() => _YogaBookingPageState();
}

class _YogaBookingPageState extends State<YogaBookingPage> {
  DateTime? _selectedStartDate;
  int _numSessions = 4;
  final TextEditingController _notesController = TextEditingController();
  bool _isChecking = false;
  List<Map<String, dynamic>> _existingBookings = [];
  bool _loadingBookings = true;

  static const int _minSessions = 1;
  static const int _maxSessions = 20;

  @override
  void initState() {
    super.initState();
    _loadExistingBookings();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingBookings() async {
    setState(() => _loadingBookings = true);
    final bookings = await SupabaseService.getMyYogaBookingsForInstructor(
        widget.instructor['id']);
    if (mounted) {
      setState(() {
        _existingBookings = bookings;
        _loadingBookings = false;
      });
    }
  }

  bool _isDateAlreadyBooked(DateTime date) {
    final dateStr = date.toIso8601String().substring(0, 10);
    return _existingBookings.any((b) => b['start_date'] == dateStr);
  }

  double get _sessionPrice =>
      (widget.instructor['session_price'] as num?)?.toDouble() ?? 30.0;

  double get _totalPrice => _sessionPrice * _numSessions;

  DateTime? get _estimatedEndDate {
    if (_selectedStartDate == null) return null;
    final sessionsPerWeek =
        (widget.instructor['sessions_per_week'] as num?)?.toInt() ?? 3;
    final weeks = (_numSessions / sessionsPerWeek).ceil();
    return _selectedStartDate!.add(Duration(days: weeks * 7));
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _showInfoDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String buttonText = 'OK',
    Color buttonColor = themeColor,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(icon, color: iconColor, size: 48),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(buttonText,
                style: TextStyle(
                    color: buttonColor == themeColor
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: themeColor,
              onPrimary: Colors.black,
              surface: const Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF2C2C2C),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (_isDateAlreadyBooked(picked)) {
        _showInfoDialog(
          icon: Icons.event_busy,
          iconColor: Colors.orangeAccent,
          title: 'Already Booked',
          message:
              'You already have a session booked starting on ${_formatDate(picked)} with this instructor. Please choose a different date.',
          buttonText: 'Choose Another',
          buttonColor: Colors.orangeAccent,
        );
        return;
      }
      setState(() => _selectedStartDate = picked);
    }
  }

  Future<void> _proceedToPayment() async {
    if (_selectedStartDate == null) return;
    setState(() => _isChecking = true);

    try {
      final dateStr = _selectedStartDate!.toIso8601String().substring(0, 10);
      final alreadyBooked = await SupabaseService.hasExistingYogaBooking(
        instructorId: widget.instructor['id'],
        startDate: dateStr,
      );

      if (!mounted) return;

      if (alreadyBooked) {
        setState(() => _isChecking = false);
        _showInfoDialog(
          icon: Icons.event_busy,
          iconColor: Colors.orangeAccent,
          title: 'Already Booked',
          message:
              'You already have a booking with this instructor on ${_formatDate(_selectedStartDate!)}. Please select a different start date.',
          buttonText: 'OK',
          buttonColor: Colors.orangeAccent,
        );
        return;
      }

      final isActive = widget.instructor['is_active'] == true;
      if (!isActive) {
        setState(() => _isChecking = false);
        _showInfoDialog(
          icon: Icons.person_off_outlined,
          iconColor: Colors.redAccent,
          title: 'Instructor Unavailable',
          message:
              'This instructor is currently not accepting new bookings. Please try another instructor.',
          buttonText: 'Go Back',
          buttonColor: Colors.redAccent,
        );
        return;
      }

      setState(() => _isChecking = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YogaPaymentPage(
            instructor: widget.instructor,
            startDate: dateStr,
            displayDate: _formatDate(_selectedStartDate!),
            numSessions: _numSessions,
            totalPrice: _totalPrice,
            notes: _notesController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isChecking = false);
      _showInfoDialog(
        icon: Icons.wifi_off_outlined,
        iconColor: Colors.redAccent,
        title: 'Connection Error',
        message: 'Failed to verify booking availability. Please check your connection and try again.',
        buttonText: 'OK',
        buttonColor: Colors.redAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructor = widget.instructor;
    final sessionsPerWeek =
        (instructor['sessions_per_week'] as num?)?.toInt() ?? 3;
    final isActive = instructor['is_active'] == true;

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
                  Text(
                    'Book a Session',
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
                    // Instructor summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: themeColor,
                            backgroundImage:
                                (instructor['image_url'] ?? '').isNotEmpty
                                    ? NetworkImage(instructor['image_url'])
                                    : null,
                            child: (instructor['image_url'] ?? '').isEmpty
                                ? const Icon(Icons.self_improvement,
                                    color: Colors.black, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(instructor['name'] ?? '',
                                    style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                                Text(instructor['specialty'] ?? '',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  '$sessionsPerWeek sessions/week  •  ${instructor['level'] ?? ''}',
                                  style: const TextStyle(
                                      color: themeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          // Active status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isActive
                                      ? Colors.green.withOpacity(0.4)
                                      : Colors.red.withOpacity(0.4)),
                            ),
                            child: Text(
                              isActive ? 'Available' : 'Unavailable',
                              style: TextStyle(
                                  color:
                                      isActive ? Colors.green : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Unavailable warning banner
                    if (!isActive)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.redAccent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This instructor is currently not accepting bookings.',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Existing bookings info
                    if (!_loadingBookings && _existingBookings.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: themeColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: themeColor, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Your existing bookings (${_existingBookings.length})',
                                  style: const TextStyle(
                                      color: themeColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._existingBookings.map((b) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          color: themeColor, size: 6),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${b['start_date']}  •  ${b['num_sessions']} sessions  •  ${b['status']}',
                                        style: TextStyle(
                                            color: context.subtextColor,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),

                    // Start date
                    Text('Start Date',
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickStartDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: context.cardBgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedStartDate != null
                                ? themeColor
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: _selectedStartDate != null
                                    ? themeColor
                                    : context.subtextColor,
                                size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedStartDate != null
                                  ? _formatDate(_selectedStartDate!)
                                  : 'Select a start date',
                              style: TextStyle(
                                color: _selectedStartDate != null
                                    ? context.textColor
                                    : context.subtextColor,
                                fontSize: 15,
                                fontWeight: _selectedStartDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right,
                                color: context.subtextColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Number of sessions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Number of Sessions',
                            style: TextStyle(
                                color: context.textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        Text('$_numSessions sessions',
                            style: const TextStyle(
                                color: themeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _numSessions > _minSessions
                                ? () => setState(() => _numSessions--)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _numSessions > _minSessions
                                    ? themeColor
                                    : Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.remove,
                                  color: _numSessions > _minSessions
                                      ? Colors.black
                                      : Colors.grey,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: themeColor,
                                inactiveTrackColor:
                                    Colors.grey.withOpacity(0.3),
                                thumbColor: themeColor,
                                overlayColor: themeColor.withOpacity(0.2),
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 10),
                              ),
                              child: Slider(
                                value: _numSessions.toDouble(),
                                min: _minSessions.toDouble(),
                                max: _maxSessions.toDouble(),
                                divisions: _maxSessions - _minSessions,
                                onChanged: (val) =>
                                    setState(() => _numSessions = val.toInt()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _numSessions < _maxSessions
                                ? () => setState(() => _numSessions++)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _numSessions < _maxSessions
                                    ? themeColor
                                    : Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.add,
                                  color: _numSessions < _maxSessions
                                      ? Colors.black
                                      : Colors.grey,
                                  size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Min $_minSessions',
                            style: TextStyle(
                                color: context.subtextColor, fontSize: 11)),
                        Text('Max $_maxSessions',
                            style: TextStyle(
                                color: context.subtextColor, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Session summary
                    if (_selectedStartDate != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: themeColor.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Session Summary',
                                style: TextStyle(
                                    color: themeColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _summaryRow(Icons.play_circle_outline, 'Starts',
                                _formatDate(_selectedStartDate!)),
                            const SizedBox(height: 6),
                            _summaryRow(
                                Icons.flag_outlined,
                                'Est. completion',
                                _estimatedEndDate != null
                                    ? _formatDate(_estimatedEndDate!)
                                    : '-'),
                            const SizedBox(height: 6),
                            _summaryRow(Icons.repeat, 'Frequency',
                                '$sessionsPerWeek sessions/week'),
                            const SizedBox(height: 6),
                            _summaryRow(Icons.self_improvement,
                                'Total sessions', '$_numSessions sessions'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Notes
                    Text('Notes (Optional)',
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style:
                            TextStyle(color: context.textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Any goals, health concerns, or preferences...',
                          hintStyle:
                              TextStyle(color: context.subtextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Price summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _priceRow(context, 'Price per session',
                              '\$${_sessionPrice.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _priceRow(
                              context, 'Sessions', '$_numSessions'),
                          Divider(
                              color: context.isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              height: 20),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total',
                                  style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                '\$${_totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: themeColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Proceed button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedStartDate == null ||
                                _isChecking ||
                                !isActive)
                            ? null
                            : _proceedToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          disabledBackgroundColor: Colors.grey.shade700,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black))
                            : Text(
                                !isActive
                                    ? 'Instructor Unavailable'
                                    : _selectedStartDate == null
                                        ? 'Select a Start Date First'
                                        : 'Proceed to Payment',
                                style: TextStyle(
                                    color: (_selectedStartDate == null ||
                                            !isActive)
                                        ? Colors.grey.shade400
                                        : Colors.black,
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

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: themeColor, size: 15),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _priceRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(color: context.subtextColor, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: context.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}