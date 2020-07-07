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
  Duration _duration;
  Duration _position;

  Map<String, dynamic> httpRequest;

  SecuredPlayerFlutterPlugin _audioPlayer;

  PlayerState _playerState;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  get _durationText => _duration?.toString()?.split('.')?.first ?? '';
  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  _AudioAppState();

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.destroy();
    super.dispose();
  }

  void initAudioPlayer() async {
    _audioPlayer = SecuredPlayerFlutterPlugin();

    _audioPlayer.durationHandler = (d) => setState(() {
      _duration = d;
    });

    _audioPlayer.positionHandler = (p) => setState(() {
      _position = p;
    });

    _audioPlayer.completionHandler = () {
      _onComplete();
    };

    _audioPlayer.initializedHandler = () {
      _onInitialized();
      _playerState = PlayerState.initialized;
    };

    _audioPlayer.destroyedHandler = () {
      // impl what to do after player has been destroyed,
      // create a new one with new song in it after a skipPrev, skipNext..
    };

    _audioPlayer.errorHandler = (msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = new Duration(seconds: 0);
        _position = new Duration(seconds: 0);
      });
    };
    await _audioPlayer.init(url: 'YOUR URL HERE',
        apiKey: 'YOUR API_KEY HERE');
  }

  Future play() async {
    await _audioPlayer.play();
    setState(() {
      _playerState = PlayerState.playing;
    });
  }

  Future pause() async {
    await _audioPlayer.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Future stop() async {
    await _audioPlayer.stop();
      setState(() {
        _position = Duration();
        _playerState = PlayerState.stopped;
      });
    }

  Future skipPrev() async {
      print('go to prev song on playlist.....');
  }

  void skipNext() {
    print('go to next song on playlist......');
  }

  Future destroy() async {
    await _audioPlayer.destroy();
    setState(() {
      _playerState = PlayerState.destroyed;
    });
  }

  void _onComplete() {}

  // for now, play the song as soon as the player is initialized
  void _onInitialized() {
    play();
  }

  Future togglePause() async {
    if(_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _playerState = PlayerState.paused);
    } else {
      await _audioPlayer.play();
      setState(() => _playerState = PlayerState.playing);
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
            icon: _isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
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
        if (_duration != null)
          Slider(
          onChanged: (v) {
          final Position = v * _duration.inMilliseconds;
          _audioPlayer
              .seek(Duration(milliseconds: Position.round()));
          },
          value: (_position != null &&
          _duration != null &&
          _position.inMilliseconds > 0 &&
          _position.inMilliseconds < _duration.inMilliseconds)
          ? _position.inMilliseconds / _duration.inMilliseconds
              : 0.0,
          ),
        if (_position != null) _buildProgressView()
      ],
    ),
  );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(
      _position != null
          ? "${_positionText ?? ''} / ${_durationText ?? ''}"
          : _duration != null ? _durationText : '',
      style: TextStyle(fontSize: 24.0),
    )
  ]);
}