class FitnessTrainerModel {
  final String image;
  final String bg_img;
  final String name;
  final String trainingType;
  final String rating;
  final String experience;
  final String training_completed;
  final String active_clients;
  final String phone_number;
  final void Function()? onTap;

  FitnessTrainerModel({
    required this.image,
    required this.bg_img,
    required this.name,
    required this.trainingType,
    required this.rating,
    required this.experience,
    this.onTap,
    this.active_clients = '0',
    this.training_completed = '0',
    this.phone_number = '',
  });
}

final List<FitnessTrainerModel> contents = [
  FitnessTrainerModel(
    image: 'https://static.vecteezy.com/system/resources/previews/036/594/092/non_2x/man-empty-avatar-photo-placeholder-for-social-networks-resumes-forums-and-dating-sites-male-and-female-no-photo-images-for-unfilled-user-profile-free-vector.jpg',
    bg_img: 'https://api.army.mil/e2/c/images/2019/10/04/566954/original.jpg',
    name: 'John Doe',
    trainingType: 'Personal Trainer',
    rating: '4.5',
    experience: '5',
    onTap: () {
    },
  ),
  FitnessTrainerModel(
    image: 'https://static.vecteezy.com/system/resources/previews/036/594/092/non_2x/man-empty-avatar-photo-placeholder-for-social-networks-resumes-forums-and-dating-sites-male-and-female-no-photo-images-for-unfilled-user-profile-free-vector.jpg',
    bg_img: 'https://api.army.mil/e2/c/images/2019/10/04/566954/original.jpg',
    name: 'John Doe',
    trainingType: 'Personal Trainer',
    rating: '4.5',
    experience: '5',
    onTap: () {
    },
  ),
  FitnessTrainerModel(
    image: 'https://static.vecteezy.com/system/resources/previews/036/594/092/non_2x/man-empty-avatar-photo-placeholder-for-social-networks-resumes-forums-and-dating-sites-male-and-female-no-photo-images-for-unfilled-user-profile-free-vector.jpg',
    bg_img: 'https://api.army.mil/e2/c/images/2019/10/04/566954/original.jpg',
    name: 'John Doe',
    trainingType: 'Personal Trainer',
    rating: '4.5',
    experience: '5',
    onTap: () {
    },
  ),
  FitnessTrainerModel(
    image: 'https://static.vecteezy.com/system/resources/previews/036/594/092/non_2x/man-empty-avatar-photo-placeholder-for-social-networks-resumes-forums-and-dating-sites-male-and-female-no-photo-images-for-unfilled-user-profile-free-vector.jpg',
    bg_img: 'https://api.army.mil/e2/c/images/2019/10/04/566954/original.jpg',
    name: 'John Doe',
    trainingType: 'Personal Trainer',
    rating: '4.5',
    experience: '5',
    onTap: () {
    },
  ),
  FitnessTrainerModel(
    image: 'https://static.vecteezy.com/system/resources/previews/036/594/092/non_2x/man-empty-avatar-photo-placeholder-for-social-networks-resumes-forums-and-dating-sites-male-and-female-no-photo-images-for-unfilled-user-profile-free-vector.jpg',
    bg_img: 'https://api.army.mil/e2/c/images/2019/10/04/566954/original.jpg',
    name: 'John Doe',
    trainingType: 'Personal Trainer',
    rating: '4.5',
    experience: '5',
    onTap: () {
    },
  ),
  FitnessTrainerModel(
    image: 'https://static.vecteezy.com/system/resources/previews/036/594/092/non_2x/man-empty-avatar-photo-placeholder-for-social-networks-resumes-forums-and-dating-sites-male-and-female-no-photo-images-for-unfilled-user-profile-free-vector.jpg',
    bg_img: 'https://api.army.mil/e2/c/images/2019/10/04/566954/original.jpg',
    name: 'John Doe',
    trainingType: 'Personal Trainer',
    rating: '4.5',
    experience: '5',
    onTap: () {
    },
  ),
  
  
];