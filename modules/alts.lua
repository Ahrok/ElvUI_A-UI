local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

local AltTracker = CreateFrame("Frame")

AUI.AltSortBy = "ilvl"
AUI.AltSortAsc = false

-- =====================================================================
-- 0. MIDNIGHT KONFIGURATION (Nur noch für den Itemlevel Stat-Squish!)
-- =====================================================================
local AUI_CONFIG = {
    -- Ab welchem Itemlevel soll der GS welche Farbe bekommen?
    IlvlEpic = 250,      -- Lila
    IlvlRare = 230,      -- Blau
    IlvlUncommon = 200   -- Grün
}

-- =====================================================================
-- 1. DYNAMISCHER WÄHRUNGSSCANNER
-- =====================================================================
local function GetDynamicCurrencyIDs()
    if AUI.CurrencyCache and AUI.CurrencyCache.Catalyst then return AUI.CurrencyCache end
    AUI.CurrencyCache = AUI.CurrencyCache or {}

    local function ParseCurrencyName(curID, name)
        local n = string.lower(name)
        if string.find(n, "restaurierter kastenschlüssel") or string.find(n, "restored coffer key") or string.find(n, "kastenschlüssel") then AUI.CurrencyCache.Key = curID
        elseif string.find(n, "morgenlichtwappen des veteranen") or string.find(n, "veteran's dawning crest") then AUI.CurrencyCache.CrestVet = curID
        elseif string.find(n, "morgenlichtwappen des champions") or string.find(n, "champion's dawning crest") then AUI.CurrencyCache.CrestChamp = curID
        elseif string.find(n, "morgenlichtwappen des helden") or string.find(n, "hero's dawning crest") then AUI.CurrencyCache.CrestHero = curID
        elseif (string.find(n, "myth") and string.find(n, "morgenlichtwappen")) or string.find(n, "mythic dawning crest") then AUI.CurrencyCache.CrestMyth = curID
        elseif string.find(n, "katalysator") or string.find(n, "catalyst") or string.find(n, "manaflux") then
            if not AUI.CurrencyCache.Catalyst or curID > AUI.CurrencyCache.Catalyst then
                AUI.CurrencyCache.Catalyst = curID
            end
        end
    end

    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize then
        local listSize = C_CurrencyInfo.GetCurrencyListSize()
        for i = 1, listSize do
            local link = C_CurrencyInfo.GetCurrencyListLink(i)
            if link then
                local curID = tonumber(string.match(link, "currency:(%d+)"))
                if curID then
                    local info = C_CurrencyInfo.GetCurrencyInfo(curID)
                    if info and info.name then ParseCurrencyName(curID, info.name) end
                end
            end
        end
    end

    if not AUI.CurrencyCache.CrestVet then
        for i = 2800, 3600 do
            local info = C_CurrencyInfo.GetCurrencyInfo(i)
            if info and info.name then ParseCurrencyName(i, info.name) end
        end
    end

    if not AUI.CurrencyCache.Key then AUI.CurrencyCache.Key = 3028 end
    if not AUI.CurrencyCache.Catalyst then AUI.CurrencyCache.Catalyst = 3116 end

    return AUI.CurrencyCache
end

-- =====================================================================
-- 2. HILFSFUNKTIONEN FÜR ICONS, ZEIT & BERUFE
-- =====================================================================
local function GetCurrencyAmount(id)
    if not id then return 0 end
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    return info and info.quantity or 0
end

local function GetCurrencyIcon(id)
    if not id then return 134400 end
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    return info and info.iconFileID or 134400
end

local function FormatGold(money)
    local g = math.floor((money or 0) / 10000)
    return BreakUpLargeNumbers(g) .. " |TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
end

local function FormatPlayed(seconds)
    if not seconds or seconds == 0 then return "-" end
    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    if d > 0 then
        return string.format("%dt %dh", d, h)
    else
        return string.format("%dh", h)
    end
end

