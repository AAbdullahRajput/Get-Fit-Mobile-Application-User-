import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Add state management for switches
  final Map<String, bool> notificationSettings = {
    'General Notification': false,
    'Sound': false,
    'Don\'t Disturb Mode': false,
    'Vibrate': false,
    'Lock Screen': false,
    'Reminder': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff232323),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Notifications Settings',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: ListView.builder(
          itemCount: notificationSettings.length,
          itemBuilder: (context, index) {
            String key = notificationSettings.keys.elementAt(index);
            return Card(
              color: const Color(0xff414141),
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                trailing: Switch(
                  value: notificationSettings[key]!,
                  onChanged: (bool value) {
                    setState(() {
                      notificationSettings[key] = value;
                    });
                  },
                  activeColor: themeColor,
                  inactiveTrackColor: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}