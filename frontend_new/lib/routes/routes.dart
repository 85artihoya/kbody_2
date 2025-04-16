import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_new/screens/home_screen.dart';
import 'package:frontend_new/screens/login_screen.dart';
import 'package:frontend_new/screens/register_screen.dart';
import 'package:frontend_new/screens/pose_analysis_screen.dart';
import 'package:frontend_new/screens/exercise_screen.dart';
import 'package:frontend_new/screens/statistics_screen.dart';
import 'package:frontend_new/screens/settings_screen.dart';
import 'package:frontend_new/screens/disability_selection_screen.dart';
import 'package:frontend_new/screens/disability_type_screen.dart';
import 'package:frontend_new/screens/gmfcs_selection_screen.dart';
import 'package:frontend_new/screens/developmental_type_screen.dart';
import 'package:frontend_new/screens/other_disability_screen.dart';
import 'package:frontend_new/screens/register_complete_screen.dart';

class Routes {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pose-analysis',
        builder: (context, state) => const PoseAnalysisScreen(),
      ),
      GoRoute(
        path: '/exercise',
        builder: (context, state) => const ExerciseScreen(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/disability-selection',
        builder: (context, state) => const DisabilitySelectionScreen(),
      ),
      GoRoute(
        path: '/disability-type',
        builder: (context, state) => const DisabilityTypeScreen(),
      ),
      GoRoute(
        path: '/gmfcs-selection',
        builder: (context, state) => const GmfcsSelectionScreen(),
      ),
      GoRoute(
        path: '/developmental-type',
        builder: (context, state) => const DevelopmentalTypeScreen(),
      ),
      GoRoute(
        path: '/other-disability',
        builder: (context, state) => const OtherDisabilityScreen(),
      ),
      GoRoute(
        path: '/register-complete',
        builder: (context, state) => const RegisterCompleteScreen(),
      ),
    ],
  );
} 