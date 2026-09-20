-- Core.lua: WOWForeverAddon Core Initialization & Namespace Framework
local ADDON_NAME, ns = ...

-- Localized API references for maximum performance
local type, pairs, ipairs, tostring, tonumber = type, pairs, ipairs, tostring, tonumber
local date, string_format = date, string.format
local table_insert, table_concat = table.insert, table.concat

-- Global SavedVariables database handle
ns.ADDON_NAME = ADDON_NAME
ns.isLoaded = false

-- Logging & Diagnostic Buffer (O(1) Ring Buffer)
ns.logs = ns.logs or {}
ns.logHead = ns.logHead or 0
local MAX_LOGS = 150

function ns.Log(cat, msg)
    local timestamp = date("%H:%M:%S")
    local line = string_format("[%s] [%s] %s", timestamp, tostring(cat), tostring(msg))
    ns.logHead = (ns.logHead % MAX_LOGS) + 1
    ns.logs[ns.logHead] = line
    if ns.RefreshLogView then
        ns.RefreshLogView()
    end
end

-- Default Settings Registry (Configured with preferred user layout)
ns.defaultSettings = {
    -- UI Visibility
    MainMenuBar = "SHOWN",
    MultiBarBottomLeft = "SHOWN",
    MultiBarBottomRight = "SHOWN",
    MultiBarRight = "SHOWN",
    MultiBarLeft = "SHOWN",
    MultiBar5 = "SHOWN",
    MultiBar6 = "SHOWN",
    MultiBar7 = "SHOWN",
    StanceBar = "SHOWN",
    PetActionBar = "SHOWN",
    PlayerFrame = "SHOWN",
    TargetFrame = "SHOWN",
    FocusFrame = "SHOWN",
    MinimapCluster = "SHOWN",
    ObjectiveTrackerFrame = "SHOWN",
    ChatFrame1 = "SHOWN",
    BuffFrame = "SHOWN",
    MicroMenu = "MOUSEOVER",
    BagsBar = "MOUSEOVER",

    -- Quality of Life (QoL)
    AutoQuest = true,
    AutoRepair = false,
    AutoSellGreys = true,
    MaxCameraZoom = true,
    FastLoot = true,
    PetReminder = true,
    BuffReminder = true,
    DisabledBuffs = {},
    HideRedErrors = true,
    AutoDismount = true,
    ChatCopyURL = true,
    ChatClassColors = true,
    ChatShortChannels = true,
    QuestAutoMarkTarget = true,
    QuestNameplateHighlight = true,

    -- Addon Minimap Collector Bar (HidingBar)
    MinimapBarEnabled = true,
    MinimapBarOrientation = "VERTICAL",
    MinimapBarMouseover = true,
    MinimapBarSnapToEdge = true,
    MinimapBarIconSize = 32,
    MinimapBarPadding = 6,
    MinimapBarAlpha = 0.9,
    MinimapBarPosition = { y = -22.999706268311, x = 0, point = "RIGHT", relativePoint = "RIGHT" },

    -- Saved Positions
    HUDPosition = nil,

    -- Leveling Features
    LevelingModuleEnabled = true,
    XPBarEnabled = true,
    XPBarWidth = 500,
    XPBarHeight = 14,
    XPBarShowStats = true,
    XPBarShowQuestOverlay = true,
    XPBarColorBase = { r = 0, g = 0.82, b = 1 },
    XPBarColorRested = { r = 1, g = 0.8, b = 0 },
    XPBarColorCompletedQuest = { r = 0, g = 1, b = 0.53 },
    XPBarColorActiveQuest = { r = 0.66, g = 0.4, b = 1 },
    LevelUpBannerEnabled = true,
    LevelUpScreenshot = true,
    QuestRewardHighlighter = true,
    ZoneEfficiencyAlert = true,
    XPBarPosition = nil,

    -- Action Bar Modernization (Phase 2)
    ActionBarCleanIcons = true,
    ActionBarHideGryphons = true,
    ActionBarModernBorder = true,
    ActionBarShortHotkeys = true,
    ActionBarHideHotkeys = false,
    ActionBarHideMacroNames = false,
    ActionBarAlwaysShowEmptySlots = true,
    ActionBarShowGrid = true,
    ActionBarSlotBgAlpha = 0.85,
}

