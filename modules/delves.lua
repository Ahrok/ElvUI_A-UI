local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

local DelveTracker = CreateFrame("Frame")

-- =====================================================================
-- ENTWICKLER-MODUS (Schaltet den Tooltip-Spam im Chat stumm)
-- =====================================================================
local DEBUG_MODE = false

-- =====================================================================
-- 1. DIE MASTER-LISTE DER MIDNIGHT TIEFEN
-- =====================================================================
AUI.DelveMasterList = {
    { locName = "Akademischer Aufruhr", name = "Collegiate Calamity", zoneMapID = 2393, internalMapID = 2547, extraMapIDs = {2577, 2578}, widgetSetID = 1611 },
    { locName = "Die Grollgrube", name = "The Grudge Pit", zoneMapID = 2413, internalMapID = 2510, widgetSetID = 1738 },
    { locName = "Sonnentötersanktum", name = "Sunkiller Sanctum", zoneMapID = 2405, internalMapID = 2528, widgetSetID = 1800 },
    { locName = "Schattenwachtspitze", name = "Shadowguard Point", zoneMapID = 2405, internalMapID = 2506, widgetSetID = 1801 },
    { locName = "Atal'Aman", name = "Atal'Aman", zoneMapID = 2437, internalMapID = 2536, widgetSetID = 1802 },
    { locName = "Die Kluft der Erinnerung", name = "The Gulf of Memory", zoneMapID = 2413, internalMapID = 2505, widgetSetID = 1803 },
    { locName = "Die Schattenenklave", name = "The Shadow Enclave", zoneMapID = 2395, internalMapID = 2502, widgetSetID = 1804 },
    { locName = "Gruften der Zwielichtklinge", name = "Twilight Crypts", zoneMapID = 2437, internalMapID = 2503, widgetSetID = 1805 },
    { locName = "Der Düsterweg", name = "The Darkway", zoneMapID = 2393, internalMapID = 2525, widgetSetID = 1806 },
    { locName = "Parhelion Plaza", name = "Parhelion Plaza", zoneMapID = 2569, internalMapID = 2545, widgetSetID = 1799 }
}

-- Status "isCompleted" verhindert Endlos-Neustarts am Ende
local currentDelve = { isActive = false, name = "", tier = 1, startTime = 0, deaths = 0, started = false, isCompleted = false }
local fallbackTimer = 0

-- Ticket-System für das Looten
local PendingPin = nil
local lastTooltipName = ""
local ActiveMapLookup = nil

local function BuildMapToDelve()
    local lookup = {}
    for _, d in ipairs(AUI.DelveMasterList) do
        lookup[d.internalMapID] = d.locName
        if d.extraMapIDs then
            for _, eID in ipairs(d.extraMapIDs) do
                lookup[eID] = d.locName
            end
        end
    end
    return lookup
end

-- =====================================================================
-- 2. DATENBANK INITIALISIEREN
-- =====================================================================
function AUI:InitDelveDatabase()
    if not _G["ElvUI_AUIDB"] then _G["ElvUI_AUIDB"] = {} end
    local DB = _G["ElvUI_AUIDB"]
    DB.Delves = DB.Delves or {}
    
    DB.Delves.TotalRuns = DB.Delves.TotalRuns or 0
    DB.Delves.TotalFails = DB.Delves.TotalFails or 0
    DB.Delves.TotalDeaths = DB.Delves.TotalDeaths or 0
    DB.Delves.TotalCurios = DB.Delves.TotalCurios or 0
    DB.Delves.TotalBanners = DB.Delves.TotalBanners or 0
    
    DB.Delves.RunsPerTier = DB.Delves.RunsPerTier or {}
    DB.Delves.DelveDetails = DB.Delves.DelveDetails or {}
    DB.Delves.RunsPerSpec = DB.Delves.RunsPerSpec or {}
    DB.Delves.RunsPerCharacter = DB.Delves.RunsPerCharacter or {}
    DB.Delves.BestTimes = DB.Delves.BestTimes or {}
    DB.Delves.LastFail = DB.Delves.LastFail or { delveName = "Keine", tier = 0, date = "-", charName = "-", spec = "-" }
    DB.Delves.History = DB.Delves.History or {}
    DB.Delves.MapPins = DB.Delves.MapPins or {}
    DB.Delves.StoryCache = DB.Delves.StoryCache or {} 
    
    if DB.Delves.DiscoveredMaps then DB.Delves.DiscoveredMaps = nil end
    
    AUI.DelveDB = DB.Delves
end

local BLACKLIST_MAPS = { [2274] = true, [2248] = true, [2214] = true, [2215] = true, [2255] = true, [2213] = true, [2339] = true, [947] = true }

local function ValidateAndLearnMap(mapID, d, isScenarioConfirmed)
    if not mapID or not d then return false end
    if BLACKLIST_MAPS[mapID] then return false end
    
    if mapID == d.internalMapID then return true end
    if d.extraMapIDs then
        for _, eID in ipairs(d.extraMapIDs) do
            if mapID == eID then return true end
        end
    end
    
    local g1 = C_Map.GetMapGroupID(mapID)
    local g2 = C_Map.GetMapGroupID(d.internalMapID)
    if g1 and g2 and g1 == g2 then return true end
    
    if isScenarioConfirmed then
        d.extraMapIDs = d.extraMapIDs or {}
        table.insert(d.extraMapIDs, mapID)
        
        if AUI.DelveDB then
            AUI.DelveDB.DiscoveredMaps = AUI.DelveDB.DiscoveredMaps or {}
            AUI.DelveDB.DiscoveredMaps[d.locName] = AUI.DelveDB.DiscoveredMaps[d.locName] or {}
            local known = false
            for _, v in ipairs(AUI.DelveDB.DiscoveredMaps[d.locName]) do
                if v == mapID then known = true; break end
            end
            if not known then 
                table.insert(AUI.DelveDB.DiscoveredMaps[d.locName], mapID) 
                if DEBUG_MODE then
                    print("|cffff0000A-UI (Debug):|r Neue Tiefen-Ebene erkannt und gelernt! (Map-ID: " .. mapID .. ")")
                end
            end
        end
        return true
    end
    return false
end

-- =====================================================================
-- 3. DER TOOLTIP-SPION & DIE "LAUF & LOOT" MAP-PIN LOGIK
-- =====================================================================
local function PlaceMapPin(pType, name)
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    local targetMapID = nil

    if BLACKLIST_MAPS[mapID] then
        for _, d in ipairs(AUI.DelveMasterList) do
            if d.locName == currentDelve.name then
                mapID = d.internalMapID
                pos = C_Map.GetPlayerMapPosition(mapID, "player")
                break
            end
        end
    end

    for _, d in ipairs(AUI.DelveMasterList) do
        if d.locName == currentDelve.name then
            if ValidateAndLearnMap(mapID, d, true) then targetMapID = mapID end
            
            if not targetMapID then
                pos = C_Map.GetPlayerMapPosition(d.internalMapID, "player")
                if pos then 
                    targetMapID = d.internalMapID 
                elseif d.extraMapIDs then
                    for _, eID in ipairs(d.extraMapIDs) do
                        pos = C_Map.GetPlayerMapPosition(eID, "player")
                        if pos then targetMapID = eID; break end
                    end
                end
            end
            break
        end
    end

    if targetMapID and pos and AUI.DelveDB then
        local db = AUI.DelveDB
        if not db.MapPins[targetMapID] then db.MapPins[targetMapID] = {} end
        
        local isDuplicate = false
        for _, pin in ipairs(db.MapPins[targetMapID]) do
            if pin.type == pType then
                local dx = pin.x - pos.x
                local dy = pin.y - pos.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist < 0.02 then isDuplicate = true; break end
            end
        end
        
        if not isDuplicate then
            table.insert(db.MapPins[targetMapID], { x = pos.x, y = pos.y, type = pType, name = name })
            
            if pType == "Curio" then db.TotalCurios = (db.TotalCurios or 0) + 1
            elseif pType == "Banner" then db.TotalBanners = (db.TotalBanners or 0) + 1 end
            
            print("|cff00ffd2A-UI:|r Erfolgreich auf der Karte markiert: " .. name)
            
            if AUI_DelveInfoFrame and AUI_DelveInfoFrame:IsShown() and AUI.CurrentMapID == targetMapID then
                AUI:DrawDelveMap(targetMapID, currentDelve.name)
                AUI:UpdateDelveUI()
            end
            if AUI.UpdateWorldMapPins then AUI:UpdateWorldMapPins() end
        end
    end
end

