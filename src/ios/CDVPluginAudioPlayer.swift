import AVFoundation
// プレイヤーイベント周り
extension Notification.Name {
    static let audioPlayerPlay = Notification.Name("audioPlayerPlay")
    static let audioPlayerStop = Notification.Name("audioPlayerStop")
    static let audioPlayerPause = Notification.Name("audioPlayerPause")
    static let audioPlayerEnded = Notification.Name("audioPlayerPause")
}

// player の wrapper クラス
struct PlayerData {
    var id: Int
    var isLoop: Bool // ループするかどうか -> まだ未実装
    var player: AudioPlayer
    var path: String
    var isDownload: Bool = false
    var delegate: CDVPluginAudioPlayer?
    // イベントコールバックid
    var playCallbackId: String?
    var pauseCallbackId: String?
    var stopCallbackId: String?
    var endedCallbackId: String?
    var canPlayCallbackId: String?

    init(data: [String: Any], id: Int) throws {
        guard
            let path = data["path"] as? String else {
                throw NSError(domain: "initalize error", code: 1, userInfo: nil)
        }
        self.id = id
        let isLoop = data["isLoop"] as? Bool ?? false
        
        self.id = id
        self.isLoop = isLoop
        self.path = path
        self.player = AudioPlayer(path: path)
        self.player.parent = self
    }
}

// audio player 本体
class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer!
    var parent: PlayerData?
    init(path:String) {
        super.init()
        do {
            
            let regularURL = path.replacingOccurrences(of: "file://", with: "")
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: regularURL))
            audioPlayer.delegate = self
//            audioPlayer.prepareToPlay() // バッファを読み込んでおく
        }
        catch {
            // TODO:Error
        }
    }
    
    func play() {
        
        
        if (audioPlayer.isPlaying) {
            return
        }
        audioPlayer.play()
        NotificationCenter.default.post(name: .audioPlayerPlay, object: self.parent)
    }
    // 時間指定で再生開始する
    func play(time: Double) {
        if (audioPlayer.isPlaying) {
            return
        }
        audioPlayer.play(atTime: audioPlayer.deviceCurrentTime + time)
        
        guard let parent = self.parent else {return}
        NotificationCenter.default.post(name: .audioPlayerPlay, object: nil, userInfo: ["playerData": parent])
    }
    func pause() {
        if (!audioPlayer.isPlaying) {
            return
        }
        audioPlayer.pause()
        
        guard let parent = self.parent else {return}
        NotificationCenter.default.post(name: .audioPlayerPause, object: nil, userInfo: ["playerData": parent])
        
    }
    func stop() {
        if (!audioPlayer.isPlaying) {
            return
        }
        audioPlayer.stop()
        
        guard let parent = self.parent else {return}
        NotificationCenter.default.post(name: .audioPlayerStop, object: nil, userInfo: ["playerData": parent])
        NotificationCenter.default.post(name: .audioPlayerEnded, object: nil, userInfo: ["playerData": parent])
    }
    // 音声の再生が終了したら
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let parent = self.parent else {return}
        NotificationCenter.default.post(name: .audioPlayerEnded, object: nil, userInfo: ["playerData": parent])
    }
    
    // secounds?
    func getDuration() -> TimeInterval {
        return audioPlayer.duration
    }
    
    func setCurrentTime(time: Double) {
        audioPlayer.currentTime = time
    }
    
    func getCurrentTime() -> TimeInterval {
        return audioPlayer.currentTime
    }
}




// マネージャー的なやつ
@objc(CDVPluginAudioPlayer) class CDVPluginAudioPlayer: CDVPlugin {

    var playerDataList:[Int:PlayerData] = [:]
    var audioIndex: Int = 0
    private var lock = NSRecursiveLock()
    
