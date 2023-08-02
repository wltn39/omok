import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //가로 세로 회전 기능
import 'omokList.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp]); // 세로고정

    return MaterialApp(
      title: 'AI Omok',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {'/omokList': (context) => OmokListApp()},
      home: Container(color: Colors.white, child: DatabaseApp()),
    );
  }
}

class DatabaseApp extends StatefulWidget {
  @override
  State<DatabaseApp> createState() => _DatabaseAppState();
}

class _DatabaseAppState extends State<DatabaseApp> {
  @override
  Widget build(BuildContext context) {
    // return Text('오목 메인 화면');
    return ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/omokList');
        },
        child: const Text(
          'Rank',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ));
  }
}
