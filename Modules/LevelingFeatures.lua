-- Modules/LevelingFeatures.lua: Leveling Features Suite for WOWForeverAddon
local ADDON_NAME, ns = ...

local levelingFrame = CreateFrame("Frame", "WOWForeverLevelingEventFrame", UIParent)

-- Analytics State
local sessionStartTime = time()
local sessionStartXP = 0
local sessionStartLevel = 0
local lastKillXP = 0

----------------------------------------------------
-- BLIZZARD XP BAR SUPPRESSION HELPER
----------------------------------------------------
local function SetBlizzardXPBarVisible(visible)
    if StatusTrackingBarManager then
        if visible then
            StatusTrackingBarManager:Show()
        else
            StatusTrackingBarManager:Hide()
        end
    end
    if MainMenuExpBar then
        if visible then
            MainMenuExpBar:Show()
            MainMenuExpBar:SetAlpha(1)
        else
            MainMenuExpBar:Hide()
            MainMenuExpBar:SetAlpha(0)
        end
    end
    if ReputationWatchBar and not visible then
        ReputationWatchBar:Hide()
    end
end

----------------------------------------------------
-- XP BAR FRAME SETUP
----------------------------------------------------
local xpBar = CreateFrame("Frame", "WOWForeverXPBar", UIParent, ns.backdropTemplate)
xpBar:SetSize(500, 14)
xpBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 40)
xpBar:SetFrameStrata("MEDIUM")
xpBar:SetClampedToScreen(true)
xpBar:EnableMouse(true)
xpBar:SetMovable(true)

-- Modern Dark Backdrop
ns.ApplyModernBackdrop(xpBar, 0.03, 0.02, 0.06, 0.9, 0.25, 0.12, 0.45, 0.8)

-- Texture Layer 1: Base Current XP
local texBase = xpBar:CreateTexture(nil, "ARTWORK", nil, 1)
texBase:SetTexture("Interface\\Buttons\\WHITE8X8")
texBase:SetPoint("TOPLEFT", xpBar, "TOPLEFT", 1, -1)
texBase:SetPoint("BOTTOMLEFT", xpBar, "BOTTOMLEFT", 1, 1)
texBase:SetWidth(1)

-- Texture Layer 2: Completed Quests XP (Green overlay ahead of Current XP)
local texCompletedQuest = xpBar:CreateTexture(nil, "ARTWORK", nil, 2)
texCompletedQuest:SetTexture("Interface\\Buttons\\WHITE8X8")
texCompletedQuest:SetPoint("TOPLEFT", texBase, "TOPRIGHT", 0, 0)
texCompletedQuest:SetPoint("BOTTOMLEFT", texBase, "BOTTOMRIGHT", 0, 0)
texCompletedQuest:SetWidth(1)

-- Texture Layer 3: Active Quests XP (Purple overlay ahead of Completed Quests XP)
local texActiveQuest = xpBar:CreateTexture(nil, "ARTWORK", nil, 3)
texActiveQuest:SetTexture("Interface\\Buttons\\WHITE8X8")
texActiveQuest:SetPoint("TOPLEFT", texCompletedQuest, "TOPRIGHT", 0, 0)
texActiveQuest:SetPoint("BOTTOMLEFT", texCompletedQuest, "BOTTOMRIGHT", 0, 0)
texActiveQuest:SetWidth(1)

-- Texture Layer 4: Rested XP (Gold overlay ahead of Current XP)
local texRested = xpBar:CreateTexture(nil, "OVERLAY", nil, 4)
texRested:SetTexture("Interface\\Buttons\\WHITE8X8")
texRested:SetPoint("TOPLEFT", texBase, "TOPRIGHT", 0, 0)
texRested:SetPoint("BOTTOMLEFT", texBase, "BOTTOMRIGHT", 0, 0)
texRested:SetWidth(1)
texRested:SetAlpha(0.65)

-- Text Display Overlay
local centerText = xpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
centerText:SetPoint("CENTER", xpBar, "CENTER", 0, 0)

local statsBadge = xpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
statsBadge:SetPoint("BOTTOM", xpBar, "TOP", 0, 4)

----------------------------------------------------
-- DRAG & POSITION SAVING
----------------------------------------------------
xpBar:RegisterForDrag("LeftButton")
xpBar:SetScript("OnDragStart", function(self)
    if IsAltKeyDown() then
        self:StartMoving()
    end
end)

xpBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local db = WOWForeverAddonDB or ns.db
    if db then
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        db.XPBarPosition = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        if ns.Log then ns.Log("XPBAR", string.format("Saved position: %s %d, %d", point, xOfs, yOfs)) end
    end
end)

----------------------------------------------------
-- QUEST LOG XP SCANNER (Cached)
----------------------------------------------------
local cachedCompletedQuestXP = 0
local cachedActiveQuestXP = 0
local questLogXPDirty = true

local function GetQuestLogXPInfo(force)
    if not questLogXPDirty and not force then
        return cachedCompletedQuestXP, cachedActiveQuestXP
    end

    local completedXP = 0
    local activeXP = 0

    local numEntries = 0
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        numEntries = C_QuestLog.GetNumQuestLogEntries()
    elseif GetNumQuestLogEntries then
        numEntries = GetNumQuestLogEntries()
    end

    for i = 1, numEntries do
        local questID = 0
        local isHeader = false
        local isComplete = false

        if C_QuestLog and C_QuestLog.GetInfo then
            local info = C_QuestLog.GetInfo(i)
            if info then
                questID = info.questID
                isHeader = info.isHeader
                isComplete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) or false
            end
        elseif GetQuestLogTitle then
            local title, level, questTag, isHeaderQuest, isCollapsed, complete, frequency, qID = GetQuestLogTitle(i)
            isHeader = isHeaderQuest
            isComplete = (complete == 1 or complete == true)
            questID = qID or 0
        end

        if not isHeader and questID and questID > 0 then
            local rewardXP = 0
            if C_QuestLog and C_QuestLog.GetQuestRewardXP then
                rewardXP = C_QuestLog.GetQuestRewardXP(questID) or 0
            elseif GetQuestLogRewardXP then
                rewardXP = GetQuestLogRewardXP(questID) or 0
            end

            if rewardXP > 0 then
                if isComplete then
                    completedXP = completedXP + rewardXP
                else
                    activeXP = activeXP + rewardXP
                end
            end
        end
    end

    cachedCompletedQuestXP = completedXP
    cachedActiveQuestXP = activeXP
    questLogXPDirty = false

    return completedXP, activeXP
end

