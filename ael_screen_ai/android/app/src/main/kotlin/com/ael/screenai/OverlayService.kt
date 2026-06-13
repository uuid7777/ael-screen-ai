package com.ael.screenai

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.view.*
import android.widget.*
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Android foreground service that draws a floating bubble overlay.
 * The bubble can be dragged around and tapped to trigger screen capture + translation.
 */
class OverlayService : Service() {
    companion object {
        const val CHANNEL = "ael_screen_ai/overlay"
        const val EVENT_CHANNEL = "ael_screen_ai/overlay_events"
        const val NOTIFICATION_ID = 1001
        const val OVERLAY_TAG = "AEL_Overlay"
        var isRunning = AtomicBoolean(false)
            private set
        var mediaProjection: MediaProjection? = null
            private set
        var resultCode: Int = 0
            private set
        var resultData: Intent? = null
            private set

        fun setupProjection(code: Int, data: Intent) {
            resultCode = code
            resultData = data
        }
    }

    private lateinit var windowManager: WindowManager
    private var bubbleView: View? = null
    private var resultView: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var resultParams: WindowManager.LayoutParams? = null
    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var channel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private val displayManager by lazy { getSystemService(DISPLAY_SERVICE) as DisplayManager }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())

        if (bubbleView == null) {
            createBubbleOverlay()
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopProjection()
        removeOverlays()
        isRunning.set(false)
        super.onDestroy()
    }

    private fun createNotification(): Notification {
        val channelId = "ael_screen_ai_overlay"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId, "Floating Bubble",
                NotificationManager.IMPORTANCE_LOW
            ).apply { setShowBadge(false) }
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("AEL Screen AI")
            .setContentText("Floating bubble active - tap to translate")
            .setSmallIcon(android.R.drawable.ic_menu_edit)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createBubbleOverlay() {
        val density = resources.displayMetrics.density
        val bubbleSize = (48 * density).toInt()

        bubbleView = LayoutInflater.from(this).inflate(R.layout.overlay_bubble, null).apply {
            setOnTouchListener(BubbleTouchListener())
            setOnClickListener {
                captureAndTranslate()
            }
        }

        params = WindowManager.LayoutParams(
            bubbleSize, bubbleSize,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                    or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = metrics.displayMetrics.heightPixels / 3
        }

        try {
            windowManager.addView(bubbleView, params)
        } catch (e: Exception) {
            stopSelf()
        }
    }

    private inner class BubbleTouchListener : View.OnTouchListener {
        private var initialX = 0
        private var initialY = 0
        private var initialTouchX = 0f
        private var initialTouchY = 0f
        private var isMoving = false

        override fun onTouch(v: View, event: MotionEvent): Boolean {
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params?.x ?: 0
                    initialY = params?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isMoving = false
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(dx) > 10 || Math.abs(dy) > 10) isMoving = true
                    params?.x = initialX + dx
                    params?.y = initialY + dy
                    try { windowManager.updateViewLayout(bubbleView, params) } catch (_: Exception) {}
                    return true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isMoving) v.performClick()
                    return true
                }
            }
            return false
        }
    }

    private fun captureAndTranslate() {
        if (!initProjection()) return

        try {
            val metrics = metrics
            imageReader = ImageReader.newInstance(
                metrics.widthPixels, metrics.heightPixels,
                PixelFormat.RGBA_8888, 2
            )

            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "ScreenCapture",
                metrics.widthPixels, metrics.heightPixels,
                metrics.densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface, null, null
            )

            handler.postDelayed({
                val image = imageReader?.acquireLatestImage()
                if (image != null) {
                    val bitmap = imageToBitmap(image)
                    image.close()
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
                    val base64 = android.util.Base64.encodeToString(
                        stream.toByteArray(), android.util.Base64.NO_WRAP
                    )

                    // Send to Flutter via method result
                    channel?.invokeMethod("onScreenshot", mapOf(
                        "image" to base64,
                        "width" to bitmap.width,
                        "height" to bitmap.height,
                    ))
                }
                stopProjection()
            }, 300)

            // Show result window
            showResultOverlay("Translating...")

        } catch (e: Exception) {
            stopProjection()
        }
    }

    private fun showResultOverlay(text: String) {
        removeResultOverlay()
        val tv = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 16f
            setPadding(24, 16, 24, 16)
            setText(text)
            setBackgroundColor(Color.argb(220, 30, 30, 50))
        }

        resultParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 40
            y = 40
        }

        resultView = tv
        try { windowManager.addView(tv, resultParams) } catch (_: Exception) {}
    }

    private val metrics: DisplayMetrics
        get() = resources.displayMetrics

    private fun initProjection(): Boolean {
        if (mediaProjection != null) return true
        if (resultCode == 0 || resultData == null) return false

        val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = mgr.getMediaProjection(resultCode, resultData!!)
        return mediaProjection != null
    }

    private fun stopProjection() {
        virtualDisplay?.release()
        virtualDisplay = null
        imageReader?.close()
        imageReader = null
    }

    private fun removeOverlays() {
        bubbleView?.let { try { windowManager.removeView(it) } catch (_: Exception) {} }
        removeResultOverlay()
    }

    private fun removeResultOverlay() {
        resultView?.let { try { windowManager.removeView(it) } catch (_: Exception) {} }
        resultView = null
    }

    private fun imageToBitmap(image: android.media.Image): Bitmap {
        val planes = image.planes
        val buffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * image.width

        val bitmap = Bitmap.createBitmap(
            image.width + rowPadding / pixelStride,
            image.height, Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        return Bitmap.createBitmap(bitmap, 0, 0, image.width, image.height)
    }

    companion object {
        val metrics: DisplayMetrics
            get() = TODO()
    }
}

// Extension to access context resources
private val Service.metrics: DisplayMetrics
    get() = resources.displayMetrics

// Layout for overlay bubble
// This is defined inline in the code for simplicity,
// but should be moved to res/layout/overlay_bubble.xml in production
// with a circular white background and AEL icon.
