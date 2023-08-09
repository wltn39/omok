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
      join(await getDatabasesPath(), 'omok_database.db'),
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

  // 변수설정
  String v_image_volume = 'asset/images/volume_on.png';
  bool v_volume = true;

  // 모든 배열 설정
  // 바둑판 배열 (15*15) ==> n,w,b
  final v_listBox = List.generate(15, (i) => List.generate(15, (j) => ''));
  // 바둑판 배열 (15*15) ==> 수순
  final v_listBox_count =
      List.generate(15, (i) => List.generate(15, (j) => ''));

  // 게임판을 누르면 바둑판에 돌을 놓기
  void step_downStone(x, y) {}

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
          ),
          ElevatedButton(
            child: Image.asset(
              'asset/images/playStore.png',
              height: 22,
              width: 25,
            ),
            onPressed: () async {
              if (v_flagButtonPlay == false) {
                EasyLoading.instance.fontSize = 16;
                EasyLoading.instance.displayDuration =
                    const Duration(milliseconds: 500);
                EasyLoading.showToast('*** Not executed! ***');
              } else {
                const url =
                    'https://play.google.com/store/apps/details?id=com.gpldy.omok';
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
          ElevatedButton(
            child: Image.asset(
              v_image_volume,
              height: 22,
              width: 25,
            ),
            onPressed: () {
              if (v_volume == true) {
                v_image_volume = 'asset/images/volume_off.png';
                v_volume = false;
              } else {
                v_image_volume = 'asset/images/volume_on.png';
                v_volume = true;
              }
              ;
              setState(() {});
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (v_flagButtonPlay == true) {
                Navigator.of(context).pushNamed('/omokList');
              } else {
                EasyLoading.instance.fontSize = 16;
                EasyLoading.instance.displayDuration =
                    const Duration(milliseconds: 500);
                EasyLoading.showToast('*** Not executed! ***');
              }
            },
            child: const Text(
              'Rank',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            // body 상단
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                // 바둑판 배경이미지
                Container(
                  width: (MediaQuery.of(context).size.width >
                          MediaQuery.of(context).size.height - 300
                      ? MediaQuery.of(context).size.height - 300
                      : MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.width >
                          MediaQuery.of(context).size.height - 300
                      ? MediaQuery.of(context).size.height - 300
                      : MediaQuery.of(context).size.width),
                  // color: Colors.yellow,
                  child: Image.asset('asset/images/omok_bg.png',
                      fit: BoxFit.contain),
                ),
                //15*15 바둑돌 이미지
                Container(
                  width: (MediaQuery.of(context).size.width >
                          MediaQuery.of(context).size.height - 300
                      ? MediaQuery.of(context).size.height - 300
                      : MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height >
                          MediaQuery.of(context).size.height - 300
                      ? MediaQuery.of(context).size.height - 300
                      : MediaQuery.of(context).size.width),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[0][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[1][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[2][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[3][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[4][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[5][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[6][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[7][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[8][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[9][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[10][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[11][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[12][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[13][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][00]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][01]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][02]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][03]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][04]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][05]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][06]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][07]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][08]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][09]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][11]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][12]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][13]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Container(
                                  child: Image.asset(
                                      'asset/images/${v_listBox[14][14]}.png'),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                //15*15 버튼
                Container(
                  width: (MediaQuery.of(context).size.width >
                          MediaQuery.of(context).size.height -
                              300 //하단 최소 height
                      ? MediaQuery.of(context).size.height - 300
                      : MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height >
                          MediaQuery.of(context).size.height - 300
                      ? MediaQuery.of(context).size.height - 300
                      : MediaQuery.of(context).size.width),
                ),
              ],
            ),
            // body 하단
            Expanded(
              flex: 1,
              child: Container(
                // color: Colors.blue,
                child: Column(
                  children: [
                    // body 하단 버튼2, 텍스트2
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.black12,
                        padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                        child: Row(
                          children: [
                            //body 하단 텍스트 (You)
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: Colors.red,
                              ),
                            ),
                            // body 하단 버튼 게임시작
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: Colors.pink,
                              ),
                            ),
                            // body 하단 버튼 기권
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: Colors.yellow,
                              ),
                            ),
                            // body 하단 텍스트 (현재수순)
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // body 하단 전적
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.blue,
                        child: Row(
                          children: [
                            //body 하단 전적 텍스트
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: Colors.deepOrangeAccent,
                              ),
                            ),
                            // body 하단 전적(승무패 점수)
                            Expanded(
                              flex: 3,
                              child: Container(
                                color: Colors.purple[300],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 63,
      ),
    );
  }

  final _player = AudioPlayer();
  Future audioPlayer(parm_mp3) async {
    await _player.setAsset(parm_mp3);
    _player.play();
  }
}
