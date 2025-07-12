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
        brightness: Brightness.light, // 明るいテーマ (Light Mode)

        colorScheme: const ColorScheme.light(
          primary: Colors.black87,    // 主要な色（暗いグレー/ほぼ黒）
          onPrimary: Colors.white,    // primary 上のテキスト色
          secondary: Colors.grey,     // 補助的な色（中間のグレー）
          onSecondary: Colors.white,  // secondary 上のテキスト色

          surface: Colors.white,      // カードやシートの背景色
          onSurface: Colors.black87,  // surface 上のテキスト色

          error: Colors.red,
          onError: Colors.white,
        ),

        // AppBarTheme も ColorScheme の色を参照するように変更
        appBarTheme: const AppBarTheme( // const を維持
          backgroundColor: Colors.black87, // ColorSchemeのprimaryと同じ色を直接指定
          foregroundColor: Colors.white,      // ColorSchemeのonPrimaryと同じ色を直接指定
          elevation: 0,
          centerTitle: true,
        ),

        // テキストテーマの調整 (Optional: より洗練されたタイポグラフィ)
        // 好みに合わせてフォントサイズなどを調整できます。
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 96.0, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 60.0, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 34.0, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
          titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
          bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal),
          labelSmall: TextStyle(fontSize: 10.0, fontWeight: FontWeight.normal),
        ),

        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'おねがい社長 イベントタイマー'),
    );
  }
}
