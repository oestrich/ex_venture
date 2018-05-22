# Effects

## damage

```
{
  'kind': 'damage',
  'type': 'slashing',
  'amount': 10
}
```

This subtracts from the health field of the target. `type` must be one of those defined in `Data.Stats.Damage.fields/0`. This will be boosted by strength for physical damage types and intelligence for magical damage types.

## damage/type

```
{
  'kind': 'damage/type',
  'types': ['slashing'],
}
```

This helps limit which damage types are used in the application of a skill. If a damage effect's type is not in the list of it's `type` then the damage is halved. For example, if a `slashing` damage effect was matched with a `bludgeoning` `damage/type` effect, then the slashing damage is halved.

This might happen when all of a player's armor and weapon effects are combined with the skill they are using. A piece of armor might be described as "magic users only", and have a `damage/type` of `["arcane", "ice", "fire"]` to restrict what skills a player might use while wearing them. If they try using a dagger with `slashing` damage, then their `slashing` damage is halved.

## damage/over-time

```
{
  'kind': 'damage/over-time',
  'type': 'slashing',
  'amount': 10,
  'every': 1000,
  'count': 4
}
```

This deals damage over time. It will damage every `every` milliseconds. Every time it ticks the `count` will decrement until it hits 0 ending the effect. The effect is also "instantiated" by giving it an id to track with. On dying or `count` reaching 0, the effect will be removed from tracking.

## recover

```
{
  'kind': 'recover',
  'type': 'health',
  'amount': 10,
}
```

The amount of damage a usee will be healed for. This is boosted by wisdom.

## stats

```
{
  'kind': 'stats',
  'field': 'dexterity',
  'amount': 10
}
```

This effect boosts the user's stats before any other effects are calulated.

## stats/boost

```
{
  'kind': 'stats/boost',
  'field': 'dexterity',
  'amount': 10,
  'duration': 1500
}
```

This effect boosts the target's stats for the `duration` amount in milliseconds.
