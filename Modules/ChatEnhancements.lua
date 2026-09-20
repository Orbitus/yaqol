-- Modules/ChatEnhancements.lua: URL Copy, Class Colors & Short Channels
-- Part of YAQoL v2.0 (Yet Another Quality of Life) by Orbitus / Liiina & Antigravity

local ADDON_NAME, ns = ...

local chatEvents = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
}

local chatGroups = {
    "SAY", "EMOTE", "YELL", "GUILD", "OFFICER", "GUILD_ACHIEVEMENT", "ACHIEVEMENT",
    "WHISPER", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING",
    "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "CHANNEL",
}

----------------------------------------------------
-- 1. COPY URL DIALOG (Sleek YAQoL Violet Theme)
----------------------------------------------------
local copyDialog = nil

function ns.ShowCopyURLDialog(url)
    if not copyDialog then
        copyDialog = CreateFrame("Frame", "YAQoLCopyURLDialog", UIParent, ns.backdropTemplate)
        copyDialog:SetSize(460, 140)
        copyDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        copyDialog:SetFrameStrata("DIALOG")
        copyDialog:EnableMouse(true)
        copyDialog:SetMovable(true)
        copyDialog:RegisterForDrag("LeftButton")
        copyDialog:SetScript("OnDragStart", copyDialog.StartMoving)
        copyDialog:SetScript("OnDragStop", copyDialog.StopMovingOrSizing)
        copyDialog:Hide()

        ns.ApplyModernBackdrop(copyDialog, 0.08, 0.04, 0.12, 0.95, 0.45, 0.2, 0.7, 1)

        -- Title
        local title = copyDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", copyDialog, "TOPLEFT", 16, -14)
        title:SetText("|cffda99ffYAQoL|r - |cffffffffCopy Link to Clipboard|r")

        -- Subtitle / Instruction
        local info = copyDialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        info:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
        info:SetText("|cffa388ccPress |r|cffffd100Ctrl+C|r|cffa388cc to copy link, then |r|cffffd100Escape|r|cffa388cc or |r|cffffd100Enter|r|cffa388cc to close.|r")

        -- EditBox container
        local ebBox = CreateFrame("Frame", nil, copyDialog, ns.backdropTemplate)
        ebBox:SetSize(428, 32)
        ebBox:SetPoint("TOPLEFT", copyDialog, "TOPLEFT", 16, -58)
        ns.ApplyModernBackdrop(ebBox, 0.04, 0.02, 0.07, 0.9, 0.25, 0.12, 0.38, 0.8)

        local editBox = CreateFrame("EditBox", nil, ebBox)
        editBox:SetAllPoints()
        editBox:SetFontObject(ChatFontNormal or GameFontHighlight)
        editBox:SetAutoFocus(true)
        editBox:SetTextInsets(8, 8, 0, 0)
        editBox:SetTextColor(0, 0.82, 1, 1)
        copyDialog.editBox = editBox

        editBox:SetScript("OnEscapePressed", function()
            copyDialog:Hide()
        end)
        editBox:SetScript("OnEnterPressed", function()
            copyDialog:Hide()
        end)
        editBox:SetScript("OnEditFocusLost", function()
            -- Keep text intact
        end)

        -- Close Button
        local closeBtn = CreateFrame("Button", nil, copyDialog, ns.backdropTemplate)
        closeBtn:SetSize(90, 24)
        closeBtn:SetPoint("BOTTOMRIGHT", copyDialog, "BOTTOMRIGHT", -16, 12)
        ns.ApplyModernBackdrop(closeBtn, 0.22, 0.1, 0.35, 0.8, 0.45, 0.2, 0.65, 0.8)

        local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
        closeText:SetText("|cffffffffClose|r")

        closeBtn:SetScript("OnClick", function()
            copyDialog:Hide()
        end)
        closeBtn:SetScript("OnEnter", function(self)
            ns.ApplyModernBackdrop(self, 0.35, 0.15, 0.55, 0.95, 0.75, 0.3, 1.0, 1)
        end)
        closeBtn:SetScript("OnLeave", function(self)
            ns.ApplyModernBackdrop(self, 0.22, 0.1, 0.35, 0.8, 0.45, 0.2, 0.65, 0.8)
        end)
    end

    copyDialog.editBox:SetText(url)
    copyDialog:Show()
    copyDialog.editBox:SetFocus()
    copyDialog.editBox:HighlightText()
end

-- Hook SetItemRef to catch clicks on "yaqolurl:" links
hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
    if link and type(link) == "string" and link:sub(1, 9) == "yaqolurl:" then
        local targetUrl = link:sub(10)
        if targetUrl and #targetUrl > 0 then
            ns.ShowCopyURLDialog(targetUrl)
        end
    end
end)

----------------------------------------------------
-- 2. URL PARSER & CLEANER
----------------------------------------------------
local function FormatURL(url)
    local post = ""
    while #url > 0 and url:match("[%.,!?:;%)%]\">]$") do
        post = url:sub(-1) .. post
        url = url:sub(1, -2)
    end
    if #url == 0 then return post end
    return "|cff00d2ff|Hyaqolurl:" .. url .. "|h[" .. url .. "]|h|r" .. post
end

