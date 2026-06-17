import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.bgColor,
      child: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                // Top yellow header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 40,
                  ),
                  decoration: const BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: context.bgColor,
                        child: Icon(Icons.person,
                            size: 80, color: context.textColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Name Surname',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "email@gmail.com",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Space for stats box overlap
                SizedBox(height: MediaQuery.of(context).padding.top + 60),

                // Form fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ...formFields.map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.cardBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                style:
                                    TextStyle(color: context.textColor),
                                decoration: InputDecoration(
                                  labelText: field['label'],
                                  labelStyle: TextStyle(
                                      color: context.subtextColor),
                                  hintText: field['hint'],
                                  hintStyle: TextStyle(
                                      color: context.subtextColor),
                                  prefixIcon: Icon(
                                    field['icon'],
                                    color: context.subtextColor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 12),
                                ),
                              ),
                            ),
                          )),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats box overlapping yellow and background
          Positioned(
            top: MediaQuery.of(context).padding.top + 220,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xff414141)
                      : const Color(0xff1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: const [
                          Text("75 kg",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Weight",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.white54),
                    Expanded(
                      child: Column(
                        children: const [
                          Text("28",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Years Old",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.white54),
                    Expanded(
                      child: Column(
                        children: const [
                          Text("180 cm",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Height",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Back button overlaying on top of yellow header
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

final List<Map<String, dynamic>> formFields = [
  {
    'label': 'Full Name',
    'hint': 'Enter your full name',
    'icon': Icons.person_outline,
  },
  {
    'label': 'Email',
    'hint': 'Enter your email',
    'icon': Icons.email_outlined,
  },
  {
    'label': 'Mobile Number',
    'hint': 'Enter your mobile number',
    'icon': Icons.phone_outlined,
  },
  {
    'label': 'Date of Birth',
    'hint': 'DD/MM/YYYY',
    'icon': Icons.calendar_today_outlined,
  },
  {
    'label': 'Weight (kg)',
    'hint': 'Enter your weight',
    'icon': Icons.monitor_weight_outlined,
  },
  {
    'label': 'Height (cm)',
    'hint': 'Enter your height',
    'icon': Icons.height_outlined,
  },
];