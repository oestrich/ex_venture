import Sizzle from "sizzle"
import _ from "underscore"

import format from "./color"

let scrollToBottom = (callback) => {
  let panel = _.first(Sizzle(".panel"))

  if (callback != undefined) {
    callback();
  }

  panel.scrollTop = panel.scrollHeight;
}

let appendMessage = (payload) => {
  let message = format(payload.message)
  let html = document.createElement('span');
  html.innerHTML = message;

  scrollToBottom(() => {
    document.getElementById("terminal").append(html)
  })
}

export { appendMessage, scrollToBottom }
