import {Socket} from "phoenix"
import Sizzle from "sizzle"
import _ from "underscore"

import CommandHistory from "./command-history"
import {appendMessage, scrollToBottom} from "./panel"
import {gmcpMessage} from "./gmcp"
import {guid} from "./utils"

class ChannelWrapper {
  constructor(channel) {
    this.channel = channel
  }

  send(message) {
    this.channel.push("recv", {message: message})
  }
}

var body = document.getElementById("body")
var userToken = body.getAttribute("data-user-token")

let socket = new Socket("/socket", {params: {token: userToken}})
socket.connect()

let options = {
  echo: true,
};

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("telnet:" + guid(), {})
let channelWrapper = new ChannelWrapper(channel)

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

channel.on("gmcp", gmcpMessage(channelWrapper))
channel.on("prompt", appendMessage)
channel.on("echo", appendMessage)
channel.on("disconnect", payload => {
  document.getElementById("terminal").append("\nDisconnected.")
  socket.disconnect()
  scrollToBottom()
})

let commandHistory = new CommandHistory()

document.getElementById("prompt").addEventListener("keydown", e => {
  let commandPrompt = document.getElementById("prompt")

  switch (e.keyCode) {
    case 38:
      commandHistory.scrollBack((command) => {
        commandPrompt.value = command
      })
      break;
    case 40:
      commandHistory.scrollForward((command) => {
        commandPrompt.value = command
      })
      break;
  }
})

document.getElementById("prompt").addEventListener("keypress", e => {
  if (e.keyCode == 13) {
    var command = document.getElementById("prompt").value

    if (options.echo) {
      commandHistory.add(command)

      let html = document.createElement('span');
      html.innerHTML = command + "<br/>";
      document.getElementById("terminal").append(html)
    }

    document.getElementById("prompt").value = ""
    channelWrapper.send(command)
  }
})

export {channel}
