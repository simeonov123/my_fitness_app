import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WorkoutNotificationService {
  WorkoutNotificationService._();

  static final WorkoutNotificationService instance =
      WorkoutNotificationService._();

  static const _channelId = 'active_workout_channel';
  static const _channelName = 'Active workout';
  static const _channelDescription = 'Shows the active workout progress';
  static const _notificationId = 7001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.low,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: false,
        );

    _initialized = true;
  }

  Future<void> showActiveWorkout({
    required String title,
    required DateTime startedAt,
    required double totalWeightLifted,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final body =
        'Workout in progress • ${totalWeightLifted.toStringAsFixed(0)} kg lifted';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        category: AndroidNotificationCategory.progress,
        showWhen: true,
        when: startedAt.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );

    await _plugin.show(
      _notificationId,
      title,
      body,
      details,
    );
  }

  Future<void> cancelActiveWorkout() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(_notificationId);
  }
}
