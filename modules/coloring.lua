local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local DT = E:GetModule('DataTexts')
local isProcessing = {}

-- =====================================================================
-- 1. DEFAULTS
-- =====================================================================
P["AUI"] = P["AUI"] or {}
P["AUI"]["coloring"] = P["AUI"]["coloring"] or {}
P["AUI"]["coloring"]["datatexts"] = P["AUI"]["coloring"]["datatexts"] or {
    enable = true,
    colorMode = "CLASS", 
    customColor = { r = 1, g = 0.82, b = 0 }, 
    gradientColor = { r = 1, g = 0.2, b = 0 },
}
P["AUI"]["coloring"]["borders"] = P["AUI"]["coloring"]["borders"] or {}

local defaultBorders = {
    topBottom   = { enable = false, colorMode = "CLASS_GRADIENT", color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0}, color3 = {r=0.5,g=0,b=0} },
    minimap     = { enable = false, colorMode = "CLASS_GRADIENT", orientation = "HORIZONTAL", invert = false, color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0} },
    leftChat    = { enable = false, colorMode = "CLASS_GRADIENT", orientation = "HORIZONTAL", invert = false, colorEditBox = true, color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0} },
    rightChat   = { enable = false, colorMode = "CLASS_GRADIENT", orientation = "HORIZONTAL", invert = false, color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0} },
    character   = { enable = false, colorMode = "CLASS", orientation = "HORIZONTAL", invert = false, color1 = {r=1,g=1,b=1}, color2 = {r=0.3,g=0.3,b=0.3} },
    statsPanel  = { enable = false, colorMode = "CLASS", orientation = "HORIZONTAL", invert = false, color1 = {r=1,g=1,b=1}, color2 = {r=0.3,g=0.3,b=0.3} },
    inspect     = { enable = false, colorMode = "TARGET_CLASS", orientation = "HORIZONTAL", invert = false, color1 = {r=1,g=1,b=1}, color2 = {r=0.3,g=0.3,b=0.3} },
    alts        = { enable = false, colorMode = "CLASS_GRADIENT", color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0}, color3 = {r=0.5,g=0,b=0} },
    minimapBag  = { enable = false, colorMode = "CLASS_GRADIENT", orientation = "HORIZONTAL", invert = false, color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0} },
    calendar    = { enable = false, colorMode = "CLASS_GRADIENT", orientation = "HORIZONTAL", invert = false, color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0} },
}

for k, v in pairs(defaultBorders) do
    if P["AUI"]["coloring"]["borders"][k] == nil then
        P["AUI"]["coloring"]["borders"][k] = v
    end
end

-- =====================================================================
-- 2. HILFSFUNKTIONEN
-- =====================================================================
local function GetDarkerColor(c, factor)
    return { r = c.r * (factor or 0.35), g = c.g * (factor or 0.35), b = c.b * (factor or 0.35) }
end

local function C(c) 
    if CreateColor then
        return CreateColor(c.r, c.g, c.b, 1)
    end
    return c
end

local function SafeSetGradient(tex, orientation, c1, c2)
    if not tex then return end
    local success = pcall(function()
        tex:SetGradient(orientation, C(c1), C(c2))
    end)
    if not success then
        pcall(function()
            if tex.SetGradientAlpha then
                tex:SetGradientAlpha(orientation, c1.r, c1.g, c1.b, 1, c2.r, c2.g, c2.b, 1)
            end
        end)
    end
end

