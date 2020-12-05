export default class Keys {
  constructor() {
    this.keysDown = [];
    this.listeners = {};

    window.addEventListener("blur", () => {
      this.keysDown = [];
    });

    document.addEventListener("keydown", (e) => {
      this.keyDown(e);
    });

    document.addEventListener("keyup", (e) => {
      this.keyUp(e.key);
    });
  }

  isModifierKeyPressed() {
    return (
      this.keysDown.includes("Control") ||
      this.keysDown.includes("Alt") ||
      this.keysDown.includes("Meta") ||
      this.keysDown.includes("Tab") ||
      this.keysDown.includes("Enter")
    );
  }

  keyDown(event) {
    this.keysDown.push(event.key);

    if (this.listeners[this.keysDown] != undefined) {
      this.listeners[this.keysDown].map((callback) => {
        callback(event);
      });
    }
  }

  keyUp(keyDown) {
    this.keysDown = this.keysDown.filter((key) => {
      return key != keyDown;
    });
  }

  on(event, callback) {
    let listeners = this.listeners[event] || [];
    listeners.push(callback);
    this.listeners[event] = listeners;
  }
}
