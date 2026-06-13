/// Platform bridge for the Android floating overlay bubble.
/// The overlay allows users to trigger screen translation from anywhere.
///
/// Android: uses a foreground service with SYSTEM_ALERT_WINDOW
///          to draw a floating bubble over other apps.
/// iOS: uses App Intents + IntentsExtension for Shortcuts integration.

import 'package:flutter/services.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('ael_screen_ai/overlay');

  static const EventChannel _eventChannel =
      EventChannel('ael_screen_ai/overlay_events');

  /// Request overlay permission (Android only).
  static Future<bool> requestOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Check if overlay permission is granted.
  static Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Start the floating overlay bubble service.
  static Future<bool> startOverlay() async {
    try {
      final result = await _channel.invokeMethod<bool>('startOverlay');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Stop the floating overlay service.
  static Future<bool> stopOverlay() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopOverlay');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Check if the overlay service is running.
  static Future<bool> isOverlayRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isOverlayRunning');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Take a screenshot via Android's MediaProjection API.
  static Future<String?> takeScreenshot() async {
    try {
      final result = await _channel.invokeMethod<String>('takeScreenshot');
      return result; // base64-encoded image bytes
    } on MissingPluginException {
      return null;
    }
  }

  /// Set up listener for overlay bubble events.
  static void onBubbleTap(void Function(Map<String, dynamic>) callback) {
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        callback(Map<String, dynamic>.from(event));
      }
    });
  }

  /// Update floating bubble position.
  static Future<void> updateBubblePosition(double x, double y) async {
    try {
      await _channel.invokeMethod('updateBubblePosition', {'x': x, 'y': y});
    } on MissingPluginException {
      // no-op on non-Android
    }
  }

  /// Show a quick translation result in a small overlay window.
  static Future<void> showFloatingResult(String text) async {
    try {
      await _channel.invokeMethod('showFloatingResult', {'text': text});
    } on MissingPluginException {
      // no-op on non-Android
    }
  }

  /// Hide the floating result window.
  static Future<void> hideFloatingResult() async {
    try {
      await _channel.invokeMethod('hideFloatingResult');
    } on MissingPluginException {
      // no-op on non-Android
    }
  }
}
