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
      body: _appEvents.isEmpty //　イベントの有無によって表示内容変更
      ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '登録イベントはここに表示',
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
          return Card( //各イベントをカードとして表示
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${event.hour.toString().padLeft(2, '0')}:${event.minute.toString().padLeft(2, '0')}'),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}

