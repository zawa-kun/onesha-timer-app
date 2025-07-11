import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart'; // debugPrint用
import 'package:onesha_timer_app/models/app_event.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 毎日の通知をスケジュールする関数
Future<void> _scheduleDailyNotification({
  required int id,
  required String title,
  required String body,
  required int hour,
  required int minute,
}) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
          'daily notification channel id', 'Daily Notification',
          channelDescription: 'Daily event notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');

  const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails();

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    _nextInstanceOfTime(hour, minute),
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.alarmClock, // AlarmClockモード
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // 毎日同じ時刻に繰り返す
    payload: 'daily_event_payload',
  );
  debugPrint('Scheduled notification $id for $hour:$minute daily.');
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}


// 通知の初期化をする関数
Future<void> initializeNotifications() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo')); // 日本

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      debugPrint('notification payload: ${notificationResponse.payload}');
    },
  );
}


// 通知とアラームの権限をリクエストする関数
Future<void> requestNoificationPermissions() async {
  final bool? notificationsResult = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  if (notificationsResult == true) {
    debugPrint('通知の許可が与えられました。');
  } else {
    debugPrint('通知の許可が否認されました。');
  }
  
  final bool? exactAlarmResult = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestExactAlarmsPermission();

  if (exactAlarmResult == true) {
    debugPrint('厳格なアラームの許可が与えられました。');
  } else {
    debugPrint('厳格なアラームの許可が否認されました。');
  }
}

// すべての通知をキャンセルする関数
Future<void> cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
}

Future<void> scheduleAppEventsNotifications(List<AppEvent> appEvents) async {
  for (var event in appEvents){
    await _scheduleDailyNotification(
      id: event.id, 
      title: event.title, 
      body: event.body, 
      hour: event.hour, 
      minute: event.minute
    );
  }
}