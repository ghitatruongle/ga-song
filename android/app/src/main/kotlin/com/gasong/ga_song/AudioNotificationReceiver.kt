package com.gasong.ga_song

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import android.util.Log
import android.content.IntentFilter
import com.ryanheise.audioservice.AudioServicePlugin

/**
 * Handles notification action broadcasts from the media notification.
 *
 * This receiver is registered in the manifest and processes actions such as
 * "previous", "next", "play/pause" forwarded by the system's media notification
 * or Bluetooth headset events.
 *
 * It delegates to [AudioServicePlugin]'s built-in receiver chain for standard
 * media actions, and provides a seam for custom notification actions the app
 * may define in the future.
 */
class AudioNotificationReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AudioNotificationReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return

        val action = intent.action
        if (action == null) return

        Log.d(TAG, "Received broadcast: $action")

        try {
            when (action) {
                // Delegate standard media actions to audio_service's built-in receiver.
                Intent.ACTION_MEDIA_BUTTON,
                AudioManager.ACTION_AUDIO_BECOMING_NOISY -> {
                    // Forward to the plugin's MediaButtonReceiver logic.
                    val forward = Intent(context, AudioServicePlugin::class.java)
                    forward.action = action
                    intent.extras?.let { forward.putExtras(it) }
                    context.applicationContext.sendBroadcast(forward)
                }

                else -> {
                    Log.w(TAG, "Unhandled notification action: $action")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification action: ${e.message}", e)
        }
    }
}
