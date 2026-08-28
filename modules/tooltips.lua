local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local TT = E:GetModule('Tooltip')

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

-- =====================================================================
-- 1. ICON-LOOKUP & ÜBERSETZUNGEN
-- =====================================================================
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

local FALLBACK_NAMES = {
    ["Collegiate Calamity"] = "Akademischer Aufruhr",
    ["The Grudge Pit"]      = "Die Grollgrube",
    ["Sunkiller Sanctum"]   = "Sonnentötersanktum",
    ["Shadowguard Point"]   = "Schattenwachtspitze",
    ["Atal'Aman"]           = "Atal'Aman",
    ["The Gulf of Memory"]  = "Die Kluft der Erinnerung",
    ["The Shadow Enclave"]  = "Die Schattenenklave",
    ["Twilight Crypts"]     = "Gruften der Zwielichtklinge",
    ["The Darkway"]         = "Der Düsterweg",
    ["Parhelion Plaza"]     = "Parhelion Plaza"
}

-- =====================================================================
-- 2. HILFSFUNKTIONEN: TALENTE & FORTSCHRITTSBALKEN
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

local function CreateProgressBar(cur, maxVal)
    if not maxVal or maxVal <= 0 then cur = 1; maxVal = 1 end
    local perc = math.min(1, math.max(0, cur / maxVal))
    local r, g, b = E:ColorGradient(perc, 1, 0, 0, 1, 1, 0, 0, 1, 0)
    local r8, g8, b8 = math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
    local barWidth = 60
    local fillWidth = math.max(0, math.floor(perc * barWidth))
    local emptyWidth = barWidth - fillWidth
    local fillStr = fillWidth > 0 and string.format("|TInterface\\Buttons\\WHITE8X8:10:%d:0:0:8:8:0:8:0:8:%d:%d:%d|t", fillWidth, r8, g8, b8) or ""
    local emptyStr = emptyWidth > 0 and string.format("|TInterface\\Buttons\\WHITE8X8:10:%d:0:0:8:8:0:8:0:8:40:40:40|t", emptyWidth) or ""
    local hexColor = string.format("ff%02x%02x%02x", r8, g8, b8)
    return string.format("  |c%s%d%%|r %s ", hexColor, math.floor(perc * 100), fillStr .. emptyStr)
end

-- =====================================================================
-- 3. HILFSFUNKTION: TOOLTIP OPTIK
-- =====================================================================
local function StyleTooltip(tip)
    if not tip then return end
    local db = E.db.AUI and E.db.AUI.microbar
    if not db then return end
    
    local bgR, bgG, bgB = unpack(E.media.backdropcolor)
    if db.tooltipBackdropColorEnable and db.tooltipBackdropColor then
        bgR, bgG, bgB = db.tooltipBackdropColor.r, db.tooltipBackdropColor.g, db.tooltipBackdropColor.b
    end
    local bgA = db.tooltipBackdropAlpha or 0.8
    
    local bdR, bdG, bdB = unpack(E.media.bordercolor)
    if db.tooltipBorderColorEnable then
        if db.tooltipBorderClassColor then
            local c = E:ClassColor(E.myclass) or RAID_CLASS_COLORS[E.myclass]
            if c then bdR, bdG, bdB = c.r, c.g, c.b end
        elseif db.tooltipBorderColor then
            bdR, bdG, bdB = db.tooltipBorderColor.r, db.tooltipBorderColor.g, db.tooltipBorderColor.b
        end
    end
    
    if tip.SetBackdropColor then tip:SetBackdropColor(bgR, bgG, bgB, bgA) end
    if tip.SetBackdropBorderColor then tip:SetBackdropBorderColor(bdR, bdG, bdB, 1) end
    
    if tip.backdrop then
        if tip.backdrop.SetBackdropColor then tip.backdrop:SetBackdropColor(bgR, bgG, bgB, bgA) end
        if tip.backdrop.SetBackdropBorderColor then tip.backdrop:SetBackdropBorderColor(bdR, bdG, bdB, 1) end
    end
end

if TT and TT.SetStyle then
    if not AUI.TooltipHooked then
        hooksecurefunc(TT, "SetStyle", function(_, tip)
            if tip and tip == GameTooltip then
                local owner = tip:GetOwner()
                if owner and owner.GetName and owner:GetName() and string.match(owner:GetName(), "AUI_MicroWrapper") then
                    StyleTooltip(tip)
                end
            end
        end)
        AUI.TooltipHooked = true
    end
else
    if not AUI.TooltipHooked then
        GameTooltip:HookScript("OnShow", function(self)
            local owner = self:GetOwner()
            if owner and owner.GetName and owner:GetName() and string.match(owner:GetName(), "AUI_MicroWrapper") then
                StyleTooltip(self)
            end
        end)
        AUI.TooltipHooked = true
    end
end

function AUI:ClearTooltipStyle() end

-- =====================================================================
-- 4. ZENTRALER RESET
-- =====================================================================
if not GameTooltip.AUI_TitleResetHooked then
    GameTooltip:HookScript("OnTooltipCleared", function(self)
        if AUI.TooltipTitleModified then
            local titleStr = _G[self:GetName() .. "TextLeft1"]
            if titleStr then
                local font, _, outline = titleStr:GetFont()
                local defaultSize = (E.db and E.db.tooltip and E.db.tooltip.headerFontSize) or AUI.OrigTooltipTitleSize or 16
                titleStr:SetFont(font, defaultSize, outline)
            end
            AUI.TooltipTitleModified = false
        end
        if self.AUI_ExtraColumns then
            for _, fs in pairs(self.AUI_ExtraColumns) do fs:Hide(); fs:SetText("") end
        end
    end)
    GameTooltip.AUI_TitleResetHooked = true
end

-- =====================================================================
-- 5. HILFSFUNKTIONEN FÜR TABELLEN
-- =====================================================================
local function AddThreeColumnLine(tip, col1, col2, col3, color1, color2, color3, midOffset, alignMid, spacerWidth)
    midOffset = midOffset or 170; alignMid = alignMid or "LEFT"; spacerWidth = spacerWidth or 120
    local r1, g1, b1 = unpack(color1 or {1, 1, 1}); local r3, g3, b3 = unpack(color3 or {1, 1, 1})
    local spacer = string.format("|TInterface\\Buttons\\WHITE8X8:1:%d:0:0:1:1:0:0:0:0:0:0:0:0|t", spacerWidth)
    tip:AddDoubleLine(col1, spacer .. col3, r1, g1, b1, r3, g3, b3)
    
    local lineNum = tip:NumLines(); local leftStr = _G[tip:GetName() .. "TextLeft" .. lineNum]
    if not tip.AUI_ExtraColumns then tip.AUI_ExtraColumns = {} end
    local midStr = tip.AUI_ExtraColumns[lineNum]
    if not midStr then midStr = tip:CreateFontString(nil, "ARTWORK", "GameTooltipText"); tip.AUI_ExtraColumns[lineNum] = midStr end
    
    local r2, g2, b2 = unpack(color2 or {1, 1, 1})
    midStr:SetFontObject(leftStr:GetFontObject()); midStr:SetText(col2); midStr:SetTextColor(r2, g2, b2); midStr:ClearAllPoints()
    if alignMid == "LEFT" then
        midStr:SetPoint("TOPLEFT", leftStr, "TOPLEFT", midOffset, 0); midStr:SetPoint("BOTTOMLEFT", leftStr, "BOTTOMLEFT", midOffset, 0)
    else
        midStr:SetPoint("TOPRIGHT", leftStr, "TOPLEFT", midOffset, 0); midStr:SetPoint("BOTTOMRIGHT", leftStr, "BOTTOMLEFT", midOffset, 0)
    end
    midStr:SetJustifyH(alignMid); midStr:Show()