GameTooltip:HookScript("OnShow", function(self)
    if not currentDelve.isActive then return end
    
    local text = _G[self:GetName().."TextLeft1"]
    if text then
        local name = text:GetText()
        
        -- Sicherheits-Check gegen "Secret Strings" von Blizzard
        local isSafe = pcall(function() return name == "" end)
        
        if isSafe and name and type(name) == "string" and name ~= lastTooltipName then
            lastTooltipName = name
            local success, lowerName = pcall(string.lower, name)
            if success and lowerName then
                local pType = nil
                
                if string.find(lowerName, "banner") then pType = "Banner"
                elseif string.find(lowerName, "kuriosit") or string.find(lowerName, "curio") then pType = "Curio"
                elseif string.find(lowerName, "checkpoint") then pType = "Checkpoint" end
                
                if pType then
                    -- Ticket-System ist wieder aktiv: Wir merken uns das Objekt für 5 Minuten!
                    PendingPin = { type = pType, name = name, time = GetTime() }
                    if DEBUG_MODE then
                        print("|cff00ffd2A-UI (Debug):|r " .. name .. " anvisiert! (Wartet auf Interaktion)")
                    end
                end
            end
        end
    end
end)

GameTooltip:HookScript("OnHide", function() lastTooltipName = "" end)

-- =====================================================================
-- 4. DER EVENT-TRACKER (Optimierte Namens-Erkennung)
-- =====================================================================
-- =====================================================================
-- 4. DER EVENT-TRACKER 
-- =====================================================================
local function FindDelveTier()
    if C_UIWidgetManager and C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo then
        local delveInfo = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(6183)
        if delveInfo and delveInfo.tierText then
            local t = tostring(delveInfo.tierText):match("%d+")
            if t then return tonumber(t) end
        end
        for i = 1, 10000 do
            local info = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(i)
            if info and info.tierText then
                local t = tostring(info.tierText):match("%d+")
                if t then return tonumber(t) end
            end
        end
    end
    return nil
end

local function UpdateDelveStatus()
    if not AUI.DelveMasterList then return end
    if not ActiveMapLookup then ActiveMapLookup = BuildMapToDelve() end
    
    local mapID = C_Map.GetBestMapForUnit("player")
    local inScenario = C_Scenario.IsInScenario()
    
    local isDelveMap = false
    local delveName = ""

    -- 1. Eindeutige Map-ID (100% Trefferquote)
    if mapID then
        if ActiveMapLookup[mapID] then
            isDelveMap = true
            delveName = ActiveMapLookup[mapID]
        elseif AUI.DelveDB and AUI.DelveDB.DiscoveredMaps then
            for dName, mapList in pairs(AUI.DelveDB.DiscoveredMaps) do
                for _, mID in ipairs(mapList) do
                    if mID == mapID then
                        isDelveMap = true
                        delveName = dName
                        break
                    end
                end
                if isDelveMap then break end
            end
        end
    end
    
    -- 2. Fallback über Szenario-Name
    if inScenario and not isDelveMap then
        local scenName = select(1, C_Scenario.GetInfo())
        if scenName and type(scenName) == "string" then
            local sNameLower = string.lower(scenName)
            for _, d in ipairs(AUI.DelveMasterList) do
                local locStrip = string.gsub(string.lower(d.locName), "^die ", "")
                locStrip = string.gsub(locStrip, "^der ", "")
                locStrip = string.gsub(locStrip, "^das ", "")
                local engStrip = string.gsub(string.lower(d.name), "^the ", "")
                
                if string.find(sNameLower, locStrip, 1, true) or string.find(sNameLower, engStrip, 1, true) then
                    isDelveMap = true
                    delveName = d.locName
                    
                    if mapID and not BLACKLIST_MAPS[mapID] then
                        if not AUI.DelveDB.DiscoveredMaps then AUI.DelveDB.DiscoveredMaps = {} end
                        if not AUI.DelveDB.DiscoveredMaps[d.locName] then AUI.DelveDB.DiscoveredMaps[d.locName] = {} end
                        table.insert(AUI.DelveDB.DiscoveredMaps[d.locName], mapID)
                        ActiveMapLookup[mapID] = d.locName 
                    end
                    break
                end
            end
        end
    end
    
    if isDelveMap then
        if not currentDelve.isActive or currentDelve.name ~= delveName then
            currentDelve.isActive = true
            currentDelve.name = delveName
            currentDelve.startTime = GetTime()
            currentDelve.deaths = 0
            currentDelve.tier = 1
            currentDelve.started = false
            currentDelve.isCompleted = false
            PendingPin = nil
            fallbackTimer = 0
        end
    else
        currentDelve.isActive = false
        currentDelve.started = false
        currentDelve.isCompleted = false
        PendingPin = nil
    end
end

C_Timer.NewTicker(2.0, function()
    if not currentDelve.isActive then
        UpdateDelveStatus()
    end
    
    if currentDelve.isActive and not currentDelve.started and not currentDelve.isCompleted then
        local stepName = select(1, C_Scenario.GetStepInfo())
        if stepName and stepName ~= "" then
            local t = FindDelveTier()
            if t then
                currentDelve.tier = t
                currentDelve.started = true
                print("|cff00ffd2A-UI:|r Tracker für " .. currentDelve.name .. " (Stufe " .. currentDelve.tier .. ") gestartet!")
                fallbackTimer = 0
            else
                fallbackTimer = fallbackTimer + 1
                if fallbackTimer > 15 then
                    currentDelve.started = true
                    print("|cff00ffd2A-UI:|r Tracker für " .. currentDelve.name .. " (Stufe 1) gestartet!")
                    fallbackTimer = 0
                end
            end
        end
    end
end)

local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED" then
        if event == "PLAYER_ENTERING_WORLD" then AUI:InitDelveDatabase() end
        C_Timer.After(1.0, UpdateDelveStatus)
        
    -- INTERAKTIONS-TRIGGERS (Mob-Loot entfernt, nur noch bombensichere Events)
    elseif event == "GOSSIP_SHOW" or event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" or event == "SCENARIO_CRITERIA_UPDATE" then
        if currentDelve.isActive and PendingPin then
            -- Wir geben dir jetzt satte 300 Sekunden (5 Min) Zeit, falls ein Kampf dazwischenkommt!
            if (GetTime() - PendingPin.time < 300) then 
                PlaceMapPin(PendingPin.type, PendingPin.name) 
            end
            PendingPin = nil
        end
        
    -- ZAUBER-TRIGGERS (Banner, Kuriositäten, Quest-Objekte)
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if unitTarget == "player" and currentDelve.isActive and PendingPin then
            if (GetTime() - PendingPin.time < 300) then
                local sName = nil
                
                -- Versuch 1: Echte Spell-ID abrufen
                if spellID and spellID > 0 then
                    sName = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID))
                    if not sName and GetSpellInfo then sName = GetSpellInfo(spellID) end
                end
                
                -- Versuch 2: Den Text direkt vom Ladebalken ablesen
                if not sName or sName == "" then
                    sName = (UnitCastInfo and UnitCastInfo("player")) or (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and select(1, UnitChannelInfo("player")))
                end
                
                if sName then
                    local lowS = string.lower(sName)
                    local lowPin = string.lower(PendingPin.name)
                    -- Rigorose Filter für alle denkbaren Blizzard-Interaktionswörter
                    if string.find(lowS, "öffnen") or string.find(lowS, "open") or string.find(lowS, "plündern") or string.find(lowS, "loot") or string.find(lowS, "entriegeln") or string.find(lowS, "unlock") or string.find(lowS, "untersuchen") or string.find(lowS, "investigate") or string.find(lowS, "befreien") or string.find(lowS, "free") or string.find(lowS, "benutzen") or string.find(lowS, "use") or string.find(lowS, "aktivieren") or string.find(lowS, "activate") or string.find(lowS, "interagieren") or string.find(lowS, "interact") or string.find(lowS, "banner") or string.find(lowPin, lowS) then
                        PlaceMapPin(PendingPin.type, PendingPin.name)
                        PendingPin = nil
                    end
                else
                    -- Notfall-Rettung, falls Blizzard uns eine leere Zauber-ID übermittelt
                    PlaceMapPin(PendingPin.type, PendingPin.name)
                    PendingPin = nil
                end
            else
                PendingPin = nil
            end
        end
        
    elseif event == "PLAYER_DEAD" then
        if currentDelve.isActive and currentDelve.started and not currentDelve.isCompleted and AUI.DelveDB then
            currentDelve.deaths = currentDelve.deaths + 1
            AUI.DelveDB.TotalDeaths = (AUI.DelveDB.TotalDeaths or 0) + 1
        end
        
    elseif event == "SCENARIO_COMPLETED" then
        if currentDelve.isActive and currentDelve.started and not currentDelve.isCompleted and AUI.DelveDB then
            local db = AUI.DelveDB
            local runTime = GetTime() - currentDelve.startTime
            local specIndex = GetSpecialization()
            local specName = specIndex and select(2, GetSpecializationInfo(specIndex)) or "Unbekannt"
            local charName = UnitName("player") .. "-" .. GetRealmName()
            
            db.TotalRuns = (db.TotalRuns or 0) + 1
            db.RunsPerTier[currentDelve.tier] = (db.RunsPerTier[currentDelve.tier] or 0) + 1
            db.RunsPerSpec[specName] = (db.RunsPerSpec[specName] or 0) + 1
            db.RunsPerCharacter[charName] = (db.RunsPerCharacter[charName] or 0) + 1
            
            if not db.DelveDetails[currentDelve.name] then db.DelveDetails[currentDelve.name] = { runs = 0, success = 0, fails = 0, maxTier = 0 } end
            db.DelveDetails[currentDelve.name].runs = db.DelveDetails[currentDelve.name].runs + 1
            db.DelveDetails[currentDelve.name].success = db.DelveDetails[currentDelve.name].success + 1
            if currentDelve.tier > (db.DelveDetails[currentDelve.name].maxTier or 0) then db.DelveDetails[currentDelve.name].maxTier = currentDelve.tier end
            
            if not db.BestTimes[currentDelve.name] then db.BestTimes[currentDelve.name] = {} end
            local oldTime = db.BestTimes[currentDelve.name][currentDelve.tier]
            if not oldTime or runTime < oldTime then db.BestTimes[currentDelve.name][currentDelve.tier] = runTime end
            
            local mins = math.floor(runTime / 60)
            local secs = math.floor(runTime % 60)
            print("|cff00ffd2A-UI:|r Tiefe erfolgreich! Zeit: " .. mins .. "m " .. secs .. "s")
            
            currentDelve.isCompleted = true
        end
    end
