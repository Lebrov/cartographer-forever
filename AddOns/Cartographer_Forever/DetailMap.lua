local _, ns = ...

-- Draw the Forever client's minimap terrain on this addon's own MapCanvas.
-- Geometry and tile FileDataIDs are adapted from TerrainWorldMap (MIT);
-- see DetailMapData.lua and DetailMap-LICENSE.txt.
local data = ns.DetailMapData
local TILE_WORLD_SIZE = 533.3333
local continentMapIDs = {
    [1415] = "Azeroth",
    [1414] = "Kalimdor",
    [2665] = "2991",
}
local pending = setmetatable({}, { __mode = "k" })
local regen = CreateFrame("Frame")

local function IsEnabled()
    local settings = ns.db and ns.db.settings
    return settings and settings.showDetailMap == true
end

local function CanRespectFog(mapID)
    local settings = ns.db and ns.db.settings
    if not settings or settings.revealFog ~= false then return true end
    -- A terrain tile has no explored-area mask of its own. Use the client's
    -- native FogOfWar pin above it, or fall back to the painted map when the
    -- current map has no native fog mask.
    if not C_FogOfWar or not C_FogOfWar.GetFogOfWarForMap then return false end
    local ok, fogID = pcall(C_FogOfWar.GetFogOfWarForMap, mapID)
    return ok and type(fogID) == "number" and fogID > 0
end

local function Defer(map)
    pending[map] = true
    regen:RegisterEvent("PLAYER_REGEN_ENABLED")
end

regen:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    for map in pairs(pending) do
        pending[map] = nil
        ns.RefreshDetailMap(map)
    end
end)

local function SetNativeArtShown(map, shown)
    local pool = map.detailLayerPool
    if pool and pool.EnumerateActive then
        for layer in pool:EnumerateActive() do
            layer:SetShown(shown)
        end
    end
end

local function SetExplorationShown(map, shown)
    if not map.EnumeratePinsByTemplate then return end
    for pin in map:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        pin:SetShown(shown)
    end
end

local function GetViewBox(mapID)
    if not mapID or not data or not data.areas then return end
    local continent = continentMapIDs[mapID]
    local zone = data.zones and data.zones[mapID]
    local box
    if zone then
        continent = zone[1]
        box = data.areas[continent] and data.areas[continent][zone[2]]
    elseif continent then
        box = data.areas[continent] and data.areas[continent][0]
    end
    if box then return continent, box end
end

local function AcquireTexture(overlay, index)
    local texture = overlay.tiles[index]
    if not texture then
        texture = overlay:CreateTexture(nil, "ARTWORK")
        if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
        if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
        overlay.tiles[index] = texture
    end
    return texture
end

local function ReleaseTextures(overlay, fromIndex)
    for index = fromIndex, #overlay.tiles do
        local texture = overlay.tiles[index]
        texture:Hide()
        texture:SetTexture(nil)
    end
end

