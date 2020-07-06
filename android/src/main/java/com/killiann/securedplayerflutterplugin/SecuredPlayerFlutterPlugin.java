package com.killiann.securedplayerflutterplugin;

import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.io.IOException;
import java.util.HashMap;
import java.util.Objects;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** SecuredPlayerFlutterPlugin */
public class SecuredPlayerFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String ID = "securedPlayerFlutterPlugin";

  private MethodChannel channel;
  private AudioManager am;
  private final Handler handler = new Handler();
  private MediaPlayer mediaPlayer;
  private Context mContext;

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    SecuredPlayerFlutterPlugin instance = new SecuredPlayerFlutterPlugin();
    instance.initInstance(registrar.messenger(), registrar.context());
  }

  private void initInstance(BinaryMessenger binaryMessenger, Context context) {
    mContext = context;
    channel = new MethodChannel(binaryMessenger, ID);
    channel.setMethodCallHandler(this);
    am = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
  }

  @RequiresApi(api = Build.VERSION_CODES.KITKAT)
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "init":
        init(Objects.requireNonNull(call.argument("url")).toString(), Objects.requireNonNull(call.argument("api_key").toString()));
        result.success(null);
        break;
      case "play":
        play();
        result.success(null);
        break;
      case "stop":
        stop();
        result.success(null);
        break;
      case "pause":
        pause();
        result.success(null);
        break;
      case "destroy":
        destroy();
        result.success(null);
        break;
      default:
        result.notImplemented();
    }
  }

  private void destroy() {
    handler.removeCallbacks(sendData);
    if (mediaPlayer != null) {
      mediaPlayer.stop();
      mediaPlayer.release();
      mediaPlayer = null;
      channel.invokeMethod("player.destroyed", null);
    }
  }

  private void pause() {
    handler.removeCallbacks(sendData);
    if (mediaPlayer != null) {
      mediaPlayer.pause();
      channel.invokeMethod("audio.onPause", true);
    }
  }

  private void stop() {
    if (mediaPlayer != null) {
      mediaPlayer.pause();
      mediaPlayer.seekTo(0);
      channel.invokeMethod("audio.onStop", null);
    }
    handler.removeCallbacks(sendData);
  }

  private void play() {
    if(mediaPlayer != null) {
      mediaPlayer.start();
      channel.invokeMethod("audio.onStart", mediaPlayer.getDuration());
      handler.post(sendData);
    } else {
      Log.w("mediaPlayer", "error on play(), mediaPlayer is not defined");
    }
  }

  private void init(String url, String api_key) {
    if (mediaPlayer == null) {
      mediaPlayer = new MediaPlayer();
      mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);

      HashMap<String, String> headers = new HashMap<String, String>();
      headers.put("Authorization", api_key);

      Uri uri = Uri.parse(url);

      try {
        mediaPlayer.setDataSource(mContext, uri, headers);
      } catch (IOException e) {
        Log.w(ID, "Invalid DataSource", e);
        channel.invokeMethod("audio.onError", "Invalid Datasource");
        return;
      }
      mediaPlayer.prepareAsync();

      mediaPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener(){
        @Override
        public void onPrepared(MediaPlayer mp) {
          channel.invokeMethod("player.initialized", null);
          mediaPlayer.start();
          channel.invokeMethod("audio.onStart", mediaPlayer.getDuration());
        }
      });

      mediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener(){
        @Override
        public void onCompletion(MediaPlayer mp) {
          // todo impl stop();
          stop();
          channel.invokeMethod("audio.onComplete", null);
        }
      });
      mediaPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener(){
        @Override
        public boolean onError(MediaPlayer mp, int what, int extra) {
          channel.invokeMethod("audio.onError", String.format("{\"what\":%d,\"extra\":%d}", what, extra));
          return true;
        }
      });
    } else {
      Log.w("mediaPlayer", "error on init(), mediaPlayer is already initialized");
    }
    handler.post(sendData);
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    initInstance(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
    am = null;
  }

  private final Runnable sendData = new Runnable(){
    public void run(){
      try {
        if (!mediaPlayer.isPlaying()) {
          handler.removeCallbacks(sendData);
        }
        int time = mediaPlayer.getCurrentPosition();
        channel.invokeMethod("audio.onCurrentPosition", time);
        handler.postDelayed(this, 200);
      }
      catch (Exception e) {
        Log.w(ID, "When running handler", e);
      }
    }
  };
}
