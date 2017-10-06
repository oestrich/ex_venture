import "phoenix_html"
import {channel} from "./socket"

let inputFocus = function() {
  document.getElementById("prompt").focus();
}

window.onkeydown = inputFocus;

channel.join()