local function GetClassHexColor(class)
    local color = E:ClassColor(class) or RAID_CLASS_COLORS[class]
    if color then
        return string.format("%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
    end
    return "ffffff"
end

local function GetExpansionNameByMaxSkill(maxSkill)
    if not maxSkill then return "" end
    if maxSkill == 100 then return "Midnight"
    elseif maxSkill == 150 then return "BfA / Kul Tiras"
    elseif maxSkill == 175 then return "Shadowlands"
    elseif maxSkill == 115 then return "Legion"
    elseif maxSkill == 75 then return "Cata / MoP"
    elseif maxSkill == 300 then return "Classic"
    else return "Aktuell" end
end

-- =====================================================================
-- 3. DATENBANK & TRACKING
-- =====================================================================
function AUI:InitAltDatabase()
    if not _G["ElvUI_AUIDB"] then _G["ElvUI_AUIDB"] = {} end
    local DB = _G["ElvUI_AUIDB"]
    DB.Alts = DB.Alts or {}
    DB.Alts.Characters = DB.Alts.Characters or {}
    DB.Alts.WarbandGold = DB.Alts.WarbandGold or 0
    
    AUI.AltDB = DB.Alts
end

local function UpdateCurrentAltInfo()
    if not AUI.AltDB then AUI:InitAltDatabase() end
    
    local name = UnitName("player")
    local realm = GetRealmName()
    local charKey = name .. "-" .. realm
    
    local _, class = UnitClass("player")
    local level = UnitLevel("player")
    local gold = GetMoney()
    local faction = UnitFactionGroup("player") or "Neutral"
    local guildName = GetGuildInfo("player") or "-"
    
    local ilvl = math.floor(select(2, GetAverageItemLevel()) or 0)
    
    local specIndex = GetSpecialization()
    local specName = specIndex and select(2, GetSpecializationInfo(specIndex)) or "-"
    local role = specIndex and GetSpecializationRole(specIndex) or "NONE"
    local roleName = (role == "TANK" and "Tank") or (role == "HEALER" and "Heal") or (role == "DAMAGER" and "DPS") or "-"
    
    local prof1, prof2 = GetProfessions()
    local p1Name, p1Icon, p1Skill, p1Max, p1Expan, p1Mod
    local p2Name, p2Icon, p2Skill, p2Max, p2Expan, p2Mod
    
    -- Parameter 8 ist der skillModifier (Ausrüstungs-Bonus / Wissen)
    if prof1 then
        local n, i, s, m, _, _, _, mod = GetProfessionInfo(prof1)
        p1Name, p1Icon, p1Skill, p1Max, p1Mod = n, i, s, m, mod
        p1Expan = GetExpansionNameByMaxSkill(m)
    end
    if prof2 then
        local n, i, s, m, _, _, _, mod = GetProfessionInfo(prof2)
        p2Name, p2Icon, p2Skill, p2Max, p2Mod = n, i, s, m, mod
        p2Expan = GetExpansionNameByMaxSkill(m)
    end
    
    local ids = GetDynamicCurrencyIDs()
    local cofferKeys = GetCurrencyAmount(ids.Key)
    local catalyst = GetCurrencyAmount(ids.Catalyst)
    local crestV = GetCurrencyAmount(ids.CrestVet)
    local crestC = GetCurrencyAmount(ids.CrestChamp)
    local crestH = GetCurrencyAmount(ids.CrestHero)
    local crestM = GetCurrencyAmount(ids.CrestMyth)
    
    local mplusScore = C_ChallengeMode.GetOverallDungeonScore() or 0
    local ksLevel = C_MythicPlus.GetOwnedKeystoneLevel() or 0
    local ksMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local ksString = "-"
    
    if ksLevel > 0 and ksMapID then
        local mapName = C_ChallengeMode.GetMapUIInfo(ksMapID)
        if mapName then
            local shortName = string.utf8sub(mapName, 1, 12)
            if string.len(mapName) > 12 then shortName = shortName .. "." end
            ksString = string.format("%s (+%d)", shortName, ksLevel)
        else
            ksString = "+" .. ksLevel
        end
    end
    
    local cdb = AUI.AltDB.Characters[charKey] or {}
    local currentPlayed = cdb.played or 0
    if cdb.playedTotal and cdb.playedSessionStart then
        currentPlayed = cdb.playedTotal + (GetTime() - cdb.playedSessionStart)
    end
    
    AUI.AltDB.Characters[charKey] = {
        name = name,
        realm = realm,
        faction = faction,
        guild = guildName,
        class = class,
        level = level,
        gold = gold,
        ilvl = ilvl,
        spec = specName,
        role = roleName,
        p1Name = p1Name, p1Icon = p1Icon, p1Skill = p1Skill, p1Max = p1Max, p1Expan = p1Expan, p1Mod = p1Mod,
        p2Name = p2Name, p2Icon = p2Icon, p2Skill = p2Skill, p2Max = p2Max, p2Expan = p2Expan, p2Mod = p2Mod,
        cofferKeys = cofferKeys,
        catalyst = catalyst,
        crestV = crestV,
        crestC = crestC,
        crestH = crestH,
        crestM = crestM,
        mplusScore = mplusScore,
        keystone = ksString,
        keystoneLevel = ksLevel,
        playedTotal = cdb.playedTotal,
        playedSessionStart = cdb.playedSessionStart,
        played = currentPlayed,
        lastUpdate = time()
    }
end

local function UpdateWarbandGold()
    if not AUI.AltDB then AUI:InitAltDatabase() end
    if C_Bank and C_Bank.FetchDepositedMoney then
        local wbGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
        if wbGold and wbGold >= 0 then
            AUI.AltDB.WarbandGold = wbGold
        end
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg)
    if AUI.IsFetchingPlayed then return true end
    return false
