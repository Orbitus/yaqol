-- Modules/ActionBarModernizer.lua: Action Bar Modernization & Styling
-- Part of YAQoL v2.0 (Yet Another Quality of Life) by Orbitus / Liiina & Antigravity

local ADDON_NAME, ns = ...

local BARS = {
    { prefix = "ActionButton", count = 12, frame = "MainActionBar", altFrame = "MainMenuBar" },
    { prefix = "MultiBarBottomLeftButton", count = 12, frame = "MultiBarBottomLeft", altFrame = "MultiBarBottomLeftFrame" },
    { prefix = "MultiBarBottomRightButton", count = 12, frame = "MultiBarBottomRight", altFrame = "MultiBarBottomRightFrame" },
    { prefix = "MultiBarRightButton", count = 12, frame = "MultiBarRight" },
    { prefix = "MultiBarLeftButton", count = 12, frame = "MultiBarLeft" },
    { prefix = "MultiBar5Button", count = 12, frame = "MultiBar5" },
    { prefix = "MultiBar6Button", count = 12, frame = "MultiBar6" },
    { prefix = "MultiBar7Button", count = 12, frame = "MultiBar7" },
    { prefix = "PetActionButton", count = 10, frame = "PetActionBar", altFrame = "PetActionBarFrame" },
    { prefix = "StanceButton", count = 10, frame = "StanceBar", altFrame = "StanceBarFrame" },
    { prefix = "PossessButton", count = 2, frame = "PossessActionBar", altFrame = "PossessBarFrame" },
}

local modernizerFrame = CreateFrame("Frame", "YAQoLActionBarModernizerFrame", UIParent)
ns.pendingSpacingUpdate = false
ns.pendingScaleUpdate = false

----------------------------------------------------
-- Hotkey Formatter (Comprehensive Localization Support & Cached)
----------------------------------------------------
ns.formattedHotkeyCache = ns.formattedHotkeyCache or {}

function ns.FormatShortHotkey(text)
    if not text or text == "" then return "" end
    if ns.formattedHotkeyCache[text] then
        return ns.formattedHotkeyCache[text]
    end

    local rawText = text

    -- Strip range indicator & parens
    text = text:gsub("RANGE_INDICATOR", "")
    text = text:gsub("%s*%(.*%)%s*", "")

    -- German & English Mouse Wheel
    text = text:gsub("Mausrad nach oben", "WU")
    text = text:gsub("Mausrad nach unten", "WD")
    text = text:gsub("Rad hoch", "WU")
    text = text:gsub("Rad runter", "WD")
    text = text:gsub("Mouse Wheel Up", "WU")
    text = text:gsub("Mouse Wheel Down", "WD")

    -- German & English Middle Mouse
    text = text:gsub("Mittlere Maustaste", "M3")
    text = text:gsub("Middle Mouse", "M3")

    -- German & English Mouse Buttons
    text = text:gsub("Maustaste%s*(%d+)", "M%1")
    text = text:gsub("Mouse Button%s*(%d+)", "M%1")
    text = text:gsub("Button%s*(%d+)", "M%1")

    -- German & English Numpad
    text = text:gsub("Nummernblock%s*(%d+)", "N%1")
    text = text:gsub("Num Pad%s*(%d+)", "N%1")
    text = text:gsub("NumPad%s*(%d+)", "N%1")
    text = text:gsub("NUMPAD%s*(%d+)", "N%1")
    text = text:gsub("Num%s*(%d+)", "N%1")

    -- Special utility keys
    text = text:gsub("Leertaste", "Spc")
    text = text:gsub("Spacebar", "Spc")
    text = text:gsub("Rückschritt", "BS")
    text = text:gsub("Backspace", "BS")
    text = text:gsub("Entfernen", "Del")
    text = text:gsub("Entf", "Del")
    text = text:gsub("Delete", "Del")
    text = text:gsub("Einfügen", "Ins")
    text = text:gsub("Insert", "Ins")
    text = text:gsub("Bild auf", "PU")
    text = text:gsub("Page Up", "PU")
    text = text:gsub("Bild ab", "PD")
    text = text:gsub("Page Down", "PD")
    text = text:gsub("Feststelltaste", "Caps")
    text = text:gsub("Caps Lock", "Caps")
    text = text:gsub("Pos 1", "Hm")
    text = text:gsub("Home", "Hm")
    text = text:gsub("Ende", "End")

    -- Full-word Modifiers (both - and +)
    text = text:gsub("[Ss][Tt][Rr][Gg]%s*[%-%+]%s*", "SR")
    text = text:gsub("[Cc][Tt][Rr][Ll]%s*[%-%+]%s*", "SR")
    text = text:gsub("[Cc][Oo][Nn][Tt][Rr][Oo][Ll]%s*[%-%+]%s*", "SR")
    text = text:gsub("[Ss][Hh][Ii][Ff][Tt]%s*[%-%+]%s*", "S")
    text = text:gsub("[Aa][Ll][Tt]%s*[%-%+]%s*", "A")

    -- Short prefix modifiers
    text = text:gsub("([sSaAcC])%s*[%-%+]%s*", function(mod)
        local m = mod:upper()
        if m == "C" then return "SR"
        elseif m == "S" then return "S"
        elseif m == "A" then return "A"
        end
    end)

    local res = strtrim(text)
    ns.formattedHotkeyCache[rawText] = res
    return res
