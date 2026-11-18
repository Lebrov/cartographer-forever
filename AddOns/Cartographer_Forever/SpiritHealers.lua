local _, ns = ...

-- Graveyard locations from the Forever client's native map API are more
-- reliable than the older Leatrix spirit-healer list in POIData.lua. The
-- healer NPC can be a short walk from the resurrection point. The static
-- list remains a fallback when the native API has no data for a map.
local liveGraveyards = {}
local GRAVEYARD_TTL = 60

local function FactionForGraveyard(mapID, x, y, graveyard)
    -- Legacy POIIcons graveyard symbols: Horde 13, Alliance 15. The generic
    -- gravestone (8) does not state a faction. Texture indices may be secret
    -- client values, so an unreadable hint must not hide the graveyard pin.
    local readable, hint = pcall(function()
        if graveyard.textureIndex == 13 then return "horde" end
        if graveyard.textureIndex == 15 then return "alliance" end
    end)
    if readable and hint then return hint end

    -- The static Forever POI list labels faction homelands and settlement
    -- graveyards. Match only a nearby point on the same zone map so a remote
    -- contested graveyard does not inherit a settlement's faction.
    local points = ns.POIData and ns.POIData[mapID] or {}
    local nearest, distance
    for _, point in ipairs(points) do
        if point.kind == "spirit" then
            local dx, dy = x - point.x, y - point.y
            local squared = dx * dx + dy * dy
            if not distance or squared < distance then
                nearest, distance = point, squared
            end
        end
    end
    if nearest and distance <= 16 then return nearest.faction or "neutral" end
    return "neutral"
end

function ns.GetSpiritHealersForMap(mapID)
    local now = GetTime and GetTime() or 0
    local cached = liveGraveyards[mapID]
    if cached and now < cached.expires then return cached.points end
    if not C_DeathInfo or not C_DeathInfo.GetGraveyardsForMap then return nil end

    local ok, result = pcall(C_DeathInfo.GetGraveyardsForMap, mapID)
    if not ok or type(result) ~= "table" then return nil end

    local points = {}
    local readable, count = pcall(function() return #result end)
    if not readable or type(count) ~= "number" then return nil end
    for index = 1, count do
        local read, point = pcall(function()
            local graveyard = result[index]
            local position = graveyard and graveyard.position
            if position then
                local x, y
                if position.GetXY then
                    x, y = position:GetXY()
                else
                    x, y = position.x, position.y
                end
                if type(x) == "number" and type(y) == "number"
                    and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                    local percentX, percentY = x * 100, y * 100
                    return {
                        kind = "spirit", zone = mapID, x = percentX, y = percentY,
                        name = "Spirit Healer", native = true,
                        faction = FactionForGraveyard(mapID, percentX, percentY,
                            graveyard),
                    }
                end
            end
        end)
        if read and point then
            points[#points + 1] = point
        end
    end
    if #points == 0 then
        liveGraveyards[mapID] = { points = false, expires = now + GRAVEYARD_TTL }
        return nil
    end
    liveGraveyards[mapID] = { points = points, expires = now + GRAVEYARD_TTL }
    return points
end