-- Resilient User Preset Fallback (Guaranteed in-code profile if Beta client fails to inject SavedVariables from WTF)
ns.UserPresetDB = {
    -- UI Visibility
    MainMenuBar = "SHOWN",
    MultiBarBottomLeft = "SHOWN",
    MultiBarBottomRight = "SHOWN",
    MultiBarRight = "SHOWN",
    MultiBarLeft = "SHOWN",
    MultiBar5 = "SHOWN",
    MultiBar6 = "SHOWN",
    MultiBar7 = "SHOWN",
    StanceBar = "SHOWN",
    PetActionBar = "SHOWN",
    PlayerFrame = "SHOWN",
    TargetFrame = "SHOWN",
    FocusFrame = "SHOWN",
    MinimapCluster = "SHOWN",
    ObjectiveTrackerFrame = "SHOWN",
    ChatFrame1 = "SHOWN",
    BuffFrame = "SHOWN",
    MicroMenu = "MOUSEOVER",
    BagsBar = "MOUSEOVER",

    -- Quality of Life (QoL)
    AutoQuest = true,
    AutoRepair = false,
    AutoSellGreys = true,
    MaxCameraZoom = true,
    FastLoot = true,
    PetReminder = true,
    BuffReminder = true,
    DisabledBuffs = {},
    HideRedErrors = true,
    AutoDismount = true,
    ChatCopyURL = true,
    ChatClassColors = true,
    ChatShortChannels = true,
    QuestAutoMarkTarget = true,
    QuestNameplateHighlight = true,

    -- Addon Minimap Collector Bar (HidingBar)
    MinimapBarEnabled = true,
    MinimapBarOrientation = "VERTICAL",
    MinimapBarMouseover = true,
    MinimapBarSnapToEdge = true,
    MinimapBarIconSize = 32,
    MinimapBarPadding = 6,
    MinimapBarAlpha = 0.9,
    MinimapBarPosition = { y = -22.999706268311, x = 0, point = "RIGHT", relativePoint = "RIGHT" },

    -- Saved Positions
    HUDPosition = nil,

    -- Leveling Features
    LevelingModuleEnabled = true,
    XPBarEnabled = true,
    XPBarWidth = 500,
    XPBarHeight = 14,
    XPBarShowStats = true,
    XPBarShowQuestOverlay = true,
    XPBarColorBase = { r = 0, g = 0.82, b = 1 },
    XPBarColorRested = { r = 1, g = 0.8, b = 0 },
    XPBarColorCompletedQuest = { r = 0, g = 1, b = 0.53 },
    XPBarColorActiveQuest = { r = 0.66, g = 0.4, b = 1 },
    LevelUpBannerEnabled = true,
    LevelUpScreenshot = true,
    QuestRewardHighlighter = true,
    ZoneEfficiencyAlert = true,
    XPBarPosition = nil,

    -- Action Bar Modernization (Phase 2)
    ActionBarCleanIcons = true,
    ActionBarHideGryphons = true,
    ActionBarModernBorder = true,
    ActionBarShortHotkeys = true,
    ActionBarHideHotkeys = false,
    ActionBarHideMacroNames = false,
    ActionBarAlwaysShowEmptySlots = true,
    ActionBarShowGrid = true,
    ActionBarSlotBgAlpha = 0.85,
}

function ns.DumpDBToString()
    local db = _G["WOWForeverAddonDB"] or WOWForeverAddonDB
    if not db then return "WOWForeverAddonDB in _G is NIL!" end
    local lines = { "-- WOWForeverAddonDB Current Memory State --" }
    for k, v in pairs(db) do
        if type(v) == "table" then
            local sub = {}
            for sk, sv in pairs(v) do
                table.insert(sub, tostring(sk) .. "=" .. tostring(sv))
            end
            table.insert(lines, string.format("  [%q] = { %s }", tostring(k), table.concat(sub, ", ")))
        else
            table.insert(lines, string.format("  [%q] = %s", tostring(k), type(v) == "string" and string.format("%q", v) or tostring(v)))
        end
    end
    return table.concat(lines, "\n")
end

