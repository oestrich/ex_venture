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
  var prompt = document.getElementById("command")

  switch (payload.type) {
    case "echo":
      options.echo = payload.echo

      if (payload.echo) {
        prompt.type = "text"
      } else {
        prompt.type = "password"
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

document.getElementById("command").addEventListener("keydown", e => {
  let command = document.getElementById("command")
  let cmdIndex = commandHistory.indexOf(command.value)

  switch (e.keyCode) {
    case 38:
      if (cmdIndex > 0) {
        command.value = commandHistory[cmdIndex - 1]
      } else if (cmdIndex == 0) {
        // do nothing at the end of the list
      } else {
        command.value = commandHistory[commandHistory.length - 1]
      }
      break;

    case 40:
      if (cmdIndex >= 0) {
        if (commandHistory[cmdIndex + 1] != undefined) {
          command.value = commandHistory[cmdIndex + 1]
        } else {
          command.value = ""
        }
      }
      break;
  }
})
document.getElementById("command").addEventListener("keypress", e => {
  if (e.keyCode == 13) {
    var command = document.getElementById("command").value

    if (options.echo) {
      commandHistory.push(command)
      if (commandHistory.length > 10) {
        commandHistory.shift()
      }

      let html = document.createElement('span');
      html.innerHTML = command + "<br/>";
      document.getElementById("terminal").append(html)
    }

    document.getElementById("command").value = ""
    channel.push("recv", {message: command})
  }
})

export default socket
