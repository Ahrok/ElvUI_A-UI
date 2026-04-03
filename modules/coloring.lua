local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local DT = E:GetModule('DataTexts')

local isProcessing = {}

-- =====================================================================
-- HILFSFUNKTIONEN
-- =====================================================================
local function GetDarkerColor(c, factor)
    return { r = c.r * (factor or 0.35), g = c.g * (factor or 0.35), b = c.b * (factor or 0.35) }
end

local function C(c) return CreateColor(c.r, c.g, c.b, 1) end

local function CreateBorderTextures(frame, isThreeColor)
    if not frame.auiGradientBorders then
        frame.auiGradientBorders = {}
        local t = frame.auiGradientBorders
        local mult = E.mult

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

local function ApplyGradientBorder(frame, config, isThreeColor)
    if not frame then return end
    local target = frame.backdrop or frame
    if not target then return end

    local t = CreateBorderTextures(target, isThreeColor)

    if not config.enable then
        for _, tex in pairs(t) do tex:Hide() end
        if target.SetBackdropBorderColor then
            local bc = E.db.general.bordercolor
            target:SetBackdropBorderColor(bc.r, bc.g, bc.b, 1)
        end
        return
    end

    if target.SetBackdropBorderColor then target:SetBackdropBorderColor(0, 0, 0, 0) end

    local c1, c2, c3
    local mode = config.colorMode

    if mode == "CLASS" then
        c1 = E:ClassColor(E.myclass, true); c2 = c1; c3 = c1
    elseif mode == "CUSTOM" then
        c1 = config.color1; c2 = c1; c3 = c1
    elseif mode == "GRADIENT" then
        c1 = config.color1; c2 = config.color2; c3 = config.color3 or c2
    elseif mode == "CLASS_GRADIENT" then
        local cc = E:ClassColor(E.myclass, true)
        local dc = GetDarkerColor(cc, 0.35)
        if isThreeColor then c1, c2, c3 = dc, cc, dc else c1, c2, c3 = cc, dc, dc end
    end

    c1 = c1 or {r=1,g=1,b=1}; c2 = c2 or {r=1,g=1,b=1}; c3 = c3 or {r=1,g=1,b=1}

    for _, tex in pairs(t) do tex:Show(); tex:SetTexture(E.media.blankTex) end

    if isThreeColor then
        t.topL:SetGradient("HORIZONTAL", C(c1), C(c2))
        t.topR:SetGradient("HORIZONTAL", C(c2), C(c3))
        t.botL:SetGradient("HORIZONTAL", C(c1), C(c2))
        t.botR:SetGradient("HORIZONTAL", C(c2), C(c3))
        t.left:SetColorTexture(c1.r, c1.g, c1.b, 1)
        t.right:SetColorTexture(c3.r, c3.g, c3.b, 1)
    else
        local orient = config.orientation or "HORIZONTAL"
        if config.invert then orient = (orient == "HORIZONTAL") and "HORIZONTAL_REV" or orient end

        if orient == "HORIZONTAL" then
            t.top:SetGradient("HORIZONTAL", C(c1), C(c2))
            t.bot:SetGradient("HORIZONTAL", C(c1), C(c2))
            t.left:SetColorTexture(c1.r, c1.g, c1.b, 1)
            t.right:SetColorTexture(c2.r, c2.g, c2.b, 1)
        elseif orient == "HORIZONTAL_REV" then
            t.top:SetGradient("HORIZONTAL", C(c2), C(c1))
            t.bot:SetGradient("HORIZONTAL", C(c2), C(c1))
            t.left:SetColorTexture(c2.r, c2.g, c2.b, 1)
            t.right:SetColorTexture(c1.r, c1.g, c1.b, 1)
        elseif orient == "VERTICAL" then
            t.top:SetColorTexture(c2.r, c2.g, c2.b, 1)
            t.bot:SetColorTexture(c1.r, c1.g, c1.b, 1)
            t.left:SetGradient("VERTICAL", C(c1), C(c2))
            t.right:SetGradient("VERTICAL", C(c1), C(c2))
        elseif orient == "VERTICAL_REV" then
            t.top:SetColorTexture(c1.r, c1.g, c1.b, 1)
            t.bot:SetColorTexture(c2.r, c2.g, c2.b, 1)
            t.left:SetGradient("VERTICAL", C(c2), C(c1))
            t.right:SetGradient("VERTICAL", C(c2), C(c1))
        end
    end
