# mod-starter-wands

*This module ([repo](https://github.com/Protonull/mod-starter-wands)) was created for [OrinWoW](https://github.com/Protonull/OrinWoW), but can be used on any [azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk) server.*

This module gives all newly-created players with the ability to use wands a modified [Alchemist's Wand](https://www.wowhead.com/wotlk/item=5235/alchemists-wand). As such, players may need to delete their item cache for the wand to work as intended.

![Starter wand tooltip](assets/wand_tooltip.png)

## Advisory

The wand-skill check happens within `OnPlayerFirstLogin` on a `PlayerScript`. It doesn't seem like AzerothCore offers any load-before, depends-on, or other means to specify an order of operations. If you likewise grant the wand skill within the same function on your own script, you may need to test whether it works. It seems like AzerothCore loads modules in alphabetical order, so rename this module to `mod_ztarter_wands` or something (remember to update the function name in `mod_loader.cpp` too!).

## Licence

Given the terms of AzerothCore's APGL licence, this module is unfortunately obligated to adopt the same. As such, this project is likewise licensed under APGL.

## Backstory

I had the idea that spellcasters should start off with a wand, similar to how hunters start off with a gun, bow, or crossbow. Getting this implemented though has been a *'fun'* journey.

Starter outfits are defined by the `charstartoutfit_dbc` table within the `acore_world` database, except that it's empty? This meant having to populate the table first before being able to make adjustments.

AzerothCore [recommends](https://www.azerothcore.org/wiki/how-to-import-dbc-data-in-db) using [node-dbc-reader](https://github.com/wowgaming/node-dbc-reader) to extract the data into SQL queries (if you don't already have the dbc files, you can download them [here](https://github.com/wowgaming/client-data/releases/)). The problem is that it doesn't tell you where to clone it, so I immediately ran into issues where node-dbc-reader could not find the dbc files, which meant having to edit file paths within its source code.

It worked at first, allowing me to modify Paladin blessings to last 30 minutes, but I ran into an [out-of-bounds error](https://discord.com/channels/217589275766685707/1255602330431127753/1404928354964078642) for `CharStartOutfit`, *sigh*.

It turns out that the dbc file's [schema](https://wowdev.wiki/DB/CharStartOutfit#3.0.8.8905-3.3.5.12340) defines the race, class, gender, and outfit-id values as bytes (u8), whereas node-dbc-reader [defines](https://github.com/wowgaming/node-dbc-reader/blob/f164222a278e8c110c30b1a5e68b682f56f4b20c/src/schemas/azerothcore/charstartoutfit.json#L6-L21) these as ints (u32). No wonder it was overflowing! A little more editing to the source code fixed this, producing a working SQL query. The `charstartoutfit_dbc` is now populated!

So I look at the `charstartoutfit_dbc` table, thinking I can find the "ranged weapon" slot by seeing what column hunters use for their ranged weapons. I assumed that it'd match the `SLOT_RANGED` enum (17), so the weapon would be in `ItemID_18` (since the database columns are 1-based indexed). *NOPE*. I Ctrl-F'd for `2508` (Old Blunderbuss) and found it in *multiple* different columns, none of which were `ItemID_18`.

As it turns out, each row in `charstartoutfit_dbc` is essentially a list of items, not a slot-to-item map. Putting an item into a particular column means nothing. In fact, putting anything in any of the `DisplayItemID_*` or `InventoryType_*` columns means nothing (since they are not used by the server). This makes editing starter outfits *extremely* obnoxious.

If `charstartoutfit_dbc` worked as I had expected, where each column corresponds to the `CharacterSlot` enum, then you could trivially update starter outfits, eg:

```sql
--                                                                  3 = Hunter
UPDATE charstartoutfit_dbc SET `ItemID_18` = 2508 WHERE `ClassID` = 3;
```

This would then set ALL hunter starter-outfits to have an Old Blunderbuss as the ranged weapon.

Instead, you are required to know where each ranged-weapon lies for each race-class-gender combo. Usually the gender doesn't matter but the possibility is there. Here is the equivalent SQL:

```sql
-- Orcs, Dwarves, Blood Elves, and Draenei
UPDATE charstartoutfit_dbc SET `ItemID_8` = 2508 WHERE `ClassID` = 3 AND `RaceID` IN (2, 3, 10, 11);
-- Night Elves and Tauren
UPDATE charstartoutfit_dbc SET `ItemID_6` = 2508 WHERE `ClassID` = 3 AND `RaceID` IN (4, 6);
-- Trolls
UPDATE charstartoutfit_dbc SET `ItemID_5` = 2508 WHERE `ClassID` = 3 AND `RaceID` = 8;
```

This is absurd and extremely bug-prone. And since this module is about giving ranged weapons to classes whose starter outfits don't already have them, the question then becomes what column do you modify? And how do you do so without potentially overwriting prior additions to starter outfits? Presumably you'd want some way to set it to the first-empty column, but how would you do that? Database tables aren't supposed to be used like this.

At this point, I abandoned the idea of using the database to modify starter outfits. It's mod time! The most obvious solution was to create a `PlayerScript`, override `OnPlayerCreate`, and then assign the item there, right? Haha, *right?* NOPE! Turns out that despite the method giving you a `Player` instance, you're not *really* supposed to do anything with it. Is this documented anywhere? Haha, no.

Luckily there's `OnPlayerFirstLogin`, which *does* work, thank goodness: I was 🤏 close to committing seppuku. Giving players the starter wand in-script also means not limiting the starter wand to *just* priests, mages, and warlocks, but to anyone who has the wand skill at time of character creation. Feel free to give druids the wand-skill :)
