import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/widgets/newsfeed_card.dart';
import 'package:get_fit/Utils/constants.dart';

class NewsfeedDetailPage extends StatelessWidget {
  const NewsfeedDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(Icons.image_outlined,
                            size: 100, color: context.subtextColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Newsfeed Title',
                      style: TextStyle(
                          fontSize: 20,
                          color: context.textColor,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This is the detail of the newsfeed post. Here you can add more information about the post. You can also include images, videos, or any other content that is relevant to the newsfeed. Feel free to customize this section as needed.',
                      style: TextStyle(
                          fontSize: 15, color: context.subtextColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Other Feeds',
                      style: TextStyle(
                          fontSize: 20,
                          color: context.textColor,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: 3,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) => const NewfeedCard(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Back button overlay
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}