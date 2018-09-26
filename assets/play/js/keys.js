export default class Keys {
  constructor() {
    this.keysDown = [];

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
  }

  keyUp(keyDown) {
    this.keysDown = this.keysDown.filter(key => {
      return key != keyDown;
    });
  }
}