end

----------------------------------------------------
-- Pixel-Perfect 1px Border Overlay (Flush to Icon)
----------------------------------------------------
local function CreateButtonBorder(btn)
    if btn.yaqolBorder then return btn.yaqolBorder end

    local border = CreateFrame("Frame", nil, btn)
    border:SetAllPoints(btn)
    border:SetFrameLevel(btn:GetFrameLevel() + 5)

    -- Exactly 1 pixel border directly flush on the button edges (0 offset)
    local top = border:CreateTexture(nil, "OVERLAY", nil, 7)
    top:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    top:SetColorTexture(0.18, 0.12, 0.25, 1)

    local bottom = border:CreateTexture(nil, "OVERLAY", nil, 7)
    bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    bottom:SetColorTexture(0.18, 0.12, 0.25, 1)

    local left = border:CreateTexture(nil, "OVERLAY", nil, 7)
    left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    left:SetColorTexture(0.18, 0.12, 0.25, 1)

    local right = border:CreateTexture(nil, "OVERLAY", nil, 7)
    right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
    right:SetColorTexture(0.18, 0.12, 0.25, 1)

    btn.yaqolBorder = border
    return border
end

----------------------------------------------------
-- Button Skinning & Modernization
----------------------------------------------------
local function SkinActionButton(btn)
    if not btn or not btn.GetName then return end
    local name = btn:GetName()
    if not name then return end

    local db = ns.db or WOWForeverAddonDB
    if not db then return end

    local slotAlpha = tonumber(db.ActionBarSlotBgAlpha)
    if slotAlpha == nil then slotAlpha = 0.85 end

    -- Dark slot background for empty slots
    if not btn.yaqolSlotBG then
        local bg = btn:CreateTexture(nil, "BACKGROUND", nil, -2)
        bg:SetAllPoints(btn)
        btn.yaqolSlotBG = bg
    end
    btn.yaqolSlotBG:SetColorTexture(0.04, 0.02, 0.07, slotAlpha)

    -- 1. Icon: Snap to full button frame & Zoom 8% to cut off Blizzard's gray border
    local icon = btn.icon or _G[name .. "Icon"]
    if icon then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        if btn.IconMask and icon.RemoveMaskTexture then
            icon:RemoveMaskTexture(btn.IconMask)
        end
        if btn.IconMask then
            btn.IconMask:Hide()
        end
        if db.ActionBarCleanIcons ~= false then
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            icon:SetTexCoord(0, 1, 0, 1)
        end
    end

    -- 2. Cooldown Frame: Match full button frame
    local cd = btn.cooldown or _G[name .. "Cooldown"]
    if cd then
        cd:ClearAllPoints()
        cd:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        cd:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    end

    -- 3. Normal Texture: Hide Blizzard rounded gray bevel
    local nt = btn:GetNormalTexture()
    if nt then
        if db.ActionBarCleanIcons ~= false or db.ActionBarModernBorder ~= false then
            nt:SetAlpha(0)
            nt:Hide()
        else
            nt:SetAlpha(1)
            nt:Show()
        end
    end

    -- 4. 1px Dark Slate Border & Empty Slot Visibility Control
    local border = CreateButtonBorder(btn)

    local hasAction = false
    if btn.action and HasAction then
        hasAction = HasAction(btn.action)
    elseif btn.GetAction then
        local a = btn:GetAction()
        if a and HasAction then hasAction = HasAction(a) end
    end

    local alwaysShowEmpty = db.ActionBarAlwaysShowEmptySlots
    if alwaysShowEmpty == nil then alwaysShowEmpty = db.ActionBarShowGrid end
    if alwaysShowEmpty == nil then alwaysShowEmpty = false end

    if not hasAction and not alwaysShowEmpty then
        if btn.yaqolSlotBG then btn.yaqolSlotBG:Hide() end
        if border then border:Hide() end
    else
        if btn.yaqolSlotBG then btn.yaqolSlotBG:Show() end
        if border then
            if db.ActionBarModernBorder ~= false then
                border:Show()
            else
                border:Hide()
            end
        end
    end

    -- 5. Clean Action Texture overlays (Pushed, Highlight, Checked)
    local pt = btn:GetPushedTexture()
    if pt then
        pt:ClearAllPoints()
        pt:SetAllPoints(btn)
        pt:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local ht = btn:GetHighlightTexture()
    if ht then
        ht:ClearAllPoints()
        ht:SetAllPoints(btn)
        ht:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local ct = btn:GetCheckedTexture()
    if ct then
        ct:ClearAllPoints()
        ct:SetAllPoints(btn)
        ct:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    -- 6. Floating Background & Slot Art removal
    local fbg = btn.SlotBackground or btn.FloatingBG or _G[name .. "FloatingBG"]
    if fbg then fbg:SetAlpha(0) end
    if btn.SlotArt then btn.SlotArt:SetAlpha(0) end
    if btn.Border then btn.Border:SetAlpha(0) end

    -- 7. Macro Text
    local nameFS = btn.Name or _G[name .. "Name"]
    if nameFS then
        if db.ActionBarHideMacroNames then
            nameFS:Hide()
        else
            nameFS:Show()
        end
    end

    -- 8. Hotkey Formatting & Crisp Positioning
    local hotkey = btn.HotKey or _G[name .. "HotKey"]
    if hotkey then
        if db.ActionBarHideHotkeys then
            hotkey:Hide()
        else
            hotkey:Show()
            hotkey:ClearAllPoints()
            hotkey:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -2)
            if db.ActionBarShortHotkeys ~= false then
                local txt = hotkey:GetText()
                if txt and txt ~= "" then
                    local formatted = ns.FormatShortHotkey(txt)
                    if formatted and formatted ~= txt then
                        hotkey:SetText(formatted)
                    end
                end
            end
        end
    end