end)

local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        AUI:InitAltDatabase()
        C_Timer.After(2.0, UpdateCurrentAltInfo)
        
        C_Timer.After(4.0, function()
            AUI.IsFetchingPlayed = true
            RequestTimePlayed()
            C_Timer.After(1.0, function() AUI.IsFetchingPlayed = false end)
        end)
        
    elseif event == "TIME_PLAYED_MSG" then
        local totalTime = ...
        if AUI.AltDB then
            local charKey = UnitName("player") .. "-" .. GetRealmName()
            if AUI.AltDB.Characters[charKey] then
                AUI.AltDB.Characters[charKey].playedTotal = totalTime
                AUI.AltDB.Characters[charKey].playedSessionStart = GetTime()
                AUI.AltDB.Characters[charKey].played = totalTime
            end
        end
        
    elseif event == "BANKFRAME_OPENED" or event == "ACCOUNT_MONEY" then
        UpdateWarbandGold()
        if event == "ACCOUNT_MONEY" and AUI_AltInfoFrame and AUI_AltInfoFrame:IsShown() then
            AUI:UpdateAltUI()
        end
    else
        C_Timer.After(1.5, UpdateCurrentAltInfo)
    end
end

AltTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
AltTracker:RegisterEvent("TIME_PLAYED_MSG")
AltTracker:RegisterEvent("PLAYER_MONEY")
AltTracker:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
AltTracker:RegisterEvent("PLAYER_LEVEL_UP")
AltTracker:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
AltTracker:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
AltTracker:RegisterEvent("BANKFRAME_OPENED")
pcall(function() AltTracker:RegisterEvent("ACCOUNT_MONEY") end)
AltTracker:SetScript("OnEvent", OnEvent)

-- =====================================================================
-- 4. DAS FRONTEND (DASHBOARD)
-- =====================================================================
local UI = CreateFrame("Frame", "AUI_AltInfoFrame", E.UIParent, "BackdropTemplate")
UI:SetSize(1480, 500) 
UI:SetPoint("CENTER", E.UIParent, "CENTER", 0, 0)
UI:SetTemplate("Transparent")
UI:SetMovable(true)
UI:EnableMouse(true)
UI:RegisterForDrag("LeftButton")
UI:SetScript("OnDragStart", UI.StartMoving)
UI:SetScript("OnDragStop", UI.StopMovingOrSizing)
UI:SetFrameStrata("HIGH")
UI:Hide()

