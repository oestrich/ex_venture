# Classes

![Classes Index](/images/admin-classes-index.png)

Classes in ExVenture give a stat boost each level and determine which skills are available to the player based on level.

## Create a new Class

From the index page, click `New Class` in the top right of the listing.

![Classes New](/images/admin-classes-new.png)

Fill in the following information:

Name | Description
---- | -----------
Name | Name of the class
Description | A description of the class. This will be viewable on the home page.
Points Name | Name of the skill points used for the class, e.g. "mana points" for a mage.
Points Abbreviation | Abbreviation of the points used for the class, e.g. "MP" for a mage.
Each Level Stats | The stat boost that each level will give the player.
Regen Health | Number of health each regen tick will give.
Regen Skill Points | Number of skill points each regen tick will give.

After saving you will have a new class.

## View a Class and Edit

After creating a class or from the index page (clicking view), you will see a details page for the class.

![Classes Show](/images/admin-classes-show.png)

You can edit the class by clicking `Edit` in the attribute table. The new stats boosts will take effect for players after disconnecting and reconnecting. It will also not change previously added levels.

## Skills

At the bottom of the class details page you can view skills for the class. The table is sorted by level, ascending. Clicking `View` will display the details page for a class. You can add a new skill by clicking `Add Skill` at the top of the skills table.

### New Skill

Creating a new skill is easy, simply fill out the form and they will be live for players who sign in after the change. The skill will not be pushed to already connected players.

![Skills New](/images/admin-skills-new.png)

Most of the attributes have help text or are obvious. Effects are slightly more complicated.

![Skills New](/images/admin-skills-new-effects.png)

Effects are saved as an array of JSON objects. Each object is validated on it's type. You can ensure you enter in valid JSON by using the `Add Effect` buttons below the field. These fill in properly formatted effects, simply change the values inside and they should be valid. You will not be able to save the form without all of them being valid. See [effects][effects] for expanded information on kinds of effects.

### SKills Detail

![Skills Show](/images/admin-skills-show.png)

This page shows the stats of a skill, most notably the effects. You can edit the skill by clicking the `Edit` button at the top right. The changes will only take affect for new sign ins.

[effects]: /admin/effects/
