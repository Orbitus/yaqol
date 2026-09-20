-- Modules/QoLAutomations.lua: Quality of Life Event Automations
-- Author: Antigravity

local ADDON_NAME, ns = ...

-- List of General QoL Features
ns.GENERAL_QOL_FEATURES = {
    { 
        key = "AutoQuest", 
        name = "Auto Quest Automator", 
        desc = "Auto accepts & turns in quests (Hold SHIFT to bypass). Will NOT auto turn-in if item choices exist." 
    },
    { 
        key = "AutoRepair", 
        name = "Auto Repair Gear", 
        desc = "Automatically repairs equipment at repair vendors and prints cost to chat." 
    },
    { 
        key = "AutoSellGreys", 
        name = "Auto Sell Junk (Greys)", 
        desc = "Automatically sells poor/grey quality items to merchants upon opening." 
    },
    { 
        key = "FastLoot", 
        name = "Fast Speed Looting", 
        desc = "Instantly loots all items from targets in a single tick, bypassing Blizzard's slow loot animation delay." 
    },
    { 
        key = "MaxCameraZoom", 
        name = "Max Camera Distance", 
        desc = "Extends maximum camera zoom distance for improved combat visibility." 
    },
    { 
        key = "HideRedErrors", 
        name = "Hide Red Combat Errors", 
        desc = "Filters out spammy combat error text (e.g. 'Not enough energy', 'Ability not ready', 'Out of range') while keeping quest & system alerts." 
    },
    { 
        key = "AutoDismount", 
        name = "Auto-Dismount on Action", 
        desc = "Automatically dismounts when attempting to cast spells or perform actions while mounted." 
    },
    { 
        key = "ChatCopyURL", 
        name = "Chat: Clickable URL Links", 
        desc = "Makes URLs in chat clickable with an instant copy-to-clipboard popup." 
    },
    { 
        key = "ChatClassColors", 
        name = "Chat: Class Colored Names", 
        desc = "Colors player names in all chat channels according to their class." 
    },
    { 
        key = "ChatShortChannels", 
        name = "Chat: Short Channel Tags", 
        desc = "Shortens chat channel tags to clean abbreviations (e.g. [1. General] -> [1], [Guild] -> [G])." 
    },
    { 
        key = "QuestAutoMarkTarget", 
        name = "Quest Mob: Target Auto-Marker", 
        desc = "Setzt automatisch den Totenkopf-Raidmarker auf dein anvisiertes Ziel, wenn es für eine aktive Quest benötigt wird." 
    },
    { 
        key = "QuestNameplateHighlight", 
        name = "Quest Mob: Nameplate Icon & Fortschritt", 
        desc = "Zeigt ein goldenes Quest-Icon und den Ziel-Fortschritt (z.B. [0/8]) direkt über den Namensplaketten von Quest-Gegnern an." 
    },
}

-- Format Money helper
function ns.FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    local str = ""
    if gold > 0 then str = str .. gold .. "g " end
    if silver > 0 or gold > 0 then str = str .. silver .. "s " end
    str = str .. cop .. "c"
    return str
end

local function DoFastLoot()
    if not WOWForeverAddonDB or not WOWForeverAddonDB.FastLoot then return end
    local numLootItems = GetNumLootItems and GetNumLootItems() or 0
    if numLootItems > 0 then
        for i = numLootItems, 1, -1 do
            LootSlot(i)
        end
    end
end

