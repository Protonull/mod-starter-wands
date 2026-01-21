-- Remove Fire skill requirement from Alchemist's Wand and make not melee range
UPDATE `item_template` SET `RequiredSkill` = 0, `RangedModRange` = 100 WHERE (`entry` = 5235);