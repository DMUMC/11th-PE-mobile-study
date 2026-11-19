import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/movie_log_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // runApp() 이전에 .env 로드를 끝내야 TmdbConfig가 빈 Token을 읽지 않는다.
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}