----------------------------------------------------
-- XP BAR REFRESH LOGIC
----------------------------------------------------
function ns.UpdateXPBar()
    local db = WOWForeverAddonDB or ns.db
    if not db then return end

    local levelingEnabled = db.LevelingModuleEnabled
    if levelingEnabled == nil then levelingEnabled = ns.defaultSettings.LevelingModuleEnabled end

    local barEnabled = db.XPBarEnabled
    if barEnabled == nil then barEnabled = ns.defaultSettings.XPBarEnabled end

    if not levelingEnabled or not barEnabled then
        xpBar:Hide()
        SetBlizzardXPBarVisible(true)
        return
    end

    -- Suppress Blizzard default XP bar
    SetBlizzardXPBarVisible(false)

    local curLevel = UnitLevel("player") or 1
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 60

    if curLevel >= maxLevel then
        -- Player is max level: hide custom XP bar
        xpBar:Hide()
        return
    end

    xpBar:Show()

    -- Apply Saved Dimensions & Position
    local w = db.XPBarWidth or 500
    local h = db.XPBarHeight or 14
    xpBar:SetSize(w, h)

    if db.XPBarPosition and db.XPBarPosition.point then
        local pos = db.XPBarPosition
        xpBar:ClearAllPoints()
        xpBar:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 40)
    end

    -- Colors
    local cBase = db.XPBarColorBase or { r = 0, g = 0.82, b = 1 }
    local cRest = db.XPBarColorRested or { r = 1, g = 0.8, b = 0 }
    local cComp = db.XPBarColorCompletedQuest or { r = 0, g = 1, b = 0.53 }
    local cActv = db.XPBarColorActiveQuest or { r = 0.66, g = 0.4, b = 1 }

    texBase:SetColorTexture(cBase.r, cBase.g, cBase.b, 0.95)
    texRested:SetColorTexture(cRest.r, cRest.g, cRest.b, 0.6)
    texCompletedQuest:SetColorTexture(cComp.r, cComp.g, cComp.b, 0.75)
    texActiveQuest:SetColorTexture(cActv.r, cActv.g, cActv.b, 0.5)

    -- Calculation
    local currXP = UnitXP("player") or 0
    local maxXP = UnitXPMax("player") or 1
    if maxXP <= 0 then maxXP = 1 end

    local restedXP = GetXPExhaustion() or 0
    local completedQuestXP, activeQuestXP = GetQuestLogXPInfo()

    local usableWidth = math.max(1, w - 2)

    -- Base Current XP Width
    local basePct = math.min(1, math.max(0, currXP / maxXP))
    local basePx = math.floor(usableWidth * basePct)
    texBase:SetWidth(math.max(1, basePx))

    -- Completed Quests Overlay
    local showQuests = db.XPBarShowQuestOverlay
    if showQuests == nil then showQuests = ns.defaultSettings.XPBarShowQuestOverlay end

    if showQuests and completedQuestXP > 0 then
        local compPct = math.min(1 - basePct, completedQuestXP / maxXP)
        local compPx = math.floor(usableWidth * compPct)
        texCompletedQuest:SetWidth(math.max(0, compPx))
        texCompletedQuest:Show()
    else
        texCompletedQuest:SetWidth(0)
        texCompletedQuest:Hide()
    end

    -- Active Quests Overlay
    if showQuests and activeQuestXP > 0 then
        local compPct = math.min(1 - basePct, completedQuestXP / maxXP)
        local actvPct = math.min(1 - basePct - compPct, activeQuestXP / maxXP)
        local actvPx = math.floor(usableWidth * actvPct)
        texActiveQuest:SetWidth(math.max(0, actvPx))
        texActiveQuest:Show()
    else
        texActiveQuest:SetWidth(0)
        texActiveQuest:Hide()
    end

    -- Rested XP Overlay
    if restedXP > 0 then
        local restPct = math.min(1 - basePct, restedXP / maxXP)
        local restPx = math.floor(usableWidth * restPct)
        texRested:SetWidth(math.max(0, restPx))
        texRested:Show()
    else
        texRested:SetWidth(0)
        texRested:Hide()
    end

    -- Center Text
    local pctStr = string.format("%.1f%%", basePct * 100)
    local formattedCurr = BreakUpLargeNumbers and BreakUpLargeNumbers(currXP) or tostring(currXP)
    local formattedMax = BreakUpLargeNumbers and BreakUpLargeNumbers(maxXP) or tostring(maxXP)
    centerText:SetText(string.format("%s / %s (%s)", formattedCurr, formattedMax, pctStr))

    -- Analytics Badge
    local showStats = db.XPBarShowStats
    if showStats == nil then showStats = ns.defaultSettings.XPBarShowStats end

    if showStats then
        local now = time()
        local elapsed = math.max(1, now - sessionStartTime)
        local totalXP = currXP - sessionStartXP
        if curLevel > sessionStartLevel then
            totalXP = currXP + (maxXP * (curLevel - sessionStartLevel))
        end

        local xpHr = math.floor((totalXP / elapsed) * 3600)
        local xpNeeded = maxXP - currXP

        local ttlStr = "N/A"
        if xpHr > 0 then
            local secondsLeft = math.floor((xpNeeded / xpHr) * 3600)
            local hrs = math.floor(secondsLeft / 3600)
            local mins = math.floor((secondsLeft % 3600) / 60)
            if hrs > 0 then
                ttlStr = string.format("%dh %dm", hrs, mins)
            else
                ttlStr = string.format("%dm", mins)
            end
        end

        local formattedXpHr = BreakUpLargeNumbers and BreakUpLargeNumbers(xpHr) or tostring(xpHr)
        statsBadge:SetText(string.format("|cff00d2ffXP/hr:|r %s  |cff00ff88TTL:|r %s", formattedXpHr, ttlStr))
        statsBadge:Show()
    else
        statsBadge:Hide()
    end
end