end

DelveTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
DelveTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
DelveTracker:RegisterEvent("ZONE_CHANGED_INDOORS")
DelveTracker:RegisterEvent("ZONE_CHANGED")
DelveTracker:RegisterEvent("PLAYER_DEAD")
DelveTracker:RegisterEvent("SCENARIO_COMPLETED")
DelveTracker:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
DelveTracker:RegisterEvent("GOSSIP_SHOW")
DelveTracker:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
DelveTracker:RegisterEvent("UNIT_SPELLCAST_START")
DelveTracker:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
DelveTracker:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
DelveTracker:SetScript("OnEvent", OnEvent)

-- =====================================================================
-- 5. LIVE-DATEN-SCANNER
-- =====================================================================
local function ExtractStoryVariant(text)
    if not text or text == "" then return nil end
    local clean = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", "\n")
    local match = clean:match("Geschichtsvariation:%s*([^\n\r]+)")
    if not match then match = clean:match("Story Variant:%s*([^\n\r]+)") end
    if match then return match:match("^%s*(.-)%s*$") or match end
    return nil
end

function AUI:ScanLiveDelves()
    local bountifulList = {}
    local normalList = {}
    
    if not AUI.DelveDB then AUI:InitDelveDatabase() end

    for _, delve in ipairs(AUI.DelveMasterList) do
        local isBountiful = false
        local currentStory = "Standard"
        local currentAtlas = nil 

        if C_AreaPoiInfo then
            local pois = C_AreaPoiInfo.GetAreaPOIForMap(delve.zoneMapID)
            if pois then
                for _, poiID in ipairs(pois) do
                    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(delve.zoneMapID, poiID)
                    if poiInfo and poiInfo.name then
                        local cleanName = poiInfo.name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                        
                        if string.find(cleanName, delve.locName, 1, true) or string.find(cleanName, delve.name, 1, true) then
                            if poiInfo.atlasName then
                                currentAtlas = poiInfo.atlasName
                                if string.find(string.lower(poiInfo.atlasName), "bountiful") then isBountiful = true end
                            end
                            if string.find(string.lower(cleanName), "großzügig") or string.find(string.lower(cleanName), "bountiful") then
                                isBountiful = true
                            end
                            if currentStory == "Standard" and poiInfo.description and poiInfo.description ~= "" then
                                local ext = ExtractStoryVariant(poiInfo.description)
                                if ext then currentStory = ext end
                            end
                            
                            if currentStory == "Standard" and poiInfo.tooltipWidgetSetID then
                                local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(poiInfo.tooltipWidgetSetID)
                                if widgets then
                                    for _, w in ipairs(widgets) do
                                        local apis = { "GetIconAndTextWidgetVisualizationInfo", "GetStateIconAndTextWidgetVisualizationInfo", "GetTextWithStateWidgetVisualizationInfo", "GetTextureAndTextWidgetVisualizationInfo" }
                                        for _, api in ipairs(apis) do
                                            if C_UIWidgetManager[api] then
                                                local info = C_UIWidgetManager[api](w.widgetID)
                                                if info then
                                                    local combinedText = (info.text or "") .. "\n" .. (info.tooltip or "")
                                                    local ext = ExtractStoryVariant(combinedText)
                                                    if ext then currentStory = ext; break end
                                                end
                                            end
                                        end
                                        if currentStory ~= "Standard" then break end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if C_UIWidgetManager and C_UIWidgetManager.GetAllWidgetsBySetID then
            local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(delve.widgetSetID)
            if widgets then
                for _, w in ipairs(widgets) do
                    local apis = { "GetIconAndTextWidgetVisualizationInfo", "GetStateIconAndTextWidgetVisualizationInfo", "GetTextWithStateWidgetVisualizationInfo", "GetTextureAndTextWidgetVisualizationInfo" }
                    for _, api in ipairs(apis) do
                        if C_UIWidgetManager[api] then
                            local info = C_UIWidgetManager[api](w.widgetID)
                            if info then
                                local combinedText = (info.text or "") .. "\n" .. (info.tooltip or "")
                                if string.find(string.lower(combinedText), "bountiful") or string.find(string.lower(combinedText), "großzügig") then
                                    isBountiful = true
                                end
                                if currentStory == "Standard" then
                                    local ext = ExtractStoryVariant(combinedText)
                                    if ext then currentStory = ext end
                                end
                            end
                        end
                    end
                end
                if #widgets > 1 then isBountiful = true end
            end
        end

        if currentStory == "Standard" and AUI.DelveDB.StoryCache[delve.locName] then
            currentStory = AUI.DelveDB.StoryCache[delve.locName]
        elseif currentStory ~= "Standard" then
            AUI.DelveDB.StoryCache[delve.locName] = currentStory
        end

        local statsText = "Max. Stufe: 0  |  Versuche: 0  |  Erfolge: 0  |  Fails: 0"
        if AUI.DelveDB and AUI.DelveDB.DelveDetails[delve.locName] then
            local dStats = AUI.DelveDB.DelveDetails[delve.locName]
            statsText = string.format("Max. Stufe: %d  |  Versuche: %d  |  Erfolge: %d  |  Fails: %d", dStats.maxTier or 0, dStats.runs or 0, dStats.success or 0, dStats.fails or 0)
        end

        local data = { name = delve.locName, story = currentStory, stats = statsText, mapID = delve.internalMapID, atlas = currentAtlas }
        if isBountiful then table.insert(bountifulList, data) else table.insert(normalList, data) end
    end

    table.sort(bountifulList, function(a, b) return a.name < b.name end)
    table.sort(normalList, function(a, b) return a.name < b.name end)
    return bountifulList, normalList
end

-- =====================================================================
-- 6. DAS FRONTEND
-- =====================================================================
local UI = CreateFrame("Frame", "AUI_DelveInfoFrame", E.UIParent, "BackdropTemplate")
UI:SetSize(1250, 750) 
UI:SetPoint("CENTER", E.UIParent, "CENTER", 0, 0)
UI:SetTemplate("Transparent")
UI:SetMovable(true)
UI:EnableMouse(true)
UI:RegisterForDrag("LeftButton")
UI:SetScript("OnDragStart", UI.StartMoving)
UI:SetScript("OnDragStop", UI.StopMovingOrSizing)
UI:SetFrameStrata("HIGH")
UI:Hide()

tinsert(UISpecialFrames, "AUI_DelveInfoFrame")

UI.Title = UI:CreateFontString(nil, "OVERLAY")
UI.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 18, "SHADOWOUTLINE")
UI.Title:SetPoint("TOP", UI, "TOP", 0, -15)
UI.Title:SetText("|cff00ffd2A-UI|r Tiefen-Dashboard")
UI.Title:SetTextColor(1, 1, 1)

UI.CloseButton = CreateFrame("Button", nil, UI, "UIPanelCloseButton")
UI.CloseButton:SetPoint("TOPRIGHT", UI, "TOPRIGHT", -4, -4)
E:GetModule("Skins"):HandleCloseButton(UI.CloseButton)

UI.TopLine = CreateFrame("Frame", nil, UI, "BackdropTemplate")
UI.TopLine:SetSize(1210, 2)
UI.TopLine:SetPoint("TOP", UI.Title, "BOTTOM", 0, -10)
UI.TopLine:SetTemplate("Default")

UI.VerticalLine = CreateFrame("Frame", nil, UI, "BackdropTemplate")
UI.VerticalLine:SetSize(2, 680) 
UI.VerticalLine:SetPoint("TOPLEFT", UI, "TOPLEFT", 470, -50)
UI.VerticalLine:SetTemplate("Default")

UI.TabStats = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
UI.TabStats:SetSize(120, 26)
UI.TabStats:SetPoint("TOPLEFT", UI, "TOPLEFT", 20, -50)
UI.TabStats:SetText("Statistiken")
E:GetModule("Skins"):HandleButton(UI.TabStats)