end

----------------------------------------------------
-- Background & Gryphons Removal
----------------------------------------------------
local function UpdateGryphonsAndBackground()
    local db = ns.db or WOWForeverAddonDB
    if not db then return end

    local hide = db.ActionBarHideGryphons ~= false

    if MainMenuBarLeftEndCap then
        if hide then MainMenuBarLeftEndCap:Hide() else MainMenuBarLeftEndCap:Show() end
    end
    if MainMenuBarRightEndCap then
        if hide then MainMenuBarRightEndCap:Hide() else MainMenuBarRightEndCap:Show() end
    end

    for i = 0, 3 do
        local tex = _G["MainMenuBarTexture" .. i]
        if tex then
            if hide then tex:Hide() else tex:Show() end
        end
        local maxTex = _G["MainMenuMaxLevelBar" .. i]
        if maxTex then
            if hide then maxTex:Hide() else maxTex:Show() end
        end
    end

    if MainMenuBarPageNumber then
        if hide then MainMenuBarPageNumber:Hide() else MainMenuBarPageNumber:Show() end
    end
    if ActionBarUpButton then
        if hide then ActionBarUpButton:Hide() else ActionBarUpButton:Show() end
    end
    if ActionBarDownButton then
        if hide then ActionBarDownButton:Hide() else ActionBarDownButton:Show() end
    end
