local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

-- =====================================================================
-- KARTEN-PINS DATENBANK (RETAIL MIDNIGHT & TBC CLASSIC)
-- =====================================================================
local cityPins = {}

if isRetail then
    -- -----------------------------------------------------------------
    -- RETAIL: SILBERMOND (MIDNIGHT - MAP-ID: 2393)
    -- -----------------------------------------------------------------
    cityPins[2393] = {
        -- HAUPT-ANLAUFSTELLEN
        { coords = { x = 0.4513, y = 0.5560 }, title = "|cff00ffd2" .. (L["Artisans Consortium"] or "Handwerkerkonsortium") .. "|r", desc = L["Consortium Desc"], icon = "Interface\\Icons\\inv_misc_symbolofkings_01" },
        { coords = { x = 0.5013, y = 0.6622 }, title = "|cffffd100" .. (L["Bank of Silvermoon"] or "Bank von Silbermond") .. "|r", desc = L["Bank Desc"], icon = "Interface\\Minimap\\Tracking\\Banker" },
        { coords = { x = 0.5037, y = 0.7503 }, title = "|cffffd100" .. (L["Auction House"] or "Auktionshaus") .. "|r", desc = L["Auction House Desc"], icon = "Interface\\Minimap\\Tracking\\Auctioneer" },
        { coords = { x = 0.5540, y = 0.7038 }, title = "|cffffd100" .. (L["Inn"] or "Gasthaus") .. "|r", desc = L["Inn Desc"], icon = "Interface\\Minimap\\Tracking\\Innkeeper" },
        { coords = { x = 0.4191, y = 0.6664 }, title = "|cffffbc00" .. (L["Heirlooms & Transmog"] or "Erbstücke & Transmog") .. "|r", desc = L["Heirloom Desc"], icon = "Interface\\Minimap\\Tracking\\Transmogrifier" },
        { coords = { x = 0.4841, y = 0.6176 }, title = "|cffffffff" .. (L["Item Upgrade"] or "Gegenstandsaufwertung") .. "|r", desc = L["Upgrade Desc"], icon = "Interface\\Icons\\Garrison_Building_Armory" },
        { coords = { x = 0.4621, y = 0.5560 }, title = "|cffffd100" .. (L["Stable Master"] or "Stallmeister") .. "|r", desc = L["Stable Desc"], icon = "Interface\\Minimap\\Tracking\\StableMaster" },
        { coords = { x = 0.4034, y = 0.6489 }, title = "|cff00ffd2" .. (L["Catalyst"] or "Katalysator") .. "|r", desc = L["Catalyst Desc"], icon = "Interface\\Icons\\inv_enchant_essencecosmicgreater" },
        { coords = { x = 0.5243, y = 0.7811 }, title = "|cffffd100" .. (L["Delve Hub"] or "Tiefen-Zentrum") .. "|r", desc = L["Delve Hub Desc"], icon = "Interface\\Icons\\ui_delves" },
        
        -- BERUFE
        { coords = { x = 0.4701, y = 0.5208 }, title = "|cff00ff00" .. (L["Alchemy"] or "Alchemie") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Alchemy" },
        { coords = { x = 0.4375, y = 0.5150 }, title = "|cff00ff00" .. (L["Blacksmithing"] or "Schmiedekunst") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_BlackSmithing" },
        { coords = { x = 0.4788, y = 0.5367 }, title = "|cff00ff00" .. (L["Enchanting"] or "Verzauberkunst") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Engraving" },
        { coords = { x = 0.4356, y = 0.5389 }, title = "|cff00ff00" .. (L["Engineering"] or "Ingenieurskunst") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Engineering" },
        { coords = { x = 0.4670, y = 0.5148 }, title = "|cff00ff00" .. (L["Inscription"] or "Inschriftenkunde") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
        { coords = { x = 0.4784, y = 0.5518 }, title = "|cff00ff00" .. (L["Jewelcrafting"] or "Juwelenschleifen") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\INV_Misc_Gem_01" },
        { coords = { x = 0.4310, y = 0.5605 }, title = "|cff00ff00" .. (L["Leatherworking"] or "Lederverarbeitung") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_LeatherWorking" },
        { coords = { x = 0.4820, y = 0.5432 }, title = "|cff00ff00" .. (L["Tailoring"] or "Schneidern") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Tailoring" },
        { coords = { x = 0.4271, y = 0.5285 }, title = "|cff00ff00" .. (L["Mining"] or "Bergbau") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Mining" },
        { coords = { x = 0.4815, y = 0.5163 }, title = "|cff00ff00" .. (L["Herbalism"] or "Kräuterkunde") .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Herbalism" },
    }
else
    -- -----------------------------------------------------------------
    -- TBC CLASSIC: SHATTRATH (MAP-ID: 111)
    -- -----------------------------------------------------------------
    cityPins[111] = {
        -- Banken & Gasthäuser
        { coords = { x = 0.3812, y = 0.3955 }, title = "|cffffd100Bank der Aldor|r", desc = "Bank im Aldor-Viertel", icon = "Interface\\Minimap\\Tracking\\Banker" },
        { coords = { x = 0.5732, y = 0.6310 }, title = "|cffffd100Bank der Seher|r", desc = "Bank auf der Seherterrasse", icon = "Interface\\Minimap\\Tracking\\Banker" },
        { coords = { x = 0.2810, y = 0.4850 }, title = "|cffffd100Gasthaus der Aldor|r", desc = "Gasthaus der Aldor", icon = "Interface\\Minimap\\Tracking\\Innkeeper" },
        { coords = { x = 0.5620, y = 0.8160 }, title = "|cffffd100Gasthaus der Seher|r", desc = "Gasthaus der Seher", icon = "Interface\\Minimap\\Tracking\\Innkeeper" },
        
        -- Flugmeister & Portale
        { coords = { x = 0.6405, y = 0.4285 }, title = "|cffffbc00Flugmeister|r", desc = "Flugmeister von Shattrath", icon = "Interface\\Minimap\\Tracking\\FlightMaster" },
        { coords = { x = 0.5400, y = 0.4500 }, title = "|cff00ffd2Hauptstädte-Portale (Mitte)|r", desc = "Portale nach Orgrimmar, Sturmwind, etc.", icon = "Interface\\Icons\\Spell_Arcane_PortalDalaran" },
        
        -- Berufe / Reagenzien
        { coords = { x = 0.6720, y = 0.6750 }, title = "|cff00ff00Alchemie-Labor|r", desc = "Speziallabor der Seher", icon = "Interface\\Icons\\Trade_Alchemy" },
        { coords = { x = 0.3650, y = 0.4730 }, title = "|cff00ff00Schmiede / Bergbau (Aldor)|r", desc = "Schmiede & Amboss", icon = "Interface\\Icons\\Trade_BlackSmithing" },
        { coords = { x = 0.4350, y = 0.9050 }, title = "|cff00ff00Juwelenschleifen (Unteres Viertel)|r", desc = "Juwelenschleifer & Rezepte", icon = "Interface\\Icons\\INV_Misc_Gem_01" },
        { coords = { x = 0.6650, y = 0.1650 }, title = "|cff00ff00Lederverarbeitung & Kürschnerei|r", desc = "Lederer im Norden", icon = "Interface\\Icons\\Trade_LeatherWorking" },
    }

    -- -----------------------------------------------------------------
    -- TBC CLASSIC: SILBERMOND (MAP-ID: 110)
    -- -----------------------------------------------------------------
    cityPins[110] = {
        { coords = { x = 0.6750, y = 0.7250 }, title = "|cffffd100Bank von Silbermond|r", desc = "Königliche Bank", icon = "Interface\\Minimap\\Tracking\\Banker" },
        { coords = { x = 0.5420, y = 0.7100 }, title = "|cffffd100Auktionshaus (Basar)|r", desc = "Auktionshaus am Basar", icon = "Interface\\Minimap\\Tracking\\Auctioneer" },
        { coords = { x = 0.6720, y = 0.5150 }, title = "|cffffd100Gasthaus Zur Silbernen Fackel|r", desc = "Gasthaus im Basar", icon = "Interface\\Minimap\\Tracking\\Innkeeper" },
        { coords = { x = 0.5430, y = 0.5080 }, title = "|cffffbc00Flugmeister|r", desc = "Falkenschreiter & Flugroute", icon = "Interface\\Minimap\\Tracking\\FlightMaster" },
        { coords = { x = 0.4850, y = 0.4650 }, title = "|cff00ffd2Translokationskugel (Unterstadt)|r", desc = "Teleport nach Unterstadt", icon = "Interface\\Icons\\Spell_Arcane_PortalDalaran" },
        
        -- Berufe
        { coords = { x = 0.5350, y = 0.3250 }, title = "|cff00ff00Alchemie & Kräuterkunde|r", desc = "Magisches Viertel", icon = "Interface\\Icons\\Trade_Alchemy" },
        { coords = { x = 0.7950, y = 0.4050 }, title = "|cff00ff00Schmiedekunst & Bergbau|r", desc = "Viertel der Handwerker", icon = "Interface\\Icons\\Trade_BlackSmithing" },
        { coords = { x = 0.5620, y = 0.5650 }, title = "|cff00ff00Verzauberkunst|r", desc = "Basar", icon = "Interface\\Icons\\Trade_Engraving" },
        { coords = { x = 0.8520, y = 0.8050 }, title = "|cff00ff00Ingenieurskunst|r", desc = "Gasse der Handwerker", icon = "Interface\\Icons\\Trade_Engineering" },
        { coords = { x = 0.5950, y = 0.6450 }, title = "|cff00ff00Juwelenschleifen|r", desc = "Königlicher Juwelier", icon = "Interface\\Icons\\INV_Misc_Gem_01" },
        { coords = { x = 0.7020, y = 0.6550 }, title = "|cff00ff00Schneidern & Lederer|r", desc = "Basar / Handwerker", icon = "Interface\\Icons\\Trade_Tailoring" },
    }
end

-- =====================================================================
-- MAP PIN MIXIN LOGIK
-- =====================================================================
AUI_MapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function AUI_MapPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_VIGNETTE")
    
    if not self.Texture then
        self.Texture = self:CreateTexture(nil, "ARTWORK")
        self.Texture:SetAllPoints()
    end
    
    self:SetScript("OnEnter", function(self)
        if not self.pinData then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.pinData.title)
        if self.pinData.desc then
            GameTooltip:AddLine(self.pinData.desc, 1, 1, 1, true)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Click to Track"] or "Links-Klick zum Verfolgen", 0, 1, 0.8)             
        GameTooltip:Show()
    end)
    
    self:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:OnPinClick()
        end
    end)
end

function AUI_MapPinMixin:OnPinClick()
    local data = self.pinData
    if not data or not self.owningMap then return end
    
    local mapID = self.owningMap:GetMapID()
    if not mapID then return end
    
    -- 1. Visueller Ping
    if self.owningMap.TriggerEvent then
        pcall(function() self.owningMap:TriggerEvent("PingMap", data.coords.x, data.coords.y) end)
    end
    
    -- 2. Blizzard Waypoint System (falls unterstützt)
    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint then
        pcall(function()
            local uiMapPoint = UiMapPoint.CreateFromCoordinates(mapID, data.coords.x, data.coords.y)
            C_Map.SetUserWaypoint(uiMapPoint)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end)
    end
    
    -- 3. TomTom Integration
    if _G.TomTom and _G.TomTom.AddWaypoint then
        if self.lastTomTom and _G.TomTom.RemoveWaypoint then 
            _G.TomTom:RemoveWaypoint(self.lastTomTom) 
        end
        
        self.lastTomTom = _G.TomTom:AddWaypoint(mapID, data.coords.x, data.coords.y, {
            title = data.title,
            persistent = false,
            minimap = true,
            world = true
        })
    end
    
    -- 4. Chat Info
    E:Print(string.format("|cff00ffd2A-UI:|r %s: %s", L["Tracking"] or "Tracking", data.title))
end

function AUI_MapPinMixin:OnAcquired(pinData, map)
    self.owningMap = map
    self.pinData = pinData
    self:SetPosition(pinData.coords.x, pinData.coords.y)
    
    local db = E.db.AUI and E.db.AUI.map
    local size = (db and db.pinSize) or 12
    local minScale = (db and db.pinScaleMin) or 1
    local maxScale = (db and db.pinScaleMax) or 1
    
    self:SetSize(size, size)
    self:SetScalingLimits(1, minScale, maxScale)
    
    if pinData.icon then
        self.Texture:SetTexture(pinData.icon)
        self.Texture:SetTexCoord(0, 1, 0, 1)
    else
        self.Texture:SetTexture("Interface\\Minimap\\POIIcons")
        self.Texture:SetTexCoord(0.43, 0.5, 0.71, 0.78)
    end
    
    self:Show()
    self:ApplyCurrentScale()
end

-- =====================================================================
-- DATA PROVIDER
-- =====================================================================
AUI_MapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function AUI_MapDataProviderMixin:OnAdded(mapCanvas)
    MapCanvasDataProviderMixin.OnAdded(self, mapCanvas)
    self.privatePool = CreateFramePool("Frame", mapCanvas:GetCanvas(), "BackdropTemplate")
    self.activePins = {}
    AUI.mapProvider = self
end

function AUI_MapDataProviderMixin:RemoveAllData()
    if self.privatePool then self.privatePool:ReleaseAll() end
    wipe(self.activePins)
end

function AUI_MapDataProviderMixin:RefreshAllData(hasValidMapPOI)
    self:RemoveAllData()
    if not E.db.AUI or not E.db.AUI.map or not E.db.AUI.map.enablePins then return end
    
    local map = self:GetMap()
    if not map then return end
    local currentMapID = map:GetMapID()
    
    if currentMapID and cityPins[currentMapID] then
        for _, pinData in ipairs(cityPins[currentMapID]) do
            local pin, isNew = self.privatePool:Acquire()
            if isNew then 
                Mixin(pin, AUI_MapPinMixin)
                pin:OnLoad() 
            end
            pin:OnAcquired(pinData, map)
            self.activePins[pin] = true
        end
    end
end

function AUI_MapDataProviderMixin:OnCanvasScaleChanged()
    for pin in pairs(self.activePins) do
        pin:ApplyCurrentScale()
    end
end

function AUI:RefreshMapPins()
    if AUI.mapProvider then AUI.mapProvider:RefreshAllData() end
end

local function InitializeMapModule()
    local dataProvider = CreateFromMixins(AUI_MapDataProviderMixin)
    if WorldMapFrame and WorldMapFrame.AddDataProvider then
        WorldMapFrame:AddDataProvider(dataProvider)
    end
end

hooksecurefunc(AUI, "Initialize", InitializeMapModule)