class DailyHydration {
  final String dateId; // Format: YYYY-MM-DD
  final double goalOz;
  final double bottleSize;
  final int firstDrinkEpoch; // Using epoch integers for easy SQLite storage
  final int bedtimeEpoch;
  final double totalDrankOz;
  final int refillCount;

  DailyHydration({
    required this.dateId,
    required this.goalOz,
    required this.bottleSize,
    required this.firstDrinkEpoch,
    required this.bedtimeEpoch,
    required this.totalDrankOz,
    required this.refillCount,
  });

  // Converts our Dart object into a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'date_id': dateId,
      'goal_oz': goalOz,
      'bottle_size': bottleSize,
      'first_drink_epoch': firstDrinkEpoch,
      'bedtime_epoch': bedtimeEpoch,
      'total_drank_oz': totalDrankOz,
      'refill_count': refillCount,
    };
  }

  // Converts a SQLite Map back into our Dart object
  factory DailyHydration.fromMap(Map<String, dynamic> map) {
    return DailyHydration(
      dateId: map['date_id'],
      goalOz: map['goal_oz'],
      bottleSize: map['bottle_size'],
      firstDrinkEpoch: map['first_drink_epoch'],
      bedtimeEpoch: map['bedtime_epoch'],
      totalDrankOz: map['total_drank_oz'],
      refillCount: map['refill_count'],
    );
  }

  // Essential for Riverpod: allows us to duplicate the state and change only specific fields (like adding a refill)
  DailyHydration copyWith({
    String? dateId,
    double? goalOz,
    double? bottleSize,
    int? firstDrinkEpoch,
    int? bedtimeEpoch,
    double? totalDrankOz,
    int? refillCount,
  }) {
    return DailyHydration(
      dateId: dateId ?? this.dateId,
      goalOz: goalOz ?? this.goalOz,
      bottleSize: bottleSize ?? this.bottleSize,
      firstDrinkEpoch: firstDrinkEpoch ?? this.firstDrinkEpoch,
      bedtimeEpoch: bedtimeEpoch ?? this.bedtimeEpoch,
      totalDrankOz: totalDrankOz ?? this.totalDrankOz,
      refillCount: refillCount ?? this.refillCount,
    );
  }
}