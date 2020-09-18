'use strict';

const exec = require('cordova/exec');
class AudioPlayerManager {
  constructor() {
  }

  async create({ path, isLoop }) {
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

    this._listeners = {};

    //　イベント登録
    this.registerEvents('play', 'setOnPlayCallbackId', { id });
    this.registerEvents('pause', 'setOnPauseCallbackId', { id });
    this.registerEvents('stop', 'setOnStopCallbackId', { id });
    this.registerEvents('ended', 'setOnEndedCallbackId', { id });
    this.on('ended', () => {
      this.paused = true;
    });
  }

  // 音楽再生
  play(time) {
    this.paused = false;
    if (time === undefined) {
      return this.exec('play');
    }
    return this.exec('play', { time });
  }
  // 音楽一時停止
  pause() {
    this.paused = true;
    return this.exec('pause');
  }
  // 音楽停止
  stop() {
    this.paused = true;
    return this.exec('stop');
  }
  getCurrentTime() {
    return this.exec('getCurrentTime');
  }
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
        params.timestamp = Date.now() / 1000;
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
  registerEvents(onSuccess, action, params) {
    exec(
      (data) => {
        this.trigger(onSuccess, data);
      },
      (error) => {
        console.log(error, 'error');
      }, 'CDVPluginAudioPlayer', action, [params]
    );
  }

}

module.exports = new AudioPlayerManager();