end

----------------------------------------------------
-- Action Bar Layout: Native Edit Mode Harmony
----------------------------------------------------
-- Best practice (as in EllesmereUI and SUI): In modern WoW, layout, rows, columns,
-- spacing (Icon Padding), and scale (Icon Size) are natively and securely handled
-- by World of Warcraft's Edit Mode. We strictly avoid calling ClearAllPoints()
-- or SetPoint() on action buttons, preventing any conflicts or layout corruptions.
function ns.UpdateActionBarSpacingAndScale()
    ns.pendingSpacingUpdate = false
    ns.pendingScaleUpdate = false
end

----------------------------------------------------
-- Empty Slot Grid Visibility
----------------------------------------------------
local function UpdateEmptyGrid()
    local db = ns.db or WOWForeverAddonDB
    if not db then return end

    local show = db.ActionBarAlwaysShowEmptySlots
    if show == nil then show = db.ActionBarShowGrid end
    if show == nil then show = false end

    local slotAlpha = tonumber(db.ActionBarSlotBgAlpha)
    if slotAlpha == nil then slotAlpha = 0.85 end

    for _, bar in ipairs(BARS) do
        for i = 1, bar.count do
            local btn = _G[bar.prefix .. i]
            if btn then
                if not btn.yaqolSlotBG then
                    local bg = btn:CreateTexture(nil, "BACKGROUND", nil, -2)
                    bg:SetAllPoints(btn)
                    btn.yaqolSlotBG = bg
                end
                btn.yaqolSlotBG:SetColorTexture(0.04, 0.02, 0.07, slotAlpha)

                local border = CreateButtonBorder(btn)

                local hasAction = false
                if btn.action and HasAction then
                    hasAction = HasAction(btn.action)
                elseif btn.GetAction then
                    local a = btn:GetAction()
                    if a and HasAction then hasAction = HasAction(a) end
                end

                if show then
                    btn:SetAttribute("showgrid", 1)
                    btn.showgrid = 1

                    -- Reveal button immediately on all bars without needing drag
                    if not InCombatLockdown() then
                        btn:Show()
                    end

                    if ActionButton_ShowGrid then
                        pcall(ActionButton_ShowGrid, btn)
                    end

                    if not hasAction then
                        btn.yaqolSlotBG:Show()
                        if border and db.ActionBarModernBorder ~= false then
                            border:Show()
                        end
                    end
                else
                    btn:SetAttribute("showgrid", 0)
                    btn.showgrid = 0

                    if ActionButton_HideGrid then
                        pcall(ActionButton_HideGrid, btn)
                    end

                    if not hasAction then
                        if not InCombatLockdown() and bar.prefix ~= "ActionButton" then
                            btn:Hide()
                        end
                        btn.yaqolSlotBG:Hide()
                        if border then border:Hide() end
                    end
                end
            end
        end
    end
end