tinsert(UISpecialFrames, "AUI_AltInfoFrame")

UI.Title = UI:CreateFontString(nil, "OVERLAY")
UI.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 18, "SHADOWOUTLINE")
UI.Title:SetPoint("TOP", UI, "TOP", 0, -15)
UI.Title:SetText("|cff00ffd2A-UI|r Alts")

UI.CloseButton = CreateFrame("Button", nil, UI, "UIPanelCloseButton")
UI.CloseButton:SetPoint("TOPRIGHT", UI, "TOPRIGHT", -4, -4)
E:GetModule("Skins"):HandleCloseButton(UI.CloseButton)

-- Header Container (Breite: 1410)
UI.HeaderFrame = CreateFrame("Frame", nil, UI, "BackdropTemplate")
UI.HeaderFrame:SetSize(1410, 24)
UI.HeaderFrame:SetPoint("TOPLEFT", UI, "TOPLEFT", 20, -50)

-- ScrollFrame (Mit eigener Spur für die Scrollbar)
UI.ScrollFrame = CreateFrame("ScrollFrame", "AUI_AltScrollFrame", UI, "UIPanelScrollFrameTemplate")
UI.ScrollFrame:SetPoint("TOPLEFT", UI.HeaderFrame, "BOTTOMLEFT", 0, -5)
UI.ScrollFrame:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", -50, 50) 

-- ScrollChild (Muss EXAKT so breit sein wie das HeaderFrame = 1410)
UI.ScrollChild = CreateFrame("Frame", nil, UI.ScrollFrame)
UI.ScrollChild:SetSize(1410, 100)
UI.ScrollFrame:SetScrollChild(UI.ScrollChild)

if AUI_AltScrollFrameScrollBar and E:GetModule("Skins").HandleScrollBar then
    E:GetModule("Skins"):HandleScrollBar(AUI_AltScrollFrameScrollBar)
end

-- Fußzeile
UI.BottomLine = CreateFrame("Frame", nil, UI, "BackdropTemplate")
UI.BottomLine:SetSize(1410, 2)
UI.BottomLine:SetPoint("BOTTOMLEFT", UI, "BOTTOMLEFT", 20, 40)
UI.BottomLine:SetTemplate("Default")

-- Text rechts (Gold & Zeit) - Exakt am Content-Rand (-50)
UI.TotalGoldText = UI:CreateFontString(nil, "OVERLAY")
UI.TotalGoldText:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
UI.TotalGoldText:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", -50, 15)
UI.TotalGoldText:SetText("Lade Gold...")

-- Text links (Rollen Statistik)
UI.RoleCountText = UI:CreateFontString(nil, "OVERLAY")
UI.RoleCountText:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
UI.RoleCountText:SetPoint("BOTTOMLEFT", UI, "BOTTOMLEFT", 25, 15)
UI.RoleCountText:SetText("Lade Rollen...")

-- =====================================================================
-- 5. SORTIERUNG & HEADER (Pixelgenaues Layout für 1410px)
-- =====================================================================
local function CreateHeaderBtn(text, width, offsetX, sortKey)
    local btn = CreateFrame("Button", nil, UI.HeaderFrame, "BackdropTemplate")
    btn:SetSize(width, 24)
    btn:SetTemplate("Transparent")
    btn:SetPoint("LEFT", UI.HeaderFrame, "LEFT", offsetX, 0)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY")
    btn.text:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.text:SetText(text)
    btn.text:SetTextColor(1, 0.82, 0)
    
    btn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
    btn:SetScript("OnLeave", function(self) self.text:SetTextColor(1, 0.82, 0) end)
    
    btn:SetScript("OnClick", function()
        if AUI.AltSortBy == sortKey then
            AUI.AltSortAsc = not AUI.AltSortAsc
        else
            AUI.AltSortBy = sortKey
            AUI.AltSortAsc = false
        end
        AUI:UpdateAltUI()
    end)
    
    return btn
