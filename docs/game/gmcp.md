# GMCP Events

## Channel.Broadcast

A channel you are in had a message broadcast to it.

```
Channel.Broadcast {
  "channel": "global",
  "from": {"id": 1, "name": "Player"},
  "message": "Hi"
}
```

## Channel.Tell

A new tell message was sent to your character.

```
Channel.Tell {"from": {"id": 1, "name": "Player"}, "message": "Hi"}
```

## Character

On sign in the general character information will be sent.

```
Character {"name": "Player"}
```

## Character.Vitals

Any time a player's vitals change (stats) this will be broadcast. Every tick will also push this out.

```
Character.Vitals {
  "strength": 15,
  "skill_points": 20,
  "move_points": 10,
  "max_skill_points": 20,
  "max_move_points": 10,
  "max_health_points": 30,
  "intelligence": 15,
  "health_points": 30,
  "dexterity": 15
}
```

## Mail.New

You have received a new peice of mail.

```
Mail.New {
  "id": 1,
  "from": {"id": 1, "name": "Player"},
  "title": "Hi"
}
```

## Room.Info

When a player uses `look` or moves this will be sent to show the current room's information.

```
Room.Info {
  "zone_id": 1,
  "y": 3,
  "x": 2,
  "shops": [{"name": "Shoppe", "id": 1},
  "players": [{"name": "player", "id": 1}],
  "npcs": [{"name": "Bandit", "id": 2}],
  "name": "Great Room",
  "items": [{"name": "Leather Armor", "id": 2}],
  "ecology": "default",
  "description": "The great room of the bandit hideout."
}
```

## Room.Characters.Enter

```
Room.Characters.Enter {"type": "player", "name": "Player", "id": 3}
```

## Room.Characters.Leave

```
Room.Characters.Leave {"type": "player", "name": "Player", "id": 3}
```

## Target.Character

```
Target.Character {"type": "player", "name": "Player", "id": 3}
```

## Target.Clear

```
Target.Clear {}
```

## Target.You

Another Charcater (PC or NPC) has targeted your character.

```
Target.You {"type": "player", "name": "Player", "id": 3}
```

## Zone.Map

```
Zone.Map {"map": "..."}
```
