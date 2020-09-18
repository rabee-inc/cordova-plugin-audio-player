'use strict';

const exec = require('cordova/exec');
// native で 即時再生する際に 100 ms 送らせて再生する
const START_TIME_LAG = 100;
class AudioPlayerManager {
  constructor() {
  }

  async create({ path, isLoop }) {
    await this.createAction('test');
    // id, path, duration
    const data = await this.createAction('create', { path, isLoop });

    const player = new AudioPlayer(data);
    return player;
  }

  // cordova の実行ファイルを登録する
  registerCordovaExecuter(action, onSuccess, onFail, param) {
    return exec(onSuccess, onFail, 'CDVPluginAudioPlayer', action, [param]);
  }

  // promise で返す。 cordova の excuter の wrapper
  createAction(action, params) {
    return new Promise((resolve, reject) => {
      // actionが定義されているかを判定したい
      if (true) {
        // cordova 実行ファイルを登録
        this.registerCordovaExecuter(action, resolve, reject, params);
      }
      else {
        // TODO: error handling
      }
    });
  }

}

class AudioPlayer {

  constructor({ id, path, duration }) {
    this.id = id; // id
    this.path = path; // file path
    this.duration = duration; // 長さ
    this.paused = true;
    this._currentTime = 0;

    this._listeners = {};

    //　イベント登録
    this.registerEvents('play', 'setOnPlayCallbackId', { id });
    this.registerEvents('pause', 'setOnPauseCallbackId', { id });
    this.registerEvents('stop', 'setOnStopCallbackId', { id });
    this.registerEvents('ended', 'setOnEndedCallbackId', { id });
    this._privateListeners = {
      play: (e) => {
        this._currentTime = e.currentTime;
        this._startTime = performance.now();
      },
      ended: () => {
        this.paused = true;
        this._currentTime = 0;
      },
    };
  }

  // 音楽再生
  play(time) {
    return this._play(time);
  }
  _play(time) {
    this.paused = false;
    if (time === undefined) {
      this._startTime = performance.now() + START_TIME_LAG;
      return this.exec('play');
    }
    this._startTime = performance.now() + time * 1000;
    return this.exec('play', { time });
  }
  // 音楽一時停止
  pause() {
    if (this.paused) {
      return;
    }
    this._currentTime = this.currentTime;
    this.paused = true;
    return this.exec('pause');
  }
  // 音楽一時停止かつメモリバッファから音声データを破棄
  stop() {
    if (!this.paused) {
      this._currentTime = this.currentTime;
    }
    this.paused = true;
    return this.exec('stop');
  }

  get currentTime() {
    if (this.paused) {
      return this._currentTime;
    }
    return Math.max(0, this._currentTime + (performance.now() - this._startTime) / 1000);
  }

  // ネイティブにセットしてJSの値を更新する
  set currentTime(time) {
    this._currentTime = time;
    this.setCurrentTime(time);
  }

  // ネイティブから currentTime を取得する
  getCurrentTime() {
    return this.exec('getCurrentTime');
  }
  // ネイティブのプレイヤーに currentTime をセットする
  setCurrentTime(time) {
    return this.exec('setCurrentTime', { time });
  }
  close() {
    return this.exec('close');
  }

  // 登録関係
  on(event, callback) {
    this._listeners[event] = this._listeners[event] || [];
    this._listeners[event].push(callback);
  }

  off(event, callback) {
    if (!this._listeners[event]) this._listeners[event] = [];
    if (event && typeof callback === 'function') {
      var i = this._listeners[event].indexOf(callback);
      if (i !== -1) {
        this._listeners[event].splice(i, 1);
      }
    }
  }

  trigger(event, value) {
    if (this._listeners[event]) {
      this._listeners[event].forEach(callback => {
        if (typeof callback === 'function') {
          callback(value);
        }
      });
    }
  }

  clearEventListener(event) {
    this._listeners[event] = [];
  }


  // ========================== private 関数 ==============================================
  // promise で返す。 cordova の excuter の wrapper
  exec(action, params = {}) {
    params.id = this.id;
    return new Promise((resolve, reject) => {
      // actionが定義されているかを判定したい
      if (true) {
        // cordova 実行ファイルを登録
        exec(resolve, reject, 'CDVPluginAudioPlayer', action, [params]);
      }
      else {
        // TODO: error handling
      }
    });
  }

  // TODO: メモリリークしないかチェック
  // イベントをバインド
  registerEvents(eventName, action, params) {
    exec(
      (data) => {
        this._triggerPrivate(eventName, data);
        this.trigger(eventName, data);
      },
      (error) => {
        console.log(error, 'error');
      }, 'CDVPluginAudioPlayer', action, [params]
    );
  }

  _triggerPrivate(eventName, data) {
    const f = this._privateListeners[eventName];
    f && f(data);
  }

}

module.exports = new AudioPlayerManager();
