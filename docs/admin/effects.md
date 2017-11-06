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

## healing

```
{
  'kind': 'healing',
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