local function CreateBorderTextures(frame, isThreeColor)
    if not frame.auiGradientBorders or (isThreeColor and not frame.auiGradientBorders.topL) or (not isThreeColor and not frame.auiGradientBorders.top) then
        if frame.auiGradientBorders then
            for _, tex in pairs(frame.auiGradientBorders) do tex:Hide() end
        end
        frame.auiGradientBorders = {}
        local t = frame.auiGradientBorders
        local mult = E.mult or 1
        
        if isThreeColor then
            t.topL = frame:CreateTexture(nil, "OVERLAY")
            t.topL:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            t.topL:SetPoint("BOTTOMRIGHT", frame, "TOP", 0, -mult)
            t.topR = frame:CreateTexture(nil, "OVERLAY")
            t.topR:SetPoint("TOPLEFT", frame, "TOP", 0, 0)
            t.topR:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -mult)
            t.botL = frame:CreateTexture(nil, "OVERLAY")
            t.botL:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            t.botL:SetPoint("TOPRIGHT", frame, "BOTTOM", 0, mult)
            t.botR = frame:CreateTexture(nil, "OVERLAY")
            t.botR:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 0, 0)
            t.botR:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, mult)
        else
            t.top = frame:CreateTexture(nil, "OVERLAY")
            t.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            t.top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -mult)
            t.bot = frame:CreateTexture(nil, "OVERLAY")
            t.bot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            t.bot:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, mult)
        end
        t.left = frame:CreateTexture(nil, "OVERLAY")
        t.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        t.left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", mult, 0)
        t.right = frame:CreateTexture(nil, "OVERLAY")
        t.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        t.right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -mult, 0)
    end
    return frame.auiGradientBorders
end

local function ApplyGradientBorder(frame, config, isThreeColor, targetUnit)
    if not frame then return end
    local target = frame.backdrop or frame
    if not target then return end
    local t = CreateBorderTextures(target, isThreeColor)
    
    if not config or not config.enable then
        for _, tex in pairs(t) do tex:Hide() end
        if target.SetBackdropBorderColor then
            local bc = (E.db and E.db.general and E.db.general.bordercolor) or { r = 0, g = 0, b = 0 }
            target:SetBackdropBorderColor(bc.r, bc.g, bc.b, 1)
        end
        return
    end
    
    if target.SetBackdropBorderColor then target:SetBackdropBorderColor(0, 0, 0, 0) end
    
    local c1, c2, c3
    local mode = config.colorMode
    
    if mode == "TARGET_CLASS" or mode == "TARGET_CLASS_GRADIENT" then
        local unitClass = targetUnit and select(2, UnitClass(targetUnit))
        local cc = unitClass and E:ClassColor(unitClass, true) or E:ClassColor(E.myclass, true)
        if mode == "TARGET_CLASS" then
            c1 = cc; c2 = cc; c3 = cc
        else
            local dc = GetDarkerColor(cc, 0.35)
            if isThreeColor then c1, c2, c3 = dc, cc, dc else c1, c2, c3 = cc, dc, dc end
        end
    elseif mode == "CLASS" then
        c1 = E:ClassColor(E.myclass, true); c2 = c1; c3 = c1
    elseif mode == "CUSTOM" then
        c1 = config.color1; c2 = config.color2 or c1; c3 = config.color3 or c1
    elseif mode == "GRADIENT" then
        c1 = config.color1; c2 = config.color2; c3 = config.color3 or c2
    elseif mode == "CLASS_GRADIENT" then
        local cc = E:ClassColor(E.myclass, true)
        local dc = GetDarkerColor(cc, 0.35)
        if isThreeColor then c1, c2, c3 = dc, cc, dc else c1, c2, c3 = cc, dc, dc end
    end
    
    c1 = c1 or {r=1,g=1,b=1}; c2 = c2 or {r=1,g=1,b=1}; c3 = c3 or {r=1,g=1,b=1}
    
    local blankTexture = (E.media and E.media.blankTex) or "Interface\\BUTTONS\\WHITE8X8"
    for _, tex in pairs(t) do tex:Show(); tex:SetTexture(blankTexture) end
    
    if isThreeColor then
        SafeSetGradient(t.topL, "HORIZONTAL", c1, c2)
        SafeSetGradient(t.topR, "HORIZONTAL", c2, c3)
        SafeSetGradient(t.botL, "HORIZONTAL", c1, c2)
        SafeSetGradient(t.botR, "HORIZONTAL", c2, c3)
        t.left:SetColorTexture(c1.r, c1.g, c1.b, 1)
        t.right:SetColorTexture(c3.r, c3.g, c3.b, 1)
    else
        local orient = config.orientation or "HORIZONTAL"
        if config.invert then orient = (orient == "HORIZONTAL") and "HORIZONTAL_REV" or orient end
        
        if orient == "HORIZONTAL" then
            SafeSetGradient(t.top, "HORIZONTAL", c1, c2)
            SafeSetGradient(t.bot, "HORIZONTAL", c1, c2)
            t.left:SetColorTexture(c1.r, c1.g, c1.b, 1)
            t.right:SetColorTexture(c2.r, c2.g, c2.b, 1)
        elseif orient == "HORIZONTAL_REV" then
            SafeSetGradient(t.top, "HORIZONTAL", c2, c1)
            SafeSetGradient(t.bot, "HORIZONTAL", c2, c1)
            t.left:SetColorTexture(c2.r, c2.g, c2.b, 1)
            t.right:SetColorTexture(c1.r, c1.g, c1.b, 1)
        elseif orient == "VERTICAL" then
            t.top:SetColorTexture(c2.r, c2.g, c2.b, 1)
            t.bot:SetColorTexture(c1.r, c1.g, c1.b, 1)
            SafeSetGradient(t.left, "VERTICAL", c1, c2)
            SafeSetGradient(t.right, "VERTICAL", c1, c2)
        elseif orient == "VERTICAL_REV" then
            t.top:SetColorTexture(c1.r, c1.g, c1.b, 1)
            t.bot:SetColorTexture(c2.r, c2.g, c2.b, 1)
            SafeSetGradient(t.left, "VERTICAL", c2, c1)
            SafeSetGradient(t.right, "VERTICAL", c2, c1)
        end
    end