UI.TabMap = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
UI.TabMap:SetSize(120, 26)
UI.TabMap:SetPoint("LEFT", UI.TabStats, "RIGHT", 10, 0)
UI.TabMap:SetText("Karte")
E:GetModule("Skins"):HandleButton(UI.TabMap)

UI.StatsContainer = CreateFrame("Frame", nil, UI)
UI.StatsContainer:SetPoint("TOPLEFT", UI.VerticalLine, "TOPRIGHT", 10, 0)
UI.StatsContainer:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", -20, 20)

UI.MapContainer = CreateFrame("Frame", nil, UI)
UI.MapContainer:SetPoint("TOPLEFT", UI.VerticalLine, "TOPRIGHT", 10, 0)
UI.MapContainer:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", -20, 20)
UI.MapContainer:Hide()

local function SetActiveTab(tabName)
    if tabName == "STATS" then
        UI.MapContainer:Hide()
        UI.StatsContainer:Show()
        UI.TabStats:SetAlpha(1)
        UI.TabMap:SetAlpha(0.5)
    else
        UI.StatsContainer:Hide()
        UI.MapContainer:Show()
        UI.TabMap:SetAlpha(1)
        UI.TabStats:SetAlpha(0.5)
    end
end
UI.TabStats:SetScript("OnClick", function() SetActiveTab("STATS") end)
UI.TabMap:SetScript("OnClick", function() SetActiveTab("MAP") end)
SetActiveTab("STATS")

local function CreateDelveLine(parent)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(420, 32) 
    
    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(1, 1, 1, 0.05) 

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
    row.icon = icon 

    local nameStr = row:CreateFontString(nil, "OVERLAY")
    nameStr:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
    nameStr:SetPoint("LEFT", icon, "RIGHT", 10, 0) 
    nameStr:SetText("Lade Daten...") 

    local storyStr = row:CreateFontString(nil, "OVERLAY")
    storyStr:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    storyStr:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)
    storyStr:SetTextColor(0.6, 0.6, 0.6)
    storyStr:SetText("-")

    local statsStr = row:CreateFontString(nil, "OVERLAY")
    statsStr:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    statsStr:SetPoint("TOPLEFT", nameStr, "BOTTOMLEFT", 0, -2)
    statsStr:SetTextColor(0.5, 0.5, 0.5)
    statsStr:SetText("-")

    row:SetScript("OnClick", function(self)
        if self.mapID then
            SetActiveTab("MAP")
            if AUI.OpenDelveMap then AUI:OpenDelveMap(self.mapID, self.delveRawName) end
        end
    end)

    return nameStr, storyStr, statsStr, row
end

UI.RightSpalte = {}
UI.BountifulTitle = UI:CreateFontString(nil, "OVERLAY")
UI.BountifulTitle:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 16, "NONE")
UI.BountifulTitle:SetPoint("TOPLEFT", UI, "TOPLEFT", 20, -90)
UI.BountifulTitle:SetText("|cffffd100Großzügige Tiefen (Heute)|r")

UI.BountifulEmptyText = UI:CreateFontString(nil, "OVERLAY")
UI.BountifulEmptyText:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
UI.BountifulEmptyText:SetText("|cff888888Keine vorhanden / Alle abgeschlossen|r")
UI.BountifulEmptyText:Hide()

for i = 1, 4 do
    local nStr, sStr, stStr, row = CreateDelveLine(UI)
    UI.RightSpalte["Bountiful"..i] = { name = nStr, story = sStr, stats = stStr, frame = row }
end

UI.NormalTitle = UI:CreateFontString(nil, "OVERLAY")
UI.NormalTitle:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 16, "NONE")
UI.NormalTitle:SetText("Weitere Tiefen")

for i = 1, 10 do 
    local nStr, sStr, stStr, row = CreateDelveLine(UI)
    UI.RightSpalte["Normal"..i] = { name = nStr, story = sStr, stats = stStr, frame = row }
end

-- =====================================================================
-- KARTEN PINS TOGGLE (Verknüpft mit ElvUI Datenbank)
-- =====================================================================
UI.PinToggle = CreateFrame("CheckButton", nil, UI, "ChatConfigCheckButtonTemplate")
UI.PinToggle:SetPoint("BOTTOMLEFT", UI, "BOTTOMLEFT", 20, 20)

if E.db.AUI and E.db.AUI.map and E.db.AUI.map.delvePins ~= nil then
    UI.PinToggle:SetChecked(E.db.AUI.map.delvePins)
else
    UI.PinToggle:SetChecked(true)
end

UI.PinToggleText = UI.PinToggle:CreateFontString(nil, "OVERLAY")
UI.PinToggleText:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
UI.PinToggleText:SetPoint("LEFT", UI.PinToggle, "RIGHT", 5, 0)
UI.PinToggleText:SetText("Kuriositäten & Banner auf der Karte anzeigen")
UI.PinToggleText:SetTextColor(1, 1, 1)
E:GetModule("Skins"):HandleCheckBox(UI.PinToggle)

UI.PinToggle:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    
    if E.db.AUI and E.db.AUI.map then
        E.db.AUI.map.delvePins = isChecked
    end
    
    if UI.MapContainer:IsShown() and AUI.CurrentMapID then
        AUI:DrawDelveMap(AUI.CurrentMapID, UI.MapContainer.Title:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
    if AUI.UpdateWorldMapPins then AUI:UpdateWorldMapPins() end
end)

local function CreateStatLine(parent, yOffset, labelText)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    label:SetText(labelText)
    label:SetTextColor(0.8, 0.8, 0.8)

    local value = parent:CreateFontString(nil, "OVERLAY")
    value:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
    value:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -40, yOffset) 
    value:SetText("-")
    value:SetTextColor(1, 1, 1)

    return value
end

UI.Stats = {}
--UI.MainTitle:SetText("|cff00ff00Allgemeine Daten|r")
UI.Stats.TotalRuns = CreateStatLine(UI.StatsContainer, -20, "Erfolgreiche Durchläufe (Gesamt):")
UI.Stats.TotalFails = CreateStatLine(UI.StatsContainer, -45, "Fehlgeschlagene Durchläufe:")
UI.Stats.TotalDeaths = CreateStatLine(UI.StatsContainer, -70, "Tode in Tiefen (Accountweit):")

UI.Stats.TotalCurios = CreateStatLine(UI.StatsContainer, -95, "Gefundene Kuriositäten:")
UI.Stats.TotalBanners = CreateStatLine(UI.StatsContainer, -120, "Gefundene Banner:")

UI.TopLine2 = CreateFrame("Frame", nil, UI.StatsContainer, "BackdropTemplate")
UI.TopLine2:SetSize(700, 2)
UI.TopLine2:SetPoint("TOPLEFT", UI.StatsContainer, "TOPLEFT", 20, -145)
UI.TopLine2:SetTemplate("Default")

UI.Stats.TopChar = CreateStatLine(UI.StatsContainer, -165, "Bester Charakter (Meiste Runs):")
UI.Stats.TopSpec = CreateStatLine(UI.StatsContainer, -190, "Meistgespielte Spezialisierung:")
UI.Stats.MostPlayedDelve = CreateStatLine(UI.StatsContainer, -215, "Meistgespielte Tiefe:")
UI.Stats.HighestTier = CreateStatLine(UI.StatsContainer, -240, "Höchste abgeschlossene Stufe:")

UI.TopLine3 = CreateFrame("Frame", nil, UI.StatsContainer, "BackdropTemplate")
UI.TopLine3:SetSize(700, 2)
UI.TopLine3:SetPoint("TOPLEFT", UI.StatsContainer, "TOPLEFT", 20, -275)
UI.TopLine3:SetTemplate("Default")

UI.BestRunTitle = UI.StatsContainer:CreateFontString(nil, "OVERLAY")
UI.BestRunTitle:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 16, "NONE")
UI.BestRunTitle:SetPoint("TOP", UI.TopLine3, "BOTTOM", 0, -15)
UI.BestRunTitle:SetText("|cff00ff00Persönliche Bestzeit|r")

UI.Stats.BestDelveName = CreateStatLine(UI.StatsContainer, -325, "Tiefe & Stufe:")
UI.Stats.BestDelveTime = CreateStatLine(UI.StatsContainer, -350, "Zeit:")

UI.TopLine4 = CreateFrame("Frame", nil, UI.StatsContainer, "BackdropTemplate")
UI.TopLine4:SetSize(700, 2)
UI.TopLine4:SetPoint("TOPLEFT", UI.StatsContainer, "TOPLEFT", 20, -385)
UI.TopLine4:SetTemplate("Default")

UI.FailTitle = UI.StatsContainer:CreateFontString(nil, "OVERLAY")
UI.FailTitle:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 16, "NONE")
UI.FailTitle:SetPoint("TOP", UI.TopLine4, "BOTTOM", 0, -15)
UI.FailTitle:SetText("|cffff0000Letzter Fehlschlag|r")

