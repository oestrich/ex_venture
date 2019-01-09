Venture Markup Language (VML) is the internal formatting language for most text in ExVenture.

VML lets you mark up text for output in the web client as well as telnet connections. Features include: basic colors, custom colors, semantic colors, commands, resource replacement, and basic templating.

## Tags

Tags in VML work similar to HTML tags. They use `{` and `}` instead of `<` and `>` respectively to create tag. Some tags can also include attributes. These look similar to HTML attributes.

Example:

```
{green}Hello{/green}
{command send="greet town crier"}greet the town crier{/command}
```

## Colors

The basic colors are the basic telnet colors, there are a few map specific colors, and any custom colors you add to your instance of ExVenture from the admin panel.

Built in tags:

`black`
`red`
`green`
`yellow`
`blue`
`magenta`
`cyan`
`white`
`blue`
`brown`
`dark-green`
`green`
`grey`
`light-grey`

Example:

```
You {red}shout{/red}
```

## Semantic Colors

The game includes semantic coloring for known entities. Thing such as players, items, rooms, exits, etc all have tags associated to them. Players can configure their own custom colors for these tags but same entities will all be colored the same.

Semantic tags:

`command`
`error`
`hint`
`item`
`npc`
`player`
`quest`
`room`
`say`
`shop`
`skill`
`zone`

Example:

```
{player}Rand{/player} says, {say}"Hello everyone."{/say}
{npc}Guard{/npc} arrives from the {exit}West{/exit}
```

## Resources

You can use a shorthand to template in the names of resources as well. This applies to items, NPCs, rooms, and zones. To insert a resource use `{{` to start the tag and `}}`. There is no closing tag for these. The tag includes the resource type, a colon, and the ID of the resource that will have it's name templated in.

Some examples: `{{item:1}`, `{{npc:2}}`, `{{room:3}}`, `{{zone:4}}`

Example:

```
You see across the street {{npc:2}}.
```

## Templating

Certain fields may have variables that can be templated in before displaying to the user. The admin panel will mention underneath the field if a variable is available for template. Variables use regular brackets as tags, e.g. `[name]`. There is no closing tag for variables.

Example:

```
[name] is running around.
```

## Commands

The `command` tag is special in that clients will let users click on the text inside of the tag and have the client send a command back as if they had typed it out. `exit` works similar but is only for room exits.

Attributes:

- `send`: change the command being sent, to allow for a different display text
- `click`: if set to `false` then the command is not clickable but is otherwise displayed the same as a command

Example:

```
{command}get item{/command}
{command send="get item"}pick up the item{/command}
{command click=false}get item{/command}
```

## Links

The `link` tag will generate a clickable link for clients that will open a new tab in their browser.

Example:

```
{link}https://exventure.org/{/link}
```
