import 'package:flutter/material.dart';
import 'package:mytrainer2client/models/client.dart';
import 'package:mytrainer2client/screens/client_detail_page.dart';
import 'package:mytrainer2client/screens/login_page.dart';
import 'package:mytrainer2client/screens/splash_page.dart';
import 'package:mytrainer2client/screens/home_page.dart';
import 'package:mytrainer2client/screens/training_session_detail_page.dart';
import 'package:mytrainer2client/screens/workouts_page.dart';
import 'package:mytrainer2client/screens/social_page.dart';
import 'package:mytrainer2client/screens/programs_page.dart';
import 'package:mytrainer2client/screens/clients_page.dart';
import 'package:mytrainer2client/screens/nutrition_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/':         (_) => const SplashPage(),
  '/login':    (_) => const LoginPage(),
  '/home':     (_) => const HomePage(),
  '/workout':  (_) => const WorkoutsPage(),
  '/social':   (_) => const SocialPage(),
  '/programs': (_) => const ProgramsPage(),
  '/clients':  (_) => const ClientsPage(),
  '/nutrition':(_) => const NutritionPage(),
  '/session': (context) {
    final int id = ModalRoute.of(context)!.settings.arguments as int;
    return TrainingSessionDetailPage(sessionId: id);
  },
  // Client details; pulls the Client from arguments
  '/client': (context) {
    final client = ModalRoute.of(context)!.settings.arguments as Client;
    return ClientDetailPage(client: client);
  },
};
