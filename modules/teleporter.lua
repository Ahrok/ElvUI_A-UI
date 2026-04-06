local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

-- =====================================================================
-- 1. DATENBANK (Kategorien & Items)
-- =====================================================================
local TeleportList = {
    {
        name = L["Hearthstones"] or "Ruhesteine",
        icon = "Interface\\Icons\\INV_Misc_Rune_01",
        items = {
            { id = 6948, type = "item" },    -- Klassischer Ruhestein
            { id = 140192, type = "toy" },   -- Dalaranruhestein
            { id = 110560, type = "toy" },   -- Garnisonsruhestein
            { id = 163045, type = "toy" },   -- Ruhestein des kopflosen Reiters
            { id = 162973, type = "toy" },   -- Ruhestein von Altvater Winter
            { id = 193588, type = "toy" },   -- Ruhestein der Zeitwanderer
            { id = 188952, type = "toy" },   -- Dominierter Ruhestein
            { id = 212337, type = "toy" },   -- Stein des Herds
            { id = 142542, type = "toy" },   -- Foliant des Stadtportals
            { id = 209035, type = "toy" },   -- Ruhestein der Flamme
            { id = 245970, type = "toy" },   -- Expressruhestein des P.O.S.T.-Meisters
            { id = 208704, type = "toy" },   -- Irdener Ruherstein des Tiefenbewohners
            { id = 172179, type = "toy" },   -- Ruhestein des Ewigen Reisenden
            { id = 210455, type = "toy", races = {"Draenei", "LightforgedDraenei"} },   -- Draenischer Holostein (NUR DRAENEI)
            { id = 183716, type = "toy" },   -- Venthyrsündenstein
        }
    },
    {
        name = L["Toys"] or "Spielzeuge",
        icon = "Interface\\Icons\\Trade_Engineering",
        items = {
            { id = 65274, type = "item" },   -- Umhang der Koordination (Gilde)
            { id = 198156, type = "toy" },   -- Wurmlochgenerator: Dracheninseln
            { id = 172924, type = "toy" },   -- Wurmlochgenerator: Schattenlande
            { id = 151652, type = "toy" },   -- Wurmlochgenerator: Argus
            { id = 112059, type = "toy" },   -- Wurmlochzentrifuge (Draenor)
            { id = 87215, type = "toy" },    -- Wurmlochgenerator: Pandaria
            { id = 48933, type = "item" },   -- Wurmlochgenerator: Nordend
            { id = 30542, type = "item" },   -- Dimensionszerfetzer: Area 52
            { id = 18986, type = "item" },   -- Ultrasiherer Transporter: Everlook
            { id = 253629, type = "toy" },   -- Persönlicher Schlüssel zur Arkantine
        }
    },
    {
        name = L["Racial Abilities"] or "Völkerfähigkeiten",
        icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
        items = {
            { id = 1238686, type = "spell" }, -- Wurzelwandeln (Haranir)
            { id = 1238695, type = "spell" }, -- Wurzelwandeln: Rückkehr (Haranir)
            { id = 312372, type = "spell" },  -- Rückkehr ins Camp (Vulpera)
            { id = 265225, type = "spell" },  -- Maulwurfmaschine (Dunkleisenzwerg)
        }
    },
    {
        name = L["Death Knight"] or "Todesritter",
        icon = "Interface\\Icons\\ClassIcon_DeathKnight",
        class = "DEATHKNIGHT",
        items = {
            { id = 50977, type = "spell" },  -- Schwarzes Tor
        }
    },
    {
        name = L["Druid"] or "Druide",
        icon = "Interface\\Icons\\ClassIcon_Druid",
        class = "DRUID",
        items = {
            { id = 18960, type = "spell" },  -- Teleportation: Mondlichtung
            { id = 193753, type = "spell" }, -- Traumwandeln
        }
    },
    {
        name = L["Monk"] or "Mönch",
        icon = "Interface\\Icons\\ClassIcon_Monk",
        class = "MONK",
        items = {
            { id = 126892, type = "spell" }, -- Zenpilgerfahrt
        }
    },
    {
        name = L["Shaman"] or "Schamane",
        icon = "Interface\\Icons\\ClassIcon_Shaman",
        class = "SHAMAN",
        items = {
            { id = 556, type = "spell" },    -- Astraler Rückruf
        }
    },
    {
        name = L["Mage Teleports"] or "Magier Teleporte",
        icon = "Interface\\Icons\\Spell_Arcane_TeleportDalaran",
        class = "MAGE",
        items = {
            { id = 3561, type = "spell" },  -- SW
            { id = 3562, type = "spell" },  -- IF
            { id = 3565, type = "spell" },  -- Darnassus
            { id = 32271, type = "spell" }, -- Exodar
            { id = 3567, type = "spell" },  -- Org
            { id = 3563, type = "spell" },  -- UC
            { id = 3566, type = "spell" },  -- TB
            { id = 32272, type = "spell" }, -- Silbermond
            { id = 53140, type = "spell" }, -- Dalaran (Nordend)
            { id = 120145, type = "spell" },-- Tal der Ewigen Blüten
            { id = 193759, type = "spell" },-- Halle des Wächters
            { id = 224869, type = "spell" },-- Dalaran (Legion)
            { id = 281404, type = "spell" },-- Boralus
            { id = 281403, type = "spell" },-- Dazar'alor
            { id = 344587, type = "spell" },-- Oribos
            { id = 390885, type = "spell" },-- Valdrakken
            { id = 446540, type = "spell" },-- Dornogal
        }
    },
    {
        name = L["Mage Portals"] or "Magier Portale",
        icon = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
        class = "MAGE",
        items = {
            { id = 10059, type = "spell" }, -- SW
            { id = 11416, type = "spell" }, -- IF
            { id = 11419, type = "spell" }, -- Darnassus
            { id = 32266, type = "spell" }, -- Exodar
            { id = 11417, type = "spell" }, -- Org
            { id = 11418, type = "spell" }, -- UC
            { id = 11420, type = "spell" }, -- TB
            { id = 32267, type = "spell" }, -- Silbermond
            { id = 53142, type = "spell" }, -- Dalaran (Nordend)
            { id = 120146, type = "spell" },-- Tal der Ewigen Blüten
            { id = 224871, type = "spell" },-- Dalaran (Legion)
            { id = 281400, type = "spell" },-- Boralus
            { id = 281402, type = "spell" },-- Dazar'alor
            { id = 344588, type = "spell" },-- Oribos
            { id = 390886, type = "spell" },-- Valdrakken
            { id = 446534, type = "spell" },-- Dornogal
        }
    }
}

