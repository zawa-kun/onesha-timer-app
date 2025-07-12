import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesha_timer_app/services/event_storage_service.dart';
import 'package:onesha_timer_app/services/notification_service.dart';
import 'package:onesha_timer_app/models/app_event.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AppEvent> _appEvents = [];
  @override
  void initState() {
    super.initState();
    _checkPendingNotificationRequests();
    _loadAppEvents();
  }

  // イベントの有効／無効を切り替えるメソッド
  Future<void> _toggleEventEnabled(int index, bool newValue) async {
    // リストのコピーを作成し、特定のイベントの状態を更新
    final updatedEvents = List<AppEvent>.from(_appEvents);
    updatedEvents[index] = AppEvent(
      id: updatedEvents[index].id,
      title: updatedEvents[index].title,
      body: updatedEvents[index].body,
      hour: updatedEvents[index].hour,
      minute: updatedEvents[index].minute,
      isEnabled: newValue, // 新しい状態を設定
    );

    // 状態を更新しUI再描画
    setState(() {
      _appEvents = updatedEvents;
    });

    // 変更の永続化
    await saveAppEvents(_appEvents);

    // 通知を再スケジュール
    await scheduleAppEventsNotifications(_appEvents);
    debugPrint('eventID: ${updatedEvents[index].id} の通知を無効化しました');
  }

  // デバッグ用：ローカルにスケジュール済みのイベントの取得（コンソール表示）
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

  Future<void> _loadAppEvents() async {
    final List<AppEvent> loadedEvents = await loadAppEvents();

    setState(() {
      _appEvents = loadedEvents;
    });

    debugPrint('${_appEvents.length}件のイベントをステートに保持しました。');
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: _appEvents.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '登録イベントはありません。',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _appEvents.length,
                itemBuilder: (context, index) {
                  final event = _appEvents[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row( // Row を使って内容とスイッチを横並びにする
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 両端に配置
                        children: [
                          Expanded( // テキスト部分がスペースを最大限使うように
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    '${event.hour.toString().padLeft(2, '0')}:${event.minute.toString().padLeft(2, '0')}'),
                              ],
                            ),
                          ),
                          Switch( // ★ここから追加
                            value: event.isEnabled, // 現在のオン/オフ状態
                            onChanged: (newValue) {
                              _toggleEventEnabled(index, newValue); // スイッチが切り替わったときの処理
                            },
                          ), // ★ここまで追加
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

