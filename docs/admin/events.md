## Events

### character/targeted

Fired when the character is targetted by another character.

Allowed actions:

- `commands/target`

Example:

```json
{
  "type": "character/targeted",
  "actions": [
    {
      "type": "commands/target",
      "delay": 0,
      "options": {}
    }
  ]
}
```

### combat/ticked

Fired when the character is in combat and the previous `combat/ticked` completed and the delay is over.

Options:

- `weight`: When a character has multiple `combat/ticked` events, the weight will be used when randomizing which event triggers

Allowed actions:

- `commands/skills`

Example:

```json
{
  "type": "combat/ticked",
  "options": {
    "weight": 10,
  },
  "actions": [
    {
      "type": "commands/skills",
      "delay": 0,
      "options": {
        "skill": "bash"
      }
    }
  ]
}
```

### room/entered

Fired when a character enters the room the NPC is in.

Allowed actions:

- `commands/emote`
- `commands/say`

Example:

```json
{
  "type": "room/entered",
  "actions": [
    {
      "type": "commands/say",
      "delay": 0,
      "options": {
        "message": "Hello!"
      }
    }
  ]
}
```

### room/heard

Fired whenever a character hears local room chat.

Options:

- `regex`: if provided the regex must match to fire the actions

Allowed actions:

- `commands/emote`
- `commands/say`

Example:

```json
{
  "type": "room/heard",
  "options": {
    "regex": "hello"
  },
  "actions": [
    {
      "type": "commands/say",
      "delay": 0,
      "options": {
        "message": "How are you?"
      }
    }
  ]
}
```

### state/ticked

Fired on start of the NPC process and will continue to run until the game is shut down. Each event is delayed a provided amount of time between triggers.

Options:

- `minimum_delay`: The minimum amount of time to wait before triggering this event again, default of `30` if none is provided
- `random_delay`: A random extra delay to add to the minimum wait, from 0 to the delay provided extra
- `room_id`: Optional, the character must be in this room to trigger the speech

Allowed actions:

- `commands/emote`
- `commands/move`
- `commands/say`

Example:

```json
{
  "type": "state/ticked",
  "options": {
    "minimum_delay": 30,
    "random_delay": 10
  },
  "actions": [
    {
      "type": "commands/say",
      "delay": 0,
      "options": {
        "message": "Hello!"
      }
    }
  ]
}
```

## Actions

### commands/emote

Sends an emote to the room the character is in. Can also change the internal status of the character.

Options:

- `message`: The emote to send, template param of `[name]` is available
- `status_reset`: If provided, it resets the internal status of the NPC back to the default, boolean
- `status_key`: If provided, changes the status key
- `status_line`: If provided, changes the status line for the character, template param of `[name]` is available
- `status_listen`: If provided, changes the status listen text for the character, template param of `[name]` is available

All status options must be provided if any of them are provided.

```json
{
  "type": "commands/emote",
  "delay": 0,
  "options": {
    "message": "[name] claps his hands",
    "status_key": "claps",
    "status_line": "[name] is clapping",
    "status_listen": "[name] is clapping"
  }
}
```

### commands/move

Moves the character a random direction from the room the character is currently in.

Options:

- `max_distance`: The max distance the character will move away from the spawn point

```json
{
  "type": "commands/move",
  "delay": 0,
  "options": {
    "max_distance": 2
  }
}
```

### commands/say

Sends local chat to the room the character is in. Either `message` or `messages` is required, but not both.

Options:

- `message`: The message being sent, takes precedence over `messages` if both are present
- `messages`: A list of messages that will be randomly selected from before sending

```json
{
  "type": "commands/say",
  "delay": 0,
  "options": {
    "message": "Hello everyone!"
  }
}
```

```json
{
  "type": "commands/say",
  "delay": 0,
  "options": {
    "messages": ["Hello everyone!"]
  }
}
```

### commands/skill

Selects a skill to use for combat.

Options:

- `skill`: Which skill the character will use on their target, the next `combat/ticked` will trigger after the skill's cooldown time

```json
{
  "type": "commands/skills",
  "delay": 0,
  "options": {
    "skill": "bash"
  }
}
```

### commands/target

Sets the characters target to the character that sent the event.

Options:

- `player`: Optional, boolean, default `false`. If true, the command will be allowed to target players
- `npc`: Optional, boolean, default `false`. If true, the command will be allowed to target npcs

```json
{
  "type": "commands/target",
  "delay": 0,
  "options": {
    "player": true
  }
}
```
