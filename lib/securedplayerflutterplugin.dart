import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';

typedef void TimeChangeHandler(Duration duration);
typedef void ErrorHandler(String message);

const MethodChannel _channel = const MethodChannel('securedPlayerFlutterPlugin');

class SecuredPlayerFlutterPlugin {

  /// This handler returns the duration of the file, when it's available (it might take a while because it's being downloaded or buffered).
  TimeChangeHandler durationHandler;

  /// This handler updates the current position of the audio. You can use it to make a progress bar, for instance.
  TimeChangeHandler positionHandler;

  /// This handler is called when the audio finishes playing; it's used in the loop method, for instance.
  ///
  /// It does not fire when you interrupt the audio with pause or stop.
  VoidCallback completionHandler;

  /// This is called when an unexpected error is thrown in the native code.
  ErrorHandler errorHandler;
  SecuredPlayerFlutterPlugin() {
    _channel.setMethodCallHandler(_audioPlayerStateChange);
  }

  /// init player with a given url.
  Future<void> init({String url, String apiKey}) async =>
      await _channel.invokeMethod('init', {'url': url, 'api_key': apiKey});


  Future<void> play() async => await _channel.invokeMethod('play');

  // fake stop as it pauses te stream an seek it to 0.
  Future<void> stop() async => await _channel.invokeMethod('stop');

  /// Pause the currently playing stream.
  Future<void> pause() async => await _channel.invokeMethod('pause');

  Future<int> seek(Duration position) {
    double positionInSeconds =
        position.inMicroseconds / Duration.microsecondsPerSecond;
    return _channel.invokeMethod('seek', {'position': positionInSeconds});
  }

  /// Destroy the player.
  Future<void> destroy() async => await _channel.invokeMethod('destroy');

  Future<void> _audioPlayerStateChange(MethodCall call) async {
    dynamic value = call.arguments;
    print(value);
    switch (call.method) {
      case "audio.onDuration":
        if (this.durationHandler != null) {
          await this.durationHandler(new Duration(milliseconds: value));
        }
        break;
      case "audio.onCurrentPosition":
        if (this.positionHandler != null) {
          await this.positionHandler(new Duration(milliseconds: value));
        }
        break;
      case 'audio.onComplete':
        if (this.completionHandler != null) {
          await this.completionHandler();
        }
        break;
      case 'audio.onError':
        if (this.errorHandler != null) {
          await this.errorHandler(value);
        }
        break;
        // first call to initiate slider & timers as soon as player is initialized
      case "player.initialized":
        this.durationHandler(new Duration(milliseconds: value));
        print('PLAYER DESTROYED');
        break;
      case "player.destroyed":
        print('PLAYER DESTROYED');
        break;

        ///// function calls for debug purposes /////
      case "audio.onStart":
        print('ON START');
        break;
      case "audio.onPause":
        print('ON PAUSE');
        break;
      case "audio.onStop":
        print('ON STOP');
        break;
      case "audio.onComplete":
        print("ON COMPLETE");
        break;
        ///// endof debug functions /////

      default:
        throw new ArgumentError('Unknown method ${call.method} ');
    }
  }
}
