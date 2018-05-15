import {Socket} from "phoenix"
import Sizzle from "sizzle"
import _ from "underscore"

import {format} from "./color"

var body = document.getElementById("body")
var userToken = body.getAttribute("data-user-token")

let socket = new Socket("/socket", {params: {token: userToken}})
socket.connect()

class Channels {
  join() {
    this.channels = {};

    _.each(Sizzle(".channel"), (channel) => {
      this.connectChannel(channel);
    });

    this.connectSend();
    this.connectTabHandlers();
  }

  connectChannel(channelEl) {
    let channelName = channelEl.dataset.channel;

    let channel = socket.channel(`chat:${channelName}`, {});
    this.channels[channelName] = channel;

    channel.on("broadcast", (data) => {
      this.alertChannel(channelName);
      this.appendMessage(channelEl, data);
    })

    channel.join();
    this.appendMessage(channelEl, {message: "Connected"});
  }

  connectSend() {
    let chatPrompt = _.first(Sizzle("#chat-prompt"));
    chatPrompt.addEventListener("keypress", e => {
      if (e.keyCode == 13) {
        this.sendMessage();
      }
    })

    let send = _.first(Sizzle("#chat-send"));
    send.addEventListener("click", e => {
      this.sendMessage();
    });
  }

  connectTabHandlers() {
    _.each(Sizzle(".channel-tab"), channelTab => {
      channelTab.addEventListener("click", (e) => {
        let bellIcon = _.first(Sizzle(".bell", channelTab));
        bellIcon.classList.add("hidden");
      });
    });
  }

  sendMessage() {
    let chatPrompt = _.first(Sizzle("#chat-prompt"));
    let activeChannel = _.first(Sizzle(".channel.active"));
    let channel = this.channels[activeChannel.dataset.channel];
    channel.push("send", {message: chatPrompt.value});
    chatPrompt.value = "";
  }

  appendMessage(channelEl, data) {
    var fragment = document.createDocumentFragment();
    let html = document.createElement("div");
    html.innerHTML = format(data);
    fragment.appendChild(html);

    channelEl.appendChild(fragment);
  }

  alertChannel(channelName) {
    let channelTab = _.first(Sizzle(`.channel-tab[data-channel="${channelName}"]`));
    let activeChannel = _.first(Sizzle(".channel.active"));
    if (activeChannel.dataset.channel != channelName) {
      let bellIcon = _.first(Sizzle(".bell", channelTab));
      bellIcon.classList.remove("hidden");
    }
  }
}

export {Channels}
