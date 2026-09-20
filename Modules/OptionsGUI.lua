-- Modules/OptionsGUI.lua: Control Panel & Sidebar Navigation
-- Author: Antigravity

local ADDON_NAME, ns = ...

local optionsFrame = nil
local rowWidgets = {}
local qolWidgets = {}
local buffWidgets = {}
local minimapWidgets = {}
local levelingWidgets = {}
local actionBarWidgets = {}
local sidebarButtons = {}
local contentPanels = {}
local currentActivePage = 1
local p7Scroll = nil

-- Helper to style custom sleek scrollbars (hiding ugly Blizzard gold buttons)
function ns.StyleCustomScrollFrame(scrollFrame)
    local sbName = scrollFrame:GetName()
    local scrollBar = scrollFrame.ScrollBar or (sbName and _G[sbName .. "ScrollBar"])
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -18)
        scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 18)
        scrollBar:SetWidth(6)

        -- Hide ugly default Blizzard up/down arrow buttons
        local upBtn = scrollBar.ScrollUpButton or (sbName and _G[sbName .. "ScrollBarScrollUpButton"])
        local downBtn = scrollBar.ScrollDownButton or (sbName and _G[sbName .. "ScrollBarScrollDownButton"])
        if upBtn then upBtn:Hide() upBtn:SetSize(0.001, 0.001) end
        if downBtn then downBtn:Hide() downBtn:SetSize(0.001, 0.001) end

        -- Custom sleek violet thumb texture
        local thumb = (scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()) or (sbName and _G[sbName .. "ScrollBarThumbTexture"])
        if thumb then
            thumb:SetColorTexture(0.55, 0.2, 0.85, 0.8)
            thumb:SetWidth(6)
        end
    end
end

-- Helper to attach rich dark-amethyst contextual tooltips to option widgets
function ns.AttachOptionTooltip(widget, title, desc, note, defaultValue)
    if not widget then return end
    widget:EnableMouse(true)
    widget:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 6, -6)
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffda99ff" .. tostring(title) .. "|r", 1, 1, 1)
        if desc and desc ~= "" then
            GameTooltip:AddLine(desc, 0.9, 0.85, 0.95, true)
        end
        if note and note ~= "" then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("|cff9977bbHinweis:|r |cffffffff" .. tostring(note) .. "|r", 0.8, 0.7, 0.9, true)
        end
        if defaultValue ~= nil then
            local defStr = tostring(defaultValue)
            if type(defaultValue) == "boolean" then
                defStr = defaultValue and "|cff00ff88Aktiviert (True)|r" or "|cffff4466Deaktiviert (False)|r"
            elseif type(defaultValue) == "string" then
                defStr = "|cffe0b3ff" .. defaultValue .. "|r"
            end
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("|cff775599Standard:|r " .. defStr, 0.7, 0.6, 0.8)
        end
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
end

function ns.RefreshGUIOptions()
    local db = ns.db or WOWForeverAddonDB
    if not optionsFrame or not ns.isLoaded or not db then return end
    
    -- Page 1: BlizzUI
    for _, elem in ipairs(ns.UI_ELEMENTS) do
        local currentMode = WOWForeverAddonDB[elem.key]
        if currentMode == nil then currentMode = ns.defaultSettings[elem.key] or "SHOWN" end
        local widgets = rowWidgets[elem.key]
        if widgets then
            if widgets.shownBtn and widgets.shownBtn.UpdateState then widgets.shownBtn:UpdateState(currentMode == "SHOWN") end
            if widgets.hiddenBtn and widgets.hiddenBtn.UpdateState then widgets.hiddenBtn:UpdateState(currentMode == "HIDDEN") end
            if widgets.mouseoverBtn and widgets.mouseoverBtn.UpdateState then widgets.mouseoverBtn:UpdateState(currentMode == "MOUSEOVER") end
        end
    end

    -- Page 2: General QoL
    for _, feature in ipairs(ns.GENERAL_QOL_FEATURES) do
        local enabled = WOWForeverAddonDB[feature.key]
        if enabled == nil then enabled = ns.defaultSettings[feature.key] end
        local widget = qolWidgets[feature.key]
        if widget and widget.toggleBtn and widget.toggleBtn.UpdateState then
            widget.toggleBtn:UpdateState(enabled == true)
        end
    end

    -- Page 3: Buff & Pet Reminders
    if buffWidgets.buffMasterBtn and buffWidgets.buffMasterBtn.UpdateState then
        local bEnable = WOWForeverAddonDB.BuffReminder
        if bEnable == nil then bEnable = ns.defaultSettings.BuffReminder end
        buffWidgets.buffMasterBtn:UpdateState(bEnable == true)
    end
    if buffWidgets.petMasterBtn and buffWidgets.petMasterBtn.UpdateState then
        local pEnable = WOWForeverAddonDB.PetReminder
        if pEnable == nil then pEnable = ns.defaultSettings.PetReminder end
        buffWidgets.petMasterBtn:UpdateState(pEnable == true)
    end
    for spellKey, widget in pairs(buffWidgets.spells or {}) do
        local isDisabled = WOWForeverAddonDB.DisabledBuffs and WOWForeverAddonDB.DisabledBuffs[spellKey]
        if widget and widget.toggleBtn and widget.toggleBtn.UpdateState then
            widget.toggleBtn:UpdateState(not isDisabled)
        end
    end

    -- Page 4: Minimap HidingBar
    if minimapWidgets.enableBtn and minimapWidgets.enableBtn.UpdateState then
        local mEnable = WOWForeverAddonDB.MinimapBarEnabled
        if mEnable == nil then mEnable = ns.defaultSettings.MinimapBarEnabled end
        minimapWidgets.enableBtn:UpdateState(mEnable == true)
    end
    if minimapWidgets.orientationBtn then
        local isHoriz = (WOWForeverAddonDB.MinimapBarOrientation or "HORIZONTAL") == "HORIZONTAL"
        minimapWidgets.orientationBtn:SetText(isHoriz and "HORIZONTAL" or "VERTICAL")
    end
    if minimapWidgets.mouseoverBtn and minimapWidgets.mouseoverBtn.UpdateState then
        local isMouseover = WOWForeverAddonDB.MinimapBarMouseover
        if isMouseover == nil then isMouseover = ns.defaultSettings.MinimapBarMouseover end
        minimapWidgets.mouseoverBtn:UpdateState(isMouseover == true)
    end
    if minimapWidgets.snapBtn and minimapWidgets.snapBtn.UpdateState then
        local isSnap = WOWForeverAddonDB.MinimapBarSnapToEdge
        if isSnap == nil then isSnap = ns.defaultSettings.MinimapBarSnapToEdge end
        minimapWidgets.snapBtn:UpdateState(isSnap ~= false)
    end

    -- Page 6: Leveling Features
    if levelingWidgets.barEnableBtn and levelingWidgets.barEnableBtn.UpdateState then
        local e = WOWForeverAddonDB.XPBarEnabled
        if e == nil then e = ns.defaultSettings.XPBarEnabled end
        levelingWidgets.barEnableBtn:UpdateState(e == true)
    end
    if levelingWidgets.barStatsBtn and levelingWidgets.barStatsBtn.UpdateState then
        local s = WOWForeverAddonDB.XPBarShowStats
        if s == nil then s = ns.defaultSettings.XPBarShowStats end
        levelingWidgets.barStatsBtn:UpdateState(s == true)
    end
    if levelingWidgets.barQuestBtn and levelingWidgets.barQuestBtn.UpdateState then
        local q = WOWForeverAddonDB.XPBarShowQuestOverlay
        if q == nil then q = ns.defaultSettings.XPBarShowQuestOverlay end
        levelingWidgets.barQuestBtn:UpdateState(q == true)
    end
    if levelingWidgets.bannerBtn and levelingWidgets.bannerBtn.UpdateState then
        local b = WOWForeverAddonDB.LevelUpBannerEnabled
        if b == nil then b = ns.defaultSettings.LevelUpBannerEnabled end
        levelingWidgets.bannerBtn:UpdateState(b == true)
    end
    if levelingWidgets.screenshotBtn and levelingWidgets.screenshotBtn.UpdateState then
        local sc = WOWForeverAddonDB.LevelUpScreenshot
        if sc == nil then sc = ns.defaultSettings.LevelUpScreenshot end
        levelingWidgets.screenshotBtn:UpdateState(sc == true)
    end
    if ns.UpdateXPBar then ns.UpdateXPBar() end
    if ns.RefreshProfileGUI then ns.RefreshProfileGUI() end

    -- Page 9: Action Bars
    if actionBarWidgets.cleanIconsBtn and actionBarWidgets.cleanIconsBtn.UpdateState then
        local v = db.ActionBarCleanIcons
        if v == nil then v = ns.defaultSettings.ActionBarCleanIcons end
        actionBarWidgets.cleanIconsBtn:UpdateState(v ~= false)
    end
    if actionBarWidgets.hideGryphonsBtn and actionBarWidgets.hideGryphonsBtn.UpdateState then
        local v = db.ActionBarHideGryphons
        if v == nil then v = ns.defaultSettings.ActionBarHideGryphons end
        actionBarWidgets.hideGryphonsBtn:UpdateState(v ~= false)
    end
    if actionBarWidgets.modernBorderBtn and actionBarWidgets.modernBorderBtn.UpdateState then
        local v = db.ActionBarModernBorder
        if v == nil then v = ns.defaultSettings.ActionBarModernBorder end
        actionBarWidgets.modernBorderBtn:UpdateState(v ~= false)
    end
    if actionBarWidgets.shortHotkeysBtn and actionBarWidgets.shortHotkeysBtn.UpdateState then
        local v = db.ActionBarShortHotkeys
        if v == nil then v = ns.defaultSettings.ActionBarShortHotkeys end
        actionBarWidgets.shortHotkeysBtn:UpdateState(v ~= false)
    end
    if actionBarWidgets.hideHotkeysBtn and actionBarWidgets.hideHotkeysBtn.UpdateState then
        local v = db.ActionBarHideHotkeys
        if v == nil then v = ns.defaultSettings.ActionBarHideHotkeys end
        actionBarWidgets.hideHotkeysBtn:UpdateState(v == true)
    end
    if actionBarWidgets.hideMacroBtn and actionBarWidgets.hideMacroBtn.UpdateState then
        local v = db.ActionBarHideMacroNames
        if v == nil then v = ns.defaultSettings.ActionBarHideMacroNames end
        actionBarWidgets.hideMacroBtn:UpdateState(v == true)
    end
    if actionBarWidgets.showGridBtn and actionBarWidgets.showGridBtn.UpdateState then
        local v = db.ActionBarAlwaysShowEmptySlots
        if v == nil then v = db.ActionBarShowGrid end
        if v == nil then v = ns.defaultSettings.ActionBarAlwaysShowEmptySlots end
        actionBarWidgets.showGridBtn:UpdateState(v == true)
    end
    if actionBarWidgets.spacingSlider then
        local v = db.ActionBarSpacing or ns.defaultSettings.ActionBarSpacing or 4
        actionBarWidgets.spacingSlider:SetValue(v)
    end
    if actionBarWidgets.scaleSlider then
        local v = db.ActionBarButtonScale or ns.defaultSettings.ActionBarButtonScale or 1.0
        actionBarWidgets.scaleSlider:SetValue(v)
    end
    if actionBarWidgets.slotBgAlphaSlider then
        local v = db.ActionBarSlotBgAlpha or ns.defaultSettings.ActionBarSlotBgAlpha or 0.85
        actionBarWidgets.slotBgAlphaSlider:SetValue(v)
    end
    if ns.RefreshActionBarModernizer then ns.RefreshActionBarModernizer() end
end


-- Modular Page Builders (Prevents Lua 200 local variable limit)

local function CreatePage1(contentArea)
----------------------------------------------------
-- PAGE 1: BLIZZUI DISPLAY SETTINGS
----------------------------------------------------
local p1 = CreateFrame("Frame", nil, contentArea)
p1:SetAllPoints()
contentPanels[1] = p1

local p1Header = CreateFrame("Frame", nil, p1, ns.backdropTemplate)
p1Header:SetPoint("TOPLEFT", p1, "TOPLEFT", 0, 0)
p1Header:SetPoint("TOPRIGHT", p1, "TOPRIGHT", -20, 0)
p1Header:SetHeight(24)
ns.ApplyModernBackdrop(p1Header, 0.08, 0.05, 0.13, 0.9, 0.3, 0.14, 0.48, 0.7)

local hElem = p1Header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hElem:SetPoint("LEFT", p1Header, "LEFT", 12, 0)
hElem:SetText("|cffc866ffBLIZZARD UI ELEMENT|r")

local hShown = p1Header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hShown:SetPoint("RIGHT", p1Header, "RIGHT", -160, 0)
hShown:SetText("|cffbf55ffShown|r")

local hHidden = p1Header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hHidden:SetPoint("RIGHT", p1Header, "RIGHT", -92, 0)
hHidden:SetText("|cffff4466Hidden|r")

local hMouseover = p1Header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hMouseover:SetPoint("RIGHT", p1Header, "RIGHT", -16, 0)
hMouseover:SetText("|cffaa66ffMouseover|r")

local p1Scroll = CreateFrame("ScrollFrame", "WOWForeverP1ScrollFrame", p1, "UIPanelScrollFrameTemplate")
p1Scroll:SetPoint("TOPLEFT", p1Header, "BOTTOMLEFT", 0, -4)
p1Scroll:SetPoint("BOTTOMRIGHT", p1, "BOTTOMRIGHT", -10, 0)
ns.StyleCustomScrollFrame(p1Scroll)

local p1Content = CreateFrame("Frame", "WOWForeverP1Content", p1Scroll)
p1Content:SetSize(460, #ns.BLIZZ_UI_ELEMENTS * 34 + 10)
p1Scroll:SetScrollChild(p1Content)
    p1.content = p1Content

local rowFrames = {}
for i, elem in ipairs(ns.BLIZZ_UI_ELEMENTS) do
    local row = CreateFrame("Frame", nil, p1Content, ns.backdropTemplate)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", p1Content, "TOPLEFT", 0, -(i - 1) * 34)
    row:SetPoint("TOPRIGHT", p1Content, "TOPRIGHT", -6, -(i - 1) * 34)
    table.insert(rowFrames, row)

    local isEven = (i % 2 == 0)
    ns.ApplyModernBackdrop(row, isEven and 0.08 or 0.05, isEven and 0.05 or 0.03, isEven and 0.12 or 0.08, 0.6, 0.22, 0.1, 0.35, 0.4)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 12, 0)
    label:SetText(elem.name)

    local function CreatePillButton(xOffset, mode, activeColor, activeLabel)
        local btn = CreateFrame("Button", nil, row, ns.backdropTemplate)
        btn:SetSize(68, 22)
        btn:SetPoint("RIGHT", row, "RIGHT", xOffset, 0)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(mode:sub(1,1) .. mode:sub(2):lower())

        btn.UpdateState = function(self, isActive)
            if isActive then
                ns.ApplyModernBackdrop(btn, activeColor[1], activeColor[2], activeColor[3], 0.9, activeColor[1]*1.4, activeColor[2]*1.4, activeColor[3]*1.4, 1)
                btnText:SetText("|cffffffff" .. activeLabel .. "|r")
            else
                ns.ApplyModernBackdrop(btn, 0.1, 0.06, 0.16, 0.6, 0.2, 0.1, 0.3, 0.5)
                btnText:SetText("|cff8866aa" .. mode:sub(1,1) .. mode:sub(2):lower() .. "|r")
            end
        end

        btn:SetScript("OnClick", function()
            WOWForeverAddonDB[elem.key] = mode
            if ns.Log then ns.Log("GUI_CLICK", "Set " .. tostring(elem.key) .. " = " .. tostring(mode)) end
            ns.ApplyFrameState(elem.key, mode)
            ns.RefreshGUIOptions()
        end)

        return btn
    end

    local shownBtn = CreatePillButton(-146, "SHOWN", {0.45, 0.15, 0.7}, "Shown")
    local hiddenBtn = CreatePillButton(-74, "HIDDEN", {0.55, 0.1, 0.25}, "Hidden")
    local mouseoverBtn = CreatePillButton(-2, "MOUSEOVER", {0.6, 0.25, 0.15}, "Mouseover")

    rowWidgets[elem.key] = {
        shownBtn = shownBtn,
        hiddenBtn = hiddenBtn,
        mouseoverBtn = mouseoverBtn,
    }
    ns.AttachOptionTooltip(row, elem.name, "Steuert die Anzeige dieses Interface-Elements.", "Shown = dauerhaft sichtbar, Hidden = ausgeblendet, Mouseover = nur bei Berührung mit der Maus sichtbar.", ns.defaultSettings[elem.key])
end

----------------------------------------------------

end

local function CreatePage2(contentArea)
-- PAGE 2: GENERAL QOL SETTINGS
----------------------------------------------------
local p2 = CreateFrame("Frame", nil, contentArea)
p2:SetAllPoints()
p2:Hide()
contentPanels[2] = p2

local p2Scroll = CreateFrame("ScrollFrame", "WOWForeverP2ScrollFrame", p2, "UIPanelScrollFrameTemplate")
p2Scroll:SetPoint("TOPLEFT", p2, "TOPLEFT", 0, 0)
p2Scroll:SetPoint("BOTTOMRIGHT", p2, "BOTTOMRIGHT", -10, 0)
ns.StyleCustomScrollFrame(p2Scroll)

