local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

local buttons = {}
local ignoreList = {
    ["minimaptrackingframe"] = true, ["minimapvoicechatframe"] = true,
    ["minimapworldmapbutton"] = true, ["minimapzoomin"] = true, 
    ["minimapzoomout"] = true, ["minimapmailframe"] = true, 
    ["battlefieldminimap"] = true, ["minimapbattlefieldframe"] = true, ["minimapbackdrop"] = true, 
    ["gametimeframe"] = true, ["timemanagerclockbutton"] = true, 
    ["feedbackuibutton"] = true, ["helpopenticketbutton"] = true, 
    ["garrisonlandingpageminimapbutton"] = true, ["expansionlandingpageminimapbutton"] = true,
    ["elvconfigtoggle"] = true, ["aui_minimapbagbutton"] = true,
    ["queuestatusminimapbutton"] = true, ["minimplfgframe"] = true, ["miniMaplfgframe"] = true,
}

local BagButton, BagFrame, BagBackdrop, IconContainer
local isBagOpen = false

-- =====================================================================
-- 1. DEFAULTS
-- =====================================================================
P["AUI"] = P["AUI"] or {}
P["AUI"]["minimapBag"] = {
    orientation = "LEFT",
    textMode = "MB",
    colorMode = "DEFAULT",
    customColor = { r = 1, g = 1, b = 1 },
    layoutMode = "BUTTON",
}

-- =====================================================================
-- 2. GRÖSSE, FARBEN & TEXT AKTUALISIEREN
-- =====================================================================
local function UpdateButtonSizeAndText()
    if not BagButton or not BagButton.Text then return end
    local db = E.db.AUI and E.db.AUI.minimapBag or { layoutMode = "BUTTON", orientation = "LEFT", textMode = "MB" }
    
    local minimapWidth = Minimap and Minimap:GetWidth() or 220
    
    if db.layoutMode == "BAR" then
        BagButton:SetSize(minimapWidth, 20)
        local orient = db.orientation
        if orient == "LEFT" then
            BagButton.Text:SetText(isBagOpen and ">" or "<")
        elseif orient == "RIGHT" then
            BagButton.Text:SetText(isBagOpen and "<" or ">")
        elseif orient == "UP" then
            BagButton.Text:SetText(isBagOpen and "v" or "^")
        elseif orient == "DOWN" then
            BagButton.Text:SetText(isBagOpen and "^" or "v")
        else
            BagButton.Text:SetText(isBagOpen and "<" or ">")
        end
    else
        BagButton:SetSize(32, 32)
        BagButton.Text:SetText(db.textMode or "MB")
    end
    
    local colorDb = E.db.AUI and E.db.AUI.minimapBag or { colorMode = "DEFAULT", customColor = {r=1,g=1,b=1} }
    local r, g, b = 1, 1, 1
    if colorDb.colorMode == "AUI" then
        r, g, b = 0, 1, 0.82
    elseif colorDb.colorMode == "CLASS" then
        local classColor = E:ClassColor(E.myclass, true)
        if classColor then r, g, b = classColor.r, classColor.g, classColor.b end
    elseif colorDb.colorMode == "CUSTOM" then
        r, g, b = colorDb.customColor.r, colorDb.customColor.g, colorDb.customColor.b
    else
        r, g, b = 1, 1, 1
    end
    BagButton.Text:SetTextColor(r, g, b)
end

-- =====================================================================
-- 3. RASTER DYNAMISCH BERECHNEN & ORIENTIERUNG
-- =====================================================================
local function UpdateBagLayout()
    if not BagFrame or not IconContainer then return end

    local numButtons = #buttons
    local db = E.db.AUI and E.db.AUI.minimapBag or { orientation = "LEFT" }
    local orientation = db.orientation or "LEFT"

    if numButtons > 0 then
        local cols = math.min(numButtons, 5) 
        local rows = math.ceil(numButtons / cols)
        local size = 30
        local spacing = 4
        
        local width = (cols * size) + (spacing * (cols + 1))
        local height = (rows * size) + (spacing * (rows + 1))
        
        BagFrame:SetSize(width, height)
        if BagBackdrop then BagBackdrop:SetSize(width, height) end
        IconContainer:SetSize(width, height)
        
        BagBackdrop:ClearAllPoints()
        if orientation == "LEFT" then
            BagBackdrop:SetPoint("TOPRIGHT", BagButton, "TOPLEFT", -5, 0)
        elseif orientation == "RIGHT" then
            BagBackdrop:SetPoint("TOPLEFT", BagButton, "TOPRIGHT", 5, 0)
        elseif orientation == "UP" then
            BagBackdrop:SetPoint("BOTTOMLEFT", BagButton, "TOPLEFT", 0, 5)
        elseif orientation == "DOWN" then
            BagBackdrop:SetPoint("TOPLEFT", BagButton, "BOTTOMLEFT", 0, -5)
        else
            BagBackdrop:SetPoint("TOPRIGHT", BagButton, "TOPLEFT", -5, 0)
        end
        
        BagFrame:SetPoint("TOPLEFT", BagBackdrop, "TOPLEFT", 0, 0)

        for i, btn in ipairs(buttons) do
            btn:ClearAllPoints()
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            
            btn:SetParent(IconContainer)
            btn:SetPoint("TOPLEFT", IconContainer, "TOPLEFT", spacing + (col * (size + spacing)), -(spacing + (row * (size + spacing))))
            btn:SetSize(size, size)
            
            btn:SetFrameStrata("HIGH")
            btn:SetFrameLevel(IconContainer:GetFrameLevel() + i)
            btn:SetAlpha(1)
            btn:SetShown(true)
            
            if btn.auiBackdrop then
                btn.auiBackdrop:Hide()
            end
            
            if isBagOpen then
                btn:Show()
            end
        end
    else
        BagFrame:SetSize(38, 38)
        if BagBackdrop then BagBackdrop:SetSize(38, 38) end
        IconContainer:SetSize(38, 38)
    end
