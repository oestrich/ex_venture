import Sizzle from "sizzle"
import _ from "underscore"

/**
 * Character module
 */
let character = (channel, data) => {
  console.log(`Signed in as ${data.name}`)
  let stats = _.first(Sizzle(".stats"));
  stats.style.display = "flex";
  let roomInfo = _.first(Sizzle(".room-info"));
  roomInfo.style.display = "inherit";
}

/**
 * Character.Vitals module
 */
let characterVitals = (channel, data) => {
  let healthWidth = data.health / data.max_health;
  let skillWidth = data.skill_points / data.max_skill_points;
  let moveWidth = data.move_points / data.max_move_points;

  let health = _.first(Sizzle("#health .container"));
  health.style.width = `${healthWidth * 100}%`;
  let healthStat = _.first(Sizzle("#health .stat"));
  healthStat.innerHTML = `${data.health}/${data.max_health} hp`;

  let skill = _.first(Sizzle("#skills .container"));
  skill.style.width = `${skillWidth * 100}%`;
  let skillStat = _.first(Sizzle("#skills .stat"));
  skillStat.innerHTML = `${data.skill_points}/${data.max_skill_points} ${data.skill_abbreviation.toLowerCase()}`;

  let movement = _.first(Sizzle("#movement .container"));
  movement.style.width = `${moveWidth * 100}%`;
  let movementStat = _.first(Sizzle("#movement .stat"));
  movementStat.innerHTML = `${data.move_points}/${data.max_move_points} mv`;
}

/**
 * Room state
 */
let room = {};

let sendExit = (channel, exit) => {
  return (e) => {
    channel.send(exit)
  }
}

/**
 * Render a room into the side panel
 */
let renderRoom = (channel, room) => {
  let roomName = _.first(Sizzle(".room-info .room-name"))
  roomName.innerHTML = room.name

  let exits = _.first(Sizzle(".room-info .exits"))
  exits.innerHTML = ""
  _.each(room.exits, (exit) => {
    let html = document.createElement("span")
    html.innerHTML = `<span class="exit white">${exit}</span>`
    html.addEventListener("click", sendExit(channel, exit))
    exits.append(html)
  })

  let characters = _.first(Sizzle(".room-info .characters"))
  characters.innerHTML = ""
  _.each(room.npcs, (npc) => {
    let html = document.createElement('span')
    html.innerHTML = `<li class="yellow">${npc.name}</li>`
    characters.append(html)
  })
  _.each(room.players, (player) => {
    let html = document.createElement('span')
    html.innerHTML = `<li class="blue">${player.name}</li>`
    characters.append(html)
  })
}

/**
 * Room.Info module
 */
let roomInfo = (channel, data) => {
  room = data
  renderRoom(channel, room)
}

/**
 * Room.Character.Enter module
 */
let roomCharacterEnter = (channel, data) => {
  console.log(data)
  console.log(room.players)
  switch (data.type) {
    case "player":
      room.players.push(data)
      renderRoom(channel, room)
      break;
    case "npc":
      room.npcs.push(data)
      renderRoom(channel, room)
      break;
  }
}

/**
 * Room.Character.Leave module
 */
let roomCharacterLeave = (channel, data) => {
  console.log(data)
  switch (data.type) {
    case "player":
      room.players = _.reject(room.players, (player) => player.id == data.id)
      renderRoom(room)
      break;
    case "npc":
      room.npcs = _.reject(room.npcs, (npc) => npc.id == data.id)
      renderRoom(room)
      break;
  }
}

let gmcp = {
  "Character": character,
  "Character.Vitals": characterVitals,
  "Room.Info": roomInfo,
  "Room.Character.Enter": roomCharacterEnter,
  "Room.Character.Leave": roomCharacterLeave,
}

export function gmcpMessage(channel) {
  return (payload) => {
    let data = JSON.parse(payload.data)

    if (gmcp[payload.module] != undefined) {
      gmcp[payload.module](channel, data);
    } else {
      console.log(`Module \"${payload.module}\" not found`)
    }
  }
}
