import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
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
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 10),
              child: ListView.builder(
                itemCount: notificationSettings.length,
                itemBuilder: (context, index) {
                  String key = notificationSettings.keys.elementAt(index);
                  return Card(
                    color: context.cardBgColor,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        key,
                        style: TextStyle(
                          color: context.textColor,
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
                        inactiveTrackColor: context.isDark
                            ? Colors.grey
                            : Colors.grey.shade300,
                      ),
                    ),
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