import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class ProfilePage  extends StatelessWidget {
  const ProfilePage({super.key});

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
                height: 480,
                child: ListView.builder(
                  itemCount: formFields.length + 1, // +1 for the button
                  itemBuilder: (context, index) {
                    if (index < formFields.length) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          height: 45,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextFormField(
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                labelText: formFields[index]['label'],
                                labelStyle: const TextStyle(color: Colors.black38),
                                hintText: formFields[index]['hint'],
                                hintStyle: const TextStyle(color: Colors.black38),
                                prefixIcon: Icon(
                                  formFields[index]['icon'],
                                  color: Colors.black38,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Update Profile Button
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 35, left: 40, right: 40 ),
                        child: ElevatedButton(
                          onPressed: () {
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                      );
                    }
                  },
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
