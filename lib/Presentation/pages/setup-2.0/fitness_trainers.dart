import 'package:flutter/material.dart';
import 'package:get_fit/Domain/models/fitness_trainer_model.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/fitness_tainer_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class FitnessTrainers extends StatelessWidget {
  const FitnessTrainers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Fitness Trainers',
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
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: contents.length,
                itemBuilder: (context, index) {
                final trainer = contents[index];
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Card(
                    color: const Color(0xff232323),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: themeColor,
                        radius: 30,
                        backgroundImage: NetworkImage(trainer.image),
                      ),
                      title: Text(
                        trainer.name,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trainer.trainingType}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          Text(
                            '${trainer.experience} years experience',
                            style: const TextStyle(color: themeColor, fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(Icons.arrow_forward, color: Colors.white,),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                            color: themeColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(trainer.rating),
                          )
                        ],
                      ),
                      onTap: (){
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => FitnessTrainerDetailPage(
                          bgImg: trainer.bg_img, 
                          trainerName: trainer.name,
                          trainerExp: trainer.experience,
                          trainerType: trainer.trainingType,
                          trainerClients: trainer.active_clients,
                          trainingCompleted: trainer.training_completed,
                          trainerRating: trainer.rating,

                          
                          
                          )));
                      },
                  
                  
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}