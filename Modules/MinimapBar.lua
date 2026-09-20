-- Modules/MinimapBar.lua: Addon Minimap Collector Bar (Dynamic Flex Size & Edge Slide)
-- Author: Antigravity

local ADDON_NAME, ns = ...

-- Excluded Core Minimap Frames (Strictly filter out Blizzard native UI elements)
ns.EXCLUDED_MINIMAP_FRAMES = {
    MinimapZoneTextButton = true,
    MinimapZoneText = true,
    MinimapZoomIn = true,
    MinimapZoomOut = true,
    MiniMapTrackingButton = true,
    MiniMapTracking = true,
    MiniMapWorldMapButton = true,
    GameTimeFrame = true,
    TimeManagerClockButton = true,
    MiniMapMailFrame = true,
    MinimapBackdrop = true,
    MinimapCompassTexture = true,
    MiniMapInstanceDifficulty = true,
    GuildInstanceDifficulty = true,
    MiniMapChallengeMode = true,
    QueueStatusMinimapButton = true,
    GarrisonLandingPageMinimapButton = true,
    ExpansionLandingPageMinimapButton = true,
    MinimapCluster = true,
    Minimap = true,
    SubZoneTextFrame = true,
    WOWForeverReminderHUDFrame = true,
    WOWForeverMinimapBarFrame = true,
}

local minimapBarFrame = nil
local trackedMinimapButtons = {}

