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
  // DateTime? dateTime = await showOmniDateTimePicker(context: context);
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Appointment',
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xff232323),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            FitnessTrainerCard(),
            ReuseableButton(title: "Pick Date and Time", onPressed: () async => await showOmniDateTimePicker(context: context),),
            Spacer(),
            ReuseableButton(title: "Next", onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => PaymentPage(),
              )); 
            },)
          ]),
        ));
  }
}
