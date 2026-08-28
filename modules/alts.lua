local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local AltTracker = CreateFrame("Frame")

AUI.AltSortBy = isRetail and "ilvl" or "level"
AUI.AltSortAsc = false

-- =====================================================================
-- 0. KONFIGURATION & ICON-LOOKUP FÜR CLASSIC
-- =====================================================================
local AUI_CONFIG = {
    IlvlEpic = isRetail and 250 or 115,
    IlvlRare = isRetail and 230 or 100,
    IlvlUncommon = isRetail and 200 or 85
}

local CLASSIC_PROF_ICONS = {
    ["Alchemie"]          = "Interface\\Icons\\Trade_Alchemy",
    ["Alchimie"]          = "Interface\\Icons\\Trade_Alchemy",
    ["Alchemy"]           = "Interface\\Icons\\Trade_Alchemy",
    ["Schmiedekunst"]     = "Interface\\Icons\\Trade_BlackSmithing",
    ["Blacksmithing"]     = "Interface\\Icons\\Trade_BlackSmithing",
    ["Verzauberkunst"]    = "Interface\\Icons\\Trade_Engraving",
    ["Enchanting"]        = "Interface\\Icons\\Trade_Engraving",
    ["Ingenieurskunst"]   = "Interface\\Icons\\Trade_Engineering",
    ["Engineering"]       = "Interface\\Icons\\Trade_Engineering",
    ["Lederverarbeitung"] = "Interface\\Icons\\Trade_LeatherWorking",
    ["Leatherworking"]    = "Interface\\Icons\\Trade_LeatherWorking",
    ["Schneidern"]        = "Interface\\Icons\\Trade_Tailoring",
    ["Schneiderei"]       = "Interface\\Icons\\Trade_Tailoring",
    ["Tailoring"]         = "Interface\\Icons\\Trade_Tailoring",
    ["Bergbau"]           = "Interface\\Icons\\Trade_Mining",
    ["Mining"]            = "Interface\\Icons\\Trade_Mining",
    ["Kräuterkunde"]      = "Interface\\Icons\\Trade_Herbalism",
    ["Herbalism"]         = "Interface\\Icons\\Trade_Herbalism",
    ["Kürschnerei"]       = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    ["Skinning"]          = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    ["Juwelenschleifen"]  = "Interface\\Icons\\INV_Misc_Gem_01",
    ["Jewelcrafting"]     = "Interface\\Icons\\INV_Misc_Gem_01",
    ["Kochkunst"]         = "Interface\\Icons\\INV_Misc_Food_15",
    ["Kochen"]            = "Interface\\Icons\\INV_Misc_Food_15",
    ["Cooking"]           = "Interface\\Icons\\INV_Misc_Food_15",
    ["Erste Hilfe"]       = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ["First Aid"]         = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ["Angeln"]            = "Interface\\Icons\\Trade_Fishing",
    ["Fishing"]           = "Interface\\Icons\\Trade_Fishing",
    ["Schlösserknacken"]  = "Interface\\Icons\\Spell_Nature_MoonKey",
    ["Lockpicking"]       = "Interface\\Icons\\Spell_Nature_MoonKey",
}

local function GetClassicProfessionIcon(name)
    if not name then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    return CLASSIC_PROF_ICONS[name] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- =====================================================================
-- 1. DYNAMISCHER WÄHRUNGSSCANNER (RETAIL)
-- =====================================================================
local function GetDynamicCurrencyIDs()
    if not isRetail then return {} end
    if AUI.CurrencyCache and AUI.CurrencyCache.Catalyst then return AUI.CurrencyCache end
    AUI.CurrencyCache = AUI.CurrencyCache or {}

    local function ParseCurrencyName(curID, name)
        local n = string.lower(name)
        if string.find(n, "kastenschlüsselsplitter") or string.find(n, "coffer key shard") then AUI.CurrencyCache.Shard = curID
        elseif string.find(n, "restaurierter kastenschlüssel") or string.find(n, "restored coffer key") or string.find(n, "kastenschlüssel") then AUI.CurrencyCache.Key = curID
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
    if not AUI.CurrencyCache.Shard then AUI.CurrencyCache.Shard = 3027 end
    if not AUI.CurrencyCache.Catalyst then AUI.CurrencyCache.Catalyst = 3116 end

    return AUI.CurrencyCache