end

-- Spalten Layout (Gesamtbreite = 1410)
local hFac     = CreateHeaderBtn("", 20, 0, "faction")
local hClass   = CreateHeaderBtn("Klasse", 30, 20, "class")
local hName    = CreateHeaderBtn("Name", 110, 50, "name")
local hRealm   = CreateHeaderBtn("Realm", 110, 160, "realm")
local hGuild   = CreateHeaderBtn("Gilde", 130, 270, "guild")
local hSpec    = CreateHeaderBtn("Spec", 110, 400, "spec")
local hRole    = CreateHeaderBtn("Rolle", 40, 510, "role")
local hLvl     = CreateHeaderBtn("Lvl", 35, 550, "level")
local hGS      = CreateHeaderBtn("Ø GS", 45, 585, "ilvl")
local hProf    = CreateHeaderBtn("Berufe", 100, 630, "none")
local hPlayed  = CreateHeaderBtn("Spielzeit", 65, 730, "played")
local hKey     = CreateHeaderBtn("Schlüssel", 40, 795, "cofferKeys")
local hCat     = CreateHeaderBtn("Katalysator", 40, 835, "catalyst")
local hScore   = CreateHeaderBtn("M+ Score", 60, 875, "mplusScore")
local hStone   = CreateHeaderBtn("Aktueller Stein", 120, 935, "keystoneLevel")
local hCrests  = CreateHeaderBtn("Wappen", 230, 1055, "crestM")
local hGold    = CreateHeaderBtn("Gold", 100, 1285, "gold")
local hDel     = CreateHeaderBtn("X", 20, 1385, "none")

hDel:SetScript("OnClick", nil)
hProf:SetScript("OnClick", nil)

local altLines = {}

