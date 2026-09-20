-- Modules/Changelog.lua: In-Game Release Notes & First-Login Update Popup
local ADDON_NAME, ns = ...

-- Centralized Version History & Changelog Database
ns.CHANGELOG_DATA = {
    {
        version = "2.0.12",
        date = "2026-09-20",
        title = "In-Game Changelog & Update Notification Popup",
        general = {
            "Added in-game Changelog section under Community in Options GUI.",
            "Added automatic 'What's New' Popup dialog on first login after update."
        },
        features = {
            "New dedicated Changelog tab in YAQoL Options Control Panel.",
            "Categorized release notes split into General, New Functions / Removed Functions, and Bugfixes.",
            "Interactive 'Re-Open What's New Popup' button."
        },
        fixes = {
            "SavedVariables lastSeenVersion tracking to prevent duplicate update popups."
        }
    },
    {
        version = "2.0.11",
        date = "2026-09-20",
        title = "Changelog & WoWUp Update Verification",
        general = {
            "Added in-game Changelog viewer in Options Control Panel.",
            "Added automatic 'What's New' Popup dialog on first login after addon updates.",
            "Optimized client updater release pipeline and metadata alignment."
        },
        features = {
            "New Changelog tab under Community category in YAQoL settings.",
            "Interactive 'Re-Open Release Notes' button in settings.",
            "First-launch update alert popup with categorized release notes."
        },
        fixes = {
            "Standardized single versioned ZIP asset YAQoL-v2.0.11.zip for clean WoWUp extraction.",
            "Synchronized version metadata across TOC, Options GUI, and Minimap bar tooltips."
        }
    },
    {
        version = "2.0.10",
        date = "2026-09-20",
        title = "Client Updater Pipeline Alignment",
        general = {
            "WoWUp client distribution build verification and tag sync."
        },
        features = {},
        fixes = {
            "Release asset naming alignment for third-party addon managers."
        }
    },
    {
        version = "2.0.9",
        date = "2026-09-20",
        title = "WoWUp Package Integration",
        general = {
            "Packaged single versioned zip asset for WoWUp automated installation."
        },
        features = {
            "Direct GitHub release tracking for WoWUp client."
        },
        fixes = {
            "Fixed WoWUp unzip folder structure mismatch."
        }
    },
    {
        version = "2.0.8",
        date = "2026-09-20",
        title = "Quest Nameplates & Safety Checks",
        general = {
            "Combat safety & quest tracking polish."
        },
        features = {
            "Added CanSetRaidMarker safety check before auto-marking quest targets."
        },
        fixes = {
            "Tightened Nameplate Quest Indicator positioning."
        }
    },
    {
        version = "2.0.7",
        date = "2026-09-20",
        title = "Asset Formatting Hotfix",
        general = {
            "Reverted to single YAQoL zip asset to resolve updater extract errors."
        },
        features = {},
        fixes = {
            "Resolved archive path layout for WoWUp client."
        }
    },
    {
        version = "2.0.0",
        date = "2026-09-18",
        title = "YAQoL Streamer Edition 2.0 Major Update",
        general = {
            "Complete rewrite and rebrand to YAQoL (Yet Another Quality of Life).",
            "Modern Violet Void glassmorphism UI theme with glowing amethyst accents."
        },
        features = {
            "Added Leveling Analytics & Rested XP Bar.",
            "Added Buff & Pet Reminder HUD.",
            "Added Minimap HidingBar collector for addon icons.",
            "Added Action Bar Modernizer (clean icons, gryphon toggles, hotkey formatting).",
            "Added Profile Export/Import and instant Settings Search."
        },
        fixes = {
            "Fixed frame taint on Blizzard MicroMenu and BagsBar fading.",
            "Fixed chat link copy URL tooltip behavior."
        }
    }
}

local popupFrame = nil

