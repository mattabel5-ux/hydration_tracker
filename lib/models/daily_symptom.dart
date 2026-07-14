class DailySymptom {
  final int? id;
  final String dateId;
  final String symptomName;
  final int timestampEpoch;

  DailySymptom({
    this.id,
    required this.dateId,
    required this.symptomName,
    required this.timestampEpoch,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateId': dateId,
      'symptomName': symptomName,
      'timestampEpoch': timestampEpoch,
    };
  }

  factory DailySymptom.fromMap(Map<String, dynamic> map) {
    return DailySymptom(
      id: map['id'],
      dateId: map['dateId'],
      symptomName: map['symptomName'],
      timestampEpoch: map['timestampEpoch'] ?? 0,
    );
  }
}