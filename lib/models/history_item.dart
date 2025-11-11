class HistoryItem {
  final String imagePath;
  final String label;
  final String confidence;
  final DateTime date;
  final double? latitude;
  final double? longitude;

  HistoryItem({
    required this.imagePath,
    required this.label,
    required this.confidence,
    required this.date,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() => {
        'imagePath': imagePath,
        'label': label,
        'confidence': confidence,
        'date': date.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

  factory HistoryItem.fromMap(Map map) => HistoryItem(
        imagePath: map['imagePath'],
        label: map['label'],
        confidence: map['confidence'],
        date: DateTime.parse(map['date']),
        latitude: map['latitude'] != null
            ? (map['latitude'] as num).toDouble()
            : null,
        longitude: map['longitude'] != null
            ? (map['longitude'] as num).toDouble()
            : null,
      );
}
