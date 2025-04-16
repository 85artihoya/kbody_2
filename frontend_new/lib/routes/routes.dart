import 'package:flutter/material.dart';
import 'package:frontend_new/screens/home_screen.dart';
import 'package:frontend_new/screens/login_screen.dart';
import 'package:frontend_new/screens/register_screen.dart';
import 'package:frontend_new/screens/pose_analysis_screen.dart';
import 'package:frontend_new/screens/exercise_screen.dart';
import 'package:frontend_new/screens/statistics_screen.dart';
import 'package:frontend_new/screens/settings_screen.dart';

class Routes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String poseAnalysis = '/pose-analysis';
  static const String exercise = '/exercise';
  static const String statistics = '/statistics';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      poseAnalysis: (context) => const PoseAnalysisScreen(),
      exercise: (context) => const ExerciseScreen(),
      statistics: (context) => const StatisticsScreen(),
      settings: (context) => const SettingsScreen(),
    };
  }
} 