end

local function ResetRegion(region)
    if not region or not region.GetObjectType then return end
    if region:IsObjectType("Texture") then
        if region.SetAlpha then region:SetAlpha(1) end
        if region.SetDesaturated then region:SetDesaturated(false) end
        if region.SetVertexColor then region:SetVertexColor(1, 1, 1, 1) end
    end
end

local reassertTicker = CreateFrame("Frame")
reassertTicker:Hide()
reassertTicker:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer > 0.2 then
        self.timer = 0
        for _, btn in ipairs(buttons) do
            if btn then
                btn:SetAlpha(1)
                btn:SetFrameStrata("HIGH")
                if btn.auiBackdrop then
                    btn.auiBackdrop:Hide()
                end
                btn:Show()

                for _, region in ipairs({btn:GetRegions()}) do
                    ResetRegion(region)
                end

                for _, child in ipairs({btn:GetChildren()}) do
                    if child then
                        if child.SetAlpha then child:SetAlpha(1) end
                        for _, region in ipairs({child:GetRegions()}) do
                            ResetRegion(region)
                        end
                    end
                end
            end
        end
    end
end)

-- =====================================================================
-- 4. SCANNER
-- =====================================================================
local function GrabMinimapButtons()
    local parentsToScan = { Minimap, _G.MinimapBackdrop, _G.MinimapCluster }
    local grabbedNew = false
    
    for _, parent in ipairs(parentsToScan) do
        if parent and parent.GetChildren then
            for _, child in ipairs({ parent:GetChildren() }) do
                if child and child:IsObjectType("Button") and not child.isGrabbed then
                    local name = child:GetName()
                    local n = name and string.lower(name) or ""
                    
                    local isBadPortrait = n:find("character") or n:find("portrait") or n:find("player")
                    local isAddon = false
                    local isBlacklisted = false
                    
                    if n == "" or isBadPortrait then
                        isBlacklisted = true
                    else
                        if n:find("libdbicon") or n:find("minimapbutton") or n:find("wim") then
                            isAddon = true
                        else
                            for _, word in ipairs({"mail", "track", "zoom", "time", "garrison", "help", "feedback", "pin", "poi", "node", "note", "gathermate", "gatherer", "handynotes", "worldmap", "questieframe", "questienote", "queue", "lfg"}) do
                                if n:find(word) then isBlacklisted = true; break end
                            end
                        end
                    end
                    
                    if (isAddon or not isBlacklisted) and child:GetNumRegions() > 0 and not ignoreList[n] then
                        child.isGrabbed = true
                        child:SetScript("OnDragStart", nil)
                        child:SetScript("OnDragStop", nil)

                        if IconContainer then
                            child:SetParent(IconContainer)
                        end
                        child:Hide()

                        table.insert(buttons, child)
                        grabbedNew = true
                    end
                end
            end
        end
    end
    
    if grabbedNew and BagFrame and isBagOpen then 
        UpdateBagLayout() 
    end
end

