import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({super.key});

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyList = ref.watch(historyProvider);

    if (historyList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No history found yet. Check back tomorrow!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'History'),
              Tab(icon: Icon(Icons.lightbulb_outline), text: 'Insights'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildHistoryLog(historyList),
                _buildInsightsTab(historyList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: THE STANDARD HISTORY LOG ---
  Widget _buildHistoryLog(List<DayHistory> historyList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final dayData = historyList[index];
        final hydration = dayData.hydration;
        final symptoms = dayData.symptoms;
        final isGoalMet = hydration.totalDrankOz >= hydration.goalOz;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hydration.dateId,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      isGoalMet ? Icons.emoji_events : Icons.water_drop,
                      color: isGoalMet ? Colors.amber : Colors.blue,
                      size: 28,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Hydration: ${hydration.totalDrankOz.toStringAsFixed(0)} oz / ${hydration.goalOz.toStringAsFixed(0)} oz',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supplements: ${hydration.electrolytePills} Salt/Potassium Capsules',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (symptoms.isNotEmpty) ...[
                  const Text('Symptoms Experienced:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: -4.0,
                    children: symptoms.map((symptom) {
                      final time = DateTime.fromMillisecondsSinceEpoch(symptom.timestampEpoch);
                      final timeString = DateFormat.jm().format(time);
                      return Chip(
                        label: Text('${symptom.symptomName} ($timeString)', style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ] else
                  const Text('No symptoms logged.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: THE NEW INSIGHTS ENGINE ---
  Widget _buildInsightsTab(List<DayHistory> historyList) {
    if (historyList.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Keep tracking! We need at least 2 days of data to start finding patterns and generating insights.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Math for Hydration vs Symptoms
    final daysGoalMet = historyList.where((d) => d.hydration.totalDrankOz >= d.hydration.goalOz).toList();
    final daysGoalMissed = historyList.where((d) => d.hydration.totalDrankOz < d.hydration.goalOz).toList();

    double avgSymptomsMet = 0;
    if (daysGoalMet.isNotEmpty) {
      int totalSymptomsMet = daysGoalMet.fold(0, (sum, day) => sum + day.symptoms.length);
      avgSymptomsMet = totalSymptomsMet / daysGoalMet.length;
    }

    double avgSymptomsMissed = 0;
    if (daysGoalMissed.isNotEmpty) {
      int totalSymptomsMissed = daysGoalMissed.fold(0, (sum, day) => sum + day.symptoms.length);
      avgSymptomsMissed = totalSymptomsMissed / daysGoalMissed.length;
    }

    // Math for Electrolytes vs Symptoms
    final daysWithPills = historyList.where((d) => d.hydration.electrolytePills > 0).toList();
    final daysNoPills = historyList.where((d) => d.hydration.electrolytePills == 0).toList();

    double avgSymptomsPills = 0;
    if (daysWithPills.isNotEmpty) {
      int totalSymptomsPills = daysWithPills.fold(0, (sum, day) => sum + day.symptoms.length);
      avgSymptomsPills = totalSymptomsPills / daysWithPills.length;
    }

    double avgSymptomsNoPills = 0;
    if (daysNoPills.isNotEmpty) {
      int totalSymptomsNoPills = daysNoPills.fold(0, (sum, day) => sum + day.symptoms.length);
      avgSymptomsNoPills = totalSymptomsNoPills / daysNoPills.length;
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInsightCard(
          title: 'Hydration Consistency',
          icon: Icons.emoji_events,
          color: Colors.amber,
          message: 'You have hit your daily hydration goal ${daysGoalMet.length} out of ${historyList.length} recorded days.',
        ),

        // Show Hydration Insight if she has data for both scenarios
        if (daysGoalMet.isNotEmpty && daysGoalMissed.isNotEmpty)
          _buildInsightCard(
            title: 'Water & Symptoms',
            icon: Icons.water_drop,
            color: Colors.blue,
            message: avgSymptomsMet < avgSymptomsMissed
                ? 'Hydration helps! You average ${avgSymptomsMet.toStringAsFixed(1)} symptoms when hitting your goal, compared to ${avgSymptomsMissed.toStringAsFixed(1)} when you miss it.'
                : 'You average ${avgSymptomsMet.toStringAsFixed(1)} symptoms on days you hit your goal, and ${avgSymptomsMissed.toStringAsFixed(1)} when you miss it.',
          ),

        // Show Supplement Insight if she has data for both scenarios
        if (daysWithPills.isNotEmpty && daysNoPills.isNotEmpty)
          _buildInsightCard(
            title: 'Electrolytes Impact',
            icon: Icons.medication,
            color: Colors.purple,
            message: avgSymptomsPills < avgSymptomsNoPills
                ? 'Your capsules are working! You average ${avgSymptomsPills.toStringAsFixed(1)} symptoms on days you take them, compared to ${avgSymptomsNoPills.toStringAsFixed(1)} when you skip them.'
                : 'You average ${avgSymptomsPills.toStringAsFixed(1)} symptoms on days you take your capsules, and ${avgSymptomsNoPills.toStringAsFixed(1)} on days you do not.',
          ),
      ],
    );
  }

  // A helper widget to make the insight cards look clean and uniform
  Widget _buildInsightCard({required String title, required IconData icon, required Color color, required String message}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(message, style: const TextStyle(fontSize: 15, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}