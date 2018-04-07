import Sizzle from "sizzle"
import _ from "underscore"

import {format} from "./color"

let scrollToBottom = (callback) => {
  let panel = _.first(Sizzle(".panel"))

  if (callback != undefined) {
    callback();
  }

  panel.scrollTop = panel.scrollHeight;
}

let appendMessage = (payload) => {
  let message = format(payload);
  var fragment = document.createDocumentFragment();
  let html = document.createElement('span');
  html.innerHTML = message;
  fragment.appendChild(html);

  scrollToBottom(() => {
    document.getElementById("terminal").appendChild(fragment);
  })
}

export { appendMessage, scrollToBottom }
