// イベントのデータクラス
class AppEvent {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool isEnabled;

  const AppEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.isEnabled = true, // デフォルトはtrue(有効)
  });

  // AppEventオブジェクトからMap（JSONに変換しやすい形式）を作成するファクトリメソッド
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'hour': hour,
    'minute': minute,
    'isEnabled': isEnabled,
  };

  // Map(JSONから読み込んだ形式)からAppEventオブジェクトを作成するファクトリコンストラクタ
  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      isEnabled: json['isEnabled'] as bool,
    );
  }
}