----------------------------------------------------
-- TOOLTIP HOVER FOR XP BAR
----------------------------------------------------
xpBar:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()

    local currXP = UnitXP("player") or 0
    local maxXP = UnitXPMax("player") or 1
    local restedXP = GetXPExhaustion() or 0
    local completedQuestXP, activeQuestXP = GetQuestLogXPInfo()

    local fmt = BreakUpLargeNumbers or function(n) return tostring(n) end

    GameTooltip:AddLine("WOWForever Leveling Analytics", 0.85, 0.4, 1)
    GameTooltip:AddLine(" ")

    GameTooltip:AddDoubleLine("Current Level:", string.format("Level %d", UnitLevel("player")), 1, 1, 1, 0, 1, 0.8)
    GameTooltip:AddDoubleLine("Current Experience:", string.format("%s / %s (%.1f%%)", fmt(currXP), fmt(maxXP), (currXP/maxXP)*100), 1, 1, 1, 1, 1, 1)
    
    if restedXP > 0 then
        GameTooltip:AddDoubleLine("Rested Experience:", string.format("+%s (%.1f%%)", fmt(restedXP), (restedXP/maxXP)*100), 1, 0.8, 0, 1, 0.8, 0)
    end

    if completedQuestXP > 0 then
        GameTooltip:AddDoubleLine("Ready Quest Log XP:", string.format("+%s (%.1f%%)", fmt(completedQuestXP), (completedQuestXP/maxXP)*100), 0, 1, 0.53, 0, 1, 0.53)
    end

    if activeQuestXP > 0 then
        GameTooltip:AddDoubleLine("Total Quest Log XP:", string.format("+%s (%.1f%%)", fmt(activeQuestXP), (activeQuestXP/maxXP)*100), 0.66, 0.4, 1, 0.66, 0.4, 1)
    end

    local xpNeeded = maxXP - currXP
    GameTooltip:AddDoubleLine("XP Remaining to Level:", fmt(xpNeeded), 1, 0.3, 0.3, 1, 0.3, 0.3)

    if lastKillXP > 0 then
        local killsNeeded = math.ceil(xpNeeded / lastKillXP)
        GameTooltip:AddDoubleLine("Est. Mobs to Level (at " .. lastKillXP .. " XP/kill):", string.format("%d kills", killsNeeded), 0.7, 0.7, 0.7, 1, 1, 0)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("<Alt + Left-Click Drag to move XP Bar>", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)

xpBar:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

----------------------------------------------------
-- LEVEL UP CELEBRATION BANNER
----------------------------------------------------
local bannerFrame = CreateFrame("Frame", "WOWForeverLevelUpBanner", UIParent, ns.backdropTemplate)
bannerFrame:SetSize(420, 80)
bannerFrame:SetPoint("TOP", UIParent, "TOP", 0, -140)
bannerFrame:SetFrameStrata("HIGH")
bannerFrame:Hide()

ns.ApplyModernBackdrop(bannerFrame, 0.05, 0.02, 0.09, 0.95, 0.8, 0.6, 0.1, 0.9)

local bTitle = bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
bTitle:SetPoint("TOP", bannerFrame, "TOP", 0, -14)
bTitle:SetText("|cffffd100LEVEL UP!|r")

local bSub = bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bSub:SetPoint("TOP", bTitle, "BOTTOM", 0, -6)
bSub:SetText("Congratulations on reaching Level XX!")

local function ShowLevelUpBanner(newLevel)
    bSub:SetText(string.format("Congratulations on reaching |cff00ffffLevel %d|r!", newLevel))
    bannerFrame:SetAlpha(0)
    bannerFrame:Show()

    local elapsed = 0
    bannerFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed <= 0.5 then
            self:SetAlpha(elapsed / 0.5)
        elseif elapsed >= 3.5 and elapsed <= 4.0 then
            self:SetAlpha((4.0 - elapsed) / 0.5)
        elseif elapsed > 4.0 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)
end

----------------------------------------------------
-- EVENT LISTENERS
----------------------------------------------------
levelingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
levelingFrame:RegisterEvent("PLAYER_XP_UPDATE")
levelingFrame:RegisterEvent("PLAYER_LEVEL_UP")
levelingFrame:RegisterEvent("QUEST_LOG_UPDATE")
levelingFrame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")

levelingFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        questLogXPDirty = true
        sessionStartTime = time()
        sessionStartXP = UnitXP("player") or 0
        sessionStartLevel = UnitLevel("player") or 1
        ns.UpdateXPBar()
    elseif event == "QUEST_LOG_UPDATE" then
        questLogXPDirty = true
        ns.UpdateXPBar()
    elseif event == "PLAYER_XP_UPDATE" then
        ns.UpdateXPBar()
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local msg = ...
        if msg then
            local gain = tonumber(string.match(msg, "(%d+) %s*experience")) or tonumber(string.match(msg, "(%d+) %s*XP"))
            if gain and gain > 0 then
                lastKillXP = gain
            end
        end
        ns.UpdateXPBar()
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        sessionStartLevel = newLevel
        sessionStartXP = 0

        local db = WOWForeverAddonDB or ns.db
        if db and db.LevelUpBannerEnabled then
            ShowLevelUpBanner(newLevel)
        end

        if db and db.LevelUpScreenshot then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.6, function() Screenshot() end)
            end
        end

        ns.UpdateXPBar()
    end
end)

if ns.Log then ns.Log("MODULE_INIT", "LevelingFeatures module loaded successfully.") end
