local addonName, ns = ...

local russian = GetLocale() == "ruRU"
local featureCommands = {
    detail = "showDetailMap",
    quests = "showQuests",
    entrances = "showEntrances",
    instances = "showInstanceMaps",
    transport = "showTransport",
    flights = "showFlightPoints",
    spirits = "showSpiritHealers",
}
local featureDefaults = {
    showDetailMap = false,
    showQuests = true,
    showEntrances = true,
    showInstanceMaps = true,
    showTransport = true,
    showFlightPoints = true,
    showSpiritHealers = true,
}
local function Say(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffCartographer Forever:|r " .. message)
    end
end

local function InitializeDB()
    if type(CartographerForeverDB) ~= "table" then
        CartographerForeverDB = {}
    end
    local db = CartographerForeverDB
    if type(db.settings) ~= "table" then
        db.settings = {}
    end
    local settings = db.settings
    if type(settings.scale) ~= "number" then settings.scale = 1.25 end
    if type(settings.alpha) ~= "number" then settings.alpha = 1 end
    if type(settings.x) ~= "number" then settings.x = 0 end
    if type(settings.y) ~= "number" then settings.y = 0 end
    if settings.captureMapKey == nil then settings.captureMapKey = true end
    if settings.revealFog == nil then settings.revealFog = true end
    for key, default in pairs(featureDefaults) do
        if type(settings[key]) ~= "boolean" then settings[key] = default end
    end
    db.version = 5
    ns.db = db
end

local function GetMap()
    return ns.map or CartographerForeverMapFrame
end

function ns.SetFeature(key, enabled)
    if featureDefaults[key] == nil then return false end
    if not ns.db then InitializeDB() end
    ns.db.settings[key] = enabled and true or false
    local map = GetMap()
    if map and ns.RefreshFeatureSettings then ns.RefreshFeatureSettings(map) end
    return true
end

function ns.SetRevealFog(enabled)
    if not ns.db then InitializeDB() end
    local settings = ns.db.settings
    settings.revealFog = enabled and true or false
    local map = GetMap()
    if map and map.UpdateFogButton then map:UpdateFogButton() end
    if map and ns.RefreshFog then ns.RefreshFog(map) end
    if map and ns.RefreshDetailMap then ns.RefreshDetailMap(map) end
    Say(settings.revealFog
        and (russian and "Туман войны выключен: неисследованные области показаны." or "Fog of war hidden: unexplored areas are shown.")
        or (russian and "Туман войны включён." or "Fog of war shown."))
end

function ns.ToggleMap()
    local map = GetMap()
    if not map then
        Say(russian and "Окно карты ещё не готово." or "The map window is not ready yet.")
        return
    end
    if map:IsShown() then
        map:Hide()
        return
    end
    if WorldMapFrame and WorldMapFrame:IsShown() then
        if HideUIPanel then HideUIPanel(WorldMapFrame) else WorldMapFrame:Hide() end
    end
    map:Show()
end

local bindingOwner = CreateFrame("Frame", "CartographerForeverBindingOwner", UIParent)
local toggleButton = CreateFrame("Button", "CartographerForeverToggleButton", UIParent)
toggleButton:SetScript("OnClick", function() ns.ToggleMap() end)
local bindingUpdatePending = false

local function EnsureEscapeClosesMap()
    if not UISpecialFrames then return end
    for _, name in ipairs(UISpecialFrames) do
        if name == "CartographerForeverMapFrame" then return end
    end
    table.insert(UISpecialFrames, "CartographerForeverMapFrame")
end

local function ApplyMapKeyBinding()
    if InCombatLockdown and InCombatLockdown() then
        bindingUpdatePending = true
        return
    end
    bindingUpdatePending = false
    if not ns.db or not ClearOverrideBindings or not SetOverrideBindingClick then return end
    ClearOverrideBindings(bindingOwner)
    if ns.db.settings.captureMapKey then
        local first, second = GetBindingKey("TOGGLEWORLDMAP")
        if first then
            SetOverrideBindingClick(bindingOwner, true, first, "CartographerForeverToggleButton", "LeftButton")
        end
        if second then
            SetOverrideBindingClick(bindingOwner, true, second, "CartographerForeverToggleButton", "LeftButton")
        end
    end
end

local function Help()
    if russian then
        Say("M — карта; Ctrl+колесо — размер; Shift+колесо — прозрачность; перетащите за заголовок.")
        Say("/cf map, /cf size 0.60-1.25, /cf alpha 0.40-1, /cf fog on|off, /cf reset, /cf key on|off")
        Say("/cf detail|quests|entrances|instances|transport|flights|spirits on|off")
    else
        Say("M: map; Ctrl+wheel: size; Shift+wheel: opacity; drag the title bar to move.")
        Say("/cf map, /cf size 0.60-1.25, /cf alpha 0.40-1, /cf fog on|off, /cf reset, /cf key on|off")
        Say("/cf detail|quests|entrances|instances|transport|flights|spirits on|off")
    end
end

SLASH_CARTOGRAPHERFOREVER1 = "/cf"
SLASH_CARTOGRAPHERFOREVER2 = "/cartographerforever"
SlashCmdList.CARTOGRAPHERFOREVER = function(input)
    if not ns.db then InitializeDB() end
    local command, argument = (input or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    local settings = ns.db.settings
    if command == "" or command == "map" then
        ns.ToggleMap()
    elseif command == "size" then
        local value = tonumber(argument)
        if not value or value < 0.60 or value > 1.25 then Help() return end
        settings.scale = value
        if ns.ApplySettings then ns.ApplySettings() end
        Say((russian and "Размер: " or "Size: ") .. string.format("%.2f", settings.scale))
    elseif command == "alpha" then
        local value = tonumber(argument)
        if not value or value < 0.40 or value > 1 then Help() return end
        settings.alpha = value
        if ns.ApplySettings then ns.ApplySettings() end
        Say((russian and "Прозрачность: " or "Opacity: ") .. string.format("%.2f", value))
    elseif command == "fog" and (argument == "on" or argument == "off") then
        ns.SetRevealFog(argument == "off")
    elseif featureCommands[command] and (argument == "on" or argument == "off") then
        ns.SetFeature(featureCommands[command], argument == "on")
        Say(command .. ": " .. argument)
    elseif command == "reset" then
        settings.scale, settings.alpha, settings.x, settings.y = 1.25, 1, 0, 0
        if ns.ApplySettings then ns.ApplySettings() end
        Say(russian and "Положение и размер карты сброшены." or "Map position and size reset.")
    elseif command == "key" and (argument == "on" or argument == "off") then
        settings.captureMapKey = argument == "on"
        ApplyMapKeyBinding()
        Say(settings.captureMapKey and (russian and "Клавиша карты включает Cartographer Forever." or "Map key opens Cartographer Forever.")
            or (russian and "Клавиша карты возвращена стандартному окну." or "Map key restored to the default window."))
    else
        Help()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, loadedName)
    if event == "ADDON_LOADED" and loadedName == addonName then
        InitializeDB()
        if ns.ApplySettings then ns.ApplySettings() end
        EnsureEscapeClosesMap()
    elseif event == "PLAYER_LOGIN" then
        if not ns.db then InitializeDB() end
        if ns.ApplySettings then ns.ApplySettings() end
        EnsureEscapeClosesMap()
        ApplyMapKeyBinding()
    elseif event == "UPDATE_BINDINGS" then
        ApplyMapKeyBinding()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if bindingUpdatePending then ApplyMapKeyBinding() end
        if ns.ApplySettings then ns.ApplySettings() end
    end
end)
