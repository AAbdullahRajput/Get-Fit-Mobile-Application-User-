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
      backgroundColor: const Color(0xff232323),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Settings',
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
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Expanded(
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
                                            backgroundColor: const Color(0xff232323),
                                            title: const Text('Delete Acount',
                                                style: TextStyle(color: Colors.white)),
                                            content: const Text(
                                              'DELETE ACC LOGIC HERE...',
                                              style: TextStyle(color: Colors.white70),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Close',
                                                    style: TextStyle(color: themeColor)),
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
          ],
        ),
      ),
    );
  }
}