end

-- =====================================================================
-- 2. HILFSFUNKTIONEN
-- =====================================================================
local function GetSafeTalentTabInfo(tabIndex)
    if not GetTalentTabInfo then return "-", nil, 0 end
    local ret1, ret2, ret3, ret4, ret5 = GetTalentTabInfo(tabIndex)
    if type(ret1) == "string" then
        return ret1, ret2, tonumber(ret3) or 0
    elseif type(ret2) == "string" then
        return ret2, ret4, tonumber(ret5) or 0
    end
    return "-", nil, 0
end

local function GetCurrencyAmount(id)
    if not id or not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return 0 end
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    return info and info.quantity or 0
end

local function GetCurrencyDetails(id)
    if not id or not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return 0, 0, 0 end
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    if not info then return 0, 0, 0 end
    local qty = info.quantity or 0
    local maxQty = info.maxQuantity or 0
    
    if maxQty == 0 and info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0 then
        maxQty = info.maxWeeklyQuantity
    end
    
    local earned = info.useTotalEarnedForMaxQty and info.totalEarned or info.quantityEarnedThisWeek or qty
    return qty, earned, maxQty
end

local function GetCurrencyIcon(id)
    if not id then return 134400 end
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(id)
        return info and info.iconFileID or 134400
    end
    return 134400
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
        return string.format("%dd %dh", d, h)
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
    
    local guildNameRaw, guildRankName = GetGuildInfo("player")
    local guildName = guildNameRaw or "-"
    local guildRank = guildRankName or "-"
    
    local ilvl = 0
    if GetAverageItemLevel then
        ilvl = math.floor(select(2, GetAverageItemLevel()) or select(1, GetAverageItemLevel()) or 0)
    end
    
    -- Spezialisierung & Rolle
    local specName, roleName = "-", "-"
    if isRetail then
        local specIndex = GetSpecialization()
        specName = specIndex and select(2, GetSpecializationInfo(specIndex)) or "-"
        local role = specIndex and GetSpecializationRole(specIndex) or "NONE"
        roleName = (role == "TANK" and "Tank") or (role == "HEALER" and "Heal") or (role == "DAMAGER" and "DPS") or "-"
    else
        local topPts, topTree = -1, "-"
        local t1, t2, t3 = 0, 0, 0
        local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 3
        if numTabs >= 3 then
            local n1, _, p1 = GetSafeTalentTabInfo(1)
            local n2, _, p2 = GetSafeTalentTabInfo(2)
            local n3, _, p3 = GetSafeTalentTabInfo(3)
            t1, t2, t3 = p1 or 0, p2 or 0, p3 or 0
            if t1 > topPts then topPts = t1; topTree = n1 or "-" end
            if t2 > topPts then topPts = t2; topTree = n2 or "-" end
            if t3 > topPts then topPts = t3; topTree = n3 or "-" end
        end
        specName = (topPts > 0) and string.format("%s (%d/%d/%d)", topTree, t1, t2, t3) or (L["Unspent"] or "Unspent")
        roleName = "-"
    end
    
    -- Berufe
    local p1Name, p1Icon, p1Skill, p1Max, p1Mod
    local p2Name, p2Icon, p2Skill, p2Max, p2Mod
    
    if isRetail and GetProfessions then
        local prof1, prof2 = GetProfessions()
        if prof1 then
            local n, i, s, m, _, _, _, mod = GetProfessionInfo(prof1)
            p1Name, p1Icon, p1Skill, p1Max, p1Mod = n, i, s, m, mod
        end
        if prof2 then
            local n, i, s, m, _, _, _, mod = GetProfessionInfo(prof2)
            p2Name, p2Icon, p2Skill, p2Max, p2Mod = n, i, s, m, mod
        end
    elseif GetNumSkillLines and GetSkillLineInfo then
        local primaryProfs = {}
        local numSkills = GetNumSkillLines()
        for i = 1, numSkills do
            local skillName, isHeader, _, skillRank, _, skillModifier, skillMaxRank, isAbandonable = GetSkillLineInfo(i)
            if not isHeader and isAbandonable then
                table.insert(primaryProfs, {
                    name = skillName,
                    icon = GetClassicProfessionIcon(skillName),
                    skill = skillRank or 0,
                    max = skillMaxRank or 0,
                    mod = skillModifier or 0
                })
            end
        end
        if primaryProfs[1] then
            p1Name, p1Icon, p1Skill, p1Max, p1Mod = primaryProfs[1].name, primaryProfs[1].icon, primaryProfs[1].skill, primaryProfs[1].max, primaryProfs[1].mod
        end
        if primaryProfs[2] then
            p2Name, p2Icon, p2Skill, p2Max, p2Mod = primaryProfs[2].name, primaryProfs[2].icon, primaryProfs[2].skill, primaryProfs[2].max, primaryProfs[2].mod
        end
    end
    
    local cdb = AUI.AltDB.Characters[charKey] or {}
    local currentPlayed = cdb.played or 0
    if cdb.playedTotal and cdb.playedSessionStart then
        currentPlayed = cdb.playedTotal + (GetTime() - cdb.playedSessionStart)
    end
    
    local charEntry = {
        name = name,
        realm = realm,
        faction = faction,
        guild = guildName,
        guildRank = guildRank,
        class = class,
        level = level,
        gold = gold,
        ilvl = ilvl,
        spec = specName,
        role = roleName,
        p1Name = p1Name, p1Icon = p1Icon, p1Skill = p1Skill, p1Max = p1Max, p1Mod = p1Mod,
        p2Name = p2Name, p2Icon = p2Icon, p2Skill = p2Skill, p2Max = p2Max, p2Mod = p2Mod,
        playedTotal = cdb.playedTotal,
        playedSessionStart = cdb.playedSessionStart,
        played = currentPlayed,
        lastUpdate = time()
    }
    
    if isRetail then
        local ids = GetDynamicCurrencyIDs()
        local shardQty, shardEarned, shardMax = GetCurrencyDetails(ids.Shard)
        local crestV_qty, crestV_earned, crestV_max = GetCurrencyDetails(ids.CrestVet)
        local crestC_qty, crestC_earned, crestC_max = GetCurrencyDetails(ids.CrestChamp)
        local crestH_qty, crestH_earned, crestH_max = GetCurrencyDetails(ids.CrestHero)
        local crestM_qty, crestM_earned, crestM_max = GetCurrencyDetails(ids.CrestMyth)
        
        local ksLevel = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel() or 0
        local ksMapID = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        local ksString = "-"
        if ksLevel > 0 and ksMapID and C_ChallengeMode then
            local mapName = C_ChallengeMode.GetMapUIInfo(ksMapID)
            if mapName then
                local shortName = string.utf8sub(mapName, 1, 12)
                if string.len(mapName) > 12 then shortName = shortName .. "." end
                ksString = string.format("%s (+%d)", shortName, ksLevel)
            else
                ksString = "+" .. ksLevel
            end
        end
        
        charEntry.cofferKeys = GetCurrencyAmount(ids.Key)
        charEntry.cofferShardQty = shardQty
        charEntry.cofferShardEarned = shardEarned
        charEntry.cofferShardMax = shardMax
        charEntry.catalyst = GetCurrencyAmount(ids.Catalyst)
        charEntry.crestV = crestV_qty; charEntry.crestV_earned = crestV_earned; charEntry.crestV_max = crestV_max
        charEntry.crestC = crestC_qty; charEntry.crestC_earned = crestC_earned; charEntry.crestC_max = crestC_max
        charEntry.crestH = crestH_qty; charEntry.crestH_earned = crestH_earned; charEntry.crestH_max = crestH_max
        charEntry.crestM = crestM_qty; charEntry.crestM_earned = crestM_earned; charEntry.crestM_max = crestM_max
        charEntry.mplusScore = C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore and C_ChallengeMode.GetOverallDungeonScore() or 0
        charEntry.keystone = ksString
        charEntry.keystoneLevel = ksLevel
    else
        charEntry.badges = GetItemCount(29434, true) or 0
        charEntry.honor = (GetHonorCurrency and GetHonorCurrency()) or 0
        charEntry.arena = (GetArenaCurrency and GetArenaCurrency()) or 0
    end
    
    AUI.AltDB.Characters[charKey] = charEntry
