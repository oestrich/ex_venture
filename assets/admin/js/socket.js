import {Socket} from "phoenix"
import _ from "underscore"
import $ from "jquery"
import format from "./color"

export class NPCSocket {
  constructor(spawnerId) {
    this.spawnerId = spawnerId
  }

  connect() {
    let body = $("body")
    let userToken = body.data("user-token")

    this.socket = new Socket("/admin/socket", {params: {token: userToken}})
    this.socket.connect()

    this.channel = this.socket.channel("npc:" + this.spawnerId, {})

    this.channel.on("room/entered", msg => {
      this.append(`${msg.name} entered`)
    })

    this.channel.on("room/leave", msg => {
      this.append(`${msg.name} left`)
    })

    this.channel.on("room/heard", msg => {
      this.append(msg.formatted);
    })

    $(".npc-chat").on("keyup", e => {
      if (e.which == 13 && $(".npc-chat").val() != "") {
        let action = $("#npc-action").val()
        this.channel.push(action, {message: $(".npc-chat").val()})
        $(".npc-chat").val("")
      }
    })

    $(".npc-console").append("Connecting...\n")
    this.channel.join()
      .receive("ok", resp => { $(".npc-console").append("Connected\n") })
      .receive("error", resp => { $(".npc-console").append(`Failed to connect: ${resp.reason}`) })
  }

  append(text) {
    let console = $(".npc-console")
    console.append(format(`${text}\n`))
    console.scrollTop(console.prop("scrollHeight"))
  }
}

window.NPCSocket = NPCSocket
