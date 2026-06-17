import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/appointment_booking_page.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/reviews_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Presentation/widgets/review_card.dart';
import 'package:get_fit/Utils/constants.dart';

class FitnessTrainerDetailPage extends StatelessWidget {
  final String bgImg;
  final String trainerName;
  final String trainerExp;
  final String trainerType;
  final String trainerRating;
  final String trainerClients;
  final String trainingCompleted;

  const FitnessTrainerDetailPage({
    super.key,
    required this.bgImg,
    required this.trainerName,
    required this.trainerExp,
    required this.trainerRating,
    required this.trainerType,
    required this.trainerClients,
    required this.trainingCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          Image.network(bgImg, fit: BoxFit.fitHeight),
          Positioned(
            top: 240,
            child: Container(
              height: 800,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        trainerName,
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        trainerType,
                        style: TextStyle(
                            color: context.subtextColor, fontSize: 16),
                      ),
                      trailing: CircleAvatar(
                        radius: 15,
                        backgroundColor: themeColor,
                        child: const Icon(Icons.phone,
                            color: Colors.black, size: 19),
                      ),
                    ),
                    Card(
                      color: context.cardBgColor,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(trainerExp,
                                    style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 25)),
                                Text('Experience',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 12)),
                              ],
                            ),
                            Column(
                              children: [
                                Text(trainingCompleted,
                                    style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 25)),
                                Text('Completed',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 12)),
                              ],
                            ),
                            Column(
                              children: [
                                Text(trainerClients,
                                    style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 25)),
                                Text('Active Clients',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        'Reviews',
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.amberAccent,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(
                                      'https://picsum.photos/200'),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.pink,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundImage: NetworkImage(
                                        'https://picsum.photos/201'),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(-20, 0),
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.orange,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundImage: NetworkImage(
                                        'https://picsum.photos/202'),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: Text(
                                  '+28 more',
                                  style: TextStyle(
                                    color: context.subtextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(trainerRating,
                                style: const TextStyle(color: Colors.black)),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      ReviewsPage(rating: trainerRating)));
                            },
                            child: Text("Read all Reviews",
                                style: TextStyle(
                                    color: context.subtextColor,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    ReviewCard(),
                    const SizedBox(height: 20),
                    ReuseableButton(
                        title: "Book an Appointment",
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  AppointmentBookingPage()));
                        }),
                  ],
                ),
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