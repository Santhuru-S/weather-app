import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:weather/weatherapp.dart';

import 'Weather.dart';
import 'new map.dart';

void main() {
  runApp(const MyApp());
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Weather(),
      builder: (context, child) => ResponsiveBreakpoints(
          child: child!,
          breakpoints: [
            Breakpoint(start: 0, end:450,name: MOBILE),
            Breakpoint(start: 451, end: 800,name: TABLET),
            Breakpoint(start: 801, end: 1920,name: DESKTOP),
            Breakpoint(start: 1921, end: double.infinity,name: '4K'),
          ]),
    );
  }
}