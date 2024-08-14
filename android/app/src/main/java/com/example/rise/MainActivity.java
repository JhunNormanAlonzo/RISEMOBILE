package com.example.rise;

import android.media.Ringtone;
import android.media.RingtoneManager;
import android.net.Uri;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import com.cloudwebrtc.webrtc.record.AudioTrackInterceptor;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.provider.Settings;
import androidx.annotation.NonNull;


public class MainActivity extends FlutterActivity {
    private Ringtone ringtone;
    private AudioTrackInterceptor audioTrackInterceptor;

    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);


        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.app/ringtone")
                .setMethodCallHandler(
                        (call, result) -> {
                            switch (call.method) {
                                case "playRingtone":
                                    playRingtone();
                                    result.success(null);
                                    break;
                                case "stopRingtone":
                                    stopRingtone();
                                    result.success(null);
                                    break;
                                default:
                                    result.notImplemented();
                                    break;
                            }
                        }
                );


        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.app/audiotrack")
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("stopAudioTrack")) {
                                stopAudioTrack();
                                result.success(null);
                            } else {
                                result.notImplemented();
                            }
                        }
                );

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.app/background_service")
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("requestIgnoreBatteryOptimizations")) {
                                boolean isIgnoringBatteryOptimizations = requestIgnoreBatteryOptimizations();
                                result.success(isIgnoringBatteryOptimizations);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }



    private boolean requestIgnoreBatteryOptimizations() {
        Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
        intent.setData(Uri.parse("package:" + getPackageName()));
        startActivity(intent);
        return true;
    }

    private void playRingtone() {
        Uri uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM);
        ringtone = RingtoneManager.getRingtone(getApplicationContext(), uri);
        if (ringtone != null) {
            ringtone.play();
        }
    }

    private void stopAudioTrack() {
        audioTrackInterceptor.stop();
    }
    private void stopRingtone() {
        if (ringtone != null && ringtone.isPlaying()) {
            ringtone.stop();
        }
    }
}
