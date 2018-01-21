# Scripts

Scripts are attached to NPCs and Quests. They dictate what an NPC will do during a conversation. Conversations are started with NPCs by `greet`ing them.

## Example

This is an example of a quest script.

```json
[
  {
    "unknown": "I don't know about that, but I can help you with bandits",
    "trigger": null,
    "message": "Hello, are you here to find out about our bandit problem?",
    "listeners": [
      {
        "phrase": "yes|bandits",
        "key": "bandits"
      }
    ],
    "key": "start"
  },
  {
    "unknown": null,
    "trigger": "quest",
    "message": "I heard they are hiding {white}down{/white} in a cave.",
    "listeners": [],
    "key": "bandits"
  }
]
```

## How they work

A conversation will start using the `start` key line. Each conversation _must_ have this. Quests must also have a `trigger: quest` in them. The NPC will send the player the `message` and respond based on the `listeners`.

Each `listener` has a `key` for which line to use next, these are validated to all exist before saving the script. The user's reply is matched against the `phrase` in each listener (as a regex), the first matching listener will trigger the transition to its key. If no listeners match, the `unknown` message is sent in response and the conversation does not move forward.

After 5 minutes, the NPCs state of conversations is cleared of stuck conversations. If a player reachs the end of a conversation (`listeners` is empty), then it also clears out their state.

## Example Interaction

Given the script above, this is a flow you should expect:

```
Guard replies, "Hello, are you here to find out about our bandit problem?"
You tell Guard, "huh?"
Guard replies, "I don't know about that, but I can help you with bandits",
You tell Guard, "yes"
Guard replies, "I heard they are hiding {white}down{/white} in a cave."
You have a new quest.
```
