import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hydration_provider.dart';
import 'dashboard_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;

  // Form controllers
  final _goalController = TextEditingController(text: '80');
  final _bottleController = TextEditingController(text: '24');
  TimeOfDay? _firstDrinkTime;
  TimeOfDay? _bedtime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await ref.read(hydrationProvider.notifier).loadToday();
    setState(() {
      _isLoading = false;
    });
  }

  // Converts the TimeOfDay picker into a DateTime for today
  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(hydrationProvider);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If we have data for today, show the Dashboard (We will build this next!)
    // If we have data for today, show the Dashboard
    if (dailyState != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hydration Dashboard'),
          centerTitle: true,
        ),
        body: const DashboardView(), // Using our new widget here!
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
                  ref.read(hydrationProvider.notifier).setupDay(
                    goalOz: double.parse(_goalController.text),
                    bottleSize: double.parse(_bottleController.text),
                    firstDrink: _timeOfDayToDateTime(_firstDrinkTime!),
                    bedtime: _timeOfDayToDateTime(_bedtime!),
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