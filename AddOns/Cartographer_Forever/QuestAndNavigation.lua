local _, ns = ...

-- The client already supplies quest pins, tooltips, filtering, and quest-log
-- updates. Keep those providers on our own MapCanvas instead of copying quest
-- data or changing the player's world-map settings.
local function Settings()
    return ns.db and ns.db.settings
end

local function QuestsEnabled()
    local settings = Settings()
    return not settings or settings.showQuests ~= false
end

local ActiveQuestsMixin
if QuestDataProviderMixin then
    ActiveQuestsMixin = CreateFromMixins(QuestDataProviderMixin)
    function ActiveQuestsMixin:RefreshAllData(fromOnShow)
        if QuestsEnabled() then
            QuestDataProviderMixin.RefreshAllData(self, fromOnShow)
        else
            self:RemoveAllData()
        end
    end
end

local AvailableQuestsMixin
if QuestOfferDataProviderMixin then
    AvailableQuestsMixin = CreateFromMixins(QuestOfferDataProviderMixin)
    function AvailableQuestsMixin:RefreshAllData(fromOnShow)
        if QuestsEnabled() then
            QuestOfferDataProviderMixin.RefreshAllData(self, fromOnShow)
        else
            self:RemoveAllData()
        end
    end
end

function ns.SetupQuestAndNavigation(map)
    if not map or map.questNavigationSetup then return end
    map.questNavigationSetup = true

    local levels = map:GetPinFrameLevelsManager()
    if ActiveQuestsMixin then
        levels:AddFrameLevel("PIN_FRAME_LEVEL_QUEST_PING")
        levels:AddFrameLevel("PIN_FRAME_LEVEL_ACTIVE_QUEST",
            C_QuestLog and C_QuestLog.GetMaxNumQuests and C_QuestLog.GetMaxNumQuests() or 35)
        levels:AddFrameLevel("PIN_FRAME_LEVEL_SUPER_TRACKED_QUEST")
        map.foreverActiveQuestProvider = CreateFromMixins(ActiveQuestsMixin)
        map:AddDataProvider(map.foreverActiveQuestProvider)
    end
    if AvailableQuestsMixin then
        levels:AddFrameLevel("PIN_FRAME_LEVEL_QUEST_OFFER", QuestOfferDataProviderMixin.PIN_LEVEL_RANGE or 7)
        map.foreverAvailableQuestProvider = CreateFromMixins(AvailableQuestsMixin)
        map:AddDataProvider(map.foreverAvailableQuestProvider)
    end
end

function ns.RefreshQuestAndNavigation(map)
    if not map then return end
    if not map:IsShown() or not map.mapID then return end
    if map.foreverActiveQuestProvider then
        map.foreverActiveQuestProvider:RefreshAllData()
    end
    if map.foreverAvailableQuestProvider then
        map.foreverAvailableQuestProvider:RefreshAllData()
    end
end
