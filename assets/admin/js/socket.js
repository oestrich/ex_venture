import {Socket} from "phoenix"
import _ from "underscore"
import $ from "jquery"
import format from "./color"

export class NPCSocket {
  constructor(spawnerId, npcName) {
    this.spawnerId = spawnerId
    this.npcName = npcName
  }

  formatName(character) {
    if (character.type === "user") {
      return `{player}${character.name}{/player}`;
    }

    if (character.type === "npc") {
      return `{npc}${character.name}{/npc}`;
    }
  }

  connect() {
    let body = $("body")
    let userToken = body.data("user-token")

    this.socket = new Socket("/admin/socket", {params: {token: userToken}})
    this.socket.connect()

    this.channel = this.socket.channel("npc:" + this.spawnerId, {})

    this.channel.on("character/died", msg => {
      this.append(`{npc}${this.npcName}{/npc} died`)
    });

    this.channel.on("character/respawned", msg => {
      this.append(`{npc}${this.npcName}{/npc} respawned`)
    });

    this.channel.on("character/targeted", msg => {
      this.append(`${this.formatName(msg)} targeted`)
    });

    this.channel.on("combat/targeted", msg => {
      this.append(`{npc}${this.npcName}{/npc} targeted by ${this.formatName(msg)}`)
    });

    this.channel.on("combat/action", msg => {
      let combatText = `{npc}${this.npcName}{/npc} attacks ${this.formatName(msg.target)}: ${msg.text}`
      msg.effects.map(effect => {
        combatText += "\n" + JSON.stringify(effect)
      })
      this.append(combatText)
    });

    this.channel.on("combat/effects", msg => {
      let combatText = `{npc}${this.npcName}{/npc} received effects from ${this.formatName(msg.from)}: ${msg.text}`
      msg.effects.map(effect => {
        combatText += "\n" + JSON.stringify(effect)
      })
      this.append(combatText)
    });

    this.channel.on("room/entered", msg => {
      this.append(`${this.formatName(msg)} entered`)
    });

    this.channel.on("room/leave", msg => {
      this.append(`${this.formatName(msg)} left`)
    });

    this.channel.on("room/heard", msg => {
      this.append(msg.formatted);
    });

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
    console.append(format(`\n${text}\n`))
    console.scrollTop(console.prop("scrollHeight"))
  }
}

export class UserSocket {
  constructor(userId) {
    this.userId = userId
  }

  connect() {
    let body = $("body")
    let userToken = body.data("user-token")

    this.socket = new Socket("/admin/socket", {params: {token: userToken}})
    this.socket.connect()

    this.channel = this.socket.channel("user:" + this.userId, {})

    this.channel.on("echo", msg => {
      this.append(msg.data)
    })

    this.append("Connecting...")
    this.channel.join()
      .receive("ok", resp => { this.append("Connected") })
      .receive("error", resp => { this.append(`Failed to connect: ${resp.reason}`) })
  }

  append(text) {
    let console = $(".console")
    console.append(format(`${text}\n`))
    console.scrollTop(console.prop("scrollHeight"))
  }
}

window.NPCSocket = NPCSocket;
window.UserSocket = UserSocket;
