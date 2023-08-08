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
  final v_lisBox = List.generate(15, (i) => List.generate(15, (j) => ''));
  // 바둑판 배열 (15*15) ==> 수순
  final v_listBox_count =
      List.generate(15, (i) => List.generate(15, (j) => ''));

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
