'use strict';

class AudioPlayerManager {
  constructor(params) {
    this.exec = require('cordova/exec');
    this.players = [];
  }

  async create({path, isLoop}) {
    // id, path, duration
    const data = await this.createAction('create', {path, isLoop});
    const player = new AudioPlayer(data);
    this.players.push(player);
  
    return player;
  }

  getPlayer({id}) {
    return this.players.find((item) => item.id === id);
  }
  
  async removePlayer({id}) {
    await this.createAction('remove', {id})
    const idx = this.players.findIndex((item) => item.id === id);
    this.players.splice(idx, 1);
    return true
  }

  async removeAll() {
    const promises = this.players.map(player => {
      return this.createAction('remove', {id: player.id});
    })
    await Promise.all(promises);
    this.players = [];
    return true
  }

  // cordova の実行ファイルを登録する
  registerCordovaExecuter(action, onSuccess, onFail, param) {
    return this.exec(onSuccess, onFail, 'CDVPluginAudioPlayer', action, [param]);
  };

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
  };

}

class AudioPlayer {

  constructor({id, path, duration}) {
    this.id = id; // id
    this.path = path; // file path
    this.duration = duration; // 長さ


    this.exec = require('cordova/exec');
    this._listeners = {};

    //　イベント登録
    this.registerEvents('play', 'setOnPlayCallbackId', {id});
    this.registerEvents('pause', 'setOnPauseCallbackId', {id});
    this.registerEvents('stop', 'setOnStopCallbackId', {id});
    this.registerEvents('ended', 'setOnEndedCallbackId', {id});

  }

  // 音楽再生
  play(time) {
    return this.createAction('play', {id: this.id, time});
  }
  // 音楽一時停止
  pause() {
    return this.createAction('pause', {id: this.id});
  }
  // 音楽停止
  stop() {
    return this.createAction('stop', {id: this.id});
  }
  getCurrentTime() {
    return this.createAction('getCurrentTime', {id: this.id});
  }
  setCurrentTime(time) {
    return this.createAction('setCurrentTime', {id: this.id, time});
  }

  // 登録関係
  on(event, callback) {
    this._listeners[event] = this._listeners[event] || [];
    this._listeners[event].push(callback);
  };
  off(event, callback) {
    if (!this._listeners[event]) this._listeners[event] = [];
    if (event && typeof callback === 'function') {
      var i = this._listeners[event].indexOf(callback);
      if (i !== -1) {
        this._listeners[event].splice(i, 1);
      }
    }
  };
  trigger(event, value) {
    if (this._listeners[event]) {
        this._listeners[event].forEach(callback => {
          if (typeof callback === 'function') {
            callback(value);
          }
      });
    }
  };
  clearEventListner(event) {
    this._listeners[event] = [];
  };


  // ========================== private 関数 ==============================================
  // promise で返す。 cordova の excuter の wrapper
  createAction(action, params = {}) {
    return new Promise((resolve, reject) => {
      // actionが定義されているかを判定したい
      if (true) {
        params.timestamp = Date.now() / 1000;
        // cordova 実行ファイルを登録
        this.registerCordovaExecuter(action, resolve, reject, params);
      }
      else {
        // TODO: error handling
      }
    });
  };
  // cordova の実行ファイルを登録する
  registerCordovaExecuter(action, onSuccess, onFail, param) {
    return this.exec(onSuccess, onFail, 'CDVPluginAudioPlayer', action, [param]);
  };
  
  // イベントをバインド
  registerEvents(onSuccess, action, params) {
    this.exec(
      (data) => {
        this.trigger(onSuccess, data);
      }, 
      (error) => {
        console.log(error, 'error');
      }, 'CDVPluginAudioPlayer', action, [params]
    );
  };

}

module.exports = new AudioPlayerManager();
