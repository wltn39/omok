import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //가로 세로 회전 기능
import 'omokList.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    //실행시 변경 설정
    ..displayDuration = const Duration(milliseconds: 1000)
    ..fontSize = 16.0
    ..toastPosition = EasyLoadingToastPosition.center
    //앱 동일설정
    ..loadingStyle = EasyLoadingStyle.dark
    ..radius = 30.0;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp]); // 세로고정
    Future<Database> database = initDatabase();

    return MaterialApp(
      title: 'AI Omok',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {'/omokList': (context) => OmokListApp(database)},
      home: Container(color: Colors.white, child: DatabaseApp(database)),
      builder: EasyLoading.init(),
    );
  }

  Future<Database> initDatabase() async {
    return openDatabase(
      join(await getDatabasePath(), 'omok_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE omoks(omokDate TEXT PRIMARY KEY, "
          "win INTEGER, tie INTEGER, defeat INTEGER, downCount INTEGER, score INTEGER)",
        );
      },
      version: 1,
    );
  }
}

class DatabaseApp extends StatefulWidget {
  final Future<Database> db;
  DatabaseApp(this.db);

  @override
  State<DatabaseApp> createState() => _DatabaseAppState();
}

class _DatabaseAppState extends State<DatabaseApp> {
  @override
  void dispose() {
    _player.stop();
    _player.dispose();

    super.dispose();
  }

  // 모든 Flag 설정
  bool? v_flagButtonPlay = true;

  @override
  Widget build(BuildContext context) {
    // return Text('오목 메인 화면');
    // return ElevatedButton(
    //     onPressed: () {
    //       Navigator.of(context).pushNamed('/omokList');
    //     },
    //     child: const Text(
    //       'Rank',
    //       style: TextStyle(color: Colors.white, fontSize: 13),
    //     ));
    return Scaffold(
      backgroundColor: Colors.transparent,
      //스캐폴드에 백그라운드를 투명하게 한다.
      appBar: AppBar(
          title: const Text(
            'AI 오목',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            ElevatedButton(
              child: Image.asset(
                'asset/images/lock.png',
                height: 30,
                width: 25,
              ),
              onPressed: () async {
                if (v_flagButtonPlay == false) {
                  EasyLoading.instance.fontSize = 16;
                  EasyLoading.instance.displayDuration =
                      const Duration(milliseconds: 500);
                  EasyLoading.showToast('*** Not executed! ***');
                } else {
                  const url = 'https://velog.io/@wltn39';
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            )
          ]),
      body: Container(),
    );
  }

  final _player = AudioPlayer();
  Future audioPlayer(parm_mp3) async {
    await _player.setAsset(parm_mp3);
    _player.play();
  }
}
