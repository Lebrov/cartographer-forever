local addonName, ns = ...

local isRussian = GetLocale() == "ruRU"
local labels = isRussian and {
    title = "Картограф Forever",
    back = "К предыдущей карте",
    home = "К местоположению игрока",
    smaller = "Уменьшить окно (Ctrl + колесо мыши)",
    larger = "Увеличить окно (Ctrl + колесо мыши)",
    close = "Закрыть карту",
    wheel = "Shift + колесо мыши: прозрачность",
    revealOn = "Показать всю карту, включая неисследованные области",
    revealOff = "Показывать только исследованные области",
    cursor = "Курсор",
    player = "Игрок",
    instances = "Подземелья",
    options = "Настройки слоёв карты",
    dungeonMenu = "Подземелья v",
    dungeonMenuTip = "Выбрать карту подземелья",
    detail = "Детальный рельеф",
    quests = "Метки заданий",
    entrances = "Порталы в инстансы",
    instanceMaps = "Карты подземелий и рейдов",
    transport = "Дирижабли и корабли",
    flights = "Точки полётов",
    spirits = "Целители душ",
} or {
    title = "Cartographer Forever",
    back = "Go to parent map",
    home = "Show player location",
    smaller = "Smaller window (Ctrl + mouse wheel)",
    larger = "Larger window (Ctrl + mouse wheel)",
    close = "Close map",
    wheel = "Shift + mouse wheel: opacity",
    revealOn = "Show unexplored areas",
    revealOff = "Show only explored areas",
    cursor = "Cursor",
    player = "Player",
    instances = "Instances",
    options = "Map layer settings",
    dungeonMenu = "Dungeons v",
    dungeonMenuTip = "Choose a dungeon map",
    detail = "Detailed terrain",
    quests = "Quest markers",
    entrances = "Instance entrances",
    instanceMaps = "Dungeon and raid maps",
    transport = "Zeppelins and ships",
    flights = "Flight points",
    spirits = "Spirit healers",
}

local featureOptions = {
    { key = "showDetailMap", label = labels.detail },
    { key = "showQuests", label = labels.quests },
    { key = "showEntrances", label = labels.entrances },
    { key = "showInstanceMaps", label = labels.instanceMaps },
    { key = "showTransport", label = labels.transport },
    { key = "showFlightPoints", label = labels.flights },
    { key = "showSpiritHealers", label = labels.spirits },
}

local BASE_WIDTH = 1000
-- Match the 3:2 map art below the 21-pixel header, avoiding letterboxing.
local BASE_HEIGHT = 689
local MIN_SCALE = 0.60
local MAX_SCALE = 1.25
local MIN_ALPHA = 0.40
local MAX_ALPHA = 1.00
local STEP = 0.05

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function Settings()
    if ns.db and type(ns.db.settings) == "table" then
        return ns.db.settings
    end
    return nil
end

local function FindRenderableMap(mapID)
    if not C_Map or not C_Map.GetMapArtLayers then return nil end
    for _ = 1, 12 do
        if type(mapID) ~= "number" or mapID <= 0 then return nil end
        local ok, layers = pcall(C_Map.GetMapArtLayers, mapID)
        if ok and type(layers) == "table" and layers[1] then return mapID end
        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
        mapID = info and info.parentMapID
    end
    return nil
end

local function GetPlayerMapID()
    if MapUtil and MapUtil.GetDisplayableMapForPlayer then
        local id = FindRenderableMap(MapUtil.GetDisplayableMapForPlayer())
        if id then return id end
    end
    if C_Map and C_Map.GetBestMapForUnit then
        local id = FindRenderableMap(C_Map.GetBestMapForUnit("player"))
        if id then return id end
    end
    -- Some Forever dungeons have no native UiMap. Keep the window open on
    -- their entrance zone so the instance artwork can be shown over it.
    if IsInInstance and GetInstanceInfo and ns.TravelData then
        local inside, instanceType = IsInInstance()
        if inside and (instanceType == "party" or instanceType == "raid") then
            local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
            for _, entry in ipairs(ns.TravelData.entrances) do
                if entry.instance == instanceID and entry.zone then
                    local id = FindRenderableMap(entry.zone)
                    if id then return id end
                end
            end
        end
    end
    return FindRenderableMap(1415) or FindRenderableMap(1414)
