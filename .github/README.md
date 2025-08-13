# mod-starter-wands

*This module ([repo](https://github.com/Protonull/mod-starter-wands)) was created for [OrinWoW](https://github.com/Protonull/OrinWoW),
but can be used on any [azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk) server.*

This module gives all newly-created players with the ability to use wands a custom starter wand.

## Licence

Given the terms of AzerothCore's APGL licence, this module is unfortunately obligated to adopt the same. As such, this
project is likewise licensed under APGL.

## Backstory

I had the idea that spellcasters should start off with a wand, similar to how hunters start off with a gun, bow, or
crossbow. Getting this implemented though has been a *'fun'* journey.

Starter outfits are determined by the `charstartoutfit_dbc` table within `acore_world`, except that it's empty. I'm not
entirely sure why. But modifying the starter outfits means populating this table with the defaults.

AzerothCore [recommends](https://www.azerothcore.org/wiki/how-to-import-dbc-data-in-db) using [node-dbc-reader](https://github.com/wowgaming/node-dbc-reader)
to extract data from the dbc files into SQL queries. If you don't already have the dbc files, you can download them [here](https://github.com/wowgaming/client-data/releases/).
Problem is that nowhere does it tell you where you should clone node-dbc-reader, so I immediately ran into issues where
it could not find the dbc files. That meant editing file paths within the source code.

It worked at first, allowing me to [modify Paladin blessings to last 30 minutes](https://github.com/Protonull/OrinWoW/commit/3d901c332c13713c7199e5e9489aa3a200894776),
but this [didn't work](https://discord.com/channels/217589275766685707/1255602330431127753/1404928354964078642) for
`CharStartOutfit` due to an out-of-bounds error, *sigh*.

As it turns out, the [schema](https://wowdev.wiki/DB/CharStartOutfit#3.0.8.8905-3.3.5.12340) for the dbc file defines
the race, class, gender, and outfit-id values as bytes (u8), whereas node-dbc-reader [defines](https://github.com/wowgaming/node-dbc-reader/blob/f164222a278e8c110c30b1a5e68b682f56f4b20c/src/schemas/azerothcore/charstartoutfit.json#L6-L21)
these as uints (u32), which are 4x the size. No wonder it was overflowing. A little more editing to the source code
fixed this, producing a working SQL query. The `charstartoutfit_dbc` is now populated!

So I look at the `charstartoutfit_dbc` table, thinking I can find the "ranged weapon" slot by seeing what column hunters
use for their ranged weapons. I assumed that it'd match the `SLOT_RANGED` enum (17), so the weapon would be in
`ItemID_18` (since the database columns are 1-based indexed). *NOPE*. I Ctrl-F'd for `2508` (Old Blunderbuss) and not
only do I not find it in `ItemID_18`, but in *multiple* different columns.

As it turns out, each row in `charstartoutfit_dbc` is essentially a struct-of-arrays, not a map. Putting an item into a
particular column means nothing. In fact, putting anything in any of the `DisplayItemID_*` or `InventoryType_*` columns
means nothing (they are not used by the server). This makes editing starter outfits *extremely* obnoxious.

If `charstartoutfit_dbc` worked as expected where each column corresponds to the `CharacterSlot` enum, then you could
trivially update starter outfits, eg:
```sql
--                                                                  3 = Hunter
UPDATE charstartoutfit_dbc SET `ItemID_18` = 2508 WHERE `ClassID` = 3;
```
This would then set ALL hunter starter-outfits to have an Old Blunderbuss, and it'd safely override any previous custom
ranged weapon for hunters.

Instead, you are required to know where each ranged-weapon lies for each race-class-gender combo. Usually the gender
doesn't matter but the possibility is there. Here is the equivalent SQL:
```sql
-- Orcs, Dwarves, Blood Elves, and Draenei
UPDATE charstartoutfit_dbc SET `ItemID_8` = 2508 WHERE `ClassID` = 3 AND `RaceID` IN (2, 3, 10, 11);
-- Night Elves and Tauren
UPDATE charstartoutfit_dbc SET `ItemID_6` = 2508 WHERE `ClassID` = 3 AND `RaceID` IN (4, 6);
-- Trolls
UPDATE charstartoutfit_dbc SET `ItemID_5` = 2508 WHERE `ClassID` = 3 AND `RaceID` = 8;
```
This is absurd and extremely bug-prone.

For example, this module is giving wands to classes that don't start out with them. Presumably, it would be best to put
it wand in the first-empty column, right? Except... ***HOW?!*** I ended up asking ChatGPT this and it generated a
hilariously long query:
```sql
-- Params
SET @itemId = 12345;  -- item_template.entry you want to add

-- Target the specific outfit row (adjust these and the WHERE to your schema)
SET @race   = 1;  -- Human
SET @class  = 3;  -- Hunter
SET @gender = 0;  -- 0=male, 1=female

UPDATE charstartoutfit_dbc
SET
  -- 1
  ItemID_1  = IF(ItemID_1  = -1, @itemId, ItemID_1),

  -- 2
  ItemID_2  = IF(ItemID_1  <> -1 AND ItemID_2  = -1, @itemId, ItemID_2),

  -- 3
  ItemID_3  = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  = -1, @itemId, ItemID_3),

  -- 4
  ItemID_4  = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  = -1, @itemId, ItemID_4),

  -- 5
  ItemID_5  = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  = -1, @itemId, ItemID_5),

  -- 6
  ItemID_6  = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  = -1, @itemId, ItemID_6),

  -- 7
  ItemID_7  = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  = -1, @itemId, ItemID_7),

  -- 8
  ItemID_8  = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  = -1, @itemId, ItemID_8),

  -- 9
  ItemID_9  = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  = -1, @itemId, ItemID_9),

  -- 10
  ItemID_10 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 = -1, @itemId, ItemID_10),

  -- 11
  ItemID_11 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 = -1, @itemId, ItemID_11),

  -- 12
  ItemID_12 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 = -1, @itemId, ItemID_12),

  -- 13
  ItemID_13 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 = -1, @itemId, ItemID_13),

  -- 14
  ItemID_14 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 = -1, @itemId, ItemID_14),

  -- 15
  ItemID_15 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 = -1, @itemId, ItemID_15),

  -- 16
  ItemID_16 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 <> -1 AND ItemID_16 = -1, @itemId, ItemID_16),

  -- 17
  ItemID_17 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 <> -1 AND ItemID_16 <> -1 AND ItemID_17 = -1, @itemId, ItemID_17),

  -- 18
  ItemID_18 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 <> -1 AND ItemID_16 <> -1 AND ItemID_17 <> -1 AND ItemID_18 = -1, @itemId, ItemID_18),

  -- 19
  ItemID_19 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 <> -1 AND ItemID_16 <> -1 AND ItemID_17 <> -1 AND ItemID_18 <> -1 AND ItemID_19 = -1, @itemId, ItemID_19),

  -- 20
  ItemID_20 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 <> -1 AND ItemID_16 <> -1 AND ItemID_17 <> -1 AND ItemID_18 <> -1 AND ItemID_19 <> -1 AND ItemID_20 = -1, @itemId, ItemID_20),

  -- 21
  ItemID_21 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 <> -1 AND ItemID_16 <> -1 AND ItemID_17 <> -1 AND ItemID_18 <> -1 AND ItemID_19 <> -1 AND ItemID_20 <> -1 AND ItemID_21 = -1, @itemId, ItemID_21),

  -- 22
  ItemID_22 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 <> -1 AND ItemID_16 <> -1 AND ItemID_17 <> -1 AND ItemID_18 <> -1 AND ItemID_19 <> -1 AND ItemID_20 <> -1 AND ItemID_21 <> -1 AND ItemID_22 = -1, @itemId, ItemID_22),

  -- 23
  ItemID_23 = IF(ItemID_1  <> -1 AND ItemID_2  <> -1 AND ItemID_3  <> -1 AND ItemID_4  <> -1 AND ItemID_5  <> -1 AND ItemID_6  <> -1 AND ItemID_7  <> -1 AND ItemID_8  <> -1 AND ItemID_9  <> -1 AND ItemID_10 <> -1 AND ItemID_11 <> -1 AND ItemID_12 <> -1 AND ItemID_13 <> -1 AND ItemID_14 <> -1 AND ItemID_15 <> -1 AND ItemID_16 <> -1 AND ItemID_17 <> -1 AND ItemID_18 <> -1 AND ItemID_19 <> -1 AND ItemID_20 <> -1 AND ItemID_21 <> -1 AND ItemID_22 <> -1 AND ItemID_23 = -1, @itemId, ItemID_23)
WHERE RaceID = @race AND ClassID = @class AND SexID = @gender
LIMIT 1;
```
I don't even know if this works, BUT THIS IS JUST FOR ONE RACE-CLASS-GENDER COMBO! I have no idea why the
`charstartoutfit_dbc` table is structured like this. *Yes,* it's mirroring the dbc-file itself, but *whyyy?!*

At this point, I abandoned the idea of using the database to modify starter outfits. It's mod time! The most obvious
solution was to create a `PlayerScript` and override `OnPlayerCreate` and assign the item there, right? Haha, *right?*
NOPE! Turns out that despite the method giving you a `Player` instance, you're not *really* supposed to do anything with
it. Is this documented anywhere? Haha, no.

Luckily there's `OnPlayerFirstLogin`, which *does* work, thank goodness: I was 🤏 close to committing seppuku. Giving
players the starter wand in-script also means I don't need to limit the starter wand to *just* priests, mages, and
warlocks, but to anyone who has the wand skill at time of character creation. Feel free to give druids the wand-skill :)
