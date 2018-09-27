import _ from "underscore"

export default class Keys {
  constructor() {
    this.keysDown = [];
    this.listeners = {};

    document.addEventListener("keydown", e => {
      this.keyDown(e.key);
    });

    document.addEventListener("keyup", e => {
      this.keyUp(e.key);
    });
  }

  isModifierKeyPressed() {
    return this.keysDown.includes("Control") || this.keysDown.includes("Alt") || this.keysDown.includes("Meta");
  }

  keyDown(key) {
    this.keysDown.push(key);

    if (this.listeners[this.keysDown] != undefined) {
      _.each(this.listeners[this.keysDown], callback => {
        callback();
      });
    }
  }

  keyUp(keyDown) {
    this.keysDown = this.keysDown.filter(key => {
      return key != keyDown;
    });
  }

  on(event, callback) {
    let listeners = this.listeners[event] || [];
    listeners.push(callback);
    this.listeners[event] = listeners;
  }
}
