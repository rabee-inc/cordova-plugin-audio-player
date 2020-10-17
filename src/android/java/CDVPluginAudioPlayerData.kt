package jp.rabee

import android.content.Context
import android.media.MediaPlayer
import android.net.Uri
import org.apache.cordova.CallbackContext
import org.apache.cordova.PluginResult
import java.io.File



class AudioPlayer(
        context: Context,
        id: Int,
        isLoop: Boolean = false,
        path: String) {

    private val id: Int = id
    private val isLoop: Boolean = isLoop
    private val player: MediaPlayer
    private val eventListenerCallbacks: MutableMap<String, MutableList<CallbackContext>> = mutableMapOf()

    init {

        val file = File(path)
        val uri = Uri.fromFile(file)
        this.player = MediaPlayer.create(context, uri)
        this.player.isLooping = isLoop

        // event listener
        this.player.setOnCompletionListener {
            sendPluginResultEvent("ended")
        }
        this.player.setOnBufferingUpdateListener { _, _ ->
            println("setOnBufferingUpdate")
        }
        this.player.setOnErrorListener { _, _, _ ->
            return@setOnErrorListener true
        }
        // FIXME: player time update をやりたい

    }

    fun play() {
        this.player.start()
        sendPluginResultEvent("play")
    }
    fun pause() {
        this.player.pause()
        sendPluginResultEvent("pause")
    }
    fun stop() {
        this.player.stop()
        sendPluginResultEvent("stop")
    }
    fun duration(): Int {
        return this.player.duration
    }
    fun currentTime(): Int {
        return this.player.currentPosition
    }
    fun setCurrenttTime(time: Int) {
        this.player.seekTo(time)
    }
    fun close() {
        this.player.release()
        sendPluginResultEvent("close")
    }
    fun setEventCallback(type: String, callbackContext: CallbackContext) {
        val callbacks = eventListenerCallbacks[type] ?: return
        callbacks.add(callbackContext)
        eventListenerCallbacks[type] = callbacks
    }
    private fun sendPluginResultEvent(type: String) {
        val callbacks = this.eventListenerCallbacks[type]
        callbacks?.forEach {
            val p = PluginResult(PluginResult.Status.OK)
            p.keepCallback = true
            it.sendPluginResult(p)
        }
    }
}