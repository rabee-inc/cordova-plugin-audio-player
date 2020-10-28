# cordova-plugin-audio-player




## interface 

```js
// 追加
const audio1 = await AudioPlayerManager.create({
    id: 'bgm1',
    url: string,
    isLoop: boolean
});

const audio2 = await AudioPlayerManager.create({
    id: 'bgm2',
    url: string,
    path: path,
    isLoop: boolean
});

// 
audio1.duration

await audio1.setCurrentTime()
await audio1.getCurrentTime()

// 再生流
audio1.play()
// 再開する
audio1.resume()
// 一時停止
audio1.pause()
// 完全に停止
audio1.stop()

// クリア
audio1.remove({id: 'hgoe'})

// イベント系
audio1.on('ended', () => {
 audio2.play();
});

// play start
audio1.on('play', () => {});
audio1.on('pause', () => {});
audio1.on('canplay', () => {});



// 管理系統
const audio1 = await AudioPlayerManger.get({id})
await AudioPlayerManger.remove({id})
await AudioPlayerManger.removeAll()

````