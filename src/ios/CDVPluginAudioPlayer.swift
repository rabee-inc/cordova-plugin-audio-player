import AVFoundation
// プレイヤーイベント周り
extension Notification.Name {
    static let audioPlayerPlay = Notification.Name("audioPlayerPlay")
    static let audioPlayerStop = Notification.Name("audioPlayerStop")
    static let audioPlayerPause = Notification.Name("audioPlayerPause")
    static let audioPlayerEnded = Notification.Name("audioPlayerEnded")
    static let audioPlayerCurrentTimeUpdate = Notification.Name("audioPlayerCurrentTimeUpdate")
}

// player の wrapper クラス
struct PlayerData {
    var id: UInt64
    var isLoop: Bool // ループするかどうか -> まだ未実装
    var player: AudioPlayer
    var path: String
    var isDownload: Bool = false
    var delegate: CDVPluginAudioPlayer?
    // イベントコールバックid
    var eventListenerCallbackIds: [String:String]

    init(data: [String: Any], id: UInt64) throws {
        guard
            let path = data["path"] as? String else {
                throw NSError(domain: "initalize error", code: 1, userInfo: nil)
        }
        self.id = id
        self.eventListenerCallbackIds = [:]
        let isLoop = data["isLoop"] as? Bool ?? false
        
        self.isLoop = isLoop
        self.path = path
        self.player = AudioPlayer(path: path, isLoop: self.isLoop)
        self.player.parent = self
        
    }
}

// audio player 本体
class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer!
    var parent: PlayerData?
    var available = false
    init(path:String, isLoop: Bool) {
        super.init()
        do {
            let regularURL = path.replacingOccurrences(of: "file://", with: "")
            let url = URL(string: regularURL)
            audioPlayer = try AVAudioPlayer(contentsOf: url!)
            audioPlayer.numberOfLoops = isLoop ? -1 : 0 // ループの設定
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay() // バッファを読み込んでおく
            available = true
        }
        catch let error {
            print(error)
        }
        
    }
    
    func play() {
        // 即時再生はラグがあるので必ず0.1秒後に再生する
        play(time: 0.1)
    }
    // 時間指定で再生開始する
    func play(time: Double) {
        if (audioPlayer.isPlaying) {
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryPlayAndRecord,
                mode: AVAudioSessionModeDefault,
                options: [.allowBluetoothA2DP, .allowBluetooth, .allowAirPlay]
            )
        }
        catch {
           
        }
        // 最後の方から再生したら最初に戻す
        if audioPlayer.currentTime >= audioPlayer.duration - 0.05 {
            audioPlayer.currentTime = 0.0
        }
        Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in
            self.trigger(name: .audioPlayerPlay)
            self.trigger(name: .audioPlayerCurrentTimeUpdate)
        })
        
        audioPlayer.play(atTime: audioPlayer.deviceCurrentTime + time)
    }
    func pause() {
        if (!audioPlayer.isPlaying) {
            return
        }
        audioPlayer.pause()
        trigger(name: .audioPlayerPause)
        
    }
    func stop() {
        if (!audioPlayer.isPlaying) {
            return
        }
        audioPlayer.stop()
        
        trigger(name: .audioPlayerStop)
        trigger(name: .audioPlayerEnded)
    }
    // 音声の再生が終了したら
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer.currentTime = audioPlayer.duration
        trigger(name: .audioPlayerEnded)
    }
    
    // secounds?
    func getDuration() -> TimeInterval {
        return audioPlayer.duration
    }
    
    func setCurrentTime(time: Double) {
        // 勝手に最初に戻ってしまうので 0.05 秒までシーク
        let currentTime = min(time, audioPlayer.duration - 0.05)
        audioPlayer.currentTime = currentTime
        // 0.1秒後に正確なcurrentTimeをjsに送信
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in
            self.trigger(name: .audioPlayerCurrentTimeUpdate)
        })
    }
    
    func getCurrentTime() -> TimeInterval {
        return audioPlayer.currentTime
    }
    
    func close() {
        audioPlayer.stop()
        // MEMO: 不要なら消す
        audioPlayer.delegate = nil
        parent = nil
        available = false
    }
    
    func trigger(name: Notification.Name) {
        guard let parent = self.parent else {return}
        NotificationCenter.default.post(name: name, object: nil, userInfo: ["playerData": parent])
    }
}




// マネージャー的なやつ
@objc(CDVPluginAudioPlayer) class CDVPluginAudioPlayer: CDVPlugin {

    var playerDataList:[UInt64:PlayerData] = [:]
    var audioIndex: UInt64 = 0
    
