-- Modules/ProfileManager.lua: Multi-Profile Management & Shareable String Serializer
-- Part of YAQoL v2.0 (Yet Another Quality of Life) by Orbitus / Liiina & Antigravity

local ADDON_NAME, ns = ...

-- Base64 Encoding & Decoding for safe profile sharing
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64lookup = {}
for i = 1, #b64chars do
    b64lookup[b64chars:sub(i, i)] = i - 1
end

local function EncodeBase64(data)
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2^(6 - i) or 0) end
        return b64chars:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function DecodeBase64(data)
    data = data:gsub('[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', b64lookup[x]
        if not f then return '' end
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0) end
        return string.char(c)
    end))
end

----------------------------------------------------
-- Profile Management API
----------------------------------------------------

function ns.GetActiveProfileName()
    if not YAQoLDB or not YAQoLDB.activeProfile then
        return "Default"
    end
    return YAQoLDB.activeProfile
end

function ns.GetProfileList()
    local list = {}
    if YAQoLDB and YAQoLDB.profiles then
        for name in pairs(YAQoLDB.profiles) do
            table.insert(list, name)
        end
    end
    table.sort(list, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return a < b
    end)
    if #list == 0 then table.insert(list, "Default") end
    return list
end

function ns.SetActiveProfile(name)
    if not YAQoLDB or not YAQoLDB.profiles or not YAQoLDB.profiles[name] then
        return false, "Profile not found"
    end

    YAQoLDB.activeProfile = name
    ns.db = YAQoLDB.profiles[name]
    _G["WOWForeverAddonDB"] = ns.db
    _G["WOWForeverAddonDBPerChar"] = ns.db
    WOWForeverAddonDB = ns.db

    -- Sync missing keys from defaults
    for k, v in pairs(ns.defaultSettings) do
        if ns.db[k] == nil then
            if type(v) == "table" then
                ns.db[k] = CopyTable and CopyTable(v) or {}
            else
                ns.db[k] = v
            end
        end
    end

    if ns.ApplyAllStates then ns.ApplyAllStates() end
    if ns.UpdateHUD then ns.UpdateHUD() end
    if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
    if ns.UpdateXPBar then ns.UpdateXPBar() end
    if ns.UpdateChatSettings then ns.UpdateChatSettings() end
    if ns.RefreshQuestNameplates then ns.RefreshQuestNameplates() end
    if ns.RefreshGUIOptions then ns.RefreshGUIOptions() end

    ns.Log("PROFILE", "Switched active profile to: " .. tostring(name))
    print("|cffc866ff[YAQoL]|r Activated profile: |cffffffff" .. tostring(name) .. "|r")
    return true
end

function ns.CreateProfile(name, copyFromActive)
    if not name or strtrim(name) == "" then
        return false, "Profile name cannot be empty."
    end
    name = strtrim(name)

    if YAQoLDB.profiles[name] then
        return false, "A profile named '" .. name .. "' already exists."
    end

    local source = copyFromActive and ns.db or ns.UserPresetDB or ns.defaultSettings
    local newTable = CopyTable and CopyTable(source) or {}
    for k, v in pairs(source) do
        if type(v) == "table" then
            newTable[k] = CopyTable and CopyTable(v) or {}
        else
            newTable[k] = v
        end
    end

    YAQoLDB.profiles[name] = newTable
    ns.SetActiveProfile(name)
    ns.Log("PROFILE", "Created new profile: " .. name)
    print("|cffc866ff[YAQoL]|r Created and switched to new profile: |cffffffff" .. name .. "|r")
    return true
end

function ns.DeleteProfile(name)
    if not name or name == "Default" then
        return false, "Cannot delete the 'Default' profile."
    end
    if not YAQoLDB.profiles[name] then
        return false, "Profile does not exist."
    end

    YAQoLDB.profiles[name] = nil
    if YAQoLDB.activeProfile == name then
        ns.SetActiveProfile("Default")
    elseif ns.RefreshGUIOptions then
        ns.RefreshGUIOptions()
    end

    ns.Log("PROFILE", "Deleted profile: " .. name)
    print("|cffc866ff[YAQoL]|r Deleted profile: |cffffffff" .. name .. "|r")
    return true
end

