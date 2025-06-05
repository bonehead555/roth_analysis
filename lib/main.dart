import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/screens/home/home.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 58, 83, 121)),
          useMaterial3: true,
        ),
        darkTheme: ThemeData.dark(),
        //themeMode: ThemeMode.dark,
        //initialRoute: '/',
        //builder:(context, child) => const HomeScreen(),
        home: const HomeScreen(),
        );
  }
}
