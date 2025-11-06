import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(MetronomeApp());

class MetronomeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Метро́ном',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MetronomeHomePage(),
    );
  }
}

class MetronomeHomePage extends StatefulWidget {
  @override
  _MetronomeHomePageState createState() => _MetronomeHomePageState();
}

class _MetronomeHomePageState extends State<MetronomeHomePage> {
  int bpm = 60;
  bool isPlaying = false;
  Timer? timer;
  final player = AudioPlayer();

  void startMetronome() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: (60000 ~/ bpm)), (Timer t) {
      player.play(AssetSource('click.wav'));
    });
    setState(() {
      isPlaying = true;
    });
  }

  void stopMetronome() {
    timer?.cancel();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Простой метроном')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('BPM: $bpm', style: TextStyle(fontSize: 32)),
            Slider(
              value: bpm.toDouble(),
              min: 30,
              max: 240,
              divisions: 210,
              label: bpm.toString(),
              onChanged: (double value) {
                setState(() {
                  bpm = value.toInt();
                  if (isPlaying) {
                    startMetronome();
                  }
                });
              },
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: isPlaying ? stopMetronome : startMetronome,
              child: Text(
                isPlaying ? 'Стоп' : 'Старт',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