----------------------------------------------------
-- Master Refresh for Action Bars
----------------------------------------------------
function ns.RefreshActionBarModernizer()
    local db = ns.db or WOWForeverAddonDB
    if not db then return end

    UpdateGryphonsAndBackground()
    ns.UpdateActionBarSpacingAndScale()
    UpdateEmptyGrid()

    for _, bar in ipairs(BARS) do
        for i = 1, bar.count do
            local btn = _G[bar.prefix .. i]
            if btn then
                SkinActionButton(btn)
            end
        end
    end
end

----------------------------------------------------
-- Hooks & Event Handlers
----------------------------------------------------
if ActionButton_Update then
    hooksecurefunc("ActionButton_Update", function(btn)
        local db = ns.db or WOWForeverAddonDB
        if db then
            local show = db.ActionBarAlwaysShowEmptySlots
            if show == nil then show = db.ActionBarShowGrid end
            if show and not InCombatLockdown() then
                if btn.SetAttribute and btn:GetAttribute("showgrid") == 0 then
                    btn:SetAttribute("showgrid", 1)
                end
                if not btn:IsShown() then
                    btn:Show()
                end
            end
        end
        SkinActionButton(btn)
    end)
end

if ActionButton_HideGrid then
    hooksecurefunc("ActionButton_HideGrid", function(btn)
        local db = ns.db or WOWForeverAddonDB
        if db then
            local show = db.ActionBarAlwaysShowEmptySlots
            if show == nil then show = db.ActionBarShowGrid end
            if show and not InCombatLockdown() then
                if btn and not btn:IsShown() then
                    btn:Show()
                end
                if btn and btn.yaqolSlotBG then
                    btn.yaqolSlotBG:Show()
                end
                if btn and btn.yaqolBorder and db.ActionBarModernBorder ~= false then
                    btn.yaqolBorder:Show()
                end
            end
        end
    end)
end

if ActionButton_UpdateHotkeys then
    hooksecurefunc("ActionButton_UpdateHotkeys", function(btn)
        local db = ns.db or WOWForeverAddonDB
        if not db or not btn then return end

        local hotkey = _G[btn:GetName() .. "HotKey"]
        if hotkey then
            if db.ActionBarHideHotkeys then
                hotkey:Hide()
            else
                hotkey:Show()
                hotkey:ClearAllPoints()
                hotkey:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -2)
                if db.ActionBarShortHotkeys ~= false then
                    local txt = hotkey:GetText()
                    if txt and txt ~= "" then
                        local formatted = ns.FormatShortHotkey(txt)
                        if formatted and formatted ~= txt then
                            hotkey:SetText(formatted)
                        end
                    end
                end
            end
        end
    end)
end

if MainMenuBarLeftEndCap and MainMenuBarLeftEndCap.HookScript then
    MainMenuBarLeftEndCap:HookScript("OnShow", function(self)
        local db = ns.db or WOWForeverAddonDB
        if db and db.ActionBarHideGryphons ~= false then self:Hide() end
    end)
end

if MainMenuBarRightEndCap and MainMenuBarRightEndCap.HookScript then
    MainMenuBarRightEndCap:HookScript("OnShow", function(self)
        local db = ns.db or WOWForeverAddonDB
        if db and db.ActionBarHideGryphons ~= false then self:Hide() end
    end)
end

modernizerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
modernizerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
modernizerFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
modernizerFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
modernizerFrame:RegisterEvent("UPDATE_BINDINGS")
modernizerFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")

modernizerFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            ns.RefreshActionBarModernizer()
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.pendingSpacingUpdate or ns.pendingScaleUpdate then
            ns.UpdateActionBarSpacingAndScale()
        end
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        UpdateEmptyGrid()
    elseif event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BINDINGS" or event == "EDIT_MODE_LAYOUTS_UPDATED" then
        ns.RefreshActionBarModernizer()
    end
end)

ns.Log("MODULE_INIT", "ActionBarModernizer module loaded successfully.")