-- =====================================================================
-- 2. ITEM CACHE, SCANNER & COOLDOWNS
-- =====================================================================
local function SafeGetSpellInfo(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID), C_Spell.GetSpellTexture(spellID)
    elseif GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellID)
        return name, icon
    end
    return nil, nil
end

local function GetSafeName(id, itemType)
    local name, icon
    if itemType == "toy" then
        name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id)
        if not name then
            local _, tName, tIcon = C_ToyBox.GetToyInfo(id)
            name, icon = tName, tIcon
        end
    elseif itemType == "item" then
        name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id)
    elseif itemType == "spell" then
        name, icon = SafeGetSpellInfo(id)
    end

    if not name and (itemType == "toy" or itemType == "item") then
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(id)
        end
    end

    return name, icon
end

-- Holt die Abklingzeit sicher ab (wird im Menü und im Tooltip verwendet)
local function GetSafeCooldown(id, itemType)
    local start, duration = 0, 0
    if itemType == "toy" or itemType == "item" then
        if C_Item and C_Item.GetItemCooldown then
            start, duration = C_Item.GetItemCooldown(id)
        elseif GetItemCooldown then
            start, duration = GetItemCooldown(id)
        end
    elseif itemType == "spell" then
        if C_Spell and C_Spell.GetSpellCooldown then
            local info = C_Spell.GetSpellCooldown(id)
            if info then start, duration = info.startTime, info.duration end
        elseif GetSpellCooldown then
            start, duration = GetSpellCooldown(id)
        end
    end
    return start, duration
end

