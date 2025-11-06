import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum NoteType { quarter, eighth, triplet, sixteenth }

void main() => runApp(const MetronomeApp());

class MetronomeApp extends StatelessWidget {
  const MetronomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Метроном',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MetronomeHomePage(),
    );
  }
}

class MetronomeHomePage extends StatefulWidget {
  const MetronomeHomePage({super.key});

  @override
  State<MetronomeHomePage> createState() => _MetronomeHomePageState();
}

class _MetronomeHomePageState extends State<MetronomeHomePage> {
  int bpm = 60;
  bool isPlaying = false;
  bool isCountingIn = false;
  Timer? _timer;
  NoteType _noteType = NoteType.quarter;
  int _currentBeat = 0;
  int _countInBeat = 0;
  int beatsPerMeasure = 4; // For visualization
  int ticksInMeasure = 4; // Number of ticks per measure

  final AudioPlayer _strongPlayer = AudioPlayer();
  final AudioPlayer _weakPlayer = AudioPlayer();
  final AudioPlayer _countInPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _strongPlayer.setReleaseMode(ReleaseMode.stop);
    _weakPlayer.setReleaseMode(ReleaseMode.stop);
    _countInPlayer.setReleaseMode(ReleaseMode.stop);
  }

  void _updateTicksInMeasure() {
    switch (_noteType) {
      case NoteType.quarter:
        ticksInMeasure = 4;
        break;
      case NoteType.eighth:
        ticksInMeasure = 8;
        break;
      case NoteType.triplet:
        ticksInMeasure = 12;
        break;
      case NoteType.sixteenth:
        ticksInMeasure = 16;
        break;
    }
  }

  Future<void> _startCountIn() async {
    setState(() {
      isCountingIn = true;
      _countInBeat = 0;
      _currentBeat = -1;
    });

    int intervalMs = (60000 / bpm).round();
    for (int i = 0; i < beatsPerMeasure; i++) {
      setState(() {
        _countInBeat = i;
      });
      await _countInPlayer.play(AssetSource('1234.mp3'));
      await Future.delayed(Duration(milliseconds: intervalMs));
    }

    setState(() {
      isCountingIn = false;
      _countInBeat = 0;
      _currentBeat = 0; // Первый удар
    });

    await _playTick(0);
    _startMetronome(firstBeat: true);
  }

  Future<void> _playTick(int tickNum) async {
    if (_noteType == NoteType.quarter) {
      await _strongPlayer.play(AssetSource('click_main.mp3'));
    } else if (_noteType == NoteType.eighth) {
      if (tickNum % 2 == 0) {
        await _strongPlayer.play(AssetSource('click_main.mp3'));
      } else {
        await _weakPlayer.play(AssetSource('click_weak.mp3'));
      }
    } else if (_noteType == NoteType.triplet) {
      if (tickNum % 3 == 0) {
        await _strongPlayer.play(AssetSource('click_main.mp3'));
      } else {
        await _weakPlayer.play(AssetSource('click_weak.mp3'));
      }
    } else if (_noteType == NoteType.sixteenth) {
      if (tickNum % 4 == 0) {
        await _strongPlayer.play(AssetSource('click_main.mp3'));
      } else {
        await _weakPlayer.play(AssetSource('click_weak.mp3'));
      }
    }
  }

  void _startMetronome({bool firstBeat = false}) {
    _updateTicksInMeasure();
    Duration interval;
    switch (_noteType) {
      case NoteType.quarter:
        interval = Duration(milliseconds: (60000 / bpm).round());
        break;
      case NoteType.eighth:
        interval = Duration(milliseconds: (60000 / bpm / 2).round());
        break;
      case NoteType.triplet:
        interval = Duration(milliseconds: (60000 / bpm / 3).round());
        break;
      case NoteType.sixteenth:
        interval = Duration(milliseconds: (60000 / bpm / 4).round());
        break;
    }
    _timer = Timer.periodic(interval, (timer) async {
      setState(() {
        _currentBeat = (_currentBeat + 1) % ticksInMeasure;
      });
      await _playTick(_currentBeat);
    });
    setState(() {
      isPlaying = true;
      if (!firstBeat) _currentBeat = 0;
    });
  }

  void _stopMetronome() {
    _timer?.cancel();
    setState(() {
      isPlaying = false;
      _currentBeat = 0;
      isCountingIn = false;
      _countInBeat = 0;
    });
  }

  void _toggleMetronome() {
    if (isPlaying || isCountingIn) {
      _stopMetronome();
    } else {
      _startCountIn();
    }
  }

  void _setNoteType(NoteType type) {
    setState(() {
      _noteType = type;
    });
    if (isPlaying) {
      _stopMetronome();
      _startCountIn();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _strongPlayer.dispose();
    _weakPlayer.dispose();
    _countInPlayer.dispose();
    super.dispose();
  }

  Widget _buildBpmSlider() {
    return Column(
      children: [
        Text('$bpm BPM', style: const TextStyle(fontSize: 20)),
        Slider(
          value: bpm.toDouble(),
          min: 10,
          max: 220,
          divisions: 210,
          label: bpm.toString(),
          onChanged: (value) {
            setState(() {
              bpm = value.round();
            });
            if (isPlaying) {
              _stopMetronome();
              _startCountIn();
            }
          },
        ),
      ],
    );
  }

  Widget _buildNoteTypeControl() {
    final noteTypes = [
      {
        'type': NoteType.quarter,
        'asset': 'assets/fourth_notes.png',
        'label': '4-ые ноты',
      },
      {
        'type': NoteType.eighth,
        'asset': 'assets/eighth_notes.png',
        'label': '8-ые ноты',
      },
      {
        'type': NoteType.triplet,
        'asset': 'assets/triplet.png',
        'label': '8-ые триоли',
      },
      {
        'type': NoteType.sixteenth,
        'asset': 'assets/sixteens_notes.png',
        'label': '16-ые ноты',
      },
    ];

    return Wrap(
      spacing: 20,
      runSpacing: 16,
      children: noteTypes.map((note) {
        final isSelected = _noteType == note['type'];
        return Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _setNoteType(note['type'] as NoteType),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: Colors.amber, width: 4)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ]
                      : [],
                ),
                child: Padding(
                  padding: EdgeInsets.all(8), // Отступ для вписывания картинки
                  child: Image.asset(
                    note['asset'] as String,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain, // Вписывает картинку в квадрат
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              note['label'] as String,
              style: TextStyle(
                fontSize: 20,
                color: isSelected ? Colors.amber[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBeatIndicators() {
    _updateTicksInMeasure();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(beatsPerMeasure, (i) {
        bool isActive = false;
        if (isCountingIn && i == _countInBeat) {
          isActive = true;
        } else if (isPlaying) {
          switch (_noteType) {
            case NoteType.quarter:
              isActive = (_currentBeat == i);
              break;
            case NoteType.eighth:
              isActive = (_currentBeat ~/ 2 == i);
              break;
            case NoteType.triplet:
              isActive = (_currentBeat ~/ 3 == i);
              break;
            case NoteType.sixteenth:
              isActive = (_currentBeat ~/ 4 == i);
              break;
          }
        }
        Color color = isActive
            ? (isCountingIn ? Colors.green : Colors.blue)
            : Colors.grey;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Метроном')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBpmSlider(),
            const SizedBox(height: 20),
            _buildNoteTypeControl(),
            const SizedBox(height: 40),
            _buildBeatIndicators(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _toggleMetronome,
              child: Text((isPlaying || isCountingIn) ? 'Стоп' : 'Старт'),
            ),
          ],
        ),
      ),
    );
  }
}
