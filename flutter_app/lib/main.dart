import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/input_screen.dart';
import 'ui/result_screen.dart';

void main() {
  runApp(const ProviderScope(child: PriceCompareApp()));
}

class PriceCompareApp extends StatelessWidget {
  const PriceCompareApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '価格比較',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    ),
    initialRoute: '/',
    routes: {
      '/': (_) => const InputScreen(),
      '/result': (_) => const ResultScreen(),
    },
  );
}
