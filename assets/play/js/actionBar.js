import Sizzle from "sizzle";
import _ from "underscore";

import {appendMessage} from "./panel";

export default class ActionBar {
  constructor(channel, actionBar, context) {
    this.channel = channel;
    this.actionBar = actionBar;
    this.context = context;
    this.actions = this.fill(context.actions);
  }

  fill(actions) {
    _.map([...Array(10).keys()], i => {
      if (actions[i] == undefined) {
        actions[i] = null;
      }
    });

    return actions;
  }

  render() {
    this.actionBar.innerHTML = "";

    _.map(this.actions, (action) => {
      let html = document.createElement('div');

      html.innerHTML = `<div class="button">
        <div class="container"></div>
      </div>`;
      let actionElement = html.children[0];

      if (action != null) {
        if (action.type == "skill") {
          if (!action.active) {
            actionElement.classList.add("inactive");
          }

          let skill = this.context.skills.find(skill => {
            return skill.name == action.name;
          });

          if (skill && !skill.active) {
            actionElement.classList.add("inactive");
          }

          this.fillInAction(actionElement, action.name, action.command, action.command);
        }

        if (action.type == "command") {
          this.fillInAction(actionElement, action.name, action.command, action.command);
        }
      } else {
        let container = _.first(actionElement.querySelectorAll(".container"));
        container.classList.add("empty");
        container.innerHTML = "&nbsp;";
      }

      this.actionBar.append(actionElement);
    });
  }

  fillInAction(element, title, tooltip, command) {
    element.classList.add("tooltip");
    element.dataset.title = tooltip;
    let container = _.first(element.querySelectorAll(".container"));
    container.innerHTML = title;

    element.addEventListener("click", (e) => {
      appendMessage({message: `${command}\n`});
      this.channel.send(command);
    });
  }
}
