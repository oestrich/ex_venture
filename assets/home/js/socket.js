import {Socket} from "phoenix"
import Sizzle from "sizzle"
import _ from "underscore"

import {format} from "./color"

var body = document.getElementById("body")
var userToken = body.getAttribute("data-user-token")

let socket = new Socket("/socket", {params: {token: userToken}})
socket.connect()

// Now that you are connected, you can join channels with a topic:

class Channels {
  join() {
    console.log("Connecting...")

    this.channels = {}

    _.each(Sizzle(".channel"), (channel) => {
      this.connectChannel(channel)
    })

    this.connectSend()
  }

  connectChannel(channelEl) {
    let channelName = channelEl.dataset.channel;

    let channel = socket.channel(`chat:${channelName}`, {});

    channel.on("broadcast", (data) => {
      var fragment = document.createDocumentFragment();
      let html = document.createElement("div");
      html.innerHTML = format(data);
      fragment.appendChild(html);

      channelEl.appendChild(fragment);
    })

    channel.join();

    this.channels[channelName] = channel;
  }

  connectSend() {
    let send = _.first(Sizzle("#chat-prompt"));
    send.addEventListener("keypress", e => {
      if (e.keyCode == 13) {
        let activeChannel = _.first(Sizzle(".channel.active"));
        let channel = this.channels[activeChannel.dataset.channel];
        channel.push("send", {message: send.value});
        send.value = "";
      }
    })
    console.log(send);
  }
}

export {Channels}
