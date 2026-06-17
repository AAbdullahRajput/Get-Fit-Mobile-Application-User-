import 'package:flutter/material.dart';
import 'package:get_fit/Domain/models/fitness_trainer_model.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/fitness_tainer_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class FitnessTrainerCard extends StatelessWidget {
  FitnessTrainerCard({super.key});

  final trainer = contents[0];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        color: context.cardBgColor,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: themeColor,
            radius: 30,
            backgroundImage: NetworkImage(trainer.image),
          ),
          title: Text(
            trainer.name,
            style: TextStyle(color: context.textColor, fontSize: 18),
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trainer.trainingType,
                style: TextStyle(color: context.subtextColor, fontSize: 14),
              ),
              Text(
                '${trainer.experience} years experience',
                style: TextStyle(color: context.textColor, fontSize: 14),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.arrow_forward, color: context.textColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  trainer.rating,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FitnessTrainerDetailPage(
                  bgImg: trainer.bg_img,
                  trainerName: trainer.name,
                  trainerExp: trainer.experience,
                  trainerType: trainer.trainingType,
                  trainerClients: trainer.active_clients,
                  trainingCompleted: trainer.training_completed,
                  trainerRating: trainer.rating,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}