local function ProcessURLs(msg)
    if not msg or type(msg) ~= "string" then return msg end

    -- Fast early exit if no URL patterns are present in message
    if not msg:find("http") and not msg:find("www%.") and not msg:find("discord") then
        return msg
    end

    -- Avoid double-linking if already in a link tag
    if msg:find("|Hyaqolurl:") then return msg end

    -- 1. Standard http:// and https:// URLs
    msg = msg:gsub("(https?://%S+)", FormatURL)

    -- 2. www. addresses
    msg = msg:gsub("^(www%.%S+)", function(url) return FormatURL("https://" .. url) end)
    msg = msg:gsub("([^/%w])(www%.%S+)", function(pre, url)
        return pre .. FormatURL("https://" .. url)
    end)

    -- 3. Discord invite links
    msg = msg:gsub("^(discord%.gg/%S+)", function(url) return FormatURL("https://" .. url) end)
    msg = msg:gsub("([^/%w])(discord%.gg/%S+)", function(pre, url)
        return pre .. FormatURL("https://" .. url)
    end)
    msg = msg:gsub("^(discord%.com/invite/%S+)", function(url) return FormatURL("https://" .. url) end)
    msg = msg:gsub("([^/%w])(discord%.com/invite/%S+)", function(pre, url)
        return pre .. FormatURL("https://" .. url)
    end)

    return msg
end

----------------------------------------------------
-- 3. SHORT CHANNEL REPLACEMENTS
----------------------------------------------------
local function ProcessShortChannels(msg)
    if not msg or type(msg) ~= "string" then return msg end

    -- Fast early exit if no brackets are present
    if not msg:find("%[") then return msg end

    -- Numbered channels: e.g. [1. General - City] or [1. Allgemein - Stadt] -> [1]
    msg = msg:gsub("(|Hchannel:channel:(%d+)|h)%[[^%]]+%]%(|h%)", "%1[%2]%3")
    msg = msg:gsub("(|Hchannel:channel:(%d+)|h)%[[^%]]+%](|h)", "%1[%2]%3")

    -- Named channels with hyperlinks
    msg = msg:gsub("(|Hchannel:Guild|h)%[[^%]]+%](|h)", "%1[G]%2")
    msg = msg:gsub("(|Hchannel:Officer|h)%[[^%]]+%](|h)", "%1[O]%2")
    msg = msg:gsub("(|Hchannel:Party|h)%[[^%]]+%](|h)", "%1[P]%2")
    msg = msg:gsub("(|Hchannel:Party Leader|h)%[[^%]]+%](|h)", "%1[PL]%2")
    msg = msg:gsub("(|Hchannel:Raid|h)%[[^%]]+%](|h)", "%1[R]%2")
    msg = msg:gsub("(|Hchannel:Raid Leader|h)%[[^%]]+%](|h)", "%1[RL]%2")
    msg = msg:gsub("(|Hchannel:Raid Warning|h)%[[^%]]+%](|h)", "%1[RW]%2")
    msg = msg:gsub("(|Hchannel:Instance|h)%[[^%]]+%](|h)", "%1[I]%2")
    msg = msg:gsub("(|Hchannel:Instance Leader|h)%[[^%]]+%](|h)", "%1[IL]%2")

    -- Plain bracket fallbacks for German/English client
    msg = msg:gsub("%[Allgemein %- [^%]]+%]", "[1]")
    msg = msg:gsub("%[Handel %- [^%]]+%]", "[2]")
    msg = msg:gsub("%[LokaleVerteidigung %- [^%]]+%]", "[3]")
    msg = msg:gsub("%[General %- [^%]]+%]", "[1]")
    msg = msg:gsub("%[Trade %- [^%]]+%]", "[2]")
    msg = msg:gsub("%[LocalDefense %- [^%]]+%]", "[3]")
    msg = msg:gsub("%[LookingForGroup%]", "[LFG]")
    msg = msg:gsub("%[SucheNachGruppe%]", "[SNG]")
    msg = msg:gsub("%[Gilde%]", "[G]")
    msg = msg:gsub("%[Offizier%]", "[O]")
    msg = msg:gsub("%[Gruppe%]", "[P]")
    msg = msg:gsub("%[Gruppenanführer%]", "[PL]")
    msg = msg:gsub("%[Schlachtzug%]", "[R]")
    msg = msg:gsub("%[Schlachtzugleiter%]", "[RL]")
    msg = msg:gsub("%[Schlachtzugswarnung%]", "[RW]")
    msg = msg:gsub("%[Instanz%]", "[I]")

    return msg
end

----------------------------------------------------
-- 4. CHAT FILTER CALLBACK
----------------------------------------------------
local function YAQoL_ChatFilter(chatFrame, event, msg, ...)
    local db = ns.db or WOWForeverAddonDB or ns.defaultSettings

    if db.ChatCopyURL ~= false then
        msg = ProcessURLs(msg)
    end

    if db.ChatShortChannels == true then
        msg = ProcessShortChannels(msg)
    end

    return false, msg, ...
end

----------------------------------------------------
-- 5. CLASS COLOR CONFIGURATION
----------------------------------------------------
function ns.ApplyChatClassColors()
    local db = ns.db or WOWForeverAddonDB or ns.defaultSettings
    local enabled = db.ChatClassColors ~= false

    if ToggleChatColorNamesByClassGroup then
        for _, grp in ipairs(chatGroups) do
            ToggleChatColorNamesByClassGroup(enabled, grp)
        end
        for i = 1, 10 do
            ToggleChatColorNamesByClassGroup(enabled, "CHANNEL" .. i)
        end
    end
end

----------------------------------------------------
-- 6. INITIALIZATION & REFRESH
----------------------------------------------------
function ns.UpdateChatSettings()
    ns.ApplyChatClassColors()
end

local function InitChatEnhancements()
    for _, event in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(event, YAQoL_ChatFilter)
    end
    ns.ApplyChatClassColors()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
    InitChatEnhancements()
end)
