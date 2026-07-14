class DailySymptom {
  final int? id; // Nullable because SQLite will auto-increment this for us
  final String dateId; // This links the symptom back to the daily_hydration date
  final String symptomName;

  DailySymptom({
    this.id,
    required this.dateId,
    required this.symptomName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_id': dateId,
      'symptom_name': symptomName,
    };
  }

  factory DailySymptom.fromMap(Map<String, dynamic> map) {
    return DailySymptom(
      id: map['id'],
      dateId: map['date_id'],
      symptomName: map['symptom_name'],
    );
  }
}