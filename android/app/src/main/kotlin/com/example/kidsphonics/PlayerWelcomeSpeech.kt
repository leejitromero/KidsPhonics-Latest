package com.example.kidsphonics

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Android's installed offline voices, used only for the player's welcome. */
internal class PlayerWelcomeSpeech(context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, "kidsphonics/player_welcome")
    private val handler = Handler(Looper.getMainLooper())
    private val audio = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
    private var engine: TextToSpeech? = null
    private var ready = false
    private var disposed = false
    private var foreground = false
    private var engineGeneration = 0
    private var pending: Request? = null
    private var watchdog: Runnable? = null
    private var focusRequest: AudioFocusRequest? = null
    private var focusListener: AudioManager.OnAudioFocusChangeListener? = null

    private data class Request(val id: String, val text: String, val result: MethodChannel.Result)

    init { channel.setMethodCallHandler(this) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "speak" -> {
                val id = call.argument<String>("id")
                val text = call.argument<String>("text")
                if (disposed || !foreground || id.isNullOrBlank() || text.isNullOrBlank() ||
                    text.length > TextToSpeech.getMaxSpeechInputLength()) {
                    result.success(false)
                    return
                }
                stop()
                val request = Request(id, text, result)
                pending = request
                val timeout = Runnable {
                    if (pending?.id == id) {
                        finish(false)
                        if (!ready) releaseEngine()
                    }
                }
                watchdog = timeout
                handler.postDelayed(timeout, 20_000)
                if (ready) speak(request) else initialize()
            }
            "stop" -> {
                // A late stop from an older Home cannot cancel a new greeting.
                if (call.argument<String>("id") == pending?.id) stop()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize() {
        if (engine != null) return
        val generation = ++engineGeneration
        try {
            engine = TextToSpeech(appContext) { status ->
                handler.post {
                    if (!disposed && generation == engineGeneration) {
                        ready = status == TextToSpeech.SUCCESS
                        if (ready) pending?.let { speak(it) } else {
                            finish(false)
                            releaseEngine()
                        }
                    }
                }
            }
        } catch (_: Exception) {
            finish(false)
            releaseEngine()
        }
    }

    private fun speak(request: Request) {
        if (disposed || !foreground || pending?.id != request.id) return
        try {
            val tts = engine ?: return finish(false)
            val voice = tts.voices?.filter {
                it.locale.language == "en" && !it.isNetworkConnectionRequired &&
                    it.features?.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) != true
            }?.sortedWith(compareBy<Voice> {
                when (it.locale.toLanguageTag()) {
                    "en-PH" -> 0
                    "en-US" -> 1
                    "en-GB" -> 2
                    else -> 3
                }
            }.thenByDescending { it.quality }.thenBy { it.name })?.firstOrNull()
            if (voice == null || tts.setVoice(voice) != TextToSpeech.SUCCESS) {
                finish(false)
                return
            }
            tts.setSpeechRate(0.9f)
            tts.setAudioAttributes(attributes)
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(id: String?) { }
                override fun onDone(id: String?) = completed(id, true)
                @Suppress("OVERRIDE_DEPRECATION")
                @Deprecated("Android callback")
                override fun onError(id: String?) = completed(id, false)
                override fun onError(id: String?, code: Int) = completed(id, false)
                override fun onStop(id: String?, interrupted: Boolean) = completed(id, false)
            })
            if (!requestFocus(request.id) ||
                tts.speak(request.text, TextToSpeech.QUEUE_FLUSH, Bundle(), request.id) != TextToSpeech.SUCCESS) {
                finish(false)
            }
        } catch (_: Exception) { finish(false) }
    }

    private fun completed(id: String?, success: Boolean) {
        handler.post { if (pending?.id == id) finish(success) }
    }

    @Suppress("DEPRECATION")
    private fun requestFocus(id: String): Boolean {
        val listener = AudioManager.OnAudioFocusChangeListener { change ->
            if (change < 0) handler.post { if (pending?.id == id) finish(false) }
        }
        focusListener = listener
        val response = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attributes).setOnAudioFocusChangeListener(listener, handler).build()
            focusRequest = request
            audio.requestAudioFocus(request)
        } else {
            audio.requestAudioFocus(listener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        }
        return response == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    @Suppress("DEPRECATION")
    private fun finish(success: Boolean) {
        val request = pending ?: return
        pending = null
        watchdog?.let { handler.removeCallbacks(it) }
        watchdog = null
        if (!success) try { engine?.stop() } catch (_: Exception) { }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                focusRequest?.let { audio.abandonAudioFocusRequest(it) }
            } else {
                focusListener?.let { audio.abandonAudioFocus(it) }
            }
        } catch (_: Exception) { }
        focusRequest = null
        focusListener = null
        request.result.success(success)
    }

    fun stop() { finish(false) }

    fun setForeground(active: Boolean) {
        foreground = active
        if (!active) stop()
    }

    private fun releaseEngine() {
        engineGeneration++
        ready = false
        try { engine?.shutdown() } catch (_: Exception) { }
        engine = null
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        stop()
        releaseEngine()
        channel.setMethodCallHandler(null)
    }
}
