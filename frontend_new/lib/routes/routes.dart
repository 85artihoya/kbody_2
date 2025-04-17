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
  static const String login = '/login';
  static const String register = '/register';
  static const String disabilitySelection = '/disability-selection';
  static const String disabilityType = '/disability-type';
  static const String gmfcsSelection = '/gmfcs-selection';
  static const String developmentalType = '/developmental-type';
  static const String otherDisability = '/other-disability';
  static const String registerComplete = '/register-complete';
  static const String home = '/home';

  static List<GoRoute> getRoutes() {
    return [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: disabilitySelection,
        builder: (context, state) {
          final registerData = state.extra as Map<String, dynamic>?;
          if (registerData == null) {
            return const LoginScreen();
          }
          return DisabilitySelectionScreen(registerData: registerData);
        },
      ),
      GoRoute(
        path: disabilityType,
        builder: (context, state) => const DisabilityTypeScreen(),
      ),
      GoRoute(
        path: gmfcsSelection,
        builder: (context, state) {
          final registerData = state.extra as Map<String, dynamic>?;
          if (registerData == null) {
            return const LoginScreen();
          }
          return GmfcsSelectionScreen(registerData: registerData);
        },
      ),
      GoRoute(
        path: developmentalType,
        builder: (context, state) => const DevelopmentalTypeScreen(),
      ),
      GoRoute(
        path: otherDisability,
        builder: (context, state) => const OtherDisabilityScreen(),
      ),
      GoRoute(
        path: registerComplete,
        builder: (context, state) => const RegisterCompleteScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
    ];
  }

  static final router = GoRouter(
    initialLocation: '/login',
    routes: getRoutes(),
  );
} 