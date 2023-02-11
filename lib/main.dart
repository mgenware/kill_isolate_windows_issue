import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simple_isolate/simple_isolate.dart';
import 'package:tmp_path/tmp_path.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SimpleIsolate<void>? _myIsolate;
  String _output = '';

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            OutlinedButton(
                onPressed: _start, child: const Text('Start isolate')),
            OutlinedButton(onPressed: _stop, child: const Text('Stop isolate')),
            Text(_output),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _start() async {
    var tmpFile = tmpPath();
    try {
      _myIsolate = await SimpleIsolate.spawn<void>(
        (SIContext ctx) async {
          var destFile = ctx.argument as String;
          var stream = File(destFile).openWrite();
          for (var i = 0; i < 100; i++) {
            ctx.sendMsg('write data', {'i': i});
            stream.add([i]);
            await stream.flush();
            await Future<void>.delayed(const Duration(seconds: 1));
          }
        },
        tmpFile,
        onMsgReceived: (msg) {
          setState(() {
            _output = msg.toString();
          });
        },
      );

      await _myIsolate!.future;
    } on SimpleIsolateAbortException catch (_) {
      try {
        var file = File(tmpFile);
        if (await file.exists()) {
          await file.delete();
          setState(() {
            _output = 'Deleted cancelled file: $tmpFile';
          });
        } else {
          setState(() {
            _output = 'File not found: $tmpFile';
          });
        }
      } catch (err) {
        setState(() {
          _output = 'Error deleting file $tmpFile: $err';
        });
      }
    } catch (err) {
      setState(() {
        _output = err.toString();
      });
    }
  }

  void _stop() {
    assert(_myIsolate != null);
    _myIsolate?.core.kill();
  }
}
