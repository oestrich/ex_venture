# Quests

![Quests Index](/images/admin-quests-index.png)

Quests help give players direction in the game. They reward gold and experience.

## Create a new Quest

From the index page, click `New Quest` in the top right of the listing.

![Quests new](/images/admin-quests-new.png)

Fill in the required information and a new quest will be created. You can then add steps and a parent or child afterwards.

## View a Quest and Edit

After creating a quest or from the index page, you will see details for the quest.

![Quests show](/images/admin-quests-show.png)

You can edit the quest by clicking `Edit` in the attribute table. Quests can have parents and children to create quest chains. Quests further down the line must be completed before being offered.

![Quests show steps](/images/admin-quests-show-steps.png)

The steps of a quest are the requirements that must be completed in order for the quest to be turned in. NPC kills are tracked as the player goes, while item collection requires they have `count` of the item in their inventory when turning in. Items will be removed from the player's inventory when turning in quests with `item/collect` steps.