end

local function UpdateWarbandGold()
    if not isRetail then return end
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
AltTracker:RegisterEvent("SKILL_LINES_CHANGED")
if isRetail then
    pcall(function() AltTracker:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE") end)
    pcall(function() AltTracker:RegisterEvent("CURRENCY_DISPLAY_UPDATE") end)
    pcall(function() AltTracker:RegisterEvent("BANKFRAME_OPENED") end)
    pcall(function() AltTracker:RegisterEvent("ACCOUNT_MONEY") end)
end
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
UI.Title:SetText("|cff00ffd2A-UI|r Alts" .. (isRetail and " (Midnight)" or " (TBC Classic)"))

UI.CloseButton = CreateFrame("Button", nil, UI, "UIPanelCloseButton")
UI.CloseButton:SetPoint("TOPRIGHT", UI, "TOPRIGHT", -4, -4)
E:GetModule("Skins"):HandleCloseButton(UI.CloseButton)

UI.HeaderFrame = CreateFrame("Frame", nil, UI, "BackdropTemplate")
UI.HeaderFrame:SetSize(1410, 24)
UI.HeaderFrame:SetPoint("TOPLEFT", UI, "TOPLEFT", 20, -50)

UI.ScrollFrame = CreateFrame("ScrollFrame", "AUI_AltScrollFrame", UI, "UIPanelScrollFrameTemplate")
UI.ScrollFrame:SetPoint("TOPLEFT", UI.HeaderFrame, "BOTTOMLEFT", 0, -5)
UI.ScrollFrame:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", -50, 50) 

UI.ScrollChild = CreateFrame("Frame", nil, UI.ScrollFrame)
UI.ScrollChild:SetSize(1410, 100)
UI.ScrollFrame:SetScrollChild(UI.ScrollChild)

if AUI_AltScrollFrameScrollBar and E:GetModule("Skins").HandleScrollBar then
    E:GetModule("Skins"):HandleScrollBar(AUI_AltScrollFrameScrollBar)
end

UI.BottomLine = CreateFrame("Frame", nil, UI, "BackdropTemplate")
UI.BottomLine:SetSize(1410, 2)
UI.BottomLine:SetPoint("BOTTOMLEFT", UI, "BOTTOMLEFT", 20, 40)
UI.BottomLine:SetTemplate("Default")

UI.TotalGoldText = UI:CreateFontString(nil, "OVERLAY")
UI.TotalGoldText:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
UI.TotalGoldText:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", -50, 15)
UI.TotalGoldText:SetText("...")

UI.RoleCountText = UI:CreateFontString(nil, "OVERLAY")
UI.RoleCountText:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
UI.RoleCountText:SetPoint("BOTTOMLEFT", UI, "BOTTOMLEFT", 25, 15)
UI.RoleCountText:SetText("")

-- =====================================================================
-- 5. SORTIERUNG & HEADER
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
        if sortKey == "none" then return end
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

local hFac     = CreateHeaderBtn("", 20, 0, "faction")
local hClass   = CreateHeaderBtn(L["Class"] or "Class", 30, 20, "class")
local hName    = CreateHeaderBtn(L["Name"] or "Name", 110, 50, "name")
local hRealm   = CreateHeaderBtn(L["Realm"] or "Realm", 110, 160, "realm")
local hGuild   = CreateHeaderBtn(L["Guild"] or "Guild", 130, 270, "guild")
local hSpec    = CreateHeaderBtn(isRetail and (L["Spec"] or "Spec") or (L["Talents"] or "Talents"), 110, 400, "spec")
local hRole    = CreateHeaderBtn(isRetail and (L["Role"] or "Role") or "-", 40, 510, isRetail and "role" or "none")
local hLvl     = CreateHeaderBtn(L["Lvl"] or "Lvl", 35, 550, "level")
local hGS      = CreateHeaderBtn(isRetail and (L["Avg. iLvl"] or "Ø iLvl") or (L["iLvl"] or "iLvl"), 45, 585, "ilvl")
local hProf    = CreateHeaderBtn(L["Professions"] or "Professions", 100, 630, "none")
local hPlayed  = CreateHeaderBtn(L["Playtime"] or "Playtime", 65, 730, "played")

local hCol1, hCol2, hCol3, hCol4, hCol5
if isRetail then
    hCol1 = CreateHeaderBtn("Schlüssel", 40, 795, "cofferKeys")
    hCol2 = CreateHeaderBtn("Katalysator", 40, 835, "catalyst")
    hCol3 = CreateHeaderBtn("M+ Score", 60, 875, "mplusScore")
    hCol4 = CreateHeaderBtn("Aktueller Stein", 120, 935, "keystoneLevel")
    hCol5 = CreateHeaderBtn("Wappen", 230, 1055, "crestM")
else
    hCol1 = CreateHeaderBtn(L["Badges"] or "Badges", 70, 795, "badges")
    hCol2 = CreateHeaderBtn(L["Honor"] or "Honor", 80, 865, "honor")
    hCol3 = CreateHeaderBtn(L["Arena"] or "Arena", 80, 945, "arena")
    hCol4 = CreateHeaderBtn(L["PvP Rank"] or "PvP Rank", 100, 1025, "none")
    hCol5 = CreateHeaderBtn(L["Notes / Details"] or "Notes / Details", 160, 1125, "none")
end

local hGold = CreateHeaderBtn(L["Gold"] or "Gold", 100, 1285, "gold")
local hDel  = CreateHeaderBtn("X", 20, 1385, "none")

local altLines = {}

-- =====================================================================
-- 6. UI UPDATE LOGIK
-- =====================================================================
function AUI:UpdateAltUI()
    if not AUI.AltDB or not AUI.AltDB.Characters then return end
    
    UpdateCurrentAltInfo() 
    UpdateWarbandGold()
    
    if isRetail then
        local ids = GetDynamicCurrencyIDs()
        hCol1.text:SetText("|T" .. GetCurrencyIcon(ids.Key) .. ":16|t")
        hCol2.text:SetText("|T" .. GetCurrencyIcon(ids.Catalyst) .. ":16|t")
    else
        hCol1.text:SetText("|TInterface\\Icons\\Spell_Holy_ChampionsBond:16|t " .. (L["Badges"] or "Badges"))
        hCol2.text:SetText("|TInterface\\Icons\\PVPCurrency-Honor-" .. (UnitFactionGroup("player") or "Horde") .. ":16|t " .. (L["Honor"] or "Honor"))
        hCol3.text:SetText("|TInterface\\Icons\\Spell_Holy_ChampionsGrace:16|t " .. (L["Arena"] or "Arena"))
    end
    
    for _, line in ipairs(altLines) do line:Hide() end
    
    local sortedAlts = {}
    local totalGold = (isRetail and AUI.AltDB.WarbandGold) or 0
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
        
        if type(valA) ~= type(valB) then
            valA = tostring(valA)
            valB = tostring(valB)
        end
        
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
            
            line.profBtn = CreateFrame("Button", nil, line)
            line.profBtn:SetAllPoints(line.prof)
            line.profBtn:SetScript("OnEnter", function(self)
                local key = self:GetParent().charKey
                if key and AUI.AltDB.Characters[key] then
                    local d = AUI.AltDB.Characters[key]
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(string.format(L["Primary Professions of %s"] or "Primary Professions of %s", d.name or (L["Unknown"] or "Unknown")), 1, 0.82, 0)
                    
                    local found = false
                    if d.p1Name or d.p1Icon then
                        local n = d.p1Name or (L["Professions"] or "Professions")
                        local iStr = d.p1Icon and ("|T"..d.p1Icon..":16|t ") or ""
                        local bonusStr = (d.p1Mod and d.p1Mod > 0) and (" |cff00ff00(+"..d.p1Mod..")|r") or ""
                        GameTooltip:AddDoubleLine(iStr .. n, (d.p1Skill or 0) .. bonusStr .. " / " .. (d.p1Max or 0), 1, 1, 1, 1, 1, 1)
                        found = true
                    end
                    if d.p2Name or d.p2Icon then
                        local n = d.p2Name or (L["Professions"] or "Professions")
                        local iStr = d.p2Icon and ("|T"..d.p2Icon..":16|t ") or ""
                        local bonusStr = (d.p2Mod and d.p2Mod > 0) and (" |cff00ff00(+"..d.p2Mod..")|r") or ""
                        GameTooltip:AddDoubleLine(iStr .. n, (d.p2Skill or 0) .. bonusStr .. " / " .. (d.p2Max or 0), 1, 1, 1, 1, 1, 1)
                        found = true
                    end
                    
                    if not found then
                        GameTooltip:AddLine(L["No primary professions learned."] or "No primary professions learned.", 0.5, 0.5, 0.5)
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
            
            line.col1 = line:CreateFontString(nil, "OVERLAY")
            line.col1:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.col1:SetJustifyH("CENTER")
            
            line.col2 = line:CreateFontString(nil, "OVERLAY")
            line.col2:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.col2:SetJustifyH("CENTER")
            
            line.col3 = line:CreateFontString(nil, "OVERLAY")
            line.col3:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
            line.col3:SetJustifyH("CENTER")
            
            line.col4 = line:CreateFontString(nil, "OVERLAY")
            line.col4:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.col4:SetJustifyH("CENTER")
            
            line.col5 = line:CreateFontString(nil, "OVERLAY")
            line.col5:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
            line.col5:SetJustifyH("CENTER")
            
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
        
        if data.faction == "Horde" then
            line.factionIcon:SetTexture("Interface\\FriendsFrame\\PlusManz-Horde")
        elseif data.faction == "Alliance" then
            line.factionIcon:SetTexture("Interface\\FriendsFrame\\PlusManz-Alliance")
        else
            line.factionIcon:SetTexture("Interface\\Icons\\INV_BannerPVP_03")
        end
        
        local classColor = GetClassHexColor(data.class)
        line.classIcon:SetTexture("Interface\\WorldStateFrame\\ICONS-CLASSES")
        line.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[data.class] or {0, 1, 0, 1}))
        line.name:SetText("|cff" .. classColor .. data.name .. "|r")
        line.realm:SetText(data.realm or "")
        line.guild:SetText(data.guild == "-" and "-" or "<" .. data.guild .. ">")
        line.spec:SetText(data.spec or "-")
        line.role:SetText("|cff888888" .. (data.role or "-") .. "|r")
        line.level:SetText(data.level or "?")
        
        local ilvl = data.ilvl or 0
        local colorStr = "|cffffffff"
        if ilvl >= AUI_CONFIG.IlvlEpic then colorStr = "|cffa335ee"
        elseif ilvl >= AUI_CONFIG.IlvlRare then colorStr = "|cff0070dd"
        elseif ilvl >= AUI_CONFIG.IlvlUncommon then colorStr = "|cff1eff00" end
        line.ilvl:SetText(ilvl > 0 and (colorStr .. ilvl .. "|r") or "-")
        
        local profStr = ""
        if data.p1Icon then profStr = profStr .. "|T" .. data.p1Icon .. ":14|t " .. (data.p1Skill or 0) end
        if data.p2Icon then profStr = profStr .. "  |T" .. data.p2Icon .. ":14|t " .. (data.p2Skill or 0) end
        line.prof:SetText(profStr == "" and "-" or profStr)
        
        line.played:SetText(FormatPlayed(data.played))
        
        if isRetail then
            local ids = GetDynamicCurrencyIDs()
            line.col1:SetPoint("LEFT", line, "LEFT", 795, 0); line.col1:SetWidth(40)
            line.col1:SetText(data.cofferKeys or 0)
            
            local catCol = (data.catalyst or 0) > 0 and "|cff00ff00" or "|cff888888"
            line.col2:SetPoint("LEFT", line, "LEFT", 835, 0); line.col2:SetWidth(40)
            line.col2:SetText(catCol .. (data.catalyst or 0) .. "|r")
            
            local mScore = data.mplusScore or 0
            local cScore = (mScore > 2000 and "|cffff8000") or (mScore > 1000 and "|cffa335ee") or "|cffffffff"
            line.col3:SetPoint("LEFT", line, "LEFT", 875, 0); line.col3:SetWidth(60)
            line.col3:SetText(cScore .. mScore .. "|r")
            
            line.col4:SetPoint("LEFT", line, "LEFT", 935, 0); line.col4:SetWidth(120)
            line.col4:SetText(data.keystone or "-")
            
            local cV, cC, cH, cM = data.crestV or 0, data.crestC or 0, data.crestH or 0, data.crestM or 0
            line.col5:SetPoint("LEFT", line, "LEFT", 1055, 0); line.col5:SetWidth(230)
            line.col5:SetText(string.format("|T%s:14|t %d | |T%s:14|t %d | |T%s:14|t %d | |T%s:14|t %d", 
                GetCurrencyIcon(ids.CrestVet), cV, 
                GetCurrencyIcon(ids.CrestChamp), cC, 
                GetCurrencyIcon(ids.CrestHero), cH, 
                GetCurrencyIcon(ids.CrestMyth), cM))
        else
            line.col1:SetPoint("LEFT", line, "LEFT", 795, 0); line.col1:SetWidth(70)
            line.col1:SetText("|cffffffff" .. (data.badges or 0) .. "|r")
            
            line.col2:SetPoint("LEFT", line, "LEFT", 865, 0); line.col2:SetWidth(80)
            line.col2:SetText("|cff00ffd2" .. (data.honor or 0) .. "|r")
            
            line.col3:SetPoint("LEFT", line, "LEFT", 945, 0); line.col3:SetWidth(80)
            line.col3:SetText("|cffff8000" .. (data.arena or 0) .. "|r")
            
            line.col4:SetPoint("LEFT", line, "LEFT", 1025, 0); line.col4:SetWidth(100)
            line.col4:SetText("-")
            
            line.col5:SetPoint("LEFT", line, "LEFT", 1125, 0); line.col5:SetWidth(160)
            line.col5:SetText("-")
        end
        
        line.gold:SetText(FormatGold(data.gold or 0))
        line.charKey = data.charKey
        
        line:ClearAllPoints()
        line:SetPoint("TOP", UI.ScrollChild, "TOP", 0, yOffset)
        line:Show()
        
        yOffset = yOffset - 30
    end
    
    UI.ScrollChild:SetHeight(math.abs(yOffset))
    
    local playedStr = FormatPlayed(totalPlayedSeconds)
    if isRetail then
        local warbandStr = FormatGold(AUI.AltDB.WarbandGold or 0)
        UI.TotalGoldText:SetText(string.format("Playtime (Account): |cffdddddd%s|r   |   Warband Bank: |cffdddddd%s|r   |   Total Gold: |cff00ffd2%s|r", playedStr, warbandStr, FormatGold(totalGold)))
        UI.RoleCountText:SetText(string.format("Roles:   |cffddddddTank:|r %d   |   |cffddddddHeal:|r %d   |   |cffddddddDPS:|r %d", countTank, countHeal, countDPS))
    else
        UI.TotalGoldText:SetText(string.format(L["Playtime (Account): |cffdddddd%s|r   |   Total Gold: |cff00ffd2%s|r"] or "Playtime (Account): |cffdddddd%s|r   |   Total Gold: |cff00ffd2%s|r", playedStr, FormatGold(totalGold)))
        UI.RoleCountText:SetText(string.format(L["Characters: |cff00ffd2%d|r"] or "Characters: |cff00ffd2%d|r", #sortedAlts))
    end
end

E:RegisterChatCommand("alts", function()
    if AUI_AltInfoFrame:IsShown() then
        AUI_AltInfoFrame:Hide()
    else
        AUI:UpdateAltUI()
        AUI_AltInfoFrame:Show()
    end
end)