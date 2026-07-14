import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/daily_hydration.dart';
import '../models/daily_symptom.dart';

// A simple custom class to bundle a day's hydration and symptoms together
class DayHistory {
  final DailyHydration hydration;
  final List<DailySymptom> symptoms; // Now passing the full object!

  DayHistory({required this.hydration, required this.symptoms});
}

class HistoryNotifier extends Notifier<List<DayHistory>> {
  @override
  List<DayHistory> build() {
    return [];
  }

  // Pulls all data from SQLite and merges it into a single history list
  Future<void> loadHistory() async {
    final allHydration = await DatabaseHelper.instance.getAllHydration();
    final allSymptoms = await DatabaseHelper.instance.getAllSymptoms();

    List<DayHistory> historyList = [];

    // Loop through each logged day
    for (var hydrationDay in allHydration) {
      // Find all symptoms that match this specific date and keep them as objects
      final daysSymptoms = allSymptoms
          .where((s) => s.dateId == hydrationDay.dateId)
          .toList();

      historyList.add(DayHistory(
        hydration: hydrationDay,
        symptoms: daysSymptoms,
      ));
    }

    state = historyList;
  }
}

// The global provider we will watch from our History UI
final historyProvider = NotifierProvider<HistoryNotifier, List<DayHistory>>(() {
  return HistoryNotifier();
});