local _, ns = ...

-- Painted maps from the user's installed ForeverInstanceMaps 1.59 addon.
-- Original map recreations are credited there to Santiago Reyes (Atlas de
-- Azeroth Forever). Keep local copies so this addon can display them alone.
local root = "Interface\\AddOns\\Cartographer_Forever\\Textures\\Maps\\"

local function NextPowerOfTwo(value)
    local size = 1
    while size < value do size = size * 2 end
    return size
end

local function Painted(key, rows, sourceWidth, sourceHeight)
    sourceWidth = sourceWidth or 1000
    sourceHeight = sourceHeight or 667
    local texRight = sourceWidth / NextPowerOfTwo(sourceWidth)
    local texBottom = sourceHeight / NextPowerOfTwo(sourceHeight)
    local floors = {}
    for index, row in ipairs(rows) do
        floors[index] = {
            floor = index,
            name = row[2],
            image = root .. row[1],
            texRight = texRight,
            texBottom = texBottom * (row[3] or 1),
        }
    end
    ns.TravelArt[key] = floors
end

Painted(33, { -- Shadowfang Keep
    { "ShadowfangKeep_1.blp", "Courtyard" },
    { "ShadowfangKeep_2.blp", "Kitchen" },
    { "ShadowfangKeep_3.blp", "Jail" },
    { "ShadowfangKeep_4.blp", "Courtyard's First Floor" },
    { "ShadowfangKeep_5.blp", "Fenrus' Room" },
    { "ShadowfangKeep_6.blp", "Fenrus' First Floor" },
    { "ShadowfangKeep_7.blp", "Nandos and Arugal's Chambers" },
})
Painted(34, { { "Stockade.blp" } })
Painted(36, { -- Deadmines
    { "Deadmines_Upper.blp", "Upper Deadmines" },
    { "Deadmines_Lower.blp", "Lower Deadmines" },
})
Painted(43, { { "WailingCaverns.blp" } })
Painted(47, { { "RazorfenKraul.blp" } })
Painted(48, { -- Blackfathom Deeps
    { "BlackfathomDeeps_1.blp", "Pool of Ask'ar" },
    { "BlackfathomDeeps_2.blp", "Moonshrine Sanctum" },
    { "BlackfathomDeeps_3.blp", "Forgotten Pool" },
})
Painted(70, { -- Uldaman
    { "Uldaman_1.blp", "Ruins" },
    { "Uldaman_2.blp", "Khaz'goroth's Seat" },
}, 1002, 668)
Painted(90, { -- Gnomeregan
    { "Gnomeregan_1.blp", "Hall of Gears" },
    { "Gnomeregan_2.blp", "Dormitory" },
    { "Gnomeregan_3.blp", "Launch Bay" },
    { "Gnomeregan_4.blp", "Tinkers' Court" },
})
Painted(129, { { "RazorfenDowns.blp" } }, 1002, 668)
Painted(209, { { "ZulFarrak.blp" } }, 1002, 668)
Painted(249, { { "OnyxiasLair.blp" } }, 1002, 668)
Painted(349, { -- Maraudon
    { "Maraudon_1.blp", "Caverns of Maraudon" },
    { "Maraudon_2.blp", "Zaetar's Grave" },
}, 1002, 668)
Painted(389, { { "RagefireChasm.blp" } })

-- Four Scarlet Monastery wings share game instance ID 189. The entrance's
-- artKey selects the specific image instead of the generic instance number.
Painted("SMGraveyard", { { "SMGraveyard.blp" } }, 1002, 668)
Painted("SMLibrary", { { "SMLibrary.blp" } }, 1002, 668)
Painted("SMArmory", { { "SMArmory.blp" } }, 1002, 668)
Painted("SMCathedral", { { "SMCathedral.blp" } }, 1002, 668)
ns.TravelArt[189] = ns.TravelArt.SMGraveyard

Painted(3065, { { "HallOfThanes.blp" } }, 1200, 800)
Painted(2999, { { "RuinsOfLordaeron.blp" } }, 1200, 800)
Painted(2998, { { "ExcavationSite.blp" } }, 1200, 800)
Painted(2959, {
    { "CityOfDalaran_1.blp", "Sewers" },
    { "CityOfDalaran_2.blp", "Streets" },
}, 1200, 800)
Painted(2970, {
    { "DrownedCity_1.blp", "Upper" },
    { "DrownedCity_2.blp", "Lower (Atal'Byzal)" },
}, 1200, 800)

-- These four new dungeons are absent from ForeverInstanceMaps 1.59. Their
-- painted textures come from the user's installed ForeverDungeonJournal.
-- The visible artwork fills the top 683 rows of each 1024-row TGA.
local journalCrop = 683 / 1024
-- Use the journal's current single Temple of Atal'Hakkar map in place of
-- the older client tile map registered by TravelData.lua.
Painted(109, { { "SunkenTempleMap.blp", nil, journalCrop } }, 1024, 1024)

Painted(2994, { -- Alcaz Prison
    { "AlcazPrisonMap.blp", "Main Unit", journalCrop },
    { "AlcazPrisonMap2.blp", "Maximum Security Unit", journalCrop },
}, 1024, 1024)
Painted(3039, { { "KroldokMap.blp", nil, journalCrop } }, 1024, 1024)
Painted(2974, { -- Blackmaw Hold
    { "BlackmawHoldGroveMap.blp", "Blackmaw Grove", journalCrop },
    { "BlackmawHoldFesteringGrottoMap.blp", "Festering Grotto", journalCrop },
    { "BlackmawHoldFallenGroveMap.blp", "Depths of the Fallen Grove", journalCrop },
    { "BlackmawHoldEldersMap.blp", "Depths of the Elders", journalCrop },
    { "BlackmawHoldBurrowMap.blp", "Depths of the Burrow", journalCrop },
    { "BlackmawHoldForbiddenMagicMap.blp", "Depths of Forbidden Magic", journalCrop },
}, 1024, 1024)
Painted(3001, { { "ShapersTerraceMap.blp", nil, journalCrop } }, 1024, 1024)

-- ForeverInstanceMaps has no painted Dire Maul art. The client's tiles are
-- separated into the wing-specific floors identified by ForeverDungeonJournal.
local dire = ns.TravelArt[429]
if dire and #dire >= 7 then
    local function WingFloor(index, name)
        local source = dire[index]
        return { floor = source.floor, name = name, path = source.path, tiles = source.tiles }
    end
    ns.TravelArt.DireMaulNorth = {
        WingFloor(2, "Gordok Commons"),
    }
    ns.TravelArt.DireMaulWest = {
        WingFloor(3, "Capital Gardens"),
        WingFloor(4, "Court of the Highborne"),
        WingFloor(5, "Prison of Immol'thar"),
    }
    ns.TravelArt.DireMaulEast = {
        WingFloor(7, "The Shrine of Eldretharr"),
        WingFloor(6, "Warpwood Quarter"),
    }
end
