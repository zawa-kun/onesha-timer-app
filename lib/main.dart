import 'dart:convert'; // json操作
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

// アプリ全体で使うためmain関数の外で定義
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// イベントのデータクラス
class AppEvent {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;

  const AppEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  // AppEventオブジェクトからMap（JSONに変換しやすい形式）を作成するファクトリメソッド
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'hour': hour,
    'minute': minute,
  };

  // Map(JSONから読み込んだ形式)からAppEventオブジェクトを作成するファクトリコンストラクタ
  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await flutterLocalNotificationsPlugin.cancelAll(); // 既存の通知をすべてキャンセル（起動毎に通知を設定し、重複を防ぐため。）

  List<AppEvent> appEvents = await loadAppEvents(); // 保存されているイベントを読み込む.

  if (appEvents.isEmpty) {
    debugPrint('初回起動またはイベントデータが無いため、デフォルトイベントを設定');
    appEvents = [
      const AppEvent(
        id: 0,
        title: 'おねがい社長イベント通知',
        body: '昼の悪徳業者、国際事業の時間です！',
        hour: 12,
        minute: 0,
      ),
      const AppEvent(
        id: 1,
        title: 'おねがい社長イベント通知',
        body: '夜の国際事業の時間です！',
        hour: 18,
        minute: 0,
      ),
    ];
    await saveAppEvents(appEvents); //デフォルトイベントを保存
  }

  for (var event in appEvents) {
    await _scheduleDailyNotification(
      id: event.id,
      title: event.title,
      body: event.body,
      hour: event.hour,
      minute: event.minute,
    );
  }

  runApp(const MyApp());
}

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


const String _kAppEventsKey = 'app_events'; // SharedPreferencesに保存する際のキー

// イベントリストを保存する関数
Future<void> saveAppEvents(List<AppEvent> events) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> jsonStringList =
    events.map((event) => jsonEncode(event.toJson())).toList();
  await prefs.setStringList(_kAppEventsKey, jsonStringList);
  debugPrint('SharedPreferencesにAppEventsが保存されました');
}

// イベントリストを読み込む関数
Future<List<AppEvent>> loadAppEvents() async {
  final prefs = await SharedPreferences.getInstance();
  final List<String>? jsonStringList = prefs.getStringList(_kAppEventsKey);

  if (jsonStringList == null) {
    debugPrint('AppEventSharedPreferences内に見つかりませんでした');
    return [];
  }

  // json文字列のリストをAppEventオブジェクトのリストに変換
  final List<AppEvent> events = jsonStringList
    .map((jsonString) => AppEvent.fromJson(jsonDecode(jsonString)))
    .toList();
  debugPrint('AppEventをSharedPreferencesから読み込みました');
  return events;
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'おねがい社長 タイマー',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'おねがい社長 イベントタイマー'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _checkPendingNotificationRequests();
  }

  Future<void> _checkPendingNotificationRequests() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    debugPrint('--- 予定されたアラームリスト ---');
    if (pendingNotificationRequests.isEmpty) {
      debugPrint('予定された通知はありません');
    } else {
      for (var request in pendingNotificationRequests) {
        debugPrint('ID: ${request.id}, Title: ${request.title}, Payload: ${request.payload}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '登録イベントはここに表示',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            // TODO: イベントリストを表示するListView.builderなどをここに追加予定
          ],
        ),
      ),
    );
  }
}