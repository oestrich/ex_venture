# GMCP Modules

## Channels

### Channels.Broadcast

A channel you are in had a message broadcast to it.

```
Channels.Broadcast {
  "channel": "global",
  "from": {"id": 1, "name": "Player"},
  "message": "Hi"
}
```

### Channels.Tell

A new tell message was sent to your character.

```
Channel.Tell {"from": {"id": 1, "name": "Player"}, "message": "Hi"}
```

## Character

### Character.Info

On sign in the general character information will be sent.

```
Character.Info {
  "name": "Player",
  "level": 5,
  "class": {
    "name": "Cleric"
  }
}
```

### Character.Skill

Fired when a skill's active state changes.

```
Character.Skill {
  "id": 10,
  "name": "Magic Missile",
  "command": "magic missile",
  "active": true
}
```

### Character.Skills

Sent on login and can be requested from the player.

```
Character.Skills {
  "skills": [
    {"id": 10, "name": "Magic Missile", "command": "magic missile", "points": 2, "cooldown": 3000},
    {"id": 11, "name": "Frosy Ray", "command": "frost ray", "points": 3, "cooldown": 5000}
  ]
}
```

### Character.Skills.Get

*Client Message*

You may request the full list of skills known at any point.

```
Character.Skills.Get {}
```

### Character.Vitals

Any time a player's vitals change (stats) this will be broadcast. Every tick will also push this out.

```
Character.Vitals {
  "strength": 15,
  "skill_points": 20,
  "endurance_points": 10,
  "max_skill_points": 20,
  "max_endurance_points": 10,
  "max_health_points": 30,
  "intelligence": 15,
  "health_points": 30,
  "agility": 15
}
```

## Config

### Config.Actions

This will contain the full set of actions the player has configured for their action bar

```
Config.Actions {
  "actions": [
    {"type": "skill", "id": 1},
    {"type": "skill", "id": 2}
  ]
}
```

### Config.Update

This will contain the full config that the player has, anytime it is updated.

```
Config.Update {
  "color_npc": "blue"
}
```

## External.Discord

This follows the Mudlet External.Discord package spec.

### External.Discord.Get

*Client Message*

Sent from the client when they wish to receive current discord status.

```
External.Discord.Get {}
```

### External.Discord.Hello

*Client Message*

Sent as a welcome from the client to see if Discord integration is available.

Mudlet may send extra information that is ignored for now.

```
External.Discord.Hello {}
```

### External.Discord.Info

A response to `External.Discord.Hello`. Will contain the discord server invite url if present.

```
External.Discord.Info {
  inviteurl: "discord.gg"
}
```

### External.Discord.Status

Current in game status. Can be prompted by `External.Discord.Get`.

```
External.Discord.Status {
  game: "ExVenture MUD",
  starttime: 1529031599
}
```

## Mail

### Mail.New

You have received a new piece of mail.

```
Mail.New {
  "id": 1,
  "from": {"id": 1, "name": "Player"},
  "title": "Hi"
}
```

## Room

### Room.Info

When a player uses `look` or moves this will be sent to show the current room's information.

```
Room.Info {
  "id": 5,
  "zone": {"id": 1, "name": "Zone"},
  "y": 3,
  "x": 2,
  "map_layer": 4,
  "shops": [{"name": "Shoppe", "id": 1},
  "players": [{"name": "player", "id": 1}],
  "npcs": [{"name": "Bandit", "id": 2}],
  "name": "Great Room",
  "items": [{"name": "Leather Armor", "id": 2}],
  "ecology": "default",
  "exits": [{"room_id": 10, "direction": "east"}],
  "description": "The great room of the bandit hideout."
}
```

### Room.Heard

Sent whenever someone `say`s to the room the player is in.

```
Room.Heard {
  "from": {"type": "player", "name": "Player", "id": 3},
  "message": "hi"
}
```

### Room.Whisper

Sent when the player is whispered to.

```
Room.Whisper {
  "from": {"type": "player", "name": "Player", "id": 3},
  "message": "hi"
}
```

## Room.Characters

### Room.Characters.Enter

Sent when a character enters the player's room.

```
Room.Characters.Enter {"type": "player", "name": "Player", "id": 3}
```

### Room.Characters.Leave

Sent when a character leaves the player's room.

```
Room.Characters.Leave {"type": "player", "name": "Player", "id": 3}
```

## Target

### Target.Character

```
Target.Character {"type": "player", "name": "Player", "id": 3}
```

### Target.Clear

*Can be a Client Message*

This is notifying that your target is emtpy, or if sent will clear your target.

```
Target.Clear {}
```

### Target.Set

*Client Message*

Set your current target

```
Target.Set {"name": "Player"}
```

### Target.You

Another Charcater (PC or NPC) has targeted your character.

```
Target.You {"type": "player", "name": "Player", "id": 3}
```

## Zone

### Zone.Map

```
Zone.Map {"map": "..."}
```
