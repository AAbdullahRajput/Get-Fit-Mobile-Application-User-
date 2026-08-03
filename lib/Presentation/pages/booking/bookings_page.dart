import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:get_fit/Services/notification_service.dart';

Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _bookingsPageSize = 9;
  List<Map<String, dynamic>> _bookings = [];
  final Map<String, bool> _expandedCards = {};
  final Map<String, List<Map<String, dynamic>>> _callSessions = {};
  final Map<String, int> _visibleCallCount = {};
  static const int _callsPageSize = 9;
  final Set<String> _loadingCalls = {};
  bool _pdfGenerating = false;

  DateTime? _nextClearDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _page = 0;
      _hasMore = true;
      _bookings.clear();
    });

    // Actually enforce the 20-day retention — deletes anything past the
    // window from the DB before we compute what date to show in the banner.
    await SupabaseService.clearOldBookings();

    final oldest = await SupabaseService.getOldestBookingDate();
    _nextClearDate = oldest?.add(const Duration(days: 20));

    await _loadPage(0);
    if (mounted) setState(() => _isLoading = false);

    if (_nextClearDate != null) {
      await NotificationService.scheduleBookingClearReminder(_nextClearDate!);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _loadPage(_page + 1);
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _loadPage(int page) async {
    try {
      final bookings = await SupabaseService.getEndedTrainerAppointments(
        page: page,
        pageSize: _bookingsPageSize,
      );
      if (mounted) {
        setState(() {
          _bookings.addAll(bookings);
          _page = page;
          _hasMore = bookings.length == _bookingsPageSize;
        });
      }
    } catch (e) {
      debugPrint('\x1B[31m[BOOKINGS] Load error: $e\x1B[0m');
    }
  }

 Future<void> _exportAllBookingsPdf() async {
    if (_bookings.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No bookings to export yet.')),
        );
      }
      return;
    }

    setState(() => _pdfGenerating = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Get Fit - Booking History',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('${_bookings.length} bookings',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        ),
        build: (ctx) {
          final items = <pw.Widget>[];
          for (final booking in _bookings) {
            items.add(_buildPdfBookingCard(booking));
            items.add(pw.SizedBox(height: 14));
          }
          return items;
        },
      ));

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/getfit_bookings_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'My Get Fit booking history');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfGenerating = false);
    }
  }

  pw.Widget _buildPdfBookingCard(Map<String, dynamic> booking) {
    final trainer = booking['fitness_trainers'] as Map<String, dynamic>? ?? {};
    final date = booking['appointment_date'] as String? ?? '';
    final startTime = booking['start_time'] as String? ?? '';
    final endTime = booking['end_time'] as String? ?? '';
    final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
    final status = booking['status'] as String? ?? 'confirmed';

    final dt = DateTime.tryParse(date);
    String fmtDate = date;
    if (dt != null) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      fmtDate = '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    String fmtTime(String t) {
      if (t.isEmpty) return '';
      final h = int.parse(t.split(':')[0]);
      final m = t.split(':')[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
      return '$h12:$m $period';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(trainer['name'] ?? 'Trainer',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.Text(status,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 8),
        pw.Text(fmtDate, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        pw.Text('${fmtTime(startTime)} → ${fmtTime(endTime)}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Price', style: const pw.TextStyle(fontSize: 11)),
          pw.Text('\$${price.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ]),
      ]),
    );
  }

  Future<void> _toggleExpand(String bookingId) async {
    final isExpanded = _expandedCards[bookingId] ?? false;
    if (!isExpanded && !_callSessions.containsKey(bookingId)) {
      setState(() => _loadingCalls.add(bookingId));
      try {
        final calls = await SupabaseService.getCallSessionsForAppointment(bookingId);
        if (mounted) {
          setState(() {
            _callSessions[bookingId] = calls;
            _visibleCallCount[bookingId] = _callsPageSize;
            _expandedCards[bookingId] = true;
            _loadingCalls.remove(bookingId);
          });
        }
      } catch (e) {
        if (mounted) setState(() => _loadingCalls.remove(bookingId));
      }
    } else {
      final willCollapse = isExpanded;
      setState(() {
        _expandedCards[bookingId] = !isExpanded;
        if (willCollapse) {
          _visibleCallCount[bookingId] = _callsPageSize;
        }
      });
    }
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
              Text('Booking History',
                  style: TextStyle(
                      color: accent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accent))
                : RefreshIndicator(
                    color: themeColor,
                    backgroundColor: context.cardBgColor,
                    onRefresh: _load,
                    child: _bookings.isEmpty
                        ? _buildEmpty(context, Icons.history, 'No booking history')
                        : Stack(
                            children: [
                              if (_nextClearDate != null)
                                Positioned.fill(
                                  child: ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                                    children: [
                                      _buildRetentionBanner(context),
                                      ..._buildBookingsList(context, accent),
                                    ],
                                  ),
                                )
                              else
                                _buildList(context, accent),
                            ],
                          ),
                  ),
          ),
          if (_pdfGenerating)
            Container(
              color: Colors.black54,
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: themeColor),
                const SizedBox(height: 12),
                Text('Generating PDF…', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ])),
            ),
        ]),
      ),
    );
  }

  // ── TRAINER BOOKINGS ─────────────────────────

  Widget _buildRetentionBanner(BuildContext context) {
    final clearDate = _nextClearDate!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColor.withOpacity(context.isDark ? 0.18 : 0.12),
              themeColor.withOpacity(context.isDark ? 0.06 : 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.history_rounded, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Bookings expire after 20 days 💛',
                style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'We keep your recent bookings for quick reference. Your earliest records clear on ${_fmtClearDate(clearDate)}—download a PDF before then so you never lose them.',
            style: TextStyle(color: context.subtextColor, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pdfGenerating ? null : _exportAllBookingsPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.black, size: 16),
              label: const Text('Download as PDF',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtClearDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

 List<Widget> _buildBookingsList(BuildContext context, Color accent) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: _bookings.length + (_hasMore || _loadingMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i < _bookings.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCard(context, _bookings[i], _accent(context)),
              );
            }
            return _loadingMore
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(color: _accent(context))),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadMore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent(context).withOpacity(0.1),
                          side: BorderSide(color: _accent(context)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Load More',
                            style: TextStyle(color: _accent(context), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
          },
        ),
      ),
    ];
  }

  Widget _buildList(BuildContext context, Color accent) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _bookings.length + (_hasMore || _loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i < _bookings.length) {
          return _buildCard(context, _bookings[i], accent);
        }
        return _loadingMore
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: accent),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadMore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent.withOpacity(0.1),
                      side: BorderSide(color: accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Load More',
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
      },
    );
  }

  Widget _buildCard(BuildContext context,
      Map<String, dynamic> booking, Color accent) {
    final bookingId = booking['id'] as String;
    final trainer = booking['fitness_trainers'] as Map<String, dynamic>? ?? {};
    final date = booking['appointment_date'] as String? ?? '';
    final startTime = booking['start_time'] as String? ?? '';
    final endTime = booking['end_time'] as String? ?? '';
final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
    final status = booking['status'] as String? ?? 'confirmed';
    final isExpanded = _expandedCards[bookingId] ?? false;
    final isLoading = _loadingCalls.contains(bookingId);
    final calls = _callSessions[bookingId] ?? [];

    final dt = DateTime.tryParse(date);
    // Compute the effective display status based on date/time AND the
    // stored status (so today's upcoming/past appointments are labelled).
    final now = DateTime.now();
    final startParts = startTime.split(':');
    DateTime? startDateTime;
    if (dt != null && startParts.length == 2) {
      startDateTime = DateTime(
        dt.year, dt.month, dt.day,
        int.tryParse(startParts[0]) ?? 0,
        int.tryParse(startParts[1]) ?? 0,
      );
    }
    final endParts = endTime.split(':');
    DateTime? endDateTime;
    if (dt != null && endParts.length == 2) {
      endDateTime = DateTime(
        dt.year, dt.month, dt.day,
        int.tryParse(endParts[0]) ?? 0,
        int.tryParse(endParts[1]) ?? 0,
      );
    }

    bool isPast = endDateTime != null && endDateTime.isBefore(now);
    bool isUpcoming = startDateTime != null && startDateTime.isAfter(now);

    String displayStatus = status;
    Color statusColor = status == 'cancelled' ? Colors.red : status == 'attended' ? Colors.green : Colors.grey;

    if (status == 'confirmed') {
      if (isPast) {
        displayStatus = 'Missed';
        statusColor = Colors.red;
      } else if (isUpcoming) {
        displayStatus = 'Upcoming';
        statusColor = Colors.blue;
      } else if (startDateTime != null) {
        // Same day, already started (or ongoing time window)
        displayStatus = 'Today';
        statusColor = Colors.orange;
      }
    } else if (status == 'attended') {
      displayStatus = 'Completed';
      statusColor = Colors.green;
    }

    String fmtDate = date;
    if (dt != null) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      fmtDate = '${dt.day} ${months[dt.month - 1]}';
    }

    String fmtTime(String t) {
      if (t.isEmpty) return '';
      final h = int.parse(t.split(':')[0]);
      final m = t.split(':')[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
      return '$h12:$m $period';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipOval(
              child: Container(
                width: 44,
                height: 44,
                color: themeColor.withOpacity(0.2),
                child: (trainer['image_url'] ?? '').toString().isNotEmpty
                    ? Image.network(
                        trainer['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.black, size: 18),
                      )
                    : const Icon(Icons.person, color: Colors.black, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trainer['name'] ?? 'Trainer',
                    style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$fmtDate • ${fmtTime(startTime)} → ${fmtTime(endTime)}',
                    style: TextStyle(color: context.subtextColor, fontSize: 11)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${price.toStringAsFixed(0)}',
                  style: TextStyle(color: themeColor, fontSize: 13, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
child: Text(displayStatus, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ),
        if (isExpanded) ...[
          Divider(height: 1, color: statusColor.withOpacity(0.2)),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: accent)),
            )
          else if (calls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Builder(builder: (_) {
                final visibleCount = _visibleCallCount[bookingId] ?? _callsPageSize;
                final shownCalls = calls.take(visibleCount).toList();
                final hasMore = visibleCount < calls.length;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Call History (${calls.length})',
                      style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...shownCalls.map((call) => _buildCallTile(context, call, accent)),
                  if (hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _visibleCallCount[bookingId] =
                                  visibleCount + _callsPageSize;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accent),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Load More Calls',
                              style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                ]);
              }),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No calls recorded',
                  style: TextStyle(color: context.subtextColor, fontSize: 11, fontStyle: FontStyle.italic)),
            ),
        ],
        GestureDetector(
          onTap: () => _toggleExpand(bookingId),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: statusColor.withOpacity(0.15))),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: accent, size: 18),
              const SizedBox(width: 4),
              Text(isExpanded ? 'Show Less' : 'Show More',
                  style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildCallTile(BuildContext context, Map<String, dynamic> call, Color accent) {
    final status = call['status'] as String? ?? 'unknown';
    final createdAt = call['created_at'] as String? ?? '';
    final duration = (call['duration_seconds'] as num?)?.toInt() ?? 0;
    final initiatedBy = call['initiated_by'] as String? ?? 'trainer';
    final connectedAt = call['connected_at'] as String?;
    final endedBy = call['ended_by'] as String?;

    Color callColor;
    IconData callIcon;
    if (status == 'ended' && duration > 0) {
      callColor = Colors.green;
      callIcon = Icons.call;
    } else if (status == 'missed') {
      callColor = Colors.orange;
      callIcon = Icons.phone_missed;
    } else if (status == 'declined') {
      callColor = Colors.red;
      callIcon = Icons.call_end;
    } else {
      callColor = Colors.grey;
      callIcon = Icons.call;
    }

    final bool trainerCalled = initiatedBy == 'trainer';
    final String directionLabel = trainerCalled ? 'You called' : 'Client called';
    final IconData directionIcon =
        trainerCalled ? Icons.call_made : Icons.call_received;

    String fmtTime(int secs) {
      if (secs == 0) return 'N/A';
      final mins = secs ~/ 60;
      final s = secs % 60;
      return '${mins}m ${s}s';
    }

    String fmtCreatedAt(String iso) {
      try {
        final dt = DateTime.parse(iso);
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      } catch (_) {
        return iso;
      }
    }

    String? fmtConnectedAt(String? iso) {
      if (iso == null || iso.isEmpty) return null;
      try {
        final dt = DateTime.parse(iso);
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      } catch (_) {
        return null;
      }
    }

    String? endedByLabel(String? endedBy) {
      if (endedBy == null || endedBy.isEmpty) return null;
      if (endedBy == 'trainer') return 'Ended by you';
      if (endedBy == 'client') return 'Ended by client';
      return 'Ended by $endedBy';
    }

    final connectedLabel = fmtConnectedAt(connectedAt);
    final endLabel = endedByLabel(endedBy);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: callColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(callIcon, color: callColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(status, style: TextStyle(color: callColor, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Icon(directionIcon, color: context.subtextColor, size: 10),
              const SizedBox(width: 2),
              Text(directionLabel, style: TextStyle(color: context.subtextColor, fontSize: 9)),
            ]),
            const SizedBox(height: 2),
            Text(
              connectedLabel != null
                  ? 'Started ${fmtCreatedAt(createdAt)} • Connected $connectedLabel'
                  : fmtCreatedAt(createdAt),
              style: TextStyle(color: context.subtextColor, fontSize: 9),
            ),
            if (endLabel != null)
              Text(endLabel, style: TextStyle(color: context.subtextColor, fontSize: 9)),
          ]),
        ),
        Text(fmtTime(duration), style: TextStyle(color: context.textColor, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────

  Widget _infoChip(BuildContext context, Color accent,
      IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: accent, size: 12),
      const SizedBox(width: 4),
      Text(label,
          style:
              TextStyle(color: context.subtextColor, fontSize: 11)),
    ]);
  }

  Widget _buildEmpty(
      BuildContext context, IconData icon, String label) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: context.subtextColor, size: 52),
        const SizedBox(height: 12),
        Text(label,
            style: TextStyle(
                color: context.subtextColor, fontSize: 14)),
      ]),
    );
  }

}