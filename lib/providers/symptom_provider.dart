import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/daily_symptom.dart';

class SymptomNotifier extends Notifier<List<DailySymptom>> {
  @override
  List<DailySymptom> build() {
    return [];
  }

  String get _todayDateId => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static const List<String> masterSymptomList = [
    'Rapid heart rate',
    'Heart palpitations',
    'Chest pain',
    'Dizziness and lightheadedness',
    'Pre-syncope and syncope (fainting)',
    'Brain fog',
    'Headaches',
    'Fatigue',
    'Exercise intolerance',
    'Blood pooling',
    'Temperature regulation'
  ];

  Future<void> loadTodaySymptoms() async {
    final symptoms = await DatabaseHelper.instance.getSymptoms(_todayDateId);
    state = symptoms;
  }

  Future<void> logSymptom(String symptomName) async {
    final newSymptom = DailySymptom(
      dateId: _todayDateId,
      symptomName: symptomName,
      timestampEpoch: DateTime.now().millisecondsSinceEpoch,
    );
    await DatabaseHelper.instance.insertSymptom(newSymptom);

    // Append the new symptom to the state instantly
    state = [...state, newSymptom];
  }
}

final symptomProvider = NotifierProvider<SymptomNotifier, List<DailySymptom>>(() {
  return SymptomNotifier();
});