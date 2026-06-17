import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/payment_page.dart';
import 'package:get_fit/Presentation/widgets/fitness_trainer_card.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class AppointmentBookingPage extends StatelessWidget {
  const AppointmentBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 60, 8, 16),
              child: Column(
                children: [
                  FitnessTrainerCard(),
                  const SizedBox(height: 16),
                  ReuseableButton(
                    title: "Pick Date and Time",
                    onPressed: () async => await showOmniDateTimePicker(
                      context: context,
                      theme: ThemeData(
                        colorScheme: context.isDark
    ? const ColorScheme.dark(
        primary: themeColor,
        onPrimary: Colors.black,
      )
    : const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ReuseableButton(
                    title: "Next",
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => PaymentPage(),
                      ));
                    },
                  ),
                ],
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