import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("[NotificationService] Local timezone set to: $timeZoneName");
    } catch (e) {
      print("[NotificationService] Could not get local timezone: $e");
      // Fallback: don't set local location, rely on default (usually UTC) or partial fix
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // requesting permission in iOS is done here or in requestPermissions
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _onNotificationClick.add(details.payload);
      },
    );
  }

  // Stream for notification clicks
  final _onNotificationClick = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationClick => _onNotificationClick.stream;

  // Immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
     await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    print("[NotificationService] Scheduling notification: Title=$title, Date=$scheduledDate");
    
    // If the scheduled date is in the past, don't schedule it.
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      print("[NotificationService] Scheduled time $scheduledDate is before now $now. Skipping.");
      return;
    }

    // Check for exact alarm permission
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    
    print("[NotificationService] Exact Alarm Permission: $granted");

    print("[NotificationService] Current tz.local: ${tz.local.name}");
    
    try {
      final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
      final now = tz.TZDateTime.now(tz.local);
      final diff = scheduledTime.difference(now);
      
      print("[NotificationService] Scheduled TZDateTime: $scheduledTime (UTC: ${scheduledTime.toUtc()})");
      print("[NotificationService] Time until notification: ${diff.inSeconds} seconds");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_channel_v3', // Force refresh again
          'To-Do Notifications',
          channelDescription: 'Notifications for to-do list items',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true, // Try to be obtrusive
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock, // Stronger guarantee
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    print("[NotificationService] Notification scheduled successfully");
    } catch (e) {
      print("[NotificationService] Error scheduling notification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
