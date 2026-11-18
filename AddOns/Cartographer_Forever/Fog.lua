local addonName, ns = ...

-- Draw missing exploration art on our own map pin. Blizzard's exploration
-- texture pool and the character's exploration state are left untouched.
local pinState = setmetatable({}, { __mode = "k" })
local hookedPins = setmetatable({}, { __mode = "k" })
local hookedFogPins = setmetatable({}, { __mode = "k" })
local pendingMaps = setmetatable({}, { __mode = "k" })
local regenFrame = CreateFrame("Frame")

local function DeferUntilCombatEnds(map)
    if not map then return end
    pendingMaps[map] = true
    regenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

regenFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    for map in pairs(pendingMaps) do
        pendingMaps[map] = nil
        ns.RefreshFog(map)
    end
end)

local function RevealEnabled()
    local settings = ns.db and ns.db.settings
    return not settings or settings.revealFog ~= false
end

local function StateFor(pin)
    local state = pinState[pin]
    if not state then
        state = { textures = {}, active = 0 }
        pinState[pin] = state
    end
    return state
end

local function HideTextures(pin)
    if InCombatLockdown and InCombatLockdown() then
        DeferUntilCombatEnds(pin:GetMap())
        return
    end
    local state = pinState[pin]
    if not state then return end
    for index = 1, state.active do
        local texture = state.textures[index]
        texture:Hide()
        texture:ClearAllPoints()
        texture:SetTexture(nil)
    end
    state.active = 0
end

local function AcquireTexture(pin, state)
    local index = state.active + 1
    local texture = state.textures[index]
    if not texture then
        texture = pin:CreateTexture(nil, "ARTWORK", nil, -1)
        state.textures[index] = texture
    end
    state.active = index
    return texture
end

local function TextureFileSize(pixelSize)
    local fileSize = 16
    while fileSize < pixelSize do
        fileSize = fileSize * 2
    end
    return fileSize
end

local function Whole(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function DrawMissingAreas(pin)
    local map = pin:GetMap()
    if InCombatLockdown and InCombatLockdown() then
        DeferUntilCombatEnds(map)
        return
    end
    HideTextures(pin)
    if not RevealEnabled() then return end
    local mapID = map and map:GetMapID()
    if not mapID or not C_Map or not C_Map.GetMapArtID then return end
    local artID = C_Map.GetMapArtID(mapID)
    local overlays = artID and ns.FogData and ns.FogData[artID]
    if not overlays then return end

    local container = map:GetCanvasContainer()
    local layerIndex = container and container:GetCurrentLayerIndex()
    local layers = C_Map.GetMapArtLayers(mapID)
    local layer = layers and layers[layerIndex or 1]
    local tileWidth = layer and layer.tileWidth
    local tileHeight = layer and layer.tileHeight
    if not tileWidth or not tileHeight or tileWidth <= 0 or tileHeight <= 0 then return end

    local explored = {}
    local exploredTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID)
    if exploredTextures then
        for _, info in ipairs(exploredTextures) do
            explored[Whole(info.textureWidth) .. ":" .. Whole(info.textureHeight) .. ":" ..
                Whole(info.offsetX) .. ":" .. Whole(info.offsetY)] = true
        end
    end

    local state = StateFor(pin)
    for key, fileList in pairs(overlays) do
        if not explored[key] then
            local width, height, left, top = key:match("^(%d+):(%d+):(%-?%d+):(%-?%d+)$")
            width, height, left, top = tonumber(width), tonumber(height), tonumber(left), tonumber(top)
            if width and height and left and top then
                local columns = math.ceil(width / tileWidth)
                local rows = math.ceil(height / tileHeight)
                local fileIDs = {}
                for id in fileList:gmatch("%d+") do
                    fileIDs[#fileIDs + 1] = tonumber(id)
                end
                if #fileIDs == columns * rows then
                    for row = 1, rows do
                        local pixelHeight = math.min(tileHeight, height - (row - 1) * tileHeight)
                        local fileHeight = TextureFileSize(pixelHeight)
                        for column = 1, columns do
                            local pixelWidth = math.min(tileWidth, width - (column - 1) * tileWidth)
                            local fileWidth = TextureFileSize(pixelWidth)
                            local texture = AcquireTexture(pin, state)
                            texture:SetSize(pixelWidth, pixelHeight)
                            texture:SetTexCoord(0, pixelWidth / fileWidth, 0, pixelHeight / fileHeight)
                            texture:SetPoint("TOPLEFT", pin, "TOPLEFT",
                                left + (column - 1) * tileWidth,
                                -top - (row - 1) * tileHeight)
                            texture:SetTexture(fileIDs[(row - 1) * columns + column], nil, nil, "TRILINEAR")
                            texture:Show()
                        end
                    end
                end
            end
        end
    end
end

local function UpdateFogPin(pin)
    if InCombatLockdown and InCombatLockdown() then
        DeferUntilCombatEnds(pin:GetMap())
        return
    end
    pin:SetShown(not RevealEnabled())
end

local function EnsureHooks(map)
    for pin in map:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        if not hookedPins[pin] and type(pin.RemoveAllData) == "function" and
            type(pin.RefreshOverlays) == "function" then
            hookedPins[pin] = true
            hooksecurefunc(pin, "RemoveAllData", HideTextures)
            hooksecurefunc(pin, "RefreshOverlays", DrawMissingAreas)
        end
    end
    for pin in map:EnumeratePinsByTemplate("FogOfWarPinTemplate") do
        if not hookedFogPins[pin] and type(pin.OnMapChanged) == "function" then
            hookedFogPins[pin] = true
            hooksecurefunc(pin, "OnMapChanged", UpdateFogPin)
        end
    end
end

function ns.SetupFog(map)
    if not map or not map.EnumeratePinsByTemplate then return end
    if InCombatLockdown and InCombatLockdown() then
        DeferUntilCombatEnds(map)
        return
    end
    EnsureHooks(map)
end

function ns.RefreshFog(map)
    if not map or not map.EnumeratePinsByTemplate then return end
    if InCombatLockdown and InCombatLockdown() then
        DeferUntilCombatEnds(map)
        return
    end
    EnsureHooks(map)
    for pin in map:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        DrawMissingAreas(pin)
    end
    for pin in map:EnumeratePinsByTemplate("FogOfWarPinTemplate") do
        UpdateFogPin(pin)
    end
end
