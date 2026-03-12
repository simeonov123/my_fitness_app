// lib/main.dart

import 'package:flutter/material.dart';
import 'package:mytrainer2client/providers/client_folders_provider.dart';
import 'package:mytrainer2client/providers/exercises_provider.dart';
import 'package:mytrainer2client/providers/muscle_groups_provider.dart';
import 'package:mytrainer2client/providers/nutrition_templates_provider.dart';
import 'package:mytrainer2client/providers/training_sessions_provider.dart';
import 'package:mytrainer2client/providers/workout_instance_exercises_provider.dart';
import 'package:mytrainer2client/providers/workout_template_exercises_provider.dart';
import 'package:mytrainer2client/providers/workout_folders_provider.dart';
import 'package:mytrainer2client/providers/workout_templates_provider.dart';
import 'package:mytrainer2client/providers/social_feed_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_strategy/url_strategy.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/api_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/clients_provider.dart';
import 'services/auth_service.dart';
import 'services/invite_link_service.dart';
import 'services/pending_client_invite_service.dart';
import 'services/workout_notification_service.dart';
import 'routes.dart';

import 'models/client.dart';
import 'screens/client_detail_page.dart';
import 'screens/client_onboarding_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialInviteToken = await InviteLinkService.instance.captureInitialInviteToken();
  if (initialInviteToken != null && initialInviteToken.isNotEmpty) {
    await PendingClientInviteService().saveToken(initialInviteToken);
  }
  await AuthService().loginOrSignup(interactive: false);
  await WorkoutNotificationService.instance.initialize();

  setPathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ApiProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ClientFoldersProvider()),
        ChangeNotifierProvider(create: (_) => ClientsProvider()),
        ChangeNotifierProvider(create: (_) => NutritionTemplatesProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutFoldersProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutTemplatesProvider()),
        ChangeNotifierProvider(create: (_) => ExercisesProvider()),
        ChangeNotifierProvider(create: (_) => MuscleGroupsProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutTemplateExercisesProvider()),
        ChangeNotifierProvider(create: (_) => TrainingSessionsProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutInstanceExercisesProvider()),
        ChangeNotifierProvider(create: (_) => SocialFeedProvider()),



      ],
      child: const MyApp(),
    ),
  );
  InviteLinkService.instance.start(appNavigatorKey);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProv, _) {
        return Semantics(
          enabled: true,
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'MVFitness',
            locale: localeProv.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (deviceLocale == null) return supportedLocales.first;
              return supportedLocales.contains(deviceLocale)
                  ? deviceLocale
                  : const Locale('en');
            },

            initialRoute: WidgetsBinding.instance.platformDispatcher.defaultRouteName,
            routes: appRoutes,

            // Catch routes with query params here.
            onGenerateRoute: (settings) {
              final name = settings.name ?? '/';
              final uri = Uri.parse(name);

              if (uri.path == '/onboard/client') {
                return MaterialPageRoute(
                  builder: (_) => ClientOnboardingPage(
                    token: uri.queryParameters['token'],
                  ),
                  settings: settings,
                );
              }

              if (uri.path == '/client') {
                final client = settings.arguments as Client;
                return MaterialPageRoute(
                  builder: (_) => ClientDetailPage(client: client),
                  settings: settings,
                );
              }
              return null; // let unknownRoute or error if truly not found
            },

            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
