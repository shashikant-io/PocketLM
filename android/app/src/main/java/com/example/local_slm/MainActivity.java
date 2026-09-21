package com.example.local_slm;

import android.app.ActivityManager;
import android.content.Context;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "pocketlm/device_info";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (!"getDeviceInfo".equals(call.method)) {
                        result.notImplemented();
                        return;
                    }

                    ActivityManager.MemoryInfo memoryInfo = new ActivityManager.MemoryInfo();
                    ActivityManager activityManager =
                            (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
                    activityManager.getMemoryInfo(memoryInfo);

                    Map<String, String> deviceInfo = new HashMap<>();
                    deviceInfo.put("deviceName", Build.MANUFACTURER + " " + Build.MODEL);
                    deviceInfo.put("androidVersion", "Android " + Build.VERSION.RELEASE);
                    deviceInfo.put("architecture", Build.SUPPORTED_ABIS.length > 0
                            ? Build.SUPPORTED_ABIS[0] : "Unavailable");
                    deviceInfo.put("totalMemory", formatBytes(memoryInfo.totalMem));
                    String deviceId = Settings.Secure.getString(
                            getContentResolver(), Settings.Secure.ANDROID_ID);
                    deviceInfo.put("deviceId", deviceId != null ? deviceId : "Unavailable");
                    deviceInfo.put("cpuCores", String.valueOf(Runtime.getRuntime().availableProcessors()));
                    deviceInfo.put("chipset", Build.HARDWARE);
                    deviceInfo.put("instructionSupport", joinAbis());
                    deviceInfo.put("gpuType", "Unavailable");
                    deviceInfo.put("renderer", "Unavailable");
                    deviceInfo.put("vendor", "Unavailable");
                    deviceInfo.put("openCl", "Unavailable");
                    deviceInfo.put("dsp", "Unavailable");
                    result.success(deviceInfo);
                });
    }

    private String joinAbis() {
        StringBuilder result = new StringBuilder();
        for (int index = 0; index < Build.SUPPORTED_ABIS.length; index++) {
            if (index > 0) {
                result.append(", ");
            }
            result.append(Build.SUPPORTED_ABIS[index]);
        }
        return result.toString();
    }

    private String formatBytes(long bytes) {
        return String.format("%.1f GB", bytes / 1024.0 / 1024.0 / 1024.0);
    }
}