end

-- =====================================================================
-- UPDATE CONTROLLER
-- =====================================================================
function AUI:UpdateBorderColors()
    local db = E.db.AUI.coloring and E.db.AUI.coloring.borders
    if not db then return end

    ApplyGradientBorder(_G["ElvUI_TopPanel"], db.topBottom, true)
    ApplyGradientBorder(_G["ElvUI_BottomPanel"], db.topBottom, true)
    
    ApplyGradientBorder(_G["Minimap"], db.minimap, false)
    ApplyGradientBorder(_G["LeftChatPanel"], db.leftChat, false)
    ApplyGradientBorder(_G["RightChatPanel"], db.rightChat, false)
end

-- =====================================================================
-- DATATEXT FARBEN
-- =====================================================================
local function ProcessSegment(segment, c1, c2)
    if segment == "" then return "" end
    local part1, part2 = segment:match("^(.-)(%s*/.*)$")
    if part1 and part2 then return E:TextGradient(part1, c1.r, c1.g, c1.b, c2.r, c2.g, c2.b) .. part2
    else return E:TextGradient(segment, c1.r, c1.g, c1.b, c2.r, c2.g, c2.b) end
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
    local db = E.db.AUI.coloring.datatexts
    if not db or not db.enable then return end
    local c1, c2
    if db.colorMode == "GRADIENT" then c1, c2 = db.customColor, db.gradientColor
    elseif db.colorMode == "CLASS_GRADIENT" then c1 = E:ClassColor(E.myclass, true); c2 = GetDarkerColor(c1)
    else return end
    isProcessing[self] = true
    self:SetText(ApplyGradientToDataText(text, c1, c2))
    isProcessing[self] = nil
end

local function Hook_SetFormattedText(self, formatStr, ...)
    if isProcessing[self] or not formatStr then return end
    local db = E.db.AUI.coloring.datatexts
    if not db or not db.enable then return end
    local c1, c2
    if db.colorMode == "GRADIENT" then c1, c2 = db.customColor, db.gradientColor
    elseif db.colorMode == "CLASS_GRADIENT" then c1 = E:ClassColor(E.myclass, true); c2 = GetDarkerColor(c1)
    else return end
    isProcessing[self] = true
    local success, text = pcall(string.format, formatStr, ...)
    if success and text then self:SetText(ApplyGradientToDataText(text, c1, c2)) end
    isProcessing[self] = nil
end

function AUI:ColorDatatextFonts()
    if not DT or not DT.RegisteredPanels then return end
    local db = E.db.AUI.coloring.datatexts
    local isEnabled = db and db.enable
    if E.db.datatexts then E.db.datatexts.customLabelColor = false end
    local r, g, b = 1, 1, 1 
    if isEnabled and (db.colorMode == "CLASS" or db.colorMode == "CUSTOM") then
        local cc = (db.colorMode == "CUSTOM") and db.customColor or E:ClassColor(E.myclass, true)
        if cc then r, g, b = cc.r, cc.g, cc.b end
    end
    for _, panel in pairs(DT.RegisteredPanels) do
        if panel and panel.dataPanels then
            for i = 1, #panel.dataPanels do
                local fs = panel.dataPanels[i] and panel.dataPanels[i].text
                if fs then fs:SetTextColor(r, g, b)
                if not fs.auiHooked then 
                    hooksecurefunc(fs, "SetText", Hook_SetText)
                    hooksecurefunc(fs, "SetFormattedText", Hook_SetFormattedText)
                    fs.auiHooked = true 
                end end
            end
        end
    end
end

-- =====================================================================
-- INIT
-- =====================================================================
local ColorTracker = CreateFrame("Frame")
ColorTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
ColorTracker:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    E:Delay(3, function() 
        AUI:ColorDatatextFonts() 
        AUI:UpdateBorderColors()
        if DT.LoadDataTexts then DT:LoadDataTexts() end
    end)
    if DT and DT.LoadDataTexts then hooksecurefunc(DT, 'LoadDataTexts', function() AUI:ColorDatatextFonts() end) end
    if DT and DT.UpdatePanelAttributes then hooksecurefunc(DT, 'UpdatePanelAttributes', function() AUI:ColorDatatextFonts() end) end
end)