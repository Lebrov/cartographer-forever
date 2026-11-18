local _, ns = ...

local isRussian = GetLocale() == "ruRU"
local L = isRussian and {
    dungeon = "Подземелье",
    raid = "Рейд",
    battleground = "Поле боя",
    ship = "Корабль",
    airship = "Воздушный корабль",
    zeppelin = "Дирижабль",
    tram = "Метро",
    flight = "Точка полётов",
    spirit = "Целитель душ",
    to = "Пункт назначения",
    open = "Щёлкните, чтобы открыть карту",
    planned = "Откроется 9 декабря 2026 года",
    dropdown = "Карты подземелий",
    page = "Страница",
    unavailable = "Для этого подземелья карта пока недоступна в клиенте.",
    unavailableRaid = "Для этого рейда карта пока недоступна в клиенте.",
    loading = "Загрузка карты...",
    floor = "Этаж",
    close = "Закрыть",
    noPosition = "Точное положение входа ещё не подтверждено",
    approach = "Путь ко входу; портал может находиться дальше",
} or {
    dungeon = "Dungeon",
    raid = "Raid",
    battleground = "Battleground",
    ship = "Ship",
    airship = "Airship",
    zeppelin = "Zeppelin",
    tram = "Tram",
    flight = "Flight point",
    spirit = "Spirit healer",
    to = "Destination",
    open = "Click to open the map",
    planned = "Opens December 9, 2026",
    dropdown = "Dungeon maps",
    page = "Page",
    unavailable = "A map for this dungeon is not yet available in the client.",
    unavailableRaid = "A map for this raid is not yet available in the client.",
    loading = "Loading map...",
    floor = "Floor",
    close = "Close",
    noPosition = "The entrance position is not yet confirmed",
    approach = "Approach to the entrance; the portal may be farther inside",
}

local ART_WIDTH, ART_HEIGHT, TILE_SIZE = 1002, 668, 256
local ART_SCALE = 0.9461077844 -- 948 / 1002; fits below the window header.
local DROPDOWN_PAGE_SIZE = 10

local function Settings()
    return ns.db and ns.db.settings
end

local function FeatureEnabled(key)
    local settings = Settings()
    return settings and settings[key] == true
end

local function ReturnToOrigin(map, viewer)
    local origin = (viewer and viewer.originMapID) or map.travelOriginMapID
    if viewer then viewer:Hide() end
    if origin and map:GetMapID() ~= origin then
        if InCombatLockdown and InCombatLockdown() then
            map.travelOriginMapID = origin
            map.travelReturnPending = true
            return
        end
        local ok = pcall(map.SetMapID, map, origin)
        if not ok or map:GetMapID() ~= origin then
            map.travelOriginMapID = origin
            map.travelReturnPending = true
            return
        end
    end
    map.travelOriginMapID, map.travelNativeMapID = nil, nil
    map.travelReturnPending = nil
end

local function IsPlanned(entry)
    return entry and entry.future and tonumber(date("%Y%m%d")) < 20261209
end

local function HasMapArt(mapID)
    if type(mapID) ~= "number" or not C_Map or not C_Map.GetMapArtLayers then return false end
    local ok, layers = pcall(C_Map.GetMapArtLayers, mapID)
    return ok and type(layers) == "table" and layers[1] ~= nil
end

local function XY(position)
    if not position then return nil end
    if position.GetXY then
        local ok, x, y = pcall(position.GetXY, position)
        if ok then return x, y end
    end
    return position.x, position.y
end

local function ValidPosition(x, y)
    return type(x) == "number" and type(y) == "number"
        and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

local function IsAncestor(ancestor, child)
    if ancestor == child then return true end
    if not C_Map or not C_Map.GetMapInfo then return false end
    local visited = {}
    for _ = 1, 12 do
        if not child or visited[child] then break end
        visited[child] = true
        local info = C_Map.GetMapInfo(child)
        child = info and info.parentMapID
        if child == ancestor then return true end
    end
    return false
end

local function ProjectPosition(entry, mapID)
    local zone = entry.zone
    if not zone or not IsAncestor(mapID, zone) then return nil end
    if zone == mapID then return entry.x / 100, entry.y / 100 end
    if not C_Map or not C_Map.GetWorldPosFromMapPos or not C_Map.GetMapPosFromWorldPos
        or not CreateVector2D then return nil end
    local ok, instanceID, world = pcall(C_Map.GetWorldPosFromMapPos,
        zone, CreateVector2D(entry.x / 100, entry.y / 100))
    if not ok or not instanceID or not world then return nil end
    local success, _, position = pcall(C_Map.GetMapPosFromWorldPos, instanceID, world, mapID)
    if not success then return nil end
    local x, y = XY(position)
    if ValidPosition(x, y) then return x, y end
    return nil
end

local function EntranceInfo(entry)
    local journalID = entry.journalID
    if not journalID or not EJ_GetInstanceInfo then return nil end
    local result = { pcall(EJ_GetInstanceInfo, journalID) }
    if not result[1] then return nil end
    -- pcall's success flag shifts EJ returns by one: 7 -> 8, 10 -> 11,
    -- and 12 -> 13.
    return result[8], result[11], result[13]
end