    @objc override func pluginInitialize() {
        // 通知登録 (play, pause, stop, ended)
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidPlay(notification:)), name: NSNotification.Name.audioPlayerPlay, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidPause(notification:)), name: NSNotification.Name.audioPlayerPause, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidStop(notification:)), name: NSNotification.Name.audioPlayerStop, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidEnded(notification:)), name: NSNotification.Name.audioPlayerEnded, object: nil)
        playerDataList = [:]
        audioIndex = 0
        lock = NSRecursiveLock()
    }
    
    // 作成
    @objc func create(_ command: CDVInvokedUrlCommand) {
        // 作成終わるまで待つ
        defer { lock.unlock() }
        lock.lock()
        
        let data = command.argument(at: 0) as! [String: Any]
        audioIndex = audioIndex + 1
        let id = audioIndex
        do {
            var playerData = try PlayerData(data: data, id: id);
            playerData.delegate = self
            playerDataList.updateValue(playerData, forKey: playerData.id)
            let data = [
                "id": playerData.id,
                "path": playerData.path as Any,
                "duration": playerData.player.getDuration(),
            ] as [String : Any]
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
            commandDelegate.send(result, callbackId: command.callbackId)
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
            let id = data["id"] as? Int,
            let playerData = playerDataList[id] else {return}
        
        let player = playerData.player
        player.play()
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    // 一時停止
    @objc func pause(_ command: CDVInvokedUrlCommand) {
        // データの生成
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? Int,
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
            let id = data["id"] as? Int,
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
            let id = data["id"] as? Int,
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
            let id = data["id"] as? Int,
            let playerData = playerDataList[id] else {return}
        
        let duration = playerData.player.getDuration()
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["duration": duration])
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    // callback id 周りの登録関数
    @objc func setOnPlayCallbackId(_ command: CDVInvokedUrlCommand) {
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? Int,
            var playerData = playerDataList[id] else {return}
        playerData.playCallbackId = command.callbackId
        playerDataList.updateValue(playerData, forKey: id)
        
    }
    @objc func setOnPauseCallbackId(_ command: CDVInvokedUrlCommand) {
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? Int,
            var playerData = playerDataList[id] else {return}
        playerData.pauseCallbackId = command.callbackId
        playerDataList.updateValue(playerData, forKey: id)
        
    }
    @objc func setOnStopCallbackId(_ command: CDVInvokedUrlCommand) {
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? Int,
            var playerData = playerDataList[id] else {return}
        playerData.stopCallbackId = command.callbackId
        playerDataList.updateValue(playerData, forKey: id)
        
    }
    @objc func setOnEndedCallbackId(_ command: CDVInvokedUrlCommand) {
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? Int,
            var playerData = playerDataList[id] else {return}
        playerData.endedCallbackId = command.callbackId
        playerDataList.updateValue(playerData, forKey: id)
        
    }
    @objc func setOnCanPlayCallbackId(_ command: CDVInvokedUrlCommand) {
        guard
            let data = command.argument(at: 0) as? [String: Any],
            let id = data["id"] as? Int,
            var playerData = playerDataList[id] else {return}
        playerData.canPlayCallbackId = command.callbackId
        playerDataList.updateValue(playerData, forKey: id)
        
    }
    
    // 通知受け取り関数
    @objc func audioDidCanPlay(notification: Notification) {
        guard let data = notification.userInfo?["playerData"] as? PlayerData,
            let playerData = playerDataList[data.id] else {return}
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        result?.keepCallback = true
        commandDelegate.send(result, callbackId: playerData.playCallbackId)
    }
    
    @objc func audioDidPlay(notification: Notification) {
        guard let data = notification.userInfo?["playerData"] as? PlayerData,
            let playerData = playerDataList[data.id] else {return}
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        result?.keepCallback = true
        commandDelegate.send(result, callbackId: playerData.playCallbackId)
    }
    
    @objc func audioDidPause(notification: Notification) {
        guard let data = notification.userInfo?["playerData"] as? PlayerData,
            let playerData = playerDataList[data.id] else {return}
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        result?.keepCallback = true
        commandDelegate.send(result, callbackId: playerData.pauseCallbackId)
    }
    
    @objc func audioDidStop(notification: Notification) {
        guard let data = notification.userInfo?["playerData"] as? PlayerData,
            let playerData = playerDataList[data.id] else {return}
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        result?.keepCallback = true
        commandDelegate.send(result, callbackId: playerData.stopCallbackId)
    }
    
    @objc func audioDidEnded(notification: Notification) {
        guard let data = notification.userInfo?["playerData"] as? PlayerData,
            let playerData = playerDataList[data.id] else {return}
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        result?.keepCallback = true
        commandDelegate.send(result, callbackId: playerData.endedCallbackId)
    }
    
}

