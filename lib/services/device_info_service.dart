import 'package:flutter/services.dart';

class DeviceInfo {
  final Map<String, String> sections;

  const DeviceInfo(this.sections);
}

class DeviceInfoService {
  static const MethodChannel _channel = MethodChannel('pocketlm/device_info');

  Future<DeviceInfo> read() async {
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMapMethod<String, Object?>('getDeviceInfo');
      final Map<String, String> values = <String, String>{};
      raw?.forEach((Object? key, Object? value) {
        if (key is String) values[key] = value?.toString() ?? 'Unavailable';
      });
      return DeviceInfo(values);
    } on PlatformException {
      return const DeviceInfo(<String, String>{});
    }
  }
}
