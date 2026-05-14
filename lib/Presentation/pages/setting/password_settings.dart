import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_fit/Utils/constants.dart';

class PasswordSettings extends StatelessWidget {
  const PasswordSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff232323),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Password Settings',
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
        padding: const EdgeInsets.only(top: 10, right: 20, left: 20),
        child: ListView.builder(
          itemCount: formFields.length + 1,
          itemBuilder: (context, index) {
            if (index < formFields.length) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 45,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextFormField(
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            hintText: formFields[index]['label'],
                            hintStyle: const TextStyle(color: Colors.black38),
                            border: InputBorder.none,
                            suffixIcon: const Icon(
                              Icons.visibility,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (index == 0) // Only show for Current Password field
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8, bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Change Password',
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
    );
  }
}

final List<Map<String, dynamic>> formFields = [
  {
    'label': 'Current Password',
    'hint': 'Enter your current password',
  },
  {
    'label': 'New Password',
    'hint': 'Enter your new password',
  },
  {
    'label': 'Confirm New Password',
    'hint': 'Re-enter your new password',
  },
];