end

local function SavePosition(map)
    local settings = Settings()
    if not settings then return end
    local x, y = map:GetCenter()
    local uiX, uiY = UIParent:GetCenter()
    if not x or not y or not uiX or not uiY then return end
    local frameScale = map:GetEffectiveScale()
    local parentScale = UIParent:GetEffectiveScale()
    if not frameScale or not parentScale or parentScale <= 0 then return end
    settings.x = x * frameScale / parentScale - uiX
    settings.y = y * frameScale / parentScale - uiY
end

local function ApplyScale(map, value)
    local maxWidth = (UIParent:GetWidth() - 24) / BASE_WIDTH
    local maxHeight = (UIParent:GetHeight() - 24) / BASE_HEIGHT
    local upper = math.max(MIN_SCALE, math.min(MAX_SCALE, maxWidth, maxHeight))
    value = Clamp(value, MIN_SCALE, upper)
    local settings = Settings()
    if settings then settings.scale = value end
    if InCombatLockdown and InCombatLockdown() then return end
    if pcall(map.SetScale, map, value) then
        pcall(map.OnFrameSizeChanged, map)
    end
end

local function ApplyAlpha(map, value)
    value = Clamp(value, MIN_ALPHA, MAX_ALPHA)
    local settings = Settings()
    if settings then settings.alpha = value end
    if InCombatLockdown and InCombatLockdown() then return end
    pcall(map.SetAlpha, map, value)
end

local function ShowTooltip(button)
    if not button.tip then return end
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
    GameTooltip:SetText(button.tip)
    GameTooltip:Show()
end

local function MakeButton(parent, text, tip, x, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 20)
    button:SetPoint("RIGHT", parent, "RIGHT", x, 0)
    button.tip = tip
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetAllPoints()
    label:SetText(text)
    button.Text = label
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function FormatLevelRange(low, high, estimated)
    if type(low) ~= "number" or type(high) ~= "number" or low <= 0 or high <= 0 then
        return ""
    end
    local color = GetQuestDifficultyColor and GetQuestDifficultyColor(low)
    local r = color and color.r or 1
    local g = color and color.g or 0.25
    local b = color and color.b or 0.25
    local hex = string.format("%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    local range = low == high and tostring(low) or (low .. "-" .. high)
    return " " .. (estimated and "~" or "") .. "|cff" .. hex .. "[" .. range .. "]|r"
end

local function CreateMapReadouts(map)
    local overlay = CreateFrame("Frame", nil, map)
    overlay:SetAllPoints(map.ScrollContainer)
    overlay:SetFrameLevel(map.ScrollContainer:GetFrameLevel() + 40)
    overlay:EnableMouse(false)
    map.InfoOverlay = overlay

    local hoverTitle = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local font, size = GameFontHighlightLarge:GetFont()
    hoverTitle:SetFont(font, size, "OUTLINE")
    hoverTitle:SetPoint("TOP", overlay, "TOP", 0, -10)
    hoverTitle:SetWidth(BASE_WIDTH - 80)
    hoverTitle:SetJustifyH("CENTER")
    hoverTitle:SetTextColor(1, 0.85, 0.2)
    hoverTitle:Hide()
    map.HoverTitle = hoverTitle

    local instances = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instances:SetPoint("TOP", hoverTitle, "BOTTOM", 0, -2)
    instances:SetWidth(BASE_WIDTH - 80)
    instances:SetJustifyH("CENTER")
    instances:SetShadowColor(0, 0, 0, 1)
    instances:SetShadowOffset(1, -1)
    instances:Hide()
    map.HoverInstances = instances

    local coordinates = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    coordinates:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 12, 12)
    coordinates:SetJustifyH("LEFT")
    coordinates:SetShadowColor(0, 0, 0, 1)
    coordinates:SetShadowOffset(1, -1)
    map.CoordinatesText = coordinates
end

