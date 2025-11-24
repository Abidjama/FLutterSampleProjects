import 'package:almasjid/MainScreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
  //handleSubuintLogic();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors
            .green, // You can set the primary color to match your app's theme
      ),
      home: MasjidApp(), // Set LoginPage as the default route (first screen)
    );
  }
}
