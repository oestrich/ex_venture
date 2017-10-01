import {Socket} from "phoenix"
import format from "./color"
import Sizzle from "sizzle"
import _ from "underscore"

var body = document.getElementById("body")
var userToken = body.getAttribute("data-user-token")

let socket = new Socket("/socket", {params: {token: userToken}})

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
let commandIndex = -1;

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
channel.on("gmcp", payload => {
  let data = JSON.parse(payload.data)

  switch(payload.module) {
    case "Character":
      console.log(`Signed in as ${data.name}`)
      let stats = _.first(Sizzle(".stats"));
      stats.style.display = "inherit";

      break;
    case "Character.Vitals":
      let healthWidth = data.health / data.max_health;
      let skillWidth = data.skill_points / data.max_skill_points;
      let moveWidth = data.move_points / data.max_move_points;

      let health = _.first(Sizzle("#health .container"));
      health.style.width = `${healthWidth * 100}%`;
      let healthStat = _.first(Sizzle("#health .stat"));
      healthStat.innerHTML = `${data.health}/${data.max_health}`;

      let skill = _.first(Sizzle("#skills .container"));
      skill.style.width = `${skillWidth * 100}%`;
      let skillStat = _.first(Sizzle("#skills .stat"));
      skillStat.innerHTML = `${data.skill_points}/${data.max_skill_points}`;

      let movement = _.first(Sizzle("#movement .container"));
      movement.style.width = `${moveWidth * 100}%`;
      let movementStat = _.first(Sizzle("#movement .stat"));
      movementStat.innerHTML = `${data.move_points}/${data.max_move_points}`;

      break;
    default:
      console.log("Module not found")
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
  window.scrollTo(0, document.body.scrollHeight);
})

document.getElementById("prompt").addEventListener("keydown", e => {
  let commandPrompt = document.getElementById("prompt")

  switch (e.keyCode) {
    case 38:
      if (commandHistory[commandIndex + 1] != undefined) {
        commandIndex += 1
        commandPrompt.value = commandHistory[commandIndex]
      }
      break;

    case 40:
      if (commandHistory[commandIndex - 1] != undefined) {
        commandIndex -= 1
        commandPrompt.value = commandHistory[commandIndex]
      } else if (commandIndex - 1 <= -1) {
        commandIndex = -1
        commandPrompt.value = ""
      }

      break;
  }
})
document.getElementById("prompt").addEventListener("keypress", e => {
  if (e.keyCode == 13) {
    var command = document.getElementById("prompt").value

    if (options.echo) {
      if (command != "") {
        commandIndex = -1
        commandHistory.unshift(command)
        if (commandHistory.length > 10) {
          commandHistory.pop()
        }
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
