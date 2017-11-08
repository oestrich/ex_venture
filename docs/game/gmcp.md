# GMCP Events

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
  "max_health": 30,
  "intelligence": 15,
  "health": 30,
  "dexterity": 15
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

## Zone.Map

```
Zone.Map {"map": "..."}
```