local function ScanTeleports()
    local available = {}
    local _, playerRace = UnitRace("player") -- Holt das Volk für den Völker-Filter
    
    for _, category in ipairs(TeleportList) do
        if not category.class or category.class == E.myclass then
            local catData = { name = category.name, icon = category.icon, buttons = {} }
            for _, itemData in ipairs(category.items) do
                local id = itemData.id
                
                -- VÖLKER CHECK
                local isRaceAllowed = true
                if itemData.races then
                    isRaceAllowed = false
                    for _, allowedRace in ipairs(itemData.races) do
                        if allowedRace == playerRace then 
                            isRaceAllowed = true 
                            break 
                        end
                    end
                end
                
                if isRaceAllowed then
                    if itemData.type == "toy" and PlayerHasToy(id) and C_ToyBox.IsToyUsable(id) then
                        local name, icon = GetSafeName(id, "toy")
                        if name then table.insert(catData.buttons, { type = "toy", id = id, name = name, icon = icon }) end
                    elseif itemData.type == "item" and GetItemCount(id) > 0 then
                        local name, icon = GetSafeName(id, "item")
                        if name then table.insert(catData.buttons, { type = "item", id = id, name = name, icon = icon }) end
                    elseif itemData.type == "spell" and IsSpellKnown(id) then
                        local name, icon = GetSafeName(id, "spell")
                        if name then table.insert(catData.buttons, { type = "spell", id = id, name = name, icon = icon }) end
                    end
                end
            end
            if #catData.buttons > 0 then
                table.insert(available, catData)
            end
        end
    end
    return available
end

-- =====================================================================
-- 3. KASKADEN-MENÜ (MIT FRAME-POOLING GEGEN LAGS)
-- =====================================================================
local menuFrame = nil
local hideTimer = nil

local function HideMenu()
    if InCombatLockdown() then return end
    if menuFrame then
        menuFrame:Hide()
        for _, sm in ipairs(menuFrame.subPool) do sm:Hide() end
    end
end

local function CancelHideTimer()
    if hideTimer then hideTimer:Cancel(); hideTimer = nil end
end

local function CheckMouseLeave()
    CancelHideTimer()
    hideTimer = C_Timer.NewTicker(0.2, function()
        if not menuFrame then return end
        local isOverAny = menuFrame:IsMouseOver()
        for _, sm in ipairs(menuFrame.subPool) do
            if sm:IsShown() and sm:IsMouseOver() then isOverAny = true end
        end
        if not isOverAny then HideMenu(); CancelHideTimer() end
    end)
end

