import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Базовый Dio-клиент. Auth-интерцептор (JWT) подключается в `providers.dart`,
/// т.к. ему нужен доступ к `SecureSessionStorage`.
Dio buildApiClient() {
  return Dio(BaseOptions(baseUrl: _resolveBaseUrl()));
}

/// `API_BASE_URL` в `.env` — ручной оверрайд (например, если IP хоста в сети
/// сменился). Без него адрес выбирается по платформе, т.к. desktop-сборка и
/// Android (только BlueStacks — см. AGENTS.md, стандартный эмулятор не
/// используется) видят машину с бэкендом по-разному: у desktop-сборки
/// бэкенд — это просто localhost, а у BlueStacks нет алиаса localhost/
/// 10.0.2.2 к хосту (это алиас только стандартного Android-эмулятора),
/// нужен реальный IP хост-машины в локальной сети.
String _resolveBaseUrl() {
  final override = dotenv.env['API_BASE_URL'];
  if (override != null && override.isNotEmpty) return override;
  return Platform.isAndroid ? 'http://192.168.0.12:8000/api' : 'http://localhost:8000/api';
}
