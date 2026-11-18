local _, ns = ...

-- Render actual minimap terrain and WMO tiles from the Forever client in
-- TravelViewer. Geometry and FileDataIDs: TerrainWorldMap (MIT); see
-- InstanceArtData.lua and DetailMap-LICENSE.txt.
local data = ns.InstanceArtData
local TILE_WORLD_SIZE = 533.3333
local PIVOT = { x = 0.5, y = 0.5 }

-- TravelData supplies classic floor maps. Add terrain maps only where those
-- Blizzard floor tiles are not present. These include every new Forever
-- launch dungeon, Wailing Caverns, and classic raids with no static art.
for instanceID in pairs(data) do
    if not ns.TravelArt[instanceID] then
        ns.TravelArt[instanceID] = {
            { floor = 1, render = "terrain", instanceID = instanceID },
        }
    end
end

local function AcquireOverlay(viewer)
    local overlay = viewer.instanceArt
    if overlay then return overlay end
    overlay = CreateFrame("Frame", nil, viewer.art)
    overlay:SetAllPoints(viewer.art)
    overlay:SetFrameLevel(viewer.art:GetFrameLevel() + 1)
    overlay:EnableMouse(false)
    if overlay.SetClipsChildren then overlay:SetClipsChildren(true) end
    local background = overlay:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(overlay)
    background:SetColorTexture(0.035, 0.045, 0.065, 1)
    overlay.terrainTiles = {}
    overlay.wmoBuckets = {}
    overlay:Hide()
    viewer.instanceArt = overlay
    return overlay
end

local function AcquireTerrainTexture(overlay, index)
    local texture = overlay.terrainTiles[index]
    if not texture then
        texture = overlay:CreateTexture(nil, "ARTWORK")
        if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
        if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
        overlay.terrainTiles[index] = texture
    end
    return texture
end

local function AcquireWMOBucket(overlay, index)
    local bucket = overlay.wmoBuckets[index]
    if not bucket then
        bucket = CreateFrame("Frame", nil, overlay)
        bucket:SetAllPoints(overlay)
        bucket:EnableMouse(false)
        bucket.tiles = {}
        overlay.wmoBuckets[index] = bucket
    end
    bucket:SetFrameLevel(overlay:GetFrameLevel() + index)
    return bucket
end

local function AcquireWMOTexture(bucket, index)
    local texture = bucket.tiles[index]
    if not texture then
        texture = bucket:CreateTexture(nil, "ARTWORK")
        if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
        if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
        bucket.tiles[index] = texture
    end
    return texture
end

local function IsLoaded(texture)
    if texture.GetTextureFileID then
        local ok, id = pcall(texture.GetTextureFileID, texture)
        return ok and type(id) == "number" and id > 0
    end
    if texture.GetTexture then
        local ok, id = pcall(texture.GetTexture, texture)
        return ok and type(id) == "number" and id > 0
    end
    return false
end

local function SetTile(texture, id)
    local ok = pcall(texture.SetTexture, texture, id, nil, nil, "TRILINEAR")
    local loaded = ok and IsLoaded(texture)
    texture:SetShown(loaded)
    return loaded
end

function ns.ClearInstanceArt(viewer)
    local overlay = viewer and viewer.instanceArt
    if not overlay then return end
    viewer.instanceArtPartial = nil
    for _, texture in ipairs(overlay.terrainTiles) do
        texture:Hide()
        texture:SetTexture(nil)
    end
    for _, bucket in ipairs(overlay.wmoBuckets) do
        for _, texture in ipairs(bucket.tiles) do
            texture:Hide()
            texture:SetTexture(nil)
        end
        bucket:Hide()
    end
    overlay:Hide()
end

