-- Modules/BuffReminder.lua: Interactive Clickable Class Buff & Pet Reminder HUD
-- Author: Antigravity

local ADDON_NAME, ns = ...

-- Class Spell Configuration Table
ns.CLASS_SPELL_CONFIG = {
    MAGE = {
        buffs = {
            { spell = "Arcane Intellect", altSpells = { "Arcane Brilliance" }, texture = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
            { spell = "Ice Armor", altSpells = { "Mage Armor", "Frost Armor", "Molten Armor" }, texture = "Interface\\Icons\\Spell_Frost_FrostArmor02" },
        },
        pet = "Summon Water Elemental",
        petIcon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_02",
    },
    PRIEST = {
        buffs = {
            { spell = "Power Word: Fortitude", altSpells = { "Prayer of Fortitude" }, texture = "Interface\\Icons\\Spell_Holy_WordFortitude" },
            { spell = "Inner Fire", texture = "Interface\\Icons\\Spell_Holy_InnerFire" },
            { spell = "Shadow Protection", altSpells = { "Prayer of Shadow Protection" }, texture = "Interface\\Icons\\Spell_Shadow_AntiShadow" },
        },
    },
    DRUID = {
        buffs = {
            { spell = "Mark of the Wild", altSpells = { "Gift of the Wild" }, texture = "Interface\\Icons\\Spell_Nature_Regeneration" },
            { spell = "Thorns", texture = "Interface\\Icons\\Spell_Nature_Thorns" },
        },
    },
    PALADIN = {
        buffs = {
            { spell = "Blessing of Kings", altSpells = { "Greater Blessing of Kings", "Blessing of Might", "Blessing of Wisdom" }, texture = "Interface\\Icons\\Spell_Magic_MageArmor" },
            { spell = "Righteous Fury", texture = "Interface\\Icons\\Spell_Holy_SealOfFury" },
        },
    },
    WARLOCK = {
        buffs = {
            { spell = "Demon Armor", altSpells = { "Fel Armor", "Demon Skin" }, texture = "Interface\\Icons\\Spell_Shadow_RagingScream" },
        },
        pet = "Summon Imp",
        petIcon = "Interface\\Icons\\Spell_Shadow_SummonImp",
    },
    SHAMAN = {
        buffs = {
            { spell = "Lightning Shield", altSpells = { "Water Shield", "Earth Shield" }, texture = "Interface\\Icons\\Spell_Nature_LightningShield" },
        },
    },
    WARRIOR = {
        buffs = {
            { spell = "Battle Shout", altSpells = { "Commanding Shout" }, texture = "Interface\\Icons\\Ability_Warrior_BattleShout" },
        },
    },
    HUNTER = {
        pet = "Call Pet 1",
        petAlt = "Call Pet",
        petIcon = "Interface\\Icons\\Ability_Hunter_BeastCall",
    },
    DEATHKNIGHT = {
        buffs = {
            { spell = "Horn of Winter", texture = "Interface\\Icons\\INV_Misc_Horn_02" },
        },
        pet = "Raise Dead",
        petIcon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    },
}

local hudFrame = nil
local hudButtons = {}

function ns.GetSpellIconTexture(spellName, defaultTexture)
    if defaultTexture then return defaultTexture end
    if not spellName then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellName)
        if tex then return tex end
    end
    if GetSpellTexture then
        local tex = GetSpellTexture(spellName)
        if tex then return tex end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Taint-Safe Unit Aura Checking
function ns.CheckPlayerHasBuff(spellName, altSpells)
    if not spellName then return false end
    local searchNames = { string.lower(spellName) }
    if altSpells then
        for _, alt in ipairs(altSpells) do
            table.insert(searchNames, string.lower(alt))
        end
    end

    local found = false

    -- Method 1: AuraUtil.ForEachAura (Safe across modern Retail & Classic)
    if AuraUtil and AuraUtil.ForEachAura then
        pcall(function()
            AuraUtil.ForEachAura("player", "HELPFUL", nil, function(auraName)
                if auraName then
                    local lname = string.lower(auraName)
                    for _, s in ipairs(searchNames) do
                        if lname == s or string.find(lname, s) then
                            found = true
                            return true
                        end
                    end
                end
            end)
        end)
        if found then return true end
    end

    -- Method 2: UnitBuff / UnitAura (Legacy & Classic)
    local getAuraFunc = UnitBuff or UnitAura
    if getAuraFunc then
        for i = 1, 40 do
            local success, name = pcall(getAuraFunc, "player", i, "HELPFUL")
            if not success or not name then break end
            local lname = string.lower(name)
            for _, s in ipairs(searchNames) do
                if lname == s or string.find(lname, s) then return true end
            end
        end
    end

    -- Method 3: Protected C_UnitAuras fallback with pcall
    if C_UnitAuras then
        for i = 1, 40 do
            local success, aura
            if C_UnitAuras.GetAuraDataByIndex then
                success, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            elseif C_UnitAuras.GetBuffDataByIndex then
                success, aura = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
            end
            if not success or not aura then break end
            if aura and aura.name then
                local lname = string.lower(aura.name)
                for _, s in ipairs(searchNames) do
                    if lname == s or string.find(lname, s) then return true end
                end
            end
        end
    end

    return false
