# NPCs

![NPCs Index](/images/admin-npc-index.png)

The index lists out all of the NPCs in the game. You can also filter the list by zone and tag.

## Create a new NPC

From the index page, click `New NPC` in the top right of the listing.

![NPC New](/images/admin-npc-new.png)

Fill out the information for the item, name, description, etc. The stats field will be prefilled with a basic character's stats. Tags will be displayed in the index page (separate by commas.) Notes is available only in the admin panel and not to players.

![NPC Events](/images/admin-npc-events.png)

The events field has buttons to help fill out events. Get more information [about events here][events]. The `script` field should be empty or filled in with script JSON. See [Scripts][scripts] for more information.

## Control an NPC

You can control an instance of an NPC from their details page.

![NPC Details](/images/admin-npc-show-spawners.png)

Click `Control` to start controlling an NPC.

![NPC Control](/images/admin-npc-control.png)

You will be able to make the NPC say and emote things from this panel. The chat box will contain characters entering and leaving, and anything the NPC can hear, such as what a player says.

[events]: /admin/events/
[scripts]: /admin/scripts/
