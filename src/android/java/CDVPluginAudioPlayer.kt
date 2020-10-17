package jp.rabee

import android.content.IntentFilter
import com.google.gson.GsonBuilder
import org.apache.cordova.*
import org.json.JSONArray
import org.json.JSONObject


// for guard
inline fun <T> guard(value: T?, ifNull: () -> Unit): T {
    if (value != null) return value
    ifNull()
    throw Exception("Guarded from null!")
}

class CDVPluginAudioPlayer : CordovaPlugin() {

    var playerId:Int = 0
    var playerList:MutableMap<Int,AudioPlayer> = mutableMapOf()

    companion object {
        val TAG = "Cordova Plugin Audio Player"
    }

    override public fun initialize(cordova: CordovaInterface,  webView: CordovaWebView) {
        LOG.d(TAG, "hi! This is CDVPluginAudioPlayer. Now intitilaizing ...");

    }

    override  public fun onDestroy() {}

    override fun execute(action: String, param: JSONArray, callbackContext: CallbackContext): Boolean {
        var result = false

        when(action) {
            "create" -> {
                result = this.create(callbackContext, param)
            }
            "play" -> {
                result = this.play(callbackContext, param)
            }
            "pause" -> {
                result = this.pause(callbackContext, param)
            }
            "stop" -> {
                result = this.stop(callbackContext, param)
            }
            "close" -> {
                result = this.close(callbackContext, param)
            }
            "getDuration" -> {
                result = this.getDuration(callbackContext, param)
            }
            "getCurrentTime" -> {
                result = this.getCurrentTime(callbackContext, param)
            }
            "setCurrentTime" -> {
                result = this.setCurrentTime(callbackContext, param)
            }
            "addEventListener" -> {
                result = this.addEventListener(callbackContext, param)
            }
            else -> {
                // TODO error
            }
        }

        return result
    }

    // プレイヤーの再生スタート
    private fun start(callbackContext: CallbackContext, params: JSONArray): Boolean {
        cordova.activity.run {}
        return true
    }

    private fun create(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val data = param.getJSONObject(0) ?: return false
        val path = data.getString("path") ?: return false
        val isLoop = data.getBoolean("isLoop") ?: return false

        playerId++
        // player 生成
        val audioPlayer = AudioPlayer(this.cordova.context, playerId, isLoop, path)
        playerList[playerId] = audioPlayer

        // success
        sendSuccessCallback(callbackContext)
        return true
    }
    private fun play(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val audioPlayer = getPlayerFromParam(param) ?: return false
        audioPlayer.play()
        return true
    }
    private fun pause(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val audioPlayer = getPlayerFromParam(param) ?: return false
        audioPlayer.pause()
        sendSuccessCallback(callbackContext)
        return true
    }
    private fun stop(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val audioPlayer = getPlayerFromParam(param) ?: return false
        audioPlayer.stop()
        sendSuccessCallback(callbackContext)
        return true
    }
    private fun getDuration(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val audioPlayer = getPlayerFromParam(param) ?: return false
        val duration = audioPlayer.duration()
        val data = JSONObject(mapOf("duration" to duration))
        val p = PluginResult(PluginResult.Status.OK, data)
        callbackContext.sendPluginResult(p)
        return true
    }
    private fun getCurrentTime(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val audioPlayer = getPlayerFromParam(param) ?: return false
        val currentTime = audioPlayer.currentTime()
        val data = JSONObject(mapOf("currentTime" to currentTime))
        val p = PluginResult(PluginResult.Status.OK, data)
        return true
    }
    private fun setCurrentTime(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val audioPlayer = getPlayerFromParam(param) ?: return false
        val time = param.getJSONObject(0).getInt("time") ?: return false
        audioPlayer.setCurrenttTime(time)
        return true
    }
    private fun close(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val audioPlayer = getPlayerFromParam(param) ?: return false
        val id = param.getJSONObject(0).getInt("id") ?: return false
        audioPlayer.stop()
        audioPlayer.close() // player を終了
        playerList.remove(id) // list から削除
        return true
    }

    private fun addEventListener(callbackContext: CallbackContext, param: JSONArray): Boolean {
        val audioPlayer = getPlayerFromParam(param) ?: return false
        val data = param.getJSONObject(0) ?: return false
        val id = data.getInt("id") ?: return false
        val type = data.getString("type") ?: return false

        audioPlayer.setEventCallback(type, callbackContext)
        playerList[id] = audioPlayer
        return true
    }

    private fun getPlayerFromParam(param: JSONArray): AudioPlayer? {
        val data = param.getJSONObject(0) ?: return null
        val id = data.getInt("id") ?: return null
        return playerList[id]
    }

    private fun sendSuccessCallback(callbackContext: CallbackContext) {
        val p = PluginResult(PluginResult.Status.OK)
        callbackContext.sendPluginResult(p)
    }
}