-- Import / Restore Database from Dump String
function ns.ImportDBFromString(text)
    if not text or text == "" then return false, "Empty text" end
    local count = 0
    local targetDB = WOWForeverAddonDB or _G["WOWForeverAddonDB"] or {}
    for line in text:gmatch("[^\r\n]+") do
        local key, val = line:match('%["([^"]+)%]%s*=%s*(.+)')
        if key and val then
            key = strtrim(key)
            val = strtrim(val)
            if val == "true" then
                targetDB[key] = true
                count = count + 1
            elseif val == "false" then
                targetDB[key] = false
                count = count + 1
            elseif tonumber(val) then
                targetDB[key] = tonumber(val)
                count = count + 1
            elseif val:match('^"(.*)"$') then
                targetDB[key] = val:match('^"(.*)"$')
                count = count + 1
            elseif val:match('^{%s*(.*)%s*}$') then
                local inner = val:match('^{%s*(.*)%s*}$')
                local tbl = {}
                for subk, subv in inner:gmatch('([%w_]+)%s*=%s*([^,%s]+)') do
                    if subv == "true" then tbl[subk] = true
                    elseif subv == "false" then tbl[subk] = false
                    elseif tonumber(subv) then tbl[subk] = tonumber(subv)
                    elseif subv:match('^"(.*)"$') then tbl[subk] = subv:match('^"(.*)"$')
                    else tbl[subk] = subv end
                end
                targetDB[key] = tbl
                count = count + 1
            end
        end
    end

    if count > 0 then
        _G["WOWForeverAddonDB"] = targetDB
        _G["WOWForeverAddonDBPerChar"] = targetDB
        WOWForeverAddonDB = targetDB
        ns.db = targetDB
        ns.isLoaded = true
        if ns.ApplyAllStates then ns.ApplyAllStates() end
        if ns.RefreshGUIOptions then ns.RefreshGUIOptions() end
        if ns.UpdateHUD then ns.UpdateHUD() end
        if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
        if ns.UpdateXPBar then ns.UpdateXPBar() end
        ns.Log("DB_IMPORT", string.format("Successfully imported %d settings from dump!", count))
        return true, count
    end
    return false, "No valid keys found in dump text"
end

local function CountKeys(tbl)
    if type(tbl) ~= "table" then return 0 end
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

local function InspectDBSources()
    local yaqolDB = _G["YAQoLDB"] or YAQoLDB
    local accDB = _G["WOWForeverAddonDB"] or WOWForeverAddonDB
    local charDB = _G["WOWForeverAddonDBPerChar"] or WOWForeverAddonDBPerChar
    
    local yaqolProfileCount = (type(yaqolDB) == "table" and type(yaqolDB.profiles) == "table") and CountKeys(yaqolDB.profiles) or 0
    local accKeys = CountKeys(accDB)
    local charKeys = CountKeys(charDB)
    return yaqolDB, yaqolProfileCount, accDB, accKeys, charDB, charKeys
end

