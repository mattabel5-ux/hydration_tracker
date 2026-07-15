import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hydration_provider.dart';
import 'dashboard_view.dart';
import '../providers/theme_provider.dart';
import '../providers/symptom_provider.dart';
import 'symptom_checklist.dart';
import 'history_view.dart';
import 'daily_plan_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;

  // Controls which tab is currently selected (0 = Dashboard, 1 = History)
  int _selectedIndex = 0;

  // Form controllers
  final _goalController = TextEditingController(text: '96');
  final _bottleController = TextEditingController(text: '24');
  TimeOfDay? _firstDrinkTime;
  TimeOfDay? _bedtime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Fire off both database load requests simultaneously
    await Future.wait([
      ref.read(hydrationProvider.notifier).loadToday(),
      ref.read(symptomProvider.notifier).loadTodaySymptoms(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  // Converts the TimeOfDay picker into a DateTime for today
  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  // --- NEW: Human Bedtime Logic for Initial Setup ---
  DateTime _bedtimeToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    int dayOffset = 0;
    // If she picks between 12:00 AM and 4:59 AM, push it to tomorrow
    if (time.hour >= 0 && time.hour < 5) {
      dayOffset = 1;
    }
    return DateTime(now.year, now.month, now.day + dayOffset, time.hour, time.minute);
  }

  // Handles tapping the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(hydrationProvider);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If we have data for today, show the Main App Interface
    if (dailyState != null) {
      final themeMode = ref.watch(themeProvider);

      // The list of screens for our bottom navigation
      final List<Widget> screens = [
        const DashboardView(),
        const HistoryView(), // Using our new history screen!
        const DailyPlanView(), // The new read-only setup view
      ];

      return Scaffold(
        appBar: AppBar(
          title: Text(
              _selectedIndex == 0 ? 'Hydration Dashboard' :
              _selectedIndex == 1 ? 'History Log' : 'My Plan'
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ],
        ),

        // Displays the screen based on the selected index
        body: screens[_selectedIndex],

        // Only show the Symptoms button if she is actively on the Dashboard tab
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton.extended(
          // This shrinks the excessive side padding
          extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
          extendedIconLabelSpacing: 8,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const SymptomChecklist(),
            );
          },
          icon: const Icon(Icons.monitor_heart, size: 20),
          label: const Text('Symptoms', style: TextStyle(fontSize: 14)),
        )
            : null,

        // The Bottom Navigation Bar
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home), // The new Home button
              label: 'Plan',
            ),
          ],
        ),
      );
    }

    // If state is null, show the Setup Form
    return Scaffold(
      appBar: AppBar(title: const Text('Good Morning!')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Let\'s set up your day',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'Daily Goal (oz)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bottleController,
              decoration: const InputDecoration(
                labelText: 'Bottle Size (oz)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (time != null) setState(() => _firstDrinkTime = time);
                    },
                    child: Text(_firstDrinkTime == null
                        ? 'First Drink Time'
                        : _firstDrinkTime!.format(context)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                          context: context, initialTime: const TimeOfDay(hour: 22, minute: 0));
                      if (time != null) setState(() => _bedtime = time);
                    },
                    child: Text(_bedtime == null
                        ? 'Bedtime'
                        : _bedtime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: () {
                if (_firstDrinkTime != null && _bedtime != null) {
                  // NEW CODE
                  ref.read(hydrationProvider.notifier).setupDay(
                    goalOz: double.parse(_goalController.text),
                    bottleSize: double.parse(_bottleController.text),
                    firstDrink: _timeOfDayToDateTime(_firstDrinkTime!),
                    bedtime: _bedtimeToDateTime(_bedtime!), // <--- Now uses the new offset logic!
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select your times!')),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Start Tracking', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}