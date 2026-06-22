import 'package:flutter/material.dart';

class Exercise {
  final String id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final String sets;
  final String reps;
  final String rest;
  final String level;
  final String duration;
  final String kcal;
  final String exerciseCount;

  const Exercise({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.level,
    this.duration = '30 Minutes',
    this.kcal = '320 Kcal',
    this.exerciseCount = '5 Exercises',
  });
}

final List<Exercise> dummyExercises = [
  Exercise(
    id: 'bench_press',
    title: 'Bench Press',
    category: 'Chest',
    description: 'Classic chest builder targeting pecs, shoulders and triceps.',
    imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
    sets: '4 sets',
    reps: '10 reps',
    rest: 'Rest 60s',
    level: 'Intermediate',
    duration: '45 Minutes',
    kcal: '380 Kcal',
    exerciseCount: '4 Exercises',
  ),
  Exercise(
    id: 'squat',
    title: 'Squat',
    category: 'Legs',
    description: 'King of lower-body movements — quads, glutes, core.',
    imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600',
    sets: '4 sets',
    reps: '12 reps',
    rest: 'Rest 90s',
    level: 'Beginner',
    duration: '40 Minutes',
    kcal: '420 Kcal',
    exerciseCount: '6 Exercises',
  ),
  Exercise(
    id: 'pull_ups',
    title: 'Pull Ups',
    category: 'Back',
    description: 'Best compound movement for a wide, strong back.',
    imageUrl: 'https://images.pexels.com/photos/4162449/pexels-photo-4162449.jpeg',
    sets: '3 sets',
    reps: '10 reps',
    rest: 'Rest 60s',
    level: 'Advanced',
    duration: '30 Minutes',
    kcal: '310 Kcal',
    exerciseCount: '5 Exercises',
  ),
  Exercise(
    id: 'shoulder_press',
    title: 'Shoulder Press',
    category: 'Shoulders',
    description: 'Press overhead to build full shoulder caps.',
    imageUrl: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=600',
    sets: '3 sets',
    reps: '10 reps',
    rest: 'Rest 45s',
    level: 'Intermediate',
    duration: '35 Minutes',
    kcal: '290 Kcal',
    exerciseCount: '4 Exercises',
  ),
  Exercise(
    id: 'bicep_curl',
    title: 'Bicep Curl',
    category: 'Arms',
    description: 'Great exercise for building strength and arm size.',
    imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600',
    sets: '3 sets',
    reps: '10 reps',
    rest: 'Rest 60s',
    level: 'Beginner',
    duration: '25 Minutes',
    kcal: '210 Kcal',
    exerciseCount: '3 Exercises',
  ),
  Exercise(
    id: 'plank',
    title: 'Plank',
    category: 'Core',
    description: 'Isometric core hold — builds anti-rotation stability.',
    imageUrl: 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=600',
    sets: '3 sets',
    reps: '1 rep',
    rest: 'Rest 30s',
    level: 'Beginner',
    duration: '20 Minutes',
    kcal: '180 Kcal',
    exerciseCount: '3 Exercises',
  ),
  Exercise(
    id: 'deadlift',
    title: 'Deadlift',
    category: 'Back',
    description: 'Full body powerhouse — builds total posterior chain strength.',
    imageUrl: 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=600',
    sets: '4 sets',
    reps: '8 reps',
    rest: 'Rest 120s',
    level: 'Advanced',
    duration: '50 Minutes',
    kcal: '520 Kcal',
    exerciseCount: '4 Exercises',
  ),
  Exercise(
    id: 'tricep_dips',
    title: 'Tricep Dips',
    category: 'Arms',
    description: 'Bodyweight move that torches the triceps effectively.',
    imageUrl: 'https://images.pexels.com/photos/4162438/pexels-photo-4162438.jpeg',
    sets: '3 sets',
    reps: '15 reps',
    rest: 'Rest 45s',
    level: 'Intermediate',
    duration: '25 Minutes',
    kcal: '230 Kcal',
    exerciseCount: '3 Exercises',
  ),
];