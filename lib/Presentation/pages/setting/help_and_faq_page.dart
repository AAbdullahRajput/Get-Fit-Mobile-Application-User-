import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_fit/Presentation/pages/setting/assistant_chat_page.dart';
import 'package:get_fit/Utils/constants.dart';

class HelpAndFaqPage extends StatefulWidget {
  
  const HelpAndFaqPage({super.key});

  @override
  State<HelpAndFaqPage> createState() => _HelpAndFaqPageState();
}

class _HelpAndFaqPageState extends State<HelpAndFaqPage> {
  int selectedIndex = 0;
  final List<String> categories = ['FAQ', 'Contact Us'];
  
  // Add FAQ data
  final List<Map<String, String>> faqItems = [
    {
      'question': 'How do I track my workout progress?',
      'answer': 'You can track your progress through the dashboard. It shows your daily activities, completed workouts, and achievement statistics.'
    },
    {
      'question': 'Can I customize my workout plan?',
      'answer': 'Yes, you can customize your workout plan based on your fitness goals, available equipment, and time constraints.'
    },
    {
      'question': 'How do I reset my password?',
      'answer': 'Go to Settings > Password Settings > Click on "Forgot Password" and follow the instructions sent to your email.'
    },
    {
      'question': 'Is my personal data secure?',
      'answer': 'Yes, we use industry-standard encryption to protect your personal information and workout data.'
    },
  ];

  // Add social links data
  final List<Map<String, dynamic>> socialLinks = [
    {
      'title': 'Customer Service',
      'icon': Icons.assistant,
      'link': ''
    },
    {
      'title': 'Instagram',
      'icon': Icons.camera_alt_outlined,
      'link': '@getfit_app'
    },
    {
      'title': 'Facebook',
      'icon': Icons.facebook_outlined,
      'link': 'GetFit Official'
    },
    {
      'title': 'Twitter',
      'icon': Icons.flutter_dash_outlined,
      'link': '@getfit'
    },
    {
      'title': 'Email Support',
      'icon': Icons.email_outlined,
      'link': 'support@getfit.com'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff232323),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Help & FAQs',
          style: TextStyle(
            color: themeColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff232323),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("How can we help you?", 
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 30,
                  width: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    shrinkWrap: true, // Add this
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: selectedIndex == index
                                ? themeColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              categories[index],
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Content based on selected category
            Expanded(
              child: selectedIndex == 0 ? _buildFAQList() : _buildContactList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    return ListView.builder(
      itemCount: faqItems.length,
      itemBuilder: (context, index) {
        return Card(
          color: const Color(0xff414141),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              faqItems[index]['question']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            trailing: Icon(Icons.arrow_drop_down, size: 20, color: themeColor,),
            iconColor: themeColor,
            collapsedIconColor: themeColor,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faqItems[index]['answer']!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactList() {
  return ListView.builder(
    itemCount: socialLinks.length,
    itemBuilder: (context, index) {
      final item = socialLinks[index];
      
      // Special handling for Customer Service
      if (item['title'] == 'Customer Service') {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: themeColor,
            child: Icon(
              item['icon'],
              color: Colors.black,
              size: 20,
            ),
          ),
          title: Text(
            item['title'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: themeColor,
            size: 18,
          ),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => AssistantChatPage()));
          },
        );
      }
      return ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: themeColor,
          child: Icon(
            item['icon'],
            color: Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          item['title'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_drop_down,
          size: 20,
          color: themeColor,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  item['link'],
                  style: const TextStyle(
                    color: themeColor,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.copy,
                    color: themeColor,
                    size: 20,
                  ),
                  onPressed: () {
                    // Add copy to clipboard functionality
                  },
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
}