local function DrawTiles(overlay, continent, box)
    local valid = data.tiles and data.tiles[continent]
    local fileIDs = data.fileIDs and data.fileIDs[continent]
    if not valid or not fileIDs then return false end

    local width, height = overlay:GetSize()
    if not width or width <= 0 or not height or height <= 0 then return false end
    local x1, x2, y1, y2 = box[1], box[2], box[3], box[4]
    if not x1 or not x2 or not y1 or not y2 or x1 == x2 or y1 == y2 then return false end

    local col1, col2 = x1 / -TILE_WORLD_SIZE + 32, x2 / -TILE_WORLD_SIZE + 32
    local row1, row2 = y1 / -TILE_WORLD_SIZE + 32, y2 / -TILE_WORLD_SIZE + 32
    local count = 0
    for col = math.max(0, math.floor(math.min(col1, col2))),
        math.min(63, math.ceil(math.max(col1, col2)) - 1) do
        for row = math.max(0, math.floor(math.min(row1, row2))),
            math.min(63, math.ceil(math.max(row1, row2)) - 1) do
            if valid[string.format("%02dx%02d", col, row)] then
                local id = fileIDs[string.format("map%02d_%02d", col, row)]
                if id then
                    local bigX1, bigY1 = (col - 32) * -TILE_WORLD_SIZE,
                        (row - 32) * -TILE_WORLD_SIZE
                    local bigX2, bigY2 = (col + 1 - 32) * -TILE_WORLD_SIZE,
                        (row + 1 - 32) * -TILE_WORLD_SIZE
                    local px1, py1 = (x1 - bigX1) / (x1 - x2) * width,
                        (y1 - bigY1) / (y1 - y2) * height
                    local px2, py2 = (x1 - bigX2) / (x1 - x2) * width,
                        (y1 - bigY2) / (y1 - y2) * height
                    local left, right = math.min(px1, px2), math.max(px1, px2)
                    local top, bottom = math.min(py1, py2), math.max(py1, py2)
                    local clipLeft, clipRight = math.max(0, left), math.min(width, right)
                    local clipTop, clipBottom = math.max(0, top), math.min(height, bottom)
                    if clipRight > clipLeft and clipBottom > clipTop then
                        count = count + 1
                        local texture = AcquireTexture(overlay, count)
                        texture:ClearAllPoints()
                        texture:SetPoint("TOPLEFT", overlay, "TOPLEFT", clipLeft, -clipTop)
                        texture:SetSize(clipRight - clipLeft, clipBottom - clipTop)
                        texture:SetTexCoord(
                            (clipLeft - left) / (right - left),
                            (clipRight - left) / (right - left),
                            (clipTop - top) / (bottom - top),
                            (clipBottom - top) / (bottom - top))
                        texture:SetTexture(id, nil, nil, "TRILINEAR")
                        texture:Show()
                    end
                end
            end
        end
    end
    ReleaseTextures(overlay, count + 1)
    return count > 0
end

local function ClearCityTiles(overlay)
    for _, bucket in ipairs(overlay.cityBuckets) do
        for _, texture in ipairs(bucket.tiles) do
            texture:Hide()
            texture:SetTexture(nil)
        end
        bucket:Hide()
    end
end

local function AcquireCityBucket(overlay, index)
    local bucket = overlay.cityBuckets[index]
    if not bucket then
        bucket = CreateFrame("Frame", nil, overlay)
        bucket:SetAllPoints(overlay)
        bucket:EnableMouse(false)
        bucket.tiles = {}
        overlay.cityBuckets[index] = bucket
    end
    -- Sixteen ARTWORK texture sublevels per bucket preserve the WMO groups'
    -- height order. Nineteen buckets cover Stormwind's 297 groups while
    -- remaining below the map's readout frame.
    bucket:SetFrameLevel(overlay:GetFrameLevel() + index)
    return bucket
end

local function AcquireCityTexture(bucket, index)
    local texture = bucket.tiles[index]
    if not texture then
        texture = bucket:CreateTexture(nil, "ARTWORK")
        if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
        if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
        bucket.tiles[index] = texture
    end
    return texture
end