end

-- =====================================================================
-- 3. UPDATE CONTROLLER
-- =====================================================================
function AUI:UpdateCharacterBorders()
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.borders
    if _G["CharacterFrame"] then
        ApplyGradientBorder(_G["CharacterFrame"], db and db.character, false)
    end
end

function AUI:UpdateStatsPanelBorders()
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.borders
    if _G["AUI_CharacterStatsFrame"] then
        ApplyGradientBorder(_G["AUI_CharacterStatsFrame"], db and db.statsPanel, false)
    end
end

function AUI:UpdateInspectBorders(unit)
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.borders
    local inspectConfig = db and db.inspect
    local targetUnit = unit or (InspectFrame and InspectFrame.unit) or "target"
    if _G["InspectFrame"] then
        ApplyGradientBorder(_G["InspectFrame"], inspectConfig, false, targetUnit)
    end
end

function AUI:UpdateMinimapBagBorders()
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.borders
    local bagConfig = db and db.minimapBag
    if _G["AUI_MinimapBagButton"] then
        ApplyGradientBorder(_G["AUI_MinimapBagButton"], bagConfig, false)
    end
    if _G["AUI_MinimapBagBackdrop"] then
        ApplyGradientBorder(_G["AUI_MinimapBagBackdrop"], bagConfig, false)
    end
end

function AUI:UpdateCalendarBorders()
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.borders
    local calConfig = db and db.calendar
    if _G["AUI_CalendarFrame"] then
        ApplyGradientBorder(_G["AUI_CalendarFrame"], calConfig, false)
    end
    if _G["AUI_CalendarDayManager"] then
        ApplyGradientBorder(_G["AUI_CalendarDayManager"], calConfig, false)
    end
    if _G["AUI_CalendarEditDialog"] then
        ApplyGradientBorder(_G["AUI_CalendarEditDialog"], calConfig, false)
    end
end

function AUI:UpdateEditBoxColors()
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.borders
    local leftChat = db and db.leftChat
    local editBoxConfig = (leftChat and leftChat.enable and leftChat.colorEditBox) and leftChat or nil

    local numWindows = NUM_CHAT_WINDOWS or 10
    for i = 1, numWindows do
        local editBox = _G["ChatFrame"..i.."EditBox"]
        if editBox then
            ApplyGradientBorder(editBox, editBoxConfig, false)
        end
    end
end

function AUI:UpdateBorderColors()
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.borders
    if not db then return end
    
    if _G["ElvUI_TopPanel"] then ApplyGradientBorder(_G["ElvUI_TopPanel"], db.topBottom, true) end
    if _G["ElvUI_BottomPanel"] then ApplyGradientBorder(_G["ElvUI_BottomPanel"], db.topBottom, true) end
    
    if _G["Minimap"] then ApplyGradientBorder(_G["Minimap"], db.minimap, false) end
    if _G["LeftChatPanel"] then ApplyGradientBorder(_G["LeftChatPanel"], db.leftChat, false) end
    if _G["RightChatPanel"] then ApplyGradientBorder(_G["RightChatPanel"], db.rightChat, false) end
    
    if _G["AUI_AltInfoFrame"] then ApplyGradientBorder(_G["AUI_AltInfoFrame"], db.alts, true) end

    AUI:UpdateCharacterBorders()
    AUI:UpdateStatsPanelBorders()
    AUI:UpdateInspectBorders()
    AUI:UpdateMinimapBagBorders()
    AUI:UpdateCalendarBorders()
    AUI:UpdateEditBoxColors()
