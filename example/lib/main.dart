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

enum PlayerState { destroyed, initialized, stopped, playing, paused }

class AudioApp extends StatefulWidget {
  @override
  _AudioAppState createState() => _AudioAppState();
}

class _AudioAppState extends State<AudioApp> {
  Duration duration;
  Duration position;

  Map<String, dynamic> httpRequest;

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
    audioPlayer.destroy();
    super.dispose();
  }

  void initAudioPlayer() async {
    audioPlayer = SecuredPlayerFlutterPlugin();
    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => setState(() => position = p));
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
          if (s == SecuredAudioPlayerState.INITIALIZED) {
            onInitialized();
          } else if (s == SecuredAudioPlayerState.PLAYING) {
            setState(() => duration = audioPlayer.duration);
          }
        }, onError: (msg) {
          setState(() {
            // assumes that player is stopped on error
            playerState = PlayerState.stopped;
            duration = Duration(seconds: 0);
            position = Duration(seconds: 0);
          });
        });
    await audioPlayer.init(url: 'YOUR URL HERE', apiKey: 'YOUR API_KEY HERE');
    playerState = PlayerState.initialized;
  }

  Future play() async {
    await audioPlayer.play();
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
      position = Duration();
      playerState = PlayerState.stopped;
    });
    // will pass through listener setup on init function above
    // so will call position = Duration();
  }

  Future skipPrev() async {
      print('go to prev song on playlist.....');
  }

  void skipNext() {
    print('go to next song on playlist......');
  }

  Future destroy() async {
    await audioPlayer.destroy();
    setState(() {
      playerState = PlayerState.destroyed;
    });
  }

  void onComplete() {}

  // for now, play the song as soon as the player is initialized
  void onInitialized() => play();

  Future togglePause() async {
    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => setState(() => position = p));
    if(isPlaying) {
      await audioPlayer.pause();
      setState(() => playerState = PlayerState.paused);
    } else {
      await audioPlayer.play();
      setState(() => playerState = PlayerState.playing);
    }
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
      Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
            iconSize: 32,
            icon: Icon(Icons.stop),
            onPressed: () {
              stop();
            }
        ),
        IconButton(
            iconSize: 32,
            icon: isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            onPressed: () {
              setState(() {
                togglePause();
              });
            }
        ),
        IconButton(
            iconSize: 32,
            icon: Icon(Icons.skip_next),
            onPressed: () {
              skipNext();
            }
        )
      ],
    ),
        if (duration != null)
          Slider(
              value: position?.inMilliseconds?.toDouble() ?? 0.0,
              onChanged: null,
              min: 0.0,
              max: duration.inMilliseconds.toDouble()),
        if (position != null) _buildProgressView()
      ],
    ),
  );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(
      position != null
          ? "${positionText ?? ''} / ${durationText ?? ''}"
          : duration != null ? durationText : '',
      style: TextStyle(fontSize: 24.0),
    )
  ]);
}