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
