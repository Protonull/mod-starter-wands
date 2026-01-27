-- Adjust damage and durability of the Alchemist's Wand to be comparable to an Old Blunderbuss (2508) with ammo
UPDATE `item_template` SET `dmg_min1` = 2, `dmg_max1` = 5, `delay` = 1900, `MaxDurability` = 20 WHERE (`entry` = 5235);
