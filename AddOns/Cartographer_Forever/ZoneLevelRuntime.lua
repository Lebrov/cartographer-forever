local addonName, ns = ...

-- Forever's C_Map.GetMapLevels often returns 0. The Group Finder carries
-- current recommended zone levels; use those when its activity matches a map.
local suggested = {}
local lastScan = -math.huge
local scanned = false
local lastRequest = -math.huge
local ScanActivities

local activityEvents = CreateFrame("Frame")
activityEvents:RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE")
activityEvents:SetScript("OnEvent", function()
    scanned = false
    lastScan = -math.huge
    if ScanActivities then ScanActivities() end
end)

local function ValidLevels(low, high)
    return type(low) == "number" and type(high) == "number"
        and low >= 1 and high >= low and high <= 100
end

local function AddActivity(activityID)
    local ok, mapID, low, high, score = pcall(function()
        local info = C_LFGList.GetActivityInfoTable(activityID)
        if not info or type(info.mapID) ~= "number" or not ns.ZoneInfoData[info.mapID] then return end
        local low, high = info.minLevelSuggestion, info.maxLevelSuggestion
        if not ValidLevels(low, high) then return end
        local mapInfo = C_Map.GetMapInfo(info.mapID)
        local zoneName = mapInfo and mapInfo.name
        if type(zoneName) ~= "string" or zoneName == "" then return end
        local fullName = info.fullName
        local shortName = info.shortName
        local exact = fullName == zoneName or shortName == zoneName
        local contains = (type(fullName) == "string" and fullName:find(zoneName, 1, true))
            or (type(shortName) == "string" and shortName:find(zoneName, 1, true))
        if not exact and not contains then return end
        return info.mapID, low, high, exact and 2 or 1
    end)
    if ok and mapID then
        local previous = suggested[mapID]
        if not previous or score > previous.score then
            suggested[mapID] = { low = low, high = high, score = score }
        end
        return true
    end
end

ScanActivities = function()
    if not C_LFGList or not C_LFGList.GetAvailableActivities
        or not C_LFGList.GetActivityInfoTable or not C_Map or not C_Map.GetMapInfo then return end
    local now = GetTime and GetTime() or 0
    if scanned or now - lastScan < 30 then return end
    lastScan = now

    if C_LFGList.HasActivityList then
        local readyOK, ready = pcall(C_LFGList.HasActivityList)
        if not readyOK or not ready then
            if C_LFGList.RequestAvailableActivities and now - lastRequest >= 30 then
                local requestOK = pcall(C_LFGList.RequestAvailableActivities)
                if requestOK then lastRequest = now end
            end
            return
        end
    end

    suggested = {}
    local seen = {}
    local foundAny = false
    local matchedZone = false
    local ok, categories = pcall(C_LFGList.GetAvailableCategories)
    if ok and type(categories) == "table" then
        for _, categoryID in ipairs(categories) do
            local activitiesOK, activities = pcall(C_LFGList.GetAvailableActivities, categoryID)
            if activitiesOK and type(activities) == "table" then
                for _, activityID in ipairs(activities) do
                    if type(activityID) == "number" and not seen[activityID] then
                        seen[activityID] = true
                        foundAny = true
                        if AddActivity(activityID) then matchedZone = true end
                    end
                end
            end
        end
    end
    if not foundAny then
        local allOK, activities = pcall(C_LFGList.GetAvailableActivities)
        if allOK and type(activities) == "table" then
            for _, activityID in ipairs(activities) do
                if type(activityID) == "number" and not seen[activityID] then
                    foundAny = true
                    if AddActivity(activityID) then matchedZone = true end
                end
            end
        end
    end
    scanned = foundAny and matchedZone
end

function ns.GetZoneLevelRange(mapID)
    if type(mapID) ~= "number" then return nil end
    ScanActivities()
    local data = suggested[mapID] or (ns.ZoneInfoData and ns.ZoneInfoData[mapID])
    if data then return data.low, data.high, data.estimated == true end
    if C_Map and C_Map.GetMapLevels then
        local ok, low, high = pcall(C_Map.GetMapLevels, mapID)
        if ok and ValidLevels(low, high) then return low, high end
    end
    return nil
end