end

-- =====================================================================
-- 4. DATATEXT FARBEN
-- =====================================================================
local function ProcessSegment(segment, c1, c2)
    if segment == "" then return "" end
    local part1, part2 = segment:match("^(.-)(%s*/.*)$")
    if part1 and part2 then 
        return E:TextGradient(part1, c1.r, c1.g, c1.b, c2.r, c2.g, c2.b) .. part2
    else 
        return E:TextGradient(segment, c1.r, c1.g, c1.b, c2.r, c2.g, c2.b) 
    end
end

local function ApplyGradientToDataText(text, c1, c2)
    if not text or text == "" or type(text) ~= "string" then return text end
    local parts, lastPos = {}, 1
    while lastPos <= #text do
        local cStart, cEnd = text:find("|c%x%x%x%x%x%x%x%x.-|r", lastPos)
        local tStart, tEnd = text:find("|T.-|t", lastPos)
        local s, e = (cStart and tStart) and (cStart < tStart and cStart or tStart) or (cStart or tStart), (cStart and tStart) and (cStart < tStart and cEnd or tEnd) or (cEnd or tEnd)
        if s then
            local before = text:sub(lastPos, s - 1)
            if before ~= "" then table.insert(parts, ProcessSegment(before, c1, c2)) end
            table.insert(parts, text:sub(s, e))
            lastPos = e + 1
        else
            local rest = text:sub(lastPos)
            if rest ~= "" then table.insert(parts, ProcessSegment(rest, c1, c2)) end
            break
        end
    end
    return table.concat(parts)
end

local function Hook_SetText(self, text)
    if isProcessing[self] or not text then return end
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.datatexts
    if not db or not db.enable then return end
    
    local c1, c2
    if db.colorMode == "GRADIENT" then 
        c1, c2 = db.customColor, db.gradientColor
    elseif db.colorMode == "CLASS_GRADIENT" then 
        c1 = E:ClassColor(E.myclass, true)
        c2 = GetDarkerColor(c1)
    else 
        return 
    end
    
    isProcessing[self] = true
    self:SetText(ApplyGradientToDataText(text, c1, c2))
    isProcessing[self] = nil
end

local function Hook_SetFormattedText(self, formatStr, ...)
    if isProcessing[self] or not formatStr then return end
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.datatexts
    if not db or not db.enable then return end
    
    local c1, c2
    if db.colorMode == "GRADIENT" then 
        c1, c2 = db.customColor, db.gradientColor
    elseif db.colorMode == "CLASS_GRADIENT" then 
        c1 = E:ClassColor(E.myclass, true)
        c2 = GetDarkerColor(c1)
    else 
        return 
    end
    
    isProcessing[self] = true
    local success, text = pcall(string.format, formatStr, ...)
    if success and text then self:SetText(ApplyGradientToDataText(text, c1, c2)) end
    isProcessing[self] = nil
end

function AUI:ColorDatatextFonts()
    if not DT then return end
    local panels = DT.RegisteredPanels or DT.Panels
    if not panels then return end
    
    local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.datatexts
    local isEnabled = db and db.enable
    if E.db.datatexts then E.db.datatexts.customLabelColor = false end
    
    local r, g, b = 1, 1, 1 
    if isEnabled and (db.colorMode == "CLASS" or db.colorMode == "CUSTOM") then
        local cc = (db.colorMode == "CUSTOM") and db.customColor or E:ClassColor(E.myclass, true)
        if cc then r, g, b = cc.r, cc.g, cc.b end
    end
    
    for _, panel in pairs(panels) do
        if panel and panel.dataPanels then
            for i = 1, #panel.dataPanels do
                local fs = panel.dataPanels[i] and panel.dataPanels[i].text
                if fs then 
                    fs:SetTextColor(r, g, b)
                    if not fs.auiHooked then 
                        hooksecurefunc(fs, "SetText", Hook_SetText)
                        hooksecurefunc(fs, "SetFormattedText", Hook_SetFormattedText)
                        fs.auiHooked = true 
                    end 
                end
            end
        end
    end
