import Sizzle from "sizzle"
import _ from "underscore"

import {format} from "./color"

let scrollToBottom = (panelSelector, callback) => {
  let panel = _.first(Sizzle(panelSelector));

  if (callback != undefined) {
    callback();
  }

  panel.scrollTop = panel.scrollHeight;
}

let appendMessage = (payload, terminalSelector, panelSelector) => {
  if (!terminalSelector) {
    terminalSelector = "terminal";
  }
  if (!panelSelector) {
    panelSelector = ".panel";
  }

  let message = format(payload);
  var fragment = document.createDocumentFragment();
  let html = document.createElement('span');
  html.innerHTML = message;
  fragment.appendChild(html);

  scrollToBottom(panelSelector, () => {
    document.getElementById(terminalSelector).appendChild(fragment);
  });
}

export { appendMessage, scrollToBottom }
