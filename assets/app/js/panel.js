import Sizzle from "sizzle"
import _ from "underscore"

import format from "./color"

let scrollToBottom = () => {
  let panel = _.first(Sizzle(".panel"))
  panel.scrollTop = panel.scrollHeight
}

let appendMessage = (payload) => {
  let message = format(payload.message)
  let html = document.createElement('span');
  html.innerHTML = message;

  document.getElementById("terminal").append(html)
  scrollToBottom()
}

export { appendMessage, scrollToBottom }
