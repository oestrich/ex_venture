# NPC Events

## room/entered

When a character enters a room, this event will be triggered.

### action: say

```
{
  "type": "room/entered",
  "action": {
    "type": "say",
    "message": "Welcome!",
  }
}
```

The message is a string that the NPC will say to the room.

### action: target

```
{
  "type": "room/entered",
  "action": {
    "type": "target",
  }
}
```

When a player enters the room they will be targeted by the NPC.

## room/heard

```
{
  "type": "room/heard",
  "condition": {
    "regex": "hello",
  },
  "action": {
    "type": "say",
    "message": "Welcome!",
  }
}
```

When a character hears something in the room, this event will be triggered. The condition is a string that is converted to a regex (case insensitive), that if matches the NPC will run the action. The action at the moment is only `say`.

## combat/tick

```
{
  "type": "combat/tick",
  "action": {
    "type": "target/effects",
    "text": "{user} slashes at you.",
    "weight": 10,
    "effects": [
      {
        "kind": "damage",
        "type": "slashing",
        "amount": 10
      }
    ],
    "delay": 0.5
  }
}
```

When a combat tick occurs, this event will be triggered. Combat ticks will start after the NPC targets something. They will continue until they lose their target. The `combat/tick` event needs to have a delay for how long before it's next combat tick will trigger. If there are more than one, a random weighted action will be chosen.

### target/effects

This action will apply the effects to the target.

## tick

When a game tick occurs, this event will be triggered.

### move

```
{
  "type": "tick",
  "action": {
    "type": "move",
    "max_distance": 3,
    "chance": 50
  }
}
```

The move action takes a `max_distance` that the NPC will stray from their original spawn point. `chance` is the percent chance that the NPC will move to a random exit.

### emote

```
{
  "type": "tick",
  "action": {
    "type": "emote",
    "message": "moves about the store",
    "chance": 50,
    "wait": 15
  }
}
```

The emote action takes a `message` that the NPC will emote into the room. `chance` is the percent chance that the NPC will do this action on each tick. `wait` is optional and will enforce a delay of `wait` seconds since the last emote. Multiple emote ticks update the same timestamp of when an emote occured.

### say

```
{
  "type": "tick",
  "action": {
    "type": "say",
    "message": "Can I help you?",
    "chance": 50,
    "wait": 10,
  }
}
```

The say action takes a `message` that the NPC will say into the room. `chance` is the percent chance that the NPC will do this action on each tick. `wait` is optional and will enforce a delay of `wait` seconds since the last say. Multiple say ticks update the same timestamp of when a say tick occured.

## character/targeted

```
{
  "type": "character/targeted",
  "action": {
    "type": "target"
  }
}
```

This event triggers whenever it is targeted, this allows the NPC to target whoever targeted them.
