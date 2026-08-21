import 'package:flutter/material.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenceHandler.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)),
      // PUSH NAMED
      initialRoute: "/",
      routes: {"/": (context) => const SplashScreenTugas12()},
    );
  }
}
