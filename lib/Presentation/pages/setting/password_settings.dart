import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class PasswordSettings extends StatelessWidget {
  const PasswordSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
              child: ListView.builder(
                itemCount: formFields.length + 1,
                itemBuilder: (context, index) {
                  if (index < formFields.length) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: context.cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            height: 45,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: TextFormField(
                                style: TextStyle(color: context.textColor),
                                decoration: InputDecoration(
                                  hintText: formFields[index]['label'],
                                  hintStyle: TextStyle(
                                      color: context.subtextColor),
                                  border: InputBorder.none,
                                  suffixIcon: Icon(
                                    Icons.visibility,
                                    color: context.subtextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 8, right: 8, bottom: 16),
                            child: GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: context.isDark
                                      ? themeColor
                                      : Colors.black,
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