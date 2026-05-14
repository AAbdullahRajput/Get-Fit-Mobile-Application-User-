import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/widgets/newsfeed_card.dart';
import 'package:get_fit/Utils/constants.dart';

class NewsfeedDetailPage extends StatelessWidget {
  const NewsfeedDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Newsfeed Detail Page',
            style: TextStyle(
                fontSize: 24, color: themeColor, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff232323),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xff232323),
      body: SingleChildScrollView( // <-- Make the page scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.image_outlined, size: 100, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Newsfeed Title',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'This is the detail of the newsfeed post. Here you can add more information about the post. You can also include images, videos, or any other content that is relevant to the newsfeed. Feel free to customize this section as needed. ',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              const Text(
                'Other Feeds',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: 3,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => NewfeedCard(), // <-- Fix typo here
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
