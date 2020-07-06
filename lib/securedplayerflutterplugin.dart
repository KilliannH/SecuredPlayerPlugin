import 'dart:async';

import 'package:flutter/services.dart';

enum SecuredAudioPlayerState {
  /// Player is stopped. No file is loaded to the player. Calling [resume] or
  /// [pause] will result in exception.
  DESTROYED,

  /// Currently playing a file. The user can [pause], [resume] or [stop] the
  /// playback.
  PLAYING,

  /// Paused. The user can [resume] the playback without providing the URL.
  PAUSED,

  /// The playback has been completed. This state is the same as [STOPPED],
  /// however we differentiate it because some clients might want to know when
  /// the playback is done versus when the user has stopped the playback.
  COMPLETED,
}

const MethodChannel _channel = const MethodChannel('securedPlayerFlutterPlugin');

class SecuredPlayerFlutterPlugin {
  final StreamController<SecuredAudioPlayerState> _playerStateController =
  new StreamController.broadcast();

  final StreamController<Duration> _positionController =
  new StreamController.broadcast();

  SecuredAudioPlayerState _state = SecuredAudioPlayerState.DESTROYED;
  Duration _duration = const Duration();

  SecuredPlayerFlutterPlugin() {
    _channel.setMethodCallHandler(_audioPlayerStateChange);
  }

  /// Play a given url.
  Future<void> play({String url, String apiKey}) async =>
      await _channel.invokeMethod('play', {'url': url, 'api_key': apiKey});

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
      case "audio.onStart":
        _state = SecuredAudioPlayerState.PLAYING;
        _playerStateController.add(SecuredAudioPlayerState.PLAYING);
        print('PLAYING ${call.arguments}');
        _duration = new Duration(milliseconds: call.arguments);
        break;
      case "audio.onPause":
        _state = SecuredAudioPlayerState.PAUSED;
        _playerStateController.add(SecuredAudioPlayerState.PAUSED);
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

        _state = SecuredAudioPlayerState.DESTROYED;
        _playerStateController.addError(call.arguments);
        // TODO: Handle optional STOPPED STATE
        break;
      default:
        throw new ArgumentError('Unknown method ${call.method} ');
    }
  }
}
