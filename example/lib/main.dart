import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:securedplayerflutterplugin/securedplayerflutterplugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

typedef void OnError(Exception exception);

void main() {
  runApp(MaterialApp(home: Scaffold(body: AudioApp())));
}

enum PlayerState { stopped, playing, paused }

class AudioApp extends StatefulWidget {
  @override
  _AudioAppState createState() => _AudioAppState();
}

class _AudioAppState extends State<AudioApp> {
  Duration duration;
  Duration position;

  SecuredPlayerFlutterPlugin audioPlayer;

  String localFilePath;

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  void initAudioPlayer() {
    audioPlayer = SecuredPlayerFlutterPlugin();
    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => setState(() => position = p));
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
          if (s == SecuredAudioPlayerState.PLAYING) {
            setState(() => duration = audioPlayer.duration);
          } else if (s == SecuredAudioPlayerState.STOPPED) {
            onComplete();
            setState(() {
              position = duration;
            });
          }
        }, onError: (msg) {
          setState(() {
            playerState = PlayerState.stopped;
            duration = Duration(seconds: 0);
            position = Duration(seconds: 0);
          });
        });
  }

  Future play({String url, String apiKey}) async {
    await audioPlayer.play(url: url, apiKey: apiKey);
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() => playerState = PlayerState.paused);
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
      position = Duration();
    });
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Flutter SecuredAudioPlayer',
              style: textTheme.headline,
            ),
            Material(child: _buildPlayer()),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() => Container(
    padding: EdgeInsets.all(16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            onPressed: isPlaying ? null : () => play(
                url:"http://192.168.1.22:3000/api/stream/katy_perry_oliver_heldens_daisies.mp3",
                apiKey:"hello_dolly1234"),
            iconSize: 64.0,
            icon: Icon(Icons.play_arrow),
            color: Colors.cyan,
          ),
          IconButton(
            onPressed: isPlaying ? () => pause() : null,
            iconSize: 64.0,
            icon: Icon(Icons.pause),
            color: Colors.cyan,
          ),
          IconButton(
            onPressed: isPlaying || isPaused ? () => stop() : null,
            iconSize: 64.0,
            icon: Icon(Icons.stop),
            color: Colors.cyan,
          ),
        ]),
        if (duration != null)
          Slider(
              value: position?.inMilliseconds?.toDouble() ?? 0.0,
              onChanged: (double value) {
                return audioPlayer.seek((value / 1000).roundToDouble());
              },
              min: 0.0,
              max: duration.inMilliseconds.toDouble()),
        if (position != null) _buildProgressView()
      ],
    ),
  );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
    Padding(
      padding: EdgeInsets.all(12.0),
      child: CircularProgressIndicator(
        value: position != null && position.inMilliseconds > 0
            ? (position?.inMilliseconds?.toDouble() ?? 0.0) /
            (duration?.inMilliseconds?.toDouble() ?? 0.0)
            : 0.0,
        valueColor: AlwaysStoppedAnimation(Colors.cyan),
        backgroundColor: Colors.grey.shade400,
      ),
    ),
    Text(
      position != null
          ? "${positionText ?? ''} / ${durationText ?? ''}"
          : duration != null ? durationText : '',
      style: TextStyle(fontSize: 24.0),
    )
  ]);
}