function ns.ResetProfile(name)
    name = name or ns.GetActiveProfileName()
    if not YAQoLDB.profiles[name] then return false, "Profile not found." end

    local source = ns.UserPresetDB or ns.defaultSettings
    local resetTbl = CopyTable and CopyTable(source) or {}
    for k, v in pairs(source) do
        if type(v) == "table" then
            resetTbl[k] = CopyTable and CopyTable(v) or {}
        else
            resetTbl[k] = v
        end
    end

    YAQoLDB.profiles[name] = resetTbl
    if YAQoLDB.activeProfile == name then
        ns.db = resetTbl
        _G["WOWForeverAddonDB"] = resetTbl
        _G["WOWForeverAddonDBPerChar"] = resetTbl
        WOWForeverAddonDB = resetTbl
        if ns.ApplyAllStates then ns.ApplyAllStates() end
        if ns.UpdateHUD then ns.UpdateHUD() end
        if ns.UpdateMinimapBar then ns.UpdateMinimapBar() end
        if ns.UpdateXPBar then ns.UpdateXPBar() end
        if ns.UpdateChatSettings then ns.UpdateChatSettings() end
        if ns.RefreshQuestNameplates then ns.RefreshQuestNameplates() end
        if ns.RefreshGUIOptions then ns.RefreshGUIOptions() end
    end

    ns.Log("PROFILE", "Reset profile to defaults: " .. name)
    print("|cffc866ff[YAQoL]|r Profile '|cffffffff" .. name .. "|r' reset to default settings.")
    return true
end

----------------------------------------------------
-- String Serializer (Export & Import)
----------------------------------------------------

function ns.ExportProfileToString(profileName)
    profileName = profileName or ns.GetActiveProfileName()
    local tbl = YAQoLDB and YAQoLDB.profiles and YAQoLDB.profiles[profileName]
    if not tbl then return nil, "Profile not found" end

    local entries = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            local sub = {}
            for sk, sv in pairs(v) do
                table.insert(sub, tostring(sk) .. ":" .. tostring(sv))
            end
            table.insert(entries, tostring(k) .. "={" .. table.concat(sub, ",") .. "}")
        else
            table.insert(entries, tostring(k) .. "=" .. tostring(v))
        end
    end
    table.sort(entries)
    local rawStr = table.concat(entries, ";")
    local b64 = EncodeBase64(rawStr)
    return "YAQOL:2:" .. b64
end

function ns.ImportProfileFromString(importStr, targetName)
    if not importStr or importStr == "" then
        return false, "Empty import string."
    end
    importStr = strtrim(importStr)

    local rawStr = nil

    -- 1. Check for YAQOL:2: prefix
    local b64Data = importStr:match("^YAQOL:2:(.+)$")
    if b64Data then
        rawStr = DecodeBase64(strtrim(b64Data))
    else
        -- 2. Try raw Base64 payload directly (in case user copied without the prefix)
        local testB64 = DecodeBase64(importStr)
        if testB64 and testB64:find("=") then
            rawStr = testB64
        end
    end

    -- 3. Check for Lua memory dump format fallback
    if (not rawStr or rawStr == "") and importStr:find("%[") and importStr:find("%]") then
        return ns.ImportDBFromString(importStr)
    end

    -- 4. Check for direct key=value pair string
    if (not rawStr or rawStr == "") and importStr:find("=") then
        rawStr = importStr
    end

    if not rawStr or rawStr == "" then
        return false, "Invalid YAQoL string format. Could not decode settings payload."
    end

    targetName = targetName and strtrim(targetName) ~= "" and strtrim(targetName) or ("Imported_" .. date("%m%d_%H%M"))
    local importedDB = {}
    local parsedCount = 0

    for pair in rawStr:gmatch("[^;]+") do
        local key, val = pair:match("^([^=]+)=(.*)$")
        if key and val then
            parsedCount = parsedCount + 1
            if val == "true" then
                importedDB[key] = true
            elseif val == "false" then
                importedDB[key] = false
            elseif tonumber(val) then
                importedDB[key] = tonumber(val)
            elseif val:match("^{(.*)}$") then
                local inner = val:match("^{(.*)}$")
                local subTbl = {}
                for subPair in inner:gmatch("[^,]+") do
                    local sk, sv = subPair:match("^([^:]+):(.*)$")
                    if sk and sv then
                        if sv == "true" then subTbl[sk] = true
                        elseif sv == "false" then subTbl[sk] = false
                        elseif tonumber(sv) then subTbl[sk] = tonumber(sv)
                        else subTbl[sk] = sv end
                    end
                end
                importedDB[key] = subTbl
            else
                importedDB[key] = val
            end
        end
    end

    if parsedCount == 0 then
        return false, "No valid settings could be parsed from the import string. Please ensure the full string was copied."
    end

    -- Fill any missing keys from defaults
    local keyCount = 0
    for k, v in pairs(ns.defaultSettings) do
        if importedDB[k] == nil then
            if type(v) == "table" then
                importedDB[k] = CopyTable and CopyTable(v) or {}
            else
                importedDB[k] = v
            end
        end
        keyCount = keyCount + 1
    end

    YAQoLDB.profiles[targetName] = importedDB
    ns.SetActiveProfile(targetName)
    ns.Log("PROFILE_IMPORT", string.format("Imported profile '%s' with %d settings.", targetName, keyCount))
    print(string.format("|cffc866ff[YAQoL]|r Successfully imported profile |cffffffff'%s'|r!", targetName))
    return true, targetName
end