    @objc override func pluginInitialize() {
        // 通知登録 (play, pause, stop, ended)
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidPlay(notification:)), name: NSNotification.Name.audioPlayerPlay, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidPause(notification:)), name: NSNotification.Name.audioPlayerPause, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidStop(notification:)), name: NSNotification.Name.audioPlayerStop, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidEnded(notification:)), name: NSNotification.Name.audioPlayerEnded, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioCurrentTimeUpdate(notification:)), name: NSNotification.Name.audioPlayerCurrentTimeUpdate, object: nil)
        playerDataList = [:]
        audioIndex = 0
    }
    
    // 作成
    @objc func create(_ command: CDVInvokedUrlCommand) {
        let data = command.argument(at: 0) as! [String: Any]
        audioIndex = audioIndex + 1
        let id:UInt64 = audioIndex
        do {
            var playerData = try PlayerData(data: data, id: id);
            playerData.delegate = self
            if playerData.player.available {
                playerDataList.updateValue(playerData, forKey: playerData.id)
                let data = [
                    "id": playerData.id,
                    "path": playerData.path as Any,
                    "duration": playerData.player.getDuration(),
                ] as [String : Any]
                let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
                commandDelegate.send(result, callbackId: command.callbackId)
            }
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: data)
                commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
        catch {
            // TODO: error handling
        }

    }
    // 再生
    @objc func play(_ command: CDVInvokedUrlCommand) {
        // データの生成
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? UInt64,
            let playerData = playerDataList[id] else {return}
        
        let player = playerData.player
        var time = data["time"] as? Double

        if (time != nil) {
            // コマンド呼び出しのラグを修正
            time! -= 0.0005;
            player.play(time: time ?? 0)
        }
        else {
            player.play()
        }
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    // 一時停止
    @objc func pause(_ command: CDVInvokedUrlCommand) {
        // データの生成
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? UInt64,
            let playerData = playerDataList[id] else {return}
        
        let player = playerData.player
        player.pause()
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    // 停止
    @objc func stop(_ command: CDVInvokedUrlCommand) {
        // データの生成
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? UInt64,
            let playerData = playerDataList[id] else {return}
        
        let player = playerData.player
        player.stop()
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    // duration 取得
    @objc func getDuration(_ command: CDVInvokedUrlCommand) {
        // データの生成
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? UInt64,
            let playerData = playerDataList[id] else {return}
        
        let duration = playerData.player.getDuration()
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["duration": duration])
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    // 現在時間の取得
    @objc func setCurrentTime(_ command: CDVInvokedUrlCommand) {
        // データの生成
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? UInt64,
            let time = data["time"] as? Double,
            let playerData = playerDataList[id] else {return}
        playerData.player.setCurrentTime(time: time)
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    // 現在時間の取得
    @objc func getCurrentTime(_ command: CDVInvokedUrlCommand) {
        // データの生成
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? UInt64,
            let playerData = playerDataList[id] else {return}
        
        let time = playerData.player.getCurrentTime()
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["currentTime": time])
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    // メモリから削除
    @objc func close(_ command: CDVInvokedUrlCommand) {
        // データの生成
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? UInt64,
            let playerData = playerDataList[id] else {return}
        let player = playerData.player
        player.close()
        playerDataList.removeValue(forKey: id)
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    // callback id 周りの登録関数
    @objc func addEventListener(_ command: CDVInvokedUrlCommand) {
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? UInt64,
            let type = data["type"] as? String,
            var playerData = playerDataList[id] else {return}
        playerData.eventListenerCallbackIds[type] = command.callbackId
        playerDataList.updateValue(playerData, forKey: id)
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["isRegisterEvent": true, "callbackId": command.callbackId])
        result?.keepCallback = true
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    // 通知受け取り関数
    func getPlayerData(notification: Notification) -> PlayerData! {
        let data = notification.userInfo?["playerData"] as? PlayerData
        return playerDataList[data!.id]
    }
    
    func sendResult(playerData: PlayerData, type: String) {
        sendResult(playerData: playerData, type: type, messageAs: nil)
    }
    
    func sendResult(playerData: PlayerData, type: String, messageAs: [AnyHashable : Any]!) {
        let result: CDVPluginResult
        if (messageAs == nil) {
            result = CDVPluginResult(status: CDVCommandStatus_OK)
        }
        else {
            result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: messageAs)
        }
        result.keepCallback = true
        commandDelegate.send(result, callbackId: playerData.eventListenerCallbackIds[type])
    }
    
    @objc func audioDidCanPlay(notification: Notification) {
        guard let playerData = getPlayerData(notification: notification) else {return}
        sendResult(playerData: playerData, type: "play")
    }
    
    @objc func audioDidPlay(notification: Notification) {
        guard let playerData = getPlayerData(notification: notification) else {return}
        sendResult(playerData: playerData, type: "play")
    }
    
    @objc func audioDidPause(notification: Notification) {
        guard let playerData = getPlayerData(notification: notification) else {return}
        sendResult(playerData: playerData, type: "pause")
    }
    
    @objc func audioDidStop(notification: Notification) {
        guard let playerData = getPlayerData(notification: notification) else {return}
        sendResult(playerData: playerData, type: "stop")
    }
    
    @objc func audioDidEnded(notification: Notification) {
        guard let playerData = getPlayerData(notification: notification) else {return}
        sendResult(playerData: playerData, type: "ended")
    }
    
    @objc func audioCurrentTimeUpdate(notification: Notification) {
        guard let playerData = getPlayerData(notification: notification) else {return}
        sendResult(playerData: playerData, type: "currenttimeupdate", messageAs: ["currentTime": playerData.player.getCurrentTime()])
    }
    
}

