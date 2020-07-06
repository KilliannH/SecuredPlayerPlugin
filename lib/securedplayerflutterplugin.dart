import 'dart:async';

import 'package:flutter/services.dart';

enum SecuredAudioPlayerState {
  DESTROYED,
  INITIALIZED,
  STOPPED,
  PLAYING,
  PAUSED,
  COMPLETED,
}

const MethodChannel _channel = const MethodChannel('securedPlayerFlutterPlugin');

class SecuredPlayerFlutterPlugin {
  final StreamController<SecuredAudioPlayerState> _playerStateController =
  new StreamController.broadcast();

  final StreamController<Duration> _positionController =
  new StreamController.broadcast();

  SecuredAudioPlayerState _state = SecuredAudioPlayerState.STOPPED;
  Duration _duration = const Duration();

  SecuredPlayerFlutterPlugin() {
    _channel.setMethodCallHandler(_audioPlayerStateChange);
  }

  /// init player with a given url.
  Future<void> init({String url, String apiKey}) async =>
      await _channel.invokeMethod('init', {'url': url, 'api_key': apiKey});


  Future<void> play() async => await _channel.invokeMethod('play');

  Future<void> stop() async => await _channel.invokeMethod('stop');

  /// Pause the currently playing stream.
  Future<void> pause() async => await _channel.invokeMethod('pause');

  /// Destroy the player.
  Future<void> destroy() async => await _channel.invokeMethod('destroy');

  /// Stream for subscribing to player state change events.
  Stream<SecuredAudioPlayerState> get onPlayerStateChanged =>
      _playerStateController.stream;

  /// Reports what the player is currently doing.
  SecuredAudioPlayerState get state => _state;

  /// Reports the duration of the current media being played. It might return
  /// 0 if we have not determined the length of the media yet. It is best to
  /// call this from a state listener when the state has become
  /// [AudioPlayerState.PLAYING].
  Duration get duration => _duration;

  /// Stream for subscribing to audio position change events. Roughly fires
  /// every 200 milliseconds. Will continously update the position of the
  /// playback if the status is [AudioPlayerState.PLAYING].
  Stream<Duration> get onAudioPositionChanged => _positionController.stream;

  Future<void> _audioPlayerStateChange(MethodCall call) async {
    switch (call.method) {
      case "audio.onCurrentPosition":
        assert(_state == SecuredAudioPlayerState.PLAYING);
        _positionController.add(new Duration(milliseconds: call.arguments));
        break;
      case "player.initialized":
        _state = SecuredAudioPlayerState.INITIALIZED;
        _playerStateController.add(SecuredAudioPlayerState.INITIALIZED);
        print('PLAYER INITIALIZED');
        break;
      case "player.destroyed":
        _state = SecuredAudioPlayerState.DESTROYED;
        _playerStateController.add(SecuredAudioPlayerState.DESTROYED);
        print('PLAYER DESTROYED');
        break;
      case "audio.onStart":
        _state = SecuredAudioPlayerState.PLAYING;
        _playerStateController.add(SecuredAudioPlayerState.PLAYING);
        print('ON START');
        _duration = new Duration(milliseconds: call.arguments);
        break;
      case "audio.onPause":
        _state = SecuredAudioPlayerState.PAUSED;
        _playerStateController.add(SecuredAudioPlayerState.PAUSED);
        print('ON PAUSE');
        break;
      case "audio.onStop":
        _state = SecuredAudioPlayerState.STOPPED;
        _playerStateController.add(SecuredAudioPlayerState.STOPPED);
        print('ON STOP');
        break;
      case "audio.onDestroy":
        _state = SecuredAudioPlayerState.DESTROYED;
        _playerStateController.add(SecuredAudioPlayerState.DESTROYED);
        break;
      case "audio.onComplete":
        _state = SecuredAudioPlayerState.COMPLETED;
        _playerStateController.add(SecuredAudioPlayerState.COMPLETED);
        break;
      case "audio.onError":
      // If there's an error, we assume the player has stopped.
        _state = SecuredAudioPlayerState.STOPPED;
        _playerStateController.addError(call.arguments);
        break;
      default:
        throw new ArgumentError('Unknown method ${call.method} ');
    }
  }
}
