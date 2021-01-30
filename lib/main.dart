import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _path;

  FlutterSoundRecorder _myRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer _myPlayer = FlutterSoundPlayer();
  List <FlutterSoundRecorder> listRecorder =[] ;
  List <FlutterSoundPlayer> listPlayer = [];
  int _index = 0;
  bool _mRecorderIsInited;
  bool _mPlayerIsInited;
  bool _recording = false;
  bool _playing = false;
  Duration maxDuration, duration = Duration(hours: 0, minutes: 0);
  Duration minDuration = Duration(hours: 0, minutes: 0);

  @override
  void initState() {
    super.initState();
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    _myPlayer.openAudioSession().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    stopRecorder();
    stopPlayer();
    _myRecorder.closeAudioSession();
    _myPlayer.closeAudioSession();
    _myRecorder = null;
    _myPlayer = null;
    if (_path != null) {
      var outputFile = File(_path);
      if (outputFile.existsSync()) {
        outputFile.delete();
      }
    }
    super.dispose();
  }


  Future<void> openTheRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    var tempDir = await getTemporaryDirectory();
    _path = '${tempDir.path}/flutter_sound_example.aac';
    var outputFile = File(_path);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    await _myRecorder.openAudioSession();
    _mRecorderIsInited = true;
  }

  Future<void> play() async {
    await _myPlayer.setSubscriptionDuration(Duration(milliseconds: 500));

    if (_myPlayer.isPaused)
      await _myPlayer.resumePlayer();
    else {
      await _myPlayer.startPlayer(
       // numChannels: _index,
          fromURI: _path,
          codec: Codec.aacMP4,
          whenFinished: () {
            setState(() {
              _playing = false;
            });
          });
    }
    playerDuration();
    setState(() {
      _playing = true;
    });
  }

  Future<void> stopPlayer() async {
    if (_myPlayer != null) {
      await _myPlayer.stopPlayer();
      setState(() {
        _playing = false;
      });
    }
  }

  Future<void> pausePlayer() async {
    if (_myPlayer != null) {
      await _myPlayer.pausePlayer();
      setState(() {
        _playing = false;
      });
    }
  }

  Future<void> record() async {
    if (_myRecorder.isPaused) {
      await _myRecorder.resumeRecorder();
    } else {
      await _myRecorder.startRecorder(
        toFile: _path,
        codec: Codec.aacMP4,
      );
    }
    recordDuration();
    setState(() {
      _recording = true;
    });
  }

  Future<void> pauseRecord() async {
    await _myRecorder.pauseRecorder();
    setState(() {
      _recording = false;
    });
  }

  Future<void> stopRecorder() async {
    setState(() {
      _index = _index +1;
      listRecorder.add(_myRecorder);
      listPlayer.add(_myPlayer);
    });
    await _myRecorder.stopRecorder();
    setState(() {
      _recording = false;
      maxDuration = duration;
    });
  }

  void playerDuration() {
    _myPlayer.onProgress.listen((e) {
      setState(() {
        maxDuration = e.duration;
        minDuration = e.position;
      });
    });
  }

  void recordDuration() {
    _myRecorder.onProgress.listen((e) {
      setState(() {
        duration = e.duration;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  child: Icon(
                    _recording ? Icons.pause : Icons.play_arrow,
                  ),
                  onTap: _recording ? pauseRecord : record,
                ),
                SizedBox(width: 20),
                duration != null
                    ? Text("${duration.toString().substring(2, 7)}")
                    : Text(''),
                SizedBox(width: 20),
                GestureDetector(
                  child: Icon(
                    Icons.stop,
                  ),
                  onTap: stopRecorder,
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
                child: Text(_playing ? 'pause' : 'Play'),
                onPressed: _playing ? pausePlayer : play),
            ElevatedButton(child: Text('Stop Player'), onPressed: stopPlayer),
            Text("${minDuration.toString().substring(2, 7)}"),
            maxDuration != null
                ? Text("${maxDuration.toString().substring(2, 7)}")
                : Text(''),
            ElevatedButton(onPressed: (){
              if(_index < listRecorder.length){
                setState(() {
                  _index = _index + 1;
                  print(_index);
                  _myRecorder = listRecorder[_index];
                  _myPlayer = listPlayer[_index];
                  play();
                });
              }
            }, child: Text("next")),
            ElevatedButton(onPressed: (){
               if(_index > 0){
                 setState(() {
                   _index = _index -1;
                   print(_index);
                   _myRecorder = listRecorder[_index];
                   _myPlayer = listPlayer[_index];
                   play();
                 });
               }
            }, child: Text("back")),
            Text("$_index"),
            Text("${listPlayer.length}"),
          ],
        ),
      ),
    );
  }
}