local function FormatInstances(instances)
    if type(instances) ~= "table" or #instances == 0 then return nil end
    local lines = { "|cffffff00" .. labels.instances .. ":|r" }
    for _, instance in ipairs(instances) do
        if type(instance) == "table" then
            local name = (isRussian and instance.ru) or instance.name or instance[1]
            if name then
                local line = name .. FormatLevelRange(instance.low, instance.high)
                if type(instance.size) == "number" and instance.size > 0 then
                    line = line .. " (" .. instance.size .. ")"
                end
                table.insert(lines, line)
            end
        elseif type(instance) == "string" then
            table.insert(lines, instance)
        end
    end
    return #lines > 1 and table.concat(lines, "\n") or nil
end

local function UpdateHover(map, x, y)
    if not x or not y then
        map.HoverTitle:Hide()
        map.HoverInstances:Hide()
        map.lastHoverKey = nil
        return
    end
    local mapID = map:GetMapID()
    if not mapID or not C_Map or not C_Map.GetMapInfoAtPosition then return end
    local ok, info = pcall(C_Map.GetMapInfoAtPosition, mapID, x, y)
    local name, zoneMapID
    if ok and info and info.mapID ~= mapID then
        name = info.name
        zoneMapID = info.mapID
    elseif MapUtil and MapUtil.FindBestAreaNameAtMouse then
        local areaOK, areaName = pcall(MapUtil.FindBestAreaNameAtMouse, mapID, x, y)
        if areaOK then
            name = areaName
            local currentMapInfo = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
            if currentMapInfo and currentMapInfo.name == name then zoneMapID = mapID end
        end
    end
    if not name then
        map.HoverTitle:Hide()
        map.HoverInstances:Hide()
        map.lastHoverKey = nil
        return
    end
    local low, high, estimated
    if zoneMapID and ns.GetZoneLevelRange then
        low, high, estimated = ns.GetZoneLevelRange(zoneMapID)
    end
    local key = name .. ":" .. tostring(zoneMapID) .. ":" .. tostring(low) .. ":" .. tostring(high) .. ":" .. tostring(estimated)
    if map.lastHoverKey == key then return end
    map.lastHoverKey = key
    map.HoverTitle:SetText(name .. FormatLevelRange(low, high, estimated))
    map.HoverTitle:Show()
    local text = FormatInstances(zoneMapID and ns.DungeonData and ns.DungeonData[zoneMapID])
    if text then
        map.HoverInstances:SetText(text)
        map.HoverInstances:Show()
    else
        map.HoverInstances:Hide()
    end
end

local function UpdateCoordinates(map, x, y, elapsed)
    local cursor = "--, --"
    if x and y then cursor = string.format("%.1f, %.1f", x * 100, y * 100) end
    map.playerReadoutElapsed = (map.playerReadoutElapsed or 0) + elapsed
    if not map.playerCoordinateText or map.playerReadoutElapsed >= 0.25 then
        map.playerReadoutElapsed = 0
        local player = "--, --"
        local zoneName
        if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
            local ok, playerMapID = pcall(C_Map.GetBestMapForUnit, "player")
            local visited = {}
            for _ = 1, 12 do
                if not ok or type(playerMapID) ~= "number" or visited[playerMapID] then break end
                visited[playerMapID] = true
                local positionOK, position = pcall(C_Map.GetPlayerMapPosition, playerMapID, "player")
                if positionOK and position then
                    local valid, px, py = pcall(position.GetXY, position)
                    if positionOK and valid and type(px) == "number" and type(py) == "number" then
                        player = string.format("%.1f, %.1f", px * 100, py * 100)
                        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)
                        zoneName = info and info.name
                        break
                    end
                end
                local info = C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)
                playerMapID = info and info.parentMapID
            end
        end
        map.playerCoordinateText = labels.player .. ": " .. player .. (zoneName and (" (" .. zoneName .. ")") or "")
    end
    local text = labels.cursor .. ": " .. cursor .. "\n" .. map.playerCoordinateText
    if text ~= map.lastCoordinateText then
        map.CoordinatesText:SetText(text)
        map.lastCoordinateText = text
    end
end