-- =====================================================================
-- 5. INITIALISIERUNG
-- =====================================================================
function AUI:InitMinimapBag()
    BagButton = CreateFrame("Button", "AUI_MinimapBagButton", UIParent, "BackdropTemplate")
    BagButton:SetSize(32, 32)
    BagButton:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    BagButton:SetTemplate("Default")
    BagButton:SetFrameStrata("HIGH")
    BagButton:SetFrameLevel(50)

    BagButton.Text = BagButton:CreateFontString(nil, "OVERLAY")
    BagButton.Text:FontTemplate(E.media.normFont, 14, "OUTLINE")
    BagButton.Text:SetPoint("CENTER", BagButton, "CENTER", 0, 0)
    
    UpdateButtonSizeAndText()

    E:CreateMover(BagButton, "AUI_MinimapBagMover", "A-UI Minimap Button", nil, nil, nil, "ALL,SOLO")

    BagBackdrop = CreateFrame("Frame", "AUI_MinimapBagBackdrop", UIParent, "BackdropTemplate")
    BagBackdrop:SetTemplate("Transparent")
    BagBackdrop:Hide()
    BagBackdrop:SetFrameStrata("LOW")
    BagBackdrop:SetFrameLevel(1)

    BagFrame = CreateFrame("Frame", "AUI_MinimapBagFrame", UIParent)
    BagFrame:SetSize(38, 38)
    BagFrame:Hide()
    BagFrame:SetFrameStrata("HIGH")
    BagFrame:SetFrameLevel(10)

    IconContainer = CreateFrame("Frame", "AUI_MinimapBagIconContainer", BagFrame)
    IconContainer:SetAllPoints(BagFrame)
    IconContainer:Hide()
    IconContainer:SetFrameStrata("HIGH")
    IconContainer:SetFrameLevel(20)

    BagButton:SetScript("OnClick", function()
        if isBagOpen then
            isBagOpen = false
            BagBackdrop:Hide()
            BagFrame:Hide()
            IconContainer:Hide()
            reassertTicker:Hide()
            for _, btn in ipairs(buttons) do
                if btn then btn:Hide() end
            end
        else
            isBagOpen = true
            GrabMinimapButtons()
            BagBackdrop:Show()
            BagFrame:Show()
            IconContainer:Show()
            UpdateBagLayout()
            reassertTicker:Show()
        end
        UpdateButtonSizeAndText()
    end)

    GrabMinimapButtons()

    C_Timer.After(1, GrabMinimapButtons)
    C_Timer.After(3, GrabMinimapButtons)
    C_Timer.After(6, GrabMinimapButtons)

    local scanTicker = CreateFrame("Frame")
    scanTicker:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 2 then
            GrabMinimapButtons()
            self.timer = 0
        end
    end)
end

function AUI:UpdateMinimapBagSettings()
    UpdateButtonSizeAndText()
    UpdateBagLayout()
end

-- =====================================================================
-- 6. MENÜ-INTEGRATION (DIREKT IM MODUL)
-- =====================================================================
local function InsertMinimapBagOptions()
    if not E.Options.args.AUI or not E.Options.args.AUI.args then return end

    E.Options.args.AUI.args.minimapBag = {
        type = "group",
        name = L["Minimap Button Bag"],
        order = 8,
        get = function(info) return E.db.AUI.minimapBag[info[#info]] end,
        set = function(info, value) 
            E.db.AUI.minimapBag[info[#info]] = value
            if AUI.UpdateMinimapBagSettings then AUI:UpdateMinimapBagSettings() end
        end,
        args = {
            header = {
                order = 1,
                type = "header",
                name = "|cff00ffd2" .. L["Minimap Button Bag"] .. "|r",
            },
            desc = {
                order = 2,
                type = "description",
                name = L["Manages minimap buttons in a clean, expandable bag."] .. "\n",
                fontSize = "medium",
            },
            layoutMode = {
                order = 3,
                type = "select",
                name = L["Layout Mode"],
                values = {
                    ["BUTTON"] = L["Button (Static)"],
                    ["BAR"] = L["Bar (With Arrow)"],
                },
            },
            textMode = {
                order = 4,
                type = "input",
                name = L["Button Text"],
                disabled = function() return E.db.AUI.minimapBag.layoutMode == "BAR" end,
            },
            orientation = {
                order = 5,
                type = "select",
                name = L["Expand Direction"],
                values = {
                    ["LEFT"] = L["Left"],
                    ["RIGHT"] = L["Right"],
                    ["UP"] = L["Up"],
                    ["DOWN"] = L["Down"],
                },
            },
            colorHeader = {
                order = 6,
                type = "header",
                name = L["Button Coloring"],
            },
            colorMode = {
                order = 7,
                type = "select",
                name = L["Color Mode"],
                values = {
                    ["DEFAULT"] = L["ElvUI Default (White)"],
                    ["AUI"] = L["A-UI Colors"],
                    ["CLASS"] = L["Class Colored"],
                    ["CUSTOM"] = L["Custom Color"],
                },
            },
            customColor = {
                order = 8,
                type = "color",
                name = L["Custom Color"],
                hasAlpha = false,
                disabled = function() return E.db.AUI.minimapBag.colorMode ~= "CUSTOM" end,
                get = function() 
                    local t = E.db.AUI.minimapBag.customColor 
                    return t.r, t.g, t.b, 1 
                end,
                set = function(_, r, g, b) 
                    E.db.AUI.minimapBag.customColor.r = r
                    E.db.AUI.minimapBag.customColor.g = g
                    E.db.AUI.minimapBag.customColor.b = b
                    AUI:UpdateMinimapBagSettings() 
                end,
            },
        },
    }
end

hooksecurefunc(AUI, "Initialize", function()
    E.db.AUI = E.db.AUI or {}
    E.db.AUI.minimapBag = E.db.AUI.minimapBag or {
        orientation = "LEFT",
        textMode = "MB",
        colorMode = "DEFAULT",
        customColor = { r = 1, g = 1, b = 1 },
        layoutMode = "BUTTON",
    }
    AUI:InitMinimapBag()
end)

hooksecurefunc(AUI, "InsertOptions", InsertMinimapBagOptions)