package com.gasong.ga_song

import android.app.PictureInPictureParams
import android.os.PowerManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.util.Rational
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val PIP_CHANNEL = "com.gasong.ga_song/pip"
        private const val DEEP_LINK_CHANNEL = "com.gasong.ga_song/deep_link"
        private const val POWER_CHANNEL = "com.gasong.ga_song/power"
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    private var pipMethodChannel: MethodChannel? = null
    private var deepLinkMethodChannel: MethodChannel? = null
    private var powerMethodChannel: MethodChannel? = null

    // ─── Battery state cache ─────────────────────────────────────────────────
    // Real BroadcastReceiver caches fresh battery values for MethodChannel queries.
    private var cachedBatteryLevel = -1
    private var cachedIsCharging = true
    private var batteryReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ─── PiP MethodChannel ────────────────────────────────────────────────
        pipMethodChannel = MethodChannel(messenger, PIP_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "enterPiP" -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val aspectRatio = Rational(16, 9)
                                val params = PictureInPictureParams.Builder()
                                    .setAspectRatio(aspectRatio)
                                    .build()
                                val success = enterPictureInPictureMode(params)
                                result.success(success)
                            } else {
                                result.error(
                                    "UNSUPPORTED",
                                    "PiP requires Android 8.0 (API 26) or higher",
                                    null
                                )
                            }
                        }
                        "isPiPSupported" -> {
                            result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "PiP MethodChannel error: ${e.message}", e)
                    result.error("PIP_ERROR", e.message, null)
                }
            }
        }

        // ─── Deep Link MethodChannel ──────────────────────────────────────────
        deepLinkMethodChannel = MethodChannel(messenger, DEEP_LINK_CHANNEL)

        // ─── Power State MethodChannel ────────────────────────────────────────
        // Exposes PowerManager.isPowerSaveMode + battery status to Flutter.
        registerBatteryReceiver()
        powerMethodChannel = MethodChannel(messenger, POWER_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "powerState" -> {
                            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                            val isPowerSaving = pm.isPowerSaveMode
                            result.success(
                                mapOf(
                                    "isPowerSaving" to isPowerSaving,
                                    "isCharging" to cachedIsCharging,
                                    "level" to cachedBatteryLevel
                                )
                            )
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Power MethodChannel error: ${e.message}", e)
                    result.error("POWER_ERROR", e.message, null)
                }
            }
        }
    }

    /// Registers a persistent BroadcastReceiver for ACTION_BATTERY_CHANGED
    /// and caches level + charging state. The receiver stays alive for the
    /// activity lifetime and is unregistered in onDestroy.
    private fun registerBatteryReceiver() {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                cachedBatteryLevel = if (scale > 0) level * 100 / scale else -1
                val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                cachedIsCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                    status == BatteryManager.BATTERY_STATUS_FULL
            }
        }
        registerReceiver(batteryReceiver, filter)
        // Seed cached values from the initial sticky broadcast (best-effort)
        val initial = registerReceiver(null, filter)
        if (initial != null) {
            val level = initial.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = initial.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            cachedBatteryLevel = if (scale > 0) level * 100 / scale else -1
            val status = initial.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            cachedIsCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle initial intent that started the activity
        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // singleTop launch mode — handle re-parented intents here
        setIntent(intent)
        handleDeepLink(intent)
    }

    /// Parses the incoming intent for a gasong://play?id=xxx deep link and
    /// forwards the song ID to the Dart side via MethodChannel.
    private fun handleDeepLink(intent: Intent?) {
        if (intent == null) return

        val action = intent.action ?: return
        val data = intent.data ?: return

        if (action != Intent.ACTION_VIEW) return
        if (data.scheme != "gasong") return
        if (data.host != "play") return

        val songId = data.getQueryParameter("id")
        if (songId.isNullOrBlank()) {
            Log.w(TAG, "Deep link missing 'id' parameter: $data")
            return
        }

        Log.i(TAG, "Deep link received: play song id=$songId")

        try {
            val id = songId.toInt()
            deepLinkMethodChannel?.invokeMethod("playSong", id)
        } catch (e: NumberFormatException) {
            Log.e(TAG, "Invalid song ID in deep link: $songId", e)
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            try {
                MethodChannel(messenger, PIP_CHANNEL)
                    .invokeMethod(
                        "onPiPChanged",
                        mapOf("isInPiP" to isInPictureInPictureMode)
                    )
            } catch (e: Exception) {
                Log.w(TAG, "Failed to notify PiP change: ${e.message}", e)
            }
        }
    }

    override fun onDestroy() {
        // Clean up MethodChannel handlers to prevent memory leaks
        pipMethodChannel?.setMethodCallHandler(null)
        pipMethodChannel = null
        deepLinkMethodChannel?.setMethodCallHandler(null)
        deepLinkMethodChannel = null
        powerMethodChannel?.setMethodCallHandler(null)
        powerMethodChannel = null
        // Unregister battery receiver to prevent leaked BroadcastReceivers
        batteryReceiver?.let {
            unregisterReceiver(it)
            batteryReceiver = null
        }
        super.onDestroy()
    }
}
