-- Deprecate the Beginner Wand, based off of Small Pocket Watch (5374)
UPDATE `item_template` SET `name` = 'Broken Wand', `class` = 15, `subclass` = 0, `Quality` = 0, `Flags` = 0, `ItemLevel` = 1, `RequiredLevel` = 0, `dmg_min1` = 0, `dmg_max1` = 0, `dmg_type1` = 0, `delay` = 0, `RangedModRange` = 0, `Material` = -1, `MaxDurability` = 0 WHERE (`entry` = 99760);