function AUI:UpdateTeleportMenu()
    if not menuFrame then
        menuFrame = CreateFrame("Frame", "AUI_TeleportMenuFrame", E.UIParent, "BackdropTemplate")
        menuFrame:SetTemplate("Transparent")
        menuFrame:SetFrameStrata("DIALOG")
        menuFrame:Hide()
        
        menuFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        menuFrame:SetScript("OnEvent", function(self) HideMenu() end)
        menuFrame:SetScript("OnEnter", function() CancelHideTimer() end)
        menuFrame:SetScript("OnLeave", function() CheckMouseLeave() end)
        
        menuFrame.catPool = {}
        menuFrame.subPool = {}
        menuFrame.btnPool = {}
        
        menuFrame.emptyText = menuFrame:CreateFontString(nil, "OVERLAY")
        menuFrame.emptyText:FontTemplate(nil, 12, "NONE")
        menuFrame.emptyText:SetPoint("TOP", menuFrame, "TOP", 0, -10)
        menuFrame.emptyText:SetText(L["No items found."] or "Keine Items gefunden.")
        menuFrame.emptyText:Hide()
    end

    local availableCats = ScanTeleports()
    local catWidth, subWidth = 160, 240
    local yOffset = -5
    
    for _, f in ipairs(menuFrame.catPool) do f:Hide() end
    for _, f in ipairs(menuFrame.subPool) do f:Hide() end
    for _, f in ipairs(menuFrame.btnPool) do f:Hide() end
    menuFrame.emptyText:Hide()

    local catIndex = 0
    local btnIndex = 0

    for _, category in ipairs(availableCats) do
        catIndex = catIndex + 1
        
        -- KATEGORIE BUTTON HOLEN ODER ERSTELLEN
        local catBtn = menuFrame.catPool[catIndex]
        if not catBtn then
            catBtn = CreateFrame("Button", nil, menuFrame, "BackdropTemplate")
            catBtn:SetTemplate("Default")
            
            catBtn.icon = catBtn:CreateTexture(nil, "ARTWORK")
            catBtn.icon:SetSize(18, 18)
            catBtn.icon:SetPoint("LEFT", catBtn, "LEFT", 4, 0)
            catBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            
            catBtn.text = catBtn:CreateFontString(nil, "OVERLAY")
            catBtn.text:FontTemplate(nil, 12, "NONE")
            catBtn.text:SetPoint("LEFT", catBtn.icon, "RIGHT", 6, 0)
            
            catBtn.arrow = catBtn:CreateFontString(nil, "OVERLAY")
            catBtn.arrow:FontTemplate(nil, 12, "NONE")
            catBtn.arrow:SetPoint("RIGHT", catBtn, "RIGHT", -6, 0)
            catBtn.arrow:SetText(">")
            
            menuFrame.catPool[catIndex] = catBtn
        end
        
        catBtn:ClearAllPoints()
        catBtn:SetSize(catWidth - 10, 26)
        catBtn:SetPoint("TOP", menuFrame, "TOP", 0, yOffset)
        catBtn.icon:SetTexture(category.icon)
        catBtn.text:SetText("|cff00ffd2" .. category.name .. "|r")
        catBtn:Show()
        
        -- SUBMENU HOLEN ODER ERSTELLEN
        local subMenu = menuFrame.subPool[catIndex]
        if not subMenu then
            subMenu = CreateFrame("Frame", nil, menuFrame, "BackdropTemplate")
            subMenu:SetTemplate("Transparent")
            subMenu:SetScript("OnEnter", function() CancelHideTimer() end)
            subMenu:SetScript("OnLeave", function() CheckMouseLeave() end)
            menuFrame.subPool[catIndex] = subMenu
        end
        
        subMenu:Hide() 
        subMenu:ClearAllPoints()
        
        -- NEUER ANKERPUNKT: Oben bündig mit der Kategorie + Automatischer Screen-Clamp!
        subMenu:SetPoint("TOPLEFT", catBtn, "TOPRIGHT", 2, 0)
        subMenu:SetClampedToScreen(true) 
        
        -- ITEMS INS SUBMENU
        local subY = -5
        for _, tp in ipairs(category.buttons) do
            btnIndex = btnIndex + 1
            local btn = menuFrame.btnPool[btnIndex]
            if not btn then
                btn = CreateFrame("Button", nil, menuFrame, "SecureActionButtonTemplate, BackdropTemplate")
                btn:SetTemplate("Default")
                btn:RegisterForClicks("AnyDown")
                
                btn:SetScript("PostClick", function() HideMenu() end)
                btn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor)); CancelHideTimer() end)
                btn:SetScript("OnLeave", function(self) self:SetTemplate("Default"); CheckMouseLeave() end)
                
                btn.icon = btn:CreateTexture(nil, "ARTWORK")
                btn.icon:SetSize(18, 18)
                btn.icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
                btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                
                btn.text = btn:CreateFontString(nil, "OVERLAY")
                btn.text:FontTemplate(nil, 12, "NONE")
                btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 6, 0)
                btn.text:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
                btn.text:SetJustifyH("LEFT")
                
                menuFrame.btnPool[btnIndex] = btn
            end
            
            if not InCombatLockdown() then
                btn:SetAttribute("type1", tp.type == "spell" and "spell" or "macro")
                btn:SetAttribute("spell1", tp.type == "spell" and tp.name or nil)
                btn:SetAttribute("macrotext1", tp.type ~= "spell" and ("/use " .. tp.name) or nil)
            end
            
            btn:SetParent(subMenu)
            btn:ClearAllPoints() 
            btn:SetSize(subWidth - 10, 24)
            btn:SetPoint("TOP", subMenu, "TOP", 0, subY)
            
            btn.icon:SetTexture(tp.icon)
            btn.text:SetText(tp.name)
            
            -- COOLDOWN GRAUFILTER
            local start, duration = GetSafeCooldown(tp.id, tp.type)
            if start and start > 0 and duration > 1.5 then
                btn.icon:SetDesaturated(true)
                btn.icon:SetVertexColor(0.5, 0.5, 0.5)
                btn.text:SetTextColor(0.5, 0.5, 0.5)
            else
                btn.icon:SetDesaturated(false)
                btn.icon:SetVertexColor(1, 1, 1)
                btn.text:SetTextColor(1, 1, 1)
            end
            
            btn:Show()
            
            subY = subY - 26
        end
        subMenu:SetSize(subWidth, math.abs(subY) + 5)
        
        catBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
            CancelHideTimer()
            for _, sm in ipairs(menuFrame.subPool) do sm:Hide() end
            subMenu:Show()
        end)
        catBtn:SetScript("OnLeave", function(self)
            self:SetTemplate("Default")
            CheckMouseLeave()
        end)
        
        yOffset = yOffset - 28
    end
    
    if #availableCats == 0 then
        menuFrame.emptyText:Show()
        yOffset = -30
    end

    menuFrame:SetSize(catWidth, math.abs(yOffset) + 5)
