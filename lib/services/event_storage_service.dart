import 'dart:convert'; // json操作
import 'package:flutter/foundation.dart'; // debugPrint用
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesha_timer_app/models/app_event.dart';


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