local function GetDynamicEntrances(mapID)
    if not C_EncounterJournal or not C_EncounterJournal.GetDungeonEntrancesForMap then return {} end
    local ok, entrances = pcall(C_EncounterJournal.GetDungeonEntrancesForMap, mapID)
    if not ok or type(entrances) ~= "table" then return {} end
    local result = {}
    for _, item in ipairs(entrances) do
        local x, y = XY(item.position)
        if ValidPosition(x, y) then
            local entry = {
                zone = mapID, x = x * 100, y = y * 100,
                name = item.name, journalID = item.journalInstanceID,
                atlasName = item.atlasName, kind = "dungeon", native = true,
            }
            local uiMapID, instanceID, isRaid = EntranceInfo(entry)
            if HasMapArt(uiMapID) then entry.uiMapID = uiMapID end
            if type(instanceID) == "number" and instanceID > 0 then entry.instance = instanceID end
            if isRaid then entry.kind = "raid" end
            result[#result + 1] = entry
        end
    end
    return result
end

local function IsNear(a, b)
    return a.zone == b.zone and math.abs(a.x - b.x) < 3 and math.abs(a.y - b.y) < 3
end

local function SameName(a, b)
    return type(a) == "string" and type(b) == "string"
        and string.lower(a) == string.lower(b)
end

local function IsStaticWingEntrance(entry)
    if not entry or entry.kind ~= "dungeon" then return false end
    if entry.instance == 189 or entry.instance == 429 or entry.instance == 329 then return true end
    local name = entry.name
    return type(name) == "string"
        and (string.find(string.lower(name), "scarlet monastery", 1, true) == 1
            or string.find(string.lower(name), "dire maul", 1, true) == 1
            or string.find(string.lower(name), "stratholme", 1, true) == 1
            or string.find(name, "Монастырь Алого ордена", 1, true) == 1
            or string.find(name, "Забытый город", 1, true) == 1
            or string.find(name, "Стратхольм", 1, true) == 1)
end

local function CollectMarkers(mapID)
    local markers = {}
    if FeatureEnabled("showEntrances") then
        local dynamic = GetDynamicEntrances(mapID)
        -- Shared game IDs cannot distinguish individual monastery, Dire
        -- Maul, and Stratholme entrances. Their static pins are authoritative.
        for index = #dynamic, 1, -1 do
            if IsStaticWingEntrance(dynamic[index]) then
                table.remove(dynamic, index)
            end
        end
        local staticInstanceCount, dynamicInstanceCount = {}, {}
        for _, entry in ipairs(ns.TravelData.entrances) do
            if entry.zone == mapID and entry.instance then
                staticInstanceCount[entry.instance] = (staticInstanceCount[entry.instance] or 0) + 1
            end
        end
        for _, entry in ipairs(dynamic) do
            if entry.instance then
                dynamicInstanceCount[entry.instance] = (dynamicInstanceCount[entry.instance] or 0) + 1
            end
        end
        for _, entry in ipairs(dynamic) do markers[#markers + 1] = entry end
        for _, entry in ipairs(ns.TravelData.entrances) do
            local duplicate = false
            if entry.zone == mapID and not (entry.instance == 189 and entry.artKey) then
                for _, other in ipairs(dynamic) do
                    local uniqueInstance = entry.instance and other.instance == entry.instance
                        and staticInstanceCount[entry.instance] == 1
                        and dynamicInstanceCount[entry.instance] == 1
                    if (IsNear(entry, other) or uniqueInstance)
                        and (entry.kind == other.kind or uniqueInstance) and
                        (not other.instance or not entry.instance or other.instance == entry.instance) then
                        -- Prefer Blizzard's live position and UiMapID, but
                        -- retain our game instance ID for custom map art when
                        -- the Encounter Journal omits it.
                        other.instance = other.instance or entry.instance
                        other.artKey = other.artKey or entry.artKey
                        other.floorIndex = other.floorIndex or entry.floorIndex
                        other.entranceZone = entry.zone
                        other.name = entry.instance == 229 and entry.name or (other.name or entry.name)
                        other.ru = other.ru or entry.ru
                        other.kind = entry.kind or other.kind
                        other.future = entry.future or other.future
                        other.approach = entry.approach or other.approach
                        duplicate = true
                        break
                    end
                end
            end
            if not duplicate then markers[#markers + 1] = entry end
        end
    end
    if FeatureEnabled("showTransport") then
        for _, entry in ipairs(ns.TravelData.transport) do
            markers[#markers + 1] = entry
        end
    end
    if ns.POIData then
        local showFlights = FeatureEnabled("showFlightPoints")
        local showSpirits = FeatureEnabled("showSpiritHealers")
        -- On continent/world maps, query each child zone instead. Its local
        -- coordinates can then be matched to the curated faction data before
        -- projection; the parent-map API has no faction field of its own.
        local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
        local mapType = mapInfo and mapInfo.mapType
        local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
        local microType = Enum and Enum.UIMapType and Enum.UIMapType.Micro or 5
        local isLocalMap = mapType == zoneType or mapType == microType
        local directSpirits = showSpirits and isLocalMap and ns.GetSpiritHealersForMap
            and ns.GetSpiritHealersForMap(mapID)
        if directSpirits then
            for _, point in ipairs(directSpirits) do
                markers[#markers + 1] = point
            end
        end
        if showFlights or showSpirits then
            for zone, points in pairs(ns.POIData) do
                if IsAncestor(mapID, zone) then
                    local liveSpirits = showSpirits and not directSpirits and ns.GetSpiritHealersForMap
                        and ns.GetSpiritHealersForMap(zone)
                    for _, point in ipairs(points) do
                        if (point.kind == "flight" and showFlights)
                            or (point.kind == "spirit" and showSpirits
                                and not directSpirits and not liveSpirits) then
                            point.zone = zone
                            markers[#markers + 1] = point
                        end
                    end
                    if liveSpirits then
                        for _, point in ipairs(liveSpirits) do
                            markers[#markers + 1] = point
                        end
                    end
                end
            end
        end
    end
    return markers
end

local function Tip(button)
    local entry = button.entry
    if not entry then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local name = entry.kind == "spirit" and L.spirit or ((isRussian and entry.ru) or entry.name)
    GameTooltip:SetText(name or "?", 1, 0.85, 0.2)
    GameTooltip:AddLine(L[entry.kind] or entry.kind or "", 0.8, 0.85, 0.95)
    if entry.to then GameTooltip:AddLine(L.to .. ": " .. entry.to, 1, 1, 1) end
    if entry.zone and entry.x and entry.y then
        GameTooltip:AddLine(string.format("%.1f, %.1f", entry.x, entry.y), 0.7, 0.7, 0.7)
    elseif entry.kind == "raid" then
        GameTooltip:AddLine(L.noPosition, 0.8, 0.8, 0.8)
    end
    if entry.note then GameTooltip:AddLine(entry.note, 0.8, 0.85, 0.95, true) end
    if entry.approach then GameTooltip:AddLine(L.approach, 1, 0.75, 0.35, true) end
    if IsPlanned(entry) then GameTooltip:AddLine(L.planned, 1, 0.65, 0.35) end
    if entry.kind == "dungeon" or entry.kind == "raid" then
        if FeatureEnabled("showInstanceMaps") then
            GameTooltip:AddLine(L.open, 0.4, 1, 0.6)
        end
    end
    GameTooltip:Show()
end

local COLORS = {
    dungeon = { 0.20, 0.60, 1.0 },
    raid = { 0.95, 0.28, 0.32 },
    battleground = { 0.98, 0.20, 0.20 },
    ship = { 0.25, 0.75, 0.95 },
    airship = { 0.45, 0.9, 0.85 },
    zeppelin = { 0.95, 0.7, 0.25 },
    tram = { 0.8, 0.8, 0.8 },
    flight = { 0.95, 0.8, 0.35 },
    spirit = { 1.0, 0.82, 0.22 },
}
local FACTION_COLORS = {
    alliance = { 0.25, 0.65, 1.0 },
    horde = { 1.0, 0.22, 0.22 },
    neutral = { 1.0, 0.82, 0.22 },
}
local TRANSPORT_ATLASES = {
    alliance = "TaxiNode_Continent_Alliance",
    horde = "TaxiNode_Continent_Horde",
    neutral = "TaxiNode_Continent_Neutral",
}
local FLIGHT_ATLASES = {
    alliance = "TaxiNode_Alliance",
    horde = "TaxiNode_Horde",
    neutral = "TaxiNode_Neutral",
}
local BATTLEGROUND_ATLASES = {
    alliance = "MagePortalAlliance",
    horde = "MagePortalHorde",
}
local GLYPHS = {
    dungeon = "D", raid = "R", battleground = "B",
    ship = "S", airship = "A", zeppelin = "Z", tram = "T",
    flight = "F", spirit = "G",
}

-- The globe symbols are bundled so transport pins still work independently.
local GLOBE_TEXTURE = "Interface\\AddOns\\Cartographer_Forever\\Media\\TransportIcons.blp"
local GLOBE_COORDS = {
    alliance = { 0, 0.125, 0.375, 0.5 },
    horde = { 0.125, 0.25, 0.375, 0.5 },
    neutral = { 0.25, 0.375, 0.375, 0.5 },
}

local function SetFileIcon(texture, path, coords)
    texture:SetTexture(nil)
    local ok = pcall(texture.SetTexture, texture, path)
    if not ok then return false end
    -- The client can accept a nonexistent path without an error. A resolved
    -- file ID prevents it from drawing a solid missing-texture square.
    if texture.GetTextureFileID then
        local gotID, fileID = pcall(texture.GetTextureFileID, texture)
        -- Addon-local images may receive negative temporary file IDs.
        if not gotID or type(fileID) ~= "number" or fileID == 0 then return false end
    end
    if coords then
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        texture:SetTexCoord(0, 1, 0, 1)
    end
    return true
end

local function SetAtlasIcon(texture, atlas)
    if not atlas then return false end
    local getInfo = (C_Texture and C_Texture.GetAtlasInfo) or GetAtlasInfo
    if not getInfo then return false end
    local ok, info = pcall(getInfo, atlas)
    if not ok or not info then return false end
    texture:SetTexture(nil)
    if not pcall(texture.SetAtlas, texture, atlas) then return false end
    -- A recycled pin may have used a cropped globe. Match Blizzard's map
    -- pins by restoring the full atlas UVs after SetAtlas.
    texture:SetTexCoord(0, 1, 0, 1)
    return true
end

local function TravelPinFrameLevel(map)
    local canvas = map:GetCanvas()
    local level = canvas:GetFrameLevel() + 34
    -- Revealed terrain is painted inside MapExplorationPinTemplate. Its
    -- MapCanvas frame level may be higher than our old fixed canvas offset.
    if map.EnumeratePinsByTemplate then
        for exploration in map:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
            level = math.max(level, exploration:GetFrameLevel() + 2)
        end
        for fog in map:EnumeratePinsByTemplate("FogOfWarPinTemplate") do
            level = math.max(level, fog:GetFrameLevel() + 2)
        end
    end
    return level
end

local function TravelModalShown(map)
    return (map.TravelViewer and map.TravelViewer:IsShown())
        or (map.TravelDropdown and map.TravelDropdown:IsShown())
end

local function UpdatePinInputAndAlpha(map)
    if not map.travelPins then return end
    local modal = TravelModalShown(map)
    for _, pin in ipairs(map.travelPins) do
        pin:SetAlpha(modal and 0 or 1)
        pin:EnableMouse(not modal)
    end
end

local function CreatePin(map)
    local canvas = map:GetCanvas()
    local pin = CreateFrame("Button", nil, canvas)
    pin:SetSize(19, 19)
    pin:SetFrameLevel(TravelPinFrameLevel(map))
    pin:RegisterForClicks("LeftButtonUp")
    local border = pin:CreateTexture(nil, "ARTWORK")
    border:SetAllPoints()
    border:SetColorTexture(0.03, 0.04, 0.06, 0.95)
    local fill = pin:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", pin, "TOPLEFT", 2, -2)
    fill:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", -2, 2)
    local label = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetAllPoints()
    label:SetTextColor(0, 0, 0)
    local icon = pin:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:Hide()
    pin.border, pin.fill, pin.label, pin.icon = border, fill, label, icon
    pin:SetScript("OnEnter", Tip)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:SetScript("OnClick", function(self)
        if self.entry and (self.entry.kind == "dungeon" or self.entry.kind == "raid") then
            ns.OpenInstanceMap(map, self.entry)
        end
    end)
    return pin
end

local function LayoutPin(map, pin)
    local canvas = map:GetCanvas()
    if not canvas or not pin.mapX or not pin.mapY then return end
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    if width <= 0 or height <= 0 then return end
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", canvas, "TOPLEFT",
        width * pin.mapX + (pin.pinOffsetX or 0),
        -height * pin.mapY + (pin.pinOffsetY or 0))
end

local function SetPin(map, pin, entry, x, y)
    pin.entry, pin.mapX, pin.mapY = entry, x, y
    pin.pinOffsetX, pin.pinOffsetY = entry.pinOffsetX, entry.pinOffsetY
    pin:SetFrameLevel(TravelPinFrameLevel(map))
    local kind = entry.kind
    local color = FACTION_COLORS[entry.faction or (kind == "spirit" and "neutral")]
        or COLORS[kind] or COLORS.dungeon
    local isTransport = kind == "ship" or kind == "airship" or kind == "zeppelin" or kind == "tram"
    local hasIcon = false
    local factionPortalIcon = false
    if isTransport then
        hasIcon = SetFileIcon(pin.icon, GLOBE_TEXTURE, GLOBE_COORDS[entry.faction or "neutral"])
    end
    if not hasIcon then
        local atlas
        if kind == "dungeon" then atlas = entry.atlasName or "Dungeon"
        elseif kind == "raid" then atlas = entry.atlasName or "Raid"
        elseif kind == "battleground" then atlas = BATTLEGROUND_ATLASES[entry.faction] or "Dungeon"
        elseif isTransport then atlas = TRANSPORT_ATLASES[entry.faction or "neutral"]
        elseif kind == "flight" then atlas = FLIGHT_ATLASES[entry.faction or "neutral"]
        elseif kind == "spirit" then atlas = "poi-graveyard-neutral"
        end
        hasIcon = SetAtlasIcon(pin.icon, atlas)
        factionPortalIcon = kind == "battleground" and hasIcon
            and BATTLEGROUND_ATLASES[entry.faction] == atlas
        if kind == "flight" and not hasIcon then
            hasIcon = SetAtlasIcon(pin.icon, "FlightPath")
            if not hasIcon then hasIcon = SetAtlasIcon(pin.icon, "FlightMaster") end
            if not hasIcon then
                hasIcon = SetFileIcon(pin.icon, "Interface\\Minimap\\Tracking\\FlightMaster")
            end
        elseif kind == "spirit" and not hasIcon then
            hasIcon = SetAtlasIcon(pin.icon, "Navigation-Tombstone-Icon")
            if not hasIcon then
                hasIcon = SetFileIcon(pin.icon, "Interface\\WorldMap\\GravePicker-Unselected")
            end
        end
    end
    if hasIcon then
        pin.icon:ClearAllPoints()
        if kind == "spirit" then
            -- Preserve the comfortable hover target while halving the visible
            -- 18x24 tombstone to 9x12.
            pin:SetSize(18, 24)
            pin.icon:SetSize(9, 12)
            pin.icon:SetPoint("CENTER", pin, "CENTER")
        else
            pin:SetSize(24, 24)
            pin.icon:SetSize(24, 24)
            pin.icon:SetAllPoints()
        end
        -- Forever's Horde taxi atlas can appear bronze; tinting the native
        -- boot silhouette keeps all three requested faction colors distinct.
        local coloredPin = (kind == "battleground" and not factionPortalIcon)
            or kind == "spirit"
            or kind == "flight"
            or (entry.faction ~= nil and not isTransport
                and kind ~= "flight" and kind ~= "battleground")
        pin.icon:SetDesaturated(coloredPin)
        if coloredPin then
            pin.icon:SetVertexColor(color[1], color[2], color[3])
        else
            pin.icon:SetVertexColor(1, 1, 1)
        end
        pin.icon:SetAlpha(IsPlanned(entry) and 0.55 or 1)
        pin.icon:Show()
        pin.border:Hide()
        pin.fill:Hide()
        pin.label:Hide()
    else
        pin.border:ClearAllPoints()
        pin.fill:ClearAllPoints()
        pin.label:ClearAllPoints()
        if kind == "spirit" then
            -- The font fallback uses the same half-size footprint as the
            -- tombstone atlas if this client has neither graveyard texture.
            pin:SetSize(18, 24)
            pin.border:SetSize(9, 12)
            pin.border:SetPoint("CENTER", pin, "CENTER")
            pin.fill:SetSize(7, 10)
            pin.fill:SetPoint("CENTER", pin, "CENTER")
            pin.label:SetSize(9, 12)
            pin.label:SetPoint("CENTER", pin, "CENTER")
        else
            pin:SetSize(19, 19)
            pin.border:SetSize(19, 19)
            pin.border:SetAllPoints()
            pin.fill:SetSize(15, 15)
            pin.fill:SetPoint("TOPLEFT", pin, "TOPLEFT", 2, -2)
            pin.fill:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", -2, 2)
            pin.label:SetSize(19, 19)
            pin.label:SetAllPoints()
        end
        pin.icon:Hide()
        pin.border:Show()
        pin.fill:Show()
        pin.label:Show()
    end
    pin.fill:SetColorTexture(color[1], color[2], color[3], IsPlanned(entry) and 0.55 or 0.95)
    pin.label:SetText(GLYPHS[entry.kind] or "?")
    LayoutPin(map, pin)
    local modal = TravelModalShown(map)
    pin:SetAlpha(modal and 0 or 1)
    pin:EnableMouse(not modal)
    pin:Show()
end

local function StyleButton(button, text)
    button:SetSize(29, 24)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.15, 0.18, 0.23, 0.98)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetAllPoints()
    label:SetText(text)
    button.Label = label
    return button
end

local function CreateViewer(map)
    local viewer = CreateFrame("Frame", nil, map.ScrollContainer)
    viewer:SetAllPoints(map.ScrollContainer)
    viewer:SetFrameLevel(math.max(map.ScrollContainer:GetFrameLevel() + 45,
        TravelPinFrameLevel(map) + 2))
    viewer:EnableMouse(true)
    local background = viewer:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.035, 0.045, 0.065, 0.99)
    local title = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", viewer, "TOPLEFT", 13, -8)
    title:SetWidth(630)
    title:SetJustifyH("LEFT")
    local floor = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    floor:SetPoint("TOPRIGHT", viewer, "TOPRIGHT", -108, -10)
    viewer.title, viewer.floorText = title, floor

    local close = StyleButton(CreateFrame("Button", nil, viewer), "X")
    close:SetPoint("TOPRIGHT", viewer, "TOPRIGHT", -8, -4)
    close:SetScript("OnClick", function() ReturnToOrigin(map, viewer) end)
    local nextFloor = StyleButton(CreateFrame("Button", nil, viewer), ">")
    nextFloor:SetPoint("RIGHT", close, "LEFT", -4, 0)
    local previous = StyleButton(CreateFrame("Button", nil, viewer), "<")
    previous:SetPoint("RIGHT", nextFloor, "LEFT", -4, 0)
    viewer.previous, viewer.nextFloor = previous, nextFloor
    for _, button in ipairs({ close, nextFloor, previous }) do
        button:SetScript("OnMouseUp", function(_, mouseButton)
            if mouseButton == "RightButton" then ReturnToOrigin(map, viewer) end
        end)
    end

    local art = CreateFrame("Frame", nil, viewer)
    art:SetSize(ART_WIDTH * ART_SCALE, ART_HEIGHT * ART_SCALE)
    art:SetPoint("TOP", viewer, "TOP", 0, -31)
    viewer.art = art
    local fullImage = art:CreateTexture(nil, "ARTWORK")
    fullImage:SetAllPoints(art)
    fullImage:Hide()
    viewer.fullImage = fullImage
    viewer.tiles = {}
    for index = 1, 12 do
        local texture = art:CreateTexture(nil, "ARTWORK")
        local col = (index - 1) % 4
        local row = math.floor((index - 1) / 4)
        local width = math.min(TILE_SIZE, ART_WIDTH - col * TILE_SIZE)
        local height = math.min(TILE_SIZE, ART_HEIGHT - row * TILE_SIZE)
        texture:SetPoint("TOPLEFT", art, "TOPLEFT", col * TILE_SIZE * ART_SCALE, -row * TILE_SIZE * ART_SCALE)
        texture:SetSize(width * ART_SCALE, height * ART_SCALE)
        texture:SetTexCoord(0, width / TILE_SIZE, 0, height / TILE_SIZE)
        viewer.tiles[index] = texture
    end
    local message = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    message:SetPoint("CENTER", art, "CENTER")
    message:SetWidth(500)
    viewer.message = message
    viewer:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then ReturnToOrigin(map, self) end
    end)
    viewer:SetScript("OnHide", function(self)
        if ns.ClearInstanceArt then ns.ClearInstanceArt(self) end
        UpdatePinInputAndAlpha(map)
    end)
    viewer:SetScript("OnShow", function(self)
        self:SetFrameLevel(math.max(map.ScrollContainer:GetFrameLevel() + 45,
            TravelPinFrameLevel(map) + 2))
        UpdatePinInputAndAlpha(map)
    end)
    viewer:Hide()
    map.TravelViewer = viewer
    return viewer
end

local function SetTile(texture, floor, index)
    texture:SetTexture(nil)
    local path = floor.path and (floor.path .. tostring(index))
    if path then pcall(texture.SetTexture, texture, path) end
    local ok, id
    if texture.GetTextureFileID then
        ok, id = pcall(texture.GetTextureFileID, texture)
    end
    if not ok then id = nil end
    if (type(id) ~= "number" or id <= 0) and floor.tiles and floor.tiles[index] then
        pcall(texture.SetTexture, texture, floor.tiles[index])
        if texture.GetTextureFileID then
            ok, id = pcall(texture.GetTextureFileID, texture)
        end
        if not ok then id = nil end
    end
    local loaded = type(id) == "number" and id > 0
    texture:SetShown(loaded)
    return loaded
end

local function ShowFloor(viewer, floorIndex, retried)
    local floors = viewer.floors
    if not floors or not floors[floorIndex] then return false end
    viewer.floorIndex = floorIndex
    local floor = floors[floorIndex]
    local loaded = 0
    if ns.ClearInstanceArt then ns.ClearInstanceArt(viewer) end
    if floor.render == "terrain" then
        for _, texture in ipairs(viewer.tiles) do texture:Hide() end
        viewer.fullImage:Hide()
        if ns.RenderInstanceArt and ns.RenderInstanceArt(viewer,
            floor.instanceID or viewer.entry.instance, floor) then
            loaded = 12
        end
    elseif floor.image then
        for _, texture in ipairs(viewer.tiles) do texture:Hide() end
        viewer.fullImage:SetTexCoord(0, floor.texRight or 1, 0, floor.texBottom or 1)
        local ok = pcall(viewer.fullImage.SetTexture, viewer.fullImage, floor.image)
        local texture = ok and viewer.fullImage:GetTexture()
        viewer.fullImage:SetShown(texture ~= nil)
        if texture then loaded = 12 end
    else
        viewer.fullImage:Hide()
        for index, texture in ipairs(viewer.tiles) do
            if SetTile(texture, floor, index) then loaded = loaded + 1 end
        end
    end
    viewer.floorText:SetText(floor.name or (L.floor .. " " .. tostring(floor.floor)))
    viewer.previous:SetEnabled(floorIndex > 1)
    viewer.nextFloor:SetEnabled(floorIndex < #floors)
    viewer.message:SetShown(loaded ~= 12)
    if loaded ~= 12 then
        viewer.message:SetText(retried and (viewer.entry.kind == "raid" and L.unavailableRaid or L.unavailable)
            or L.loading)
        if not retried and C_Timer and C_Timer.After then
            C_Timer.After(0.3, function()
                if viewer:IsShown() and viewer.floorIndex == floorIndex then
                    ShowFloor(viewer, floorIndex, true)
                end
            end)
        end
    end
    return loaded == 12
end

local function OpenStaticArt(map, entry)
    local floors = ns.TravelArt and ns.TravelArt[entry.artKey or entry.artInstance or entry.instance]
    if not floors or not floors[1] then return false end
    local viewer = map.TravelViewer or CreateViewer(map)
    viewer.entry = entry
    viewer.floors = floors
    viewer.originMapID = map.travelOriginMapID or map:GetMapID()
    viewer.displayMapID = map:GetMapID()
    viewer.title:SetText(entry.name .. (IsPlanned(entry) and (" |cffffaa55(" .. L.planned .. ")|r") or ""))
    viewer.previous:SetScript("OnClick", function()
        ShowFloor(viewer, (viewer.floorIndex or 1) - 1)
    end)
    viewer.nextFloor:SetScript("OnClick", function()
        ShowFloor(viewer, (viewer.floorIndex or 1) + 1)
    end)
    local firstFloor = math.max(1, math.min(#floors, entry.floorIndex or 1))
    local loaded = ShowFloor(viewer, firstFloor)
    if loaded or not floors[firstFloor].image then
        viewer:Show()
        return true
    end
    viewer:Hide()
    return false
end

local function ShowUnavailable(map, entry)
    local viewer = map.TravelViewer or CreateViewer(map)
    viewer.entry = entry
    viewer.floors = nil
    viewer.originMapID = map.travelOriginMapID or map:GetMapID()
    viewer.displayMapID = map:GetMapID()
    viewer.title:SetText(entry.name)
    viewer.floorText:SetText("")
    viewer.previous:Disable()
    viewer.nextFloor:Disable()
    if ns.ClearInstanceArt then ns.ClearInstanceArt(viewer) end
    viewer.fullImage:Hide()
    for _, texture in ipairs(viewer.tiles) do texture:Hide() end
    viewer.message:SetText(entry.kind == "raid" and L.unavailableRaid or L.unavailable)
    viewer.message:Show()
    viewer:Show()
end

local function FindNativeMap(entry)
    if HasMapArt(entry.uiMapID) then return entry.uiMapID end
    local uiMapID = EntranceInfo(entry)
    if HasMapArt(uiMapID) then return uiMapID end

    local entranceZone = entry.entranceZone or entry.zone
    if entranceZone then
        for _, candidate in ipairs(GetDynamicEntrances(entranceZone)) do
            if IsNear(entry, candidate) and HasMapArt(candidate.uiMapID) then
                return candidate.uiMapID
            end
        end
    end
    if not entranceZone or not C_Map or not C_Map.GetMapChildrenInfo then return nil end
    local ok, children = pcall(C_Map.GetMapChildrenInfo, entranceZone, nil, true)
    if not ok or type(children) ~= "table" then return nil end
    local names = {}
    if entry.name then names[#names + 1] = string.lower(entry.name) end
    for _, instance in ipairs(ns.DungeonData and ns.DungeonData[entranceZone] or {}) do
        if instance.name and entry.name and
            (instance.name == entry.name or string.find(instance.name, entry.name, 1, true))
            and instance.ru and instance.ru ~= instance.name then
            names[#names + 1] = string.lower(instance.ru)
        end
    end
    for _, child in ipairs(children) do
        local name = child.name and string.lower(child.name)
        if name and HasMapArt(child.mapID) then
            for _, target in ipairs(names) do
                if name == target or string.find(target, name, 1, true)
                    or string.find(name, target, 1, true) then
                    return child.mapID
                end
            end
        end
    end
    return nil
end

function ns.OpenInstanceMap(map, entry)
    if not map or not FeatureEnabled("showInstanceMaps") then return false end
    if type(entry) ~= "table" or (entry.kind ~= "dungeon" and entry.kind ~= "raid") then return false end
    if map.TravelDropdown then map.TravelDropdown:Hide() end
    if map.TravelViewer then map.TravelViewer:Hide() end
    local floors = ns.TravelArt and ns.TravelArt[entry.artKey or entry.artInstance or entry.instance]
    if floors and floors[1] and (floors[1].image or entry.artKey)
        and OpenStaticArt(map, entry) then
        return true
    end
    local nativeMapID = FindNativeMap(entry)
    if nativeMapID and not (InCombatLockdown and InCombatLockdown()) then
        local originMapID = map.travelOriginMapID or map:GetMapID()
        local previousOriginID = map.travelOriginMapID
        local previousNativeID = map.travelNativeMapID
        map.travelOriginMapID = originMapID
        map.travelNativeMapID = nativeMapID
        local ok = pcall(map.SetMapID, map, nativeMapID)
        if ok and map:GetMapID() == nativeMapID then return true end
        map.travelOriginMapID, map.travelNativeMapID = previousOriginID, previousNativeID
    end
    if OpenStaticArt(map, entry) then return true end
    ShowUnavailable(map, entry)
    return false
end

-- Several wings share one game instance ID. The client's dungeon UiMapID
-- identifies the actual wing and floor while the player is inside it.
local wingByUiMapID = {
    [235] = { "DireMaulNorth", "Dire Maul North", 1, 429 },
    [236] = { "DireMaulWest", "Dire Maul West", 1, 429 },
    [237] = { "DireMaulWest", "Dire Maul West", 2, 429 },
    [238] = { "DireMaulWest", "Dire Maul West", 3, 429 },
    [239] = { "DireMaulEast", "Dire Maul East", 2, 429 },
    [240] = { "DireMaulEast", "Dire Maul East", 1, 429 },
    [302] = { "SMGraveyard", "Scarlet Monastery: Graveyard", 1, 189 },
    [303] = { "SMLibrary", "Scarlet Monastery: Library", 1, 189 },
    [304] = { "SMArmory", "Scarlet Monastery: Armory", 1, 189 },
    [305] = { "SMCathedral", "Scarlet Monastery: Cathedral", 1, 189 },
    [317] = { 329, "Stratholme (Main Gate)", 1, 329 },
    [318] = { 329, "Stratholme (Service Gate)", 2, 329 },
}

-- Called when this map window opens. Instance IDs come from the player's
-- actual current instance, rather than from the previously viewed world map.
function ns.ShowPlayerInstanceMap(map)
    if not map or not FeatureEnabled("showInstanceMaps") or not IsInInstance or not GetInstanceInfo then
        return false
    end
    local inside, instanceType = IsInInstance()
    if not inside or (instanceType ~= "party" and instanceType ~= "raid") then return false end
    -- GetInstanceInfo return #8 is the game instance ID (not a UiMapID).
    local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    if type(instanceID) ~= "number" or instanceID <= 0 then return false end

    local source
    for _, candidate in ipairs(ns.TravelData.entrances) do
        if candidate.instance == instanceID then
            source = candidate
            if candidate.floorIndex == 1 or not candidate.floorIndex then break end
        end
    end
    local entry = {}
    if source then
        for key, value in pairs(source) do entry[key] = value end
    end
    entry.instance = instanceID
    entry.name = name or entry.name or (instanceType == "raid" and L.raid or L.dungeon)
    entry.kind = instanceType == "raid" and "raid" or "dungeon"

    if C_Map and C_Map.GetBestMapForUnit then
        local ok, playerMapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and type(playerMapID) == "number" then
            local wing = wingByUiMapID[playerMapID]
            if wing and instanceID == wing[4] then
                entry.artKey, entry.name, entry.floorIndex = wing[1], wing[2], wing[3]
            end
            local info = C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)
            local dungeonType = Enum and Enum.UIMapType and Enum.UIMapType.Dungeon or 4
            if info and info.mapType == dungeonType and HasMapArt(playerMapID) then
                entry.uiMapID = playerMapID
            end
            if not entry.zone and info and HasMapArt(info.parentMapID) then
                entry.zone = info.parentMapID
            end
        end
    end

    local originMapID = entry.zone or map.travelOriginMapID or map:GetMapID()
    map.travelOriginMapID = originMapID
    local success = ns.OpenInstanceMap(map, entry)
    if not success and not map.travelNativeMapID then
        -- Keep the zone selected for right-clicking out of an unavailable
        -- static view, then discard the context when that view is closed.
        map.travelOriginMapID = originMapID
    end
    return success
end

local function DungeonEntries()
    local entries, seen = {}, {}
    for _, entry in ipairs(ns.TravelData.entrances) do
        if entry.kind == "dungeon" and entry.name ~= "Scarlet Monastery"
            and entry.name ~= "Maraudon" and entry.name ~= "Blackrock Spire"
            and entry.name ~= "Blackrock Spire (LBRS / UBRS)" then
            local key = entry.name
            if not seen[key] then
                seen[key] = true
                entries[#entries + 1] = entry
            end
        end
    end
    -- Add wing names not already supplied by the static entrance data.
    local wings = {
        { zone = 1420, base = 189, prefix = "Scarlet Monastery:" },
        { zone = 1443, base = 349, prefix = "Maraudon:" },
        { zone = 1428, base = 229, prefix = "Lower Blackrock Spire" },
        { zone = 1428, base = 229, prefix = "Upper Blackrock Spire" },
    }
    for _, wing in ipairs(wings) do
        for _, info in ipairs(ns.DungeonData and ns.DungeonData[wing.zone] or {}) do
            if info.name and string.find(info.name, wing.prefix, 1, true) == 1
                and not seen[info.name] then
                entries[#entries + 1] = {
                    name = info.name, ru = info.ru, kind = "dungeon", zone = wing.zone,
                    instance = wing.base, artKey = wing.base == 229 and wing.base or nil,
                }
                seen[info.name] = true
            end
        end
    end
    table.sort(entries, function(a, b) return a.name < b.name end)
    return entries
end

local function ShowDropdownPage(dropdown, page)
    local maxPage = math.max(1, math.ceil(#dropdown.entries / DROPDOWN_PAGE_SIZE))
    dropdown.page = math.max(1, math.min(maxPage, page))
    for index, row in ipairs(dropdown.rows) do
        local entry = dropdown.entries[(dropdown.page - 1) * DROPDOWN_PAGE_SIZE + index]
        row.entry = entry
        if entry then
            row.Label:SetText((isRussian and entry.ru) or entry.name)
            row:Show()
        else
            row:Hide()
        end
    end
    dropdown.pageText:SetText(L.page .. " " .. dropdown.page .. "/" .. maxPage)
    dropdown.previous:SetEnabled(dropdown.page > 1)
    dropdown.nextPage:SetEnabled(dropdown.page < maxPage)
end

local function CreateDropdown(map)
    local dropdown = CreateFrame("Frame", nil, map)
    dropdown:SetSize(282, 345)
    -- The terrain viewer can add WMO child frames above its own frame level.
    -- A separate strata keeps the menu's opaque background above all of them.
    dropdown:SetFrameStrata("DIALOG")
    local viewerLevel = map.TravelViewer and map.TravelViewer:GetFrameLevel() or 0
    dropdown:SetFrameLevel(math.max(map.Header:GetFrameLevel() + 6,
        TravelPinFrameLevel(map) + 3, viewerLevel + 3))
    dropdown:EnableMouse(true)
    local background = dropdown:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.045, 0.055, 0.075, 0.98)
    local title = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 9, -8)
    title:SetText(L.dropdown)
    local previous = StyleButton(CreateFrame("Button", nil, dropdown), "<")
    previous:SetPoint("BOTTOMLEFT", dropdown, "BOTTOMLEFT", 9, 6)
    local nextPage = StyleButton(CreateFrame("Button", nil, dropdown), ">")
    nextPage:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -7, 6)
    local pageText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pageText:SetPoint("CENTER", dropdown, "BOTTOM", 0, 18)
    pageText:SetWidth(160)
    pageText:SetJustifyH("CENTER")
    dropdown.previous, dropdown.nextPage, dropdown.pageText = previous, nextPage, pageText
    dropdown.rows = {}
    for index = 1, DROPDOWN_PAGE_SIZE do
        local row = CreateFrame("Button", nil, dropdown)
        row:SetSize(264, 27)
        row:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 9, -27 - (index - 1) * 27)
        local fill = row:CreateTexture(nil, "BACKGROUND")
        fill:SetAllPoints()
        fill:SetColorTexture(0.13, 0.16, 0.20, index % 2 == 0 and 0.8 or 0.6)
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", row, "LEFT", 7, 0)
        label:SetWidth(250)
        label:SetJustifyH("LEFT")
        row.Label = label
        row:SetScript("OnClick", function(self)
            if self.entry then ns.OpenInstanceMap(map, self.entry) end
        end)
        row:SetScript("OnEnter", Tip)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        dropdown.rows[index] = row
    end
    dropdown.previous:SetScript("OnClick", function()
        ShowDropdownPage(dropdown, dropdown.page - 1)
    end)
    dropdown.nextPage:SetScript("OnClick", function()
        ShowDropdownPage(dropdown, dropdown.page + 1)
    end)
    dropdown.entries = DungeonEntries()
    dropdown.page = 1
    dropdown:SetScript("OnShow", function(self)
        local currentViewerLevel = map.TravelViewer and map.TravelViewer:GetFrameLevel() or 0
        self:SetFrameLevel(math.max(map.Header:GetFrameLevel() + 6,
            TravelPinFrameLevel(map) + 3, currentViewerLevel + 3))
        UpdatePinInputAndAlpha(map)
    end)
    dropdown:SetScript("OnHide", function()
        UpdatePinInputAndAlpha(map)
    end)
    dropdown:Hide()
    map.TravelDropdown = dropdown
    return dropdown
end

function ns.ToggleInstanceDropdown(map, anchorButton)
    if not map or not anchorButton or not FeatureEnabled("showInstanceMaps") then return false end
    local dropdown = map.TravelDropdown or CreateDropdown(map)
    if dropdown:IsShown() then
        dropdown:Hide()
        return false
    end
    dropdown:ClearAllPoints()
    dropdown:SetPoint("TOPRIGHT", anchorButton, "BOTTOMRIGHT", 0, -3)
    dropdown.originMapID = map:GetMapID()
    dropdown.entries = DungeonEntries()
    ShowDropdownPage(dropdown, dropdown.page or 1)
    dropdown:Show()
    return true
end

function ns.RefreshTravel(map)
    if not map or not map.travelPins then return end
    if not FeatureEnabled("showInstanceMaps") then
        if map.TravelViewer then map.TravelViewer:Hide() end
        if map.TravelDropdown then map.TravelDropdown:Hide() end
    end
    local mapID = map:GetMapID()
    if not mapID then return end
    if map.travelNativeMapID and not IsAncestor(map.travelNativeMapID, mapID) then
        map.travelOriginMapID, map.travelNativeMapID = nil, nil
    end
    if map.TravelViewer and map.TravelViewer:IsShown()
        and map.TravelViewer.displayMapID ~= mapID then
        map.TravelViewer:Hide()
    end
    if map.TravelDropdown and map.TravelDropdown:IsShown()
        and map.TravelDropdown.originMapID ~= mapID then
        map.TravelDropdown:Hide()
    end
    if not map:IsShown() then
        map.travelRefreshPending = true
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        for _, pin in ipairs(map.travelPins) do
            local kind = pin.entry and pin.entry.kind
            if (kind == "dungeon" or kind == "raid" or kind == "battleground")
                and not FeatureEnabled("showEntrances") then
                pin:Hide()
            elseif (kind == "ship" or kind == "airship" or kind == "zeppelin" or kind == "tram")
                and not FeatureEnabled("showTransport") then
                pin:Hide()
            elseif kind == "flight" and not FeatureEnabled("showFlightPoints") then
                pin:Hide()
            elseif kind == "spirit" and not FeatureEnabled("showSpiritHealers") then
                pin:Hide()
            end
        end
        map.travelRefreshPending = true
        return
    end
    map.travelRefreshPending = nil
    local count = 0
    local placed = {}
    local markers = CollectMarkers(mapID)
    local skipped = {}
    -- Continent and world maps report EJ pins in the parent map's coordinate
    -- space. Match them against projected static entrances before placing any
    -- pins, so a live marker still carries the game instance ID for map art.
    for _, dynamic in ipairs(markers) do
        if dynamic.native and (dynamic.kind == "dungeon" or dynamic.kind == "raid") then
            local dx, dy = ProjectPosition(dynamic, mapID)
            local exact, near = {}, {}
            if ValidPosition(dx, dy) then
                for _, static in ipairs(markers) do
                    if not static.native and (static.kind == dynamic.kind
                        or (static.instance == 229 and dynamic.instance == 229)) then
                        local sx, sy = ProjectPosition(static, mapID)
                        if ValidPosition(sx, sy) then
                            if (dynamic.instance and static.instance == dynamic.instance)
                                or SameName(dynamic.name, static.name) then
                                exact[#exact + 1] = static
                            elseif not dynamic.instance then
                                local tolerance = static.zone == mapID and 0.035 or 0.009
                                if math.abs(dx - sx) < tolerance and math.abs(dy - sy) < tolerance then
                                    near[#near + 1] = static
                                end
                            end
                        end
                    end
                end
            end
            local match = #exact == 1 and exact[1] or (#exact == 0 and #near == 1 and near[1])
            if not match and #exact > 1 then
                -- A shared portal can have approaches on two adjacent zone
                -- maps. Match the live pin to the closest projected approach.
                local bestDistance, tied
                for _, candidate in ipairs(exact) do
                    local sx, sy = ProjectPosition(candidate, mapID)
                    if ValidPosition(sx, sy) then
                        local distance = (dx - sx) ^ 2 + (dy - sy) ^ 2
                        if not bestDistance or distance < bestDistance - 0.000001 then
                            match, bestDistance, tied = candidate, distance, false
                        elseif math.abs(distance - bestDistance) <= 0.000001 then
                            tied = true
                        end
                    end
                end
                if tied then match = nil end
            end
            if match then
                dynamic.artInstance = match.instance
                dynamic.artKey = match.artKey
                dynamic.floorIndex = match.floorIndex
                dynamic.instance = dynamic.instance or match.instance
                if match.instance == 229 then dynamic.name = match.name end
                dynamic.ru = dynamic.ru or match.ru
                dynamic.kind = match.kind
                dynamic.entranceZone = match.zone
                dynamic.future = dynamic.future or match.future
                dynamic.approach = dynamic.approach or match.approach
                skipped[match] = true
            elseif not dynamic.instance and (#exact > 1 or #near > 1) then
                -- Ambiguous overlapping portals: keep the known static pins.
                skipped[dynamic] = true
            end
        end
    end
    for _, entry in ipairs(markers) do
        local x, y
        if not skipped[entry] then x, y = ProjectPosition(entry, mapID) end
        if ValidPosition(x, y) then
            local duplicate = false
            if entry.kind == "dungeon" or entry.kind == "raid" then
                for _, other in ipairs(placed) do
                    if other.entry.native ~= entry.native and other.entry.kind == entry.kind
                        and math.abs(other.x - x) < 0.012
                        and math.abs(other.y - y) < 0.012
                        and (not entry.artKey or not other.entry.artKey
                            or entry.artKey == other.entry.artKey)
                        and (not entry.artKey or not other.entry.native
                            or other.entry.artKey == entry.artKey)
                        and (not entry.floorIndex or not other.entry.floorIndex
                            or entry.floorIndex == other.entry.floorIndex)
                        and ((entry.instance and other.entry.instance == entry.instance)
                            or (not entry.instance or not other.entry.instance)) then
                        if other.entry.native then
                            other.entry.instance = other.entry.instance or entry.instance
                            other.entry.artKey = other.entry.artKey or entry.artKey
                            other.entry.floorIndex = other.entry.floorIndex or entry.floorIndex
                            other.entry.ru = other.entry.ru or entry.ru
                            other.entry.entranceZone = entry.zone
                            other.entry.future = other.entry.future or entry.future
                        end
                        duplicate = true
                        break
                    end
                end
            end
            if not duplicate then
                count = count + 1
                local pin = map.travelPins[count]
                if not pin then
                    pin = CreatePin(map)
                    map.travelPins[count] = pin
                end
                SetPin(map, pin, entry, x, y)
                placed[#placed + 1] = { entry = entry, x = x, y = y }
            end
        end
    end
    for index = count + 1, #map.travelPins do
        map.travelPins[index]:Hide()
    end
end

function ns.SetupTravel(map)
    if not map or map.travelPins then return end
    map.travelPins = {}
    hooksecurefunc(map, "OnCanvasSizeChanged", function(self)
        if self.travelPins then
            for _, pin in ipairs(self.travelPins) do
                if pin:IsShown() then
                    pin:SetFrameLevel(TravelPinFrameLevel(self))
                    LayoutPin(self, pin)
                end
            end
        end
    end)
    map:AddCanvasClickHandler(function(self, button)
        if button ~= "RightButton" or not self.travelNativeMapID then return false end
        if not IsAncestor(self.travelNativeMapID, self:GetMapID()) then return false end
        ReturnToOrigin(self)
        return true
    end, 1000)
    map:HookScript("OnHide", function(self)
        if self.TravelDropdown then self.TravelDropdown:Hide() end
        if self.TravelViewer then self.TravelViewer:Hide() end
    end)
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function()
        if map.travelReturnPending then ReturnToOrigin(map) end
        if map.travelRefreshPending then ns.RefreshTravel(map) end
    end)
    map.travelEvents = events
end
