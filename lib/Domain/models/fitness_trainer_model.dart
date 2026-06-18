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
    image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&h=200&fit=crop',
    bg_img: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&fit=crop',
    name: 'James Carter',
    trainingType: 'Strength & Conditioning',
    rating: '4.8',
    experience: '7',
    active_clients: '24',
    training_completed: '320',
    phone_number: '+1 234 567 8901',
    onTap: () {},
  ),
  FitnessTrainerModel(
    image: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200&h=200&fit=crop',
    bg_img: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&fit=crop',
    name: 'Sarah Mitchell',
    trainingType: 'Yoga & Flexibility',
    rating: '4.9',
    experience: '5',
    active_clients: '31',
    training_completed: '210',
    phone_number: '+1 234 567 8902',
    onTap: () {},
  ),
  FitnessTrainerModel(
    image: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=200&h=200&fit=crop',
    bg_img: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800&fit=crop',
    name: 'Marcus Johnson',
    trainingType: 'CrossFit Coach',
    rating: '4.7',
    experience: '9',
    active_clients: '18',
    training_completed: '450',
    phone_number: '+1 234 567 8903',
    onTap: () {},
  ),
  FitnessTrainerModel(
    image: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=200&h=200&fit=crop',
    bg_img: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&fit=crop',
    name: 'Elena Rodriguez',
    trainingType: 'Pilates & Core',
    rating: '4.6',
    experience: '4',
    active_clients: '22',
    training_completed: '180',
    phone_number: '+1 234 567 8904',
    onTap: () {},
  ),
  FitnessTrainerModel(
    image: 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=200&h=200&fit=crop',
    bg_img: 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=800&fit=crop',
    name: 'David Kim',
    trainingType: 'HIIT & Cardio',
    rating: '4.5',
    experience: '6',
    active_clients: '27',
    training_completed: '290',
    phone_number: '+1 234 567 8905',
    onTap: () {},
  ),
  FitnessTrainerModel(
    image: 'https://images.unsplash.com/photo-1617922001439-4a2e6562f328?w=200&h=200&fit=crop',
    bg_img: 'https://images.unsplash.com/photo-1617922001439-4a2e6562f328?w=800&fit=crop',
    name: 'Aisha Thompson',
    trainingType: 'Nutrition & Wellness',
    rating: '4.9',
    experience: '8',
    active_clients: '35',
    training_completed: '380',
    phone_number: '+1 234 567 8906',
    onTap: () {},
  ),
];