UI.Stats.LastFailDelve = CreateStatLine(UI.StatsContainer, -435, "Tiefe & Stufe:")
UI.Stats.LastFailChar = CreateStatLine(UI.StatsContainer, -460, "Charakter & Spec:")
UI.Stats.LastFailDate = CreateStatLine(UI.StatsContainer, -485, "Datum:")

-- =====================================================================
-- ELVUI-STYLED FORTSCHRITTSBUTTONS
-- =====================================================================
local function CreateElvUIStyledButton(parent, width, height, anchor, pointX, pointY, iconTex, titleText, r, g, b)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetPoint(anchor, parent, anchor, pointX, pointY)
    btn:SetTemplate("Transparent")
    
    btn.Highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.Highlight:SetAllPoints()
    btn.Highlight:SetColorTexture(1, 1, 1, 0.05)
    
    btn.IconBG = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    btn.IconBG:SetSize(height - 8, height - 8)
    btn.IconBG:SetPoint("LEFT", btn, "LEFT", 4, 0)
    btn.IconBG:SetTemplate("Default")
    
    btn.Icon = btn.IconBG:CreateTexture(nil, "ARTWORK")
    btn.Icon:SetAllPoints()
    btn.Icon:SetTexture(iconTex)
    btn.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    btn.Title = btn:CreateFontString(nil, "OVERLAY")
    btn.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
    btn.Title:SetPoint("TOPLEFT", btn.IconBG, "TOPRIGHT", 10, -2)
    btn.Title:SetText(titleText)
    
    btn.StatusBG = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    btn.StatusBG:SetSize(width - height - 16, 14)
    btn.StatusBG:SetPoint("BOTTOMLEFT", btn.IconBG, "BOTTOMRIGHT", 10, 0)
    btn.StatusBG:SetTemplate("Default")
    
    btn.Status = CreateFrame("StatusBar", nil, btn.StatusBG)
    btn.Status:SetPoint("TOPLEFT", 1, -1)
    btn.Status:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.Status:SetStatusBarTexture(E.media.normTex)
    btn.Status:SetStatusBarColor(r, g, b, 0.9)
    
    btn.Text = btn.Status:CreateFontString(nil, "OVERLAY")
    btn.Text:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    btn.Text:SetPoint("CENTER", btn.Status, "CENTER", 0, 0)
    btn.Text:SetText("Lade Daten...")
    
    return btn
end

UI.JourneyBtn = CreateElvUIStyledButton(UI.StatsContainer, 340, 46, "BOTTOMLEFT", 20, 20, "Interface\\Icons\\INV_Misc_Map_01", "|cffffd100Tiefenreise (Saison 1)|r", 1, 0.6, 0)
UI.CompanionBtn = CreateElvUIStyledButton(UI.StatsContainer, 340, 46, "BOTTOMRIGHT", -20, 20, "Interface\\Icons\\Achievement_Character_Bloodelf_Female", "|cff00ff00Valeera Sanguinar|r", 0.2, 0.8, 0.2)

UI.JourneyBtn:SetScript("OnClick", function()
    if not C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
        C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
    end
    if not EncounterJournal or not EncounterJournal:IsShown() then
        ToggleEncounterJournal()
    end
    -- Öffnet gezielt Tab 1 ("Reisen"), wo die Tiefen zu finden sind
    if EncounterJournal and EncounterJournal_SetTab then
        EncounterJournal_SetTab(EncounterJournal, 1)
    end
end)

UI.CompanionBtn:SetScript("OnClick", function()
    if not C_AddOns.IsAddOnLoaded("Blizzard_DelvesCompanionConfiguration") then
        C_AddOns.LoadAddOn("Blizzard_DelvesCompanionConfiguration")
    end
    if DelvesCompanionConfigurationFrame then
        if DelvesCompanionConfigurationFrame:IsShown() then HideUIPanel(DelvesCompanionConfigurationFrame) 
        else ShowUIPanel(DelvesCompanionConfigurationFrame) end
    end
end)


-- =====================================================================
-- 8. RECHTE SPALTE (TAB 2): DAS KARTEN-PANEL
-- =====================================================================
UI.MapContainer.Title = UI.MapContainer:CreateFontString(nil, "OVERLAY")
UI.MapContainer.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 18, "SHADOWOUTLINE")
UI.MapContainer.Title:SetPoint("TOP", UI.MapContainer, "TOP", 0, 0)
UI.MapContainer.Title:SetText("|cffffd100Karte auswählen...|r")

UI.MapContainer.Viewport = CreateFrame("Frame", nil, UI.MapContainer)
UI.MapContainer.Viewport:SetPoint("TOPLEFT", UI.MapContainer, "TOPLEFT", 10, -30)
UI.MapContainer.Viewport:SetPoint("BOTTOMRIGHT", UI.MapContainer, "BOTTOMRIGHT", -10, 40)
UI.MapContainer.Viewport:SetClipsChildren(true) 
UI.MapContainer.Viewport:EnableMouse(true)
UI.MapContainer.Viewport:RegisterForDrag("LeftButton")

UI.MapContainer.Canvas = CreateFrame("Frame", nil, UI.MapContainer.Viewport)
UI.MapContainer.Canvas:SetPoint("CENTER")
UI.MapContainer.Canvas:SetMovable(true)

UI.MapContainer.Viewport:SetScript("OnDragStart", function() UI.MapContainer.Canvas:StartMoving() end)
UI.MapContainer.Viewport:SetScript("OnDragStop", function() UI.MapContainer.Canvas:StopMovingOrSizing() end)

UI.MapContainer.Viewport:SetScript("OnMouseWheel", function(self, delta)
    local currentScale = UI.MapContainer.Canvas:GetScale()
    local newScale = currentScale + (delta * 0.1)
    if newScale < 0.2 then newScale = 0.2 end
    if newScale > 4.0 then newScale = 4.0 end
    UI.MapContainer.Canvas:SetScale(newScale)
end)

UI.MapContainer.Tiles = {}
UI.MapContainer.Pins = {}

UI.MapContainer.FloorText = UI.MapContainer:CreateFontString(nil, "OVERLAY")
UI.MapContainer.FloorText:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
UI.MapContainer.FloorText:SetPoint("BOTTOM", UI.MapContainer, "BOTTOM", 0, 10)
UI.MapContainer.FloorText:SetText("Ebene 1")

UI.MapContainer.PrevButton = CreateFrame("Button", nil, UI.MapContainer, "UIPanelButtonTemplate")
UI.MapContainer.PrevButton:SetSize(30, 30)
UI.MapContainer.PrevButton:SetPoint("RIGHT", UI.MapContainer.FloorText, "LEFT", -15, 0)
UI.MapContainer.PrevButton:SetText("<")
E:GetModule("Skins"):HandleButton(UI.MapContainer.PrevButton)

UI.MapContainer.NextButton = CreateFrame("Button", nil, UI.MapContainer, "UIPanelButtonTemplate")
UI.MapContainer.NextButton:SetSize(30, 30)
UI.MapContainer.NextButton:SetPoint("LEFT", UI.MapContainer.FloorText, "RIGHT", 15, 0)
UI.MapContainer.NextButton:SetText(">")
E:GetModule("Skins"):HandleButton(UI.MapContainer.NextButton)

local currentMapGroup = {}
local currentFloorIndex = 1

