local _, ns = ...

-- Dungeons available at the WoW Forever launch, grouped by the UiMapID of
-- their entrance zone. Ranges are the dungeon ranges, not minimum entry levels.
-- Sources (checked 2026-11-16):
-- https://worldofwarcraft.blizzard.com/en-us/news/24301455/explore-the-new-dungeons-of-world-of-warcraft-forever
-- https://www.wowhead.com/forever/guide/dungeons-overview-locations-details
-- Map IDs are from the Forever client map API. Both approaches to Blackrock
-- Mountain are listed so the original Cartographer hover behavior is retained.
-- Raids are omitted because the first Forever raids unlock on 2026-12-09.

local blackrock = {
    { name = "Blackrock Depths", ru = "Глубины Черной горы", low = 52, high = 60, size = 5 },
    { name = "Lower Blackrock Spire", ru = "Нижний ярус Пика Черной горы", low = 55, high = 60, size = 5 },
    { name = "Upper Blackrock Spire", ru = "Верхний ярус Пика Черной горы", low = 58, high = 60, size = 10 },
}

ns.DungeonData = {
    -- Eastern Kingdoms
    [1455] = { -- Ironforge
        { name = "Hall of Thanes", ru = "Hall of Thanes", low = 13, high = 18, size = 5 },
    },
    [1420] = { -- Tirisfal Glades
        { name = "Ruins of Lordaeron", ru = "Ruins of Lordaeron", low = 15, high = 20, size = 5 },
        { name = "Scarlet Monastery: Graveyard", ru = "Монастырь Алого ордена: Кладбище", low = 28, high = 38, size = 5 },
        { name = "Scarlet Monastery: Library", ru = "Монастырь Алого ордена: Библиотека", low = 29, high = 39, size = 5 },
        { name = "Scarlet Monastery: Armory", ru = "Монастырь Алого ордена: Оружейная", low = 32, high = 42, size = 5 },
        { name = "Scarlet Monastery: Cathedral", ru = "Монастырь Алого ордена: Собор", low = 35, high = 45, size = 5 },
    },
    [1436] = { -- Westfall
        { name = "The Deadmines", ru = "Мертвые копи", low = 18, high = 23, size = 5 },
    },
    [1421] = { -- Silverpine Forest
        { name = "Shadowfang Keep", ru = "Крепость Темного Клыка", low = 22, high = 30, size = 5 },
    },
    [1453] = { -- Stormwind City
        { name = "The Stockade", ru = "Тюрьма", low = 22, high = 30, size = 5 },
    },
    [1437] = { -- Wetlands
        { name = "Excavation Site: Wetlands", ru = "Excavation Site: Wetlands", low = 24, high = 29, size = 5 },
    },
    [1416] = { -- Alterac Mountains
        { name = "City of Dalaran", ru = "City of Dalaran", low = 28, high = 33, size = 5 },
    },
    [1426] = { -- Dun Morogh
        { name = "Gnomeregan", ru = "Гномреган", low = 29, high = 38, size = 5 },
    },
    [1434] = { -- Stranglethorn Vale
        { name = "The Drowned City", ru = "The Drowned City", low = 35, high = 40, size = 5 },
    },
    [2548] = { -- Riverglades
        { name = "Krol'dok Stronghold", ru = "Krol'dok Stronghold", low = 40, high = 45, size = 5 },
    },
    [1418] = { -- Badlands
        { name = "Uldaman", ru = "Ульдаман", low = 42, high = 52, size = 5 },
    },
    [1427] = blackrock, -- Searing Gorge approach to Blackrock Mountain
    [1428] = blackrock, -- Burning Steppes approach to Blackrock Mountain
    [1435] = { -- Swamp of Sorrows
        { name = "Temple of Atal'Hakkar", ru = "Храм Атал'Хаккара", low = 50, high = 60, size = 5 },
    },
    [1422] = { -- Western Plaguelands
        { name = "Scholomance", ru = "Некроситет", low = 58, high = 60, size = 5 },
    },
    [1423] = { -- Eastern Plaguelands
        { name = "Stratholme", ru = "Стратхольм", low = 58, high = 60, size = 5 },
    },

    -- Kalimdor
    [1454] = { -- Orgrimmar
        { name = "Ragefire Chasm", ru = "Огненная Пропасть", low = 13, high = 18, size = 5 },
    },
    [1413] = { -- The Barrens
        { name = "Wailing Caverns", ru = "Пещеры Стенаний", low = 15, high = 25, size = 5 },
        { name = "Razorfen Kraul", ru = "Лабиринты Иглошкурых", low = 30, high = 40, size = 5 },
        { name = "Razorfen Downs", ru = "Курганы Иглошкурых", low = 40, high = 50, size = 5 },
    },
    [1440] = { -- Ashenvale
        { name = "Blackfathom Deeps", ru = "Непроглядная Пучина", low = 24, high = 32, size = 5 },
    },
    [1443] = { -- Desolace
        { name = "Maraudon: Wicked Grotto", ru = "Maraudon: Wicked Grotto", low = 45, high = 53, size = 5 },
        { name = "Maraudon: Foulspore Cavern", ru = "Maraudon: Foulspore Cavern", low = 45, high = 53, size = 5 },
        { name = "Maraudon: Earth Song Falls", ru = "Maraudon: Earth Song Falls", low = 48, high = 57, size = 5 },
    },
    [1445] = { -- Dustwallow Marsh
        { name = "Alcaz Prison", ru = "Alcaz Prison", low = 48, high = 53, size = 5 },
    },
    [1446] = { -- Tanaris
        { name = "Zul'Farrak", ru = "Зул'Фаррак", low = 44, high = 54, size = 5 },
    },
    [1447] = { -- Azshara
        { name = "Blackmaw Hold", ru = "Blackmaw Hold", low = 55, high = 60, size = 5 },
    },
    [1449] = { -- Un'Goro Crater
        { name = "Shaper's Terrace", ru = "Shaper's Terrace", low = 58, high = 60, size = 5 },
    },
    [1444] = { -- Feralas
        { name = "Dire Maul", ru = "Забытый Город", low = 58, high = 60, size = 5 },
    },
}
