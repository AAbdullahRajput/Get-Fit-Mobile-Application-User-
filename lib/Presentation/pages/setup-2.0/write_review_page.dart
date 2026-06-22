import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class WriteReviewPage extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final Map<String, dynamic>? existing;
  final VoidCallback? onSubmitted;

  const WriteReviewPage({
    super.key,
    required this.trainerId,
    required this.trainerName,
    this.existing,
    this.onSubmitted,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  late double _rating;
  late TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing != null
        ? (widget.existing!['rating'] as num).toDouble()
        : 4.6;
    _controller = TextEditingController(
        text: widget.existing?['review_text'] ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.submitReview(
        trainerId: widget.trainerId,
        rating: _rating,
        reviewText: text,
      );
      widget.onSubmitted?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to submit review'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 // Top bar
                  Row(
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
                        'Write a Review',
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Rating bar — Figma style
                 // Rating bar — volume style (no thumb)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            final box = context.findRenderObject() as RenderBox;
                            final localX = details.localPosition.dx;
                            final width = box.size.width - 40; // subtract number width
                            final fraction = (localX / width).clamp(0.0, 1.0);
                            final raw = 1.0 + fraction * 4.0;
                            // snap to 0.5 steps
                            final snapped = (raw * 2).round() / 2.0;
                            setState(() => _rating = snapped.clamp(1.0, 5.0));
                          },
                          onTapDown: (details) {
                            final box = context.findRenderObject() as RenderBox;
                            final localX = details.localPosition.dx;
                            final width = box.size.width - 40;
                            final fraction = (localX / width).clamp(0.0, 1.0);
                            final raw = 1.0 + fraction * 4.0;
                            final snapped = (raw * 2).round() / 2.0;
                            setState(() => _rating = snapped.clamp(1.0, 5.0));
                          },
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: context.cardBgColor,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: LayoutBuilder(
                              builder: (ctx, constraints) {
                                final fraction = (_rating - 1.0) / 4.0;
                                return Stack(
                                  children: [
                                    // Yellow fill
                                    Positioned(
                                      left: 0, top: 0, bottom: 0,
                                      width: constraints.maxWidth * fraction,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: themeColor,
                                          borderRadius: BorderRadius.circular(32),
                                        ),
                                      ),
                                    ),
                                    // "Rating" label
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Rating',
                                          style: TextStyle(
                                            color: fraction > 0.25
                                                ? Colors.black
                                                : context.textColor,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Review text field
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: context.cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(color: context.textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Review (Optional)',
                        hintStyle: TextStyle(color: context.subtextColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.black))
                          : Text(
                              widget.existing != null ? 'Update' : 'Send',
                              style: const TextStyle(
                                  color: Colors.black,
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
    );
  }
}