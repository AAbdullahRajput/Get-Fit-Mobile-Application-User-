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
  List<Map<String, dynamic>> _sessions = [];
  final Set<String> _selectedSessionIds = {};
  final Set<String> _alreadyBookedIds = {};
  bool _isLoading = true;
  bool _isChecking = false;
  final TextEditingController _notesController = TextEditingController();

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
    final instructorId = widget.instructor['id'] as String;
    final sessions = await SupabaseService.getInstructorSessions(instructorId);

    // check which ones already booked
    final Set<String> booked = {};
    for (final s in sessions) {
      final already = await SupabaseService.hasBookedSession(s['id'] as String);
      if (already) booked.add(s['id'] as String);
    }

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _alreadyBookedIds.addAll(booked);
        _isLoading = false;
      });
    }
  }

  double get _sessionPrice =>
      (widget.instructor['session_price'] as num?)?.toDouble() ?? 36.0;

  double get _totalPrice => _sessionPrice * _selectedSessionIds.length;

  int get _availableCount =>
      _sessions.where((s) => !_alreadyBookedIds.contains(s['id'])).length;

  String _formatDate(String dateStr) {
    final dt = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _dayName(String dateStr) {
    final dt = DateTime.parse(dateStr);
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return days[dt.weekday - 1];
  }

  bool _isExpired(String dateStr) {
    final dt = DateTime.parse(dateStr);
    final today = DateTime.now();
    return dt.isBefore(DateTime(today.year, today.month, today.day));
  }

  Future<void> _proceed() async {
    if (_selectedSessionIds.isEmpty) return;
    setState(() => _isChecking = true);
    try {
      // re-verify none already booked
      for (final id in _selectedSessionIds) {
        if (await SupabaseService.hasBookedSession(id)) {
          if (!mounted) return;
          setState(() => _isChecking = false);
          _showDialog(
            icon: Icons.event_busy,
            iconColor: Colors.orange,
            title: 'Already Booked',
            message: 'One of your selected sessions is already booked. Please deselect it.',
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isChecking = false);

      final selectedSessions = _sessions
          .where((s) => _selectedSessionIds.contains(s['id'] as String))
          .toList()
        ..sort((a, b) => (a['session_start'] as String)
            .compareTo(b['session_start'] as String));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YogaPaymentPage(
            instructor: widget.instructor,
            startDate: selectedSessions.first['session_start'] as String,
            displayDate: _formatDate(selectedSessions.first['session_start'] as String),
            numSessions: _selectedSessionIds.length,
            totalPrice: _totalPrice,
            notes: _notesController.text.trim(),
            selectedSessionIds: _selectedSessionIds.toList(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(children: [
          Icon(icon, color: iconColor, size: 48),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('OK',
                style: TextStyle(
                    color: iconColor == themeColor ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructor = widget.instructor;
    final isActive = instructor['is_active'] == true;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
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
                Text('Book Sessions',
                    style: TextStyle(
                        color: themeColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ]),
            ),

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: themeColor))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Instructor card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.cardBgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 28,
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
                                      '\$${_sessionPrice.toStringAsFixed(2)} per session  •  ${_sessions.length} total sessions',
                                      style: const TextStyle(
                                          color: themeColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 20),

                          // Sessions header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Available Sessions',
                                  style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_selectedSessionIds.length} selected',
                                  style: const TextStyle(
                                      color: themeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to select sessions you want to book. Max: $_availableCount available.',
                            style: TextStyle(
                                color: context.subtextColor, fontSize: 12),
                          ),
                          const SizedBox(height: 14),

                          // Session cards
                          if (_sessions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: context.cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(children: [
                                Icon(Icons.event_busy,
                                    color: context.subtextColor, size: 40),
                                const SizedBox(height: 12),
                                Text('No sessions available',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 14)),
                              ]),
                            )
                          else
                            ..._sessions.map((session) {
                              final id = session['id'] as String;
                              final isBooked = _alreadyBookedIds.contains(id);
                              final isSelected = _selectedSessionIds.contains(id);
                              final expired = _isExpired(
                                  session['session_end'] as String? ??
                                      session['session_start'] as String);

                              return GestureDetector(
                                onTap: (isBooked || expired)
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedSessionIds.remove(id);
                                          } else {
                                            _selectedSessionIds.add(id);
                                          }
                                        });
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isBooked
                                        ? themeColor.withOpacity(0.08)
                                        : expired
                                            ? Colors.grey.withOpacity(0.08)
                                            : isSelected
                                                ? themeColor.withOpacity(0.12)
                                                : context.cardBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isBooked
                                          ? themeColor.withOpacity(0.5)
                                          : expired
                                              ? Colors.grey.withOpacity(0.3)
                                              : isSelected
                                                  ? themeColor
                                                  : Colors.transparent,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(children: [
                                    // Day badge
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: isBooked
                                            ? themeColor
                                            : expired
                                                ? Colors.grey
                                                : isSelected
                                                    ? themeColor
                                                    : context.isDark
                                                        ? Colors.white12
                                                        : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _dayName(session['session_start']
                                                as String),
                                            style: TextStyle(
                                              color: (isBooked ||
                                                      isSelected ||
                                                      expired)
                                                  ? Colors.black
                                                  : context.subtextColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            DateTime.parse(
                                                    session['session_start']
                                                        as String)
                                                .day
                                                .toString(),
                                            style: TextStyle(
                                              color: (isBooked ||
                                                      isSelected ||
                                                      expired)
                                                  ? Colors.black
                                                  : context.textColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session['title'] as String? ?? '',
                                            style: TextStyle(
                                              color: context.textColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_formatDate(session['session_start'] as String)}  →  ${_formatDate(session['session_end'] as String)}',
                                            style: TextStyle(
                                              color: context.subtextColor,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(children: [
                                            Icon(Icons.class_outlined,
                                                size: 12,
                                                color: context.subtextColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${session['total_classes']} classes',
                                              style: TextStyle(
                                                  color: context.subtextColor,
                                                  fontSize: 11),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),

                                    // Status icon
                                    if (isBooked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: themeColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text('Booked',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      )
                                    else if (expired)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text('Expired',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      )
                                    else
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? themeColor
                                              : Colors.transparent,
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
                                ),
                              );
                            }).toList(),

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
                              style: TextStyle(
                                  color: context.textColor, fontSize: 14),
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
                          const SizedBox(height: 20),

                          // Price summary
                          if (_selectedSessionIds.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.cardBgColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(children: [
                                _priceRow(context, 'Price per session',
                                    '\$${_sessionPrice.toStringAsFixed(2)}'),
                                const SizedBox(height: 8),
                                _priceRow(context, 'Sessions selected',
                                    '${_selectedSessionIds.length}'),
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
                              ]),
                            ),

                          const SizedBox(height: 28),

                          // Proceed button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_selectedSessionIds.isEmpty ||
                                      _isChecking ||
                                      !isActive)
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
                              child: _isChecking
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black))
                                  : Text(
                                      _selectedSessionIds.isEmpty
                                          ? 'Select at least one session'
                                          : 'Proceed to Payment  •  \$${_totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: _selectedSessionIds.isEmpty
                                              ? Colors.grey.shade400
                                              : Colors.black,
                                          fontSize: 15,
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

  Widget _priceRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: context.subtextColor, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: context.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}