local p2Content = CreateFrame("Frame", "WOWForeverP2Content", p2Scroll)
p2Content:SetSize(460, #ns.GENERAL_QOL_FEATURES * 65 + 10)
p2Scroll:SetScrollChild(p2Content)
    p2.content = p2Content

for i, feature in ipairs(ns.GENERAL_QOL_FEATURES) do
    local card = CreateFrame("Frame", nil, p2Content, ns.backdropTemplate)
    card:SetSize(455, 56)
    card:SetPoint("TOPLEFT", p2Content, "TOPLEFT", 0, -(i - 1) * 62)

    ns.ApplyModernBackdrop(card, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

    local fName = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fName:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -10)
    fName:SetText("|cffda99ff" .. feature.name .. "|r")

    local fDesc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fDesc:SetPoint("TOPLEFT", fName, "BOTTOMLEFT", 0, -4)
    fDesc:SetPoint("RIGHT", card, "RIGHT", -100, 0)
    fDesc:SetText("|cffa388cc" .. feature.desc .. "|r")
    fDesc:SetJustifyH("LEFT")

    local toggleBtn = CreateFrame("Button", nil, card, ns.backdropTemplate)
    toggleBtn:SetSize(80, 24)
    toggleBtn:SetPoint("RIGHT", card, "RIGHT", -12, 0)

    local toggleText = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleText:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)

    toggleBtn.UpdateState = function(self, isEnabled)
        if isEnabled then
            ns.ApplyModernBackdrop(toggleBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
            toggleText:SetText("|cffffffffENABLED|r")
        else
            ns.ApplyModernBackdrop(toggleBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
            toggleText:SetText("|cff8866aaDISABLED|r")
        end
    end

    toggleBtn:SetScript("OnClick", function()
        local cur = WOWForeverAddonDB[feature.key]
        if cur == nil then cur = ns.defaultSettings[feature.key] end
        local newVal = not cur
        WOWForeverAddonDB[feature.key] = newVal
        if ns.Log then ns.Log("GUI_CLICK", "Set " .. tostring(feature.key) .. " = " .. tostring(newVal)) end
        if feature.key == "MaxCameraZoom" then
            SetCVar("cameraDistanceMaxZoomFactor", newVal and 2.6 or 1.9)
        elseif feature.key == "ChatClassColors" or feature.key == "ChatShortChannels" then
            if ns.UpdateChatSettings then ns.UpdateChatSettings() end
        elseif feature.key == "QuestNameplateHighlight" then
            if ns.RefreshQuestNameplates then ns.RefreshQuestNameplates() end
        end
        ns.RefreshGUIOptions()
    end)

    qolWidgets[feature.key] = { card = card, toggleBtn = toggleBtn }
    ns.AttachOptionTooltip(card, feature.name, feature.desc, "Klicke den Schalter rechts, um die Funktion ein- oder auszuschalten.", ns.defaultSettings[feature.key])
end

----------------------------------------------------

end

local function CreatePage3(contentArea)
-- PAGE 3: BUFF & PET REMINDERS PAGE
----------------------------------------------------
local p3 = CreateFrame("Frame", nil, contentArea)
p3:SetAllPoints()
p3:Hide()
contentPanels[3] = p3

local p3Scroll = CreateFrame("ScrollFrame", "WOWForeverP3ScrollFrame", p3, "UIPanelScrollFrameTemplate")
p3Scroll:SetPoint("TOPLEFT", p3, "TOPLEFT", 0, 0)
p3Scroll:SetPoint("BOTTOMRIGHT", p3, "BOTTOMRIGHT", -10, 0)
ns.StyleCustomScrollFrame(p3Scroll)

local p3Content = CreateFrame("Frame", "WOWForeverP3Content", p3Scroll)
p3Content:SetSize(460, 480)
p3Scroll:SetScrollChild(p3Content)
    p3.content = p3Content

-- Master Toggle 1: Buff Reminder
local bCard1 = CreateFrame("Frame", nil, p3Content, ns.backdropTemplate)
bCard1:SetSize(455, 56)
bCard1:SetPoint("TOPLEFT", p3Content, "TOPLEFT", 0, 0)
ns.ApplyModernBackdrop(bCard1, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local bc1Title = bCard1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bc1Title:SetPoint("TOPLEFT", bCard1, "TOPLEFT", 14, -10)
bc1Title:SetText("|cffda99ffClass Buff Reminder HUD|r")

local bc1Desc = bCard1:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bc1Desc:SetPoint("TOPLEFT", bc1Title, "BOTTOMLEFT", 0, -4)
bc1Desc:SetText("|cffa388ccEnables interactive HUD icons when self-buffs or poisons are missing.|r")

local bMasterBtn = CreateFrame("Button", nil, bCard1, ns.backdropTemplate)
bMasterBtn:SetSize(80, 24)
bMasterBtn:SetPoint("RIGHT", bCard1, "RIGHT", -12, 0)
local bMasterText = bMasterBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bMasterText:SetPoint("CENTER", bMasterBtn, "CENTER", 0, 0)
bMasterBtn.UpdateState = function(self, isEnabled)
    if isEnabled then
        ns.ApplyModernBackdrop(bMasterBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
        bMasterText:SetText("|cffffffffENABLED|r")
    else
        ns.ApplyModernBackdrop(bMasterBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
        bMasterText:SetText("|cff8866aaDISABLED|r")
    end
end
bMasterBtn:SetScript("OnClick", function()
    WOWForeverAddonDB.BuffReminder = not WOWForeverAddonDB.BuffReminder
    ns.RefreshGUIOptions()
    if ns.UpdateHUD then ns.UpdateHUD() end
end)
buffWidgets.buffMasterBtn = bMasterBtn
ns.AttachOptionTooltip(bCard1, "Buff Reminder HUD", "Blendet interaktive Symbole auf dem Bildschirm ein, wenn wichtige Klassenbuffs auf deinem Charakter fehlen.", "Ein Klick auf das HUD-Symbol zaubert den fehlenden Buff direkt nach.", true)

-- Master Toggle 2: Pet Reminder
local bCard2 = CreateFrame("Frame", nil, p3Content, ns.backdropTemplate)
bCard2:SetSize(455, 56)
bCard2:SetPoint("TOPLEFT", bCard1, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(bCard2, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local bc2Title = bCard2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bc2Title:SetPoint("TOPLEFT", bCard2, "TOPLEFT", 14, -10)
bc2Title:SetText("|cffda99ffPet Class Reminder HUD|r")

local bc2Desc = bCard2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bc2Desc:SetPoint("TOPLEFT", bc2Title, "BOTTOMLEFT", 0, -4)
bc2Desc:SetText("|cffa388ccEnables interactive HUD icons when class pet is missing or dead.|r")

local pMasterBtn = CreateFrame("Button", nil, bCard2, ns.backdropTemplate)
pMasterBtn:SetSize(80, 24)
pMasterBtn:SetPoint("RIGHT", bCard2, "RIGHT", -12, 0)
local pMasterText = pMasterBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
pMasterText:SetPoint("CENTER", pMasterBtn, "CENTER", 0, 0)
pMasterBtn.UpdateState = function(self, isEnabled)
    if isEnabled then
        ns.ApplyModernBackdrop(pMasterBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
        pMasterText:SetText("|cffffffffENABLED|r")
    else
        ns.ApplyModernBackdrop(pMasterBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
        pMasterText:SetText("|cff8866aaDISABLED|r")
    end
end
pMasterBtn:SetScript("OnClick", function()
    WOWForeverAddonDB.PetReminder = not WOWForeverAddonDB.PetReminder
    ns.RefreshGUIOptions()
    if ns.UpdateHUD then ns.UpdateHUD() end
end)
buffWidgets.petMasterBtn = pMasterBtn
ns.AttachOptionTooltip(bCard2, "Pet Reminder HUD", "Blendet ein dezentes Begleiter-Symbol ein, wenn dein Klassen-Pet (Jäger / Hexenmeister) nicht aktiv oder tot ist.", "Klicke das Symbol an, um deinen Begleiter sofort zu rufen.", true)

-- Class Specific Granular Trackers Header
local spellHeader = CreateFrame("Frame", nil, p3Content, ns.backdropTemplate)
spellHeader:SetSize(455, 24)
spellHeader:SetPoint("TOPLEFT", bCard2, "BOTTOMLEFT", 0, -12)
ns.ApplyModernBackdrop(spellHeader, 0.12, 0.06, 0.2, 0.9, 0.35, 0.16, 0.55, 0.8)

local shText = spellHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
shText:SetPoint("LEFT", spellHeader, "LEFT", 12, 0)
shText:SetText("|cffc866ffGRANULAR BUFF & SPELL SELECTION FOR YOUR CLASS|r")

buffWidgets.spells = {}
local _, pClass = UnitClass("player")
local cConf = ns.CLASS_SPELL_CONFIG[pClass]
local spellIndex = 0

local function AddSpellToggleRow(spellKey, spellName, iconTexture)
    spellIndex = spellIndex + 1
    local row = CreateFrame("Frame", nil, p3Content, ns.backdropTemplate)
    row:SetSize(455, 40)
    row:SetPoint("TOPLEFT", spellHeader, "BOTTOMLEFT", 0, -8 - (spellIndex - 1) * 46)
    ns.ApplyModernBackdrop(row, 0.06, 0.04, 0.1, 0.6, 0.2, 0.1, 0.3, 0.5)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", row, "LEFT", 10, 0)
    icon:SetTexture(iconTexture)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    label:SetText(spellName)

    local tBtn = CreateFrame("Button", nil, row, ns.backdropTemplate)
    tBtn:SetSize(75, 22)
    tBtn:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    local tTxt = tBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tTxt:SetPoint("CENTER", tBtn, "CENTER", 0, 0)

    tBtn.UpdateState = function(self, isTracked)
        if isTracked then
            ns.ApplyModernBackdrop(tBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
            tTxt:SetText("|cffffffffTRACKED|r")
        else
            ns.ApplyModernBackdrop(tBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
            tTxt:SetText("|cff8866aaOFF|r")
        end
    end

    tBtn:SetScript("OnClick", function()
        WOWForeverAddonDB.DisabledBuffs = WOWForeverAddonDB.DisabledBuffs or {}
        local curDisabled = WOWForeverAddonDB.DisabledBuffs[spellKey]
        WOWForeverAddonDB.DisabledBuffs[spellKey] = not curDisabled
        ns.RefreshGUIOptions()
        if ns.UpdateHUD then ns.UpdateHUD() end
    end)

    buffWidgets.spells[spellKey] = { row = row, toggleBtn = tBtn }
    ns.AttachOptionTooltip(row, spellName, "Aktiviert oder deaktiviert die visuelle Erinnerung für diesen spezifischen Klassen-Zauber.", nil, true)
end

if cConf then
    if cConf.buffs then
        for _, b in ipairs(cConf.buffs) do
            local tex = b.texture or ns.GetSpellIconTexture(b.spell)
            AddSpellToggleRow(b.spell, b.spell, tex)
        end
    end
    if cConf.pet then
        local tex = cConf.petIcon or ns.GetSpellIconTexture(cConf.pet)
        AddSpellToggleRow(cConf.pet, cConf.pet, tex)
    end
end
if pClass == "ROGUE" then
    AddSpellToggleRow("Deadly Poison", "Weapon Poison Tracking", "Interface\\Icons\\Ability_PoisonousStab")
end

----------------------------------------------------

end

local function CreatePage4(contentArea)
-- PAGE 4: MINIMAP HIDINGBAR CONFIG PAGE
----------------------------------------------------
local p4 = CreateFrame("Frame", nil, contentArea)
p4:SetAllPoints()
p4:Hide()
contentPanels[4] = p4

local p4Scroll = CreateFrame("ScrollFrame", "WOWForeverP4ScrollFrame", p4, "UIPanelScrollFrameTemplate")
p4Scroll:SetPoint("TOPLEFT", p4, "TOPLEFT", 0, 0)
p4Scroll:SetPoint("BOTTOMRIGHT", p4, "BOTTOMRIGHT", -10, 0)
ns.StyleCustomScrollFrame(p4Scroll)

local p4Content = CreateFrame("Frame", "WOWForeverP4Content", p4Scroll)
p4Content:SetSize(460, 440)
p4Scroll:SetScrollChild(p4Content)
    p4.content = p4Content

-- Card 1: Enable / Disable
local mCard1 = CreateFrame("Frame", nil, p4Content, ns.backdropTemplate)
mCard1:SetSize(455, 60)
mCard1:SetPoint("TOPLEFT", p4Content, "TOPLEFT", 0, 0)
ns.ApplyModernBackdrop(mCard1, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local mc1Title = mCard1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mc1Title:SetPoint("TOPLEFT", mCard1, "TOPLEFT", 14, -10)
mc1Title:SetText("|cffda99ffMinimap Addon Button Bar|r")

local mc1Desc = mCard1:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mc1Desc:SetPoint("TOPLEFT", mc1Title, "BOTTOMLEFT", 0, -4)
mc1Desc:SetText("|cffa388ccCollects all third-party addon minimap icons into a single movable bar.|r")

local mEnableBtn = CreateFrame("Button", nil, mCard1, ns.backdropTemplate)
mEnableBtn:SetSize(90, 24)
mEnableBtn:SetPoint("RIGHT", mCard1, "RIGHT", -12, 0)
local mEnableText = mEnableBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mEnableText:SetPoint("CENTER", mEnableBtn, "CENTER", 0, 0)

mEnableBtn.UpdateState = function(self, isEnabled)
    if isEnabled then
        ns.ApplyModernBackdrop(mEnableBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
        mEnableText:SetText("|cffffffffENABLED|r")
    else
        ns.ApplyModernBackdrop(mEnableBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
        mEnableText:SetText("|cff8866aaDISABLED|r")
    end
end
mEnableBtn:SetScript("OnClick", function()
    WOWForeverAddonDB.MinimapBarEnabled = not WOWForeverAddonDB.MinimapBarEnabled
    ns.RefreshGUIOptions()
    if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
end)
minimapWidgets.enableBtn = mEnableBtn
ns.AttachOptionTooltip(mCard1, "Minimap Addon Button Bar", "Sammelt alle Minimap-Symbole fremder Addons automatisch in einer sauberen, frei verschiebbaren Leiste.", "Verhindert das Überladen der Minimap mit unzähligen Addon-Icons.", true)

-- Card 2: Layout Orientation
local mCard2 = CreateFrame("Frame", nil, p4Content, ns.backdropTemplate)
mCard2:SetSize(455, 60)
mCard2:SetPoint("TOPLEFT", mCard1, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(mCard2, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local mc2Title = mCard2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mc2Title:SetPoint("TOPLEFT", mCard2, "TOPLEFT", 14, -10)
mc2Title:SetText("|cffda99ffBar Orientation|r")

local mc2Desc = mCard2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mc2Desc:SetPoint("TOPLEFT", mc2Title, "BOTTOMLEFT", 0, -4)
mc2Desc:SetText("|cffa388ccChoose whether the minimap bar expands horizontally or vertically.|r")

local mOrientBtn = CreateFrame("Button", nil, mCard2, ns.backdropTemplate)
mOrientBtn:SetSize(110, 24)
mOrientBtn:SetPoint("RIGHT", mCard2, "RIGHT", -12, 0)
ns.ApplyModernBackdrop(mOrientBtn, 0.25, 0.1, 0.4, 0.8, 0.45, 0.2, 0.7, 0.9)
local mOrientText = mOrientBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mOrientText:SetPoint("CENTER", mOrientBtn, "CENTER", 0, 0)
mOrientBtn.SetText = function(self, txt) mOrientText:SetText("|cffffffff" .. txt .. "|r") end

mOrientBtn:SetScript("OnClick", function()
    local cur = WOWForeverAddonDB.MinimapBarOrientation or "HORIZONTAL"
    WOWForeverAddonDB.MinimapBarOrientation = (cur == "HORIZONTAL") and "VERTICAL" or "HORIZONTAL"
    ns.RefreshGUIOptions()
    if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
end)
minimapWidgets.orientationBtn = mOrientBtn
ns.AttachOptionTooltip(mCard2, "Bar Orientation", "Schaltet das Layout der gesammelten Minimap-Buttons zwischen horizontaler und vertikaler Ausrichtung um.", nil, "VERTICAL")

-- Card 3: Display Mode (Mouseover Reveal vs Always Shown)
local mCard3 = CreateFrame("Frame", nil, p4Content, ns.backdropTemplate)
mCard3:SetSize(455, 60)
mCard3:SetPoint("TOPLEFT", mCard2, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(mCard3, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local mc3Title = mCard3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mc3Title:SetPoint("TOPLEFT", mCard3, "TOPLEFT", 14, -10)
mc3Title:SetText("|cffda99ffMouseover Reveal Mode (HidingBar Style)|r")

local mc3Desc = mCard3:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mc3Desc:SetPoint("TOPLEFT", mc3Title, "BOTTOMLEFT", 0, -4)
mc3Desc:SetText("|cffa388ccOnly reveal the minimap bar when hovering mouse over it.|r")

local mMouseoverBtn = CreateFrame("Button", nil, mCard3, ns.backdropTemplate)
mMouseoverBtn:SetSize(110, 24)
mMouseoverBtn:SetPoint("RIGHT", mCard3, "RIGHT", -12, 0)
local mMouseoverText = mMouseoverBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mMouseoverText:SetPoint("CENTER", mMouseoverBtn, "CENTER", 0, 0)

mMouseoverBtn.UpdateState = function(self, isEnabled)
    if isEnabled then
        ns.ApplyModernBackdrop(mMouseoverBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
        mMouseoverText:SetText("|cffffffffMOUSEOVER|r")
    else
        ns.ApplyModernBackdrop(mMouseoverBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
        mMouseoverText:SetText("|cff8866aaALWAYS SHOWN|r")
    end
end
mMouseoverBtn:SetScript("OnClick", function()
    WOWForeverAddonDB.MinimapBarMouseover = not WOWForeverAddonDB.MinimapBarMouseover
    ns.RefreshGUIOptions()
    if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
end)
minimapWidgets.mouseoverBtn = mMouseoverBtn
ns.AttachOptionTooltip(mCard3, "Mouseover Reveal Mode", "Macht die Addon-Leiste unsichtbar, bis du mit dem Mauszeiger darüber fährst (HidingBar-Stil).", nil, true)

-- Card 4: Screen Edge Snapping Toggle
local mCardSnap = CreateFrame("Frame", nil, p4Content, ns.backdropTemplate)
mCardSnap:SetSize(455, 60)
mCardSnap:SetPoint("TOPLEFT", mCard3, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(mCardSnap, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local mcSnapTitle = mCardSnap:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mcSnapTitle:SetPoint("TOPLEFT", mCardSnap, "TOPLEFT", 14, -10)
mcSnapTitle:SetText("|cffda99ffSnap to Screen Edges|r")

local mcSnapDesc = mCardSnap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mcSnapDesc:SetPoint("TOPLEFT", mcSnapTitle, "BOTTOMLEFT", 0, -4)
mcSnapDesc:SetText("|cffa388ccAutomatically snap bar to screen edge when dragged near it.|r")

local mSnapBtn = CreateFrame("Button", nil, mCardSnap, ns.backdropTemplate)
mSnapBtn:SetSize(110, 24)
mSnapBtn:SetPoint("RIGHT", mCardSnap, "RIGHT", -12, 0)
local mSnapText = mSnapBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mSnapText:SetPoint("CENTER", mSnapBtn, "CENTER", 0, 0)

mSnapBtn.UpdateState = function(self, isEnabled)
    if isEnabled then
        ns.ApplyModernBackdrop(mSnapBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
        mSnapText:SetText("|cffffffffENABLED|r")
    else
        ns.ApplyModernBackdrop(mSnapBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
        mSnapText:SetText("|cff8866aaDISABLED|r")
    end
end
mSnapBtn:SetScript("OnClick", function()
    WOWForeverAddonDB.MinimapBarSnapToEdge = not (WOWForeverAddonDB.MinimapBarSnapToEdge ~= false)
    ns.RefreshGUIOptions()
end)
minimapWidgets.snapBtn = mSnapBtn
ns.AttachOptionTooltip(mCardSnap, "Snap to Screen Edges", "Lässt die Leiste automatisch am linken oder rechten Bildschirmrand magnetisch einrasten.", nil, true)

-- Card 5: Position Reset
local mCard4 = CreateFrame("Frame", nil, p4Content, ns.backdropTemplate)
mCard4:SetSize(455, 60)
mCard4:SetPoint("TOPLEFT", mCardSnap, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(mCard4, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local mc4Title = mCard4:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mc4Title:SetPoint("TOPLEFT", mCard4, "TOPLEFT", 14, -10)
mc4Title:SetText("|cffda99ffReset Minimap Bar Position|r")

local mc4Desc = mCard4:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mc4Desc:SetPoint("TOPLEFT", mc4Title, "BOTTOMLEFT", 0, -4)
mc4Desc:SetText("|cffa388ccReset the minimap collector bar back to top right anchor.|r")

local mResetBtn = CreateFrame("Button", nil, mCard4, ns.backdropTemplate)
mResetBtn:SetSize(110, 24)
mResetBtn:SetPoint("RIGHT", mCard4, "RIGHT", -12, 0)
ns.ApplyModernBackdrop(mResetBtn, 0.18, 0.09, 0.28, 0.8, 0.35, 0.16, 0.5, 0.8)

local mResetText = mResetBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mResetText:SetPoint("CENTER", mResetBtn, "CENTER", 0, 0)
mResetText:SetText("|cffe0b3ffReset Position|r")

mResetBtn:SetScript("OnClick", function()
    WOWForeverAddonDB.MinimapBarPosition = nil
    if WOWForeverMinimapBarFrame then
        WOWForeverMinimapBarFrame:ClearAllPoints()
        WOWForeverMinimapBarFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -300)
    end
    print("|cffc866ff[WOWForeverAddon]|r Minimap collector bar position reset.")
end)
ns.AttachOptionTooltip(mCard4, "Reset Position", "Setzt die Position der Leiste auf den Standard-Ankerpunkt oben rechts zurück.", nil, nil)

----------------------------------------------------

end

local function CreatePage5(contentArea)
-- PAGE 5: DEBUG LOGS & DATABASE DIAGNOSTICS
----------------------------------------------------
local p5 = CreateFrame("Frame", nil, contentArea)
p5:SetAllPoints()
p5:Hide()
contentPanels[5] = p5

local dCard = CreateFrame("Frame", nil, p5, ns.backdropTemplate)
dCard:SetPoint("TOPLEFT", p5, "TOPLEFT", 0, 0)
dCard:SetPoint("TOPRIGHT", p5, "TOPRIGHT", -10, 0)
dCard:SetHeight(50)
ns.ApplyModernBackdrop(dCard, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local btnRefresh = CreateFrame("Button", nil, dCard, ns.backdropTemplate)
btnRefresh:SetSize(90, 22)
btnRefresh:SetPoint("RIGHT", dCard, "RIGHT", -12, 0)
ns.ApplyModernBackdrop(btnRefresh, 0.25, 0.1, 0.4, 0.8, 0.45, 0.2, 0.7, 0.9)
local tRef = btnRefresh:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tRef:SetPoint("CENTER", btnRefresh, "CENTER", 0, 0)
tRef:SetText("|cffffffffRefresh All|r")

local btnClear = CreateFrame("Button", nil, dCard, ns.backdropTemplate)
btnClear:SetSize(80, 22)
btnClear:SetPoint("RIGHT", btnRefresh, "LEFT", -6, 0)
ns.ApplyModernBackdrop(btnClear, 0.18, 0.09, 0.28, 0.8, 0.35, 0.16, 0.5, 0.8)
local tClr = btnClear:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tClr:SetPoint("CENTER", btnClear, "CENTER", 0, 0)
tClr:SetText("|cffe0b3ffClear Logs|r")

local btnCopyLogs = CreateFrame("Button", nil, dCard, ns.backdropTemplate)
btnCopyLogs:SetSize(95, 22)
btnCopyLogs:SetPoint("RIGHT", btnClear, "LEFT", -6, 0)
ns.ApplyModernBackdrop(btnCopyLogs, 0.2, 0.12, 0.35, 0.8, 0.5, 0.25, 0.8, 0.9)
local tCopyLogs = btnCopyLogs:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tCopyLogs:SetPoint("CENTER", btnCopyLogs, "CENTER", 0, 0)
tCopyLogs:SetText("|cffffffffCopy All Logs|r")

local dTitle = dCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
dTitle:SetPoint("TOPLEFT", dCard, "TOPLEFT", 14, -8)
dTitle:SetPoint("RIGHT", btnCopyLogs, "LEFT", -10, 0)
dTitle:SetJustifyH("LEFT")
dTitle:SetText("|cffda99ffDebug Diagnostic Feed & DB Inspector|r")

local dDesc = dCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
dDesc:SetPoint("TOPLEFT", dTitle, "BOTTOMLEFT", 0, -3)
dDesc:SetPoint("RIGHT", btnCopyLogs, "LEFT", -10, 0)
dDesc:SetJustifyH("LEFT")
dDesc:SetText("|cffa388ccSelect & copy logs or raw DB dump with Ctrl+A, Ctrl+C.|r")

-- Event Logs Scroll Container
local logFrame = CreateFrame("Frame", nil, p5, ns.backdropTemplate)
logFrame:SetPoint("TOPLEFT", dCard, "BOTTOMLEFT", 0, -8)
logFrame:SetPoint("TOPRIGHT", dCard, "BOTTOMRIGHT", 0, -8)
logFrame:SetHeight(180)
ns.ApplyModernBackdrop(logFrame, 0.04, 0.02, 0.07, 0.9, 0.2, 0.1, 0.35, 0.5)

local logScroll = CreateFrame("ScrollFrame", "WOWForeverLogScrollFrame", logFrame, "UIPanelScrollFrameTemplate")
logScroll:SetPoint("TOPLEFT", logFrame, "TOPLEFT", 8, -6)
logScroll:SetPoint("BOTTOMRIGHT", logFrame, "BOTTOMRIGHT", -26, 6)
ns.StyleCustomScrollFrame(logScroll)

local logEditBox = CreateFrame("EditBox", "WOWForeverLogEditBox", logScroll)
logEditBox:SetMultiLine(true)
logEditBox:SetMaxLetters(999999)
logEditBox:SetFontObject("GameFontHighlightSmall")
logEditBox:SetWidth(420)
logEditBox:SetAutoFocus(false)
logEditBox:EnableMouse(true)
logScroll:SetScrollChild(logEditBox)

logEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

ns.RefreshLogView = function()
    if logEditBox and ns.logs then
        logEditBox:SetText(table.concat(ns.logs, "\n"))
        local count = #ns.logs
        logEditBox:SetHeight(math.max(180, count * 14 + 30))
    end
end

btnCopyLogs:SetScript("OnClick", function()
    if logEditBox then
        logEditBox:SetFocus()
        logEditBox:HighlightText()
        print("|cffc866ff[WOWForeverAddon]|r All logs highlighted! Press |cffda99ffCtrl+C|r to copy.")
    end
end)

-- Raw DB EditBox Dump & Controls
local dbHeader = p5:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dbHeader:SetPoint("TOPLEFT", logFrame, "BOTTOMLEFT", 0, -8)
dbHeader:SetText("|cffc866ffRAW SAVEDVARIABLES DATABASE DUMP:|r")

local btnRestoreDump = CreateFrame("Button", nil, p5, ns.backdropTemplate)
btnRestoreDump:SetSize(130, 20)
btnRestoreDump:SetPoint("TOPRIGHT", p5, "TOPRIGHT", -10, -244)
ns.ApplyModernBackdrop(btnRestoreDump, 0.15, 0.35, 0.2, 0.85, 0.3, 0.8, 0.4, 0.9)
local tRestore = btnRestoreDump:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tRestore:SetPoint("CENTER", btnRestoreDump, "CENTER", 0, 0)
tRestore:SetText("|cff99ffbbApply / Restore Dump|r")

local btnSelectDump = CreateFrame("Button", nil, p5, ns.backdropTemplate)
btnSelectDump:SetSize(80, 20)
btnSelectDump:SetPoint("RIGHT", btnRestoreDump, "LEFT", -6, 0)
ns.ApplyModernBackdrop(btnSelectDump, 0.2, 0.12, 0.35, 0.8, 0.5, 0.25, 0.8, 0.9)
local tSelectDump = btnSelectDump:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tSelectDump:SetPoint("CENTER", btnSelectDump, "CENTER", 0, 0)
tSelectDump:SetText("|cffffffffSelect All|r")

local dumpBoxFrame = CreateFrame("Frame", nil, p5, ns.backdropTemplate)
dumpBoxFrame:SetPoint("TOPLEFT", dbHeader, "BOTTOMLEFT", 0, -4)
dumpBoxFrame:SetPoint("BOTTOMRIGHT", p5, "BOTTOMRIGHT", -10, 0)
ns.ApplyModernBackdrop(dumpBoxFrame, 0.03, 0.02, 0.05, 0.95, 0.35, 0.15, 0.55, 0.7)

local dumpScroll = CreateFrame("ScrollFrame", "WOWForeverDumpScrollFrame", dumpBoxFrame, "UIPanelScrollFrameTemplate")
dumpScroll:SetPoint("TOPLEFT", dumpBoxFrame, "TOPLEFT", 8, -6)
dumpScroll:SetPoint("BOTTOMRIGHT", dumpBoxFrame, "BOTTOMRIGHT", -26, 6)
ns.StyleCustomScrollFrame(dumpScroll)

local dumpEditBox = CreateFrame("EditBox", nil, dumpScroll)
dumpEditBox:SetMultiLine(true)
dumpEditBox:SetMaxLetters(999999)
dumpEditBox:SetFontObject("GameFontHighlightSmall")
dumpEditBox:SetWidth(420)
dumpEditBox:SetAutoFocus(false)
dumpScroll:SetScrollChild(dumpEditBox)

local function RefreshDumpText()
    if ns.DumpDBToString then
        dumpEditBox:SetText(ns.DumpDBToString())
    end
end

btnSelectDump:SetScript("OnClick", function()
    if dumpEditBox then
        dumpEditBox:SetFocus()
        dumpEditBox:HighlightText()
        print("|cffc866ff[WOWForeverAddon]|r DB Dump highlighted! Press |cffda99ffCtrl+C|r to copy.")
    end
end)

btnRestoreDump:SetScript("OnClick", function()
    if dumpEditBox and ns.ImportDBFromString then
        local text = dumpEditBox:GetText()
        local success, countOrErr = ns.ImportDBFromString(text)
        if success then
            print(string.format("|cff00ff88[WOWForeverAddon]|r Restored %d settings from dump successfully!", countOrErr))
            if ns.RefreshLogView then ns.RefreshLogView() end
        else
            print("|cffff4466[WOWForeverAddon]|r Failed to restore dump: " .. tostring(countOrErr))
        end
    end
end)

btnRefresh:SetScript("OnClick", function()
    RefreshDumpText()
    ns.RefreshLogView()
    if ns.Log then ns.Log("MANUAL", "Refreshed DB Dump & Log view.") end
end)

btnClear:SetScript("OnClick", function()
    ns.logs = {}
    ns.RefreshLogView()
end)

p5:SetScript("OnShow", function()
    RefreshDumpText()
    ns.RefreshLogView()
end)

----------------------------------------------------

end

local function CreatePage6(contentArea)
-- PAGE 6: LEVELING FEATURES & XP BAR SUITE
----------------------------------------------------
local p6 = CreateFrame("Frame", nil, contentArea)
p6:SetAllPoints()
p6:Hide()
contentPanels[6] = p6

local p6Scroll = CreateFrame("ScrollFrame", "WOWForeverP6ScrollFrame", p6, "UIPanelScrollFrameTemplate")
p6Scroll:SetPoint("TOPLEFT", p6, "TOPLEFT", 0, 0)
p6Scroll:SetPoint("BOTTOMRIGHT", p6, "BOTTOMRIGHT", -10, 0)
ns.StyleCustomScrollFrame(p6Scroll)

local p6Content = CreateFrame("Frame", "WOWForeverP6Content", p6Scroll)
p6Content:SetSize(460, 360)
p6Scroll:SetScrollChild(p6Content)
    p6.content = p6Content

-- Card 1: XP Bar Master & Stats Badge
local lCard1 = CreateFrame("Frame", nil, p6Content, ns.backdropTemplate)
lCard1:SetSize(455, 115)
lCard1:SetPoint("TOPLEFT", p6Content, "TOPLEFT", 0, 0)
ns.ApplyModernBackdrop(lCard1, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local lc1Title = lCard1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lc1Title:SetPoint("TOPLEFT", lCard1, "TOPLEFT", 14, -10)
lc1Title:SetText("|cffda99ffModern XP Bar & Analytics HUD|r")

local lc1Desc = lCard1:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
lc1Desc:SetPoint("TOPLEFT", lc1Title, "BOTTOMLEFT", 0, -4)
lc1Desc:SetText("|cffa388ccEnable modern multi-segmented XP bar, XP/hr rate & TTL badge.|r")

local btnBarEnable = CreateFrame("Button", nil, lCard1, ns.backdropTemplate)
btnBarEnable:SetSize(90, 22)
btnBarEnable:SetPoint("TOPRIGHT", lCard1, "TOPRIGHT", -12, -10)
local txtBarEnable = btnBarEnable:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
txtBarEnable:SetPoint("CENTER", btnBarEnable, "CENTER", 0, 0)
btnBarEnable.UpdateState = function(self, isEnabled)
    if isEnabled then
        ns.ApplyModernBackdrop(btnBarEnable, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
        txtBarEnable:SetText("|cffffffffENABLED|r")
    else
        ns.ApplyModernBackdrop(btnBarEnable, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
        txtBarEnable:SetText("|cff8866aaDISABLED|r")
    end
end
btnBarEnable:SetScript("OnClick", function()
    local cur = WOWForeverAddonDB.XPBarEnabled
    if cur == nil then cur = ns.defaultSettings.XPBarEnabled end
    WOWForeverAddonDB.XPBarEnabled = not cur
    ns.RefreshGUIOptions()
end)
levelingWidgets.barEnableBtn = btnBarEnable

-- Stats badge toggle
local btnStats = CreateFrame("Button", nil, lCard1, ns.backdropTemplate)
btnStats:SetSize(140, 22)
btnStats:SetPoint("TOPLEFT", lc1Desc, "BOTTOMLEFT", 0, -10)
local txtStats = btnStats:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
txtStats:SetPoint("CENTER", btnStats, "CENTER", 0, 0)
btnStats.UpdateState = function(self, isShown)
    if isShown then
        ns.ApplyModernBackdrop(btnStats, 0.25, 0.1, 0.4, 0.8, 0.45, 0.2, 0.7, 0.9)
        txtStats:SetText("|cffffffffStats Badge: ON|r")
    else
        ns.ApplyModernBackdrop(btnStats, 0.1, 0.05, 0.15, 0.6, 0.2, 0.1, 0.3, 0.5)
        txtStats:SetText("|cff8866aaStats Badge: OFF|r")
    end
end
btnStats:SetScript("OnClick", function()
    local cur = WOWForeverAddonDB.XPBarShowStats
    if cur == nil then cur = ns.defaultSettings.XPBarShowStats end
    WOWForeverAddonDB.XPBarShowStats = not cur
    ns.RefreshGUIOptions()
end)
levelingWidgets.barStatsBtn = btnStats

-- Quest Overlays toggle
local btnQuestOverlays = CreateFrame("Button", nil, lCard1, ns.backdropTemplate)
btnQuestOverlays:SetSize(170, 22)
btnQuestOverlays:SetPoint("LEFT", btnStats, "RIGHT", 10, 0)
local txtQuestOverlays = btnQuestOverlays:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
txtQuestOverlays:SetPoint("CENTER", btnQuestOverlays, "CENTER", 0, 0)
btnQuestOverlays.UpdateState = function(self, isShown)
    if isShown then
        ns.ApplyModernBackdrop(btnQuestOverlays, 0.25, 0.1, 0.4, 0.8, 0.45, 0.2, 0.7, 0.9)
        txtQuestOverlays:SetText("|cffffffffQuest XP Overlays: ON|r")
    else
        ns.ApplyModernBackdrop(btnQuestOverlays, 0.1, 0.05, 0.15, 0.6, 0.2, 0.1, 0.3, 0.5)
        txtQuestOverlays:SetText("|cff8866aaQuest XP Overlays: OFF|r")
    end
end
btnQuestOverlays:SetScript("OnClick", function()
    local cur = WOWForeverAddonDB.XPBarShowQuestOverlay
    if cur == nil then cur = ns.defaultSettings.XPBarShowQuestOverlay end
    WOWForeverAddonDB.XPBarShowQuestOverlay = not cur
    ns.RefreshGUIOptions()
end)
    levelingWidgets.barQuestBtn = btnQuestOverlays
    ns.AttachOptionTooltip(lCard1, "Modern XP Bar & Analytics HUD", "Aktiviert die schlanke, anpassbare Erfahrungsleiste mit Echtzeit-Statistiken.", "Mehrfarbige Segmente zeigen Basis-XP, Erholt-Bonus und Quest-Vorschau an.", true)
    ns.AttachOptionTooltip(btnStats, "XP Bar Stats Badge", "Schaltet die Textanzeige für genaue Erfahrungswerte, Prozente und TTL-Schätzungen um.", nil, true)
    ns.AttachOptionTooltip(btnQuestOverlays, "Quest XP Overlays", "Zeigt den Erfahrungswert aller Quests als farbige Vorschau auf der Leiste an.", nil, true)

-- Card 2: Color Presets
local lCard2 = CreateFrame("Frame", nil, p6Content, ns.backdropTemplate)
lCard2:SetSize(455, 95)
lCard2:SetPoint("TOPLEFT", lCard1, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(lCard2, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local lc2Title = lCard2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lc2Title:SetPoint("TOPLEFT", lCard2, "TOPLEFT", 14, -10)
lc2Title:SetText("|cffda99ffXP Bar Color Themes & Presets|r")

local lc2Desc = lCard2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
lc2Desc:SetPoint("TOPLEFT", lc2Title, "BOTTOMLEFT", 0, -4)
lc2Desc:SetText("|cffa388ccSelect custom visual color themes for the experience bar.|r")

local btnPresetCyan = CreateFrame("Button", nil, lCard2, ns.backdropTemplate)
btnPresetCyan:SetSize(110, 22)
btnPresetCyan:SetPoint("TOPLEFT", lc2Desc, "BOTTOMLEFT", 0, -8)
ns.ApplyModernBackdrop(btnPresetCyan, 0.15, 0.08, 0.25, 0.8, 0.35, 0.16, 0.55, 0.8)
local tPCyan = btnPresetCyan:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tPCyan:SetPoint("CENTER", btnPresetCyan, "CENTER", 0, 0)
tPCyan:SetText("|cff00d2ffCyan & Gold|r")
btnPresetCyan:SetScript("OnClick", function()
    WOWForeverAddonDB.XPBarColorBase = { r = 0, g = 0.82, b = 1 }
    WOWForeverAddonDB.XPBarColorRested = { r = 1, g = 0.8, b = 0 }
    WOWForeverAddonDB.XPBarColorCompletedQuest = { r = 0, g = 1, b = 0.53 }
    WOWForeverAddonDB.XPBarColorActiveQuest = { r = 0.66, g = 0.4, b = 1 }
    ns.RefreshGUIOptions()
end)
ns.AttachOptionTooltip(btnPresetCyan, "Cyan & Gold Thema", "Setzt das Farbprofil auf Cyan (Basis) und warmes Gold (Erholt).", nil, nil)

local btnPresetCyber = CreateFrame("Button", nil, lCard2, ns.backdropTemplate)
btnPresetCyber:SetSize(110, 22)
btnPresetCyber:SetPoint("LEFT", btnPresetCyan, "RIGHT", 8, 0)
ns.ApplyModernBackdrop(btnPresetCyber, 0.15, 0.08, 0.25, 0.8, 0.35, 0.16, 0.55, 0.8)
local tPCyber = btnPresetCyber:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tPCyber:SetPoint("CENTER", btnPresetCyber, "CENTER", 0, 0)
tPCyber:SetText("|cffff0080Cyberpunk|r")
btnPresetCyber:SetScript("OnClick", function()
    WOWForeverAddonDB.XPBarColorBase = { r = 1, g = 0, b = 0.5 }
    WOWForeverAddonDB.XPBarColorRested = { r = 1, g = 0.9, b = 0 }
    WOWForeverAddonDB.XPBarColorCompletedQuest = { r = 0.2, g = 1, b = 0.2 }
    WOWForeverAddonDB.XPBarColorActiveQuest = { r = 0, g = 0.8, b = 1 }
    ns.RefreshGUIOptions()
end)
ns.AttachOptionTooltip(btnPresetCyber, "Cyberpunk Thema", "Setzt das Farbprofil auf leuchtendes Pink und Cyan.", nil, nil)

local btnPresetCrimson = CreateFrame("Button", nil, lCard2, ns.backdropTemplate)
btnPresetCrimson:SetSize(120, 22)
btnPresetCrimson:SetPoint("LEFT", btnPresetCyber, "RIGHT", 8, 0)
ns.ApplyModernBackdrop(btnPresetCrimson, 0.15, 0.08, 0.25, 0.8, 0.35, 0.16, 0.55, 0.8)
local tPCrim = btnPresetCrimson:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tPCrim:SetPoint("CENTER", btnPresetCrimson, "CENTER", 0, 0)
tPCrim:SetText("|cffea2027Gothic Crimson|r")
btnPresetCrimson:SetScript("OnClick", function()
    WOWForeverAddonDB.XPBarColorBase = { r = 0.9, g = 0.1, b = 0.2 }
    WOWForeverAddonDB.XPBarColorRested = { r = 1, g = 0.7, b = 0 }
    WOWForeverAddonDB.XPBarColorCompletedQuest = { r = 0, g = 0.8, b = 0.4 }
    WOWForeverAddonDB.XPBarColorActiveQuest = { r = 0.6, g = 0.2, b = 0.8 }
    ns.RefreshGUIOptions()
end)
ns.AttachOptionTooltip(btnPresetCrimson, "Gothic Crimson Thema", "Setzt das Farbprofil auf blutrotes Gothic-Amethyst.", nil, nil)

-- Card 3: Level-Up Banner & Automation
local lCard3 = CreateFrame("Frame", nil, p6Content, ns.backdropTemplate)
lCard3:SetSize(455, 65)
lCard3:SetPoint("TOPLEFT", lCard2, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(lCard3, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local lc3Title = lCard3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lc3Title:SetPoint("TOPLEFT", lCard3, "TOPLEFT", 14, -10)
lc3Title:SetText("|cffda99ffLevel-Up Celebration & Auto-Screenshot|r")

local lc3Desc = lCard3:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
lc3Desc:SetPoint("TOPLEFT", lc3Title, "BOTTOMLEFT", 0, -4)
lc3Desc:SetText("|cffa388ccAchievement banner and automatic screenshot on level up.|r")

local btnBanner = CreateFrame("Button", nil, lCard3, ns.backdropTemplate)
btnBanner:SetSize(80, 22)
btnBanner:SetPoint("RIGHT", lCard3, "RIGHT", -100, 0)
local txtBanner = btnBanner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
txtBanner:SetPoint("CENTER", btnBanner, "CENTER", 0, 0)
btnBanner.UpdateState = function(self, isEnabled)
    if isEnabled then
        ns.ApplyModernBackdrop(btnBanner, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
        txtBanner:SetText("|cffffffffBANNER|r")
    else
        ns.ApplyModernBackdrop(btnBanner, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
        txtBanner:SetText("|cff8866aaBANNER|r")
    end
end
btnBanner:SetScript("OnClick", function()
    local cur = WOWForeverAddonDB.LevelUpBannerEnabled
    if cur == nil then cur = ns.defaultSettings.LevelUpBannerEnabled end
    WOWForeverAddonDB.LevelUpBannerEnabled = not cur
    ns.RefreshGUIOptions()
end)
levelingWidgets.bannerBtn = btnBanner

local btnScreenshot = CreateFrame("Button", nil, lCard3, ns.backdropTemplate)
btnScreenshot:SetSize(80, 22)
btnScreenshot:SetPoint("RIGHT", lCard3, "RIGHT", -12, 0)
local txtScreenshot = btnScreenshot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
txtScreenshot:SetPoint("CENTER", btnScreenshot, "CENTER", 0, 0)
btnScreenshot.UpdateState = function(self, isEnabled)
    if isEnabled then
        ns.ApplyModernBackdrop(btnScreenshot, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
        txtScreenshot:SetText("|cffffffffSHOT: ON|r")
    else
        ns.ApplyModernBackdrop(btnScreenshot, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
        txtScreenshot:SetText("|cff8866aaSHOT: OFF|r")
    end
end
btnScreenshot:SetScript("OnClick", function()
    local cur = WOWForeverAddonDB.LevelUpScreenshot
    if cur == nil then cur = ns.defaultSettings.LevelUpScreenshot end
    WOWForeverAddonDB.LevelUpScreenshot = not cur
    ns.RefreshGUIOptions()
end)
levelingWidgets.screenshotBtn = btnScreenshot
ns.AttachOptionTooltip(lCard3, "Level-Up Feier & Screenshot", "Banner-Animation und automatischer Screenshot bei jedem Stufenaufstieg.", nil, true)
ns.AttachOptionTooltip(btnBanner, "Level-Up Banner", "Blendet beim Levelaufstieg ein stilvolles Fanfare-Banner ein.", nil, true)
ns.AttachOptionTooltip(btnScreenshot, "Auto-Screenshot", "Speichert beim Levelaufstieg automatisch ein Bild in deinem WoW-Screenshots-Ordner.", nil, true)

----------------------------------------------------

end

local function CreatePage7(contentArea)
-- PAGE 7: PROFILES & SHARING (YAQoL v2.0)
----------------------------------------------------
local p7 = CreateFrame("Frame", nil, contentArea)
p7:SetAllPoints()
p7:Hide()
contentPanels[7] = p7

p7Scroll = CreateFrame("ScrollFrame", "YAQoLP7ScrollFrame", p7, "UIPanelScrollFrameTemplate")
p7Scroll:SetPoint("TOPLEFT", p7, "TOPLEFT", 0, -4)
p7Scroll:SetPoint("BOTTOMRIGHT", p7, "BOTTOMRIGHT", -10, 0)
ns.StyleCustomScrollFrame(p7Scroll)

local p7Content = CreateFrame("Frame", "YAQoLP7Content", p7Scroll)
p7Content:SetSize(460, 620)
p7Scroll:SetScrollChild(p7Content)
    p7.content = p7Content

-- Card 1: Active Profile & Switcher
local profCard = CreateFrame("Frame", nil, p7Content, ns.backdropTemplate)
profCard:SetSize(455, 145)
profCard:SetPoint("TOPLEFT", p7Content, "TOPLEFT", 0, -8)
ns.ApplyModernBackdrop(profCard, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local profTitle = profCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
profTitle:SetPoint("TOPLEFT", profCard, "TOPLEFT", 14, -10)
profTitle:SetText("|cffda99ffProfile Manager|r")

local profDesc = profCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
profDesc:SetPoint("TOPLEFT", profTitle, "BOTTOMLEFT", 0, -4)
profDesc:SetText("|cffa388ccManage multiple profiles for different characters, specs, or streaming.|r")

local activeLabel = profCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
activeLabel:SetPoint("TOPLEFT", profDesc, "BOTTOMLEFT", 0, -10)
activeLabel:SetText("|cffc866ffActive Profile:|r |cffffffff" .. (ns.GetActiveProfileName and ns.GetActiveProfileName() or "Default") .. "|r")

local profBtnContainer = CreateFrame("Frame", nil, profCard)
profBtnContainer:SetPoint("TOPLEFT", activeLabel, "BOTTOMLEFT", 0, -8)
profBtnContainer:SetSize(430, 28)

local profBtns = {}
local function RefreshProfileButtons()
    activeLabel:SetText("|cffc866ffActive Profile:|r |cffffffff" .. (ns.GetActiveProfileName and ns.GetActiveProfileName() or "Default") .. "|r")
    for _, b in ipairs(profBtns) do b:Hide() end
    profBtns = {}

    local list = ns.GetProfileList and ns.GetProfileList() or { "Default" }
    local curActive = ns.GetActiveProfileName and ns.GetActiveProfileName() or "Default"
    local xOff = 0
    for idx, pName in ipairs(list) do
        if xOff < 340 then
            local pBtn = CreateFrame("Button", nil, profBtnContainer, ns.backdropTemplate)
            pBtn:SetSize(math.max(70, #pName * 8 + 14), 22)
            pBtn:SetPoint("LEFT", profBtnContainer, "LEFT", xOff, 0)
            local isCurrent = (pName == curActive)
            if isCurrent then
                ns.ApplyModernBackdrop(pBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
            else
                ns.ApplyModernBackdrop(pBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
            end
            local pTxt = pBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            pTxt:SetPoint("CENTER", pBtn, "CENTER", 0, 0)
            pTxt:SetText(isCurrent and ("|cffffffff" .. pName .. "|r") or ("|cffa388cc" .. pName .. "|r"))

            pBtn:SetScript("OnClick", function()
                if ns.SetActiveProfile then
                    ns.SetActiveProfile(pName)
                    RefreshProfileButtons()
                end
            end)
            table.insert(profBtns, pBtn)
            xOff = xOff + pBtn:GetWidth() + 6
        end
    end
end
ns.RefreshProfileGUI = RefreshProfileButtons

local newProfBox = CreateFrame("EditBox", "YAQoLNewProfileBox", profCard, ns.backdropTemplate)
newProfBox:SetSize(150, 22)
newProfBox:SetPoint("BOTTOMLEFT", profCard, "BOTTOMLEFT", 14, 12)
newProfBox:SetAutoFocus(false)
newProfBox:SetFontObject("GameFontHighlightSmall")
newProfBox:SetTextInsets(6, 6, 0, 0)
ns.ApplyModernBackdrop(newProfBox, 0.04, 0.02, 0.06, 0.9, 0.35, 0.15, 0.5, 0.8)

local newProfPlaceholder = newProfBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
newProfPlaceholder:SetPoint("LEFT", newProfBox, "LEFT", 8, 0)
newProfPlaceholder:SetText("Profile name...")
newProfBox:SetScript("OnTextChanged", function(self)
    if self:GetText() ~= "" then newProfPlaceholder:Hide() else newProfPlaceholder:Show() end
end)

local createBtn = CreateFrame("Button", nil, profCard, ns.backdropTemplate)
createBtn:SetSize(95, 22)
createBtn:SetPoint("LEFT", newProfBox, "RIGHT", 6, 0)
ns.ApplyModernBackdrop(createBtn, 0.22, 0.12, 0.35, 0.8, 0.5, 0.25, 0.8, 0.9)
local createTxt = createBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
createTxt:SetPoint("CENTER", createBtn, "CENTER", 0, 0)
createTxt:SetText("|cffffffffCreate Copy|r")
createBtn:SetScript("OnClick", function()
    local name = newProfBox:GetText()
    if name and strtrim(name) ~= "" then
        if ns.CreateProfile then
            local ok, err = ns.CreateProfile(name, true)
            if ok then
                newProfBox:SetText("")
                newProfBox:ClearFocus()
                RefreshProfileButtons()
            else
                print("|cffff4466[YAQoL Error]|r " .. tostring(err))
            end
        end
    end
end)
ns.AttachOptionTooltip(createBtn, "Profil duplizieren", "Erstellt eine vollständige Kopie des aktuell aktiven Profils unter dem eingegebenen Namen.")

local resetProfBtn = CreateFrame("Button", nil, profCard, ns.backdropTemplate)
resetProfBtn:SetSize(75, 22)
resetProfBtn:SetPoint("LEFT", createBtn, "RIGHT", 6, 0)
ns.ApplyModernBackdrop(resetProfBtn, 0.16, 0.08, 0.22, 0.8, 0.35, 0.15, 0.5, 0.8)
local resetProfTxt = resetProfBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
resetProfTxt:SetPoint("CENTER", resetProfBtn, "CENTER", 0, 0)
resetProfTxt:SetText("|cffe0b3ffReset|r")
resetProfBtn:SetScript("OnClick", function()
    if ns.ResetProfile then
        ns.ResetProfile()
        RefreshProfileButtons()
    end
end)
ns.AttachOptionTooltip(resetProfBtn, "Profil zurücksetzen", "Setzt alle Einstellungen des aktuellen Profils auf die Standardwerte zurück.")

local delProfBtn = CreateFrame("Button", nil, profCard, ns.backdropTemplate)
delProfBtn:SetSize(70, 22)
delProfBtn:SetPoint("LEFT", resetProfBtn, "RIGHT", 6, 0)
ns.ApplyModernBackdrop(delProfBtn, 0.25, 0.05, 0.08, 0.8, 0.6, 0.15, 0.2, 0.8)
local delProfTxt = delProfBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
delProfTxt:SetPoint("CENTER", delProfBtn, "CENTER", 0, 0)
delProfTxt:SetText("|cffff7788Delete|r")
delProfBtn:SetScript("OnClick", function()
    local curActive = ns.GetActiveProfileName and ns.GetActiveProfileName() or "Default"
    if curActive ~= "Default" then
        if ns.DeleteProfile then
            ns.DeleteProfile(curActive)
            RefreshProfileButtons()
        end
    else
        print("|cffff4466[YAQoL]|r Cannot delete the Default profile.")
    end
end)
ns.AttachOptionTooltip(delProfBtn, "Profil löschen", "Entfernt das ausgewählte Profil dauerhaft (das 'Default'-Profil kann nicht gelöscht werden).")

-- Card 2: Export Profile (Shareable Base64 String)
local expCard = CreateFrame("Frame", nil, p7Content, ns.backdropTemplate)
expCard:SetSize(455, 160)
expCard:SetPoint("TOPLEFT", profCard, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(expCard, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local expTitle = expCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
expTitle:SetPoint("TOPLEFT", expCard, "TOPLEFT", 14, -10)
expTitle:SetText("|cffda99ffShare Profile String (Export)|r")

local expDesc = expCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
expDesc:SetPoint("TOPLEFT", expTitle, "BOTTOMLEFT", 0, -3)
expDesc:SetText("|cffa388ccGenerate an export string to share with other players or your guild.|r")

-- Inset textarea frame with visible border
local expArea = CreateFrame("Frame", nil, expCard, ns.backdropTemplate)
expArea:SetPoint("TOPLEFT", expCard, "TOPLEFT", 12, -45)
expArea:SetPoint("BOTTOMRIGHT", expCard, "BOTTOMRIGHT", -12, 38)
ns.ApplyModernBackdrop(expArea, 0.04, 0.02, 0.06, 0.95, 0.35, 0.15, 0.5, 0.8)

local expScroll = CreateFrame("ScrollFrame", "YAQoLExportScrollFrame", expArea, "UIPanelScrollFrameTemplate")
expScroll:SetPoint("TOPLEFT", expArea, "TOPLEFT", 6, -6)
expScroll:SetPoint("BOTTOMRIGHT", expArea, "BOTTOMRIGHT", -20, 6)
ns.StyleCustomScrollFrame(expScroll)

local expBox = CreateFrame("EditBox", "YAQoLExportEditBox", expScroll)
expBox:SetMultiLine(true)
expBox:SetAutoFocus(false)
expBox:SetFontObject("GameFontHighlightSmall")
expBox:SetWidth(400)
expBox:SetHeight(65)
expBox:SetTextInsets(2, 2, 2, 2)
expScroll:SetScrollChild(expBox)
expScroll:EnableMouse(true)
expScroll:SetScript("OnMouseDown", function()
    expBox:HighlightText()
    expBox:SetFocus()
end)
expBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
expBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
expBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

local expBtn = CreateFrame("Button", nil, expCard, ns.backdropTemplate)
expBtn:SetSize(160, 22)
expBtn:SetPoint("BOTTOMLEFT", expCard, "BOTTOMLEFT", 12, 8)
ns.ApplyModernBackdrop(expBtn, 0.35, 0.15, 0.55, 0.9, 0.65, 0.25, 0.9, 1)
local expBtnTxt = expBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
expBtnTxt:SetPoint("CENTER", expBtn, "CENTER", 0, 0)
expBtnTxt:SetText("|cffffffffGenerate Export String|r")
expBtn:SetScript("OnClick", function()
    if ns.ExportProfileToString then
        local str = ns.ExportProfileToString()
        expBox:SetText(str or "Failed to export profile")
        expBox:HighlightText()
        expBox:SetFocus()
    end
end)
ns.AttachOptionTooltip(expBtn, "Export-String erstellen", "Generiert eine kompakte, teilbare Zeichenkette mit all deinen aktuellen Einstellungen zum Teilen.")

local copyExpBtn = CreateFrame("Button", nil, expCard, ns.backdropTemplate)
copyExpBtn:SetSize(130, 22)
copyExpBtn:SetPoint("LEFT", expBtn, "RIGHT", 8, 0)
ns.ApplyModernBackdrop(copyExpBtn, 0.2, 0.12, 0.3, 0.8, 0.45, 0.2, 0.7, 0.9)
local copyExpTxt = copyExpBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
copyExpTxt:SetPoint("CENTER", copyExpBtn, "CENTER", 0, 0)
copyExpTxt:SetText("|cffe0b3ffSelect for Copy|r")
copyExpBtn:SetScript("OnClick", function()
    expBox:HighlightText()
    expBox:SetFocus()
end)
ns.AttachOptionTooltip(copyExpBtn, "Text auswählen", "Markiert den gesamten Export-Text, damit du ihn sofort mit Strg+C kopieren kannst.")

-- Card 3: Import Profile String
local impCard = CreateFrame("Frame", nil, p7Content, ns.backdropTemplate)
impCard:SetSize(455, 190)
impCard:SetPoint("TOPLEFT", expCard, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(impCard, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local impTitle = impCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
impTitle:SetPoint("TOPLEFT", impCard, "TOPLEFT", 14, -10)
impTitle:SetText("|cffda99ffImport Profile String|r")

local impDesc = impCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
impDesc:SetPoint("TOPLEFT", impTitle, "BOTTOMLEFT", 0, -3)
impDesc:SetText("|cffa388ccClick the box below and paste (Ctrl+V) any YAQoL export string or dump.|r")

-- Inset textarea frame with visible border
local impArea = CreateFrame("Frame", nil, impCard, ns.backdropTemplate)
impArea:SetPoint("TOPLEFT", impCard, "TOPLEFT", 12, -45)
impArea:SetPoint("BOTTOMRIGHT", impCard, "BOTTOMRIGHT", -12, 42)
ns.ApplyModernBackdrop(impArea, 0.04, 0.02, 0.06, 0.95, 0.35, 0.15, 0.5, 0.8)
impArea:EnableMouse(true)

local impScroll = CreateFrame("ScrollFrame", "YAQoLImportScrollFrame", impArea, "UIPanelScrollFrameTemplate")
impScroll:SetPoint("TOPLEFT", impArea, "TOPLEFT", 6, -6)
impScroll:SetPoint("BOTTOMRIGHT", impArea, "BOTTOMRIGHT", -20, 6)
ns.StyleCustomScrollFrame(impScroll)
impScroll:EnableMouse(true)

local impBox = CreateFrame("EditBox", "YAQoLImportEditBox", impScroll)
impBox:SetMultiLine(true)
impBox:SetAutoFocus(false)
impBox:SetFontObject("GameFontHighlightSmall")
impBox:SetWidth(400)
impBox:SetHeight(85)
impBox:SetTextInsets(2, 2, 2, 2)
impScroll:SetScrollChild(impBox)
impBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local impPlaceholder = impArea:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
impPlaceholder:SetPoint("TOPLEFT", impArea, "TOPLEFT", 10, -10)
impPlaceholder:SetText("Paste YAQoL export string or Base64 code here (Ctrl+V)...")

impBox:SetScript("OnTextChanged", function(self)
    if self:GetText() ~= "" then impPlaceholder:Hide() else impPlaceholder:Show() end
end)
impArea:SetScript("OnMouseDown", function()
    impBox:SetFocus()
end)
impScroll:SetScript("OnMouseDown", function()
    impBox:SetFocus()
end)

local impNameBox = CreateFrame("EditBox", "YAQoLImportNameBox", impCard, ns.backdropTemplate)
impNameBox:SetSize(160, 24)
impNameBox:SetPoint("BOTTOMLEFT", impCard, "BOTTOMLEFT", 12, 10)
impNameBox:SetAutoFocus(false)
impNameBox:SetFontObject("GameFontHighlightSmall")
impNameBox:SetTextInsets(6, 6, 0, 0)
ns.ApplyModernBackdrop(impNameBox, 0.04, 0.02, 0.06, 0.9, 0.35, 0.15, 0.5, 0.8)

local impNamePlaceholder = impNameBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
impNamePlaceholder:SetPoint("LEFT", impNameBox, "LEFT", 8, 0)
impNamePlaceholder:SetText("New Profile Name (optional)...")
impNameBox:SetScript("OnTextChanged", function(self)
    if self:GetText() ~= "" then impNamePlaceholder:Hide() else impNamePlaceholder:Show() end
end)

local applyImpBtn = CreateFrame("Button", nil, impCard, ns.backdropTemplate)
applyImpBtn:SetSize(160, 24)
applyImpBtn:SetPoint("LEFT", impNameBox, "RIGHT", 8, 0)
ns.ApplyModernBackdrop(applyImpBtn, 0.25, 0.45, 0.2, 0.9, 0.4, 0.8, 0.3, 1)
local applyImpTxt = applyImpBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
applyImpTxt:SetPoint("CENTER", applyImpBtn, "CENTER", 0, 0)
applyImpTxt:SetText("|cffffffffImport & Apply Profile|r")
ns.AttachOptionTooltip(applyImpBtn, "Profil importieren", "Liest den eingefügten Export-Code ein, validiert ihn und wendet das Profil direkt an.")

applyImpBtn:SetScript("OnClick", function()
    local raw = impBox:GetText()
    local name = impNameBox:GetText()

    -- SMART RESCUE: If the large textarea is empty, but the user typed or pasted into the name box:
    -- treat the content of the name box as the import string!
    if (not raw or strtrim(raw) == "") and (name and strtrim(name) ~= "") then
        raw = name
        name = ""
    end

    raw = raw and strtrim(raw) or ""
    name = name and strtrim(name) or ""

    if raw == "" then
        print("|cffff4466[YAQoL Error]|r Paste an import string into the box first.")
        impBox:SetFocus()
        return
    end

    if ns.ImportProfileFromString then
        local ok, res = ns.ImportProfileFromString(raw, name)
        if ok then
            impBox:SetText("")
            impNameBox:SetText("")
            if ns.RefreshProfileGUI then ns.RefreshProfileGUI() end
        else
            print("|cffff4466[YAQoL Error]|r " .. tostring(res))
        end
    end
end)

----------------------------------------------------

end

local function CreatePage8(contentArea)
-- PAGE 8: CREDITS & SOCIALS (Orbitus / Liiina)
----------------------------------------------------
local p8 = CreateFrame("Frame", nil, contentArea)
p8:SetAllPoints()
p8:Hide()
contentPanels[8] = p8

local p8Scroll = CreateFrame("ScrollFrame", "YAQoLP8ScrollFrame", p8, "UIPanelScrollFrameTemplate")
p8Scroll:SetPoint("TOPLEFT", p8, "TOPLEFT", 0, 0)
p8Scroll:SetPoint("BOTTOMRIGHT", p8, "BOTTOMRIGHT", -10, 0)
ns.StyleCustomScrollFrame(p8Scroll)

local p8Content = CreateFrame("Frame", "YAQoLP8Content", p8Scroll)
p8Content:SetSize(460, 480)
p8Scroll:SetScrollChild(p8Content)
    p8.content = p8Content

-- Card 1: Banner Card
local cBanner = CreateFrame("Frame", nil, p8Content, ns.backdropTemplate)
cBanner:SetSize(455, 110)
cBanner:SetPoint("TOPLEFT", p8Content, "TOPLEFT", 0, 0)
ns.ApplyModernBackdrop(cBanner, 0.08, 0.04, 0.13, 0.9, 0.65, 0.25, 0.95, 0.9)

local cbTitle = cBanner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
cbTitle:SetPoint("TOPLEFT", cBanner, "TOPLEFT", 16, -14)
cbTitle:SetText("|cffc866ffYAQoL|r |cffffffff(Yet Another Quality of Life)|r")

local cbBadge = cBanner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cbBadge:SetPoint("TOPLEFT", cbTitle, "BOTTOMLEFT", 0, -4)
cbBadge:SetText("|cffda99ffStreamer Edition v2.0.0 | Built for World of Warcraft Classic & Retail|r")

local cbText = cBanner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cbText:SetPoint("TOPLEFT", cbBadge, "BOTTOMLEFT", 0, -8)
cbText:SetPoint("RIGHT", cBanner, "RIGHT", -16, 0)
cbText:SetJustifyH("LEFT")
cbText:SetText("|cffe0d4f5YAQoL is a modern, distraction-free UI suite combining smart element fading, minimalist action bar aesthetics, leveling analytics, and quality-of-life automations.|r")

-- Card 2: Creator & Streamer Profile
local cCreator = CreateFrame("Frame", nil, p8Content, ns.backdropTemplate)
cCreator:SetSize(455, 160)
cCreator:SetPoint("TOPLEFT", cBanner, "BOTTOMLEFT", 0, -12)
ns.ApplyModernBackdrop(cCreator, 0.06, 0.03, 0.1, 0.8, 0.28, 0.12, 0.45, 0.6)

local ccTitle = cCreator:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ccTitle:SetPoint("TOPLEFT", cCreator, "TOPLEFT", 16, -12)
ccTitle:SetText("|cffda99ffCreator & Streamer|r")

local ccSub = cCreator:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
ccSub:SetPoint("TOPLEFT", ccTitle, "BOTTOMLEFT", 0, -4)
ccSub:SetText("|cffa388ccGaming Alias: |cffffffffOrbitus / Liiina|r")

local ccBio = cCreator:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
ccBio:SetPoint("TOPLEFT", ccSub, "BOTTOMLEFT", 0, -8)
ccBio:SetPoint("RIGHT", cCreator, "RIGHT", -16, 0)
ccBio:SetJustifyH("LEFT")
ccBio:SetText("|cffccccccTwitch streamer and passionate World of Warcraft player. Focused on high-end clean interface design, peak combat visibility, and lightning-fast quality of life.|r")

local twitchBox = CreateFrame("EditBox", "YAQoLTwitchEditBox", cCreator, ns.backdropTemplate)
twitchBox:SetSize(270, 26)
twitchBox:SetPoint("BOTTOMLEFT", cCreator, "BOTTOMLEFT", 16, 14)
twitchBox:SetAutoFocus(false)
twitchBox:SetFontObject("GameFontHighlightSmall")
twitchBox:SetTextInsets(8, 8, 0, 0)
twitchBox:SetText("https://twitch.tv/orbitus")
ns.ApplyModernBackdrop(twitchBox, 0.04, 0.02, 0.07, 0.9, 0.55, 0.2, 0.85, 0.9)
twitchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
twitchBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)

local twitchBtn = CreateFrame("Button", nil, cCreator, ns.backdropTemplate)
twitchBtn:SetSize(140, 26)
twitchBtn:SetPoint("LEFT", twitchBox, "RIGHT", 10, 0)
ns.ApplyModernBackdrop(twitchBtn, 0.4, 0.16, 0.68, 0.9, 0.75, 0.35, 1.0, 1)
local twitchTxt = twitchBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
twitchTxt:SetPoint("CENTER", twitchBtn, "CENTER", 0, 0)
twitchTxt:SetText("|cffffffffSelect Twitch URL|r")
twitchBtn:SetScript("OnClick", function()
    twitchBox:HighlightText()
    twitchBox:SetFocus()
    print("|cffc866ff[YAQoL]|r Link selected! Press |cffffffffCtrl+C|r to copy |cffda99ffhttps://twitch.tv/orbitus|r")
end)

-- Card 3: Quick Commands & Community
local cCommands = CreateFrame("Frame", nil, p8Content, ns.backdropTemplate)
cCommands:SetSize(455, 130)
cCommands:SetPoint("TOPLEFT", cCreator, "BOTTOMLEFT", 0, -12)
ns.ApplyModernBackdrop(cCommands, 0.06, 0.03, 0.1, 0.8, 0.28, 0.12, 0.45, 0.6)

local cmdTitle = cCommands:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
cmdTitle:SetPoint("TOPLEFT", cCommands, "TOPLEFT", 16, -12)
cmdTitle:SetText("|cffda99ffQuick Slash Commands|r")

local cmdList = cCommands:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cmdList:SetPoint("TOPLEFT", cmdTitle, "BOTTOMLEFT", 0, -6)
cmdList:SetJustifyH("LEFT")
cmdList:SetText(
    "|cffc866ff/yaqol|r or |cffc866ff/yql|r  -  Open this control panel\n" ..
    "|cffc866ff/yaqol export|r  -  Generate shareable profile string\n" ..
    "|cffc866ff/yaqol reset|r  -  Reset active profile settings to defaults\n" ..
    "|cffc866ff/yaqol dump|r  -  Output current memory state to chat\n" ..
    "|cff665588Legacy aliases: /wfa, /wowforever|r"
)

----------------------------------------------------

end

local function CreatePage9(contentArea)
-- PAGE 9: ACTION BARS (Modernization & Layout)
----------------------------------------------------
local p9 = CreateFrame("Frame", nil, contentArea)
p9:SetAllPoints()
p9:Hide()
contentPanels[9] = p9

local p9Scroll = CreateFrame("ScrollFrame", "YAQoLP9ScrollFrame", p9, "UIPanelScrollFrameTemplate")
p9Scroll:SetPoint("TOPLEFT", p9, "TOPLEFT", 0, 0)
p9Scroll:SetPoint("BOTTOMRIGHT", p9, "BOTTOMRIGHT", -10, 0)
ns.StyleCustomScrollFrame(p9Scroll)

local p9Content = CreateFrame("Frame", "YAQoLP9Content", p9Scroll)
p9Content:SetSize(460, 990)
p9Scroll:SetScrollChild(p9Content)
    p9.content = p9Content

-- Card 0: Action Bar Visibility & Mouseover
local abCard0 = CreateFrame("Frame", nil, p9Content, ns.backdropTemplate)
abCard0:SetSize(455, #ns.ACTION_BAR_ELEMENTS * 34 + 68)
abCard0:SetPoint("TOPLEFT", p9Content, "TOPLEFT", 0, 0)
ns.ApplyModernBackdrop(abCard0, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local abc0Title = abCard0:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
abc0Title:SetPoint("TOPLEFT", abCard0, "TOPLEFT", 14, -10)
abc0Title:SetText("|cffda99ffAction Bar Visibility & Mouseover|r")

local abc0Desc = abCard0:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
abc0Desc:SetPoint("TOPLEFT", abc0Title, "BOTTOMLEFT", 0, -3)
abc0Desc:SetText("|cffa388ccConfigure Shown, Hidden, or Mouseover fade for each action bar.|r")

-- Header column labels
local hShown = abCard0:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hShown:SetPoint("TOPRIGHT", abCard0, "TOPRIGHT", -160, -36)
hShown:SetText("|cffbf55ffShown|r")

local hHidden = abCard0:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hHidden:SetPoint("TOPRIGHT", abCard0, "TOPRIGHT", -92, -36)
hHidden:SetText("|cffff4466Hidden|r")

local hMouseover = abCard0:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hMouseover:SetPoint("TOPRIGHT", abCard0, "TOPRIGHT", -16, -36)
hMouseover:SetText("|cffaa66ffMouseover|r")

for i, elem in ipairs(ns.ACTION_BAR_ELEMENTS) do
    local row = CreateFrame("Frame", nil, abCard0, ns.backdropTemplate)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", abCard0, "TOPLEFT", 8, -54 - (i - 1) * 34)
    row:SetPoint("TOPRIGHT", abCard0, "TOPRIGHT", -8, -54 - (i - 1) * 34)

    local isEven = (i % 2 == 0)
    ns.ApplyModernBackdrop(row, isEven and 0.08 or 0.05, isEven and 0.05 or 0.03, isEven and 0.12 or 0.08, 0.6, 0.22, 0.1, 0.35, 0.4)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 12, 0)
    label:SetText(elem.name)

    local function CreateBarPillButton(xOffset, mode, activeColor, activeLabel)
        local btn = CreateFrame("Button", nil, row, ns.backdropTemplate)
        btn:SetSize(68, 22)
        btn:SetPoint("RIGHT", row, "RIGHT", xOffset, 0)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(mode:sub(1,1) .. mode:sub(2):lower())

        btn.UpdateState = function(self, isActive)
            if isActive then
                ns.ApplyModernBackdrop(btn, activeColor[1], activeColor[2], activeColor[3], 0.9, activeColor[1]*1.4, activeColor[2]*1.4, activeColor[3]*1.4, 1)
                btnText:SetText("|cffffffff" .. activeLabel .. "|r")
            else
                ns.ApplyModernBackdrop(btn, 0.1, 0.06, 0.16, 0.6, 0.2, 0.1, 0.3, 0.5)
                btnText:SetText("|cff8866aa" .. mode:sub(1,1) .. mode:sub(2):lower() .. "|r")
            end
        end

        btn:SetScript("OnClick", function()
            local db = ns.db or WOWForeverAddonDB
            if not db then return end
            db[elem.key] = mode
            if ns.Log then ns.Log("GUI_CLICK", "Set " .. tostring(elem.key) .. " = " .. tostring(mode)) end
            ns.ApplyFrameState(elem.key, mode)
            ns.RefreshGUIOptions()
        end)

        return btn
    end

    local shownBtn = CreateBarPillButton(-146, "SHOWN", {0.45, 0.15, 0.7}, "Shown")
    local hiddenBtn = CreateBarPillButton(-74, "HIDDEN", {0.55, 0.1, 0.25}, "Hidden")
    local mouseoverBtn = CreateBarPillButton(-2, "MOUSEOVER", {0.6, 0.25, 0.15}, "Mouseover")

    rowWidgets[elem.key] = {
        shownBtn = shownBtn,
        hiddenBtn = hiddenBtn,
        mouseoverBtn = mouseoverBtn,
    }
    ns.AttachOptionTooltip(row, elem.name, "Steuert die Anzeige von " .. elem.name .. ".", "Shown = dauerhaft sichtbar, Hidden = ausgeblendet, Mouseover = nur bei Berührung mit der Maus sichtbar.", ns.defaultSettings[elem.key])
end

    -- Helper to create a custom modern dark-amethyst slider
    local function CreateCustomSlider(parent, name, minVal, maxVal, stepVal, minText, maxText, getVal, setVal, formatLabel)
        local slider = CreateFrame("Slider", name, parent)
        slider:SetOrientation("HORIZONTAL")
        slider:SetHeight(16)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(stepVal)
        if slider.SetObeyStepNumbers then slider:SetObeyStepNumbers(true) end
        slider:EnableMouse(true)

        -- Custom sleek dark void track
        local track = CreateFrame("Frame", nil, slider, ns.backdropTemplate)
        track:SetPoint("LEFT", slider, "LEFT", 0, 0)
        track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
        track:SetHeight(6)
        track:SetFrameLevel(slider:GetFrameLevel() + 1)
        ns.ApplyModernBackdrop(track, 0.04, 0.02, 0.08, 0.95, 0.35, 0.15, 0.55, 0.9)

        -- Custom Glowing Purple Thumb
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        local thumb = slider:GetThumbTexture()
        if thumb then
            thumb:SetSize(12, 18)
            thumb:SetColorTexture(0.75, 0.3, 1.0, 1.0)
        end

        -- Fill bar showing progress
        local fill = track:CreateTexture(nil, "ARTWORK")
        fill:SetColorTexture(0.55, 0.2, 0.85, 0.9)
        fill:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 1, 1)

        -- Title / Value label above
        local titleFS = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        titleFS:SetPoint("BOTTOM", track, "TOP", 0, 8)

        -- Low & High labels below
        local lowFS = slider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        lowFS:SetPoint("TOPLEFT", track, "BOTTOMLEFT", 0, -4)
        lowFS:SetText("|cffa388cc" .. minText .. "|r")

        local highFS = slider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        highFS:SetPoint("TOPRIGHT", track, "BOTTOMRIGHT", 0, -4)
        highFS:SetText("|cffa388cc" .. maxText .. "|r")

        local function UpdateDisplay(val)
            titleFS:SetText(formatLabel(val))
            local range = maxVal - minVal
            local pct = range > 0 and ((val - minVal) / range) or 0
            local w = track:GetWidth()
            if w and w > 2 then
                fill:SetWidth(math.max(1, pct * (w - 2)))
            end
        end

        track:SetScript("OnSizeChanged", function(self, w)
            local val = slider:GetValue() or minVal
            local range = maxVal - minVal
            local pct = range > 0 and ((val - minVal) / range) or 0
            fill:SetWidth(math.max(1, pct * (w - 2)))
        end)

        local initVal = getVal() or minVal
        slider:SetValue(initVal)
        UpdateDisplay(initVal)

        slider:SetScript("OnValueChanged", function(self, value)
            if stepVal >= 1 then
                value = math.floor(value + 0.5)
            else
                local factor = 1 / stepVal
                value = math.floor(value * factor + 0.5) / factor
            end
            UpdateDisplay(value)
            setVal(value)
        end)

        return slider
    end

    -- Card 1: Icon & Border Aesthetics
    local abCard1 = CreateFrame("Frame", nil, p9Content, ns.backdropTemplate)
    abCard1:SetSize(455, 290)
    abCard1:SetPoint("TOPLEFT", abCard0, "BOTTOMLEFT", 0, -10)
    ns.ApplyModernBackdrop(abCard1, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

    local abc1Title = abCard1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    abc1Title:SetPoint("TOPLEFT", abCard1, "TOPLEFT", 14, -10)
    abc1Title:SetText("|cffda99ffModern Icon & Border Aesthetics|r")

    local abc1Desc = abCard1:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    abc1Desc:SetPoint("TOPLEFT", abc1Title, "BOTTOMLEFT", 0, -3)
    abc1Desc:SetText("|cffa388ccTransform default Blizzard rounded action buttons into clean square icons.|r")

    -- Helper to create clean toggle row inside an Action Bar card
    local function CreateABToggleRow(parent, anchorTo, labelText, descText, key)
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(425, 40)
        row:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -6)

        local title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        title:SetText(labelText)

        local desc = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
        desc:SetText(descText)

        local btn = CreateFrame("Button", nil, row, ns.backdropTemplate)
        btn:SetSize(80, 22)
        btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        local btnTxt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnTxt:SetPoint("CENTER", btn, "CENTER", 0, 0)

        btn.UpdateState = function(self, isActive)
            if isActive then
                ns.ApplyModernBackdrop(btn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
                btnTxt:SetText("|cffffffffENABLED|r")
            else
                ns.ApplyModernBackdrop(btn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
                btnTxt:SetText("|cff8866aaDISABLED|r")
            end
        end

        btn:SetScript("OnClick", function()
            local db = ns.db or WOWForeverAddonDB
            if not db then return end
            local cur = db[key]
            if cur == nil then cur = ns.defaultSettings[key] end
            db[key] = not cur
            if key == "ActionBarAlwaysShowEmptySlots" then
                db.ActionBarShowGrid = db[key]
            end
            ns.RefreshGUIOptions()
            if ns.RefreshActionBarModernizer then ns.RefreshActionBarModernizer() end
        end)

        return row, btn
    end

    local rowIcons, btnIcons = CreateABToggleRow(abCard1, abc1Desc, "Clean Square Icons (Icon Zoom)", "Zooms 8% to strip blurry default Blizzard gray border.", "ActionBarCleanIcons")
    actionBarWidgets.cleanIconsBtn = btnIcons
    ns.AttachOptionTooltip(rowIcons, "Clean Square Icons (Icon Zoom)", "Zoomt Icons um 8% heran und schneidet den verschwommenen Blizzard-Graurand ab.", "Kompatibel mit nativem Edit Mode.", true)

    local rowBorder, btnBorder = CreateABToggleRow(abCard1, rowIcons, "1px Dark Slate Borders", "Adds a sleek pixel-perfect 1px border around buttons.", "ActionBarModernBorder")
    actionBarWidgets.modernBorderBtn = btnBorder
    ns.AttachOptionTooltip(rowBorder, "1px Dark Slate Borders", "Fügt einen gestochen scharfen 1-Pixel-Rahmen um jeden Aktionsbutton hinzu.", nil, true)

    local rowGryph, btnGryph = CreateABToggleRow(abCard1, rowBorder, "Hide Gryphons & Background Art", "Removes lion/gryphon endcaps, divider textures and bar art.", "ActionBarHideGryphons")
    actionBarWidgets.hideGryphonsBtn = btnGryph
    ns.AttachOptionTooltip(rowGryph, "Hide Gryphons & Background Art", "Entfernt die Blizzard-Greifen, Löwen und Balkengrafiken an den Leisten.", nil, true)

    local rowEmpty, btnEmpty = CreateABToggleRow(abCard1, rowGryph, "Always Show Empty Slots (Dock Grid)", "Keep empty action button slots permanently visible.", "ActionBarAlwaysShowEmptySlots")
    actionBarWidgets.showGridBtn = btnEmpty
    actionBarWidgets.alwaysShowEmptyBtn = btnEmpty
    ns.AttachOptionTooltip(rowEmpty, "Always Show Empty Slots (Grid)", "Hält leere Aktions-Slots dauerhaft sichtbar als Dock-Gitter.", nil, true)

    -- Slot Background Opacity Slider
    local slotAlphaSlider = CreateCustomSlider(
        abCard1,
        "YAQoLActionBarSlotAlphaSlider",
        0.0, 1.0, 0.05,
        "0% (Glass)", "100% (Solid)",
        function()
            local db = ns.db or WOWForeverAddonDB
            return db and db.ActionBarSlotBgAlpha or 0.85
        end,
        function(val)
            local db = ns.db or WOWForeverAddonDB
            if db and math.abs((db.ActionBarSlotBgAlpha or 0.85) - val) > 0.01 then
                db.ActionBarSlotBgAlpha = val
                if ns.RefreshActionBarModernizer then
                    ns.RefreshActionBarModernizer()
                end
            end
        end,
        function(val)
            return string.format("|cffda99ffEmpty Slot Opacity:|r |cffffffff%d%%|r", math.floor(val * 100 + 0.5))
        end
    )
    slotAlphaSlider:SetWidth(410)
    slotAlphaSlider:SetPoint("TOPLEFT", rowEmpty, "BOTTOMLEFT", 10, -22)
    actionBarWidgets.slotBgAlphaSlider = slotAlphaSlider
    ns.AttachOptionTooltip(slotAlphaSlider, "Empty Slot Opacity", "Bestimmt die Hintergrund-Deckkraft für leere Aktions-Slots (0% = Unsichtbar, 100% = Voll deckend).", nil, "85%")

-- Card 2: Hotkeys & Keybind Display
local abCard2 = CreateFrame("Frame", nil, p9Content, ns.backdropTemplate)
abCard2:SetSize(455, 180)
abCard2:SetPoint("TOPLEFT", abCard1, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(abCard2, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local abc2Title = abCard2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
abc2Title:SetPoint("TOPLEFT", abCard2, "TOPLEFT", 14, -10)
abc2Title:SetText("|cffda99ffHotkeys & Keybind Display|r")

local abc2Desc = abCard2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
abc2Desc:SetPoint("TOPLEFT", abc2Title, "BOTTOMLEFT", 0, -3)
abc2Desc:SetText("|cffa388ccStreamer-grade short keybind abbreviations and text visibility.|r")

local rowShort, btnShort = CreateABToggleRow(abCard2, abc2Desc, "Smart Short Keybinds", "Shortens binds: Shift-R -> SR, Ctrl-R -> sR, Num1 -> N1, M3, WD, WU.", "ActionBarShortHotkeys")
actionBarWidgets.shortHotkeysBtn = btnShort
ns.AttachOptionTooltip(rowShort, "Smart Short Keybinds", "Verkürzt lange Tastenbelegungen (z.B. Strg-1 zu SR, Shift-1 zu S1, Mausrad zu WU/WD).", nil, true)

local rowHideHot, btnHideHot = CreateABToggleRow(abCard2, rowShort, "Hide Keybind Text", "Completely hide hotkey labels for maximum minimalist look.", "ActionBarHideHotkeys")
actionBarWidgets.hideHotkeysBtn = btnHideHot
ns.AttachOptionTooltip(rowHideHot, "Hide Keybind Text", "Blendet Tastenkürzel auf allen Buttons aus für maximale Übersicht.", nil, false)

local rowMacro, btnMacro = CreateABToggleRow(abCard2, rowHideHot, "Hide Macro Names", "Hides macro title text at the bottom of action buttons.", "ActionBarHideMacroNames")
actionBarWidgets.hideMacroBtn = btnMacro
ns.AttachOptionTooltip(rowMacro, "Hide Macro Names", "Blendet Makro-Namen auf Buttons aus.", nil, false)

-- Card 3: Edit Mode & Layout Integration
local abCard3 = CreateFrame("Frame", nil, p9Content, ns.backdropTemplate)
abCard3:SetSize(455, 100)
abCard3:SetPoint("TOPLEFT", abCard2, "BOTTOMLEFT", 0, -10)
ns.ApplyModernBackdrop(abCard3, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

local abc3Title = abCard3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
abc3Title:SetPoint("TOPLEFT", abCard3, "TOPLEFT", 14, -12)
abc3Title:SetText("|cffda99ffEdit Mode & Layout Integration|r")

local abc3Desc = abCard3:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
abc3Desc:SetPoint("TOPLEFT", abc3Title, "BOTTOMLEFT", 0, -6)
abc3Desc:SetPoint("RIGHT", abCard3, "RIGHT", -14, 0)
abc3Desc:SetJustifyH("LEFT")
abc3Desc:SetText("|cffa388ccLeisten-Positionen, Ausrichtung, Zeilenanzahl sowie Button-Abstand (Icon-Abstand) und Skalierung werden direkt über den offiziellen WoW Edit Mode gesteuert (wie bei EllesmereUI). YAQoL veredelt deine Leisten visuell mit Clean Square Icons, 1px Border, leeren Sockeln und kurzen Keybinds – ohne Taint oder Layout-Konflikte.|r")

end

----------------------------------------------------
-- SEARCH REGISTRY & SEARCH RESULTS PANEL
----------------------------------------------------
ns.SETTINGS_SEARCH_INDEX = {
    -- ACTION BARS VISIBILITY
    { key = "MainMenuBar", name = "Aktionsleiste 1 (Hauptleiste)", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der primären Aktionsleiste (Shown / Hidden / Mouseover).",
      keywords = "bar 1 actionbar main action leiste 1 hauptleiste", default = "SHOWN" },
    { key = "MultiBarBottomLeft", name = "Aktionsleiste 2 (Unten Links)", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der zweiten Aktionsleiste über der Hauptleiste.",
      keywords = "bar 2 actionbar leiste 2 unten links bottomleft", default = "SHOWN" },
    { key = "MultiBarBottomRight", name = "Aktionsleiste 3 (Unten Rechts)", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der dritten Aktionsleiste.",
      keywords = "bar 3 actionbar leiste 3 unten rechts bottomright", default = "SHOWN" },
    { key = "MultiBarRight", name = "Aktionsleiste 4 (Rechts 1)", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der rechten vertikalen Leiste 1.",
      keywords = "bar 4 actionbar leiste 4 rechts right", default = "SHOWN" },
    { key = "MultiBarLeft", name = "Aktionsleiste 5 (Rechts 2)", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der rechten vertikalen Leiste 2.",
      keywords = "bar 5 actionbar leiste 5 rechts links left", default = "SHOWN" },
    { key = "MultiBar5", name = "Aktionsleiste 6", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der Aktionsleiste 6.",
      keywords = "bar 6 actionbar leiste 6", default = "SHOWN" },
    { key = "MultiBar6", name = "Aktionsleiste 7", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der Aktionsleiste 7.",
      keywords = "bar 7 actionbar leiste 7", default = "SHOWN" },
    { key = "MultiBar7", name = "Aktionsleiste 8", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der Aktionsleiste 8.",
      keywords = "bar 8 actionbar leiste 8", default = "SHOWN" },
    { key = "PetActionBar", name = "Pet Bar (Begleiterleiste)", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der Begleiterleiste für Jäger und Hexenmeister.",
      keywords = "pet bar begleiter petactionbar petbar", default = "SHOWN" },
    { key = "StanceBar", name = "Stance Bar (Haltungsleiste)", pageId = 9, category = "Aktionsleisten", type = "visibility",
      desc = "Sichtbarkeit der Haltungs-, Auren- oder Gestaltleiste.",
      keywords = "stance bar haltung gestalt aura druide krieger paladin stancebar", default = "SHOWN" },

    -- ACTION BAR MODERNIZATION
    { key = "ActionBarCleanIcons", name = "Clean Square Icons (Icon Zoom)", pageId = 9, category = "Aktionsleisten", type = "toggle",
      desc = "Zoomt Icons um 8% heran, um den verschwommenen Blizzard-Graurand abzuschneiden.",
      keywords = "icon zoom square eckig sauber clean cut border rand", default = true },
    { key = "ActionBarModernBorder", name = "1px Dark Slate Borders", pageId = 9, category = "Aktionsleisten", type = "toggle",
      desc = "Fügt einen dezenten, gestochen scharfen 1-Pixel-Rand um jeden Aktionsbutton hinzu.",
      keywords = "1px border rahmen pixel border slate dunkler rand", default = true },
    { key = "ActionBarHideGryphons", name = "Hide Gryphons & Background Art", pageId = 9, category = "Aktionsleisten", type = "toggle",
      desc = "Entfernt die Blizzard-Greifen, Löwen und Balkengrafiken an den Leisten.",
      keywords = "gryphons greifen loewen löwen art background balken texture", default = true },
    { key = "ActionBarAlwaysShowEmptySlots", name = "Always Show Empty Slots (Grid)", pageId = 9, category = "Aktionsleisten", type = "toggle",
      desc = "Hält leere Aktions-Slots dauerhaft sichtbar als Dock-Gitter.",
      keywords = "grid leere slots empty show always gitter hintergrund dock", default = true },
    { key = "ActionBarShortHotkeys", name = "Smart Short Keybinds", pageId = 9, category = "Aktionsleisten", type = "toggle",
      desc = "Verkürzt lange Tastenbelegungen (z.B. Strg-1 zu SR, Shift-1 zu S1, Mausrad zu WU/WD).",
      keywords = "hotkey keybind tasten kurz short tastaturbelegung bind sr s1", default = true },
    { key = "ActionBarHideHotkeys", name = "Hide Keybind Text", pageId = 9, category = "Aktionsleisten", type = "toggle",
      desc = "Blendet Tastenkürzel-Texte auf allen Buttons komplett aus.",
      keywords = "hide hotkeys keybinds verstecken tasten ausblenden", default = false },
    { key = "ActionBarHideMacroNames", name = "Hide Macro Names", pageId = 9, category = "Aktionsleisten", type = "toggle",
      desc = "Blendet Makro-Namen auf Buttons aus für maximale Übersicht.",
      keywords = "macro makro namen text ausblenden hide", default = false },

    -- BLIZZUI VISIBILITY
    { key = "PlayerFrame", name = "Player Unit Frame", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit des eigenen Spieler-Porträts / Lebensbalkens.",
      keywords = "player frame spieler portraet portrait leben hp unit", default = "SHOWN" },
    { key = "TargetFrame", name = "Target Unit Frame", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit des Ziel-Porträts und Lebensbalkens.",
      keywords = "target frame ziel gegner portrait unit", default = "SHOWN" },
    { key = "FocusFrame", name = "Focus Unit Frame", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit des Fokus-Ziels.",
      keywords = "focus frame fokus unit", default = "SHOWN" },
    { key = "MinimapCluster", name = "Minimap Cluster", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit der Minimap und des umgebenden Rahmens.",
      keywords = "minimap karte radar cluster", default = "SHOWN" },
    { key = "ObjectiveTrackerFrame", name = "Quest / Objective Tracker", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit der Quest-Verfolgung am rechten Bildschirmrand.",
      keywords = "quest tracker watchframe objective questlog aufgaben", default = "SHOWN" },
    { key = "ChatFrame1", name = "Chat Window", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit des Haupt-Chatfensters.",
      keywords = "chat fenster window text", default = "SHOWN" },
    { key = "BuffFrame", name = "Buffs & Debuffs", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit der Blizzard Stärkungs- und Schwächungszauber oben rechts.",
      keywords = "buff debuff stärkungszauber auren oben", default = "SHOWN" },
    { key = "MicroMenu", name = "Micro Menu Bar", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit der kleinen Menü-Buttons (Charakter, Talente, Zauberbuch).",
      keywords = "micro menu mikromenü buttons charakter talente", default = "MOUSEOVER" },
    { key = "BagsBar", name = "Bags Bar (Taschenleiste)", pageId = 1, category = "BlizzUI Display", type = "visibility",
      desc = "Sichtbarkeit der Taschen-Buttons und des Rucksacks.",
      keywords = "bags bar taschen rucksack inventar bag", default = "MOUSEOVER" },

    -- GENERAL QOL
    { key = "AutoQuest", name = "Auto Quest Automator", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Nimmt Quests automatisch an und schließt sie ab (Shift halten zum Umgehen).",
      keywords = "quest auto annehmen abgeben turn in accept complete", default = true },
    { key = "AutoRepair", name = "Auto Repair Gear", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Repariert Ausrüstung automatisch beim Händler und gibt Kosten im Chat aus.",
      keywords = "repair reparieren ausrüstung gold händler merchant", default = false },
    { key = "AutoSellGreys", name = "Auto Sell Junk (Greys)", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Verkauft graue Müll-Gegenstände automatisch beim Öffnen eines Händlers.",
      keywords = "sell greys junk schrott grau verkaufen merchant händler", default = true },
    { key = "FastLoot", name = "Fast Speed Looting", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Plündert alle Gegenstände in einem einzigen Tick ohne künstliche Verzögerung.",
      keywords = "fast loot schnell plündern beute drop instant", default = true },
    { key = "MaxCameraZoom", name = "Max Camera Distance", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Erhöht die maximale Kamera-Entfernung für bessere Kampfübersicht.",
      keywords = "camera zoom kamera abstand sicht distance max", default = true },
    { key = "HideRedErrors", name = "Hide Red Combat Errors", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Filtert störende rote Fehlermeldungen (z.B. 'Nicht genug Energie', 'Fähigkeit nicht bereit').",
      keywords = "error fehler rot red combat kampf uierrorsframe cooldown wut mana", default = true },
    { key = "AutoDismount", name = "Auto-Dismount on Action", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Sitzt beim Wirken von Zaubern oder Aktionen automatisch vom Reittier ab.",
      keywords = "dismount mount reittier absitzen zaubern cast", default = true },
    { key = "ChatCopyURL", name = "Chat: Clickable URL Links", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Macht Web- und Discord-Links im Chat klickbar mit praktischem Kopier-Dialog.",
      keywords = "url link copy kopieren chat webadresse discord", default = true },
    { key = "ChatClassColors", name = "Chat: Class Colored Names", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Färbt Spielernamen im Chat automatisch in ihren Klassenfarben ein.",
      keywords = "chat class colors klassenfarben name farbe spieler", default = true },
    { key = "ChatShortChannels", name = "Chat: Short Channel Tags", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Kürzt Kanalnamen ab (z.B. [1. Allgemein] -> [1], [Gilde] -> [G]).",
      keywords = "chat short channels kanal kanäle abkürzen [g] [1]", default = true },
    { key = "QuestAutoMarkTarget", name = "Quest Mob: Target Auto-Marker", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Setzt automatisch den Totenkopf-Raidmarker auf dein anvisiertes Ziel, wenn es für eine aktive Quest benötigt wird.",
      keywords = "quest mob marker totenkopf skull auto raidmarker target ziel", default = true },
    { key = "QuestNameplateHighlight", name = "Quest Mob: Nameplate Icon & Fortschritt", pageId = 2, category = "General QoL", type = "toggle",
      desc = "Zeigt ein goldenes Quest-Icon und den Ziel-Fortschritt (z.B. [0/8]) direkt über den Namensplaketten von Quest-Gegnern an.",
      keywords = "quest mob nameplate plakette icon symbol highlight leiste", default = true },

    -- BUFF & PET REMINDERS
    { key = "BuffReminder", name = "Buff Reminder Master", pageId = 3, category = "Buff & Pet Reminders", type = "toggle",
      desc = "Blendet ein dezentes Symbol ein, wenn Klassen-Buffs fehlen.",
      keywords = "buff reminder fehlende buffs auren stärkungszauber", default = true },
    { key = "PetReminder", name = "Pet Reminder Master", pageId = 3, category = "Buff & Pet Reminders", type = "toggle",
      desc = "Erinnert Jäger und Hexenmeister daran, wenn ihr Begleiter nicht aktiv ist.",
      keywords = "pet reminder begleiter fehlen petactionbar jager hexer", default = true },

    -- MINIMAP COLLECTOR BAR
    { key = "MinimapBarEnabled", name = "Minimap Collector Bar (HidingBar)", pageId = 4, category = "Minimap HidingBar", type = "toggle",
      desc = "Sammelt Addon-Symbole an der Minimap in einer eleganten Leiste.",
      keywords = "minimap bar collector hidingbar addons leiste minimapbar", default = true },
    { key = "MinimapBarMouseover", name = "Minimap Bar Mouseover Fade", pageId = 4, category = "Minimap HidingBar", type = "toggle",
      desc = "Blendet die Addon-Leiste nur ein, wenn du mit der Maus darüber fährst.",
      keywords = "minimap bar mouseover einblenden fade maus", default = true },
    { key = "MinimapBarSnapToEdge", name = "Snap to Screen Edge", pageId = 4, category = "Minimap HidingBar", type = "toggle",
      desc = "Dockt die Leiste automatisch am linken oder rechten Bildschirmrand an.",
      keywords = "minimap bar snap dock andocken rand", default = true },

    -- LEVELING & ANALYTICS
    { key = "XPBarEnabled", name = "Custom XP & Leveling Bar", pageId = 6, category = "XP Bar & Analytics", type = "toggle",
      desc = "Aktiviert die moderne, minimalistische Erfahrungsleiste.",
      keywords = "xp bar leveling erfahrung level levelbar fortschritt", default = true },
    { key = "XPBarShowStats", name = "XP Bar Stats & Rested Numbers", pageId = 6, category = "XP Bar & Analytics", type = "toggle",
      desc = "Zeigt genaue XP-Zahlen und Erholt-Boni auf der Leiste an.",
      keywords = "xp stats zahlen prozent erholt rested", default = true },
    { key = "XPBarShowQuestOverlay", name = "Quest XP Preview Overlay", pageId = 6, category = "XP Bar & Analytics", type = "toggle",
      desc = "Zeigt den Erfahrungs-Vorschauwert für fertige und aktive Quests auf der XP-Leiste an.",
      keywords = "quest xp overlay vorschau preview questfortschritt", default = true },
    { key = "LevelUpBannerEnabled", name = "Level-Up Fanfare Banner", pageId = 6, category = "XP Bar & Analytics", type = "toggle",
      desc = "Spielt beim Stufenaufstieg ein elegantes Banner mit Fanfare ab.",
      keywords = "levelup level banner fanfare stufenaufstieg gratulation", default = true },
    { key = "LevelUpScreenshot", name = "Auto-Screenshot on Level-Up", pageId = 6, category = "XP Bar & Analytics", type = "toggle",
      desc = "Erstellt automatisch einen Screenshot, wenn dein Charakter ein Level aufsteigt.",
      keywords = "screenshot bildschirmfoto level aufstieg bild photo", default = true },
}

local searchEditBox = nil
local searchStatusText = nil
local searchContent = nil
local searchScroll = nil
local resultCards = {}
local switchPageFn = nil

local function GetOrCreateResultCard(index)
    if resultCards[index] then return resultCards[index] end

    local card = CreateFrame("Frame", nil, searchContent, ns.backdropTemplate)
    card:SetSize(455, 58)
    ns.ApplyModernBackdrop(card, 0.07, 0.04, 0.11, 0.8, 0.28, 0.12, 0.45, 0.6)

    local catBadge = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catBadge:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -8)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("LEFT", catBadge, "RIGHT", 6, 0)

    local desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", catBadge, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("RIGHT", card, "RIGHT", -190, 0)
    desc:SetJustifyH("LEFT")

    -- Jump button: [Tab ->]
    local jumpBtn = CreateFrame("Button", nil, card, ns.backdropTemplate)
    jumpBtn:SetSize(62, 22)
    jumpBtn:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    ns.ApplyModernBackdrop(jumpBtn, 0.16, 0.08, 0.24, 0.8, 0.35, 0.16, 0.55, 0.8)

    local jumpText = jumpBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    jumpText:SetPoint("CENTER", jumpBtn, "CENTER", 0, 0)
    jumpText:SetText("|cffe0b3ffTab ->|r")

    jumpBtn:SetScript("OnEnter", function(self)
        ns.ApplyModernBackdrop(self, 0.35, 0.15, 0.55, 0.95, 0.75, 0.3, 1.0, 1)
    end)
    jumpBtn:SetScript("OnLeave", function(self)
        ns.ApplyModernBackdrop(self, 0.16, 0.08, 0.24, 0.8, 0.35, 0.16, 0.55, 0.8)
    end)

    -- Toggle button for type == "toggle"
    local toggleBtn = CreateFrame("Button", nil, card, ns.backdropTemplate)
    toggleBtn:SetSize(80, 22)
    toggleBtn:SetPoint("RIGHT", jumpBtn, "LEFT", -6, 0)

    local toggleText = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleText:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)

    -- Visibility pill container for type == "visibility"
    local visFrame = CreateFrame("Frame", nil, card)
    visFrame:SetSize(96, 22)
    visFrame:SetPoint("RIGHT", jumpBtn, "LEFT", -6, 0)

    local function CreatePill(xOffset, textLabel, mode, color)
        local pill = CreateFrame("Button", nil, visFrame, ns.backdropTemplate)
        pill:SetSize(30, 22)
        pill:SetPoint("LEFT", visFrame, "LEFT", xOffset, 0)
        local pt = pill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pt:SetPoint("CENTER", pill, "CENTER", 0, 0)
        pt:SetText(textLabel)
        pill.label = pt
        pill.mode = mode
        pill.color = color
        return pill
    end

    local pillS = CreatePill(0, "S", "SHOWN", {0.45, 0.15, 0.7})
    local pillH = CreatePill(33, "H", "HIDDEN", {0.55, 0.1, 0.25})
    local pillM = CreatePill(66, "M", "MOUSEOVER", {0.6, 0.25, 0.15})

    resultCards[index] = {
        card = card,
        catBadge = catBadge,
        title = title,
        desc = desc,
        jumpBtn = jumpBtn,
        toggleBtn = toggleBtn,
        toggleText = toggleText,
        visFrame = visFrame,
        pillS = pillS,
        pillH = pillH,
        pillM = pillM,
    }
    return resultCards[index]
end

function ns.PerformSearch(query)
    if not contentPanels["search"] then return end

    if not query or strtrim(query) == "" then
        contentPanels["search"]:Hide()
        for id, panel in pairs(contentPanels) do
            if id == currentActivePage then panel:Show() else panel:Hide() end
        end
        return
    end

    query = strtrim(query):lower()

    for id, panel in pairs(contentPanels) do
        if id == "search" then panel:Show() else panel:Hide() end
    end

    local terms = {}
    for term in query:gmatch("%S+") do
        table.insert(terms, term)
    end

    local matches = {}
    for _, item in ipairs(ns.SETTINGS_SEARCH_INDEX) do
        local haystack = (item.name .. " " .. item.desc .. " " .. item.category .. " " .. (item.keywords or "") .. " " .. item.key):lower()
        local allMatch = true
        for _, term in ipairs(terms) do
            if not haystack:find(term, 1, true) then
                allMatch = false
                break
            end
        end
        if allMatch then
            table.insert(matches, item)
        end
    end

    if #matches == 0 then
        searchStatusText:SetText(string.format("|cffff5577Keine Einstellungen gefunden für |r|cffffffff\"%s\"|r\n|cffa388ccSuchtipps: 'loot', 'bar', 'tasche', 'quest', 'hotkey', 'error', 'buff', 'zoom'|r", query))
        for _, w in ipairs(resultCards) do w.card:Hide() end
        searchContent:SetSize(460, 100)
        return
    end

    searchStatusText:SetText(string.format("|cffda99ff%d Treffer gefunden für |r|cffffffff\"%s\"|r:", #matches, query))

    for i, item in ipairs(matches) do
        local w = GetOrCreateResultCard(i)
        w.card:ClearAllPoints()
        w.card:SetPoint("TOPLEFT", searchContent, "TOPLEFT", 0, -(i - 1) * 62)
        w.card:Show()

        w.catBadge:SetText("|cffbf55ff[" .. item.category .. "]|r")
        w.title:SetText("|cffda99ff" .. item.name .. "|r")
        w.desc:SetText("|cffa388cc" .. item.desc .. "|r")

        ns.AttachOptionTooltip(w.card, item.name, item.desc, "Kategorie: " .. item.category, item.default)

        w.jumpBtn:SetScript("OnClick", function()
            if searchEditBox then
                searchEditBox:SetText("")
                searchEditBox:ClearFocus()
            end
            if switchPageFn then
                switchPageFn(item.pageId)
            end
        end)
        ns.AttachOptionTooltip(w.jumpBtn, "Kategorie öffnen", "Springt direkt zum Tab '" .. item.category .. "'.")

        local db = ns.db or WOWForeverAddonDB
        if item.type == "toggle" then
            w.visFrame:Hide()
            w.toggleBtn:Show()

            local val = db and db[item.key]
            if val == nil then val = ns.defaultSettings[item.key] end
            local isEnabled = (val == true)

            if isEnabled then
                ns.ApplyModernBackdrop(w.toggleBtn, 0.45, 0.15, 0.7, 0.9, 0.75, 0.3, 1.0, 1)
                w.toggleText:SetText("|cffffffffENABLED|r")
            else
                ns.ApplyModernBackdrop(w.toggleBtn, 0.12, 0.07, 0.18, 0.6, 0.25, 0.12, 0.35, 0.5)
                w.toggleText:SetText("|cff8866aaDISABLED|r")
            end

            w.toggleBtn:SetScript("OnClick", function()
                local cur = db[item.key]
                if cur == nil then cur = ns.defaultSettings[item.key] end
                local newVal = not cur
                db[item.key] = newVal
                if item.key == "MaxCameraZoom" then
                    SetCVar("cameraDistanceMaxZoomFactor", newVal and 2.6 or 1.9)
                elseif item.key == "ActionBarAlwaysShowEmptySlots" then
                    db.ActionBarShowGrid = newVal
                end
                if item.key:find("^ActionBar") and ns.RefreshActionBarModernizer then
                    ns.RefreshActionBarModernizer()
                end
                if item.key:find("^Chat") and ns.UpdateChatSettings then
                    ns.UpdateChatSettings()
                end
                if item.key == "QuestNameplateHighlight" and ns.RefreshQuestNameplates then
                    ns.RefreshQuestNameplates()
                end
                ns.RefreshGUIOptions()
                ns.PerformSearch(query)
            end)

        elseif item.type == "visibility" then
            w.toggleBtn:Hide()
            w.visFrame:Show()

            local currentMode = db and db[item.key]
            if currentMode == nil then currentMode = ns.defaultSettings[item.key] or "SHOWN" end

            local function UpdatePill(pill, isActive)
                if isActive then
                    ns.ApplyModernBackdrop(pill, pill.color[1], pill.color[2], pill.color[3], 0.9, pill.color[1]*1.4, pill.color[2]*1.4, pill.color[3]*1.4, 1)
                    pill.label:SetText("|cffffffff" .. pill.mode:sub(1,1) .. "|r")
                else
                    ns.ApplyModernBackdrop(pill, 0.1, 0.06, 0.16, 0.6, 0.2, 0.1, 0.3, 0.5)
                    pill.label:SetText("|cff8866aa" .. pill.mode:sub(1,1) .. "|r")
                end
            end

            UpdatePill(w.pillS, currentMode == "SHOWN")
            UpdatePill(w.pillH, currentMode == "HIDDEN")
            UpdatePill(w.pillM, currentMode == "MOUSEOVER")

            local function PillClick(mode)
                db[item.key] = mode
                ns.ApplyFrameState(item.key, mode)
                ns.RefreshGUIOptions()
                ns.PerformSearch(query)
            end

            w.pillS:SetScript("OnClick", function() PillClick("SHOWN") end)
            w.pillH:SetScript("OnClick", function() PillClick("HIDDEN") end)
            w.pillM:SetScript("OnClick", function() PillClick("MOUSEOVER") end)

            ns.AttachOptionTooltip(w.pillS, "Shown", "Dauerhaft anzeigen.")
            ns.AttachOptionTooltip(w.pillH, "Hidden", "Dauerhaft verbergen.")
            ns.AttachOptionTooltip(w.pillM, "Mouseover", "Nur beim Drüberfahren mit der Maus anzeigen.")
        end
    end

    for i = #matches + 1, #resultCards do
        resultCards[i].card:Hide()
    end

    searchContent:SetSize(460, #matches * 62 + 30)
end

local function CreateSearchPanel(contentArea)
    local searchPanel = CreateFrame("Frame", "YAQoLSearchPanel", contentArea)
    searchPanel:SetAllPoints()
    searchPanel:Hide()
    contentPanels["search"] = searchPanel

    local sScroll = CreateFrame("ScrollFrame", "YAQoLSearchScrollFrame", searchPanel, "UIPanelScrollFrameTemplate")
    sScroll:SetPoint("TOPLEFT", searchPanel, "TOPLEFT", 0, -32)
    sScroll:SetPoint("BOTTOMRIGHT", searchPanel, "BOTTOMRIGHT", -10, 0)
    ns.StyleCustomScrollFrame(sScroll)
    searchScroll = sScroll

    local sContent = CreateFrame("Frame", "YAQoLSearchContent", sScroll)
    sContent:SetSize(460, 200)
    sScroll:SetScrollChild(sContent)
    searchPanel.content = sContent
    searchContent = sContent

    local sStatus = searchPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sStatus:SetPoint("TOPLEFT", searchPanel, "TOPLEFT", 6, -6)
    sStatus:SetPoint("RIGHT", searchPanel, "RIGHT", -10, 0)
    sStatus:SetJustifyH("LEFT")
    sStatus:SetText("|cffa388ccGib einen Suchbegriff ein...|r")
    searchStatusText = sStatus
end

local function CreateSearchBar(optionsFrame, contentArea, onSwitchPage)
    switchPageFn = onSwitchPage
    local searchContainer = CreateFrame("Frame", "YAQoLSearchBarContainer", optionsFrame, ns.backdropTemplate)
    searchContainer:SetSize(210, 24)
    local closeBtn = optionsFrame.closeBtn
    if closeBtn then
        searchContainer:SetPoint("RIGHT", closeBtn, "LEFT", -10, 0)
    else
        searchContainer:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -48, -12)
    end
    ns.ApplyModernBackdrop(searchContainer, 0.07, 0.04, 0.11, 0.9, 0.35, 0.16, 0.55, 0.7)

    local searchIcon = searchContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    searchIcon:SetPoint("LEFT", searchContainer, "LEFT", 8, 0)
    searchIcon:SetText("|cffa388cc🔍|r")

    local clearBtn = CreateFrame("Button", nil, searchContainer)
    clearBtn:SetSize(16, 16)
    clearBtn:SetPoint("RIGHT", searchContainer, "RIGHT", -4, 0)
    clearBtn:Hide()

    local clearText = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clearText:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
    clearText:SetText("|cffa388ccx|r")

    clearBtn:SetScript("OnEnter", function() clearText:SetText("|cffffffffx|r") end)
    clearBtn:SetScript("OnLeave", function() clearText:SetText("|cffa388ccx|r") end)

    local editBox = CreateFrame("EditBox", "YAQoLSearchEditBox", searchContainer)
    editBox:SetPoint("LEFT", searchContainer, "LEFT", 26, 0)
    editBox:SetPoint("RIGHT", searchContainer, "RIGHT", -22, 0)
    editBox:SetHeight(20)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetAutoFocus(false)
    searchEditBox = editBox

    local placeholder = editBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("LEFT", editBox, "LEFT", 0, 0)
    placeholder:SetText("|cff775599Suche / Search...|r")

    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and text ~= "" then
            placeholder:Hide()
            clearBtn:Show()
        else
            placeholder:Show()
            clearBtn:Hide()
        end
        ns.PerformSearch(text)
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        ns.PerformSearch("")
    end)

    editBox:SetScript("OnEditFocusGained", function(self)
        ns.ApplyModernBackdrop(searchContainer, 0.12, 0.06, 0.18, 0.98, 0.75, 0.3, 1.0, 1.0)
    end)

    editBox:SetScript("OnEditFocusLost", function(self)
        ns.ApplyModernBackdrop(searchContainer, 0.07, 0.04, 0.11, 0.9, 0.35, 0.16, 0.55, 0.7)
    end)

    clearBtn:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:ClearFocus()
        ns.PerformSearch("")
    end)

    ns.AttachOptionTooltip(searchContainer, "Einstellungen durchsuchen", "Tippe hier einen beliebigen Begriff ein (z.B. 'loot', 'bar', 'quest', 'hotkey'), um passende Einstellungen sofort zu finden und direkt umzuschalten.")

    return searchContainer
end

function ns.CreateOptionsGUI()
    if optionsFrame then return end

    optionsFrame = CreateFrame("Frame", "WOWForeverAddonMainFrame", UIParent, ns.backdropTemplate)
    tinsert(UISpecialFrames, "WOWForeverAddonMainFrame")
    tinsert(UISpecialFrames, "YAQoLMainFrame")
    optionsFrame:SetSize(720, 580)
    optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    optionsFrame:SetFrameStrata("HIGH")
    optionsFrame:SetClampedToScreen(true)

    if optionsFrame.SetResizable then optionsFrame:SetResizable(true) end
    if optionsFrame.SetResizeBounds then
        optionsFrame:SetResizeBounds(680, 450, 1050, 850)
    elseif optionsFrame.SetMinResize then
        optionsFrame:SetMinResize(680, 450)
        optionsFrame:SetMaxResize(1050, 850)
    end

    -- Dark Violet Void Backdrop with Glowing Amethyst Border
    ns.ApplyModernBackdrop(optionsFrame, 0.05, 0.03, 0.08, 0.97, 0.55, 0.2, 0.85, 0.9)

    -- Top Electric Violet Glowing Accent Line
    local topBar = optionsFrame:CreateTexture(nil, "OVERLAY")
    topBar:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -1, -1)
    topBar:SetHeight(3)
    topBar:SetColorTexture(0.72, 0.25, 1.0, 1.0)

    -- Title & Subtitle for YAQoL
    local verStr = (C_AddOns and C_AddOns.GetAddOnMetadata) and C_AddOns.GetAddOnMetadata("YAQoL", "Version") or (GetAddOnMetadata and GetAddOnMetadata("YAQoL", "Version")) or "2.0.11"
    local title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 22, -16)
    title:SetText("|cffc866ffYAQoL|r  |cff775599•|r  |cffffffffYet Another Quality of Life|r  |cff00ffccv" .. tostring(verStr) .. "|r")

    local subtitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("|cffa388ccClean UI Visibility & Quality of Life Automations.|r")

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, optionsFrame, ns.backdropTemplate)
    closeBtn:SetSize(28, 24)
    closeBtn:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -12, -12)
    optionsFrame.closeBtn = closeBtn
    ns.ApplyModernBackdrop(closeBtn, 0.12, 0.06, 0.18, 0.8, 0.45, 0.18, 0.65, 0.6)
    
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeText:SetText("|cffccaaffX|r")

    closeBtn:SetScript("OnEnter", function()
        ns.ApplyModernBackdrop(closeBtn, 0.75, 0.12, 0.3, 0.95, 1.0, 0.2, 0.4, 1)
        closeText:SetText("|cffffffffX|r")
    end)
    closeBtn:SetScript("OnLeave", function()
        ns.ApplyModernBackdrop(closeBtn, 0.12, 0.06, 0.18, 0.8, 0.45, 0.18, 0.65, 0.6)
        closeText:SetText("|cffccaaffX|r")
    end)
    closeBtn:SetScript("OnClick", function() optionsFrame:Hide() end)

    ----------------------------------------------------
    -- LEFT SIDEBAR NAVIGATION PANE
    ----------------------------------------------------
    local sidebar = CreateFrame("Frame", nil, optionsFrame, ns.backdropTemplate)
    sidebar:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 16, -62)
    sidebar:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 16, 50)
    sidebar:SetWidth(180)
    ns.ApplyModernBackdrop(sidebar, 0.03, 0.02, 0.06, 0.9, 0.25, 0.12, 0.4, 0.6)

    -- Container for right-hand content panels
    local contentArea = CreateFrame("Frame", nil, optionsFrame)
    contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 14, 0)
    contentArea:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -16, 50)

    -- Define Nav Pages for YAQoL v2.0
    local pages = {
        { id = 1, category = "MAIN FEATURES", label = "BlizzUI Display" },
        { id = 9, category = "MAIN FEATURES", label = "Aktionsleisten" },
        { id = 6, category = "LEVELING FEATURES", label = "XP Bar & Analytics" },
        { id = 2, category = "QUALITY OF LIFE", label = "General QoL" },
        { id = 3, category = "QUALITY OF LIFE", label = "Buff & Pet Reminders" },
        { id = 4, category = "QUALITY OF LIFE", label = "Minimap HidingBar" },
        { id = 7, category = "PROFILES & SHARING", label = "Profiles & Export" },
        { id = 8, category = "COMMUNITY", label = "Credits & Socials" },
        { id = 5, category = "DEVELOPMENT", label = "Debug Logs & DB Dump" },
    }

    local yOffset = -12
    local lastCategory = ""

    local function SwitchSidebarPage(pageId)
        currentActivePage = pageId
        if searchEditBox and searchEditBox:GetText() ~= "" then
            searchEditBox:SetText("")
            searchEditBox:ClearFocus()
        end
        if contentPanels["search"] then
            contentPanels["search"]:Hide()
        end
        for id, btn in pairs(sidebarButtons) do
            if id == pageId then
                ns.ApplyModernBackdrop(btn, 0.38, 0.12, 0.6, 0.9, 0.75, 0.3, 1.0, 1)
                btn.text:SetText("|cffffffff" .. btn.labelStr .. "|r")
                if btn.glowBar then btn.glowBar:Show() end
            else
                ns.ApplyModernBackdrop(btn, 0.07, 0.04, 0.11, 0.5, 0.22, 0.1, 0.35, 0.4)
                btn.text:SetText("|cffa388cc" .. btn.labelStr .. "|r")
                if btn.glowBar then btn.glowBar:Hide() end
            end
        end

        for id, panel in pairs(contentPanels) do
            if id == pageId then panel:Show() else panel:Hide() end
        end

        if pageId == 7 then
            if p7Scroll and p7Scroll.SetVerticalScroll then
                p7Scroll:SetVerticalScroll(0)
            end
            if ns.RefreshProfileGUI then
                ns.RefreshProfileGUI()
            end
        end
    end

    for _, pageDef in ipairs(pages) do
        -- Category Header if changed
        if pageDef.category ~= lastCategory then
            lastCategory = pageDef.category
            local catHeader = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            catHeader:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, yOffset)
            catHeader:SetText("|cff775599" .. pageDef.category .. "|r")
            yOffset = yOffset - 20
        end

        local navBtn = CreateFrame("Button", nil, sidebar, ns.backdropTemplate)
        navBtn:SetSize(156, 26)
        navBtn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, yOffset)
        navBtn.labelStr = pageDef.label

        local glowBar = navBtn:CreateTexture(nil, "OVERLAY")
        glowBar:SetPoint("LEFT", navBtn, "LEFT", 1, 0)
        glowBar:SetSize(3, 20)
        glowBar:SetColorTexture(0.85, 0.4, 1.0, 1.0)
        glowBar:Hide()
        navBtn.glowBar = glowBar

        local navText = navBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        navText:SetPoint("LEFT", navBtn, "LEFT", 10, 0)
        navBtn.text = navText

        navBtn:SetScript("OnClick", function() SwitchSidebarPage(pageDef.id) end)
        sidebarButtons[pageDef.id] = navBtn

        yOffset = yOffset - 30
    end

    -- Initialize Feature Pages
    CreatePage1(contentArea)
    CreatePage2(contentArea)
    CreatePage3(contentArea)
    CreatePage4(contentArea)
    CreatePage5(contentArea)
    CreatePage6(contentArea)
    CreatePage7(contentArea)
    CreatePage8(contentArea)
    CreatePage9(contentArea)
    CreateSearchPanel(contentArea)

    -- Create Header Search Bar
    CreateSearchBar(optionsFrame, contentArea, SwitchSidebarPage)

    -- BOTTOM ACTION BAR & RESIZE HANDLE
    ----------------------------------------------------
    local bottomBar = CreateFrame("Frame", nil, optionsFrame, ns.backdropTemplate)
    bottomBar:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 16, 12)
    bottomBar:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -16, 12)
    bottomBar:SetHeight(30)

    local resetBtn = CreateFrame("Button", nil, bottomBar, ns.backdropTemplate)
    resetBtn:SetSize(130, 26)
    resetBtn:SetPoint("LEFT", bottomBar, "LEFT", 0, 0)
    ns.ApplyModernBackdrop(resetBtn, 0.16, 0.08, 0.25, 0.8, 0.35, 0.16, 0.55, 0.8)

    local resetText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetText:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
    resetText:SetText("|cffe0b3ffReset Defaults|r")

    resetBtn:SetScript("OnEnter", function() ns.ApplyModernBackdrop(resetBtn, 0.25, 0.12, 0.38, 0.9, 0.5, 0.2, 0.75, 1) end)
    resetBtn:SetScript("OnLeave", function() ns.ApplyModernBackdrop(resetBtn, 0.16, 0.08, 0.25, 0.8, 0.35, 0.16, 0.55, 0.8) end)
    resetBtn:SetScript("OnClick", function()
        if ns.ResetProfile then
            ns.ResetProfile()
        else
            for k, v in pairs(ns.defaultSettings) do
                WOWForeverAddonDB[k] = v
                if ns.ApplyFrameState then ns.ApplyFrameState(k, v) end
            end
            WOWForeverAddonDB.DisabledBuffs = {}
            ns.RefreshGUIOptions()
            if ns.UpdateHUD then ns.UpdateHUD() end
            if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
        end
        print("|cffc866ff[YAQoL]|r Reset active profile settings to defaults.")
    end)

    local closeBottomBtn = CreateFrame("Button", nil, bottomBar, ns.backdropTemplate)
    closeBottomBtn:SetSize(90, 26)
    closeBottomBtn:SetPoint("RIGHT", bottomBar, "RIGHT", -20, 0)
    ns.ApplyModernBackdrop(closeBottomBtn, 0.16, 0.08, 0.25, 0.8, 0.35, 0.16, 0.55, 0.8)

    local closeBottomText = closeBottomBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeBottomText:SetPoint("CENTER", closeBottomBtn, "CENTER", 0, 0)
    closeBottomText:SetText("|cffddddddClose|r")

    closeBottomBtn:SetScript("OnEnter", function() ns.ApplyModernBackdrop(closeBottomBtn, 0.25, 0.12, 0.38, 0.9, 0.5, 0.2, 0.75, 1) end)
    closeBottomBtn:SetScript("OnLeave", function() ns.ApplyModernBackdrop(closeBottomBtn, 0.16, 0.08, 0.25, 0.8, 0.35, 0.16, 0.55, 0.8) end)
    closeBottomBtn:SetScript("OnClick", function() optionsFrame:Hide() end)

    local resizeGrip = CreateFrame("Button", nil, optionsFrame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeGrip:SetScript("OnMouseDown", function()
        optionsFrame:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        optionsFrame:StopMovingOrSizing()
    end)

    optionsFrame:SetScript("OnSizeChanged", function(self, w, h)
        local contentW = w - 255
        for id, panel in pairs(contentPanels) do
            if panel and panel.content and panel.content.SetWidth then
                panel.content:SetWidth(contentW)
            end
        end
    end)

    SwitchSidebarPage(1)
    optionsFrame:Hide()
end

function ns.ToggleOptionsGUI()
    ns.CreateOptionsGUI()
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
        ns.RefreshGUIOptions()
    end
end