end

-- Cached Spellbook lookup table to eliminate scanning overhead
ns.learnedSpellCache = nil

function ns.BuildSpellbookCache()
    ns.learnedSpellCache = {}
    
    if IsSpellKnown then
        -- Fast lookup fallback
    end

    local numSpells = 0
    if C_SpellBook and C_SpellBook.GetNumSpellBookItems then
        numSpells = C_SpellBook.GetNumSpellBookItems()
    elseif GetNumSpellTabs then
        for i = 1, GetNumSpellTabs() do
            local _, _, offset, numEntries = GetSpellTabInfo(i)
            numSpells = numSpells + (numEntries or 0)
        end
    end

    if numSpells > 0 then
        for i = 1, numSpells do
            local name
            if C_SpellBook and C_SpellBook.GetSpellBookItemName then
                name = C_SpellBook.GetSpellBookItemName(i, Enum.SpellBookSpellBank.Player)
            elseif GetSpellBookItemName then
                name = GetSpellBookItemName(i, "player") or GetSpellBookItemName(i, BOOKTYPE_SPELL)
            end
            if name then
                ns.learnedSpellCache[name] = true
            end
        end
    end
end

-- Check if player has learned spell in spellbook (O(1) cached lookup)
function ns.IsSpellLearnedInSpellbook(spellName)
    if not spellName then return false end
    if not ns.learnedSpellCache then
        ns.BuildSpellbookCache()
    end
    if ns.learnedSpellCache[spellName] then return true end

    -- Check partial match fallback
    for name in pairs(ns.learnedSpellCache) do
        if string.find(name, spellName) then
            return true
        end
    end

    if IsSpellKnown then
        local spellID = (C_Spell and C_Spell.GetSpellIDForSpellIdentifier) and C_Spell.GetSpellIDForSpellIdentifier(spellName)
        if spellID and IsSpellKnown(spellID) then
            ns.learnedSpellCache[spellName] = true
            return true
        end
    end

    local name = GetSpellInfo and GetSpellInfo(spellName)
    if name then
        ns.learnedSpellCache[spellName] = true
        return true
    end

    return false
end

