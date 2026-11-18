local addonName, ns = ...

-- Static fallback for WoW Forever Group Finder's zone ranges, keyed by uiMapID.
-- Reported from launch client build 1.60.1.70938:
-- https://endgametools.com/en/wow-forever/news/wow-forever-leveling-zones
-- Use live Group Finder suggested levels in preference to these cached values.
-- Shen'dralas has no reported Group Finder range; its entry is estimated.
ns.ZoneInfoData = {
    -- Eastern Kingdoms
    [1426] = { low = 1, high = 14 },   -- Dun Morogh
    [1429] = { low = 1, high = 14 },   -- Elwynn Forest
    [1420] = { low = 1, high = 14 },   -- Tirisfal Glades
    [1432] = { low = 8, high = 24 },   -- Loch Modan
    [1436] = { low = 8, high = 24 },   -- Westfall
    [1421] = { low = 8, high = 24 },   -- Silverpine Forest
    [1433] = { low = 13, high = 30 },  -- Redridge Mountains
    [1431] = { low = 18, high = 34 },  -- Duskwood
    [1437] = { low = 18, high = 34 },  -- Wetlands
    [1424] = { low = 18, high = 34 },  -- Hillsbrad Foothills
    [1416] = { low = 28, high = 44 },  -- Alterac Mountains
    [1417] = { low = 28, high = 44 },  -- Arathi Highlands
    [1434] = { low = 28, high = 50 },  -- Stranglethorn Vale
    [1418] = { low = 33, high = 50 },  -- Badlands
    [1435] = { low = 33, high = 50 },  -- Swamp of Sorrows
    [1425] = { low = 38, high = 54 },  -- The Hinterlands
    [1427] = { low = 43, high = 60 },  -- Searing Gorge
    [1419] = { low = 43, high = 60 },  -- Blasted Lands
    [1428] = { low = 48, high = 60 },  -- Burning Steppes
    [1422] = { low = 48, high = 60 },  -- Western Plaguelands
    [1423] = { low = 53, high = 63 },  -- Eastern Plaguelands
    [2548] = { low = 33, high = 54 },  -- Riverglades (Forever)

    -- Kalimdor
    [1411] = { low = 1, high = 14 },   -- Durotar
    [1412] = { low = 1, high = 14 },   -- Mulgore
    [1438] = { low = 1, high = 14 },   -- Teldrassil
    [1439] = { low = 8, high = 24 },   -- Darkshore
    [1413] = { low = 8, high = 30 },   -- The Barrens
    [1442] = { low = 13, high = 32 },  -- Stonetalon Mountains
    [1440] = { low = 18, high = 34 },  -- Ashenvale
    [1441] = { low = 23, high = 40 },  -- Thousand Needles
    [1443] = { low = 28, high = 44 },  -- Desolace
    [1445] = { low = 33, high = 50 },  -- Dustwallow Marsh
    [1444] = { low = 38, high = 54 },  -- Feralas
    [1446] = { low = 38, high = 54 },  -- Tanaris
    [1447] = { low = 43, high = 60 },  -- Azshara
    [1448] = { low = 46, high = 60 },  -- Felwood
    [1449] = { low = 45, high = 60 },  -- Un'Goro Crater
    [1451] = { low = 53, high = 60 },  -- Silithus
    [1452] = { low = 53, high = 63 },  -- Winterspring
    [2482] = { low = 55, high = 60 },  -- Mount Hyjal (Forever)
    [2652] = { low = 35, high = 45, estimated = true }, -- Shen'dralas (Forever)

    -- Separate starting island
    [2521] = { low = 1, high = 14 },   -- Zephras Isle (Forever)
}
