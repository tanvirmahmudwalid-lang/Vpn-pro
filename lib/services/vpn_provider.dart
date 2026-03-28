import 'package:flutter/services.dart';

enum VpnStatus {
  disconnected,
  connecting,
  connected,
  error
}

/**
 * VpnProvider connects the Flutter UI to the native Android VpnService.
 * It uses MethodChannel to communicate with MainActivity.kt.
 */
class VpnProvider {
  static const _channel = MethodChannel('com.btaf.meet/vpn');

  /**
   * Prepares the VPN service. This will show the system VPN connection request dialog.
   * Returns true if the user grants permission.
   */
  static Future<bool> prepare() async {
    try {
      final bool? result = await _channel.invokeMethod('prepare');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to prepare VPN: '${e.message}'.");
      return false;
    }
  }

  /**
   * Starts the VPN service.
   */
  static Future<bool> startVpn() async {
    try {
      final bool? result = await _channel.invokeMethod('start');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to start VPN: '${e.message}'.");
      return false;
    }
  }

  /**
   * Stops the VPN service.
   */
  static Future<bool> stopVpn() async {
    try {
      final bool? result = await _channel.invokeMethod('stop');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to stop VPN: '${e.message}'.");
      return false;
    }
  }

  /**
   * Gets the current status of the VPN service.
   */
  static Future<String> getStatus() async {
    try {
      final String? result = await _channel.invokeMethod('getStatus');
      return result ?? "UNKNOWN";
    } on PlatformException catch (e) {
      print("Failed to get VPN status: '${e.message}'.");
      return "ERROR";
    }
  }
}