local function TryInitializeDatabase(sourceEvent)
    if ns.isLoaded then return true end

    local yaqolDB, yaqolProfileCount, accDB, accKeys, charDB, charKeys = InspectDBSources()
    ns.Log("DB_CHECK", string.format("[%s] DB inspect -> YAQoL profiles: %d, Legacy acc keys: %d, char keys: %d", 
        tostring(sourceEvent), yaqolProfileCount, accKeys, charKeys))

    local chosenDB = nil
    local adoptedSource = "NONE"

    -- 1. Check if modern YAQoLDB with profiles exists
    if yaqolProfileCount > 0 then
        YAQoLDB = yaqolDB
        YAQoLDB.activeProfile = YAQoLDB.activeProfile or "Default"
        if not YAQoLDB.profiles[YAQoLDB.activeProfile] then
            for pName in pairs(YAQoLDB.profiles) do
                YAQoLDB.activeProfile = pName
                break
            end
        end
        chosenDB = YAQoLDB.profiles[YAQoLDB.activeProfile]
        adoptedSource = "YAQOL_SAVEDVARIABLES"
    -- 2. Migrate from legacy WOWForeverAddonDB if present
    elseif accKeys > 0 or charKeys > 0 then
        local sourceTbl = (accKeys > 0) and accDB or charDB
        YAQoLDB = {
            activeProfile = "Default",
            profiles = {
                ["Default"] = CopyTable and CopyTable(sourceTbl) or {}
            }
        }
        chosenDB = YAQoLDB.profiles["Default"]
        adoptedSource = "MIGRATED_FROM_V1_LEGACY"
    end

    -- 3. Fallback on world entry if client bug dropped SavedVariables
    if not chosenDB then
        if sourceEvent == "PLAYER_ENTERING_WORLD" then
            local fallbackTbl = (ns.UserPresetDB and CountKeys(ns.UserPresetDB) > 0) and ns.UserPresetDB or ns.defaultSettings
            YAQoLDB = {
                activeProfile = "Default",
                profiles = {
                    ["Default"] = CopyTable and CopyTable(fallbackTbl) or {}
                }
            }
            chosenDB = YAQoLDB.profiles["Default"]
            adoptedSource = (ns.UserPresetDB and CountKeys(ns.UserPresetDB) > 0) and "USER_PRESET_BACKUP" or "FRESH_INSTALL_DEFAULTS"
            ns.Log("DB_INIT", string.format("[PLAYER_ENTERING_WORLD] Initialized YAQoLDB with source: %s", adoptedSource))
        else
            -- SavedVariables not yet ready in _G. Deferring to next lifecycle event...
            ns.Log("DB_INIT", string.format("[%s] SavedVariables not yet ready in _G. Deferring to next lifecycle event...", tostring(sourceEvent)))
            return false
        end
    end

    -- Populate missing default keys
    local filledCount = 0
    for k, v in pairs(ns.defaultSettings) do
        if chosenDB[k] == nil then
            filledCount = filledCount + 1
            if type(v) == "table" then
                chosenDB[k] = CopyTable and CopyTable(v) or {}
            else
                chosenDB[k] = v
            end
        end
    end
    chosenDB.DisabledBuffs = chosenDB.DisabledBuffs or {}

    -- Bind to globals & namespace
    _G["YAQoLDB"] = YAQoLDB
    YAQoLDB = YAQoLDB
    ns.db = chosenDB
    _G["WOWForeverAddonDB"] = chosenDB
    _G["WOWForeverAddonDBPerChar"] = chosenDB
    WOWForeverAddonDB = chosenDB
    ns.isLoaded = true

    ns.Log("DB_LOADED", string.format("YAQoL active! Profile: '%s', Source: %s (%d missing keys filled). Active keys: %d", 
        YAQoLDB.activeProfile or "Default", adoptedSource, filledCount, CountKeys(chosenDB)))

    if ns.ApplyAllStates then ns.ApplyAllStates() end
    if ns.UpdateHUD then ns.UpdateHUD() end
    if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
    if ns.UpdateXPBar then ns.UpdateXPBar() end
    if ns.UpdateChatSettings then ns.UpdateChatSettings() end
    if ns.RefreshGUIOptions then ns.RefreshGUIOptions() end

    return true
end

local initialYAQoL = _G["YAQoLDB"] or YAQoLDB
local initialAccDB = _G["WOWForeverAddonDB"] or WOWForeverAddonDB
local hasInitial = (type(initialYAQoL) == "table" and type(initialYAQoL.profiles) == "table") or (CountKeys(initialAccDB) > 0)
ns.Log("CORE_INIT", string.format("Core.lua executed. File load check: %s.", hasInitial and "data present" or "nil"))

-- If LoadSavedVariablesFirst: 1 is active, adopt immediately at file load time!
if hasInitial then
    TryInitializeDatabase("FILE_LOAD_TIME")
end

-- Cross-version backdrop template
ns.backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

-- Apply Gothic Backdrop Styling Helper
function ns.ApplyModernBackdrop(f, r, g, b, a, borderR, borderG, borderB, borderA)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        f:SetBackdropColor(r or 0.06, g or 0.04, b or 0.09, a or 0.96)
        f:SetBackdropBorderColor(borderR or 0.45, borderG or 0.18, borderB or 0.75, borderA or 0.7)
    else
        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(r or 0.06, g or 0.04, b or 0.09, a or 0.96)
    end
end

