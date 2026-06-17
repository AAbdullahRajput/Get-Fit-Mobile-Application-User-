import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setting/notifications_page.dart';
import 'package:get_fit/Presentation/pages/setting/password_settings.dart';
import 'package:get_fit/Utils/constants.dart';

class AppSettingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> settingsItems = const [
    {
      'title': 'Notification Settings',
      'icon': Icons.notifications,
    },
    {
      'title': 'Password Settings',
      'icon': Icons.lock,
    },
    {
      'title': 'Delete Account',
      'icon': Icons.delete,
    },
  ];
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 60, 0, 10),
              child: ListView.builder(
                itemCount: settingsItems.length,
                itemBuilder: (context, index) {
                  final item = settingsItems[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: themeColor,
                      child: Icon(
                        item['icon'],
                        color: Colors.black,
                        size: 24,
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
                      switch (item['title']) {
                        case 'Notification Settings':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationsPage(),
                            ),
                          );
                          break;

                        case 'Password Settings':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PasswordSettings(),
                            ),
                          );
                          break;

                        case 'Delete Account':
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: context.bgColor,
                                title: Text(
                                  'Delete Account',
                                  style: TextStyle(color: context.textColor),
                                ),
                                content: Text(
                                  'DELETE ACC LOGIC HERE...',
                                  style:
                                      TextStyle(color: context.subtextColor),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                    'Close',
                                    style: TextStyle(color: context.isDark ? themeColor : Colors.black),
                                  ),
                                  ),
                                ],
                              );
                            },
                          );
                          break;
                      }
                    },
                  );
                },
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