import "phoenix_html"
import socket from "./socket"

let inputFocus = function() {
  document.getElementById("prompt").focus();
}

window.onkeydown = inputFocus;
