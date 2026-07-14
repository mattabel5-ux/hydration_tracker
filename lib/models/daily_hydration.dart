class DailyHydration {
  final String dateId;
  final double goalOz;
  final double bottleSize;
  final int firstDrinkEpoch;
  final int bedtimeEpoch;
  final double totalDrankOz;
  final int refillCount;
  final int electrolytePills; // The new combined variable

  DailyHydration({
    required this.dateId,
    required this.goalOz,
    required this.bottleSize,
    required this.firstDrinkEpoch,
    required this.bedtimeEpoch,
    required this.totalDrankOz,
    required this.refillCount,
    required this.electrolytePills,
  });

  DailyHydration copyWith({
    String? dateId,
    double? goalOz,
    double? bottleSize,
    int? firstDrinkEpoch,
    int? bedtimeEpoch,
    double? totalDrankOz,
    int? refillCount,
    int? electrolytePills,
  }) {
    return DailyHydration(
      dateId: dateId ?? this.dateId,
      goalOz: goalOz ?? this.goalOz,
      bottleSize: bottleSize ?? this.bottleSize,
      firstDrinkEpoch: firstDrinkEpoch ?? this.firstDrinkEpoch,
      bedtimeEpoch: bedtimeEpoch ?? this.bedtimeEpoch,
      totalDrankOz: totalDrankOz ?? this.totalDrankOz,
      refillCount: refillCount ?? this.refillCount,
      electrolytePills: electrolytePills ?? this.electrolytePills,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateId': dateId,
      'goalOz': goalOz,
      'bottleSize': bottleSize,
      'firstDrinkEpoch': firstDrinkEpoch,
      'bedtimeEpoch': bedtimeEpoch,
      'totalDrankOz': totalDrankOz,
      'refillCount': refillCount,
      'electrolytePills': electrolytePills,
    };
  }

  factory DailyHydration.fromMap(Map<String, dynamic> map) {
    return DailyHydration(
      dateId: map['dateId'],
      goalOz: map['goalOz'],
      bottleSize: map['bottleSize'],
      firstDrinkEpoch: map['firstDrinkEpoch'],
      bedtimeEpoch: map['bedtimeEpoch'],
      totalDrankOz: map['totalDrankOz'],
      refillCount: map['refillCount'],
      electrolytePills: map['electrolytePills'] ?? 0,
    );
  }
}