end

-- =====================================================================
-- 4. ÖFFNEN / SCHLIEßEN
-- =====================================================================
function AUI:ToggleTeleportMenu(parentButton)
    if InCombatLockdown() then return end
    
    if AUI_TeleportMenuFrame and AUI_TeleportMenuFrame:IsShown() then
        HideMenu()
    else
        AUI:UpdateTeleportMenu() 
        
        if GameTooltip:IsShown() then
            GameTooltip:Hide()
        end

        AUI_TeleportMenuFrame:ClearAllPoints()
        AUI_TeleportMenuFrame:SetPoint("BOTTOM", parentButton, "TOPRIGHT", 2, 0)
        AUI_TeleportMenuFrame:Show()
    end
end

-- =====================================================================
-- 5. SILENT PRE-CACHE BEIM LOGIN
-- =====================================================================
local preloadFrame = CreateFrame("Frame")
preloadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
preloadFrame:SetScript("OnEvent", function(self, event, isInitialLogin, isReloading)
    for _, category in ipairs(TeleportList) do
        for _, itemData in ipairs(category.items) do
            if itemData.type == "toy" or itemData.type == "item" then
                if C_Item and C_Item.RequestLoadItemDataByID then
                    C_Item.RequestLoadItemDataByID(itemData.id)
                end
                GetItemInfo(itemData.id) 
            end
        end
    end
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

-- =====================================================================
-- 6. TOOLTIP ERWEITERUNG (Heimatort & Abklingzeiten)
-- =====================================================================
local function FormatCooldown(seconds)
    if seconds >= 3600 then
        return string.format("%dh %02dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    elseif seconds >= 60 then
        return string.format("%dm %02ds", math.floor(seconds / 60), math.floor(seconds % 60))
    else
        return string.format("%ds", math.floor(seconds))
    end
end

if AUI.ShowMicroButtonTooltip then
    hooksecurefunc(AUI, "ShowMicroButtonTooltip", function(self, wrapper, btnName, data)
        if btnName == "AUI_TeleportButton" then
            
            -- Heimatort anzeigen
            local bindLoc = GetBindLocation()
            if bindLoc and bindLoc ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine((L["Bind Location"] or "Heimatort: "), 0, 1, 0.82)
                GameTooltip:AddLine(bindLoc, 1, 1, 1)
            end

            -- Abklingzeiten sammeln
            local cooldowns = {}
            local activeCDs = {} 
            local currentTime = GetTime()
            local _, playerRace = UnitRace("player") -- Völkercheck für den Tooltip

            for _, category in ipairs(TeleportList) do
                if not category.class or category.class == E.myclass then
                    for _, itemData in ipairs(category.items) do
                        
                        -- VÖLKER CHECK
                        local isRaceAllowed = true
                        if itemData.races then
                            isRaceAllowed = false
                            for _, allowedRace in ipairs(itemData.races) do
                                if allowedRace == playerRace then 
                                    isRaceAllowed = true 
                                    break 
                                end
                            end
                        end
                        
                        if isRaceAllowed then
                            local owns = false
                            if itemData.type == "toy" and PlayerHasToy(itemData.id) and C_ToyBox.IsToyUsable(itemData.id) then owns = true
                            elseif itemData.type == "item" and GetItemCount(itemData.id) > 0 then owns = true
                            elseif itemData.type == "spell" and IsSpellKnown(itemData.id) then owns = true end
                            
                            if owns then
                                local start, duration = GetSafeCooldown(itemData.id, itemData.type)
                                
                                if start and start > 0 and duration > 1.5 then
                                    local remaining = (start + duration) - currentTime
                                    if remaining > 0 then
                                        local name = GetSafeName(itemData.id, itemData.type)
                                        if name then
                                            local endTime = math.floor(start + duration)
                                            if not activeCDs[endTime] then
                                                activeCDs[endTime] = true
                                                table.insert(cooldowns, { name = name, remaining = remaining })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if #cooldowns > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine((L["Cooldowns"] or "Abklingzeiten:"), 1, 0.2, 0.2)
                
                table.sort(cooldowns, function(a, b) return a.remaining < b.remaining end)
                for _, cd in ipairs(cooldowns) do
                    GameTooltip:AddDoubleLine(cd.name, FormatCooldown(cd.remaining), 1, 1, 1, 1, 1, 1)
                end
            end

            GameTooltip:Show()
        end
    end)
end