local function DrawCityTiles(overlay, mapID, box)
    local groups = data.cityWMO and data.cityWMO[mapID]
    if not groups then
        ClearCityTiles(overlay)
        return false
    end
    local width, height = overlay:GetSize()
    if not width or width <= 0 or not height or height <= 0 then
        ClearCityTiles(overlay)
        return false
    end
    local x1, x2, y1, y2 = box[1], box[2], box[3], box[4]
    local sx, sy = width / (x1 - x2), height / (y1 - y2)
    local ordered = {}
    for order, group in ipairs(groups) do
        if group[1] then
            ordered[#ordered + 1] = { group = group, z = group[1][7] or 0, order = order }
        end
    end
    table.sort(ordered, function(a, b)
        if a.z ~= b.z then return a.z < b.z end
        return a.order < b.order
    end)

    local used = {}
    for rank, entry in ipairs(ordered) do
        local bucketIndex = math.floor((rank - 1) / 16) + 1
        local bucket = AcquireCityBucket(overlay, bucketIndex)
        local sublevel = ((rank - 1) % 16) - 8
        for _, tile in ipairs(entry.group) do
            local index = (used[bucketIndex] or 0) + 1
            used[bucketIndex] = index
            local texture = AcquireCityTexture(bucket, index)
            texture:ClearAllPoints()
            texture:SetDrawLayer("ARTWORK", sublevel)
            texture:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
            texture:SetPoint("CENTER", overlay, "TOPLEFT",
                (x1 - tile[2]) * sx, -(y1 - tile[3]) * sy)
            texture:SetSize(tile[5] * sx, tile[4] * sy)
            texture:SetRotation(math.rad(-(tile[6] or 0)), { x = 0.5, y = 0.5 })
            texture:SetTexture(tile[1])
            texture:Show()
        end
        bucket:Show()
    end
    for index, bucket in ipairs(overlay.cityBuckets) do
        local count = used[index] or 0
        for tileIndex = count + 1, #bucket.tiles do
            local texture = bucket.tiles[tileIndex]
            texture:Hide()
            texture:SetTexture(nil)
        end
        bucket:SetShown(count > 0)
    end
    return #ordered > 0
end

function ns.RefreshDetailMap(map)
    if not map or not map.DetailOverlay then return end
    if InCombatLockdown and InCombatLockdown() then
        Defer(map)
        return
    end

    local overlay = map.DetailOverlay
    local continent, box
    if IsEnabled() and CanRespectFog(map:GetMapID()) then
        continent, box = GetViewBox(map:GetMapID())
    end
    local hasTerrain = continent and DrawTiles(overlay, continent, box)
    local hasCity = continent and DrawCityTiles(overlay, map:GetMapID(), box)
    if not hasTerrain and not hasCity then
        overlay:Hide()
        ReleaseTextures(overlay, 1)
        ClearCityTiles(overlay)
        SetNativeArtShown(map, true)
        SetExplorationShown(map, true)
        return
    end

    overlay:Show()
    SetNativeArtShown(map, false)
    SetExplorationShown(map, false)
end

function ns.SetupDetailMap(map)
    if not map or not map.GetCanvas or map.DetailOverlay then return end
    local canvas = map:GetCanvas()
    if not canvas then return end
    local overlay = CreateFrame("Frame", nil, canvas)
    overlay:SetAllPoints(canvas)
    -- Native detail layers use the canvas level; pins start at 2000.
    -- Keep our terrain below the readout overlay (ScrollContainer + 40).
    overlay:SetFrameLevel(canvas:GetFrameLevel() + 10)
    overlay:EnableMouse(false)
    overlay.tiles = {}
    overlay.cityBuckets = {}
    local backdrop = overlay:CreateTexture(nil, "BACKGROUND")
    backdrop:SetAllPoints(overlay)
    backdrop:SetColorTexture(0, 0, 0, 1)
    overlay:Hide()
    map.DetailOverlay = overlay

    -- MapCanvas recreates art layers after some map changes. Keep the terrain
    -- above those layers while the detail mode is active.
    if hooksecurefunc and type(map.RefreshDetailLayers) == "function" then
        hooksecurefunc(map, "RefreshDetailLayers", function()
            if IsEnabled() then ns.RefreshDetailMap(map) end
        end)
    end
    if hooksecurefunc and type(map.OnCanvasSizeChanged) == "function" then
        hooksecurefunc(map, "OnCanvasSizeChanged", function()
            if IsEnabled() then ns.RefreshDetailMap(map) end
        end)
    end
    if hooksecurefunc and type(map.AdjustDetailLayerAlpha) == "function" then
        hooksecurefunc(map, "AdjustDetailLayerAlpha", function()
            if overlay:IsShown() then SetNativeArtShown(map, false) end
        end)
    end
    if hooksecurefunc and map.explorationProvider
        and type(map.explorationProvider.RefreshAll) == "function" then
        hooksecurefunc(map.explorationProvider, "RefreshAll", function()
            if overlay:IsShown() then SetExplorationShown(map, false) end
        end)
    end
end
