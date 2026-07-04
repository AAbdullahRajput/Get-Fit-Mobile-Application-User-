import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class NewsfeedDetailPage extends StatefulWidget {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final String author;
  final String date;

  const NewsfeedDetailPage({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.author,
    required this.date,
  });

  @override
  State<NewsfeedDetailPage> createState() => _NewsfeedDetailPageState();
}

class _NewsfeedDetailPageState extends State<NewsfeedDetailPage> {
  List<Map<String, dynamic>> _relatedItems = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    final items = await SupabaseService.getNewsfeedItems(category: widget.category);
    final filtered = items.where((i) => i['id']?.toString() != widget.id).take(4).toList();
    if (mounted) {
      setState(() {
        _relatedItems = filtered;
        _isLoadingRelated = false;
      });
    }
  }

  void _openRelated(Map<String, dynamic> item) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NewsfeedDetailPage(
          id: item['id']?.toString() ?? '',
          title: item['title'] as String? ?? '',
          description: item['description'] as String? ?? '',
          category: item['category'] as String? ?? '',
          imageUrl: item['image_url'] as String?,
          author: item['author'] as String? ?? item['source_name'] as String? ?? '',
          date: _formatDate(item['published_at'] as String?),
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header — back button + category title, no overlap
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
                  const SizedBox(width: 12),
                  Text(
                    '${widget.category} News',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 24,
                        color: context.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Author and Date
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: context.subtextColor),
                        const SizedBox(width: 4),
                        Text(
                          widget.author,
                          style: TextStyle(fontSize: 12, color: context.subtextColor),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today_outlined, size: 14, color: context.subtextColor),
                        const SizedBox(width: 4),
                        Text(
                          widget.date,
                          style: TextStyle(fontSize: 12, color: context.subtextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Image
                    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: context.cardBgColor,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(color: themeColor),
                              );
                            },
                            errorBuilder: (context, error, stack) => Center(
                              child: Icon(Icons.image_outlined, size: 64, color: context.subtextColor),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Content
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About this post',
                            style: TextStyle(
                              fontSize: 16,
                              color: context.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.description,
                            style: TextStyle(fontSize: 15, color: context.subtextColor, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Related Posts Section — real data now
                    if (_isLoadingRelated)
                      _buildRelatedSkeleton(context)
                    else if (_relatedItems.isNotEmpty) ...[
                      Text(
                        'More in ${widget.category}',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._relatedItems.map((item) => _relatedFeedItem(context, item)),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _relatedFeedItem(BuildContext context, Map<String, dynamic> item) {
    final imageUrl = item['image_url'] as String? ?? '';
    return GestureDetector(
      onTap: () => _openRelated(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _relatedImagePlaceholder(context),
                    )
                  : _relatedImagePlaceholder(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String? ?? '',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] as String? ?? '',
                    style: TextStyle(color: context.subtextColor, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, size: 14, color: context.subtextColor),
          ],
        ),
      ),
    );
  }

  Widget _relatedImagePlaceholder(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: context.isDark ? Colors.grey[800] : Colors.grey[200],
      child: Icon(Icons.image_outlined, color: context.subtextColor, size: 24),
    );
  }

  Widget _buildRelatedSkeleton(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          height: 84,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xff2c2c2c) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}