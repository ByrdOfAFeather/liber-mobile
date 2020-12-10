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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BarcodeScanner(),
    );
  }
}
