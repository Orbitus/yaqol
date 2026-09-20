-- Modules/UIElementManager.lua: UI Element Visibility & Mouseover Management
-- Author: Antigravity

local ADDON_NAME, ns = ...

-- Action Bar UI Elements (Configured in OptionsGUI Page 9: Aktionsleisten)
ns.ACTION_BAR_ELEMENTS = {
    { 
        key = "MainMenuBar", 
        name = "Aktionsleiste 1", 
        frames = { "MainActionBar", "MainMenuBar", "MainMenuBarFrame", "ActionBar1" },
        buttons = { "ActionButton1", "ActionButton2", "ActionButton3", "ActionButton4", "ActionButton5", "ActionButton6", "ActionButton7", "ActionButton8", "ActionButton9", "ActionButton10", "ActionButton11", "ActionButton12" }
    },
    { 
        key = "MultiBarBottomLeft", 
        name = "Aktionsleiste 2", 
        frames = { "MultiBarBottomLeft", "MultiBarBottomLeftFrame" },
        buttons = { "MultiBarBottomLeftButton1", "MultiBarBottomLeftButton2", "MultiBarBottomLeftButton3", "MultiBarBottomLeftButton4", "MultiBarBottomLeftButton5", "MultiBarBottomLeftButton6", "MultiBarBottomLeftButton7", "MultiBarBottomLeftButton8", "MultiBarBottomLeftButton9", "MultiBarBottomLeftButton10", "MultiBarBottomLeftButton11", "MultiBarBottomLeftButton12" }
    },
    { 
        key = "MultiBarBottomRight", 
        name = "Aktionsleiste 3", 
        frames = { "MultiBarBottomRight", "MultiBarBottomRightFrame" },
        buttons = { "MultiBarBottomRightButton1", "MultiBarBottomRightButton2", "MultiBarBottomRightButton3", "MultiBarBottomRightButton4", "MultiBarBottomRightButton5", "MultiBarBottomRightButton6", "MultiBarBottomRightButton7", "MultiBarBottomRightButton8", "MultiBarBottomRightButton9", "MultiBarBottomRightButton10", "MultiBarBottomRightButton11", "MultiBarBottomRightButton12" }
    },
    { 
        key = "MultiBarRight", 
        name = "Aktionsleiste 4", 
        frames = { "MultiBarRight" },
        buttons = { "MultiBarRightButton1", "MultiBarRightButton2", "MultiBarRightButton3", "MultiBarRightButton4", "MultiBarRightButton5", "MultiBarRightButton6", "MultiBarRightButton7", "MultiBarRightButton8", "MultiBarRightButton9", "MultiBarRightButton10", "MultiBarRightButton11", "MultiBarRightButton12" }
    },
    { 
        key = "MultiBarLeft", 
        name = "Aktionsleiste 5", 
        frames = { "MultiBarLeft" },
        buttons = { "MultiBarLeftButton1", "MultiBarLeftButton2", "MultiBarLeftButton3", "MultiBarLeftButton4", "MultiBarLeftButton5", "MultiBarLeftButton6", "MultiBarLeftButton7", "MultiBarLeftButton8", "MultiBarLeftButton9", "MultiBarLeftButton10", "MultiBarLeftButton11", "MultiBarLeftButton12" }
    },
    { 
        key = "MultiBar5", 
        name = "Aktionsleiste 6", 
        frames = { "MultiBar5" },
        buttons = { "MultiBar5Button1", "MultiBar5Button2", "MultiBar5Button3", "MultiBar5Button4", "MultiBar5Button5", "MultiBar5Button6", "MultiBar5Button7", "MultiBar5Button8", "MultiBar5Button9", "MultiBar5Button10", "MultiBar5Button11", "MultiBar5Button12" }
    },
    { 
        key = "MultiBar6", 
        name = "Aktionsleiste 7", 
        frames = { "MultiBar6" },
        buttons = { "MultiBar6Button1", "MultiBar6Button2", "MultiBar6Button3", "MultiBar6Button4", "MultiBar6Button5", "MultiBar6Button6", "MultiBar6Button7", "MultiBar6Button8", "MultiBar6Button9", "MultiBar6Button10", "MultiBar6Button11", "MultiBar6Button12" }
    },
    { 
        key = "MultiBar7", 
        name = "Aktionsleiste 8", 
        frames = { "MultiBar7" },
        buttons = { "MultiBar7Button1", "MultiBar7Button2", "MultiBar7Button3", "MultiBar7Button4", "MultiBar7Button5", "MultiBar7Button6", "MultiBar7Button7", "MultiBar7Button8", "MultiBar7Button9", "MultiBar7Button10", "MultiBar7Button11", "MultiBar7Button12" }
    },
    { 
        key = "PetActionBar", 
        name = "Pet Bar", 
        frames = { "PetActionBar", "PetActionBarFrame" },
        buttons = { "PetActionButton1", "PetActionButton2", "PetActionButton3", "PetActionButton4", "PetActionButton5", "PetActionButton6", "PetActionButton7", "PetActionButton8", "PetActionButton9", "PetActionButton10" }
    },
    { 
        key = "StanceBar", 
        name = "Stance Bar", 
        frames = { "StanceBar", "StanceBarFrame", "ShapeshiftBarFrame" },
        buttons = { "StanceButton1", "StanceButton2", "StanceButton3", "StanceButton4", "StanceButton5", "StanceButton6", "StanceButton7", "StanceButton8", "StanceButton9", "StanceButton10" }
    },
}

