import {Socket} from "phoenix"

let socket = new Socket("/socket", {})
socket.connect()

function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
  }
  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
}

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("telnet:" + guid(), {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

channel.on("prompt", payload => {
  document.getElementById("terminal").append(payload.message)
  window.scrollTo(0, document.body.scrollHeight);
})
channel.on("echo", payload => {
  document.getElementById("terminal").append(payload.message)
  document.getElementById("terminal").append("\n")
  window.scrollTo(0, document.body.scrollHeight);
})
channel.on("disconnect", payload => {
  document.getElementById("terminal").append("\nDisconnected.")
  socket.disconnect()
})

document.getElementById("command").addEventListener("keypress", e => {
  if (e.keyCode == 13) {
    var command = document.getElementById("command").value
    document.getElementById("terminal").append(command + "\n")
    document.getElementById("command").value = ""
    channel.push("recv", {message: command})
  }
})

export default socket
