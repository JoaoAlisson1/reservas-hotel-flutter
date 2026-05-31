import 'package:flutter/material.dart';
import 'core/database/app_database.dart';
import 'app_widget.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase().database; // comentar para testar no chrome

  runApp(const MyApp());
}