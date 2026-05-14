import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_fit/Presentation/pages/setting/app_settings_page.dart';
import 'package:get_fit/Presentation/pages/setting/favorites_page.dart';
import 'package:get_fit/Presentation/pages/setting/help_and_faq_page.dart';
import 'package:get_fit/Presentation/pages/setting/privacy_policy_page.dart';
import 'package:get_fit/Presentation/pages/setting/profile_page.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/auth/login_page.dart'; // Add this

class SettingHomePage extends StatelessWidget {
  final List<Map<String, dynamic>> settingsItems = const [
    {
      'title': 'Profile',
      'icon': Icons.person,
    },
    {
      'title': 'Favourite',
      'icon': Icons.star,
    },
    {
      'title': 'Privacy Policy',
      'icon': Icons.lock,
    },
    {
      'title': 'Settings',
      'icon': Icons.settings,
    },
    {
      'title': 'Help',
      'icon': Icons.help,
    },
    {
      'title': 'Logout',
      'icon': Icons.logout,
    },
  ];

  const SettingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff232323),
      body: Stack(
        children: [
          Container(
            height: 337,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: themeColor,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
              ],
            ),
          ),
          const SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    CircleAvatar(
                        radius: 65,
                        backgroundColor: Color(0xff232323),
                        child:
                            Icon(Icons.person, size: 100, color: Colors.white)),
                    SizedBox(height: 20),
                    Text(
                      'Name Surname',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "email@gmail.com",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 295,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xff414141),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              "75 kg",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Weight",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        VerticalDivider(
                          color: Colors.white,
                          thickness: 2,
                        ),
                        Column(
                          children: [
                            Text(
                              "28",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Years Old",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        VerticalDivider(
                          color: Colors.white,
                          thickness: 2,
                        ),
                        Column(
                          children: [
                            Text(
                              "180 cm",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Height",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )),
            ),
          ),
          Positioned(
            top: 350,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                child: SizedBox(
                  height: 380,
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
                            case 'Profile':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(),
                                ),
                              );
                              break;
                  
                            case 'Favourite':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FavoritesPage(),
                                ),
                              );
                              break;
                  
                            case 'Privacy Policy':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PrivacyPolicyPage(),
                                ),
                              );
                              break;
                  
                            case 'Settings':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppSettingsPage(),
                                ),
                              );
                              break;
                  
                            case 'Help':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const HelpAndFaqPage(),
                                ),
                              );
                              break;
                  
                            case 'Logout':
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: const Color(0xff232323),
                                    title: const Text('Logout',
                                        style: TextStyle(color: Colors.white)),
                                    content: const Text(
                                      'Are you sure you want to logout?',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel',
                                            style: TextStyle(color: Colors.white70)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Clear user data/preferences here
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const LoginPage(),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: const Text('Logout',
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
