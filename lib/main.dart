import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open (and create on first run) the local SQLite database up front so the
  // first screen doesn't pay the initialisation cost.
  await DatabaseHelper.instance.database;

  runApp(const MoneyPlannerApp());
}
