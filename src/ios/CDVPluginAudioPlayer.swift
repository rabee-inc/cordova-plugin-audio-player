import AVFoundation

struct PlayerData {
    var id: String
    var url: String
    var isLoop: Bool
    var player: AudioPlayer
    init(data: [String: Any]) throws {
        guard
            let id = data["id"] as? String,
            let url = data["url"] as? String,
            let isLoop = data["isLoop"] as? Bool else {
                throw NSError(domain: "initalize error", code: 1, userInfo: nil)
        }
        
        self.id = id
        self.url = url
        self.isLoop = isLoop
        player = AudioPlayer(url: self.url)
    }
}

class AudioPlayer {
    private var audioPlayer: AVAudioPlayer!
    
    init(url:String) {
        guard let path = Bundle.main.path(forResource: url, ofType: "mp3") else {
            print("音源ファイルが見つかりません")
            return
        }
        do {
            // AVAudioPlayerのインスタンス化
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            // AVAudioPlayerのデリゲートをセット
            audioPlayer.delegate = self as? AVAudioPlayerDelegate
        }
        catch {
        }
    }
    
    func play() {
        audioPlayer.play()
    }
    
    func pause() {
        audioPlayer.pause()
    }
    
    func stop() {
        audioPlayer.stop()
    }
}

    
@objc(CDVPluginAudioPlayer ) class CDVPluginAudioPlayer: CDVPlugin {

    var playerDataList:[String:PlayerData] = [:]
    
    // 作成
    @objc func create(_ command: CDVInvokedUrlCommand) {
        let data = command.argument(at: 0) as! [String: Any]
        do {
            let playerData = try PlayerData(data: data)
            playerDataList[playerData.id] = playerData
            
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
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
            let id = data["id"] as? String,
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
            let id = data["id"] as? String,
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
            let id = data["id"] as? String,
            let playerData = playerDataList[id] else {return}
        
        let player = playerData.player
        player.stop()
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
}
