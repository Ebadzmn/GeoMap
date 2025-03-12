import 'package:flutter/material.dart';
import 'package:mapgeolocation/HomeScreen.dart';

void main () {
  runApp(GoogleMaps());
}
class GoogleMaps extends StatelessWidget {
  const GoogleMaps({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Homescreen(),
    );
  }
}