-- General Blizzard UI Elements (Configured in OptionsGUI Page 1: Blizz UI)
ns.BLIZZ_UI_ELEMENTS = {
    { key = "PlayerFrame", name = "Player Unit Frame", frames = { "PlayerFrame" } },
    { key = "TargetFrame", name = "Target Unit Frame", frames = { "TargetFrame" } },
    { key = "FocusFrame", name = "Focus Unit Frame", frames = { "FocusFrame" } },
    { key = "MinimapCluster", name = "Minimap Cluster", frames = { "MinimapCluster", "Minimap" } },
    { key = "ObjectiveTrackerFrame", name = "Quest / Objective Tracker", frames = { "ObjectiveTrackerFrame", "WatchFrame" } },
    { key = "ChatFrame1", name = "Chat Window", frames = { "ChatFrame1", "GeneralDockManager" } },
    { key = "BuffFrame", name = "Buffs & Debuffs", frames = { "BuffFrame" } },
    { 
        key = "MicroMenu", 
        name = "Micro Menu Bar", 
        frames = { "MicroMenu", "MicroButtonAndBagsBar", "MainMenuBarMicroButtons" },
        buttons = { 
            "CharacterMicroButton", "SpellbookMicroButton", "PlayerSpellsMicroButton", 
            "TalentMicroButton", "AchievementMicroButton", "QuestLogMicroButton", 
            "GuildMicroButton", "LFDMicroButton", "EJMicroButton", "StoreMicroButton", 
            "MainMenuMicroButton", "HelpMicroButton", "CollectionsMicroButton" 
        } 
    },
    { 
        key = "BagsBar", 
        name = "Bags Bar", 
        frames = { "BagsBar", "BagsBarContainer" },
        buttons = { 
            "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot", 
            "CharacterBag2Slot", "CharacterBag3Slot", "KeyRingButton" 
        } 
    },
}

-- Combined list of all customizable elements for lifecycle & state management
ns.UI_ELEMENTS = {}
for _, e in ipairs(ns.ACTION_BAR_ELEMENTS) do table.insert(ns.UI_ELEMENTS, e) end
for _, e in ipairs(ns.BLIZZ_UI_ELEMENTS) do table.insert(ns.UI_ELEMENTS, e) end

local pairs, ipairs, math_abs = pairs, ipairs, math.abs
local _G = _G
local MouseIsOver = MouseIsOver

local activeMouseoverElements = {}
local updater = CreateFrame("Frame")
local isUpdaterRunning = false

-- Cache button object references on element definition to avoid _G lookups
local function CacheElementButtons(elem)
    if not elem.buttonObjects then
        elem.buttonObjects = {}
        if elem.buttons then
            for _, btnName in ipairs(elem.buttons) do
                local b = _G[btnName]
                if b then table.insert(elem.buttonObjects, b) end
            end
        end
    end
    return elem.buttonObjects
end

-- Utility: Resolve frame object by candidate global names
function ns.GetElementFrame(elementDef)
    if elementDef.cachedFrame then return elementDef.cachedFrame end
    if elementDef.frames then
        for _, name in ipairs(elementDef.frames) do
            local f = _G[name]
            if f then
                elementDef.cachedFrame = f
                return f
            end
        end
    end
    return nil
end

-- Utility: Set alpha on frame container and/or button list
function ns.SetElementAlpha(elem, alpha)
    local frame = ns.GetElementFrame(elem)
    if frame then
        frame:SetAlpha(alpha)
    end
    local buttons = CacheElementButtons(elem)
    for _, b in ipairs(buttons) do
        if not frame or b:GetParent() ~= frame then
            b:SetAlpha(alpha)
        end
    end