----------------------------------------------------
-- ERROR FILTERING & AUTO-DISMOUNT TABLES
----------------------------------------------------
local blacklistedErrors = {}
local errorGlobals = {
    "ERR_SPELL_COOLDOWN",
    "ERR_ABILITY_COOLDOWN",
    "ERR_ITEM_COOLDOWN",
    "ERR_OUT_OF_MANA",
    "ERR_OUT_OF_ENERGY",
    "ERR_OUT_OF_RAGE",
    "ERR_OUT_OF_FOCUS",
    "ERR_OUT_OF_RUNIC_POWER",
    "ERR_OUT_OF_HEALTH",
    "ERR_OUT_OF_FURY",
    "ERR_OUT_OF_PAIN",
    "ERR_SPELL_OUT_OF_RANGE",
    "ERR_BADATTACKFACING",
    "ERR_BADATTACKPOS",
    "ERR_AUTOFOLLOW_TOO_FAR",
    "ERR_ATTACK_DEAD",
    "ERR_NO_ATTACK_TARGET",
    "ERR_INVALID_ATTACK_TARGET",
    "ERR_NOT_WHILE_MOVING",
    "ERR_ABILITY_NOT_USABLE",
    "ERR_GENERIC_NO_TARGET",
    "ERR_SPELL_FAILED_ALREADY_AT_FULL_MANA",
    "ERR_SPELL_FAILED_ALREADY_AT_FULL_HEALTH",
    "SPELL_FAILED_MOVING",
    "SPELL_FAILED_SPELL_IN_PROGRESS",
    "SPELL_FAILED_NOT_STANDING",
    "SPELL_FAILED_LINE_OF_SIGHT",
}

for _, g in ipairs(errorGlobals) do
    local val = _G[g]
    if val and type(val) == "string" then
        blacklistedErrors[val] = true
    end
end

-- Hook UIErrorsFrame to filter combat errors
if UIErrorsFrame and UIErrorsFrame.AddMessage then
    local origAddMessage = UIErrorsFrame.AddMessage
    UIErrorsFrame.AddMessage = function(self, msg, ...)
        local db = ns.db or WOWForeverAddonDB or ns.defaultSettings
        if db and db.HideRedErrors and msg and blacklistedErrors[msg] then
            return
        end
        return origAddMessage(self, msg, ...)
    end
end

-- Mount error triggers for Auto-Dismount
local mountErrorStrings = {}
local mountGlobals = {
    "ERR_NOT_WHILE_MOUNTED",
    "ERR_ATTACK_MOUNTED",
    "ERR_TAXIPLAYERALREADYMOUNTED",
    "SPELL_FAILED_NOT_MOUNTED",
}
for _, mg in ipairs(mountGlobals) do
    local val = _G[mg]
    if val and type(val) == "string" then
        mountErrorStrings[val] = true
    end
end

-- QoL Event Automations Frame
local qolFrame = CreateFrame("Frame")
qolFrame:RegisterEvent("QUEST_DETAIL")
qolFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
qolFrame:RegisterEvent("QUEST_PROGRESS")
qolFrame:RegisterEvent("QUEST_COMPLETE")
qolFrame:RegisterEvent("GOSSIP_SHOW")
qolFrame:RegisterEvent("MERCHANT_SHOW")
qolFrame:RegisterEvent("LOOT_OPENED")
qolFrame:RegisterEvent("LOOT_READY")
qolFrame:RegisterEvent("LOOT_SLOT_CLEARED")
qolFrame:RegisterEvent("UI_ERROR_MESSAGE")
qolFrame:RegisterEvent("PLAYER_LOGIN")

qolFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "LOOT_OPENED" or event == "LOOT_READY" or event == "LOOT_SLOT_CLEARED" then
        DoFastLoot()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.01, DoFastLoot)
            C_Timer.After(0.05, DoFastLoot)
        end
    elseif event == "QUEST_DETAIL" then
        if WOWForeverAddonDB.AutoQuest and not IsShiftKeyDown() then
            AcceptQuest()
        end
    elseif event == "QUEST_ACCEPT_CONFIRM" then
        if WOWForeverAddonDB.AutoQuest and not IsShiftKeyDown() then
            ConfirmAcceptQuest()
        end
    elseif event == "QUEST_PROGRESS" then
        if WOWForeverAddonDB.AutoQuest and not IsShiftKeyDown() then
            if IsQuestCompletable and IsQuestCompletable() then
                CompleteQuest()
            end
        end
    elseif event == "QUEST_COMPLETE" then
        if WOWForeverAddonDB.AutoQuest and not IsShiftKeyDown() then
            local numChoices = GetNumQuestChoices and GetNumQuestChoices() or 0
            if numChoices <= 1 then
                GetQuestReward(1)
            else
                print("|cffc866ff[YAQoL]|r Multiple quest rewards available. Please select your reward manually.")
            end
        end
    elseif event == "GOSSIP_SHOW" then
        if WOWForeverAddonDB.AutoQuest and not IsShiftKeyDown() then
            if C_GossipInfo then
                local activeQuests = C_GossipInfo.GetActiveQuests()
                if activeQuests and #activeQuests > 0 then
                    for _, q in ipairs(activeQuests) do
                        if q.isComplete then
                            C_GossipInfo.SelectActiveQuest(q.questID)
                            return
                        end
                    end
                end
                local availableQuests = C_GossipInfo.GetAvailableQuests()
                if availableQuests and #availableQuests > 0 then
                    C_GossipInfo.SelectAvailableQuest(availableQuests[1].questID)
                    return
                end
            end
        end
    elseif event == "MERCHANT_SHOW" then
        if WOWForeverAddonDB.AutoRepair and CanMerchantRepair and CanMerchantRepair() then
            local repairCost, canRepair = GetRepairAllCost()
            if canRepair and repairCost > 0 then
                local money = GetMoney()
                if money >= repairCost then
                    RepairAllItems(false)
                    print("|cffc866ff[YAQoL]|r Repaired gear for " .. ns.FormatMoney(repairCost) .. ".")
                end
            end
        end

        if WOWForeverAddonDB.AutoSellGreys then
            local itemsToSell = {}
            for bag = 0, 4 do
                local numSlots = (C_Container and C_Container.GetContainerNumSlots) and C_Container.GetContainerNumSlots(bag) or GetContainerNumSlots(bag)
                if numSlots and numSlots > 0 then
                    for slot = 1, numSlots do
                        local quality, price, count
                        if C_Container and C_Container.GetContainerItemInfo then
                            local info = C_Container.GetContainerItemInfo(bag, slot)
                            if info then
                                quality = info.quality
                                price = info.hasNoValue and 0 or (info.sellPrice or 0)
                                count = info.stackCount or 1
                            end
                        else
                            local _, itemCount, _, itemQuality, _, _, link = GetContainerItemInfo(bag, slot)
                            quality = itemQuality
                            count = itemCount or 1
                            if link then
                                local _, _, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(link)
                                price = itemSellPrice or 0
                            end
                        end

                        if quality == 0 then
                            table.insert(itemsToSell, { bag = bag, slot = slot, price = price or 0, count = count or 1 })
                        end
                    end
                end
            end

            if #itemsToSell > 0 then
                local index = 1
                local totalEarned = 0
                C_Timer.NewTicker(0.08, function(ticker)
                    if index > #itemsToSell then
                        ticker:Cancel()
                        if totalEarned > 0 then
                            print("|cffc866ff[YAQoL]|r Sold " .. #itemsToSell .. " grey junk items for " .. ns.FormatMoney(totalEarned) .. ".")
                        end
                        return
                    end
                    local item = itemsToSell[index]
                    totalEarned = totalEarned + (item.price * item.count)
                    if C_Container and C_Container.UseContainerItem then
                        C_Container.UseContainerItem(item.bag, item.slot)
                    else
                        UseContainerItem(item.bag, item.slot)
                    end
                    index = index + 1
                end)
            end
        end
    elseif event == "PLAYER_LOGIN" then
        if SetCVar then
            if GetCVar("autoDismount") ~= nil then
                SetCVar("autoDismount", "1")
            end
            if GetCVar("autoDismountFlying") ~= nil then
                SetCVar("autoDismountFlying", "1")
            end
        end
    elseif event == "UI_ERROR_MESSAGE" then
        local db = ns.db or WOWForeverAddonDB or ns.defaultSettings
        if db and db.AutoDismount then
            local msg = (type(arg2) == "string" and arg2) or (type(arg1) == "string" and arg1)
            if msg and mountErrorStrings[msg] then
                if (IsMounted and IsMounted()) or (IsFlying and IsFlying()) then
                    if Dismount then
                        Dismount()
                    end
                end
            end
        end
    end
end)
