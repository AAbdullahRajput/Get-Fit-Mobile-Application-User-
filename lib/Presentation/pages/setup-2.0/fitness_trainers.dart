import 'package:flutter/material.dart';
import 'package:get_fit/Domain/models/fitness_trainer_model.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/fitness_tainer_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class FitnessTrainers extends StatelessWidget {
  const FitnessTrainers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 60, 14, 14),
              child: Column(
                children: [
                  Text(
                      'Fitness Trainers',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                      itemCount: contents.length,
                      itemBuilder: (context, index) {
                        final trainer = contents[index];
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Card(
                          color: context.cardBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: context.isDark ? 0 : 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: themeColor,
                                radius: 30,
                                backgroundImage: NetworkImage(trainer.image),
                              ),
                              title: Text(
                                trainer.name,
                                style: TextStyle(
                                    color: context.textColor, fontSize: 18),
                              ),
                              subtitle: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trainer.trainingType,
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    '${trainer.experience} years experience',
                                    style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Icon(Icons.arrow_forward,
                                      color: context.textColor),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: themeColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      '',
                                      style:
                                          TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FitnessTrainerDetailPage(
                                      bgImg: trainer.bg_img,
                                      trainerName: trainer.name,
                                      trainerExp: trainer.experience,
                                      trainerType: trainer.trainingType,
                                      trainerClients: trainer.active_clients,
                                      trainingCompleted:
                                          trainer.training_completed,
                                      trainerRating: trainer.rating,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
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