-- Create custom Minimap Icon for WOWForeverAddon
function ns.CreateAddonMinimapButton()
    if _G["WOWForeverMinimapButton"] then return _G["WOWForeverMinimapButton"] end

    local btn = CreateFrame("Button", "WOWForeverMinimapButton", UIParent, ns.backdropTemplate)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)

    ns.ApplyModernBackdrop(btn, 0.08, 0.04, 0.12, 0.95, 0.65, 0.25, 0.9, 1)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    btn:SetScript("OnClick", function()
        if ns.ToggleOptionsGUI then ns.ToggleOptionsGUI() end
    end)

    btn:SetScript("OnEnter", function(self)
        local verStr = (C_AddOns and C_AddOns.GetAddOnMetadata) and C_AddOns.GetAddOnMetadata("YAQoL", "Version") or (GetAddOnMetadata and GetAddOnMetadata("YAQoL", "Version")) or "2.0.13"
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffc866ffYAQoL|r  |cff00ffccv" .. tostring(verStr) .. "|r", 0.8, 0.4, 1.0)
        GameTooltip:AddLine("Click to open Interface Control Panel", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    trackedMinimapButtons[btn] = true
    return btn
end

-- Helper: Check if a frame is a native Blizzard core minimap element
function ns.IsBlizzardNativeMinimapFrame(child)
    if not child or not child.GetName then return true end
    local name = child:GetName()
    if not name then return true end

    if ns.EXCLUDED_MINIMAP_FRAMES[name] then return true end

    if string.find(name, "MinimapZone") or string.find(name, "SubZone") or string.find(name, "ZoneText")
       or string.find(name, "MinimapZoom") or string.find(name, "MiniMapTracking") or string.find(name, "MiniMapMail")
       or string.find(name, "MiniMapWorldMap") or string.find(name, "GameTime") or string.find(name, "TimeManager")
       or string.find(name, "InstanceDifficulty") or string.find(name, "ChallengeMode") or string.find(name, "QueueStatus")
       or string.find(name, "GarrisonLanding") or string.find(name, "ExpansionLanding") or string.find(name, "Compass") then
        return true
    end

    return false
end

function ns.ScanMinimapButtons()
    local buttons = {}
    local addedMap = {}

    local ownBtn = ns.CreateAddonMinimapButton()
    if ownBtn then
        addedMap[ownBtn] = true
        table.insert(buttons, ownBtn)
    end

    local function TryAddButton(child)
        if ns.IsBlizzardNativeMinimapFrame(child) then return end
        if addedMap[child] then return end

        local name = child.GetName and child:GetName()
        if name then
            if string.find(name, "LibDBIcon") or string.find(name, "MinimapButton") or string.find(name, "MinimapBtn") then
                addedMap[child] = true
                trackedMinimapButtons[child] = true
                table.insert(buttons, child)
            end
        elseif child.IsObjectType and child:IsObjectType("Button") then
            if child ~= Minimap and child ~= MinimapCluster then
                addedMap[child] = true
                trackedMinimapButtons[child] = true
                table.insert(buttons, child)
            end
        end
    end

    -- 1. Check already tracked buttons
    for btn, _ in pairs(trackedMinimapButtons) do
        if btn and btn.IsShown and not ns.IsBlizzardNativeMinimapFrame(btn) then
            if not addedMap[btn] then
                addedMap[btn] = true
                table.insert(buttons, btn)
            end
        end
    end

    -- 2. Query LibDBIcon library button list directly if available
    local libDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if libDBIcon and libDBIcon.GetButtonList then
        for _, iconName in ipairs(libDBIcon:GetButtonList()) do
            local b = libDBIcon:GetMinimapButton(iconName)
            if b and not addedMap[b] then
                addedMap[b] = true
                trackedMinimapButtons[b] = true
                table.insert(buttons, b)
            end
        end
    end

    -- 3. Scan Minimap children (lightweight pass)
    if Minimap then
        for _, child in ipairs({ Minimap:GetChildren() }) do TryAddButton(child) end
    end

    return buttons
end

local function OnMinimapBarUpdate(self, elapsed)
    local db = ns.db or _G["YAQoLDB"] or _G["WOWForeverAddonDB"]
    if not ns.isLoaded or not db then return end

    local isMouseoverMode = db.MinimapBarMouseover
    local isHorizontal = (db.MinimapBarOrientation or "HORIZONTAL") == "HORIZONTAL"
    local rawOver = (MouseIsOver and MouseIsOver(self)) or (self.IsMouseOver and self:IsMouseOver())

    -- Check children hover state
    if not rawOver and self.currentButtons then
        for _, btn in ipairs(self.currentButtons) do
            if btn and btn:IsShown() and ((MouseIsOver and MouseIsOver(btn)) or (btn.IsMouseOver and btn:IsMouseOver())) then
                rawOver = true
                break
            end
        end
    end

    -- Hysteresis Grace Period (0.35s delay before closing to prevent edge flickering)
    if rawOver then
        self.leaveTimer = 0.35
    else
        self.leaveTimer = math.max(0, (self.leaveTimer or 0) - elapsed)
    end
    local isOver = rawOver or (self.leaveTimer > 0)

    local btnSize = 32
    local padding = 6
    local numBtns = self.currentButtons and #self.currentButtons or 0

    local fullW, fullH
    if numBtns == 0 then
        fullW = 140
        fullH = 36
    else
        if isHorizontal then
            fullW = numBtns * (btnSize + padding) + 6
            fullH = btnSize + 14
            if self.handleLine then self.handleLine:SetSize(math.max(16, fullW - 12), 3) end
        else
            fullW = btnSize + 14
            fullH = numBtns * (btnSize + padding) + 6
            if self.handleLine then self.handleLine:SetSize(3, math.max(16, fullH - 12)) end
        end
    end

    local targetW, targetH
    if isMouseoverMode and not isOver then
        if isHorizontal then targetW = fullW; targetH = 14
        else targetW = 14; targetH = fullH end
    else
        targetW = fullW
        targetH = fullH
    end

    local curW = self:GetWidth() or targetW
    local curH = self:GetHeight() or targetH

    local speed = elapsed * 14
    local newW = curW + (targetW - curW) * speed
    local newH = curH + (targetH - curH) * speed

    local isSettled = false
    if math.abs(newW - targetW) < 0.5 and math.abs(newH - targetH) < 0.5 then
        newW = targetW
        newH = targetH
        if self.leaveTimer <= 0 or (rawOver and newW == targetW and newH == targetH) then
            isSettled = true
        end
    end

    self:SetSize(newW, newH)

    local isExpanded = (isHorizontal and newH > 22) or (not isHorizontal and newW > 22)
    self.isExpanded = isExpanded

    if isMouseoverMode then
        if self.currentButtons then
            for _, btn in ipairs(self.currentButtons) do
                if isExpanded then btn:Show() else btn:Hide() end
            end
        end
        if isExpanded then self.handleLine:Hide() else self.handleLine:Show() end
    else
        if self.currentButtons then
            for _, btn in ipairs(self.currentButtons) do btn:Show() end
        end
        self.handleLine:Hide()
    end

    -- Put OnUpdate to sleep once settled to achieve 0% idle CPU
    if isSettled and not rawOver then
        self:SetScript("OnUpdate", nil)
        self.isAnimating = false
    end
end

local function WakeupMinimapBarTicker()
    if minimapBarFrame and not minimapBarFrame.isAnimating then
        minimapBarFrame.isAnimating = true
        minimapBarFrame:SetScript("OnUpdate", OnMinimapBarUpdate)
    end
end

function ns.UpdateMinimapBar()
    local db = ns.db or _G["YAQoLDB"] or _G["WOWForeverAddonDB"]
    if not ns.isLoaded or not db or not db.MinimapBarEnabled then
        if minimapBarFrame then minimapBarFrame:Hide() end
        return
    end

    local buttons = ns.ScanMinimapButtons()

    if not minimapBarFrame then
        minimapBarFrame = CreateFrame("Frame", "WOWForeverMinimapBarFrame", UIParent, ns.backdropTemplate)
        minimapBarFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -300)
        minimapBarFrame:SetMovable(true)
        minimapBarFrame:EnableMouse(true)
        minimapBarFrame:RegisterForDrag("LeftButton")
        minimapBarFrame:SetScript("OnDragStart", minimapBarFrame.StartMoving)
        minimapBarFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            local activeDB = ns.db or _G["YAQoLDB"] or _G["WOWForeverAddonDB"]

            if activeDB and activeDB.MinimapBarSnapToEdge ~= false then
                local screenWidth = UIParent:GetWidth()
                local screenHeight = UIParent:GetHeight()
                local frameLeft = self:GetLeft()
                local frameRight = self:GetRight()
                local frameTop = self:GetTop()
                local frameBottom = self:GetBottom()
                local frameCenterX, frameCenterY = self:GetCenter()

                if frameLeft and frameRight and frameTop and frameBottom and frameCenterX and frameCenterY and screenWidth and screenHeight then
                    local snapThreshold = 25
                    local newPoint = point
                    local newRelPoint = relativePoint
                    local newX = xOfs
                    local newY = yOfs
                    local snappedX = false
                    local snappedY = false

                    if frameLeft < snapThreshold then
                        newPoint = "LEFT"
                        newRelPoint = "LEFT"
                        newX = 0
                        newY = frameCenterY - (screenHeight / 2)
                        snappedX = true
                    elseif (screenWidth - frameRight) < snapThreshold then
                        newPoint = "RIGHT"
                        newRelPoint = "RIGHT"
                        newX = 0
                        newY = frameCenterY - (screenHeight / 2)
                        snappedX = true
                    end

                    if (screenHeight - frameTop) < snapThreshold then
                        if snappedX then
                            newPoint = (newRelPoint == "LEFT") and "TOPLEFT" or "TOPRIGHT"
                            newRelPoint = newPoint
                            newX = 0
                            newY = 0
                        else
                            newPoint = "TOP"
                            newRelPoint = "TOP"
                            newX = frameCenterX - (screenWidth / 2)
                            newY = 0
                        end
                        snappedY = true
                    elseif frameBottom < snapThreshold then
                        if snappedX then
                            newPoint = (newRelPoint == "LEFT") and "BOTTOMLEFT" or "BOTTOMRIGHT"
                            newRelPoint = newPoint
                            newX = 0
                            newY = 0
                        else
                            newPoint = "BOTTOM"
                            newRelPoint = "BOTTOM"
                            newX = frameCenterX - (screenWidth / 2)
                            newY = 0
                        end
                        snappedY = true
                    end

                    if snappedX or snappedY then
                        self:ClearAllPoints()
                        self:SetPoint(newPoint, UIParent, newRelPoint, newX, newY)
                        point, relativePoint, xOfs, yOfs = newPoint, newRelPoint, newX, newY
                    end
                end
            end

            if activeDB then
                activeDB.MinimapBarPosition = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
            end
        end)
        minimapBarFrame:SetFrameStrata("MEDIUM")

        if db and db.MinimapBarPosition then
            local pos = db.MinimapBarPosition
            minimapBarFrame:ClearAllPoints()
            minimapBarFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        end

        ns.ApplyModernBackdrop(minimapBarFrame, 0.05, 0.03, 0.08, 0.95, 0.55, 0.2, 0.85, 0.9)

        local handleLine = minimapBarFrame:CreateTexture(nil, "OVERLAY")
        handleLine:SetPoint("CENTER", minimapBarFrame, "CENTER", 0, 0)
        handleLine:SetColorTexture(0.75, 0.3, 1.0, 0.9)
        minimapBarFrame.handleLine = handleLine

        minimapBarFrame.leaveTimer = 0
        minimapBarFrame:HookScript("OnEnter", WakeupMinimapBarTicker)
        minimapBarFrame:HookScript("OnLeave", WakeupMinimapBarTicker)
    end

    minimapBarFrame.currentButtons = buttons
    local isHorizontal = (WOWForeverAddonDB.MinimapBarOrientation or "HORIZONTAL") == "HORIZONTAL"
    local btnSize = 32
    local padding = 6

    if #buttons == 0 then
        if not minimapBarFrame.placeholderText then
            local phText = minimapBarFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            phText:SetPoint("CENTER", minimapBarFrame, "CENTER", 0, 0)
            phText:SetText("|cffa388cc[Minimap Bar]|r")
            minimapBarFrame.placeholderText = phText
        end
        minimapBarFrame.placeholderText:Show()
    else
        if minimapBarFrame.placeholderText then minimapBarFrame.placeholderText:Hide() end

        local isMouseoverMode = WOWForeverAddonDB.MinimapBarMouseover
        local isExpanded = minimapBarFrame.isExpanded ~= false

        for i, btn in ipairs(buttons) do
            btn:SetParent(minimapBarFrame)
            btn:ClearAllPoints()
            btn:SetSize(btnSize, btnSize)
            if isHorizontal then
                btn:SetPoint("LEFT", minimapBarFrame, "LEFT", 6 + (i - 1) * (btnSize + padding), 0)
            else
                btn:SetPoint("TOP", minimapBarFrame, "TOP", 0, -6 - (i - 1) * (btnSize + padding))
            end
            if isMouseoverMode and not isExpanded then
                btn:Hide()
            else
                btn:Show()
            end
            if not btn.yaqolHooked then
                btn.yaqolHooked = true
                btn:HookScript("OnEnter", WakeupMinimapBarTicker)
                btn:HookScript("OnLeave", WakeupMinimapBarTicker)
            end
        end
    end

    WakeupMinimapBarTicker()
    minimapBarFrame:Show()
end

-- Global alias for backward compatibility
WOWForeverUpdateMinimapBar = ns.UpdateMinimapBar
