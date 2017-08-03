import {Socket} from "phoenix"
import format from "./color"

let socket = new Socket("/socket", {})
socket.connect()

function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
  }
  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
}

let options = {
  echo: true,
};
let commandHistory = [];

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("telnet:" + guid(), {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

channel.on("option", payload => {
  let commandPrompt = document.getElementById("prompt")

  switch (payload.type) {
    case "echo":
      options.echo = payload.echo

      if (payload.echo) {
        commandPrompt.type = "text"
      } else {
        commandPrompt.type = "password"
      }

      break;
    default:
      console.log("No option found")
  }
})
channel.on("prompt", payload => {
  let message = format(payload.message)
  let html = document.createElement('span');
  html.innerHTML = message;

  document.getElementById("terminal").append(html)
  window.scrollTo(0, document.body.scrollHeight);
})
channel.on("echo", payload => {
  let message = format(payload.message)
  let html = document.createElement('span');
  html.innerHTML = message;

  document.getElementById("terminal").append(html)
  window.scrollTo(0, document.body.scrollHeight);
})
channel.on("disconnect", payload => {
  document.getElementById("terminal").append("\nDisconnected.")
  socket.disconnect()
})

document.getElementById("prompt").addEventListener("keydown", e => {
  let commandPrompt = document.getElementById("prompt")
  let cmdIndex = commandHistory.indexOf(commandPrompt.value)

  switch (e.keyCode) {
    case 38:
      if (cmdIndex > 0) {
        commandPrompt.value = commandHistory[cmdIndex - 1]
      } else if (cmdIndex == 0) {
        // do nothing at the end of the list
      } else {
        commandPrompt.value = commandHistory[commandHistory.length - 1]
      }
      break;

    case 40:
      if (cmdIndex >= 0) {
        if (commandHistory[cmdIndex + 1] != undefined) {
          commandPrompt.value = commandHistory[cmdIndex + 1]
        } else {
          commandPrompt.value = ""
        }
      }
      break;
  }
})
document.getElementById("prompt").addEventListener("keypress", e => {
  if (e.keyCode == 13) {
    var command = document.getElementById("prompt").value

    if (options.echo) {
      commandHistory.push(command)
      if (commandHistory.length > 10) {
        commandHistory.shift()
      }

      let html = document.createElement('span');
      html.innerHTML = command + "<br/>";
      document.getElementById("terminal").append(html)
    }

    document.getElementById("prompt").value = ""
    channel.push("recv", {message: command})
  }
})

export default socket
