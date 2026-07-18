import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 160
    ..maximumSizeBytes = 48 * 1024 * 1024;
  runApp(const ProviderScope(child: RoadDnaApp()));
}
