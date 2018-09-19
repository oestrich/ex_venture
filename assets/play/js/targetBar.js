import Sizzle from "sizzle"
import _ from "underscore"

import {appendMessage} from "./panel"

export default class TargetBar {
  constructor(channel, targetBar, currentTarget) {
    this.channel = channel;
    this.targetBar = targetBar;
    this.currentTarget = currentTarget;
  }

  reset() {
    this.targetBar.innerHTML = "";
  }

  render(character, color) {
    let html = document.createElement('div');
    html.innerHTML = `<div class="button tooltip" data-title="Select Target">
      <div class="container">
        <span class="${color}">${character.name}</span>
      </div>
    </div>`;

    let target = html.children[0];
    if (this.currentTarget != null && this.currentTarget.type == character.type && this.currentTarget.id == character.id) {
      target.classList.add("selected");
    }

    target.addEventListener("click", (e) => {
      appendMessage({message: `target ${character.name}`});
      this.channel.sendGMCP("Target.Set", {name: character.name});
    });

    this.targetBar.append(target);
  }
}
