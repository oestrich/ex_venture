import Sizzle from "sizzle"
import _ from "underscore"

/**
 * Character module
 */
let character = (data) => {
  console.log(`Signed in as ${data.name}`)
  let stats = _.first(Sizzle(".stats"));
  stats.style.display = "inherit";
  let roomInfo = _.first(Sizzle(".room-info"));
  roomInfo.style.display = "inherit";
}

/**
 * Character.Vitals module
 */
let characterVitals = (data) => {
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
}

/**
 * Room.Info module
 */
let roomInfo = (data) => {
  let roomName = _.first(Sizzle(".room-info .room-name"))
  roomName.innerHTML = data.name

  let characters = _.first(Sizzle(".room-info .characters"))
  characters.innerHTML = ""
  _.each(data.npcs, (npc) => {
    let html = document.createElement('span')
    html.innerHTML = `<li class="yellow">${npc.name}</li>`
    characters.append(html)
  })
  _.each(data.players, (player) => {
    let html = document.createElement('span')
    html.innerHTML = `<li class="blue">${player.name}</li>`
    characters.append(html)
  })
}

let gmcp = {
  "Character": character,
  "Character.Vitals": characterVitals,
  "Room.Info": roomInfo,
}

export function gmcpMessage(payload) {
  let data = JSON.parse(payload.data)

  if (gmcp[payload.module] != undefined) {
    gmcp[payload.module](data);
  } else {
    console.log("Module not found")
  }
}