end

local function AddFourColumnLine(tip, col1, col2, col3, col4, color1, color2, color3, color4, off1, off2, align1, align2, spacerWidth)
    off1 = off1 or 140; off2 = off2 or 260; align1 = align1 or "LEFT"; align2 = align2 or "LEFT"; spacerWidth = spacerWidth or 280
    local r1, g1, b1 = unpack(color1 or {1, 1, 1}); local r4, g4, b4 = unpack(color4 or {1, 1, 1})
    local spacer = string.format("|TInterface\\Buttons\\WHITE8X8:1:%d:0:0:1:1:0:0:0:0:0:0:0:0|t", spacerWidth)
    tip:AddDoubleLine(col1, spacer .. col4, r1, g1, b1, r4, g4, b4)
    local lineNum = tip:NumLines(); local leftStr = _G[tip:GetName() .. "TextLeft" .. lineNum]
    if not tip.AUI_ExtraColumns then tip.AUI_ExtraColumns = {} end
    local mid1 = tip.AUI_ExtraColumns[lineNum .. "_1"]
    if not mid1 then mid1 = tip:CreateFontString(nil, "ARTWORK", "GameTooltipText"); tip.AUI_ExtraColumns[lineNum .. "_1"] = mid1 end
    local mid2 = tip.AUI_ExtraColumns[lineNum .. "_2"]
    if not mid2 then mid2 = tip:CreateFontString(nil, "ARTWORK", "GameTooltipText"); tip.AUI_ExtraColumns[lineNum .. "_2"] = mid2 end
    local r2, g2, b2 = unpack(color2 or {1, 1, 1}); local r3, g3, b3 = unpack(color3 or {1, 1, 1})
    mid1:SetFontObject(leftStr:GetFontObject()); mid1:SetText(col2); mid1:SetTextColor(r2, g2, b2); mid1:ClearAllPoints()
    mid2:SetFontObject(leftStr:GetFontObject()); mid2:SetText(col3); mid2:SetTextColor(r3, g3, b3); mid2:ClearAllPoints()
    if align1 == "LEFT" then
        mid1:SetPoint("TOPLEFT", leftStr, "TOPLEFT", off1, 0); mid1:SetPoint("BOTTOMLEFT", leftStr, "BOTTOMLEFT", off1, 0)
    else
        mid1:SetPoint("TOPRIGHT", leftStr, "TOPLEFT", off1, 0); mid1:SetPoint("BOTTOMRIGHT", leftStr, "BOTTOMLEFT", off1, 0)
    end
    mid1:SetJustifyH(align1); mid1:Show()
    if align2 == "LEFT" then
        mid2:SetPoint("TOPLEFT", leftStr, "TOPLEFT", off2, 0); mid2:SetPoint("BOTTOMLEFT", leftStr, "BOTTOMLEFT", off2, 0)
    else
        mid2:SetPoint("TOPRIGHT", leftStr, "TOPLEFT", off2, 0); mid2:SetPoint("BOTTOMRIGHT", leftStr, "BOTTOMLEFT", off2, 0)
    end
    mid2:SetJustifyH(align2); mid2:Show()
end

-- =====================================================================
-- 6. MAP PRELOADER (RETAIL)
-- =====================================================================
local TARGET_MAPS = { 2393, 2437, 2395, 2444, 2413, 2405, 2274, 2248, 2214, 2215, 2255, 2277 }
if isRetail and not AUI.DelvePreloaderFrame then
    AUI.DelvePreloaderFrame = CreateFrame("Frame")
    AUI.DelvePreloaderFrame.timer = 0
    AUI.DelvePreloaderFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timer = self.timer + elapsed
        if self.timer > 30 then
            self.timer = 0
            if C_Map and C_Map.RequestPreloadMap then
                for _, mapID in ipairs(TARGET_MAPS) do C_Map.RequestPreloadMap(mapID) end
            end
        end
    end)
    C_Timer.After(3, function() 
        if C_Map and C_Map.RequestPreloadMap then
            for _, mapID in ipairs(TARGET_MAPS) do C_Map.RequestPreloadMap(mapID) end
        end
    end)
end

-- =====================================================================
-- 7. TIEFEN-SCANNER (RETAIL MIDNIGHT)
-- =====================================================================
local EXACT_MIDNIGHT_POIS = {
    [1611] = { map = 2393, name = "Collegiate Calamity" },
    [1738] = { map = 2413, name = "The Grudge Pit" },
    [1800] = { map = 2405, name = "Sunkiller Sanctum" },
    [1801] = { map = 2405, name = "Shadowguard Point" },
    [1802] = { map = 2437, name = "Atal'Aman" },
    [1803] = { map = 2413, name = "The Gulf of Memory" },
    [1804] = { map = 2395, name = "The Shadow Enclave" },
    [1805] = { map = 2437, name = "Twilight Crypts" },
    [1806] = { map = 2393, name = "The Darkway" },
    [1799] = { map = 2569, name = "Parhelion Plaza" }
}

local function ExtractStoryVariant(text)
    if not text or text == "" then return nil end
    local clean = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", "\n")
    local match = clean:match("Geschichtsvariation:%s*([^\n\r]+)")
    if not match then match = clean:match("Story Variant:%s*([^\n\r]+)") end
    if match then
        return match:match("^%s*(.-)%s*$") or match
    end
    return nil
end

local BountifulCache = { time = 0, delves = {} }
local function GetBountifulDelves()
    if not isRetail then return {} end
    if GetTime() - BountifulCache.time < 5 and #BountifulCache.delves > 0 then 
        return BountifulCache.delves 
    end
    
    local activeDelves = {}
    if C_UIWidgetManager and C_UIWidgetManager.GetAllWidgetsBySetID then
        for setId, data in pairs(EXACT_MIDNIGHT_POIS) do
            local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setId)
            if widgets and #widgets > 1 then
                local locName = FALLBACK_NAMES[data.name] or (L and L[data.name]) or data.name
                local variantText = ""
                for _, w in ipairs(widgets) do
                    local apis = {
                        "GetIconAndTextWidgetVisualizationInfo",
                        "GetStateIconAndTextWidgetVisualizationInfo",
                        "GetTextWithStateWidgetVisualizationInfo",
                        "GetTextureAndTextWidgetVisualizationInfo"
                    }
                    for _, api in ipairs(apis) do
                        if C_UIWidgetManager[api] then
                            local info = C_UIWidgetManager[api](w.widgetID)
                            if info then
                                local combinedText = (info.text or "") .. "\n" .. (info.tooltip or "")
                                local ext = ExtractStoryVariant(combinedText)
                                if ext then variantText = ext; break end
                            end
                        end
                    end
                    if variantText ~= "" then break end
                end
                
                if variantText == "" and C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap then
                    local pois = C_AreaPoiInfo.GetAreaPOIForMap(data.map)
                    if pois then
                        for _, pid in ipairs(pois) do
                            local info = C_AreaPoiInfo.GetAreaPOIInfo(data.map, pid)
                            if info and info.name and (info.name:find(locName) or info.name:find("roßzügig") or info.name:find("Bountiful")) then
                                if info.description then
                                    local ext = ExtractStoryVariant(info.description)
                                    if ext then variantText = ext; break end
                                end
                            end
                        end
                    end
                end
                
                table.insert(activeDelves, { localized = locName, variant = variantText })
            end
        end
    end
    
    table.sort(activeDelves, function(a, b) return a.localized < b.localized end)
    BountifulCache.delves = activeDelves
    BountifulCache.time = GetTime()
    return activeDelves
end

