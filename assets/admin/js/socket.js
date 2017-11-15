import {Socket} from "phoenix"
import _ from "underscore"
import $ from "jquery"

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
      this.append(`${msg.name} says, "${msg.message}"`)
    })

    $(".npc-chat").on("keyup", e => {
      if (e.which == 13 && $(".npc-chat").val() != "") {
        this.channel.push("say", {message: $(".npc-chat").val()})
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
    console.append(`${text}\n`)
    console.scrollTop(console.prop("scrollHeight"))
  }
}

window.NPCSocket = NPCSocket
