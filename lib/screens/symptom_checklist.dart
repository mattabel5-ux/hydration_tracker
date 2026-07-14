import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/symptom_provider.dart';

class SymptomChecklist extends ConsumerWidget {
  const SymptomChecklist({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We only need the notifier to fire off the log command
    final notifier = ref.read(symptomProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'What are you feeling right now?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a symptom to log it with the current time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: SymptomNotifier.masterSymptomList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final symptom = SymptomNotifier.masterSymptomList[index];

                return ListTile(
                  title: Text(symptom, style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.add_circle, color: Colors.blue),
                  onTap: () {
                    // Logs the event with the exact timestamp
                    notifier.logSymptom(symptom);

                    // Show a quick success pop-up so she knows it worked
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$symptom logged at ${TimeOfDay.now().format(context)}'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context); // Close the menu automatically
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}