-- =====================================================================
-- 8. DYNAMISCHER WÄHRUNGSSCANNER (RETAIL)
-- =====================================================================
local function GetDynamicCurrencyIDs()
    if not isRetail then return {} end
    if AUI.CurrencyCache then return AUI.CurrencyCache end
    AUI.CurrencyCache = { Tender = 2032, Undercoin = nil, Shard = nil, Key = 3028, CrestAdv = nil, CrestVet = nil, CrestChamp = nil, CrestHero = nil, CrestMyth = nil, Catalyst = nil }
    
    local function ParseCurrencyName(curID, name)
        local n = string.lower(name)
        if string.find(n, "lorenmünze") or string.find(n, "undercoin") then AUI.CurrencyCache.Undercoin = curID
        elseif string.find(n, "kastenschlüsselsplitter") or string.find(n, "coffer key shard") then AUI.CurrencyCache.Shard = curID
        elseif string.find(n, "restaurierter kastenschlüssel") or string.find(n, "restored coffer key") then AUI.CurrencyCache.Key = curID
        elseif string.find(n, "morgenlichtwappen des abenteurers") or string.find(n, "adventurer's dawning crest") then AUI.CurrencyCache.CrestAdv = curID
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
    
    if not AUI.CurrencyCache.Undercoin or not AUI.CurrencyCache.CrestAdv then
        for i = 2800, 3600 do
            local info = C_CurrencyInfo.GetCurrencyInfo(i)
            if info and info.name then ParseCurrencyName(i, info.name) end
        end
    end
    
    if not AUI.CurrencyCache.Undercoin then AUI.CurrencyCache.Undercoin = 3243 end
    if not AUI.CurrencyCache.Shard then AUI.CurrencyCache.Shard = 3027 end
    
    return AUI.CurrencyCache
end

