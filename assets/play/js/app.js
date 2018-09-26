import "phoenix_html"

import {Socket} from "phoenix"
import Sizzle from "sizzle"
import _ from "underscore"

import ChannelWrapper from "./channelWrapper"
import CommandHistory from "./command-history"
import {gmcpMessage} from "./gmcp"
import Logger from "./logger"
import Keys from "./keys"
import {appendMessage, scrollToBottom} from "./panel"
import {guid} from "./utils"

window.gameConfig = {};

var body = document.getElementById("body");
var userToken = body.getAttribute("data-user-token");

let keys = new Keys();
let socket = new Socket("/socket", {params: {token: userToken}});
socket.connect();

let options = {
  echo: true,
};

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("telnet:" + guid(), {})
let channelWrapper = new ChannelWrapper(channel)

channel.onMessage = function (event, payload, ref) {
  if (payload != undefined && payload.sent_at) {
    let sentAt = Date.parse(payload.sent_at)
    let receivedAt = new Date().getTime()
    let totalTimeMs = receivedAt - sentAt
    Logger.log(event, `${totalTimeMs}ms`)
  }
  return payload
}

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
channel.on("prompt", payload => {
  appendMessage(payload);
});
channel.on("echo", payload => {
  appendMessage(payload);
});
channel.on("disconnect", payload => {
  document.getElementById("terminal").append("\nDisconnected.");
  socket.disconnect();

  let html = document.createElement("div");
  html.innerHTML = "<a class='white' href='#'>Reconnect</a>";
  let reconnectButton = html.children[0];
  reconnectButton.addEventListener("click", e => {
    e.preventDefault();
    window.location.reload();
  });

  document.getElementById("terminal").append("\n\n");
  document.getElementById("terminal").append(reconnectButton);

  scrollToBottom(".panel");
});

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

let sendCommand = command => {
  if (options.echo) {
    commandHistory.add(command);
    appendMessage({message: command + "<br />", delink: true});
  }

  document.getElementById("prompt").value = "";
  channelWrapper.send(command);
}

document.getElementById("prompt").addEventListener("keypress", e => {
  if (e.keyCode == 13) {
    var command = document.getElementById("prompt").value
    sendCommand(command);
  }
})

document.addEventListener("click", e => {
  if (e.target.classList.contains("command")){
    if (e.target.dataset.command != undefined) {
      sendCommand(e.target.dataset.command);
    } else {
      sendCommand(e.target.innerText);
    }
  }
}, false);

document.addEventListener("mouseover", e => {
  if (e.target.classList.contains("command")) {
    if (e.target.dataset.command != undefined) {
      e.target.setAttribute("data-title", e.target.dataset.command);
    } else {
      e.target.setAttribute("data-title", e.target.innerText);
    }
  }
}, false);

document.addEventListener("keydown", e => {
  if (!keys.isModifierKeyPressed()) {
    document.getElementById("prompt").focus();
  }
});

channelWrapper.join();
