-- Modules/QuestMobAutomarker.lua: Quest Mob Nameplate Indicator
-- Author: Antigravity
-- NOTE: Nameplate indicators are parented to UIParent (not the nameplate frame)
--       to avoid tainting Blizzard's secure nameplate hierarchy.

local ADDON_NAME, ns = ...

local questFrame = CreateFrame("Frame", "YAQoLQuestMobFrame")
local scanTooltip = nil
local nameplateIndicators = {} -- keyed by nameplate frame

-- Hidden tooltip helper for objective scanning fallback
local function GetOrCreateScanTooltip()
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", "YAQoLQuestScanTooltip", nil, "GameTooltipTemplate")
        scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return scanTooltip
end

local unitQuestCache = {}

-- Detects if a given unit is required for an active quest (Cached per unit GUID)
function ns.IsQuestUnit(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsPlayer(unit) or UnitIsDead(unit) or UnitIsFriend("player", unit) or not UnitCanAttack("player", unit) then return false end

    local guid = UnitGUID(unit)
    if guid and unitQuestCache[guid] ~= nil then
        local cached = unitQuestCache[guid]
        return cached.isQuest, cached.qText, cached.cur, cached.goal
    end

    local isQuest, qText, cur, goal = false, nil, nil, nil

    -- 1. Modern C_TooltipInfo API (WoW 10.0+ / Classic engine)
    if C_TooltipInfo and C_TooltipInfo.GetUnit then
        local data = C_TooltipInfo.GetUnit(unit)
        if data and data.lines then
            for _, line in ipairs(data.lines) do
                local isObjType = (line.type == 8) or (Enum.TooltipDataLineType and line.type == Enum.TooltipDataLineType.QuestObjective)
                if (isObjType or line.type == 17 or line.type == 0 or not line.type) and line.leftText then
                    local text = line.leftText
                    local isComplete = text:find("100%%") or text:find("Complete") or text:find("Abgeschlossen")
                    local c, g = text:match("(%d+)%s*/%s*(%d+)")
                    if c and g then
                        local cNum = tonumber(c)
                        local gNum = tonumber(g)
                        if cNum and gNum and cNum < gNum then
                            isQuest, qText, cur, goal = true, text, c, g
                            break
                        end
                    elseif not isComplete and (isObjType or text:find("%%")) then
                        isQuest, qText = true, text
                        break
                    end
                end
            end
        end
    end

    -- 2. Fallback via hidden GameTooltip
    if not isQuest then
        local tip = GetOrCreateScanTooltip()
        tip:ClearLines()
        tip:SetUnit(unit)
        local numLines = tip:NumLines()
        for i = 2, numLines do
            local line = _G["YAQoLQuestScanTooltipTextLeft" .. i]
            if line then
                local text = line:GetText()
                if text then
                    local isComplete = text:find("100%%") or text:find("Complete") or text:find("Abgeschlossen")
                    local c, g = text:match("(%d+)%s*/%s*(%d+)")
                    if c and g then
                        local cNum = tonumber(c)
                        local gNum = tonumber(g)
                        if cNum and gNum and cNum < gNum then
                            isQuest, qText, cur, goal = true, text, c, g
                            break
                        end
                    elseif not isComplete and text:find("%%") then
                        isQuest, qText = true, text
                        break
                    end
                end
            end
        end
    end

    if guid then
        unitQuestCache[guid] = { isQuest = isQuest, qText = qText, cur = cur, goal = goal }
    end

    return isQuest, qText, cur, goal
end

-- Clear quest mob cache when quest log updates
local function InvalidateQuestCache()
    unitQuestCache = {}
end

----------------------------------------------------
-- OPTION 3: NAMEPLATE QUEST OBJECTIVE HIGHLIGHT
----------------------------------------------------
local function GetNameplateAnchor(nameplateFrame, unit)
    if not nameplateFrame then return nameplateFrame, "TOP", 0, 0 end

    local uf = nameplateFrame.UnitFrame or nameplateFrame.unitFrame or nameplateFrame.UF
    local anchorFrame = nameplateFrame
    local anchorPoint = "TOP"
    local xOff = 0
    local yOff = 1

    if uf then
        if uf.name and uf.name:IsShown() then
            anchorFrame = uf.name
            anchorPoint = "TOP"
            yOff = 1
        elseif uf.Name and uf.Name:IsShown() then
            anchorFrame = uf.Name
            anchorPoint = "TOP"
            yOff = 1
        elseif uf.healthBar and uf.healthBar:IsShown() then
            anchorFrame = uf.healthBar
            anchorPoint = "TOP"
            yOff = 12
        elseif uf.HealthBar and uf.HealthBar:IsShown() then
            anchorFrame = uf.HealthBar
            anchorPoint = "TOP"
            yOff = 14
        else
            anchorFrame = uf
            anchorPoint = "TOP"
            yOff = 2
        end
    else
        -- Fallback for raw C_NamePlate frame container
        anchorFrame = nameplateFrame
        anchorPoint = "CENTER"
        yOff = 14
    end

    -- If a raid target marker icon (like orange circle) is present on this unit, offset up slightly to stack cleanly!
    if unit and GetRaidTargetIndex and GetRaidTargetIndex(unit) then
        yOff = yOff + 16
    end

    return anchorFrame, anchorPoint, xOff, yOff
end

local function GetOrCreateNameplateIndicator(nameplateFrame)
    if nameplateIndicators[nameplateFrame] then
        return nameplateIndicators[nameplateFrame]
    end

    local ind = CreateFrame("Frame", nil, UIParent)
    ind:SetSize(40, 20)
    ind:SetFrameStrata("HIGH")
    ind:SetFrameLevel(200)
    ind.nameplateRef = nameplateFrame

    local icon = ind:CreateTexture(nil, "OVERLAY")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", ind, "LEFT", 0, 0)
    if icon.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("QuestNormal") then
        icon:SetAtlas("QuestNormal")
    else
        icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    end
    ind.icon = icon

    local text = ind:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    text:SetPoint("LEFT", icon, "RIGHT", 2, 0)
    text:SetTextColor(1, 0.85, 0.25, 1)
    ind.text = text

    nameplateIndicators[nameplateFrame] = ind
    return ind
end

local function UpdateNameplate(unit)
    if not unit or not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return end
    local nameplateFrame = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplateFrame then return end

    local db = ns.db or _G["YAQoLDB"] or _G["WOWForeverAddonDB"]
    local enabled = db and db.QuestNameplateHighlight

    if not enabled or UnitIsDead(unit) or UnitIsPlayer(unit) or UnitIsFriend("player", unit) or not UnitCanAttack("player", unit) then
        if nameplateIndicators[nameplateFrame] then
            nameplateIndicators[nameplateFrame]:Hide()
        end
        return
    end

    local isQuest, qText, cur, goal = ns.IsQuestUnit(unit)
    if isQuest then
        local ind = GetOrCreateNameplateIndicator(nameplateFrame)
        local anchorFrame, anchorPoint, xOff, yOff = GetNameplateAnchor(nameplateFrame, unit)
        ind:ClearAllPoints()
        ind:SetPoint("BOTTOM", anchorFrame, anchorPoint, xOff, yOff)
        if cur and goal then
            ind.text:SetText(string.format("%s/%s", cur, goal))
            ind:SetWidth(18 + ind.text:GetStringWidth())
        else
            ind.text:SetText("")
            ind:SetWidth(18)
        end
        ind:Show()
    else
        if nameplateIndicators[nameplateFrame] then
            nameplateIndicators[nameplateFrame]:Hide()
        end
    end
end

local function OnNameplateAdded(unit)
    UpdateNameplate(unit)
end

local function OnNameplateRemoved(unit)
    if not unit or not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return end
    local nameplateFrame = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplateFrame and nameplateIndicators[nameplateFrame] then
        nameplateIndicators[nameplateFrame]:Hide()
    end
end

local function RefreshAllNameplates()
    local db = ns.db or _G["YAQoLDB"] or _G["WOWForeverAddonDB"]
    local enabled = db and db.QuestNameplateHighlight

    if not enabled then
        for _, ind in pairs(nameplateIndicators) do
            ind:Hide()
        end
        return
    end

    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    local nameplates = C_NamePlate.GetNamePlates()
    if not nameplates then return end
    for _, nameplateFrame in ipairs(nameplates) do
        local unit = nameplateFrame.namePlateUnitToken or (nameplateFrame.UnitFrame and nameplateFrame.UnitFrame.unit)
        if unit then
            UpdateNameplate(unit)
        end
    end
end
ns.RefreshQuestNameplates = RefreshAllNameplates

----------------------------------------------------
-- EVENT DISPATCHER & LIFECYCLE
----------------------------------------------------
questFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
questFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
questFrame:RegisterEvent("QUEST_LOG_UPDATE")

questFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "NAME_PLATE_UNIT_ADDED" then
        OnNameplateAdded(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        OnNameplateRemoved(arg1)
    elseif event == "QUEST_LOG_UPDATE" then
        InvalidateQuestCache()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.15, RefreshAllNameplates)
        else
            RefreshAllNameplates()
        end
    end
end)
