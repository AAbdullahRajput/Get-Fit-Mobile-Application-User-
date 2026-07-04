import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class NewfeedCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final String author;
  final String date;

  const NewfeedCard({
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NewsfeedDetailPage(
              id: id,
              title: title,
              description: description,
              category: category,
              imageUrl: imageUrl,
              author: author,
              date: date,
            ),
          ),
        );
      },
      child: Container(
        height: 168,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Image Section
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          cacheWidth: 400,
                          headers: const {
                            'User-Agent':
                                'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
                            'Referer': 'https://breakingmuscle.com/',
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: themeColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) {
                            debugPrint('❌ Image load failed: $imageUrl');
                            debugPrint('❌ Error: $error');
                            return Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: context.isDark ? themeColor : Colors.grey,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: context.isDark ? themeColor : Colors.grey,
                      ),
              ),
            ),
            // Content Section
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xff2f2f2f)
                      : const Color(0xff1A1A1A),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: themeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Title
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Description
                      Flexible(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Author and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '$author • $date',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeColor,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}