-- =====================================================================
-- 6. UI UPDATE LOGIK
-- =====================================================================
function AUI:UpdateAltUI()
    if not AUI.AltDB or not AUI.AltDB.Characters then return end
    
    UpdateCurrentAltInfo() 
    UpdateWarbandGold()
    
    local ids = GetDynamicCurrencyIDs()
    hKey.text:SetText("|T" .. GetCurrencyIcon(ids.Key) .. ":16|t")
    hCat.text:SetText("|T" .. GetCurrencyIcon(ids.Catalyst) .. ":16|t")
    
    for _, line in ipairs(altLines) do line:Hide() end
    
    local sortedAlts = {}
    local totalGold = AUI.AltDB.WarbandGold or 0
    local totalPlayedSeconds = 0
    
    local countTank, countHeal, countDPS = 0, 0, 0
    
    for charKey, data in pairs(AUI.AltDB.Characters) do
        data.charKey = charKey
        table.insert(sortedAlts, data)
        totalGold = totalGold + (data.gold or 0)
        totalPlayedSeconds = totalPlayedSeconds + (data.played or 0)
        
        if data.role == "Tank" then countTank = countTank + 1
        elseif data.role == "Heal" then countHeal = countHeal + 1
        elseif data.role == "DPS" then countDPS = countDPS + 1 end
    end
    
    local sortCol = AUI.AltSortBy
    local asc = AUI.AltSortAsc
    
    table.sort(sortedAlts, function(a, b)
        local valA = a[sortCol] or 0
        local valB = b[sortCol] or 0
        
        if type(valA) == "string" and type(valB) == "string" then
            if asc then return valA < valB else return valA > valB end
        end
        if asc then return valA < valB else return valA > valB end
    end)
    
    local yOffset = 0
    for i, data in ipairs(sortedAlts) do
        local line = altLines[i]
        if not line then
            line = CreateFrame("Frame", nil, UI.ScrollChild, "BackdropTemplate")
            line:SetSize(1410, 26)
            line:SetTemplate("Transparent")
            
            line.factionIcon = line:CreateTexture(nil, "ARTWORK")
            line.factionIcon:SetSize(16, 16)
            line.factionIcon:SetPoint("LEFT", line, "LEFT", 2, 0)
            
            line.classIcon = line:CreateTexture(nil, "ARTWORK")
            line.classIcon:SetSize(16, 16)
            line.classIcon:SetPoint("LEFT", line, "LEFT", 27, 0)
            
            line.name = line:CreateFontString(nil, "OVERLAY")
            line.name:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.name:SetPoint("LEFT", line, "LEFT", 50, 0)
            line.name:SetWidth(110)
            line.name:SetJustifyH("CENTER")
            line.name:SetWordWrap(false)
            
            line.realm = line:CreateFontString(nil, "OVERLAY")
            line.realm:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.realm:SetPoint("LEFT", line, "LEFT", 160, 0)
            line.realm:SetWidth(110)
            line.realm:SetJustifyH("CENTER")
            line.realm:SetWordWrap(false)
            line.realm:SetTextColor(0.6, 0.6, 0.6)
            
            line.guild = line:CreateFontString(nil, "OVERLAY")
            line.guild:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.guild:SetPoint("LEFT", line, "LEFT", 270, 0)
            line.guild:SetWidth(130)
            line.guild:SetJustifyH("CENTER")
            line.guild:SetWordWrap(false)
            line.guild:SetTextColor(0.4, 0.8, 0.2)
            
            line.spec = line:CreateFontString(nil, "OVERLAY")
            line.spec:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.spec:SetPoint("LEFT", line, "LEFT", 400, 0)
            line.spec:SetWidth(110)
            line.spec:SetJustifyH("CENTER")
            
            line.role = line:CreateFontString(nil, "OVERLAY")
            line.role:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.role:SetPoint("LEFT", line, "LEFT", 510, 0)
            line.role:SetWidth(40)
            line.role:SetJustifyH("CENTER")
            
            line.level = line:CreateFontString(nil, "OVERLAY")
            line.level:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.level:SetPoint("LEFT", line, "LEFT", 550, 0)
            line.level:SetWidth(35)
            line.level:SetJustifyH("CENTER")
            
            line.ilvl = line:CreateFontString(nil, "OVERLAY")
            line.ilvl:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.ilvl:SetPoint("LEFT", line, "LEFT", 585, 0)
            line.ilvl:SetWidth(45)
            line.ilvl:SetJustifyH("CENTER")
            
            line.prof = line:CreateFontString(nil, "OVERLAY")
            line.prof:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.prof:SetPoint("LEFT", line, "LEFT", 630, 0)
            line.prof:SetWidth(100)
            line.prof:SetJustifyH("CENTER")
            
            -- Tooltip für Berufe Button
            line.profBtn = CreateFrame("Button", nil, line)
            line.profBtn:SetAllPoints(line.prof)
            line.profBtn:SetScript("OnEnter", function(self)
                local key = self:GetParent().charKey
                if key and AUI.AltDB.Characters[key] then
                    local d = AUI.AltDB.Characters[key]
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine("Hauptberufe von " .. (d.name or "Unbekannt"), 1, 0.82, 0)
                    
                    local found = false
                    if d.p1Name or d.p1Icon then
                        local n = d.p1Name or "Beruf 1"
                        local expan = d.p1Expan and (" ("..d.p1Expan..")") or ""
                        local iStr = d.p1Icon and ("|T"..d.p1Icon..":16|t ") or ""
                        local bonusStr = (d.p1Mod and d.p1Mod > 0) and (" |cff00ff00(+"..d.p1Mod..")|r") or ""
                        GameTooltip:AddDoubleLine(iStr .. n .. " |cff888888" .. expan .. "|r", (d.p1Skill or 0) .. bonusStr .. " / " .. (d.p1Max or 0), 1, 1, 1, 1, 1, 1)
                        found = true
                    end
                    if d.p2Name or d.p2Icon then
                        local n = d.p2Name or "Beruf 2"
                        local expan = d.p2Expan and (" ("..d.p2Expan..")") or ""
                        local iStr = d.p2Icon and ("|T"..d.p2Icon..":16|t ") or ""
                        local bonusStr = (d.p2Mod and d.p2Mod > 0) and (" |cff00ff00(+"..d.p2Mod..")|r") or ""
                        GameTooltip:AddDoubleLine(iStr .. n .. " |cff888888" .. expan .. "|r", (d.p2Skill or 0) .. bonusStr .. " / " .. (d.p2Max or 0), 1, 1, 1, 1, 1, 1)
                        found = true
                    end
                    
                    if not found then
                        GameTooltip:AddLine("Keine Hauptberufe erlernt.", 0.5, 0.5, 0.5)
                    end
                    
                    GameTooltip:Show()
                end
            end)
            line.profBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            line.played = line:CreateFontString(nil, "OVERLAY")
            line.played:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.played:SetPoint("LEFT", line, "LEFT", 730, 0)
            line.played:SetWidth(65)
            line.played:SetJustifyH("CENTER")
            line.played:SetTextColor(0.8, 0.8, 0.8)
            
            line.keys = line:CreateFontString(nil, "OVERLAY")
            line.keys:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.keys:SetPoint("LEFT", line, "LEFT", 795, 0)
            line.keys:SetWidth(40)
            line.keys:SetJustifyH("CENTER")
            
            line.catalyst = line:CreateFontString(nil, "OVERLAY")
            line.catalyst:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.catalyst:SetPoint("LEFT", line, "LEFT", 835, 0)
            line.catalyst:SetWidth(40)
            line.catalyst:SetJustifyH("CENTER")
            
            line.mscore = line:CreateFontString(nil, "OVERLAY")
            line.mscore:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.mscore:SetPoint("LEFT", line, "LEFT", 875, 0)
            line.mscore:SetWidth(60)
            line.mscore:SetJustifyH("CENTER")
            
            line.stone = line:CreateFontString(nil, "OVERLAY")
            line.stone:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.stone:SetPoint("LEFT", line, "LEFT", 935, 0)
            line.stone:SetWidth(120)
            line.stone:SetJustifyH("CENTER")
            line.stone:SetWordWrap(false)
            
            line.crests = line:CreateFontString(nil, "OVERLAY")
            line.crests:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.crests:SetPoint("LEFT", line, "LEFT", 1055, 0)
            line.crests:SetWidth(230)
            line.crests:SetJustifyH("CENTER")
            
            line.gold = line:CreateFontString(nil, "OVERLAY")
            line.gold:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.gold:SetPoint("LEFT", line, "LEFT", 1285, 0)
            line.gold:SetWidth(100)
            line.gold:SetJustifyH("RIGHT")
            
            line.delBtn = CreateFrame("Button", nil, line)
            line.delBtn:SetSize(16, 16)
            line.delBtn:SetPoint("LEFT", line, "LEFT", 1385, 0)
            line.delBtn.tex = line.delBtn:CreateTexture(nil, "ARTWORK")
            line.delBtn.tex:SetAllPoints()
            line.delBtn.tex:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
            line.delBtn:SetScript("OnEnter", function(self) self.tex:SetVertexColor(1, 0, 0) end)
            line.delBtn:SetScript("OnLeave", function(self) self.tex:SetVertexColor(1, 1, 1) end)
            line.delBtn:SetScript("OnClick", function(self)
                local key = self:GetParent().charKey
                if key and AUI.AltDB.Characters[key] then
                    AUI.AltDB.Characters[key] = nil
                    AUI:UpdateAltUI()
                end
            end)
            
            altLines[i] = line
        end
        
        -- Fraktion (Blizzard UI Icons)
        if data.faction == "Horde" then
            line.factionIcon:SetTexture("Interface\\FriendsFrame\\PlusManz-Horde")
        elseif data.faction == "Alliance" then
            line.factionIcon:SetTexture("Interface\\FriendsFrame\\PlusManz-Alliance")
        else
            line.factionIcon:SetTexture("Interface\\Icons\\INV_BannerPVP_03")
        end
        
        -- Klasse, Name & Realm
        local classColor = GetClassHexColor(data.class)
        line.classIcon:SetTexture("Interface\\WorldStateFrame\\ICONS-CLASSES")
        line.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[data.class] or {0, 1, 0, 1}))
        
        line.name:SetText("|cff" .. classColor .. data.name .. "|r")
        line.realm:SetText(data.realm or "")
        
        -- Gilde
        line.guild:SetText(data.guild == "-" and "-" or "<" .. data.guild .. ">")
        
        -- Spec & Rolle
        line.spec:SetText(data.spec or "-")
        line.role:SetText("|cff888888" .. (data.role or "-") .. "|r")
        
        -- Level
        line.level:SetText(data.level or "?")
        
        -- Itemlevel Farbe dynamisch berechnen
        local ilvl = data.ilvl or 0
        local colorStr = "|cffffffff"
        if ilvl >= AUI_CONFIG.IlvlEpic then colorStr = "|cffa335ee"
        elseif ilvl >= AUI_CONFIG.IlvlRare then colorStr = "|cff0070dd"
        elseif ilvl >= AUI_CONFIG.IlvlUncommon then colorStr = "|cff1eff00" end
        line.ilvl:SetText(colorStr .. ilvl .. "|r")
        
        -- Berufe
        local profStr = ""
        if data.p1Icon then profStr = profStr .. "|T" .. data.p1Icon .. ":14|t " .. (data.p1Skill or 0) end
        if data.p2Icon then profStr = profStr .. "  |T" .. data.p2Icon .. ":14|t " .. (data.p2Skill or 0) end
        line.prof:SetText(profStr == "" and "-" or profStr)
        
        line.played:SetText(FormatPlayed(data.played))
        line.keys:SetText(data.cofferKeys or 0)
        
        local catCol = (data.catalyst or 0) > 0 and "|cff00ff00" or "|cff888888"
        line.catalyst:SetText(catCol .. (data.catalyst or 0) .. "|r")
        
        local mScore = data.mplusScore or 0
        local cScore = (mScore > 2000 and "|cffff8000") or (mScore > 1000 and "|cffa335ee") or "|cffffffff"
        line.mscore:SetText(cScore .. mScore .. "|r")
        
        line.stone:SetText(data.keystone or "-")
        
        -- Wappen formatieren
        local cV, cC, cH, cM = data.crestV or 0, data.crestC or 0, data.crestH or 0, data.crestM or 0
        line.crests:SetText(string.format("|T%s:14|t %d | |T%s:14|t %d | |T%s:14|t %d | |T%s:14|t %d", 
            GetCurrencyIcon(ids.CrestVet), cV, 
            GetCurrencyIcon(ids.CrestChamp), cC, 
            GetCurrencyIcon(ids.CrestHero), cH, 
            GetCurrencyIcon(ids.CrestMyth), cM))
        
        line.gold:SetText(FormatGold(data.gold or 0))
        line.charKey = data.charKey
        
        line:ClearAllPoints()
        line:SetPoint("TOP", UI.ScrollChild, "TOP", 0, yOffset)
        line:Show()
        
        yOffset = yOffset - 30
    end
    
    UI.ScrollChild:SetHeight(math.abs(yOffset))
    
    local warbandStr = FormatGold(AUI.AltDB.WarbandGold or 0)
    local playedStr = FormatPlayed(totalPlayedSeconds)
    
    UI.TotalGoldText:SetText(string.format("Spielzeit (Account): |cffdddddd%s|r   |   Kriegsmeutenbank: |cffdddddd%s|r   |   Gesamtgold: |cff00ffd2%s|r", playedStr, warbandStr, FormatGold(totalGold)))
    
    UI.RoleCountText:SetText(string.format("Rollen:   |cffddddddTank:|r %d   |   |cffddddddHeal:|r %d   |   |cffddddddDPS:|r %d", countTank, countHeal, countDPS))
end

E:RegisterChatCommand("alts", function()
    if AUI_AltInfoFrame:IsShown() then
        AUI_AltInfoFrame:Hide()
    else
        AUI:UpdateAltUI()
        AUI_AltInfoFrame:Show()
    end
end)