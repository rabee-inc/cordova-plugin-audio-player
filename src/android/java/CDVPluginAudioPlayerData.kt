package jp.rabee

import android.content.Context
import android.media.MediaPlayer
import android.net.Uri
import org.apache.cordova.CallbackContext
import org.apache.cordova.PluginResult
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import kotlin.math.round


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
        // file:// から始まるが、uri 変換の時におかしくなるので、切り取る
        val file = File(path.replace("file://", ""))
        if (file.exists()) print("exist!!!") // 一応存在チェック

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
        if (this.player.isPlaying) {
            return
        }
        this.player.start()
        sendPluginResultEvent("play")
        sendPluginResultEvent("currenttimeupdate", JSONObject(mutableMapOf("currentTime" to currentTime())))
    }
    fun pause() {
        if (!this.player.isPlaying) {
            return
        }
        this.player.pause()
        sendPluginResultEvent("pause")
    }
    fun stop() {
        this.player.stop()
        sendPluginResultEvent("stop")
        sendPluginResultEvent("ended")
    }
    fun duration(): Float {
        return this.player.duration / 1000f
    }
    fun currentTime(): Float {
        return this.player.currentPosition / 1000f
    }
    fun setCurrentTime(time: Double) {
        this.player.seekTo(round(time * 1000).toInt())
    }
    fun close() {
        this.player.release()
        sendPluginResultEvent("close")
    }
    fun setEventCallback(type: String, callbackContext: CallbackContext) {
        var callbacks = eventListenerCallbacks[type]
        if (callbacks.isNullOrEmpty()) {
            callbacks = mutableListOf()
        }
        callbacks.add(callbackContext)
        eventListenerCallbacks[type] = callbacks
    }
    private fun sendPluginResultEvent(type: String, args: JSONObject?) {
        val callbacks = this.eventListenerCallbacks[type]
        callbacks?.forEach {
            var p :PluginResult
            if (args == null) {
                p = PluginResult(PluginResult.Status.OK)
            }
            else {
                p = PluginResult(PluginResult.Status.OK, args)
            }
            p.keepCallback = true
            it.sendPluginResult(p)
        }
    }

    private fun sendPluginResultEvent(type: String) {
        sendPluginResultEvent(type, null)
    }
}