local function CreateHeader(map)
    local header = map.Header
    local headerBackground = header:CreateTexture(nil, "BACKGROUND")
    headerBackground:SetAllPoints(header)
    headerBackground:SetColorTexture(0.065, 0.075, 0.095, 0.98)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", header, "LEFT", 9, 0)
    title:SetText(labels.title)
    title:SetTextColor(0.9, 0.92, 0.96)
    map.TitleText = title

    MakeButton(header, "X", labels.close, -8, function() map:Hide() end)
    MakeButton(header, "+", labels.larger, -35, function()
        ApplyScale(map, map:GetScale() + STEP)
    end)
    MakeButton(header, "-", labels.smaller, -62, function()
        ApplyScale(map, map:GetScale() - STEP)
    end)
    MakeButton(header, "H", labels.home, -89, function()
        if ns.ShowPlayerInstanceMap and ns.ShowPlayerInstanceMap(map) then return end
        local mapID = GetPlayerMapID()
        if mapID then map:SetMapID(mapID) end
    end)
    MakeButton(header, "<", labels.back, -116, function()
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(map:GetMapID())
        local parentID = info and FindRenderableMap(info.parentMapID)
        if parentID then
            map:SetMapID(parentID)
        end
    end)
    map.FogButton = MakeButton(header, "F", labels.revealOff, -143, function()
        local settings = Settings()
        if ns.SetRevealFog then
            ns.SetRevealFog(settings and settings.revealFog == false)
        end
    end)
    map:UpdateFogButton()

    map.OptionsButton = MakeButton(header, "O", labels.options, -170, function()
        if map.TravelDropdown then map.TravelDropdown:Hide() end
        if map.OptionsPanel then map.OptionsPanel:SetShown(not map.OptionsPanel:IsShown()) end
    end)
    map.DungeonMenuButton = MakeButton(header, labels.dungeonMenu, labels.dungeonMenuTip, -202, function()
        if map.OptionsPanel then map.OptionsPanel:Hide() end
        if ns.ToggleInstanceDropdown then ns.ToggleInstanceDropdown(map, map.DungeonMenuButton) end
    end)
    map.DungeonMenuButton:SetSize(118, 20)

    local panel = CreateFrame("Frame", nil, map)
    panel:SetSize(245, #featureOptions * 25 + 45)
    panel:SetPoint("TOPRIGHT", map, "TOPRIGHT", -7, -24)
    panel:SetFrameLevel(header:GetFrameLevel() + 5)
    panel:EnableMouse(true)
    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.06, 0.07, 0.09, 0.96)
    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 11, -8)
    heading:SetText(labels.options)
    map.OptionChecks = {}
    for index, option in ipairs(featureOptions) do
        local check = CreateFrame("CheckButton", nil, panel)
        check:SetSize(18, 18)
        check:SetPoint("TOPLEFT", panel, "TOPLEFT", 11, -19 - index * 25)
        local base = check:CreateTexture(nil, "BACKGROUND")
        base:SetAllPoints()
        base:SetColorTexture(0.2, 0.23, 0.27, 1)
        local tick = check:CreateTexture(nil, "OVERLAY")
        tick:SetPoint("CENTER")
        tick:SetSize(12, 12)
        tick:SetColorTexture(0.25, 0.9, 0.45, 1)
        check:SetCheckedTexture(tick)
        local name = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        name:SetPoint("LEFT", check, "RIGHT", 7, 0)
        name:SetText(option.label)
        check:SetScript("OnClick", function(self)
            if ns.SetFeature then ns.SetFeature(option.key, self:GetChecked()) end
        end)
        map.OptionChecks[option.key] = check
    end
    panel:Hide()
    map.OptionsPanel = panel
    map:UpdateFeatureButtons()

    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if not InCombatLockdown() then map:StartMoving() end
    end)
    header:SetScript("OnDragStop", function()
        map:StopMovingOrSizing()
        SavePosition(map)
    end)
    header:EnableMouseWheel(true)
    header:SetScript("OnMouseWheel", function(_, delta)
        map:HandleWindowWheel(delta)
    end)
    header:SetScript("OnEnter", function()
        GameTooltip:SetOwner(header, "ANCHOR_BOTTOM")
        GameTooltip:SetText(labels.wheel)
        GameTooltip:Show()
    end)
    header:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

CartographerForeverMapMixin = CreateFromMixins(MapCanvasMixin)

function CartographerForeverMapMixin:UpdateFeatureButtons()
    local settings = Settings()
    if self.OptionChecks then
        for key, check in pairs(self.OptionChecks) do
            check:SetChecked(settings and settings[key] == true)
        end
    end
    if self.DungeonMenuButton then
        local enabled = settings and settings.showInstanceMaps
        self.DungeonMenuButton.Text:SetTextColor(enabled and 0.35 or 0.5,
            enabled and 0.9 or 0.5, enabled and 1 or 0.5)
    end
