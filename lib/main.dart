import 'package:flutter/material.dart';
import 'package:liber/scanning_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Liber());
}

class Liber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liber',
      theme: ThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.lightBlueAccent
      ),
      home: HomeScreen(),
    );
  }
}
