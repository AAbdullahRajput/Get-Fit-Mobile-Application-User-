class Exercise {
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final String sets;
  final String reps;
  final String rest;
  final String level;

  const Exercise({
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.level,
  });
}

final List<Exercise> dummyExercises = [
  Exercise(
    title: 'Bench Press',
    category: 'Chest',
    description: 'Classic chest builder targeting pecs, shoulders and triceps.',
    imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
    sets: '4 sets',
    reps: '10 reps',
    rest: 'Rest 60s',
    level: 'Intermediate',
  ),
  Exercise(
    title: 'Squat',
    category: 'Legs',
    description: 'King of lower-body movements — quads, glutes, core.',
    imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600',
    sets: '4 sets',
    reps: '12 reps',
    rest: 'Rest 90s',
    level: 'Beginner',
  ),
  Exercise(
    title: 'Pull Ups',
    category: 'Back',
    description: 'Best compound movement for a wide, strong back.',
    imageUrl: 'https://images.unsplash.com/photo-1598971639058-fab3c3109a34?w=600',
    sets: '3 sets',
    reps: '10 reps',
    rest: 'Rest 60s',
    level: 'Advanced',
  ),
  Exercise(
    title: 'Shoulder Press',
    category: 'Shoulders',
    description: 'Press overhead to build full shoulder caps.',
    imageUrl: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=600',
    sets: '3 sets',
    reps: '10 reps',
    rest: 'Rest 45s',
    level: 'Intermediate',
  ),
  Exercise(
    title: 'Bicep Curl',
    category: 'Arms',
    description: 'Great exercise for building strength and arm size.',
    imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600',
    sets: '3 sets',
    reps: '10 reps',
    rest: 'Rest 60s',
    level: 'Beginner',
  ),
  Exercise(
    title: 'Plank',
    category: 'Core',
    description: 'Isometric core hold — builds anti-rotation stability.',
    imageUrl: 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=600',
    sets: '3 sets',
    reps: '1 rep',
    rest: 'Rest 30s',
    level: 'Beginner',
  ),
  Exercise(
    title: 'Deadlift',
    category: 'Back',
    description: 'Full body powerhouse — builds total posterior chain strength.',
    imageUrl: 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=600',
    sets: '4 sets',
    reps: '8 reps',
    rest: 'Rest 120s',
    level: 'Advanced',
  ),
  Exercise(
    title: 'Tricep Dips',
    category: 'Arms',
    description: 'Bodyweight move that torches the triceps effectively.',
    imageUrl: 'https://images.unsplash.com/photo-1530822847156-5df684ec5933?w=600',
    sets: '3 sets',
    reps: '15 reps',
    rest: 'Rest 45s',
    level: 'Intermediate',
  ),
];