# NPC Events

## room/entered

```
{
  "type": "room/entered",
  "arguments": "Welcome!",
  "action": "say"
}
```

When a character enters a room, this event will be triggered. At the moment the only action is `say`. The argument is a string that the NPC will say to the room.

## room/heard

```
{
  "type": "room/heard",
  "condition": "hello",
  "arguments": "Welcome!",
  "action": "say"
}
```

When a character hears something in the room, this event will be triggered. The condition is a string that is converted to a regex (case insensitive), that if matches the NPC will run the action. The action at the moment is only `say`.
