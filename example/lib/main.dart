import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:isolate_utils/isolate_utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IsolateUtils Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'IsolateUtils Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  IsolateUtils? _isolateUtils;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton.icon(
              label: Text('Create'),
              icon: Icon(Icons.create),
              onPressed: _onCreate,
            ),
            TextButton.icon(
              label: Text('Start'),
              icon: Icon(Icons.play_arrow),
              onPressed: _onStart,
            ),
            TextButton.icon(
              label: Text('Pause'),
              icon: Icon(Icons.pause),
              onPressed: _onPause,
            ),
            TextButton.icon(
              label: Text('Resume'),
              icon: Icon(Icons.play_arrow),
              onPressed: _onResume,
            ),
            TextButton.icon(
              label: Text('Stop'),
              icon: Icon(Icons.stop),
              onPressed: _onStop,
            ),
            Text('--- OR ---'),
            TextButton.icon(
              label: Text('Create and start'),
              icon: Icon(Icons.playlist_play),
              onPressed: _onCreateAndStart,
            ),
          ],
        ),
      ),
    );
  }

  void _onCreate() async {
    print('Create Isolate');
    _isolateUtils = await IsolateUtils.create(_testFunction, 'Hello World');
  }

  void _onStart() async {
    print('Start Isolate');
    final _value = await _isolateUtils?.start();
    print(_value);
  }

  void _onPause() {
    print('Pause Isolate');
    _isolateUtils?.pause();
  }

  void _onResume() {
    print('Resume Isolate');
    _isolateUtils?.resume();
  }

  void _onStop() {
    print('Stop Isolate');
    _isolateUtils?.stop();
  }

  void _onCreateAndStart() async {
    print('Create And Start Isolate');
    final _value =
        await IsolateUtils.createAndStart(_testFunction, 'Hello World');
    print(_value);
  }

  static Future<String> _testFunction(String message) async {
    Timer.periodic(
        Duration(seconds: 1), (timer) => print('$message - ${timer.tick}'));
    await Future.delayed(Duration(seconds: 30));
    return '_testFunction finish';
  }
}
