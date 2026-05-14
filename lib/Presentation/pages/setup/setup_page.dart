import 'package:animated_weight_picker/animated_weight_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/home/home_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String? selectedGender;
  int? selectedAge;
  int? selectedWeight;
  int? selectedHeight;
  int? selectedGoal;
  int? selectedActivityLevel;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const highlightColor = Color(0xFFDBF500);
    const darkBackgroundStart = Colors.black;
    const darkBackgroundEnd = Color.fromARGB(255, 68, 73, 19);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkBackgroundStart, darkBackgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildGenderPage();
                      } else if (index == 1) {
                        return _buildAgePage();
                      } else if (index == 2) {
                        return _buildWeightPage();
                      } else if (index == 3) {
                        return _buildHeightPage();
                      } else if (index == 4) {
                        return _buildGoalPage();
                      } else {
                        return _buildActivityLevelPage();
                      }
                    },
                  ),
                ),
                // Replace the existing buttons withthis Row
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentPage == 0
                          ? const SizedBox(width: 48)
                          : GestureDetector(
                              onTap: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      // Next button
                      GestureDetector(
                        onTap: (_currentPage == 0 && selectedGender != null) ||
                                (_currentPage == 1 && selectedAge != null) ||
                                (_currentPage == 2 && selectedWeight != null) ||
                                (_currentPage == 3 && selectedHeight != null) ||
                                (_currentPage == 4 && selectedGoal != null) ||
                                (_currentPage == 5 &&
                                    selectedActivityLevel !=
                                        null)
                            ? _nextPage
                            : null,
                        child: Container(
                          width: 120,
                          height: 48,
                          decoration: BoxDecoration(
                            color: highlightColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Next',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.black,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderPage() {
    const highlightColor = Color(0xFFDBF500);
    final unselectedColor = Colors.grey.shade800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text(
          'Tell us about yourself',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'To give you a better experience we need\nto know your gender',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Column(
          children: [
            _buildGenderOption(
              gender: 'Male',
              icon: Icons.male,
              isSelected: selectedGender == 'Male',
              highlightColor: highlightColor,
              unselectedColor: unselectedColor,
            ),
            const SizedBox(height: 20),
            _buildGenderOption(
              gender: 'Female',
              icon: Icons.female,
              isSelected: selectedGender == 'Female',
              highlightColor: highlightColor,
              unselectedColor: unselectedColor,
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildAgePage() {
    const highlightColor = Color(0xFFDBF500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text(
          'How old are you ?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This helps us create your personalized plan',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 400,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 80,
            diameterRatio: 1.8,
            perspective: 0.005,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
                initialItem: 8), // Add this line (18-10=8)
            onSelectedItemChanged: (index) {
              setState(() {
                selectedAge = index + 10; // Starting from age 10
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 90, // Ages 10-99
              builder: (context, index) {
                final age = index + 10;
                final isSelected = selectedAge == age ||
                    (selectedAge == null && age == 18); // Default to 36

                if (isSelected && selectedAge == null) {
                  // Set default age to 36
                  Future.delayed(Duration.zero, () {
                    setState(() {
                      selectedAge = 18;
                    });
                  });
                }
                return SizedBox(
                  height: 80, // Match itemExtent
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 1.5,
                                  color: highlightColor,
                                  width: 100,
                                ),
                                const SizedBox(height: 60),
                                Container(
                                  height: 1.5,
                                  color: highlightColor,
                                  width: 100,
                                ),
                              ],
                            ),
                          Text(
                            '$age',
                            style: TextStyle(
                              color: isSelected ? highlightColor : Colors.grey,
                              fontSize: isSelected ? 45 : 40,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildWeightPage() {
    const highlightColor = Color(0xFFDBF500);
    const double min = 30;
    const double max = 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text(
          'What\'s your weight ?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'You can always change this later',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Column(
          children: [
            AnimatedWeightPicker(
              dialColor: Colors.white,
              suffixTextColor: highlightColor,
              selectedValueColor: highlightColor,
              min: min,
              max: max,
              onChange: (newValue) {
                setState(() {
                  selectedWeight = int.parse(newValue); // Update selectedWeight
                });
              },
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildHeightPage() {
    const highlightColor = Color(0xFFDBF500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text(
          "What's your height ?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This helps us create your personalized plan',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 400,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 80,
            diameterRatio: 1.8,
            perspective: 0.005,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
                initialItem: 20), // 170cm default (170-150=20)
            onSelectedItemChanged: (index) {
              setState(() {
                selectedHeight = index + 150; // Heights from 150-250cm
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 101, // Heights 150-250cm
              builder: (context, index) {
                final height = index + 150; // Start from 150cm
                final isSelected = selectedHeight == height ||
                    (selectedHeight == null &&
                        height == 170); // Default to 170cm

                if (isSelected && selectedHeight == null) {
                  Future.delayed(Duration.zero, () {
                    setState(() {
                      selectedHeight = 170; // Set default height to 170cm
                    });
                  });
                }
                return SizedBox(
                  height: 80, // Match itemExtent
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 1.5,
                                  color: highlightColor,
                                  width: 100,
                                ),
                                const SizedBox(height: 60), // Reduced from 60
                                Container(
                                  height: 1.5,
                                  color: highlightColor,
                                  width: 100,
                                ),
                              ],
                            ),
                          Text(
                            '$height',
                            style: TextStyle(
                              color: isSelected ? highlightColor : Colors.grey,
                              fontSize: isSelected ? 45 : 40,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildGoalPage() {
    const highlightColor = Color(0xFFDBF500);
    final goals = [
      'Lose Weight',
      'Gain Weight',
      'Build Muscle',
      'Stay Fit',
      'Improve Endurance',
      'General Fitness'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text(
          "What's your Goal ?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This helps us create your personalized plan',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 400,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 80,
            diameterRatio: 1.8,
            perspective: 0.005,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: 0),
            onSelectedItemChanged: (index) {
              setState(() {
                selectedGoal = index;
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: goals.length,
              builder: (context, index) {
                final goal = goals[index];
                final isSelected = selectedGoal == index ||
                    (selectedGoal == null && index == 0);

                if (isSelected && selectedGoal == null) {
                  Future.delayed(Duration.zero, () {
                    setState(() {
                      selectedGoal = 0;
                    });
                  });
                }
                return SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 1.5,
                                  color: highlightColor,
                                  width: 150,
                                ),
                                const SizedBox(height: 60),
                                Container(
                                  height: 1.5,
                                  color: highlightColor,
                                  width: 150,
                                ),
                              ],
                            ),
                          Text(
                            goal,
                            style: TextStyle(
                              color: isSelected ? highlightColor : Colors.grey,
                              fontSize: isSelected ? 24 : 20,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildActivityLevelPage() {
    const highlightColor = Color(0xFFDBF500);
    final activityLevels = [
      'Sedentary',
      'Lightly Active',
      'Moderately Active',
      'Very Active',
      'Extremely Active'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text(
          "What's your Activity Level ?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This helps us create your personalized plan',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 400,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 80,
            diameterRatio: 1.8,
            perspective: 0.005,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
                initialItem: 2), // Default to "Moderately Active"
            onSelectedItemChanged: (index) {
              setState(() {
                selectedActivityLevel = index;
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: activityLevels.length,
              builder: (context, index) {
                final activityLevel = activityLevels[index];
                final isSelected = selectedActivityLevel == index ||
                    (selectedActivityLevel == null && index == 2);

                if (isSelected && selectedActivityLevel == null) {
                  Future.delayed(Duration.zero, () {
                    setState(() {
                      selectedActivityLevel =
                          2; // Default to "Moderately Active"
                    });
                  });
                }
                return SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 1.5,
                                  color: highlightColor,
                                  width: 180,
                                ),
                                const SizedBox(height: 60),
                                Container(
                                  height: 1.5,
                                  color: highlightColor,
                                  width: 180,
                                ),
                              ],
                            ),
                          Text(
                            activityLevel,
                            style: TextStyle(
                              color: isSelected ? highlightColor : Colors.grey,
                              fontSize: isSelected ? 22 : 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildGenderOption({
    required String gender,
    required IconData icon,
    required bool isSelected,
    required Color highlightColor,
    required Color unselectedColor,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = gender;
        });
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? highlightColor : unselectedColor,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: highlightColor.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 50,
            ),
            const SizedBox(height: 5),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
