import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

class InstructorClassDetailPage extends StatefulWidget {
  final Map<String, dynamic> classData;
  final Map<String, dynamic> instructorData;

  const InstructorClassDetailPage({
    super.key,
    required this.classData,
    required this.instructorData,
  });

  @override
  State<InstructorClassDetailPage> createState() =>
      _InstructorClassDetailPageState();
}

class _InstructorClassDetailPageState
    extends State<InstructorClassDetailPage> {
  List<Map<String, dynamic>> _steps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final classId = widget.classData['id'] as String;
    final steps = await SupabaseService.getInstructorClassSteps(classId);
    if (mounted) {
      setState(() {
        _steps = steps;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.classData;
    final ins = widget.instructorData;
    final title = cls['title'] as String? ?? '';
    final description = cls['description'] as String? ?? '';
    final imageUrl = cls['image_url'] as String? ?? '';
    final durationMin = (cls['duration_minutes'] as num?)?.toInt() ?? 0;
    final level = cls['level'] as String? ?? '';
    final classType = cls['class_type'] as String? ?? '';
    final scheduledTime = cls['scheduled_time'] as String? ?? '';
    final insName = ins['name'] as String? ?? '';
    final insImage = ins['image_url'] as String? ?? '';
    final insSpecialty = ins['specialty'] as String? ?? '';

    final accent = _accent(context);
    final bgColor =
        context.isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final cardColor =
        context.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = context.isDark ? Colors.white : Colors.black87;
    final subColor = context.isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : CustomScrollView(
              slivers: [
                // ── Hero banner ──
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: accent.withOpacity(0.2)),
                              )
                            : Container(color: accent.withOpacity(0.2)),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      // Owned badge
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 13, color: Colors.black),
                              SizedBox(width: 4),
                              Text('Owned',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                _chip(level, Icons.bar_chart),
                                _chip('$durationMin min', Icons.timer),
                                if (classType.isNotEmpty)
                                  _chip(classType, Icons.category),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Instructor row ──
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: insImage.isNotEmpty
                                  ? NetworkImage(insImage)
                                  : null,
                              backgroundColor: accent.withOpacity(0.2),
                              child: insImage.isEmpty
                                  ? Icon(Icons.person, color: accent)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(insName,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    )),
                                Text(insSpecialty,
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 12,
                                    )),
                              ],
                            ),
                            const Spacer(),
                            if (scheduledTime.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 13, color: accent),
                                    const SizedBox(width: 4),
                                    Text(scheduledTime,
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Description ──
                        Text('About this class',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        Text(description,
                            style: TextStyle(
                              color: subColor,
                              fontSize: 14,
                              height: 1.6,
                            )),

                        const SizedBox(height: 28),

                        // ── Video placeholder ──
                        _videoPlaceholder(context, imageUrl, accent),

                        const SizedBox(height: 28),

                        // ── Steps header (informational only, no locking) ──
                        Text('Session Guide',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          '${_steps.length} steps — watch anytime, as many times as you like',
                          style: TextStyle(
                            color: subColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._steps.asMap().entries.map((e) => _stepCard(
                            context,
                            e.key,
                            e.value,
                            accent,
                            cardColor,
                            textColor,
                            subColor)),

                        const SizedBox(height: 24),

                        // ── Owned notice (replaces the old lock/mark-done button) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.all_inclusive,
                                  color: accent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You own this course — access it anytime, no limits.',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, IconData icon) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11)),
          ],
        ),
      );

  Widget _videoPlaceholder(
          BuildContext context, String thumb, Color accent) =>
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
          image: thumb.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(thumb),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.45), BlendMode.darken),
                )
              : null,
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow,
                color: Colors.white, size: 34),
          ),
        ),
      );

  Widget _stepCard(
    BuildContext context,
    int idx,
    Map<String, dynamic> step,
    Color accent,
    Color cardColor,
    Color textColor,
    Color subColor,
  ) {
    final stepNum =
        (step['step_number'] as num?)?.toInt() ?? idx + 1;
    final instruction = step['instruction'] as String? ?? '';
    final tip = step['tip'] as String? ?? '';
    final doTip = step['do_tip'] as String? ?? '';
    final dontTip = step['dont_tip'] as String? ?? '';
    final imageUrl = step['image_url'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: context.isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Step number bubble
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$stepNum',
                            style: TextStyle(
                              color: context.isDark
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(instruction,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          )),
                    ),
                  ],
                ),

                if (tip.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(tip, Icons.lightbulb_outline,
                      Colors.amber, subColor),
                ],
                if (doTip.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(doTip, Icons.check_circle_outline,
                      Colors.green, subColor),
                ],
                if (dontTip.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(dontTip, Icons.cancel_outlined,
                      Colors.red, subColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
          String text, IconData icon, Color iconColor, Color textColor) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  height: 1.4,
                )),
          ),
        ],
      );
}