-- Core Event Dispatcher Frame
local coreFrame = CreateFrame("Frame")
coreFrame:RegisterEvent("ADDON_LOADED")
coreFrame:RegisterEvent("VARIABLES_LOADED")
coreFrame:RegisterEvent("PLAYER_LOGIN")
coreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
coreFrame:RegisterEvent("PLAYER_LOGOUT")
coreFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
coreFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
coreFrame:RegisterEvent("UNIT_AURA")
coreFrame:RegisterEvent("UNIT_PET")
coreFrame:RegisterEvent("SPELLS_CHANGED")
coreFrame:RegisterEvent("BAG_UPDATE_DELAYED")

coreFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == ADDON_NAME or arg1 == "YAQoL") then
        TryInitializeDatabase("ADDON_LOADED")
    elseif event == "VARIABLES_LOADED" then
        TryInitializeDatabase("VARIABLES_LOADED")
    elseif event == "PLAYER_LOGIN" then
        TryInitializeDatabase("PLAYER_LOGIN")
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
        TryInitializeDatabase(event)
        if ns.isLoaded then
            C_Timer.After(0.5, function()
                if ns.ApplyAllStates then ns.ApplyAllStates() end
                if ns.UpdateHUD then ns.UpdateHUD() end
                if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
                if ns.UpdateXPBar then ns.UpdateXPBar() end
            end)
        end
    elseif event == "UNIT_AURA" or event == "UNIT_PET" then
        if arg1 == "player" or arg1 == "pet" then
            if ns.isLoaded and ns.UpdateHUD then ns.UpdateHUD() end
        end
    elseif event == "SPELLS_CHANGED" then
        ns.learnedSpellCache = nil -- Invalidate spellbook cache
        if ns.isLoaded and ns.UpdateHUD then ns.UpdateHUD() end
    elseif event == "BAG_UPDATE_DELAYED" then
        if ns.isLoaded and ns.UpdateHUD then ns.UpdateHUD() end
    elseif event == "PLAYER_LOGOUT" then
        if YAQoLDB and ns.isLoaded then
            if YAQoLDB.activeProfile and ns.db then
                YAQoLDB.profiles[YAQoLDB.activeProfile] = ns.db
            end
            _G["YAQoLDB"] = YAQoLDB
            _G["WOWForeverAddonDB"] = ns.db
            _G["WOWForeverAddonDBPerChar"] = ns.db
            ns.Log("PLAYER_LOGOUT", "Synced YAQoLDB & legacy WOWForeverAddonDB before disk write.")
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.Log("EVENT", "PLAYER_REGEN_DISABLED (Combat Start)")
        if ns.isLoaded and ns.UpdateHUD then ns.UpdateHUD() end
    end
end)

-- Register Slash Commands for YAQoL v2.0
SLASH_YAQOL1 = "/yaqol"
SLASH_YAQOL2 = "/yql"
SLASH_YAQOL3 = "/yaq"
SLASH_YAQOL4 = "/wfa"
SLASH_YAQOL5 = "/wowforever"
SLASH_YAQOL6 = "/wft"

SlashCmdList["YAQOL"] = function(msg)
    msg = string.lower(strtrim(msg or ""))
    if msg == "reset" then
        if ns.ResetProfile then
            ns.ResetProfile()
        else
            for k, v in pairs(ns.defaultSettings) do
                ns.db[k] = v
                if ns.ApplyFrameState then ns.ApplyFrameState(k, v) end
            end
            ns.db.DisabledBuffs = {}
            if ns.RefreshGUIOptions then ns.RefreshGUIOptions() end
            print("|cffc866ff[YAQoL]|r Settings reset to default.")
        end
    elseif msg == "dump" then
        print("|cffc866ff[YAQoL Profile Dump]|r")
        print(ns.DumpDBToString())
    elseif msg == "export" then
        if ns.ExportProfileToString then
            local exportStr = ns.ExportProfileToString()
            print("|cffc866ff[YAQoL Profile Export]|r " .. tostring(exportStr))
        end
    else
        if ns.ToggleOptionsGUI then ns.ToggleOptionsGUI() end
    end
end
SlashCmdList["WOWFOREVER"] = SlashCmdList["YAQOL"]

ns.Log("CORE_INIT", "Core.lua registration complete.")
print("|cffc866ff[YAQoL v2.0]|r Loaded. Type |cffda99ff/yaqol|r or |cffda99ff/yql|r to open settings.")
