# Zones

![Zones Index](/images/admin-zones-index.png)

Zones in ExVenture are ways of breaking the world up into manageable chunks. Each zone can have as many rooms as required, along with multiple map layers.

## Create a New Zone

From the index page, click `New Zone` in the top right of the listing.

![Zones New](/images/admin-zones-new.png)

Fill in the required information and you will see an empty zone detail page.

![Zones New](/images/admin-zones-details-empty.png)

Click `Add Room` to start filling in the zone.

![New Room](/images/admin-zones-room-new.png)

Fill in the required information. Most fields will default to good values for a first room. Pay attention to the `x`, `y`, and `map_layer` fields. These can be any number but must be relative to other future rooms. Starting with `{0, 0, 1}` (x, y, map_layer) is a good start. The zone exit field is important as checking that will allow you to create an exit to it from other zones.

### Creating a new room after rooms exist

Once rooms exist, `New Room` buttons will show up on the map. Clicking one of these will prefill the `{x, y, map_layer}` fields in the form for quick creation.

![Zone with rooms](/images/admin-zones-with-rooms.png)

## Creating Exits

Once you have created a few rooms, you will need to connect them.

![Room new exit](/images/admin-zones-room-new-exit.png)

From the details page, click an exit direction you wish to connect. In this case we will be creating a new "East" direction.

![Room select exit](/images/admin-zones-room-new-exit-select-room.png)

You can select the room from the select box or click the room on the map that you wish to connect. Click `Create` to create the exit. You can also add a door by checking the box.

![Room with exit](/images/admin-zones-room-with-exit.png)

## Room Items

You can add items from the room show page. Click `Add Item`, select the item from the list and it will be placed in the room for pickup. Also available is an item spawner. This will place the item back in the room after the spawner detects it missing.

## Shops

Shops can be created in a room. Each room can have multiple shops. They will be referred to by their name if multiple are in the same room. After creating a shop you can add items to the shop.

![New Shop Item](/images/admin-zones-shop-new-item.png)

Select an item, which has the sell price listed in parens, and give it a price and quantity. -1 quantity will have an unlimited quantity. You can delete items from the shop later.