end

-- =====================================================================
-- 5. OPTIONEN-GENERATOR (AUFGERÄUMTES MENÜ)
-- =====================================================================
local function GetBorderInlineGroup(key, title, orderIdx, updateFunc, isThreeColor)
    local isInspect = (key == "inspect")
    local isLeftChat = (key == "leftChat")
    
    local colorModeValues = isInspect and {
        ["TARGET_CLASS"] = L["Target Class Color"] or "Klassenfarbe des Ziels",
        ["TARGET_CLASS_GRADIENT"] = L["Target Class Gradient"] or "Klassen-Verlauf des Ziels",
        ["CLASS"] = L["Own Class Color"] or "Eigene Klassenfarbe",
        ["CLASS_GRADIENT"] = L["Own Class Gradient"] or "Eigener Klassen-Verlauf",
        ["CUSTOM"] = L["Custom"] or "Benutzerdefiniert",
        ["GRADIENT"] = L["Color Gradient"] or "Farbverlauf",
    } or {
        ["CLASS"] = L["Class Color"] or "Klassenfarbe",
        ["CLASS_GRADIENT"] = L["Class Gradient"] or "Klassen-Verlauf",
        ["CUSTOM"] = L["Custom"] or "Benutzerdefiniert",
        ["GRADIENT"] = L["Color Gradient"] or "Farbverlauf",
    }

    local group = {
        order = orderIdx,
        type = "group",
        name = title,
        guiInline = true,
        get = function(info) 
            return E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key][info[#info]]
        end,
        set = function(info, value)
            if not E.db.AUI.coloring.borders[key] then E.db.AUI.coloring.borders[key] = {} end
            E.db.AUI.coloring.borders[key][info[#info]] = value
            if updateFunc then updateFunc() else AUI:UpdateBorderColors() end
        end,
        args = {
            enable = {
                order = 1,
                type = "toggle",
                name = L["Enable"] or "Aktivieren",
                width = "full",
            },
            colorMode = {
                order = 2,
                type = "select",
                name = L["Color Mode"] or "Farbmodus",
                disabled = function() return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) end,
                values = colorModeValues,
            },
        }
    }

    if not isThreeColor then
        group.args.orientation = {
            order = 3,
            type = "select",
            name = L["Gradient Orientation"] or "Verlauf-Ausrichtung",
            disabled = function() 
                local m = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].colorMode
                return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) or (m ~= "GRADIENT" and m ~= "CLASS_GRADIENT" and m ~= "TARGET_CLASS_GRADIENT")
            end,
            values = {
                ["HORIZONTAL"] = L["Horizontal"] or "Horizontal",
                ["VERTICAL"] = L["Vertical"] or "Vertikal",
            },
        }
        group.args.invert = {
            order = 4,
            type = "toggle",
            name = L["Invert Gradient"] or "Verlauf umkehren",
            disabled = function() 
                local m = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].colorMode
                return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) or (m ~= "GRADIENT" and m ~= "CLASS_GRADIENT" and m ~= "TARGET_CLASS_GRADIENT")
            end,
        }
        group.args.color1 = {
            order = 5,
            type = "color",
            name = L["Color 1"] or "Farbe 1 (Start)",
            hasAlpha = false,
            disabled = function() 
                local m = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].colorMode
                return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) or (m ~= "CUSTOM" and m ~= "GRADIENT")
            end,
            get = function()
                local c = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].color1 or {r=1, g=1, b=1}
                return c.r, c.g, c.b, 1
            end,
            set = function(_, r, g, b)
                local c = E.db.AUI.coloring.borders[key].color1
                if not c then c = {}; E.db.AUI.coloring.borders[key].color1 = c end
                c.r, c.g, c.b = r, g, b
                if updateFunc then updateFunc() else AUI:UpdateBorderColors() end
            end,
        }
        group.args.color2 = {
            order = 6,
            type = "color",
            name = L["Color 2"] or "Farbe 2 (Ende)",
            hasAlpha = false,
            disabled = function() 
                local m = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].colorMode
                return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) or (m ~= "GRADIENT")
            end,
            get = function()
                local c = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].color2 or {r=1, g=1, b=1}
                return c.r, c.g, c.b, 1
            end,
            set = function(_, r, g, b)
                local c = E.db.AUI.coloring.borders[key].color2
                if not c then c = {}; E.db.AUI.coloring.borders[key].color2 = c end
                c.r, c.g, c.b = r, g, b
                if updateFunc then updateFunc() else AUI:UpdateBorderColors() end
            end,
        }
    else
        group.args.color1 = {
            order = 3,
            type = "color",
            name = L["Color 1 (Left)"] or "Farbe 1 (Links)",
            hasAlpha = false,
            disabled = function() 
                local m = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].colorMode
                return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) or (m ~= "CUSTOM" and m ~= "GRADIENT")
            end,
            get = function()
                local c = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].color1 or {r=1, g=1, b=1}
                return c.r, c.g, c.b, 1
            end,
            set = function(_, r, g, b)
                local c = E.db.AUI.coloring.borders[key].color1
                if not c then c = {}; E.db.AUI.coloring.borders[key].color1 = c end
                c.r, c.g, c.b = r, g, b
                if updateFunc then updateFunc() else AUI:UpdateBorderColors() end
            end,
        }
        group.args.color2 = {
            order = 4,
            type = "color",
            name = L["Color 2 (Center)"] or "Farbe 2 (Mitte)",
            hasAlpha = false,
            disabled = function() 
                local m = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].colorMode
                return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) or (m ~= "GRADIENT")
            end,
            get = function()
                local c = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].color2 or {r=1, g=1, b=1}
                return c.r, c.g, c.b, 1
            end,
            set = function(_, r, g, b)
                local c = E.db.AUI.coloring.borders[key].color2
                if not c then c = {}; E.db.AUI.coloring.borders[key].color2 = c end
                c.r, c.g, c.b = r, g, b
                if updateFunc then updateFunc() else AUI:UpdateBorderColors() end
            end,
        }
        group.args.color3 = {
            order = 5,
            type = "color",
            name = L["Color 3 (Right)"] or "Farbe 3 (Rechts)",
            hasAlpha = false,
            disabled = function() 
                local m = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].colorMode
                return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) or (m ~= "GRADIENT")
            end,
            get = function()
                local c = E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].color3 or {r=1, g=1, b=1}
                return c.r, c.g, c.b, 1
            end,
            set = function(_, r, g, b)
                local c = E.db.AUI.coloring.borders[key].color3
                if not c then c = {}; E.db.AUI.coloring.borders[key].color3 = c end
                c.r, c.g, c.b = r, g, b
                if updateFunc then updateFunc() else AUI:UpdateBorderColors() end
            end,
        }
    end

    if isLeftChat then
        group.args.colorEditBox = {
            order = 7,
            type = "toggle",
            name = L["Colorize EditBox"] or "Chat-Eingabefeld einfärben",
            desc = L["Apply the same border coloring to the chat editbox."] or "Wendet die gleiche Rahmenfärbung auf das Chat-Eingabefeld an.",
            width = "full",
            disabled = function() return not (E.db.AUI.coloring.borders[key] and E.db.AUI.coloring.borders[key].enable) end,
        }
    end

    return group
