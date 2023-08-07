import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';
import 'omok.dart';

class OmokListApp extends StatefulWidget {
  final Future<Database> database;
  OmokListApp(this.database);

  @override
  State<OmokListApp> createState() => _OmokListAppState();
}

class _OmokListAppState extends State<OmokListApp> {
  @override
  Widget build(BuildContext context) {
    return const Text('게임 결과 화면');
  }
}
