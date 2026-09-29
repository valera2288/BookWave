import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  // Нужно для DateFormat с локалью 'ru' в formatOrderDate — без инициализации
  // intl бросает LocaleDataException на любой локали, кроме дефолтной 'en_US'.
  await initializeDateFormatting();
  runApp(const ProviderScope(child: BookWaveApp()));
}