function AUI:DrawDelveMap(mapID, delveName)
    if not mapID then return end
    AUI.CurrentMapID = mapID
    UI.MapContainer.Title:SetText("|cffffd100" .. (delveName or "Karte") .. "|r")

    UI.MapContainer.Canvas:ClearAllPoints()
    UI.MapContainer.Canvas:SetPoint("CENTER")

    for _, t in ipairs(UI.MapContainer.Tiles) do t:Hide() end
    for _, p in ipairs(UI.MapContainer.Pins) do p:Hide() end 

    local layers = C_Map.GetMapArtLayers(mapID)
    if not layers or not layers[1] then return end
    local layer = layers[1]
    local textures = C_Map.GetMapArtLayerTextures(mapID, 1)
    
    if not textures or #textures == 0 then return end

    UI.MapContainer.Canvas:SetSize(layer.layerWidth, layer.layerHeight)

    local scaleX = UI.MapContainer.Viewport:GetWidth() / layer.layerWidth
    local scaleY = UI.MapContainer.Viewport:GetHeight() / layer.layerHeight
    local scale = math.min(scaleX, scaleY) * 1.25
    UI.MapContainer.Canvas:SetScale(scale)

    local numCols = math.ceil(layer.layerWidth / layer.tileWidth)

    for i, fileDataID in ipairs(textures) do
        local row = math.floor((i - 1) / numCols)
        local col = (i - 1) % numCols
        local offsetX = col * layer.tileWidth
        local offsetY = row * layer.tileHeight

        local tex = UI.MapContainer.Tiles[i]
        if not tex then
            tex = UI.MapContainer.Canvas:CreateTexture(nil, "BACKGROUND")
            UI.MapContainer.Tiles[i] = tex
        end
        
        if type(fileDataID) == "table" and fileDataID.fileDataIDs then
            tex:SetTexture(fileDataID.fileDataIDs[1])
        else
            tex:SetTexture(fileDataID)
        end
        
        tex:SetSize(layer.tileWidth, layer.tileHeight)
        tex:SetPoint("TOPLEFT", UI.MapContainer.Canvas, "TOPLEFT", offsetX, -offsetY)
        tex:Show()
    end
    
    if UI.PinToggle:GetChecked() and AUI.DelveDB and AUI.DelveDB.MapPins and AUI.DelveDB.MapPins[mapID] then
        local pinIndex = 1
        for dbIndex, pinData in ipairs(AUI.DelveDB.MapPins[mapID]) do
            local pin = UI.MapContainer.Pins[pinIndex]
            if not pin then
                pin = CreateFrame("Button", nil, UI.MapContainer.Canvas)
                pin:SetSize(18, 18)
                pin:RegisterForClicks("RightButtonUp")
                
                pin.Icon = pin:CreateTexture(nil, "OVERLAY")
                pin.Icon:SetAllPoints()
                
                pin.Glow = pin:CreateTexture(nil, "BACKGROUND")
                pin.Glow:SetSize(30, 30)
                pin.Glow:SetPoint("CENTER", pin, "CENTER", 0, 0)
                pin.Glow:SetTexture("Interface\\AddOns\\ElvUI\\Core\\Media\\Textures\\GlowTex")
                
                pin:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(self.pinName, 1, 0.82, 0)
                    GameTooltip:AddLine("<Shift + Rechtsklick> zum Löschen", 1, 0.2, 0.2)
                    GameTooltip:Show()
                end)
                pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
                
                pin:SetScript("OnClick", function(self, button)
                    if button == "RightButton" and IsShiftKeyDown() then
                        table.remove(AUI.DelveDB.MapPins[self.mapID], self.dbIndex)
                        AUI:DrawDelveMap(self.mapID, UI.MapContainer.Title:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
                        if AUI.UpdateWorldMapPins then AUI:UpdateWorldMapPins() end
                        GameTooltip:Hide()
                    end
                end)
                
                UI.MapContainer.Pins[pinIndex] = pin
            end
            
            pin.mapID = mapID
            pin.dbIndex = dbIndex
            
            if pinData.type == "Banner" then
                pin.Icon:SetTexture("Interface\\Icons\\inv_banner_03")
                pin.Glow:SetVertexColor(1, 0.8, 0, 0.8) 
            elseif pinData.type == "Checkpoint" then
                pin.Icon:SetTexture("Interface\\Icons\\poi-graveyard")
                pin.Glow:SetVertexColor(1, 1, 1, 0.8)
            else
                pin.Icon:SetTexture("Interface\\Icons\\inv_misc_bag_08") 
                pin.Glow:SetVertexColor(0, 1, 0.8, 0.8) 
            end
            pin.pinName = pinData.name or pinData.type
            
            local px = pinData.x * layer.layerWidth
            local py = -(pinData.y * layer.layerHeight)
            pin:SetPoint("CENTER", UI.MapContainer.Canvas, "TOPLEFT", px, py)
            pin:Show()
            pinIndex = pinIndex + 1
        end
    end
end

function AUI:OpenDelveMap(mapID, delveName)
    currentMapGroup = {}
    currentFloorIndex = 1

    local overrideGroups = {
        [2547] = { {mapID=2577, name="Eingang"}, {mapID=2578, name="Treppenhaus"}, {mapID=2547, name="Hauptbereich"} },
        [2577] = { {mapID=2577, name="Eingang"}, {mapID=2578, name="Treppenhaus"}, {mapID=2547, name="Hauptbereich"} },
        [2578] = { {mapID=2577, name="Eingang"}, {mapID=2578, name="Treppenhaus"}, {mapID=2547, name="Hauptbereich"} }
    }

    if overrideGroups[mapID] then
        currentMapGroup = overrideGroups[mapID]
    else
        local groupID = C_Map.GetMapGroupID(mapID)
        if groupID then
            local members = C_Map.GetMapGroupMembersInfo(groupID)
            if members and #members > 0 then
                currentMapGroup = members
            end
        end
    end
    
    if #currentMapGroup == 0 then
        for _, d in ipairs(AUI.DelveMasterList) do
            if d.locName == delveName or d.internalMapID == mapID then
                table.insert(currentMapGroup, {mapID = d.internalMapID, name = "Ebene 1"})
                if d.extraMapIDs then
                    for idx, eID in ipairs(d.extraMapIDs) do
                        local isDup = false
                        for _, e in ipairs(currentMapGroup) do if e.mapID == eID then isDup = true; break end end
                        if not isDup then table.insert(currentMapGroup, {mapID = eID, name = "Ebene " .. (#currentMapGroup + 1)}) end
                    end
                end
                break
            end
        end
    end
    
    if #currentMapGroup == 0 then
        table.insert(currentMapGroup, {mapID = mapID, name = delveName})
    end

    for i, m in ipairs(currentMapGroup) do
        if m.mapID == mapID then
            currentFloorIndex = i
            break
        end
    end

    if #currentMapGroup > 1 then
        UI.MapContainer.PrevButton:Show()
        UI.MapContainer.NextButton:Show()
        UI.MapContainer.FloorText:Show()
        UI.MapContainer.FloorText:SetText(currentMapGroup[currentFloorIndex].name or ("Ebene " .. currentFloorIndex))
    else
        UI.MapContainer.PrevButton:Hide()
        UI.MapContainer.NextButton:Hide()
        UI.MapContainer.FloorText:Hide()
    end

    AUI:DrawDelveMap(mapID, delveName)
end

UI.MapContainer.PrevButton:SetScript("OnClick", function()
    if currentFloorIndex > 1 then
        currentFloorIndex = currentFloorIndex - 1
        local m = currentMapGroup[currentFloorIndex]
        UI.MapContainer.FloorText:SetText(m.name or ("Ebene " .. currentFloorIndex))
        AUI:DrawDelveMap(m.mapID, UI.MapContainer.Title:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
end)

UI.MapContainer.NextButton:SetScript("OnClick", function()
    if currentFloorIndex < #currentMapGroup then
        currentFloorIndex = currentFloorIndex + 1
        local m = currentMapGroup[currentFloorIndex]
        UI.MapContainer.FloorText:SetText(m.name or ("Ebene " .. currentFloorIndex))
        AUI:DrawDelveMap(m.mapID, UI.MapContainer.Title:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
end)

-- =====================================================================
-- 9. DIE NORMALE BLIZZARD WELTKARTE (M)
-- =====================================================================
local WorldMapPins = {}

function AUI:UpdateWorldMapPins()
    for _, p in ipairs(WorldMapPins) do p:Hide() end
    
    local showPins = true
    if E.db.AUI and E.db.AUI.map and E.db.AUI.map.delvePins ~= nil then
        showPins = E.db.AUI.map.delvePins
    else
        showPins = UI.PinToggle:GetChecked()
    end
    
    if not showPins or not WorldMapFrame:IsShown() then return end

    local mapID = WorldMapFrame:GetMapID()
    if not mapID or not AUI.DelveDB or not AUI.DelveDB.MapPins or not AUI.DelveDB.MapPins[mapID] then return end

    local canvas = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child or WorldMapFrame:GetCanvas()
    if not canvas then return end

    local canvasWidth = canvas:GetWidth()
    local canvasHeight = canvas:GetHeight()

    local pinIndex = 1
    for dbIndex, pinData in ipairs(AUI.DelveDB.MapPins[mapID]) do
        local pin = WorldMapPins[pinIndex]
        if not pin then
            pin = CreateFrame("Button", nil, canvas)
            pin:SetSize(16, 16)
            
            pin:RegisterForClicks("RightButtonUp")
            pin:SetFrameStrata("DIALOG")
            pin:SetFrameLevel(5000)
            
            pin.Icon = pin:CreateTexture(nil, "OVERLAY")
            pin.Icon:SetAllPoints()
            pin.Glow = pin:CreateTexture(nil, "BACKGROUND")
            pin.Glow:SetSize(26, 26)
            pin.Glow:SetPoint("CENTER")
            pin.Glow:SetTexture("Interface\\AddOns\\ElvUI\\Core\\Media\\Textures\\GlowTex")
            
            pin:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.pinName, 1, 0.82, 0)
                GameTooltip:AddLine("<Shift + Rechtsklick> zum Löschen", 1, 0.2, 0.2)
                GameTooltip:Show()
            end)
            pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            pin:SetScript("OnClick", function(self, button)
                if button == "RightButton" and IsShiftKeyDown() then
                    table.remove(AUI.DelveDB.MapPins[self.mapID], self.dbIndex)
                    AUI:UpdateWorldMapPins()
                    if AUI_DelveInfoFrame and AUI_DelveInfoFrame:IsShown() and AUI.CurrentMapID == self.mapID then
                        AUI:DrawDelveMap(self.mapID, UI.MapContainer.Title:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
                    end
                    GameTooltip:Hide()
                end
            end)
            
            WorldMapPins[pinIndex] = pin
        end
        
        pin:SetParent(canvas)
        pin.mapID = mapID
        pin.dbIndex = dbIndex

        if pinData.type == "Banner" then
            pin.Icon:SetTexture("Interface\\Icons\\inv_banner_03")
            pin.Glow:SetVertexColor(1, 0.8, 0, 0.8)
        elseif pinData.type == "Checkpoint" then
            pin.Icon:SetTexture("Interface\\Icons\\poi-graveyard")
            pin.Glow:SetVertexColor(1, 1, 1, 0.8)
        else
            pin.Icon:SetTexture("Interface\\Icons\\inv_misc_bag_08")
            pin.Glow:SetVertexColor(0, 1, 0.8, 0.8)
        end
        pin.pinName = pinData.name or pinData.type

        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT", pinData.x * canvasWidth, -(pinData.y * canvasHeight))
        pin:Show()
        pinIndex = pinIndex + 1
    end
end

hooksecurefunc(WorldMapFrame, "OnMapChanged", function() AUI:UpdateWorldMapPins() end)
WorldMapFrame:HookScript("OnShow", function() AUI:UpdateWorldMapPins() end)
WorldMapFrame:HookScript("OnHide", function()
    for _, p in ipairs(WorldMapPins) do p:Hide() end
end)

-- =====================================================================
-- 10. IMPORT & EXPORT
-- =====================================================================
UI.SyncButton = CreateFrame("Button", nil, UI.MapContainer, "UIPanelButtonTemplate")
UI.SyncButton:SetSize(120, 26)
UI.SyncButton:SetPoint("BOTTOMRIGHT", UI.MapContainer, "BOTTOMRIGHT", -10, 0)
UI.SyncButton:SetText("Pins Teilen")
E:GetModule("Skins"):HandleButton(UI.SyncButton)

local SyncFrame = CreateFrame("Frame", "AUI_DelveSyncFrame", UI, "BackdropTemplate")
SyncFrame:SetSize(400, 250)
SyncFrame:SetPoint("CENTER", UI, "CENTER", 0, 0)
SyncFrame:SetTemplate("Transparent")
SyncFrame:SetFrameStrata("DIALOG")
SyncFrame:Hide()

SyncFrame.Title = SyncFrame:CreateFontString(nil, "OVERLAY")
SyncFrame.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 16, "NONE")
SyncFrame.Title:SetPoint("TOP", 0, -10)
SyncFrame.Title:SetText("Pins Importieren / Exportieren")

SyncFrame.Close = CreateFrame("Button", nil, SyncFrame, "UIPanelCloseButton")
SyncFrame.Close:SetPoint("TOPRIGHT", -4, -4)
E:GetModule("Skins"):HandleCloseButton(SyncFrame.Close)

SyncFrame.ScrollBG = CreateFrame("Frame", nil, SyncFrame, "BackdropTemplate")
SyncFrame.ScrollBG:SetTemplate("Default")
SyncFrame.ScrollBG:SetPoint("TOPLEFT", 15, -40)
SyncFrame.ScrollBG:SetPoint("BOTTOMRIGHT", -35, 50)

SyncFrame.Scroll = CreateFrame("ScrollFrame", "AUI_DelveSyncScrollFrame", SyncFrame.ScrollBG, "UIPanelScrollFrameTemplate")
SyncFrame.Scroll:SetPoint("TOPLEFT", 5, -5)
SyncFrame.Scroll:SetPoint("BOTTOMRIGHT", -25, 5)

if AUI_DelveSyncScrollFrameScrollBar and E:GetModule("Skins").HandleScrollBar then
    E:GetModule("Skins"):HandleScrollBar(AUI_DelveSyncScrollFrameScrollBar)
end

SyncFrame.EditBox = CreateFrame("EditBox", nil, SyncFrame.Scroll)
SyncFrame.EditBox:SetMultiLine(true)
SyncFrame.EditBox:SetFontObject(ChatFontNormal)
SyncFrame.EditBox:SetWidth(320)
SyncFrame.EditBox:SetAutoFocus(false)
SyncFrame.EditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
SyncFrame.Scroll:SetScrollChild(SyncFrame.EditBox)

SyncFrame.ScrollBG:SetScript("OnMouseDown", function() SyncFrame.EditBox:SetFocus() end)

SyncFrame.BtnExport = CreateFrame("Button", nil, SyncFrame, "UIPanelButtonTemplate")
SyncFrame.BtnExport:SetSize(100, 24)
SyncFrame.BtnExport:SetPoint("BOTTOMLEFT", 20, 10)
SyncFrame.BtnExport:SetText("Exportieren")
E:GetModule("Skins"):HandleButton(SyncFrame.BtnExport)

SyncFrame.BtnImport = CreateFrame("Button", nil, SyncFrame, "UIPanelButtonTemplate")
SyncFrame.BtnImport:SetSize(100, 24)
SyncFrame.BtnImport:SetPoint("BOTTOMRIGHT", -20, 10)
SyncFrame.BtnImport:SetText("Importieren")
E:GetModule("Skins"):HandleButton(SyncFrame.BtnImport)

UI.SyncButton:SetScript("OnClick", function()
    SyncFrame.EditBox:SetText("")
    SyncFrame:Show()
end)

SyncFrame.BtnExport:SetScript("OnClick", function()
    local str = ""
    for mapID, pins in pairs(AUI.DelveDB.MapPins) do
        for _, pin in ipairs(pins) do
            local n = pin.name:gsub(":", ""):gsub("|", "")
            str = str .. mapID .. ":" .. pin.x .. ":" .. pin.y .. ":" .. pin.type .. ":" .. n .. "|"
        end
    end
    SyncFrame.EditBox:SetText(str)
    SyncFrame.EditBox:HighlightText()
    print("|cff00ffd2A-UI:|r Pins erfolgreich exportiert. Nutze STRG+C zum Kopieren!")
end)

SyncFrame.BtnImport:SetScript("OnClick", function()
    local str = SyncFrame.EditBox:GetText()
    if not str or str == "" then return end
    local count = 0
    for mapStr in string.gmatch(str, "([^|]+)") do
        local mapID, x, y, pType, name = string.match(mapStr, "(%d+):([%d%.]+):([%d%.]+):([^:]+):([^:]+)")
        if mapID and x and y and pType and name then
            mapID = tonumber(mapID); x = tonumber(x); y = tonumber(y)
            if not AUI.DelveDB.MapPins[mapID] then AUI.DelveDB.MapPins[mapID] = {} end
            
            local isDuplicate = false
            for _, pin in ipairs(AUI.DelveDB.MapPins[mapID]) do
                if pin.type == pType then
                    local dx = pin.x - x
                    local dy = pin.y - y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < 0.02 then isDuplicate = true; break end
                end
            end
            if not isDuplicate then
                table.insert(AUI.DelveDB.MapPins[mapID], {x = x, y = y, type = pType, name = name})
                count = count + 1
            end
        end
    end
    print("|cff00ffd2A-UI:|r " .. count .. " neue Pins erfolgreich importiert!")
    SyncFrame:Hide()
    if UI.MapContainer:IsShown() and AUI.CurrentMapID then
        AUI:DrawDelveMap(AUI.CurrentMapID, UI.MapContainer.Title:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
    if AUI.UpdateWorldMapPins then AUI:UpdateWorldMapPins() end
end)


-- =====================================================================
-- 11. UI UPDATEN & ANZEIGEN
-- =====================================================================
local function GetTopFromTable(t)
    local topName, topVal = "-", 0
    if not t then return topName end
    for name, val in pairs(t) do
        if val > topVal then topVal = val; topName = name end
    end
    return topName, topVal
end

function AUI:UpdateDelveUI()
    if not AUI.DelveDB then AUI:InitDelveDatabase() end
    local db = AUI.DelveDB
    if not db then return end 

    UI.Stats.TotalRuns:SetText(db.TotalRuns or 0)
    UI.Stats.TotalFails:SetText(db.TotalFails or 0)
    UI.Stats.TotalDeaths:SetText(db.TotalDeaths or 0)
    
    UI.Stats.TotalCurios:SetText(db.TotalCurios or 0)
    UI.Stats.TotalBanners:SetText(db.TotalBanners or 0)
    
    local topChar, charRuns = GetTopFromTable(db.RunsPerCharacter)
    local topSpec, specRuns = GetTopFromTable(db.RunsPerSpec)
    local topDelve = "-"
    local topDelveRuns = 0
    for name, data in pairs(db.DelveDetails) do
        if data.runs > topDelveRuns then topDelveRuns = data.runs; topDelve = name end
    end
    
    UI.Stats.TopChar:SetText(topChar ~= "-" and (topChar .. " (" .. charRuns .. ")") or "-")
    UI.Stats.TopSpec:SetText(topSpec ~= "-" and (topSpec .. " (" .. specRuns .. ")") or "-")
    UI.Stats.MostPlayedDelve:SetText(topDelve ~= "-" and (topDelve .. " (" .. topDelveRuns .. ")") or "-")

    local highestTier = 0
    for name, data in pairs(db.DelveDetails) do
        if data.maxTier and data.maxTier > highestTier then
            highestTier = data.maxTier
        end
    end
    if highestTier > 0 then
        UI.Stats.HighestTier:SetText("Stufe " .. highestTier)
    else
        UI.Stats.HighestTier:SetText("-")
    end


    local bestDName, bestDTier, bestDTime = "-", "-", 999999
    for dName, tiers in pairs(db.BestTimes) do
        for tier, time in pairs(tiers) do
            if time < bestDTime then bestDTime = time; bestDName = dName; bestDTier = tier end
        end
    end
    
    if bestDTime ~= 999999 then
        local mins = math.floor(bestDTime / 60); local secs = math.floor(bestDTime % 60)
        UI.Stats.BestDelveName:SetText(bestDName .. " (Stufe " .. bestDTier .. ")")
        UI.Stats.BestDelveTime:SetText(mins .. "m " .. secs .. "s")
    else
        UI.Stats.BestDelveName:SetText("-"); UI.Stats.BestDelveTime:SetText("-")
    end

    if db.LastFail and db.LastFail.delveName ~= "Keine" then
        UI.Stats.LastFailDelve:SetText(db.LastFail.delveName .. " (Stufe " .. db.LastFail.tier .. ")")
        UI.Stats.LastFailChar:SetText(db.LastFail.charName .. " - " .. db.LastFail.spec)
        UI.Stats.LastFailDate:SetText(db.LastFail.date)
    else
        UI.Stats.LastFailDelve:SetText("-"); UI.Stats.LastFailChar:SetText("-"); UI.Stats.LastFailDate:SetText("-")
    end

    -- ================================================================
    -- FORTSCHRITTSBALKEN AKTUALISIEREN 
    -- ================================================================
    
    -- 1. TIEFENREISE (ID: 2742)
    local jID = 2742 
    local jRenownInfo = C_MajorFactions and C_MajorFactions.GetMajorFactionData(jID) 
    local jRepData = C_Reputation and C_Reputation.GetFactionDataByID(jID) 
    
    local jName, jLevel, jCur, jMax = "Tiefenreise", 0, 0, 1
    if jRenownInfo then
        jName = jRenownInfo.name or jName
        jLevel = jRenownInfo.renownLevel or 0
        local isMaxed = C_MajorFactions.HasMaximumRenown(jID) 
        jCur = isMaxed and 1 or (jRenownInfo.renownReputationEarned or 0) 
        jMax = isMaxed and 1 or (jRenownInfo.renownLevelThreshold or 1) 
    elseif jRepData then
        jName = jRepData.name or jName
        jLevel = jRepData.reaction or 0
        local min = jRepData.currentReactionThreshold or jRepData.bottomValue or 0 
        jMax = jRepData.nextReactionThreshold or jRepData.topValue or 1 
        jMax = jMax - min
        if jMax <= 0 then jMax = 1 end
        jCur = jRepData.currentStanding - min 
    end
    
    UI.JourneyBtn.Status:SetMinMaxValues(0, jMax)
    UI.JourneyBtn.Status:SetValue(jCur)
    
    if jMax == 1 and jCur == 1 then
        UI.JourneyBtn.Text:SetText(string.format("Stufe %s  |  Maximal", tostring(jLevel)))
    else
        UI.JourneyBtn.Text:SetText(string.format("Stufe %s  |  %d / %d XP", tostring(jLevel), jCur, jMax))
    end
    
    -- 2. VALEERA (ID: 2744) 
    local valID = 2744 
    local friend = C_GossipInfo and C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(valID) 
    local rankInfo = C_GossipInfo and C_GossipInfo.GetFriendshipReputationRanks and C_GossipInfo.GetFriendshipReputationRanks(valID) 
    local compRep = C_Reputation and C_Reputation.GetFactionDataByID(valID) 
    
    local cName = "Valeera Sanguinar"
    local cLevel = "--"
    local cCur, cMax = 0, 1
    
    if friend and friend.name then cName = friend.name end 
    if compRep and compRep.name then cName = compRep.name end 
    
    if rankInfo and rankInfo.currentLevel then cLevel = tostring(rankInfo.currentLevel) 
    elseif compRep and compRep.reaction then cLevel = tostring(compRep.reaction) end 
    
    if friend and friend.friendshipFactionID and friend.friendshipFactionID > 0 then 
        if friend.nextThreshold and friend.reactionThreshold and friend.nextThreshold > friend.reactionThreshold then 
            cCur = friend.standing - friend.reactionThreshold 
            cMax = friend.nextThreshold - friend.reactionThreshold 
        elseif friend.standing and friend.standing > 0 then 
            cCur, cMax = 1, 1
        end
    elseif compRep then 
        local min = compRep.currentReactionThreshold or compRep.bottomValue or 0 
        local maxVal = compRep.nextReactionThreshold or compRep.topValue or 1 
        if maxVal > min then 
            cCur = compRep.currentStanding - min 
            cMax = maxVal - min 
        end
    end
    
    UI.CompanionBtn.Icon:SetTexture("Interface\\Icons\\Achievement_Character_Bloodelf_Female")
    
    UI.CompanionBtn.Status:SetMinMaxValues(0, cMax)
    UI.CompanionBtn.Status:SetValue(cCur)
    
    if cMax == 1 and cCur == 1 then
        UI.CompanionBtn.Text:SetText(string.format("Stufe %s  |  Maximal", cLevel))
    else
        UI.CompanionBtn.Text:SetText(string.format("Stufe %s  |  %d / %d XP", cLevel, cCur, cMax))
    end
    
    -- ================================================================
    
    local bountifulData, normalData = AUI:ScanLiveDelves()

    local currentY = -120

    if #bountifulData == 0 then
        UI.BountifulEmptyText:SetPoint("TOPLEFT", UI, "TOPLEFT", 20, currentY)
        UI.BountifulEmptyText:Show()
        currentY = currentY - 35
        for i = 1, 4 do UI.RightSpalte["Bountiful"..i].frame:Hide() end
    else
        UI.BountifulEmptyText:Hide()
        for i = 1, 4 do
            local row = UI.RightSpalte["Bountiful"..i]
            local data = bountifulData[i]
            if data then
                row.frame:ClearAllPoints()
                row.frame:SetPoint("TOPLEFT", UI, "TOPLEFT", 20, currentY)
                
                row.name:SetText("|cffffd100" .. data.name .. "|r")
                row.frame.delveRawName = data.name 
                row.story:SetText(data.story ~= "Standard" and ("|cffdddddd" .. data.story .. "|r") or "|cff888888(Aktiv)|r")
                row.stats:SetText(data.stats)
                row.frame.mapID = data.mapID
                local atlas = data.atlas or "delves-bountiful"
                row.frame.icon:SetAtlas(atlas)
                row.frame:Show()
                
                currentY = currentY - 38
            else 
                row.frame:Hide() 
            end
        end
    end

    UI.NormalTitle:ClearAllPoints()
    UI.NormalTitle:SetPoint("TOPLEFT", UI, "TOPLEFT", 20, currentY - 10)
    currentY = currentY - 35

    for i = 1, 10 do
        local row = UI.RightSpalte["Normal"..i]
        local data = normalData[i]
        if data then
            row.frame:ClearAllPoints()
            row.frame:SetPoint("TOPLEFT", UI, "TOPLEFT", 20, currentY)
            
            row.name:SetText(data.name)
            row.frame.delveRawName = data.name 
            row.story:SetText(data.story ~= "Standard" and ("|cff888888" .. data.story .. "|r") or "|cff555555(Aktiv)|r")
            row.stats:SetText(data.stats)
            row.frame.mapID = data.mapID
            local atlas = data.atlas or "delves-normal"
            if not row.frame.icon:SetAtlas(atlas) and not row.frame.icon:GetAtlas() then row.frame.icon:SetAtlas("Dungeon") end
            row.frame:Show()
            
            currentY = currentY - 38
        else 
            row.frame:Hide() 
        end
    end

    if currentDelve.isActive then
        local activeMapID
        for _, d in ipairs(AUI.DelveMasterList) do
            if d.locName == currentDelve.name then
                activeMapID = d.internalMapID
                local fallbackMap = C_Map.GetBestMapForUnit("player")
                if d.extraMapIDs then
                    for _, eID in ipairs(d.extraMapIDs) do
                        if eID == fallbackMap then activeMapID = eID; break end
                    end
                end
                break
            end
        end
        if activeMapID then
            AUI:OpenDelveMap(activeMapID, currentDelve.name)
            SetActiveTab("MAP")
        end
    else
        SetActiveTab("STATS")
        if not AUI.CurrentMapLoaded then
            local fallbackData = bountifulData[1] or normalData[1]
            if fallbackData then
                AUI:OpenDelveMap(fallbackData.mapID, fallbackData.name)
                AUI.CurrentMapLoaded = true
            end
        end
    end
end

E:RegisterChatCommand("delves", function()
    if AUI_DelveInfoFrame:IsShown() then
        AUI_DelveInfoFrame:Hide()
    else
        AUI:UpdateDelveUI()
        AUI_DelveInfoFrame:Show()
    end
end) 