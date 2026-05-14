class OnboardingModel {
  final String image;
  final String title;
  final String description;
  final String icon;

  OnboardingModel({
    required this.icon,
    required this.image,
    required this.title,
    required this.description,
  });
}

final List<OnboardingModel> contents = [
  OnboardingModel(
    icon: 'assets/onboarding/icon-1.png',
    image: 'assets/onboarding/onboard-1.jpg',
    title: 'Start your Journey towards a more active lifestyle',
    description: 'Begin your fitness journey today with personalized workouts and expert guidance.', 
  ),
  OnboardingModel(
    icon: 'assets/onboarding/icon-2.png',
    image: 'assets/onboarding/onboard-2.jpg',
    title: 'Find nutrition tips that fit your lifestyle',
    description: 'Monitor your fitness goals and celebrate your achievements along the way.', 
  ),
  OnboardingModel(
    icon: 'assets/onboarding/icon-3.png',
    image: 'assets/onboarding/onboard-3.jpg',
    title: 'A community for you, challenge yourself',
    description: 'Connect with like-minded fitness enthusiasts and share your success story.', 
  ),
];