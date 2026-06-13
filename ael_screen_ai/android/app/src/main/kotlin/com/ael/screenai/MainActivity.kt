package com.ael.screenai

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ael_screen_ai/overlay"
    private val EVENT_CHANNEL = "ael_screen_ai/overlay_events"
    private val REQUEST_CODE_OVERLAY = 1001
    private val REQUEST_CODE_MEDIA_PROJECTION = 1002

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivityForResult(intent, REQUEST_CODE_OVERLAY)
                        }
                    }
                    result.success(true)
                }

                "hasOverlayPermission" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else true
                    result.success(granted)
                }

                "startOverlay" -> {
                    val intent = Intent(this, OverlayService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    OverlayService.isRunning.set(true)
                    result.success(true)
                }

                "stopOverlay" -> {
                    stopService(Intent(this, OverlayService::class.java))
                    OverlayService.isRunning.set(false)
                    result.success(true)
                }

                "isOverlayRunning" -> {
                    result.success(OverlayService.isRunning.get())
                }

                "takeScreenshot" -> {
                    // Request media projection permission first
                    val mgr = getSystemService(MEDIA_PROJECTION_SERVICE)
                            as android.media.projection.MediaProjectionManager
                    startActivityForResult(
                        mgr.createScreenCaptureIntent(),
                        REQUEST_CODE_MEDIA_PROJECTION
                    )
                    result.success(null)
                }

                "showFloatingResult" -> {
                    result.success(null)
                }

                "hideFloatingResult" -> {
                    result.success(null)
                }

                "updateBubblePosition" -> {
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_CODE_MEDIA_PROJECTION -> {
                if (resultCode == RESULT_OK && data != null) {
                    OverlayService.setupProjection(resultCode, data)
                    // Start capture
                    val intent = Intent(this, OverlayService::class.java)
                    startService(intent)
                }
            }
        }
    }
}
