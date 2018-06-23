import Sizzle from "sizzle"
import _ from "underscore"

import {format, defaultColorCSS} from "./color"
import Logger from "./logger"
import Notifacations from "./notifications"

let notifications = new Notifacations();

/**
 * Channel.Broadcast module
 */
let channelBroadcast = (channel, data) => {
  notifications.display(`[${data.channel}] ${data.from.name}`, data.message);
}

/**
 * Character module
 */
let characterInfo = (channel, data) => {
  console.log(`Signed in as ${data.name}`)

  renderCharacter(data);

  let stats = _.first(Sizzle(".stats"));
  stats.style.display = "flex";

  let characterInfo = _.first(Sizzle(".character-info"));
  characterInfo.style.display = "inherit";

  let roomInfo = _.first(Sizzle(".room-info"));
  roomInfo.style.display = "inherit";
}

/**
 * Character.Skill module
 */
let characterSkill = (channel, data) => {
  Logger.log("Skill", data);
}

/**
 * Character.Vitals module
 */
let characterVitals = (channel, data) => {
  renderStats(data);

  let healthWidth = data.health_points / data.max_health_points;
  let skillWidth = data.skill_points / data.max_skill_points;
  let enduranceWidth = data.endurance_points / data.max_endurance_points;

  let health = _.first(Sizzle("#health .percentage"));
  health.style.width = `${healthWidth * 100}%`;
  let healthStat = _.first(Sizzle("#health .stat"));
  healthStat.innerHTML = `${data.health_points}/${data.max_health_points} hp`;

  let skill = _.first(Sizzle("#skills .percentage"));
  skill.style.width = `${skillWidth * 100}%`;
  let skillStat = _.first(Sizzle("#skills .stat"));
  skillStat.innerHTML = `${data.skill_points}/${data.max_skill_points} sp`;

  let endurance = _.first(Sizzle("#endurance .percentage"));
  endurance.style.width = `${enduranceWidth * 100}%`;
  let enduranceStat = _.first(Sizzle("#endurance .stat"));
  enduranceStat.innerHTML = `${data.endurance_points}/${data.max_endurance_points} ep`;
}

/**
 * Config.Update module
 */
let configUpdate = (channel, data) => {
  window.gameConfig = data;
}

/**
 * Core.Heartbeat module
 */
let coreHeartbeat = (channel, data) => {
  Logger.log("Heartbeat");
}

/**
 * Mail.New module
 */
let mailNew = (channel, data) => {
  notifications.display(`New Mail from ${data.from.name}`, data.title);
}

/**
 * Channels.Tell module
 */
let tell = (channel, data) => {
  notifications.display(`New tell from ${data.from.name}`, data.message);
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
 * Render the character info in the side panel
 */

let renderCharacter = (character) => {
  let characterName = _.first(Sizzle(".character-info .character-name"));
  characterName.innerHTML = character.name;

  let className = _.first(Sizzle(".character-info .class-name"));
  className.innerHTML = character.class.name;

  let level = _.first(Sizzle(".character-info .level"));
  level.innerHTML = character.level;
}

let renderStats = (stats) => {
  let strength = _.first(Sizzle(".character-info .strength"));
  strength.innerHTML = stats.strength;

  let agility = _.first(Sizzle(".character-info .agility"));
  agility.innerHTML = stats.agility;

  let intelligence = _.first(Sizzle(".character-info .intelligence"));
  intelligence.innerHTML = stats.intelligence;

  let awareness = _.first(Sizzle(".character-info .awareness"));
  awareness.innerHTML = stats.awareness;

  let vitality = _.first(Sizzle(".character-info .vitality"));
  vitality.innerHTML = stats.vitality;

  let willpower = _.first(Sizzle(".character-info .willpower"));
  willpower.innerHTML = stats.willpower;
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
    html.innerHTML = `<span class="exit white">${exit.direction}</span>`
    html.addEventListener("click", sendExit(channel, exit.direction))
    exits.append(html)
  })

  let npcColor = defaultColorCSS("npc", "yellow");
  let playerColor = defaultColorCSS("player", "blue");

  let characters = _.first(Sizzle(".room-info .characters"))
  characters.innerHTML = ""
  _.each(room.npcs, (npc) => {
    let html = document.createElement('div')
    html.innerHTML = `<li class="${npcColor}">${npc.name}</li>`
    _.each(html.children, (li) => { characters.append(li) })
  })
  _.each(room.players, (player) => {
    let html = document.createElement('div')
    html.innerHTML = `<li class="${playerColor}">${player.name}</li>`
    _.each(html.children, (li) => { characters.append(li) })
  })
}

/**
 * Room.Heard module
 */
let roomHeard = (channel, data) => {
  notifications.display(`${data.from.name}`, data.message);
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
  switch (data.type) {
    case "player":
      room.players = _.reject(room.players, (player) => player.id == data.id)
      renderRoom(channel, room)
      break;
    case "npc":
      room.npcs = _.reject(room.npcs, (npc) => npc.id == data.id)
      renderRoom(channel, room)
      break;
  }
}

let targetYou = (channel, data) => {
  notifications.display(`${data.name} is targetting you`, "");
}

let zoneMap = (channel, data) => {
  let map = _.first(Sizzle(".room-info .map"))

  let html = document.createElement('pre')
  let mapString = format({message: data.map})
  html.innerHTML = `<code>${mapString}</lcodei>`

  map.innerHTML = ""
  map.append(html)
}

let gmcp = {
  "Channels.Broadcast": channelBroadcast,
  "Channels.Tell": tell,
  "Character.Info": characterInfo,
  "Character.Skill": characterSkill,
  "Character.Vitals": characterVitals,
  "Config.Update": configUpdate,
  "Core.Heartbeat": coreHeartbeat,
  "Mail.New": mailNew,
  "Room.Heard": roomHeard,
  "Room.Info": roomInfo,
  "Room.Character.Enter": roomCharacterEnter,
  "Room.Character.Leave": roomCharacterLeave,
  "Target.You": targetYou,
  "Zone.Map": zoneMap,
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
