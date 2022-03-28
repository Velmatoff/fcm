import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:background_fetch/background_fetch.dart';

const uri = 'http://192.168.31.159:3333/';

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');

  final url = Uri.parse(uri);

  try {
    final response = await http.get(url);
    print(response.body);
  } catch (e) {
    print(e);
  }

  BackgroundFetch.finish(taskId);
}

void main() {
  runApp(const MyApp());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];

  @override
  void initState() {
    _events.insert(0, DateTime.now());
    initPlatformState();
    super.initState();
  }

  Future<void> initPlatformState() async {
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 1,
            forceAlarmManager: true,
            startOnBoot: true,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY), (String taskId) async {
      print("[BackgroundFetch] Event received $taskId");

      final url = Uri.parse(uri);

      try {
        final response = await http.get(url);
        print(response.body);
      } catch (e) {
        print(e);
      }

      setState(() {
        _events.insert(0, DateTime.now());
      });

      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');
    setState(() {
      _status = status;
    });

    if (!mounted) return;
  }

  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }

  void _onClickStatus() async {
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status: $status');
    setState(() {
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            title: const Text('BackgroundFetch Example', style: TextStyle(color: Colors.black)),
            actions: <Widget>[
              Switch(value: _enabled, onChanged: _onClickEnable),
            ]),
        body: ListView.builder(
            itemCount: _events.length,
            itemBuilder: (BuildContext context, int index) {
              DateTime timestamp = _events[index];
              return InputDecorator(
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 10.0, top: 10.0, bottom: 0.0),
                      labelStyle: TextStyle(color: Colors.amberAccent, fontSize: 20.0),
                      labelText: "[background fetch event]"),
                  child: Text(timestamp.toString(), style: const TextStyle(color: Colors.white, fontSize: 16.0)));
            }),
        bottomNavigationBar: BottomAppBar(
            child: Row(children: <Widget>[
          RaisedButton(onPressed: _onClickStatus, child: const Text('Status')),
          Container(child: Text("$_status"), margin: const EdgeInsets.only(left: 20.0))
        ])),
      ),
    );
  }
}