-- =====================================================================
-- 9. HAUPTFUNKTION: TOOLTIP AUFBAUEN
-- =====================================================================
function AUI:ShowMicroButtonTooltip(wrapper, btnName, data)
    GameTooltip:Hide()
    GameTooltip:SetOwner(wrapper, "ANCHOR_TOP", 0, 4)
    GameTooltip:ClearLines()
    
    if GameTooltip.AUI_ExtraColumns then
        for _, fs in pairs(GameTooltip.AUI_ExtraColumns) do fs:Hide(); fs:SetText("") end
    end
    
    if not GameTooltip.AUI_TopRightIcon then
        GameTooltip.AUI_TopRightIcon = GameTooltip:CreateTexture(nil, "ARTWORK")
        if not GameTooltip.AUI_TopRightIconHooked then
            GameTooltip:HookScript("OnHide", function(tip) if tip.AUI_TopRightIcon then tip.AUI_TopRightIcon:Hide() end end)
            GameTooltip.AUI_TopRightIconHooked = true
        end
    end
    GameTooltip.AUI_TopRightIcon:Hide()
    
    if not GameTooltip.AUI_GuildTabard then
        GameTooltip.AUI_GuildTabard = CreateFrame("Frame", nil, GameTooltip, "BackdropTemplate")
        local tabard = GameTooltip.AUI_GuildTabard
        tabard:SetSize(64, 64) 
        tabard:SetTemplate("Transparent")
        tabard.bg = tabard:CreateTexture(nil, "ARTWORK", nil, 1); tabard.bg:SetAllPoints()
        tabard.emblem = tabard:CreateTexture(nil, "ARTWORK", nil, 2); tabard.emblem:SetAllPoints()
        tabard.border = tabard:CreateTexture(nil, "ARTWORK", nil, 3); tabard.border:SetAllPoints()
        if not GameTooltip.AUI_GuildTabardHooked then
            GameTooltip:HookScript("OnHide", function(tip) if tip.AUI_GuildTabard then tip.AUI_GuildTabard:Hide() end end)
            GameTooltip.AUI_GuildTabardHooked = true
        end
    end
    GameTooltip.AUI_GuildTabard:Hide()

    -- -----------------------------------------------------------------
    -- KALENDER
    -- -----------------------------------------------------------------
    if btnName == "AUI_CalendarButton" then
        GameTooltip:AddLine(L["Calendar"] or "Calendar", 1, 1, 1) 
        GameTooltip:AddLine(date("%d.%m.%Y"), 1, 0.82, 0)
        
        if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
            local dailyReset = C_DateAndTime.GetSecondsUntilDailyReset()
            local weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(L["Daily Reset"] or "Daily Reset:", SecondsToTime(dailyReset, false, false, 2), 1, 0.82, 0, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Weekly Reset"] or "Weekly Reset:", SecondsToTime(weeklyReset, false, false, 2), 1, 0.82, 0, 1, 1, 1)
        end
        
        if RequestRaidInfo then RequestRaidInfo() end
        local numSaved = (GetNumSavedInstances and GetNumSavedInstances()) or 0
        local numWorldBosses = (GetNumSavedWorldBosses and GetNumSavedWorldBosses()) or 0
        local raids, dungeons, worldbosses = {}, {}, {}
        
        for idx = 1, numSaved do
            local name, _, _, _, locked, _, _, isRaid, _, diffName, numEncounters, encounterProgress = GetSavedInstanceInfo(idx)
            if locked then
                local progress = ""
                if numEncounters and numEncounters > 0 and encounterProgress then progress = " (" .. encounterProgress .. "/" .. numEncounters .. ")" end
                if isRaid then table.insert(raids, {name = name .. progress, diff = diffName or ""})
                else table.insert(dungeons, {name = name .. progress, diff = diffName or ""}) end
            end
        end
        for idx = 1, numWorldBosses do 
            local name = GetSavedWorldBossInfo(idx)
            if name then table.insert(worldbosses, name) end 
        end
        
        if #raids > 0 then 
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Saved Raids"] or "Saved Raids:", 1, 0.82, 0)
            for _, raid in ipairs(raids) do GameTooltip:AddDoubleLine(raid.name, raid.diff, 1, 1, 1, 1, 0.3, 0.3) end 
        end
        if #dungeons > 0 then 
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Saved Dungeons"] or "Saved Dungeons:", 1, 0.82, 0)
            for _, d in ipairs(dungeons) do GameTooltip:AddDoubleLine(d.name, d.diff, 1, 1, 1, 0.3, 1, 0.3) end 
        end
        if #worldbosses > 0 then 
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["World Bosses"] or "World Bosses:", 1, 0.82, 0)
            for _, wb in ipairs(worldbosses) do GameTooltip:AddDoubleLine(wb, L["Defeated"] or "Defeated", 1, 1, 1, 1, 0.6, 0) end 
        end

    -- -----------------------------------------------------------------
    -- GRUPPENSUCHE (LFD / LFG / AUI_LFGButton)
    -- -----------------------------------------------------------------
    elseif (btnName == "LFDMicroButton" or btnName == "LFGMicroButton" or btnName == "AUI_LFGButton") and (E.db.AUI.microbar.extendedLFDTooltip ~= false) then
        GameTooltip:AddLine(data.name or L["Group Finder"] or "Group Finder", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        if isRetail then
            -- RETAIL: CRESTS & CATALYST
            if C_CurrencyInfo then
                local ids = GetDynamicCurrencyIDs()
                
                if ids.Catalyst then
                    local catInfo = C_CurrencyInfo.GetCurrencyInfo(ids.Catalyst)
                    if catInfo and catInfo.quantity then
                        local iconStr = (catInfo.iconFileID and catInfo.iconFileID > 0) and (" |T" .. catInfo.iconFileID .. ":14:14|t") or ""
                        GameTooltip:AddDoubleLine(L["Catalyst Charges:"] or "Catalyst Charges:", catInfo.quantity .. iconStr, 1, 0.82, 0, 1, 1, 1)
                        GameTooltip:AddLine(" ")
                    end
                end
                
                GameTooltip:AddLine(L["PvE Crests:"] or "PvE Crests:", 1, 0.82, 0)
                AddFourColumnLine(GameTooltip, L["Type"] or "Type", L["Owned"] or "Owned", L["Earned"] or "Earned", L["Source"] or "Source", {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, 150, 250, "RIGHT", "RIGHT", 190)
                
                local crests = {
                    {id = ids.CrestMyth, name = L["Mythic"] or "Mythic", color = "ffff8000", src = L["Mythic, +9"] or "Mythic, +9"},
                    {id = ids.CrestHero, name = L["Hero"] or "Hero", color = "ffa335ee", src = L["Heroic, +4"] or "Heroic, +4"},
                    {id = ids.CrestChamp, name = L["Champion"] or "Champion", color = "ff0070dd", src = L["Normal, +2"] or "Normal, +2"},
                    {id = ids.CrestVet, name = L["Veteran"] or "Veteran", color = "ff1eff00", src = L["LFR"] or "LFR"},
                    {id = ids.CrestAdv, name = L["Adventurer"] or "Adventurer", color = "ffffffff", src = L["World Content"] or "World Content"}
                }
                
                local foundAnyCrest = false
                for _, cur in ipairs(crests) do
                    if cur.id then
                        local info = C_CurrencyInfo.GetCurrencyInfo(cur.id)
                        if info then
                            foundAnyCrest = true
                            local quantity = info.quantity or 0
                            local iconID = (info.iconFileID and info.iconFileID > 0) and info.iconFileID or 134400
                            local iconStr = iconID and (" |T" .. iconID .. ":14:14|t") or ""
                            
                            local maxQty = info.maxQuantity or 0
                            local earned = info.useTotalEarnedForMaxQty and info.totalEarned or quantity
                            
                            local midText = quantity .. iconStr
                            local rightText = ""
                            if maxQty > 0 then
                                rightText = string.format("%d / %d", earned, maxQty)
                            else
                                rightText = tostring(earned)
                            end
                            
                            AddFourColumnLine(GameTooltip, "|c" .. cur.color .. cur.name .. "|r", midText, rightText, cur.src, {1,1,1}, {1,1,1}, {1,1,1}, {1,0.82,0}, 150, 250, "RIGHT", "RIGHT", 190)
                        end
                    end
                end
                
                if not foundAnyCrest then
                    GameTooltip:AddLine(L["No Crests found."] or "No Crests found.", 0.5, 0.5, 0.5)
                end
                
                GameTooltip:AddLine(" ")
                
                GameTooltip:AddLine(L["PvP Currencies:"] or "PvP Currencies:", 1, 0.82, 0)
                AddFourColumnLine(GameTooltip, L["Type"] or "Type", L["Owned"] or "Owned", L["Earned"] or "Earned", L["Source"] or "Source", {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, 150, 250, "RIGHT", "RIGHT", 190)
                
                local pvpCurrencies = {
                    {id = 1792, name = L["Honor"] or "Honor", src = L["Unrated PvP"] or "Unrated PvP"},
                    {id = 1602, name = L["Conquest"] or "Conquest", src = L["Rated PvP"] or "Rated PvP"},
                    {id = 2123, name = L["Bloody Tokens"] or "Bloody Tokens", src = L["War Mode"] or "War Mode"}
                }
                
                for _, cur in ipairs(pvpCurrencies) do
                    local info = C_CurrencyInfo.GetCurrencyInfo(cur.id)
                    if info then
                        local quantity = info.quantity or 0
                        local iconID = (info.iconFileID and info.iconFileID > 0) and info.iconFileID or 134400
                        local iconStr = " |T" .. iconID .. ":14:14|t"
                        
                        local maxQty = info.maxQuantity or 0
                        local earned = info.useTotalEarnedForMaxQty and info.totalEarned or quantity
                        
                        local midText = quantity .. iconStr
                        local rightText = ""
                        if maxQty > 0 then
                            rightText = string.format("%d / %d", earned, maxQty)
                        else
                            rightText = tostring(earned)
                        end
                        
                        AddFourColumnLine(GameTooltip, cur.name, midText, rightText, cur.src, {1,1,1}, {1,1,1}, {1,1,1}, {1,0.82,0}, 150, 250, "RIGHT", "RIGHT", 190)
                    end
                end
            end
        else
            -- TBC CLASSIC: BADGES & MARKS
            GameTooltip:AddLine(L["TBC PvE & PvP Badges:"] or "TBC PvE & PvP Badges:", 1, 0.82, 0)
            
            local badgeName = (C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(29434)) or (GetItemInfo and GetItemInfo(29434)) or (L["Badge of Justice"] or "Badge of Justice")
            local badges = GetItemCount(29434, true) or 0
            GameTooltip:AddDoubleLine("|TInterface\\Icons\\Spell_Holy_ChampionsBond:14:14|t " .. badgeName, "|cffffffff" .. badges .. "|r", 1, 1, 1, 1, 1, 1)
            
            local honor = (GetHonorCurrency and GetHonorCurrency()) or 0
            local arena = (GetArenaCurrency and GetArenaCurrency()) or 0
            local fGroup = UnitFactionGroup("player") or "Horde"
            GameTooltip:AddDoubleLine("|TInterface\\Icons\\PVPCurrency-Honor-" .. fGroup .. ":14:14|t " .. (L["Honor Points"] or "Honor Points"), "|cff00ffd2" .. honor .. "|r", 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("|TInterface\\Icons\\Spell_Holy_ChampionsGrace:14:14|t " .. (L["Arena Points"] or "Arena Points"), "|cffff8000" .. arena .. "|r", 1, 1, 1, 1, 1, 1)
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Battleground Marks:"] or "Battleground Marks:", 1, 0.82, 0)
            local bgTokens = {
                { id = 20560, fallback = L["Warsong Gulch Mark of Honor"] or "Warsong Gulch Mark of Honor", icon = "Interface\\Icons\\INV_Misc_Rune_07" },
                { id = 20559, fallback = L["Arathi Basin Mark of Honor"] or "Arathi Basin Mark of Honor",        icon = "Interface\\Icons\\INV_Jewelry_Amulet_07" },
                { id = 20558, fallback = L["Alterac Valley Mark of Honor"] or "Alterac Valley Mark of Honor",      icon = "Interface\\Icons\\INV_Jewelry_Necklace_21" },
                { id = 29024, fallback = L["Eye of the Storm Mark of Honor"] or "Eye of the Storm Mark of Honor", icon = "Interface\\Icons\\Spell_Nature_EyeOfTheStorm" },
            }
            for _, token in ipairs(bgTokens) do
                local tName = (GetItemInfo and GetItemInfo(token.id)) or token.fallback
                local count = GetItemCount(token.id, true) or 0
                GameTooltip:AddDoubleLine("|T" .. token.icon .. ":14:14|t " .. tName, "|cffffffff" .. count .. "|r", 1, 1, 1, 1, 1, 1)
            end
        end

    -- -----------------------------------------------------------------
    -- ABENTEUERFÜHRER (NUR RETAIL MIDNIGHT)
    -- -----------------------------------------------------------------
    elseif btnName == "EJMicroButton" and isRetail and E.db.AUI.microbar.extendedAdventureTooltip then
        GameTooltip:AddLine(data.name, 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        if C_CurrencyInfo then
            GameTooltip:AddLine(L["Currencies:"] or "Currencies:", 1, 0.82, 0)
            
            local ids = GetDynamicCurrencyIDs()
            local currencies = {
                {id = ids.Tender, name = L["Trader's Tender:"] or "Trader's Tender:", fallback = 4698565},
                {id = ids.Undercoin, name = L["Bountiful Coins:"] or "Bountiful Coins:", fallback = 5932750},
                {id = ids.Shard, name = L["Coffer Key Shards:"] or "Coffer Key Shards:", fallback = 5932596, isShard = true},
                {id = ids.Key, name = L["Restored Coffer Key:"] or "Restored Coffer Key:", fallback = 5932595}
            }
            
            for _, cur in ipairs(currencies) do
                if cur.id then
                    local info = C_CurrencyInfo.GetCurrencyInfo(cur.id)
                    if info then
                        local quantity = info.quantity or 0
                        local iconID = (info.iconFileID and info.iconFileID > 0) and info.iconFileID or cur.fallback
                        local iconStr = " |T" .. iconID .. ":14:14|t"
                        
                        local valStr = tostring(quantity)
                        if cur.isShard then
                            local earned = info.quantityEarnedThisWeek or 0
                            local maxW = info.maxWeeklyQuantity or 0
                            
                            if maxW > 0 then
                                valStr = valStr .. string.format(" (|cff00ffd2%d|r/%d)", earned, maxW)
                            else
                                valStr = valStr .. string.format(" (|cff00ffd2%d|r %s)", earned, L["This Week"] or "this week")
                            end
                        end
                        GameTooltip:AddDoubleLine(cur.name, valStr .. iconStr, 1, 1, 1, 1, 1, 1)
                    end
                end
            end
            
            local activeDelves = GetBountifulDelves()
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Bountiful Delves (Active):"] or "Bountiful Delves (Active):", 1, 0.82, 0)
            
            if #activeDelves > 0 then
                for _, delve in ipairs(activeDelves) do
                    local col1 = "|A:delves-bountiful:16:16|a " .. delve.localized
                    if delve.variant ~= "" then
                        GameTooltip:AddDoubleLine(col1, "|cff00ffd2" .. delve.variant .. "|r", 1, 1, 1, 1, 1, 1)
                    else
                        GameTooltip:AddDoubleLine(col1, "|cff888888(Loading...)|r", 1, 1, 1, 1, 1, 1)
                    end
                end
            else
                GameTooltip:AddLine(L["None (or all completed)"] or "None (or all completed)", 0.5, 0.5, 0.5)
            end
            
            GameTooltip:AddLine(" ")
        end
        
        -- MIDNIGHT FRAKTIONEN
        GameTooltip:AddLine(L["Midnight Factions:"] or "Midnight Factions:", 1, 0.82, 0)
        local midnightFactions = { {id=2696,n="Amani Tribe"}, {id=2699,n="The Singularity"}, {id=2704,n="Hara'ti"}, {id=2710,n="Court of Silvermoon"} }
        for _, f in ipairs(midnightFactions) do
            local renownInfo = C_MajorFactions and C_MajorFactions.GetMajorFactionData and C_MajorFactions.GetMajorFactionData(f.id)
            if renownInfo then
                local isMaxed = C_MajorFactions.HasMaximumRenown(f.id)
                local cur = isMaxed and 1 or (renownInfo.renownReputationEarned or 0)
                local maxVal = isMaxed and 1 or (renownInfo.renownLevelThreshold or 1)
                local pBar = CreateProgressBar(cur, maxVal)
                local rLvl = (L["Renown"] or "Renown") .. " " .. (renownInfo.renownLevel or 0)
                AddThreeColumnLine(GameTooltip, renownInfo.name or f.n, rLvl, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
            else
                local repData = C_Reputation and C_Reputation.GetFactionDataByID and C_Reputation.GetFactionDataByID(f.id)
                if repData and repData.name then
                    local min = repData.currentReactionThreshold or repData.bottomValue or 0
                    local maxVal = repData.nextReactionThreshold or repData.topValue or 1
                    local cur = (repData.currentStanding or 0) - min
                    local total = maxVal - min
                    if total <= 0 then total = 1 end
                    local pBar = CreateProgressBar(cur, total)
                    local rLvl = (L["Renown"] or "Renown") .. " " .. (repData.reaction or "--")
                    AddThreeColumnLine(GameTooltip, repData.name, rLvl, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
                else 
                    GameTooltip:AddDoubleLine(f.n, "--", 1, 1, 1, 0.5, 0.5, 0.5) 
                end
            end
        end
        
        -- TIEFEN BEGLEITER
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Delve Companion:"] or "Delve Companion:", 1, 0.82, 0)
        
        local valID = 2744
        local friend = C_GossipInfo and C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(valID)
        local rankInfo = C_GossipInfo and C_GossipInfo.GetFriendshipReputationRanks and C_GossipInfo.GetFriendshipReputationRanks(valID)
        local compRep = C_Reputation and C_Reputation.GetFactionDataByID and C_Reputation.GetFactionDataByID(valID)
        
        local cName = "Valeera Sanguinar"
        if friend and friend.name then cName = friend.name end
        if compRep and compRep.name then cName = compRep.name end
        
        local cLevel = "--"
        local cBar = ""
        
        if rankInfo and rankInfo.currentLevel then cLevel = rankInfo.currentLevel
        elseif compRep and compRep.reaction then cLevel = compRep.reaction end
        
        if friend and friend.friendshipFactionID and friend.friendshipFactionID > 0 then
            cName = friend.name or cName
            if friend.nextThreshold and friend.reactionThreshold and friend.nextThreshold > friend.reactionThreshold then
                local cur = friend.standing - friend.reactionThreshold
                local maxVal = friend.nextThreshold - friend.reactionThreshold
                cBar = CreateProgressBar(cur, maxVal)
            elseif friend.standing and friend.standing > 0 then
                cBar = CreateProgressBar(1, 1)
            end
        elseif compRep then
            local min = compRep.currentReactionThreshold or compRep.bottomValue or 0
            local maxVal = compRep.nextReactionThreshold or compRep.topValue or 1
            if maxVal > min then
                local cur = compRep.currentStanding - min
                cBar = CreateProgressBar(cur, maxVal - min)
            end
        end
        local lvlStr = (L["Level"] or "Level") .. " " .. cLevel
        AddThreeColumnLine(GameTooltip, cName, lvlStr, cBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
        
        -- SAISON FORTSCHRITT
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Season Progress:"] or "Season Progress:", 1, 0.82, 0)
        local seasons = { {id=2742,n="Delves Journey"}, {id=2764,n="Prey Hunt Season"} }
        for _, s in ipairs(seasons) do
            local label = L["Renown"] or "Renown"
            local renownInfo = C_MajorFactions and C_MajorFactions.GetMajorFactionData and C_MajorFactions.GetMajorFactionData(s.id)
            local repData = C_Reputation and C_Reputation.GetFactionDataByID and C_Reputation.GetFactionDataByID(s.id)
            local name = s.n
            
            if renownInfo and renownInfo.name then name = renownInfo.name end
            if repData and repData.name then name = repData.name end
            
            if renownInfo then
                local isMaxed = C_MajorFactions.HasMaximumRenown(s.id)
                local cur = isMaxed and 1 or (renownInfo.renownReputationEarned or 0)
                local maxVal = isMaxed and 1 or (renownInfo.renownLevelThreshold or 1)
                local pBar = CreateProgressBar(cur, maxVal)
                local rLvl = label .. " " .. (renownInfo.renownLevel or 0)
                AddThreeColumnLine(GameTooltip, name, rLvl, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
            elseif repData then
                local min = repData.currentReactionThreshold or repData.bottomValue or 0
                local maxVal = repData.nextReactionThreshold or repData.topValue or 1
                local cur = (repData.currentStanding or 0) - min
                local total = maxVal - min
                if total <= 0 then total = 1 end
                local pBar = CreateProgressBar(cur, total)
                local lvlLabel = repData.reaction or "--"
                local rLvl = label .. " " .. lvlLabel
                AddThreeColumnLine(GameTooltip, name, rLvl, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
            else 
                GameTooltip:AddDoubleLine(name, "--", 1, 1, 1, 0.5, 0.5, 0.5) 
            end
        end

    -- -----------------------------------------------------------------
    -- TALENTE
    -- -----------------------------------------------------------------
    elseif (btnName == "TalentMicroButton" or btnName == "PlayerSpellsMicroButton") and E.db.AUI.microbar.extendedTalentTooltip then
        local classAtlas = "classicon-" .. string.lower(E.myclass)
        GameTooltip.AUI_TopRightIcon:SetAtlas(classAtlas)
        GameTooltip.AUI_TopRightIcon:SetSize(46, 46)
        GameTooltip.AUI_TopRightIcon:SetPoint("TOPRIGHT", GameTooltip, "TOPRIGHT", -5, -5)
        GameTooltip.AUI_TopRightIcon:Show()
        
        GameTooltip:AddDoubleLine(data.name, "             ", 1, 1, 1, 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        if isRetail then
            local specIndex = GetSpecialization()
            local specID, currentSpecName, currentSpecIcon = nil, "", ""
            if specIndex then
                local id, sName, _, icon = GetSpecializationInfo(specIndex)
                specID = id; currentSpecName = sName or ""; currentSpecIcon = icon and ("|T"..icon..":16:16:0:0:64:64:4:60:4:60|t ") or ""
                GameTooltip:AddLine((L["Current Specialization:"] or "Current Specialization:") .. " " .. currentSpecIcon .. "|cffffd100" .. currentSpecName .. "|r", 1, 1, 1)
            end
            
            if specID and C_ClassTalents and C_Traits then
                local configID = C_ClassTalents.GetLastSelectedSavedConfigID and C_ClassTalents.GetLastSelectedSavedConfigID(specID)
                if not configID and C_ClassTalents.GetActiveConfigID then configID = C_ClassTalents.GetActiveConfigID() end
                if configID then
                    local configInfo = C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
                    local buildName = configInfo and configInfo.name
                    if buildName and buildName ~= "" then GameTooltip:AddLine((L["Active Build:"] or "Active Build:") .. " |cff33ff33" .. buildName .. "|r", 1, 1, 1) end
                end
            end
            
            local lootSpecID = GetLootSpecialization and GetLootSpecialization()
            if lootSpecID then
                local lootSpecText = ""
                if lootSpecID == 0 then lootSpecText = "|cff888888" .. (L["Current Specialization"] or "Current Specialization") .. "|r (" .. currentSpecName .. ")"
                else
                    local _, name, _, icon = GetSpecializationInfoByID(lootSpecID)
                    if name then
                        local iconStr = icon and ("|T"..icon..":16:16:0:0:64:64:4:60:4:60|t ") or ""
                        lootSpecText = iconStr .. name
                    end
                end
                if lootSpecText ~= "" then GameTooltip:AddLine((L["Loot Specialization:"] or "Loot Specialization:") .. " |cffffd100" .. lootSpecText .. "|r", 1, 1, 1) end
            end
        else
            -- TBC CLASSIC TALENTE
            local numTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 3
            GameTooltip:AddLine(L["Talent Distribution (TBC):"] or "Talent Distribution (TBC):", 1, 0.82, 0)
            local totalPoints = 0
            for tab = 1, numTabs do
                local name, icon, points = GetSafeTalentTabInfo(tab)
                if name and name ~= "-" then
                    totalPoints = totalPoints + (points or 0)
                    local iconStr = icon and ("|T" .. icon .. ":16:16|t ") or ""
                    local ptsStr = string.format(L["|cffffffff%d|r Points"] or "|cffffffff%d|r Points", points or 0)
                    GameTooltip:AddDoubleLine(iconStr .. name, ptsStr, 1, 1, 1, 1, 1, 1)
                end
            end
            local unspent = (UnitCharacterPoints and UnitCharacterPoints("player")) or (GetNumUnspentTalents and GetNumUnspentTalents()) or 0
            if unspent > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(string.format(L["Available Talent Points: %d"] or "Available Talent Points: %d", unspent), 0, 1, 0)
            end
        end

    -- -----------------------------------------------------------------
    -- BERUFE
    -- -----------------------------------------------------------------
    elseif (btnName == "ProfessionMicroButton" or btnName == "SpellbookMicroButton") and E.db.AUI.microbar.extendedProfessionTooltip then
        GameTooltip:AddLine(data.name, 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        local primaryList = {}
        local secondaryList = {}
        
        if isRetail and GetProfessions then
            local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
            if prof1 then table.insert(primaryList, prof1) end
            if prof2 then table.insert(primaryList, prof2) end
            if cooking then table.insert(secondaryList, cooking) end
            if fishing then table.insert(secondaryList, fishing) end
            if archaeology then table.insert(secondaryList, archaeology) end
        elseif GetNumSkillLines and GetSkillLineInfo then
            local numSkills = GetNumSkillLines()
            for i = 1, numSkills do
                local skillName, isHeader, _, skillRank, _, skillModifier, skillMaxRank, isAbandonable = GetSkillLineInfo(i)
                if not isHeader and skillMaxRank and skillMaxRank > 0 then
                    local entry = {
                        name = skillName,
                        icon = GetClassicProfessionIcon(skillName),
                        skill = skillRank or 0,
                        max = skillMaxRank or 0,
                        mod = skillModifier or 0
                    }
                    if isAbandonable then
                        table.insert(primaryList, entry)
                    else
                        local sNameLower = string.lower(skillName or "")
                        if string.find(sNameLower, "koch") or string.find(sNameLower, "cook")
                        or string.find(sNameLower, "erste") or string.find(sNameLower, "first aid")
                        or string.find(sNameLower, "angel") or string.find(sNameLower, "fish")
                        or string.find(sNameLower, "schloss") or string.find(sNameLower, "lockpick") then
                            table.insert(secondaryList, entry)
                        end
                    end
                end
            end
        end
        
        local hasProfession = (#primaryList > 0 or #secondaryList > 0)
        
        if hasProfession then
            local currencyAdded = false
            
            if isRetail then
                local profCurrencies = {}
                local acuityCur = nil
                
                if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize then
                    for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
                        local link = C_CurrencyInfo.GetCurrencyListLink(i)
                        if link then
                            local curID = tonumber(string.match(link, "currency:(%d+)"))
                            if curID then
                                local info = C_CurrencyInfo.GetCurrencyInfo(curID)
                                if info and info.name then
                                    local n = string.lower(info.name)
                                    if string.find(n, "tatkraft") or string.find(n, "knowledge") then
                                        table.insert(profCurrencies, {name = info.name, qty = info.quantity or 0, icon = info.iconFileID})
                                    elseif string.find(n, "handwerksgeschick") or string.find(n, "acuity") then
                                        acuityCur = {name = info.name, qty = info.quantity or 0, icon = info.iconFileID}
                                    end
                                end
                            end
                        end
                    end
                end
                
                for _, cur in ipairs(profCurrencies) do
                    local iconStr = (cur.icon and cur.icon > 0) and (" |T" .. cur.icon .. ":14:14|t") or " |T134400:14:14|t"
                    GameTooltip:AddDoubleLine(cur.name, "|cffffffff" .. cur.qty .. "|r" .. iconStr, 1, 0.82, 0, 1, 1, 1)
                    currencyAdded = true
                end
                
                if acuityCur then
                    local iconStr = (acuityCur.icon and acuityCur.icon > 0) and (" |T" .. acuityCur.icon .. ":14:14|t") or " |T134400:14:14|t"
                    GameTooltip:AddDoubleLine(acuityCur.name, "|cff00ffd2" .. acuityCur.qty .. "|r" .. iconStr, 1, 0.82, 0, 1, 1, 1)
                    currencyAdded = true
                end
            end
            
            local function RenderList(list, headerText, addSpacingBefore)
                if #list == 0 then return false end
                if addSpacingBefore then GameTooltip:AddLine(" ") end
                GameTooltip:AddLine(headerText, 1, 0.82, 0)
                
                for _, item in ipairs(list) do
                    local name, icon, skillLevel, maxSkillLevel, skillModifier
                    if type(item) == "number" and GetProfessionInfo then
                        name, icon, skillLevel, maxSkillLevel, _, _, _, skillModifier = GetProfessionInfo(item)
                    elseif type(item) == "table" then
                        name = item.name
                        icon = item.icon
                        skillLevel = item.skill
                        maxSkillLevel = item.max
                        skillModifier = item.mod
                    end
                    
                    if name and maxSkillLevel and maxSkillLevel > 0 then
                        local iconStr = icon and ("|T"..icon..":16:16:0:0:64:64:4:60:4:60|t ") or ""
                        local pBar = CreateProgressBar(skillLevel, maxSkillLevel)
                        local bonusStr = (skillModifier and skillModifier > 0) and (" |cff00ff00+" .. skillModifier .. "|r") or ""
                        
                        local r, g, b = E:ColorGradient(skillLevel / math.max(maxSkillLevel, 1), 1, 0, 0, 1, 1, 0, 0, 1, 0)
                        local hexColor = string.format("ff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
                        local numberStr = string.format("|c%s%d|r%s |c%s/ %d|r", hexColor, skillLevel, bonusStr, hexColor, maxSkillLevel)
                        
                        AddThreeColumnLine(GameTooltip, iconStr .. name, numberStr, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 120)
                    end
                end
                return true
            end
            
            local hadPrimary = RenderList(primaryList, L["Primary Professions"] or "Primary Professions:", currencyAdded)
            RenderList(secondaryList, L["Secondary Professions"] or "Secondary Professions:", currencyAdded or hadPrimary)
        else
            GameTooltip:AddLine(L["No professions learned."] or "No professions learned.", 0.5, 0.5, 0.5)
        end

    -- -----------------------------------------------------------------
    -- CHARAKTER
    -- -----------------------------------------------------------------
    elseif btnName == "CharacterMicroButton" and E.db.AUI.microbar.extendedCharacterTooltip then
        local nameWithTitle = (UnitPVPName and UnitPVPName("player")) or UnitName("player")
        local factionGroup = UnitFactionGroup("player")
        
        if factionGroup == "Horde" then 
            GameTooltip.AUI_TopRightIcon:SetAtlas("bfa-landingbutton-horde-up")
        elseif factionGroup == "Alliance" then 
            GameTooltip.AUI_TopRightIcon:SetAtlas("bfa-landingbutton-alliance-up") 
        end
        GameTooltip.AUI_TopRightIcon:SetSize(56, 56)
        GameTooltip.AUI_TopRightIcon:SetPoint("TOPRIGHT", GameTooltip, "TOPRIGHT", -5, -5)
        GameTooltip.AUI_TopRightIcon:Show()
        
        local guildName, guildRankName = GetGuildInfo("player")
        local level = UnitLevel("player")
        local localizedRace = UnitRace("player")
        
        local specIndex = GetSpecialization and GetSpecialization()
        local specName, specIcon = "", ""
        if isRetail and specIndex then
            local _, name, _, icon = GetSpecializationInfo(specIndex)
            specName = name or ""
            specIcon = icon and ("|T"..icon..":16:16:0:0:64:64:4:60:4:60|t ") or ""
        end
        local localizedClass = UnitClass("player")
        local classColor = E:ClassColor(E.myclass) or {r=1, g=1, b=1}
        GameTooltip:AddDoubleLine(nameWithTitle, "          ", classColor.r, classColor.g, classColor.b, 1, 1, 1)
        if guildName then GameTooltip:AddLine("<"..guildName.."> ["..(guildRankName or "").."]", 0.4, 1, 0.4) end
        GameTooltip:AddLine("|cffffff00"..level.."|r " .. (localizedRace or ""), 1, 1, 1)
        if isRetail and specName ~= "" then
            GameTooltip:AddLine(specIcon .. specName .. " " .. localizedClass, classColor.r, classColor.g, classColor.b)
        else
            GameTooltip:AddLine(localizedClass, classColor.r, classColor.g, classColor.b)
        end
        GameTooltip:AddLine(" ")
        
        if GetAverageItemLevel then
            local _, avgItemLevelEquipped = GetAverageItemLevel()
            if avgItemLevelEquipped and avgItemLevelEquipped > 0 then
                GameTooltip:AddDoubleLine(L["Item Level:"] or "Item Level:", string.format("%.2f", avgItemLevelEquipped), 1, 1, 1, 1, 0.82, 0)
            end
        end
        
        local currentDur, maxDur = 0, 0
        for slot = 1, 18 do
            if slot ~= 4 and slot ~= 19 then 
                local rarity = GetInventoryItemQuality("player", slot)
                if rarity then totalRarity = (totalRarity or 0) + rarity; countRarity = (countRarity or 0) + 1 end
                local v1, v2 = GetInventoryItemDurability(slot)
                if v1 and v2 then currentDur = currentDur + v1; maxDur = maxDur + v2 end
            end
        end
        local durability = (maxDur > 0) and (currentDur / maxDur * 100) or 100
        local r, g, b = E:ColorGradient(durability * 0.01, 1, 0, 0, 1, 1, 0, 0, 1, 0)
        GameTooltip:AddDoubleLine(L["Durability:"] or "Durability:", string.format("%.0f%%", durability), 1, 1, 1, r, g, b)

    -- -----------------------------------------------------------------
    -- GILDE & COMMUNITYS
    -- -----------------------------------------------------------------
    elseif (btnName == "GuildMicroButton" or btnName == "SocialsMicroButton") and E.db.AUI.microbar.extendedGuildTooltip then
        GameTooltip:AddLine(L["Guild & Communities"] or "Guild & Communities", 1, 1, 1)
        
        local guildName, guildRankName = GetGuildInfo("player")
        if guildName then
            if SetLargeGuildTabardTextures and GameTooltip.AUI_GuildTabard then 
                pcall(SetLargeGuildTabardTextures, "player", GameTooltip.AUI_GuildTabard.bg, GameTooltip.AUI_GuildTabard.emblem, GameTooltip.AUI_GuildTabard.border)
                GameTooltip.AUI_GuildTabard:SetPoint("TOPRIGHT", GameTooltip, "TOPRIGHT", -5, -5)
                GameTooltip.AUI_GuildTabard:Show()
            end
            GameTooltip:AddLine("<" .. guildName .. "> |cffaaaaaa[" .. (guildRankName or "") .. "]|r", 0.4, 1, 0.4)
            GameTooltip:AddLine(" ")
            
            local motd = GetGuildRosterMOTD and GetGuildRosterMOTD()
            if motd and motd ~= "" then 
                GameTooltip:AddLine(L["MOTD:"] or "MOTD:", 1, 0.82, 0)
                GameTooltip:AddLine(motd, 1, 1, 1, true) 
            end
        else 
            GameTooltip:AddLine(data.name, 1, 1, 1) 
        end
        
        local numTotal, numOnline = (GetNumGuildMembers and GetNumGuildMembers()) or 0, 0
        if numOnline > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine((L["Online: "] or "Online: ") .. numOnline .. "/" .. numTotal, 0, 1, 0)
            
            AddFourColumnLine(GameTooltip, L["Name"] or "Name", L["Note"] or "Note", L["Zone"] or "Zone", L["Class & Level"] or "Class & Level", {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, 160, 300, "LEFT", "LEFT", 320)
            
            local HordeRaces = { ["Orc"]=true, ["Scourge"]=true, ["Tauren"]=true, ["Troll"]=true, ["BloodElf"]=true, ["Goblin"]=true, ["Nightborne"]=true, ["HighmountainTauren"]=true, ["MagharOrc"]=true, ["ZandalariTroll"]=true, ["Vulpera"]=true }
            local AllianceRaces = { ["Human"]=true, ["Dwarf"]=true, ["NightElf"]=true, ["Gnome"]=true, ["Draenei"]=true, ["Worgen"]=true, ["VoidElf"]=true, ["LightforgedDraenei"]=true, ["DarkIronDwarf"]=true, ["KulTiran"]=true, ["Mechagnome"]=true }
            
            local shown = 0
            for idx = 1, numTotal do
                if shown >= 15 then break end
                local name, _, _, level, classDisplayName, zone, note, _, isOnline, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(idx)
                
                if isOnline then
                    local classColor = E:ClassColor(class) or {r=1, g=1, b=1}
                    local nameOnly = Ambiguate and Ambiguate(name, "guild") or name
                    local factionIcon = ""
                    if guid and GetPlayerInfoByGUID then
                        local _, _, _, englishRace = GetPlayerInfoByGUID(guid)
                        if englishRace then
                            if HordeRaces[englishRace] then factionIcon = "|TInterface\\FriendsFrame\\PlusManz-Horde:14|t "
                            elseif AllianceRaces[englishRace] then factionIcon = "|TInterface\\FriendsFrame\\PlusManz-Alliance:14|t " end
                        end
                    end
                    
                    local col1 = factionIcon .. nameOnly
                    local col2 = (note and note ~= "") and note or "--"
                    if string.len(col2) > 18 then col2 = string.sub(col2, 1, 15) .. "..." end
                    
                    local col3 = (zone and zone ~= "") and zone or "--"
                    if string.len(col3) > 18 then col3 = string.sub(col3, 1, 15) .. "..." end
                    
                    local col4 = string.format("%s %2d", classDisplayName or class, level or 0)
                    
                    AddFourColumnLine(GameTooltip, col1, col2, col3, col4, {classColor.r, classColor.g, classColor.b}, {0.7,0.7,0.7}, {1,1,1}, {classColor.r, classColor.g, classColor.b}, 160, 300, "LEFT", "LEFT", 320)
                    shown = shown + 1
                end
            end
            if numOnline > 15 then GameTooltip:AddLine("... " .. (numOnline - 15) .. " " .. (L["more"] or "more"), 0.5, 0.5, 0.5) end
        end

    -- -----------------------------------------------------------------
    -- SYSTEM
    -- -----------------------------------------------------------------
    elseif btnName == "MainMenuMicroButton" and E.db.AUI.microbar.extendedSystemTooltip then
        GameTooltip:AddLine(data.name, 1, 1, 1)
        
        local _, _, latencyHome, latencyWorld = GetNetStats()
        local fps = floor(GetFramerate())
        
        local serverHr, serverMin = GetGameTime()
        local serverTime = string.format("%02d:%02d", serverHr, serverMin)
        local localTime = date("%H:%M")
        
        local sessionTime = GetTime() - (AUI.loginTime or GetTime())
        local sHours = math.floor(sessionTime / 3600)
        local sMinutes = math.floor((sessionTime % 3600) / 60)
        local sTimeText = string.format("%d h %d m", sHours, sMinutes)
        
        local masterVolume = tonumber(GetCVar("Sound_MasterVolume")) or 0
        
        UpdateAddOnMemoryUsage()
        local totalMemory = 0
        local addonList = {}
        local numAddons = (C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns()) or (GetNumAddOns and GetNumAddOns()) or 0
        
        for j = 1, numAddons do
            local mem = GetAddOnMemoryUsage(j) or 0
            totalMemory = totalMemory + mem
            local aName = (C_AddOns and C_AddOns.GetAddOnInfo and C_AddOns.GetAddOnInfo(j)) or (GetAddOnInfo and GetAddOnInfo(j))
            if aName and mem > 0 then table.insert(addonList, {name = aName, memory = mem}) end
        end
        table.sort(addonList, function(a, b) return a.memory > b.memory end)
        
        local memText = (totalMemory > 1024) and string.format("%.2f MB", totalMemory / 1024) or string.format("%.0f KB", totalMemory)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("FPS:", fps, 1, 1, 1, 0, 1, 0)
        GameTooltip:AddDoubleLine(L["Home Latency:"] or "Home Latency:", (latencyHome or 0) .. " ms", 1, 1, 1, 0, 1, 0)
        GameTooltip:AddDoubleLine(L["World Latency:"] or "World Latency:", (latencyWorld or 0) .. " ms", 1, 1, 1, 0, 1, 0)
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Local Time:"] or "Local Time:", localTime, 1, 1, 1, 0.82, 0.82, 0.82)
        GameTooltip:AddDoubleLine(L["Server Time:"] or "Server Time:", serverTime, 1, 1, 1, 0.82, 0.82, 0.82)
        GameTooltip:AddDoubleLine(L["Session:"] or "Session:", sTimeText, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["Volume:"] or "Volume:", string.format("%.0f%%", masterVolume * 100), 1, 1, 1, 0, 1, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Addon Memory:"] or "Addon Memory:", memText, 1, 0.82, 0, 0, 0.82, 1)
        for j = 1, math.min(5, #addonList) do
            local a = addonList[j]
            local aName = a.name
            if string.len(aName) > 22 then aName = string.sub(aName, 1, 19).."..." end
            local aMemText = a.memory > 1024 and string.format("%.2f MB", a.memory / 1024) or string.format("%.0f KB", a.memory)
            GameTooltip:AddDoubleLine("  " .. aName, aMemText, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
        end

    -- -----------------------------------------------------------------
    -- POST
    -- -----------------------------------------------------------------
    elseif btnName == "AUI_MailButton" then
        GameTooltip:AddLine(data.name, 1, 1, 1)
        if HasNewMail() then
            GameTooltip:AddLine(L["New Mail!"] or "New Mail!", 0, 1, 0)
            if GetLatestThreeSenders then
                local senders = { GetLatestThreeSenders() }
                if #senders > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(L["Mail from:"] or (HAVE_MAIL_FROM or "Mail from:"), 1, 0.82, 0)
                    for _, sender in ipairs(senders) do GameTooltip:AddLine(sender, 1, 1, 1) end
                end
            end
        else 
            GameTooltip:AddLine(L["No Mail!"] or "No Mail!", 1, 0, 0) 
        end

    -- -----------------------------------------------------------------
    -- STANDARD FALLBACK
    -- -----------------------------------------------------------------
    else 
        GameTooltip:AddLine(data.name, 1, 1, 1) 
    end
    
    local titleStr = _G[GameTooltip:GetName() .. "TextLeft1"]
    if titleStr and titleStr:GetText() then
        local db = E.db.AUI and E.db.AUI.microbar
        if db then
            local r, g, b = 1, 0.82, 0
            if db.titleColorMode == "CLASS" then
                local c = E:ClassColor(E.myclass) or RAID_CLASS_COLORS[E.myclass]
                if c then r, g, b = c.r, c.g, c.b end
            elseif db.titleColorMode == "CUSTOM" and db.titleColor then
                r, g, b = db.titleColor.r, db.titleColor.g, db.titleColor.b
            end
            titleStr:SetTextColor(r, g, b)
            
            local font, size, outline = titleStr:GetFont()
            if not AUI.OrigTooltipTitleSize then AUI.OrigTooltipTitleSize = size end
            local newSize = db.titleFontSize or 16
            titleStr:SetFont(font, newSize, outline)
            AUI.TooltipTitleModified = true
        end
    end
    
    StyleTooltip(GameTooltip)
    GameTooltip:Show()
end