import Sizzle from "sizzle"
import _ from "underscore"

import format from "./color"

let scrollToBottom = (callback) => {
  let panel = _.first(Sizzle(".panel"))

  let willScroll = panel.scrollHeight - panel.scrollTop - panel.offsetHeight < 0;

  if (callback != undefined) {
    callback();
  }

  if (willScroll) {
    panel.scrollTop = panel.scrollHeight;
  }
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
