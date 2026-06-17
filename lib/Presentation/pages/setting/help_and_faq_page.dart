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

  final List<Map<String, String>> faqItems = [
    {
      'question': 'How do I track my workout progress?',
      'answer':
          'You can track your progress through the dashboard. It shows your daily activities, completed workouts, and achievement statistics.'
    },
    {
      'question': 'Can I customize my workout plan?',
      'answer':
          'Yes, you can customize your workout plan based on your fitness goals, available equipment, and time constraints.'
    },
    {
      'question': 'How do I reset my password?',
      'answer':
          'Go to Settings > Password Settings > Click on "Forgot Password" and follow the instructions sent to your email.'
    },
    {
      'question': 'Is my personal data secure?',
      'answer':
          'Yes, we use industry-standard encryption to protect your personal information and workout data.'
    },
  ];

  final List<Map<String, dynamic>> socialLinks = [
    {'title': 'Customer Service', 'icon': Icons.assistant, 'link': ''},
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
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                children: [
                  Text(
                    "How can we help you?",
                    style: TextStyle(color: context.textColor, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 35,
                        width: 210,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: selectedIndex == index
                                      ? themeColor
                                      : context.cardBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: selectedIndex == index
                                      ? null
                                      : Border.all(
                                          color: context.isDark
                                              ? Colors.transparent
                                              : Colors.grey.shade300,
                                        ),
                                ),
                                child: Center(
                                  child: Text(
                                    categories[index],
                                    style: TextStyle(
                                      color: selectedIndex == index
                                          ? Colors.black
                                          : context.textColor,
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
                  Expanded(
                    child: selectedIndex == 0
                        ? _buildFAQList(context)
                        : _buildContactList(context),
                  ),
                ],
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

  Widget _buildFAQList(BuildContext context) {
    return ListView.builder(
      itemCount: faqItems.length,
      itemBuilder: (context, index) {
        return Card(
          color: context.cardBgColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              faqItems[index]['question']!,
              style: TextStyle(
                color: context.textColor,
                fontSize: 16,
              ),
            ),
            trailing:
                Icon(Icons.arrow_drop_down, size: 20, color: context.isDark ? themeColor : Colors.black),
            iconColor: context.isDark ? themeColor : Colors.black,
            collapsedIconColor: context.isDark ? themeColor : Colors.black,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faqItems[index]['answer']!,
                  style: TextStyle(
                    color: context.subtextColor,
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

  Widget _buildContactList(BuildContext context) {
    return ListView.builder(
      itemCount: socialLinks.length,
      itemBuilder: (context, index) {
        final item = socialLinks[index];

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
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: context.isDark ? themeColor : Colors.black,
              size: 18,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AssistantChatPage()),
              );
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
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          trailing: Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: context.isDark ? themeColor : Colors.black,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    item['link'],
                    style: TextStyle(
                      color: context.isDark ? themeColor : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: context.isDark ? themeColor : Colors.black,
                      size: 20,
                    ),
                    onPressed: () {},
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