package com.gasong.ga_song

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Rational
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val PIP_CHANNEL = "com.gasong.ga_song/pip"
        private const val DEEP_LINK_CHANNEL = "com.gasong.ga_song/deep_link"
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    private var pipMethodChannel: MethodChannel? = null
    private var deepLinkMethodChannel: MethodChannel? = null

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

    /// Parses the incoming intent for a ga-song://play?id=xxx deep link and
    /// forwards the song ID to the Dart side via MethodChannel.
    private fun handleDeepLink(intent: Intent?) {
        if (intent == null) return

        val action = intent.action ?: return
        val data = intent.data ?: return

        if (action != Intent.ACTION_VIEW) return
        if (data.scheme != "ga-song") return
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
        super.onDestroy()
    }
}