-- Create & Show First-Login Version Changelog Popup
function ns.ShowChangelogPopup(versionOverride)
    local curVersion = versionOverride or ((C_AddOns and C_AddOns.GetAddOnMetadata) and C_AddOns.GetAddOnMetadata("YAQoL", "Version") or "2.0.12")
    
    -- Find entry for curVersion or fallback to latest entry
    local entry = ns.CHANGELOG_DATA[1]
    for _, item in ipairs(ns.CHANGELOG_DATA) do
        if item.version == curVersion then
            entry = item
            break
        end
    end

    if not popupFrame then
        popupFrame = CreateFrame("Frame", "YAQoLChangelogPopupFrame", UIParent, ns.backdropTemplate)
        tinsert(UISpecialFrames, "YAQoLChangelogPopupFrame")
        popupFrame:SetSize(540, 440)
        popupFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
        popupFrame:SetMovable(true)
        popupFrame:EnableMouse(true)
        popupFrame:RegisterForDrag("LeftButton")
        popupFrame:SetScript("OnDragStart", popupFrame.StartMoving)
        popupFrame:SetScript("OnDragStop", popupFrame.StopMovingOrSizing)
        popupFrame:SetFrameStrata("DIALOG")
        popupFrame:SetClampedToScreen(true)

        -- Dark Violet Glassmorphism Frame
        ns.ApplyModernBackdrop(popupFrame, 0.05, 0.03, 0.09, 0.98, 0.65, 0.25, 0.95, 0.95)

        -- Top Electric Violet Accent Line
        local topBar = popupFrame:CreateTexture(nil, "OVERLAY")
        topBar:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", 1, -1)
        topBar:SetPoint("TOPRIGHT", popupFrame, "TOPRIGHT", -1, -1)
        topBar:SetHeight(3)
        topBar:SetColorTexture(0.72, 0.25, 1.0, 1.0)

        -- Header
        local icon = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        icon:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", 20, -18)
        icon:SetText("|cffc866ff✦|r")

        local title = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        title:SetText("|cffc866ffYAQoL Update|r  |cffffffffWhat's New in v" .. tostring(entry.version) .. "|r")
        popupFrame.title = title

        local subtitle = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        subtitle:SetText("|cffa388cc" .. (entry.title or "Clean UI Visibility & Quality of Life Automations") .. "|r")
        popupFrame.subtitle = subtitle

        -- Close Button (Top-Right X)
        local closeX = CreateFrame("Button", nil, popupFrame, ns.backdropTemplate)
        closeX:SetSize(24, 22)
        closeX:SetPoint("TOPRIGHT", popupFrame, "TOPRIGHT", -12, -12)
        ns.ApplyModernBackdrop(closeX, 0.12, 0.06, 0.18, 0.8, 0.45, 0.18, 0.65, 0.6)

        local closeXText = closeX:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        closeXText:SetPoint("CENTER", closeX, "CENTER", 0, 0)
        closeXText:SetText("|cffccaaffX|r")

        closeX:SetScript("OnEnter", function()
            ns.ApplyModernBackdrop(closeX, 0.75, 0.12, 0.3, 0.95, 1.0, 0.2, 0.4, 1)
            closeXText:SetText("|cffffffffX|r")
        end)
        closeX:SetScript("OnLeave", function()
            ns.ApplyModernBackdrop(closeX, 0.12, 0.06, 0.18, 0.8, 0.45, 0.18, 0.65, 0.6)
            closeXText:SetText("|cffccaaffX|r")
        end)
        closeX:SetScript("OnClick", function()
            popupFrame:Hide()
        end)

        -- Scroll Area for Content
        local scrollFrame = CreateFrame("ScrollFrame", "YAQoLPopupScrollFrame", popupFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", 18, -64)
        scrollFrame:SetPoint("BOTTOMRIGHT", popupFrame, "BOTTOMRIGHT", -28, 56)
        ns.StyleCustomScrollFrame(scrollFrame)
        popupFrame.scrollFrame = scrollFrame

        local content = CreateFrame("Frame", "YAQoLPopupScrollContent", scrollFrame)
        content:SetSize(470, 300)
        scrollFrame:SetScrollChild(content)
        popupFrame.content = content

        -- Bottom Action Buttons
        local gotItBtn = CreateFrame("Button", nil, popupFrame, ns.backdropTemplate)
        gotItBtn:SetSize(160, 30)
        gotItBtn:SetPoint("BOTTOMRIGHT", popupFrame, "BOTTOMRIGHT", -20, 16)
        ns.ApplyModernBackdrop(gotItBtn, 0.45, 0.16, 0.72, 0.95, 0.85, 0.4, 1.0, 1)

        local gotItTxt = gotItBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        gotItTxt:SetPoint("CENTER", gotItBtn, "CENTER", 0, 0)
        gotItTxt:SetText("|cffffffffVerstanden / Got it!|r")

        gotItBtn:SetScript("OnClick", function()
            popupFrame:Hide()
        end)

        local optsBtn = CreateFrame("Button", nil, popupFrame, ns.backdropTemplate)
        optsBtn:SetSize(160, 30)
        optsBtn:SetPoint("RIGHT", gotItBtn, "LEFT", -12, 0)
        ns.ApplyModernBackdrop(optsBtn, 0.14, 0.07, 0.22, 0.9, 0.45, 0.2, 0.65, 0.8)

        local optsTxt = optsBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        optsTxt:SetPoint("CENTER", optsBtn, "CENTER", 0, 0)
        optsTxt:SetText("|cffda99ffOptionen öffnen|r")

        optsBtn:SetScript("OnClick", function()
            popupFrame:Hide()
            if ns.CreateOptionsGUI then
                ns.CreateOptionsGUI()
            end
        end)
    else
        popupFrame.title:SetText("|cffc866ffYAQoL Update|r  |cffffffffWhat's New in v" .. tostring(entry.version) .. "|r")
        popupFrame.subtitle:SetText("|cffa388cc" .. (entry.title or "Clean UI Visibility & Quality of Life Automations") .. "|r")
    end

    -- Re-render scroll content for selected entry
    local content = popupFrame.content
    -- Clear old children textures/strings
    for _, child in ipairs({ content:GetRegions() }) do
        child:Hide()
    end
    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
    end

    local yPos = 0

    local function AddCategorySection(catTitle, catColorHex, catIcon, items)
        if not items or #items == 0 then return end
        
        local secHeader = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        secHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -yPos)
        secHeader:SetText(string.format("%s |c%s%s|r", catIcon, catColorHex, catTitle))
        yPos = yPos + 22

        for _, itemText in ipairs(items) do
            local bullet = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            bullet:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -yPos)
            bullet:SetPoint("RIGHT", content, "RIGHT", -10, 0)
            bullet:SetJustifyH("LEFT")
            bullet:SetText("|cffaaaaaa•|r |cffffffff" .. itemText .. "|r")
            yPos = yPos + 20
        end

        yPos = yPos + 10
    end

    -- 1. General
    AddCategorySection("General", "ffc866ff", "|cffc866ff🟣|r", entry.general)

    -- 2. New Functions / Removed Functions
    AddCategorySection("New Functions / Removed Functions", "ff00ffcc", "|cff00ffcc🟢|r", entry.features)

    -- 3. Bugfixes
    AddCategorySection("Bugfixes", "ffff7799", "|cffff7799🔧|r", entry.fixes)

    content:SetHeight(math.max(260, yPos + 20))
    popupFrame.scrollFrame:SetVerticalScroll(0)

    popupFrame:Show()

    -- Mark this version as seen in SavedVariables
    local db = ns.db or WOWForeverAddonDB
    if db then
        db.lastSeenVersion = curVersion
    end
end

-- Automatic login check for new addon version
function ns.CheckVersionPopupOnLogin()
    local curVersion = (C_AddOns and C_AddOns.GetAddOnMetadata) and C_AddOns.GetAddOnMetadata("YAQoL", "Version") or "2.0.12"
    local db = ns.db or WOWForeverAddonDB
    if not db then return end

    if db.lastSeenVersion ~= curVersion then
        C_Timer.After(1.5, function()
            ns.ShowChangelogPopup(curVersion)
        end)
    end
end