end

-- Utility: Check if mouse is hovering over container or any button
function ns.IsMouseOverElement(elem, frame)
    if frame and frame:IsShown() then
        local isOver = (MouseIsOver and MouseIsOver(frame)) or (frame.IsMouseOver and frame:IsMouseOver())
        if isOver then return true end
    end
    local buttons = CacheElementButtons(elem)
    for _, b in ipairs(buttons) do
        if b:IsShown() then
            local isOver = (MouseIsOver and MouseIsOver(b)) or (b.IsMouseOver and b:IsMouseOver())
            if isOver then return true end
        end
    end
    return false
end

-- Get current alpha for comparison
function ns.GetElementAlpha(elem, frame)
    if frame then return frame:GetAlpha() or 0.0 end
    local buttons = CacheElementButtons(elem)
    if buttons[1] then return buttons[1]:GetAlpha() or 0.0 end
    return 0.0
end

local function OnMouseoverUpdate(self, elapsed)
    local needsUpdate = false
    for key, data in pairs(activeMouseoverElements) do
        local elem = data.elem
        local frame = data.frame
        local isOver = ns.IsMouseOverElement(elem, frame)
        local targetAlpha = isOver and 1.0 or 0.0
        local currentAlpha = ns.GetElementAlpha(elem, frame)

        if math_abs(currentAlpha - targetAlpha) > 0.01 then
            needsUpdate = true
            local step = elapsed * 10
            local newAlpha = currentAlpha + (targetAlpha > currentAlpha and step or -step)
            if (targetAlpha > currentAlpha and newAlpha > targetAlpha) or (targetAlpha < currentAlpha and newAlpha < targetAlpha) then
                newAlpha = targetAlpha
            end
            ns.SetElementAlpha(elem, newAlpha)
        else
            ns.SetElementAlpha(elem, targetAlpha)
        end
    end

    -- If no element is actively animating and active set is empty or settled, put ticker to sleep
    if not needsUpdate then
        local anyAnimating = false
        for key, data in pairs(activeMouseoverElements) do
            local isOver = ns.IsMouseOverElement(data.elem, data.frame)
            local targetAlpha = isOver and 1.0 or 0.0
            local currentAlpha = ns.GetElementAlpha(data.elem, data.frame)
            if math_abs(currentAlpha - targetAlpha) > 0.01 then
                anyAnimating = true
                break
            end
        end
        if not anyAnimating then
            updater:SetScript("OnUpdate", nil)
            isUpdaterRunning = false
        end
    end
end

local function StartMouseoverTicker()
    if not isUpdaterRunning then
        isUpdaterRunning = true
        updater:SetScript("OnUpdate", OnMouseoverUpdate)
    end
end
ns.WakeupMouseoverTicker = StartMouseoverTicker

-- Apply state (SHOWN, HIDDEN, MOUSEOVER) to a specific frame/element
function ns.ApplyFrameState(key, mode)
    local elem = nil
    for _, e in ipairs(ns.UI_ELEMENTS) do
        if e.key == key then elem = e break end
    end
    if not elem then return end

    local frame = ns.GetElementFrame(elem)

    if mode == "SHOWN" then
        activeMouseoverElements[key] = nil
        ns.SetElementAlpha(elem, 1.0)
    elseif mode == "HIDDEN" then
        activeMouseoverElements[key] = nil
        ns.SetElementAlpha(elem, 0.0)
    elseif mode == "MOUSEOVER" then
        activeMouseoverElements[key] = { elem = elem, frame = frame }
        local isOver = ns.IsMouseOverElement(elem, frame)
        ns.SetElementAlpha(elem, isOver and 1.0 or 0.0)
        StartMouseoverTicker()
    end
end

-- Apply all saved states
function ns.ApplyAllStates()
    if not ns.isLoaded or not WOWForeverAddonDB then return end
    for _, elem in ipairs(ns.UI_ELEMENTS) do
        local mode = WOWForeverAddonDB[elem.key]
        if mode == nil then mode = (ns.defaultSettings and ns.defaultSettings[elem.key]) or "SHOWN" end
        ns.ApplyFrameState(elem.key, mode)
    end
    if WOWForeverAddonDB.MaxCameraZoom then
        SetCVar("cameraDistanceMaxZoomFactor", 2.6)
    end
end