end

local function InjectColoringOptions()
    if not E.Options.args.AUI or not E.Options.args.AUI.args then return end
    local coloringGroup = E.Options.args.AUI.args.coloring
    if not coloringGroup then return end

    coloringGroup.childGroups = "tab"
    
    coloringGroup.args = {
        datatextPanels = {
            order = 1,
            type = "group",
            name = L["Datatext & Panels"] or "Datatext & Panels",
            args = {
                datatexts = {
                    order = 1,
                    type = "group",
                    name = L["DataTexts"] or "Datatexte",
                    guiInline = true,
                    get = function(info) return E.db.AUI.coloring.datatexts[info[#info]] end,
                    set = function(info, value) 
                        E.db.AUI.coloring.datatexts[info[#info]] = value
                        if AUI.ColorDatatextFonts then AUI:ColorDatatextFonts() end 
                        if DT and DT.LoadDataTexts then DT:LoadDataTexts() end
                    end,
                    args = {
                        enable = { order = 1, type = "toggle", name = L["Enable"] or "Aktivieren", width = "full" },
                        colorMode = {
                            order = 2,
                            type = "select",
                            name = L["Color Mode"] or "Farbmodus",
                            disabled = function() return not (E.db.AUI.coloring.datatexts and E.db.AUI.coloring.datatexts.enable) end,
                            values = { 
                                ["CLASS"] = L["Class Color"] or "Klassenfarbe", 
                                ["CUSTOM"] = L["Custom Color"] or "Eigene Farbe",
                                ["GRADIENT"] = L["Gradient"] or "Farbverlauf",
                                ["CLASS_GRADIENT"] = L["Class Gradient"] or "Klassenverlauf" 
                            }
                        },
                        customColor = {
                            order = 3,
                            type = "color",
                            name = L["Color 1 (Start)"] or "Farbe 1 (Start)",
                            hasAlpha = false,
                            disabled = function() 
                                local m = E.db.AUI.coloring.datatexts and E.db.AUI.coloring.datatexts.colorMode
                                return not (E.db.AUI.coloring.datatexts and E.db.AUI.coloring.datatexts.enable) or (m == "CLASS" or m == "CLASS_GRADIENT")
                            end,
                            get = function() 
                                local t = (E.db.AUI.coloring.datatexts and E.db.AUI.coloring.datatexts.customColor) or {r=1,g=0.82,b=0}
                                return t.r, t.g, t.b, 1 
                            end,
                            set = function(_, r, g, b) 
                                local t = E.db.AUI.coloring.datatexts.customColor
                                if not t then t = {}; E.db.AUI.coloring.datatexts.customColor = t end
                                t.r, t.g, t.b = r, g, b
                                if AUI.ColorDatatextFonts then AUI:ColorDatatextFonts() end 
                                if DT and DT.LoadDataTexts then DT:LoadDataTexts() end
                            end,
                        },
                        gradientColor = {
                            order = 4,
                            type = "color",
                            name = L["Color 2 (End)"] or "Farbe 2 (Ende)",
                            hasAlpha = false,
                            disabled = function() 
                                local m = E.db.AUI.coloring.datatexts and E.db.AUI.coloring.datatexts.colorMode
                                return not (E.db.AUI.coloring.datatexts and E.db.AUI.coloring.datatexts.enable) or (m == "CLASS" or m == "CUSTOM")
                            end,
                            get = function() 
                                local t = (E.db.AUI.coloring.datatexts and E.db.AUI.coloring.datatexts.gradientColor) or {r=1,g=0.2,b=0}
                                return t.r, t.g, t.b, 1 
                            end,
                            set = function(_, r, g, b) 
                                local t = E.db.AUI.coloring.datatexts.gradientColor
                                if not t then t = {}; E.db.AUI.coloring.datatexts.gradientColor = t end
                                t.r, t.g, t.b = r, g, b
                                if AUI.ColorDatatextFonts then AUI:ColorDatatextFonts() end 
                                if DT and DT.LoadDataTexts then DT:LoadDataTexts() end
                            end,
                        }
                    }
                },
                topBottom = GetBorderInlineGroup("topBottom", L["Top & Bottom Panels"] or "Top & Bottom Panels", 2, function() AUI:UpdateBorderColors() end, true),
            }
        },
        chats = {
            order = 2,
            type = "group",
            name = L["Chats"] or "Chats",
            args = {
                leftChat = GetBorderInlineGroup("leftChat", L["Left Chat"] or "Linker Chat", 1, function() AUI:UpdateBorderColors() end, false),
                rightChat = GetBorderInlineGroup("rightChat", L["Right Chat"] or "Rechter Chat", 2, function() AUI:UpdateBorderColors() end, false),
            }
        },
        minimap = {
            order = 3,
            type = "group",
            name = L["Minimap"] or "Minimap",
            args = {
                minimapGroup = GetBorderInlineGroup("minimap", L["Minimap"] or "Minimap", 1, function() AUI:UpdateBorderColors() end, false),
            }
        },
        characterFrames = {
            order = 4,
            type = "group",
            name = L["Character Frames"] or "Character Frames",
            args = {
                character = GetBorderInlineGroup("character", L["Character Frame"] or "Charakterfenster", 1, function() AUI:UpdateCharacterBorders() end, false),
                statsPanel = GetBorderInlineGroup("statsPanel", L["Stats Panel"] or "Stats Panel", 2, function() AUI:UpdateStatsPanelBorders() end, false),
                inspect = GetBorderInlineGroup("inspect", L["Inspect Frame"] or "Inspect-Fenster", 3, function() AUI:UpdateInspectBorders() end, false),
            }
        },
        qol = {
            order = 5,
            type = "group",
            name = L["A-UI - QoL"] or "A-UI - QoL",
            args = {
                alts = GetBorderInlineGroup("alts", L["Alts Dashboard"] or "Alts Dashboard", 1, function() AUI:UpdateBorderColors() end, true),
                minimapBag = GetBorderInlineGroup("minimapBag", L["Minimap Bag"] or "Minimap Bag", 2, function() AUI:UpdateMinimapBagBorders() end, false),
                calendar = GetBorderInlineGroup("calendar", L["Calendar"] or "Kalender", 3, function() AUI:UpdateCalendarBorders() end, false),
            }
        },
    }
end

-- =====================================================================
-- 6. HOOKS & INITIALISIERUNG
-- =====================================================================
local function HookFrames()
    if _G.CharacterFrame then
        _G.CharacterFrame:HookScript("OnShow", function()
            AUI:UpdateCharacterBorders()
            AUI:UpdateStatsPanelBorders()
        end)
    end

    local function SetupInspectHook()
        if _G.InspectFrame and not _G.InspectFrame.auiHooked then
            _G.InspectFrame:HookScript("OnShow", function(self)
                AUI:UpdateInspectBorders(self.unit)
            end)
            _G.InspectFrame.auiHooked = true
        end
    end

    SetupInspectHook()

    local inspectWatcher = CreateFrame("Frame")
    inspectWatcher:RegisterEvent("ADDON_LOADED")
    inspectWatcher:RegisterEvent("INSPECT_READY")
    inspectWatcher:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" and arg1 == "Blizzard_InspectUI" then
            SetupInspectHook()
        elseif event == "INSPECT_READY" then
            if _G.InspectFrame and _G.InspectFrame:IsShown() then
                AUI:UpdateInspectBorders(_G.InspectFrame.unit)
            end
        end
    end)

    -- Kalender Hook: Wendet die Rahmen sofort beim Öffnen des Kalenders oder der Dialoge an
    if _G.AUI_CalendarFrame then
        _G.AUI_CalendarFrame:HookScript("OnShow", function()
            AUI:UpdateCalendarBorders()
        end)
    end
end

local function HookChatEditBox()
    local CH = E:GetModule('Chat')
    if CH and CH.UpdateEditBoxColor and not CH.auiEditBoxHooked then
        hooksecurefunc(CH, "UpdateEditBoxColor", function()
            local db = E.db.AUI and E.db.AUI.coloring and E.db.AUI.coloring.borders and E.db.AUI.coloring.borders.leftChat
            if db and db.enable and db.colorEditBox then
                AUI:UpdateEditBoxColors()
            end
        end)
        CH.auiEditBoxHooked = true
    end
end

hooksecurefunc(AUI, "InsertOptions", InjectColoringOptions)

local ColorTracker = CreateFrame("Frame")
ColorTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
ColorTracker:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    HookChatEditBox()
    HookFrames()
    E:Delay(1, function() 
        AUI:ColorDatatextFonts() 
        AUI:UpdateBorderColors()
        InjectColoringOptions()
        if DT and DT.LoadDataTexts then DT:LoadDataTexts() end
    end)
    if DT and DT.LoadDataTexts then hooksecurefunc(DT, 'LoadDataTexts', function() AUI:ColorDatatextFonts() end) end
    if DT and DT.UpdatePanelAttributes then hooksecurefunc(DT, 'UpdatePanelAttributes', function() AUI:ColorDatatextFonts() end) end
end)