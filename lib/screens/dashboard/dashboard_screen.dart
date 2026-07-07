import 'package:flutter/material.dart';

import '../../widgets/remaining_balance_bar.dart';

/// Home screen — current period overview.
///
/// Scaffold placeholder for Phase 1. Wire real data (income, planned, spent,
/// remaining, unallocated) once the period/split providers land, then add the
/// pie chart and per-category progress bars in Phase 2.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Money Planner')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.savings_outlined, size: 64),
              SizedBox(height: 16),
              Text(
                'Your envelope budget lives here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Create a period and split your income to get started.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      // Persistent remaining-balance bar, shown on every screen.
      bottomNavigationBar: const RemainingBalanceBar(remaining: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO(phase-1): open New Period setup.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New period — coming in Phase 1')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New period'),
      ),
    );
  }
}
