import 'package:flutter/material.dart';

import 'package:onesha_timer_app/models/app_event.dart'; // AppEventクラス
import 'package:onesha_timer_app/screens/home_screens.dart'; // ホーム画面UI
import 'package:onesha_timer_app/services/event_storage_service.dart'; // 
import 'package:onesha_timer_app/services/notification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 通知サービスの初期化
  await initializeNotifications();
  // 権限のリクエスト
  await requestNoificationPermissions();
  // 既存の通知をすべてキャンセル(起動毎に通知が追加され,通知重複を防ぐため。)
  await cancelAllNotifications(); 
  // 保存されているイベントを読み込む.
  List<AppEvent> appEvents = await loadAppEvents(); 

  if (appEvents.isEmpty) {
    debugPrint('初回起動またはイベントデータが無いため、デフォルトイベントを設定');
    appEvents = [
      const AppEvent(
        id: 0,
        title: '昼の悪徳業者・国際事業',
        body: '昼の悪徳業者、国際事業の時間です！',
        hour: 12,
        minute: 0,
        isEnabled: true,
      ),
      const AppEvent(
        id: 1,
        title: '夜の国際事業',
        body: '夜の国際事業の時間です！',
        hour: 18,
        minute: 0,
        isEnabled: true,
      ),
    ];
    await saveAppEvents(appEvents); //デフォルトイベントを保存
  }

  // イベントスケジュールに基づいて通知をスケジュール
  await scheduleAppEventsNotifications(appEvents);

  runApp(const MyApp());
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

