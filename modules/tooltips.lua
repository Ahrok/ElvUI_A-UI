local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local TT = E:GetModule('Tooltip')

-- =====================================================================
-- EINGEBAUTE ÜBERSETZUNGEN
-- =====================================================================
local FALLBACK_NAMES = {
    ["Collegiate Calamity"] = "Akademischer Aufruhr",
    ["The Grudge Pit"]      = "Die Grollgrube",
    ["Sunkiller Sanctum"]   = "Sonnentötersanktum",
    ["Shadowguard Point"]   = "Schattenwachtspitze",
    ["Atal'Aman"]           = "Atal'Aman",
    ["The Gulf of Memory"]  = "Die Kluft der Erinnerung",
    ["The Shadow Enclave"]  = "Die Schattenenklave",
    ["Twilight Crypts"]     = "Gruften der Zwielichtklinge",
    ["The Darkway"]     = "Der Düsterweg",
    ["Parhelion Plaza"]     = "Parhelion Plaza"
}

-- =====================================================================
-- HILFSFUNKTION: FORTSCHRITTSBALKEN
-- =====================================================================
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
-- HILFSFUNKTION: TOOLTIP OPTIK
-- =====================================================================
local function StyleTooltip(tip)
    if not tip then return end
    local db = E.db.AUI.microbar
    
    local bgR, bgG, bgB = unpack(E.media.backdropcolor)
    if db.tooltipBackdropColorEnable then
        bgR, bgG, bgB = db.tooltipBackdropColor.r, db.tooltipBackdropColor.g, db.tooltipBackdropColor.b
    end
    local bgA = db.tooltipBackdropAlpha or 0.8
    
    local bdR, bdG, bdB = unpack(E.media.bordercolor)
    if db.tooltipBorderColorEnable then
        if db.tooltipBorderClassColor then
            local c = E:ClassColor(E.myclass) or RAID_CLASS_COLORS[E.myclass]
            if c then bdR, bdG, bdB = c.r, c.g, c.b end
        else
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
-- ZENTRALER RESET (Gegen Geister-Texte)
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
-- HILFSFUNKTIONEN FÜR TABELLEN
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
-- MAP PRELOADER
-- =====================================================================
local TARGET_MAPS = { 2393, 2437, 2395, 2444, 2413, 2405, 2274, 2248, 2214, 2215, 2255, 2277 }
if not AUI.DelvePreloaderFrame then
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
-- PERFEKTER TIEFEN-SCANNER (Die bewährte "Alles-Sauger" Widget-Logik)
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
    -- Caching (5 Sek)
    if GetTime() - BountifulCache.time < 5 and #BountifulCache.delves > 0 then 
        return BountifulCache.delves 
    end
    
    local activeDelves = {}
    
    if C_UIWidgetManager and C_UIWidgetManager.GetAllWidgetsBySetID then
        for setId, data in pairs(EXACT_MIDNIGHT_POIS) do
            local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setId)
            
            -- > 1 Widget = Tiefe ist "Großzügig" aktiv!
            if widgets and #widgets > 1 then
                local locName = FALLBACK_NAMES[data.name] or L[data.name] or data.name
                local variantText = ""
                
                -- DIE FUNKTIONIERENDE LOGIK: Lade jeden Text aus jedem Widget
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
                
                -- Sicherheits-Fallback Map POI
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
-- HILFSFUNKTION: DYNAMISCHER WÄHRUNGSSCANNER
-- =====================================================================
local function GetDynamicCurrencyIDs()
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
-- HAUPTFUNKTION: TOOLTIP AUFBAUEN
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
    
    -- KALENDER
    if btnName == "AUI_CalendarButton" then
        GameTooltip:AddLine(L["Calendar"] or "Kalender", 1, 1, 1) 
        GameTooltip:AddLine(date("%d.%m.%Y"), 1, 0.82, 0) 
        
        if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
            local dailyReset = C_DateAndTime.GetSecondsUntilDailyReset()
            local weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(L["Daily Reset"] or "Täglicher Reset:", SecondsToTime(dailyReset, false, false, 2), 1, 0.82, 0, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Weekly Reset"] or "Wöchentlicher Reset:", SecondsToTime(weeklyReset, false, false, 2), 1, 0.82, 0, 1, 1, 1)
        end
        
        RequestRaidInfo()
        local numSaved = GetNumSavedInstances()
        local numWorldBosses = GetNumSavedWorldBosses()
        local raids, dungeons, worldbosses = {}, {}, {}
        
        for idx = 1, numSaved do
            local name, _, _, _, locked, _, _, isRaid, _, diffName, numEncounters, encounterProgress = GetSavedInstanceInfo(idx)
            if locked then
                local progress = ""
                if numEncounters and numEncounters > 0 and encounterProgress then progress = " (" .. encounterProgress .. "/" .. numEncounters .. ")" end
                if isRaid then table.insert(raids, {name = name .. progress, diff = diffName})
                else table.insert(dungeons, {name = name .. progress, diff = diffName}) end
            end
        end
        for idx = 1, numWorldBosses do local name = GetSavedWorldBossInfo(idx); if name then table.insert(worldbosses, name) end end
        
        if #raids > 0 then GameTooltip:AddLine(" "); GameTooltip:AddLine(L["Saved Raids"] or "Gespeicherte Schlachtzüge", 1, 0.82, 0); for _, raid in ipairs(raids) do GameTooltip:AddDoubleLine(raid.name, raid.diff, 1, 1, 1, 1, 0.3, 0.3) end end
        if #dungeons > 0 then GameTooltip:AddLine(" "); GameTooltip:AddLine(L["Saved Dungeons"] or "Gespeicherte Instanz(en)", 1, 0.82, 0); for _, d in ipairs(dungeons) do GameTooltip:AddDoubleLine(d.name, d.diff, 1, 1, 1, 0.3, 1, 0.3) end end
        if #worldbosses > 0 then GameTooltip:AddLine(" "); GameTooltip:AddLine(L["World Bosses"] or "Weltbosse", 1, 0.82, 0); for _, wb in ipairs(worldbosses) do GameTooltip:AddDoubleLine(wb, L["Defeated"] or "Besiegt", 1, 1, 1, 1, 0.6, 0) end end
        
    -- GRUPPENSUCHE (LFD)
    elseif btnName == "LFDMicroButton" and (E.db.AUI.microbar.extendedLFDTooltip ~= false) then
        GameTooltip:AddLine(data.name or L["Group Finder"] or "Gruppensuche", 1, 1, 1); GameTooltip:AddLine(" ")
        
        if C_CurrencyInfo then
            local ids = GetDynamicCurrencyIDs()
            
            if ids.Catalyst then
                local catInfo = C_CurrencyInfo.GetCurrencyInfo(ids.Catalyst)
                if catInfo and catInfo.quantity then
                    local iconStr = (catInfo.iconFileID and catInfo.iconFileID > 0) and (" |T" .. catInfo.iconFileID .. ":14:14|t") or ""
                    GameTooltip:AddDoubleLine(L["Catalyst Charges:"] or "Katalysator-Aufladungen:", catInfo.quantity .. iconStr, 1, 0.82, 0, 1, 1, 1)
                    GameTooltip:AddLine(" ")
                end
            end
            
            GameTooltip:AddLine(L["PvE Crests:"] or "PvE Wappen:", 1, 0.82, 0)
            
            AddFourColumnLine(GameTooltip, L["Type"] or "Typ", L["Owned"] or "Besitzen", L["Earned"] or "# Verdient", L["Source"] or "Herkunft", {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, 150, 250, "RIGHT", "RIGHT", 190)
            
            local crests = {
                {id = ids.CrestMyth, name = L["Mythic"] or "Mythos", color = "ffff8000", src = L["Mythic, +9"] or "Mythisch, +9"},
                {id = ids.CrestHero, name = L["Hero"] or "Held", color = "ffa335ee", src = L["Heroic, +4"] or "Heroisch, +4"},
                {id = ids.CrestChamp, name = L["Champion"] or "Champion", color = "ff0070dd", src = L["Normal, +2"] or "Normal, +2"},
                {id = ids.CrestVet, name = L["Veteran"] or "Veteran", color = "ff1eff00", src = L["LFR"] or "Schlachtzugsbrowser"},
                {id = ids.CrestAdv, name = L["Adventurer"] or "Abenteurer", color = "ffffffff", src = L["World Content"] or "Welt-Content"}
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
                GameTooltip:AddLine(L["No Crests found."] or "Keine Wappen gefunden.", 0.5, 0.5, 0.5)
            end
            
            GameTooltip:AddLine(" ")
            
            GameTooltip:AddLine(L["PvP Currencies:"] or "PvP Währungen:", 1, 0.82, 0)
            AddFourColumnLine(GameTooltip, L["Type"] or "Typ", L["Owned"] or "Besitzen", L["Earned"] or "# Verdient", L["Source"] or "Herkunft", {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, 150, 250, "RIGHT", "RIGHT", 190)
            
            local pvpCurrencies = {
                {id = 1792, name = L["Honor"] or "Ehre", src = L["Unrated PvP"] or "Ungewertetes PvP"},
                {id = 1602, name = L["Conquest"] or "Eroberung", src = L["Rated PvP"] or "Gewertetes PvP"},
                {id = 2123, name = L["Bloody Tokens"] or "Blutige Abzeichen", src = L["War Mode"] or "Kriegsmodus"}
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
        
    -- ABENTEUERFÜHRER
    elseif btnName == "EJMicroButton" and E.db.AUI.microbar.extendedAdventureTooltip then
        GameTooltip:AddLine(data.name, 1, 1, 1); GameTooltip:AddLine(" ")
        
        if C_CurrencyInfo then
            GameTooltip:AddLine(L["Currencies:"] or "Währungen:", 1, 0.82, 0)
            
            local ids = GetDynamicCurrencyIDs()
            local currencies = {
                {id = ids.Tender, name = L["Trader's Tender:"] or "Devisen:", fallback = 4698565},
                {id = ids.Undercoin, name = L["Bountiful Coins:"] or "Lorenmünzen:", fallback = 5932750},
                {id = ids.Shard, name = L["Coffer Key Shards:"] or "Kastenschlüsselsplitter:", fallback = 5932596, isShard = true},
                {id = ids.Key, name = L["Restored Coffer Key:"] or "Restaurierter Kastenschlüssel:", fallback = 5932595}
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
                                valStr = valStr .. string.format(" (|cff00ffd2%d|r %s)", earned, L["This Week"] or "diese Woche")
                            end
                        end
                        GameTooltip:AddDoubleLine(cur.name, valStr .. iconStr, 1, 1, 1, 1, 1, 1)
                    end
                end
            end
            
            -- LORENREICHE TIEFEN
            local activeDelves = GetBountifulDelves()
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Bountiful Delves (Active):"] or "Großzügige Tiefen (Aktiv):", 1, 0.82, 0)
            
            if #activeDelves > 0 then
                for _, delve in ipairs(activeDelves) do
                    local col1 = "|A:delves-bountiful:16:16|a " .. delve.localized
                    if delve.variant ~= "" then
                        GameTooltip:AddDoubleLine(col1, "|cff00ffd2" .. delve.variant .. "|r", 1, 1, 1, 1, 1, 1)
                    else
                        GameTooltip:AddDoubleLine(col1, "|cff888888(Lädt...)|r", 1, 1, 1, 1, 1, 1)
                    end
                end
            else
                GameTooltip:AddLine(L["None (or all completed)"] or "Keine (oder alle abgeschlossen)", 0.5, 0.5, 0.5)
            end
            
            GameTooltip:AddLine(" ")
        end
        
        GameTooltip:AddLine(L["Midnight Factions:"] or "Midnight Fraktionen:", 1, 0.82, 0)
        local midnightFactions = { {id=2696,n="Amanistamm"}, {id=2699,n="Die Singularität"}, {id=2704,n="Hara'ti"}, {id=2710,n="Hof in Silbermond"} }
        for _, f in ipairs(midnightFactions) do
            local renownInfo = C_MajorFactions and C_MajorFactions.GetMajorFactionData(f.id)
            if renownInfo then
                local isMaxed = C_MajorFactions.HasMaximumRenown(f.id)
                local cur = isMaxed and 1 or renownInfo.renownReputationEarned or 0
                local maxVal = isMaxed and 1 or renownInfo.renownLevelThreshold or 1
                local pBar = CreateProgressBar(cur, maxVal)
                local rLvl = (L["Renown"] or "Ruhm") .. " " .. renownInfo.renownLevel
                AddThreeColumnLine(GameTooltip, renownInfo.name, rLvl, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
            else
                local repData = C_Reputation and C_Reputation.GetFactionDataByID(f.id)
                if repData and repData.name then
                    local min = repData.currentReactionThreshold or repData.bottomValue or 0
                    local maxVal = repData.nextReactionThreshold or repData.topValue or 1
                    local cur = repData.currentStanding - min; local total = maxVal - min
                    if total <= 0 then total = 1 end
                    local pBar = CreateProgressBar(cur, total)
                    local rLvl = (L["Renown"] or "Ruhm") .. " " .. (repData.reaction or "--")
                    AddThreeColumnLine(GameTooltip, repData.name, rLvl, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
                else 
                    GameTooltip:AddDoubleLine(f.n, "--", 1, 1, 1, 0.5, 0.5, 0.5) 
                end
            end
        end
        
        -- TIEFEN BEGLEITER (Valeera)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Delve Companion:"] or "Tiefen Begleiter:", 1, 0.82, 0)
        
        local valID = 2744
        local friend = C_GossipInfo and C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(valID)
        local rankInfo = C_GossipInfo and C_GossipInfo.GetFriendshipReputationRanks and C_GossipInfo.GetFriendshipReputationRanks(valID)
        local compRep = C_Reputation and C_Reputation.GetFactionDataByID(valID)
        
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
        local lvlStr = (L["Level"] or "Stufe") .. " " .. cLevel
        AddThreeColumnLine(GameTooltip, cName, lvlStr, cBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)

        -- SAISON FORTSCHRITT
        GameTooltip:AddLine(" "); GameTooltip:AddLine(L["Season Progress:"] or "Saison Fortschritt:", 1, 0.82, 0)
        local seasons = { {id=2742,n="Tiefen Reise"}, {id=2764,n="Beutejagd Saison"} }
        for _, s in ipairs(seasons) do
            local label = L["Renown"] or "Ruhm"
            local renownInfo = C_MajorFactions and C_MajorFactions.GetMajorFactionData(s.id)
            local repData = C_Reputation and C_Reputation.GetFactionDataByID(s.id)
            local name = s.n
            
            if renownInfo and renownInfo.name then name = renownInfo.name end
            if repData and repData.name then name = repData.name end
            
            if renownInfo then
                local isMaxed = C_MajorFactions.HasMaximumRenown(s.id)
                local cur = isMaxed and 1 or renownInfo.renownReputationEarned or 0
                local maxVal = isMaxed and 1 or renownInfo.renownLevelThreshold or 1
                local pBar = CreateProgressBar(cur, maxVal)
                local rLvl = label .. " " .. renownInfo.renownLevel
                AddThreeColumnLine(GameTooltip, name, rLvl, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
            elseif repData then
                local min = repData.currentReactionThreshold or repData.bottomValue or 0
                local maxVal = repData.nextReactionThreshold or repData.topValue or 1
                local cur = repData.currentStanding - min; local total = maxVal - min
                if total <= 0 then total = 1 end
                local pBar = CreateProgressBar(cur, total)
                local lvlLabel = repData.reaction or "--"
                local rLvl = label .. " " .. lvlLabel
                AddThreeColumnLine(GameTooltip, name, rLvl, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 100)
            else 
                GameTooltip:AddDoubleLine(name, "--", 1, 1, 1, 0.5, 0.5, 0.5) 
            end
        end
        
    -- TALENTE
    elseif (btnName == "TalentMicroButton" or btnName == "PlayerSpellsMicroButton") and E.db.AUI.microbar.extendedTalentTooltip then
        local classAtlas = "classicon-" .. string.lower(E.myclass)
        GameTooltip.AUI_TopRightIcon:SetAtlas(classAtlas)
        GameTooltip.AUI_TopRightIcon:SetSize(46, 46)
        GameTooltip.AUI_TopRightIcon:SetPoint("TOPRIGHT", GameTooltip, "TOPRIGHT", -5, -5)
        GameTooltip.AUI_TopRightIcon:Show()

        GameTooltip:AddDoubleLine(data.name, "             ", 1, 1, 1, 1, 1, 1); GameTooltip:AddLine(" "); GameTooltip:AddLine(" ")
        
        local specIndex = GetSpecialization()
        local specID, currentSpecName, currentSpecIcon = nil, "", ""
        if specIndex then
            local id, name, _, icon = GetSpecializationInfo(specIndex)
            specID = id; currentSpecName = name or ""; currentSpecIcon = icon and ("|T"..icon..":16:16:0:0:64:64:4:60:4:60|t ") or ""
            GameTooltip:AddLine(L["Current Specialization:"] .. " " .. currentSpecIcon .. "|cffffd100" .. currentSpecName .. "|r", 1, 1, 1)
        end
        
        if specID and C_ClassTalents and C_Traits then
            local configID = C_ClassTalents.GetLastSelectedSavedConfigID and C_ClassTalents.GetLastSelectedSavedConfigID(specID)
            if not configID and C_ClassTalents.GetActiveConfigID then configID = C_ClassTalents.GetActiveConfigID() end
            if configID then
                local configInfo = C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
                local buildName = configInfo and configInfo.name
                if buildName and buildName ~= "" then GameTooltip:AddLine(L["Active Build:"] .. " |cff33ff33" .. buildName .. "|r", 1, 1, 1) end
            end
        end
        
        local lootSpecID = GetLootSpecialization()
        if lootSpecID then
            local lootSpecText = ""
            if lootSpecID == 0 then lootSpecText = "|cff888888" .. L["Current Specialization"] .. "|r (" .. currentSpecName .. ")"
            else
                local _, name, _, icon = GetSpecializationInfoByID(lootSpecID)
                if name then
                    local iconStr = icon and ("|T"..icon..":16:16:0:0:64:64:4:60:4:60|t ") or ""
                    lootSpecText = iconStr .. name
                end
            end
            if lootSpecText ~= "" then GameTooltip:AddLine(L["Loot Specialization:"] .. " |cffffd100" .. lootSpecText .. "|r", 1, 1, 1) end
        end
    
    -- BERUFE
    elseif btnName == "ProfessionMicroButton" and E.db.AUI.microbar.extendedProfessionTooltip then
        GameTooltip:AddLine(data.name, 1, 1, 1); GameTooltip:AddLine(" ")
        
        local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
        local hasProfession = (prof1 or prof2 or archaeology or fishing or cooking)
        
        if hasProfession then
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
            
            local currencyAdded = false
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
            
            local function RenderProfessionList(profList, headerText, addSpacingBefore)
                local addedHeader = false
                for _, profIndex in ipairs(profList) do
                    if profIndex then
                        local name, icon, skillLevel, maxSkillLevel, _, _, _, skillModifier = GetProfessionInfo(profIndex)
                        if name and maxSkillLevel and maxSkillLevel > 0 then
                            if not addedHeader then
                                if addSpacingBefore then GameTooltip:AddLine(" ") end
                                GameTooltip:AddLine(headerText, 1, 0.82, 0)
                                addedHeader = true
                            end
                            
                            local iconStr = icon and ("|T"..icon..":16:16:0:0:64:64:4:60:4:60|t ") or ""
                            local pBar = CreateProgressBar(skillLevel, maxSkillLevel)
                            local bonusStr = (skillModifier and skillModifier > 0) and (" |cff00ff00+" .. skillModifier .. "|r") or ""
                            
                            local r, g, b = E:ColorGradient(skillLevel / math.max(maxSkillLevel, 1), 1, 0, 0, 1, 1, 0, 0, 1, 0)
                            local hexColor = string.format("ff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
                            local numberStr = string.format("|c%s%d|r%s |c%s/ %d|r", hexColor, skillLevel, bonusStr, hexColor, maxSkillLevel)
                            
                            AddThreeColumnLine(GameTooltip, iconStr .. name, numberStr, pBar, {1,1,1}, {1,1,1}, {1,1,1}, 170, "LEFT", 120)
                        end
                    end
                end
                return addedHeader
            end
            
            local hadPrimary = RenderProfessionList({prof1, prof2}, L["Primary Professions"] or "Hauptberufe:", currencyAdded)
            RenderProfessionList({cooking, fishing, archaeology}, L["Secondary Professions"] or "Nebenberufe:", currencyAdded or hadPrimary)
            
        else
            GameTooltip:AddLine(L["No professions learned."], 0.5, 0.5, 0.5)
        end
    
    -- CHARAKTER
    elseif btnName == "CharacterMicroButton" and E.db.AUI.microbar.extendedCharacterTooltip then
        local nameWithTitle = UnitPVPName("player") or UnitName("player")
        local factionGroup = UnitFactionGroup("player")
        
        if factionGroup == "Horde" then GameTooltip.AUI_TopRightIcon:SetAtlas("bfa-landingbutton-horde-up")
        elseif factionGroup == "Alliance" then GameTooltip.AUI_TopRightIcon:SetAtlas("bfa-landingbutton-alliance-up") end
        GameTooltip.AUI_TopRightIcon:SetSize(56, 56); GameTooltip.AUI_TopRightIcon:SetPoint("TOPRIGHT", GameTooltip, "TOPRIGHT", -5, -5); GameTooltip.AUI_TopRightIcon:Show()
        
        local guildName, guildRankName = GetGuildInfo("player")
        local level = UnitLevel("player")
        local localizedRace = UnitRace("player")
        
        local specIndex = GetSpecialization()
        local specName, specIcon = "", ""
        if specIndex then
            local _, name, _, icon = GetSpecializationInfo(specIndex)
            specName = name; specIcon = icon and "|T"..icon..":16:16:0:0:64:64:4:60:4:60|t " or ""
        end
        local localizedClass = UnitClass("player")
        local classColor = E:ClassColor(E.myclass) or {r=1, g=1, b=1}

        GameTooltip:AddDoubleLine(nameWithTitle, "          ", classColor.r, classColor.g, classColor.b, 1, 1, 1)
        if guildName then GameTooltip:AddLine("<"..guildName.."> ["..(guildRankName or "").."]", 0.4, 1, 0.4) end
        GameTooltip:AddLine("|cffffff00"..level.."|r " .. (localizedRace or ""), 1, 1, 1)
        GameTooltip:AddLine(specIcon .. specName .. " " .. localizedClass, classColor.r, classColor.g, classColor.b)
        GameTooltip:AddLine(" ")

        local _, avgItemLevelEquipped = GetAverageItemLevel()
        local totalRarity, countRarity = 0, 0
        for slot = 1, 18 do
            if slot ~= 4 and slot ~= 19 then 
                local rarity = GetInventoryItemQuality("player", slot)
                if rarity then totalRarity = totalRarity + rarity; countRarity = countRarity + 1 end
            end
        end
        local avgRarity = countRarity > 0 and math.floor((totalRarity / countRarity) + 0.5) or 1
        local ilvlR, ilvlG, ilvlB = GetItemQualityColor(avgRarity)
        GameTooltip:AddDoubleLine(L["Item Level:"], string.format("%.2f", avgItemLevelEquipped), 1, 1, 1, ilvlR, ilvlG, ilvlB)

        local currentDur, maxDur = 0, 0
        for slot = 1, 18 do
            local v1, v2 = GetInventoryItemDurability(slot)
            if v1 and v2 then currentDur = currentDur + v1; maxDur = maxDur + v2 end
        end
        local durability = (maxDur > 0) and (currentDur / maxDur * 100) or 100
        local r, g, b = E:ColorGradient(durability * 0.01, 1, 0, 0, 1, 1, 0, 0, 1, 0)
        GameTooltip:AddDoubleLine(L["Durability:"], string.format("%.0f%%", durability), 1, 1, 1, r, g, b)
    
    -- GILDE
    elseif btnName == "GuildMicroButton" and E.db.AUI.microbar.extendedGuildTooltip then
        GameTooltip:AddLine(L["Guild & Communities"] or "Gilde & Communitys", 1, 1, 1)
        
        local guildName, guildRankName = GetGuildInfo("player")
        if guildName then
            if SetLargeGuildTabardTextures then SetLargeGuildTabardTextures("player", GameTooltip.AUI_GuildTabard.bg, GameTooltip.AUI_GuildTabard.emblem, GameTooltip.AUI_GuildTabard.border) end
            GameTooltip.AUI_GuildTabard:SetPoint("TOPRIGHT", GameTooltip, "TOPRIGHT", -5, -5); GameTooltip.AUI_GuildTabard:Show()

            GameTooltip:AddLine("<" .. guildName .. "> |cffaaaaaa[" .. (guildRankName or "") .. "]|r", 0.4, 1, 0.4)
            GameTooltip:AddLine(" "); GameTooltip:AddLine(" ")
            
            local motd = GetGuildRosterMOTD()
            if motd and motd ~= "" then GameTooltip:AddLine(L["MOTD:"], 1, 0.82, 0); GameTooltip:AddLine(motd, 1, 1, 1, true) end
        else GameTooltip:AddLine(data.name, 1, 1, 1) end
        
        local numTotal, numOnline = GetNumGuildMembers()
        if numOnline > 0 then
            GameTooltip:AddLine(" "); GameTooltip:AddLine((L["Online: "] or "Online: ") .. numOnline .. "/" .. numTotal, 0, 1, 0)
            
            AddFourColumnLine(GameTooltip, L["Name"] or "Name", L["Note"] or "Notiz", L["Zone"] or "Zone", L["Class & Level"] or "Klasse & Level", {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, {0.8,0.8,0.8}, 160, 300, "LEFT", "LEFT", 320)
            
            local HordeRaces = { ["Orc"]=true, ["Scourge"]=true, ["Tauren"]=true, ["Troll"]=true, ["BloodElf"]=true, ["Goblin"]=true, ["Nightborne"]=true, ["HighmountainTauren"]=true, ["MagharOrc"]=true, ["ZandalariTroll"]=true, ["Vulpera"]=true }
            local AllianceRaces = { ["Human"]=true, ["Dwarf"]=true, ["NightElf"]=true, ["Gnome"]=true, ["Draenei"]=true, ["Worgen"]=true, ["VoidElf"]=true, ["LightforgedDraenei"]=true, ["DarkIronDwarf"]=true, ["KulTiran"]=true, ["Mechagnome"]=true }
            
            local shown = 0
            for idx = 1, numTotal do
                if shown >= 15 then break end
                local name, _, _, level, classDisplayName, zone, note, _, isOnline, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(idx)
                
                if isOnline then
                    local classColor = E:ClassColor(class) or {r=1, g=1, b=1}
                    local nameOnly = Ambiguate(name, "guild")
                    local factionIcon = ""
                    if guid then
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
                    
                    local col4 = string.format("%s %2d", classDisplayName, level)
                    
                    AddFourColumnLine(GameTooltip, col1, col2, col3, col4, {classColor.r, classColor.g, classColor.b}, {0.7,0.7,0.7}, {1,1,1}, {classColor.r, classColor.g, classColor.b}, 160, 300, "LEFT", "LEFT", 320)
                    
                    shown = shown + 1
                end
            end
            if numOnline > 15 then GameTooltip:AddLine("... " .. (numOnline - 15) .. " " .. (L["more"] or "weitere"), 0.5, 0.5, 0.5) end
        end
        
    -- SYSTEM
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
        for j = 1, C_AddOns.GetNumAddOns() do
            local mem = GetAddOnMemoryUsage(j) or 0
            totalMemory = totalMemory + mem
            local aName = C_AddOns.GetAddOnInfo(j)
            if aName and mem > 0 then table.insert(addonList, {name = aName, memory = mem}) end
        end
        table.sort(addonList, function(a, b) return a.memory > b.memory end)
        
        local memText = ""
        if totalMemory > 1024 then memText = string.format("%.2f MB", totalMemory / 1024)
        else memText = string.format("%.0f KB", totalMemory) end

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("FPS:", fps, 1, 1, 1, 0, 1, 0)
        GameTooltip:AddDoubleLine(L["Home Latency:"], latencyHome .. " ms", 1, 1, 1, 0, 1, 0)
        GameTooltip:AddDoubleLine(L["World Latency:"], latencyWorld .. " ms", 1, 1, 1, 0, 1, 0)
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Local Time:"], localTime, 1, 1, 1, 0.82, 0.82, 0.82)
        GameTooltip:AddDoubleLine(L["Server Time:"], serverTime, 1, 1, 1, 0.82, 0.82, 0.82)
        GameTooltip:AddDoubleLine(L["Session:"], sTimeText, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["Volume:"], string.format("%.0f%%", masterVolume * 100), 1, 1, 1, 0, 1, 0)

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Addon Memory:"], memText, 1, 0.82, 0, 0, 0.82, 1)
        for j = 1, math.min(5, #addonList) do
            local a = addonList[j]
            local aName = a.name
            if string.len(aName) > 22 then aName = string.sub(aName, 1, 19).."..." end
            local aMemText = a.memory > 1024 and string.format("%.2f MB", a.memory / 1024) or string.format("%.0f KB", a.memory)
            GameTooltip:AddDoubleLine("  " .. aName, aMemText, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
        end
        
    -- POST
    elseif btnName == "AUI_MailButton" then
        GameTooltip:AddLine(data.name, 1, 1, 1) 
        if HasNewMail() then
            GameTooltip:AddLine(L["New Mail!"], 0, 1, 0)
            local senders = { GetLatestThreeSenders() }
            if #senders > 0 then
                GameTooltip:AddLine(" "); GameTooltip:AddLine(HAVE_MAIL_FROM, 1, 0.82, 0) 
                for _, sender in ipairs(senders) do GameTooltip:AddLine(sender, 1, 1, 1) end
            end
        else GameTooltip:AddLine(L["No Mail!"], 1, 0, 0) end
        
    -- STANDARD
    else GameTooltip:AddLine(data.name, 1, 1, 1) end
    
    local titleStr = _G[GameTooltip:GetName() .. "TextLeft1"]
    if titleStr and titleStr:GetText() then
        local db = E.db.AUI.microbar
        
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
    
    StyleTooltip(GameTooltip)
    GameTooltip:Show()
end