end

function CartographerForeverMapMixin:UpdateFogButton()
    if not self.FogButton then return end
    local settings = Settings()
    local reveal = not settings or settings.revealFog ~= false
    self.FogButton.tip = reveal and labels.revealOff or labels.revealOn
    self.FogButton.Text:SetTextColor(reveal and 0.35 or 0.95, reveal and 0.95 or 0.72, reveal and 0.4 or 0.2)
end

function CartographerForeverMapMixin:HandleWindowWheel(delta)
    if IsControlKeyDown() then
        ApplyScale(self, self:GetScale() + (delta > 0 and STEP or -STEP))
        return true
    end
    if IsShiftKeyDown() then
        ApplyAlpha(self, self:GetAlpha() + (delta > 0 and STEP or -STEP))
        return true
    end
    return false
end

function CartographerForeverMapMixin:OnLoad()
    MapCanvasMixin.OnLoad(self)
    self:SetSize(BASE_WIDTH, BASE_HEIGHT)
    self:SetMovable(true)
    self:SetClampedToScreen(true)
    self:SetPoint("CENTER", UIParent, "CENTER")

    self.ScrollContainer:ClearAllPoints()
    self.ScrollContainer:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -22)
    self.ScrollContainer:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 2)
    self.Header:SetFrameLevel(self.ScrollContainer:GetFrameLevel() + 50)
    self:SetShouldNavigateOnClick(true)
    self:SetShouldZoomInOnClick(false)
    self:SetShouldPanOnClick(false)
    self:SetShouldZoomInstantly(true)

    local levels = self:GetPinFrameLevelsManager()
    levels:AddFrameLevel("PIN_FRAME_LEVEL_MAP_EXPLORATION")
    levels:AddFrameLevel("PIN_FRAME_LEVEL_FOG_OF_WAR")
    levels:AddFrameLevel("PIN_FRAME_LEVEL_MAP_HIGHLIGHT")
    levels:AddFrameLevel("PIN_FRAME_LEVEL_MAP_LINK")
    levels:AddFrameLevel("PIN_FRAME_LEVEL_FLIGHT_POINT")
    levels:AddFrameLevel("PIN_FRAME_LEVEL_AREA_POI")
    levels:AddFrameLevel("PIN_FRAME_LEVEL_WAYPOINT_LOCATION")
    levels:AddFrameLevel("PIN_FRAME_LEVEL_GROUP_MEMBER")
    self.explorationProvider = CreateFromMixins(MapExplorationDataProviderMixin)
    self.fogProvider = CreateFromMixins(FogOfWarDataProviderMixin)
    self:AddDataProvider(self.explorationProvider)
    self:AddDataProvider(self.fogProvider)
    self:AddDataProvider(CreateFromMixins(MapHighlightDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(MapLinkDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(FlightPointDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(AreaPOIDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(WaypointLocationDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(GroupMembersDataProviderMixin))

    if ns.SetupQuestAndNavigation then ns.SetupQuestAndNavigation(self) end
    if ns.SetupTravel then ns.SetupTravel(self) end

    CreateHeader(self)
    CreateMapReadouts(self)
    if ns.SetupFog then ns.SetupFog(self) end
    if ns.SetupDetailMap then ns.SetupDetailMap(self) end
    local nativeWheel = self.ScrollContainer:GetScript("OnMouseWheel")
    self.ScrollContainer:SetScript("OnMouseWheel", function(container, delta)
        if not self:HandleWindowWheel(delta) and nativeWheel then
            nativeWheel(container, delta)
        end
    end)
    self:HookScript("OnSizeChanged", function(map)
        map:OnFrameSizeChanged()
    end)
    if UISpecialFrames then
        table.insert(UISpecialFrames, self:GetName())
    end
end

function CartographerForeverMapMixin:OnUpdate(elapsed)
    MapCanvasMixin.OnUpdate(self, elapsed)
    local x, y
    if self:IsCanvasMouseFocusOrPinFocus() then
        local ok, cursorX, cursorY = pcall(self.GetNormalizedCursorPosition, self)
        if ok and type(cursorX) == "number" and type(cursorY) == "number"
            and cursorX >= 0 and cursorX <= 1 and cursorY >= 0 and cursorY <= 1 then
            x, y = cursorX, cursorY
        end
    end
    self.hoverReadoutElapsed = (self.hoverReadoutElapsed or 0) + elapsed
    if self.hoverReadoutElapsed >= 0.05 or not x then
        self.hoverReadoutElapsed = 0
        UpdateHover(self, x, y)
    end
    UpdateCoordinates(self, x, y, elapsed)
end

function CartographerForeverMapMixin:OnShow()
    local mapID = self.mapID or GetPlayerMapID()
    if not mapID and IsInInstance then
        local inside, instanceType = IsInInstance()
        if inside and (instanceType == "party" or instanceType == "raid") then
            -- The static viewer can render even when the client supplies no
            -- displayable UiMap for the player's current dungeon.
            mapID = 1415
        end
    end
    if not mapID then self:Hide() return end
    if not self.mapID then self:SetMapID(mapID) end
    self.playerCoordinateText = nil
    MapCanvasMixin.OnShow(self)
    -- UIParent can have a provisional size while SavedVariables are loaded.
    -- Apply the largest usable scale when the map is first opened each login.
    if not self.foreverInitialMaxApplied then
        self.foreverInitialMaxApplied = true
        ApplyScale(self, MAX_SCALE)
    end
    if ns.RefreshFeatureSettings then ns.RefreshFeatureSettings(self) end
    if ns.ShowPlayerInstanceMap then ns.ShowPlayerInstanceMap(self) end
end

function CartographerForeverMapMixin:OnHide()
    MapCanvasMixin.OnHide(self)
    if self.OptionsPanel then self.OptionsPanel:Hide() end
    if self.HoverTitle then self.HoverTitle:Hide() end
    if self.HoverInstances then self.HoverInstances:Hide() end
    self.lastHoverKey = nil
end

function CartographerForeverMapMixin:OnEvent(event, ...)
    MapCanvasMixin.OnEvent(self, event, ...)
end

function CartographerForeverMapMixin:OnMapChanged()
    MapCanvasMixin.OnMapChanged(self)
    self.lastHoverKey = nil
    if self.HoverTitle then self.HoverTitle:Hide() end
    if self.HoverInstances then self.HoverInstances:Hide() end
    if ns.RefreshFog then ns.RefreshFog(self) end
    if ns.RefreshFeatureSettings then ns.RefreshFeatureSettings(self) end
    local mapID = self:GetMapID()
    local info = mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    if self.TitleText then
        self.TitleText:SetText(info and info.name or labels.title)
    end
end

function CartographerForeverMapMixin:OnCanvasSizeChanged()
    MapCanvasMixin.OnCanvasSizeChanged(self)
end

function ns.RefreshFeatureSettings(map)
    if not map then return end
    if map.UpdateFeatureButtons then map:UpdateFeatureButtons() end
    if ns.RefreshDetailMap then ns.RefreshDetailMap(map) end
    if ns.RefreshQuestAndNavigation then ns.RefreshQuestAndNavigation(map) end
    if ns.RefreshTravel then ns.RefreshTravel(map) end
end

function ns.ApplySettings()
    if InCombatLockdown and InCombatLockdown() then return end
    local map = CartographerForeverMapFrame
    if not map then return end
    local settings = Settings()
    local scale = settings and tonumber(settings.scale) or MAX_SCALE
    local alpha = settings and tonumber(settings.alpha) or 1
    ApplyScale(map, scale or MAX_SCALE)
    ApplyAlpha(map, alpha or 1)
    local x = settings and tonumber(settings.x) or 0
    local y = settings and tonumber(settings.y) or 0
    map:ClearAllPoints()
    map:SetPoint("CENTER", UIParent, "CENTER", x or 0, y or 0)
    map:UpdateFogButton()
    if ns.RefreshFog then ns.RefreshFog(map) end
    ns.RefreshFeatureSettings(map)
end

function ns.ToggleMapWindow()
    local map = CartographerForeverMapFrame
    if not map then return false end
    if map:IsShown() then
        map:Hide()
    else
        map:Show()
    end
    return true
end