local function DrawTerrain(overlay, record, width, height, scale, offsetX, offsetY)
    local box = record.box
    local x1, x2, y1, y2 = box[1], box[2], box[3], box[4]
    local count, loaded = 0, 0
    for _, tile in ipairs(record.terrain) do
        local col, row, id = tile[1], tile[2], tile[3]
        local bigX1 = (col - 32) * -TILE_WORLD_SIZE
        local bigY1 = (row - 32) * -TILE_WORLD_SIZE
        local bigX2 = (col + 1 - 32) * -TILE_WORLD_SIZE
        local bigY2 = (row + 1 - 32) * -TILE_WORLD_SIZE
        local px1 = offsetX + (x1 - bigX1) * scale
        local py1 = offsetY + (y1 - bigY1) * scale
        local px2 = offsetX + (x1 - bigX2) * scale
        local py2 = offsetY + (y1 - bigY2) * scale
        local left, right = math.min(px1, px2), math.max(px1, px2)
        local top, bottom = math.min(py1, py2), math.max(py1, py2)
        local clipLeft, clipRight = math.max(0, left), math.min(width, right)
        local clipTop, clipBottom = math.max(0, top), math.min(height, bottom)
        if clipRight > clipLeft and clipBottom > clipTop then
            count = count + 1
            local texture = AcquireTerrainTexture(overlay, count)
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", overlay, "TOPLEFT", clipLeft, -clipTop)
            texture:SetSize(clipRight - clipLeft, clipBottom - clipTop)
            texture:SetTexCoord(
                (clipLeft - left) / (right - left),
                (clipRight - left) / (right - left),
                (clipTop - top) / (bottom - top),
                (clipBottom - top) / (bottom - top))
            if SetTile(texture, id) then loaded = loaded + 1 end
        end
    end
    for index = count + 1, #overlay.terrainTiles do
        overlay.terrainTiles[index]:Hide()
    end
    return count, loaded
end

local function DrawWMO(overlay, record, scale, offsetX, offsetY)
    local box = record.box
    local x1, x2, y1, y2 = box[1], box[2], box[3], box[4]
    local ordered = {}
    for order, group in ipairs(record.wmo) do
        if group[1] then
            ordered[#ordered + 1] = {
                group = group, z = group[1][7] or 0, order = order,
            }
        end
    end
    table.sort(ordered, function(a, b)
        if a.z ~= b.z then return a.z < b.z end
        return a.order < b.order
    end)
    local used = {}
    local total, loaded = 0, 0
    for rank, entry in ipairs(ordered) do
        local bucketIndex = math.floor((rank - 1) / 16) + 1
        local bucket = AcquireWMOBucket(overlay, bucketIndex)
        local sublevel = ((rank - 1) % 16) - 8
        for _, tile in ipairs(entry.group) do
            local index = (used[bucketIndex] or 0) + 1
            used[bucketIndex] = index
            local texture = AcquireWMOTexture(bucket, index)
            texture:ClearAllPoints()
            texture:SetDrawLayer("ARTWORK", sublevel)
            texture:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
            texture:SetPoint("CENTER", overlay, "TOPLEFT",
                offsetX + (x1 - tile[2]) * scale,
                -offsetY - (y1 - tile[3]) * scale)
            texture:SetSize(tile[5] * scale, tile[4] * scale)
            texture:SetRotation(math.rad(-(tile[6] or 0)), PIVOT)
            total = total + 1
            if SetTile(texture, tile[1]) then loaded = loaded + 1 end
        end
        bucket:Show()
    end
    for index, bucket in ipairs(overlay.wmoBuckets) do
        local count = used[index] or 0
        for tileIndex = count + 1, #bucket.tiles do
            bucket.tiles[tileIndex]:Hide()
        end
        bucket:SetShown(count > 0)
    end
    return total, loaded
end

function ns.RenderInstanceArt(viewer, instanceID, floor)
    local record = data and data[instanceID]
    if not viewer or not viewer.art or not record then return false end
    local overlay = AcquireOverlay(viewer)
    local width, height = overlay:GetSize()
    if not width or width <= 0 or not height or height <= 0 then return false end
    local box = record.box
    if not box or not box[1] or not box[2] or not box[3] or not box[4]
        or box[1] <= box[2] or box[3] <= box[4] then return false end
    -- Keep Big-coordinate proportions: dungeon bounds are not all 3:2.
    local worldWidth, worldHeight = box[1] - box[2], box[3] - box[4]
    local scale = math.min(width / worldWidth, height / worldHeight)
    local offsetX = (width - worldWidth * scale) / 2
    local offsetY = (height - worldHeight * scale) / 2
    local terrainCount, terrainLoaded =
        DrawTerrain(overlay, record, width, height, scale, offsetX, offsetY)
    local wmoCount, wmoLoaded = DrawWMO(overlay, record, scale, offsetX, offsetY)
    local total = terrainCount + wmoCount
    local loaded = terrainLoaded + wmoLoaded
    if total == 0 or loaded == 0 then
        ns.ClearInstanceArt(viewer)
        return false
    end
    viewer.instanceArtPartial = loaded < total
    overlay:Show()
    return true
end