function ns.UpdateHUD()
    if not ns.isLoaded or not WOWForeverAddonDB then return end
    
    -- ALWAYS hide Buff & Pet Reminder HUD completely in combat
    if InCombatLockdown and InCombatLockdown() then
        if hudFrame then hudFrame:Hide() end
        return
    end

    local disabledBuffs = WOWForeverAddonDB.DisabledBuffs or {}

    local _, playerClass = UnitClass("player")
    local classConfig = ns.CLASS_SPELL_CONFIG[playerClass]

    local missingSpells = {}

    -- Check Pet Missing
    if WOWForeverAddonDB.PetReminder and classConfig and classConfig.pet then
        if not disabledBuffs[classConfig.pet] then
            if ns.IsSpellLearnedInSpellbook(classConfig.pet) or (classConfig.petAlt and ns.IsSpellLearnedInSpellbook(classConfig.petAlt)) then
                if not UnitExists("pet") or UnitIsDead("pet") then
                    table.insert(missingSpells, {
                        name = "NO PET",
                        spell = classConfig.pet,
                        texture = classConfig.petIcon or ns.GetSpellIconTexture(classConfig.pet),
                        isPet = true
                    })
                end
            end
        end
    end

    -- Check Class Buffs Missing
    if WOWForeverAddonDB.BuffReminder and classConfig and classConfig.buffs then
        for _, bEntry in ipairs(classConfig.buffs) do
            if not disabledBuffs[bEntry.spell] then
                if ns.IsSpellLearnedInSpellbook(bEntry.spell) then
                    if not ns.CheckPlayerHasBuff(bEntry.spell, bEntry.altSpells) then
                        table.insert(missingSpells, {
                            name = "MISSING",
                            spell = bEntry.spell,
                            texture = bEntry.texture or ns.GetSpellIconTexture(bEntry.spell),
                            isPet = false
                        })
                    end
                end
            end
        end
    end

    -- Check Rogue Poison Missing
    if WOWForeverAddonDB.BuffReminder and playerClass == "ROGUE" then
        if not disabledBuffs["Deadly Poison"] then
            if ns.IsSpellLearnedInSpellbook("Deadly Poison") or ns.IsSpellLearnedInSpellbook("Instant Poison") then
                local hasMH, _, _, _, hasOH = GetWeaponEnchantInfo()
                if not hasMH then
                    table.insert(missingSpells, {
                        name = "NO POISON",
                        spell = ns.IsSpellLearnedInSpellbook("Deadly Poison") and "Deadly Poison" or "Instant Poison",
                        texture = "Interface\\Icons\\Ability_PoisonousStab",
                        isPet = false
                    })
                end
            end
        end
    end

    if #missingSpells == 0 then
        if hudFrame then hudFrame:Hide() end
        return
    end

    if not hudFrame then
        hudFrame = CreateFrame("Frame", "WOWForeverReminderHUDFrame", UIParent, ns.backdropTemplate)
        hudFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
        hudFrame:SetMovable(true)
        hudFrame:EnableMouse(true)
        hudFrame:RegisterForDrag("LeftButton")
        hudFrame:SetScript("OnDragStart", hudFrame.StartMoving)
        hudFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            WOWForeverAddonDB.HUDPosition = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        end)
        hudFrame:SetFrameStrata("MEDIUM")

        if WOWForeverAddonDB.HUDPosition then
            local pos = WOWForeverAddonDB.HUDPosition
            hudFrame:ClearAllPoints()
            hudFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        end

        ns.ApplyModernBackdrop(hudFrame, 0.05, 0.03, 0.08, 0.92, 0.5, 0.2, 0.8, 0.9)

        local hudTitle = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hudTitle:SetPoint("TOP", hudFrame, "TOP", 0, -5)
        hudTitle:SetText("|cffc866ffBUFF & PET REMINDER|r")
    end

    local btnSize = 44
    local btnPadding = 12
    local totalWidth = math.max(220, #missingSpells * (btnSize + btnPadding) + 24)
    hudFrame:SetSize(totalWidth, 76)
    hudFrame:Show()

    for _, btn in ipairs(hudButtons) do
        btn:Hide()
    end

    for i, item in ipairs(missingSpells) do
        local btn = hudButtons[i]
        if not btn then
            btn = CreateFrame("Button", "WOWForeverHUDBtn_"..i, hudFrame, "SecureActionButtonTemplate, BackdropTemplate")
            btn:SetSize(btnSize, btnSize)

            ns.ApplyModernBackdrop(btn, 0.08, 0.04, 0.12, 0.95, 0.65, 0.25, 0.9, 1)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
            icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.icon = icon

            -- Embedded badge overlay container
            local badgeOverlay = CreateFrame("Frame", nil, btn, ns.backdropTemplate)
            badgeOverlay:SetHeight(14)
            badgeOverlay:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 2)
            badgeOverlay:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
            ns.ApplyModernBackdrop(badgeOverlay, 0.0, 0.0, 0.0, 0.85, 0.0, 0.0, 0.0, 0.0)

            local badge = badgeOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            badge:SetPoint("CENTER", badgeOverlay, "CENTER", 0, 0)
            btn.badge = badge
            btn.badgeOverlay = badgeOverlay

            table.insert(hudButtons, btn)
        end

        btn:SetPoint("LEFT", hudFrame, "LEFT", 12 + (i - 1) * (btnSize + btnPadding), -8)
        btn.icon:SetTexture(item.texture)
        btn.spellName = item.spell

        if item.isPet then
            btn.badge:SetText("|cffff3355NO PET|r")
            ns.ApplyModernBackdrop(btn, 0.18, 0.05, 0.12, 0.95, 0.9, 0.15, 0.35, 1)
        else
            btn.badge:SetText("|cffda99ffMISSING|r")
            ns.ApplyModernBackdrop(btn, 0.12, 0.05, 0.2, 0.95, 0.75, 0.3, 0.95, 1)
        end

        -- Spell casting binding
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", item.spell)

        -- Interactive GameTooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(item.spell, 0.8, 0.4, 1.0)
            if item.isPet then
                GameTooltip:AddLine("Click to summon your class pet.", 0.8, 0.8, 0.8, true)
            else
                GameTooltip:AddLine("Click to cast missing buff.", 0.8, 0.8, 0.8, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        btn:Show()
    end
end

-- Global alias for backward compatibility
WOWForeverUpdateHUD = ns.UpdateHUD
