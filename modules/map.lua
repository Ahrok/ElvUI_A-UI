local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

-- =====================================================================
-- DEINE MAP PINS FÜR SILBERMOND (MAP-ID: 2393)
-- =====================================================================
local SILVERMOON_MAP_ID = 2393

local mapPins = {
    -- HAUPT-ANLAUFSTELLEN
    { coords = { x = 0.4513, y = 0.5560 }, title = "|cff00ffd2" .. L["Artisans Consortium"] .. "|r", desc = L["Consortium Desc"], icon = "Interface\\Icons\\inv_misc_symbolofkings_01" },
    { coords = { x = 0.5013, y = 0.6622 }, title = "|cffffd100" .. L["Bank of Silvermoon"] .. "|r", desc = L["Bank Desc"], icon = "Interface\\Minimap\\Tracking\\Banker" },
    { coords = { x = 0.5037, y = 0.7503 }, title = "|cffffd100" .. L["Auction House"] .. "|r", desc = L["Auction House Desc"], icon = "Interface\\Minimap\\Tracking\\Auctioneer" },
    { coords = { x = 0.5540, y = 0.7038 }, title = "|cffffd100" .. L["Inn"] .. "|r", desc = L["Inn Desc"], icon = "Interface\\Minimap\\Tracking\\Innkeeper" },
    { coords = { x = 0.4191, y = 0.6664 }, title = "|cffffbc00" .. L["Heirlooms & Transmog"] .. "|r", desc = L["Heirloom Desc"], icon = "Interface\\Minimap\\Tracking\\Transmogrifier" },
    { coords = { x = 0.4841, y = 0.6176 }, title = "|cffffffff" .. L["Item Upgrade"] .. "|r", desc = L["Upgrade Desc"], icon = "Interface\\Icons\\Garrison_Building_Armory" },
    { coords = { x = 0.4621, y = 0.5560 }, title = "|cffffd100" .. L["Stable Master"] .. "|r", desc = L["Stable Desc"], icon = "Interface\\Minimap\\Tracking\\StableMaster" },
    { coords = { x = 0.4034, y = 0.6489 }, title = "|cff00ffd2" .. L["Catalyst"] .. "|r", desc = L["Catalyst Desc"], icon = "Interface\\Icons\\inv_enchant_essencecosmicgreater" },
    { coords = { x = 0.5243, y = 0.7811 }, title = "|cffffd100" .. L["Delve Hub"] .. "|r", desc = L["Delve Hub Desc"], icon = "Interface\\Icons\\ui_delves" },

    -- BERUFE (VOLLSTÄNDIG)
    { coords = { x = 0.4701, y = 0.5208 }, title = "|cff00ff00" .. L["Alchemy"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Alchemy" },
    { coords = { x = 0.4375, y = 0.5150 }, title = "|cff00ff00" .. L["Blacksmithing"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_BlackSmithing" },
    { coords = { x = 0.4788, y = 0.5367 }, title = "|cff00ff00" .. L["Enchanting"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Engraving" },
    { coords = { x = 0.4356, y = 0.5389 }, title = "|cff00ff00" .. L["Engineering"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Engineering" },
    { coords = { x = 0.4670, y = 0.5148 }, title = "|cff00ff00" .. L["Inscription"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
    { coords = { x = 0.4784, y = 0.5518 }, title = "|cff00ff00" .. L["Jewelcrafting"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\INV_Misc_Gem_01" },
    { coords = { x = 0.4310, y = 0.5605 }, title = "|cff00ff00" .. L["Leatherworking"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_LeatherWorking" },
    { coords = { x = 0.4820, y = 0.5432 }, title = "|cff00ff00" .. L["Tailoring"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Tailoring" },
    { coords = { x = 0.4271, y = 0.5285 }, title = "|cff00ff00" .. L["Mining"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Mining" },
    { coords = { x = 0.4815, y = 0.5163 }, title = "|cff00ff00" .. L["Herbalism"] .. "|r", desc = L["Profession Desc"], icon = "Interface\\Icons\\Trade_Herbalism" },
}

-- =====================================================================
-- EIGENE MAP PIN MIXIN LOGIK
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
        GameTooltip:AddLine(" ") -- Kleiner Abstandshalter
        -- Tracking-Hinweis im Tooltip
        GameTooltip:AddLine(L["Click to Track"] or "Left-Click to track target", 0, 1, 0.8) 
        

        GameTooltip:Show()
    end)
    
    self:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Tracking-Klick-Event
    self:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:OnPinClick()
        end
    end)
end

function AUI_MapPinMixin:OnPinClick()
    local data = self.pinData
    if not data then return end

    -- 1. Visueller Ping auf der Map
    self.owningMap:TriggerEvent("PingMap", data.coords.x, data.coords.y) 

    -- 2. Native Waypoint UI & Minimap Pfeil (Blizzard System)
    local uiMapPoint = UiMapPoint.CreateFromCoordinates(SILVERMOON_MAP_ID, data.coords.x, data.coords.y)
    C_Map.SetUserWaypoint(uiMapPoint)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)

    -- 3. TomTom Integration
    if _G.TomTom then
        if self.lastTomTom then _G.TomTom:RemoveWaypoint(self.lastTomTom) end
        
        self.lastTomTom = _G.TomTom:AddWaypoint(SILVERMOON_MAP_ID, data.coords.x, data.coords.y, {
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
    
    local db = E.db.AUI.map
    local size = db.pinSize or 12
    local minScale = db.pinScaleMin or 1
    local maxScale = db.pinScaleMax or 1
    
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
    self.privatePool:ReleaseAll()
    wipe(self.activePins)
end

function AUI_MapDataProviderMixin:RefreshAllData(hasValidMapPOI)
    self:RemoveAllData()
    if not E.db.AUI.map.enablePins then return end
    
    local currentMapID = self:GetMap():GetMapID()
    if currentMapID == SILVERMOON_MAP_ID then
        for _, pinData in ipairs(mapPins) do
            local pin, isNew = self.privatePool:Acquire()
            if isNew then Mixin(pin, AUI_MapPinMixin); pin:OnLoad() end
            pin:OnAcquired(pinData, self:GetMap())
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
    WorldMapFrame:AddDataProvider(dataProvider)
end

hooksecurefunc(AUI, "Initialize", InitializeMapModule)