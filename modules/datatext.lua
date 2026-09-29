local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local DT = E:GetModule('DataTexts')

local function OpenConfig()
    if _G.ElvUI_AUI_CompartmentClick then
        _G.ElvUI_AUI_CompartmentClick()
    elseif E.ToggleOptions then
        E:ToggleOptions()
        E:Delay(0.1, function()
            local ACD = E.Libs and (E.Libs.AceConfigDialog or LibStub("AceConfigDialog-3.0", true))
            if ACD then ACD:SelectGroup("ElvUI", "AUI") end
        end)
    end
end

local function DT_OnClick(self, button)
    if button == "LeftButton" then
        local db = E.db.AUI and E.db.AUI.microbar
        if db then
            db.enable = not db.enable
            if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end
        end
    elseif button == "RightButton" then
        OpenConfig()
    elseif button == "MiddleButton" then
        if _G["AUI_AltInfoFrame"] then
            if _G["AUI_AltInfoFrame"]:IsShown() then
                _G["AUI_AltInfoFrame"]:Hide()
            else
                if AUI.UpdateAltUI then AUI:UpdateAltUI() end
                _G["AUI_AltInfoFrame"]:Show()
            end
        end
    end
end

local function DT_OnEnter(self)
    if DT.SetupTooltip then DT:SetupTooltip(self) end
    local tip = DT.tooltip or GameTooltip
    
    tip:ClearLines()
    tip:AddLine("|TInterface\\AddOns\\ElvUI_A-UI\\media\\A-UI.tga:16:16|t |cff00ffd2A-UI|r", 1, 1, 1)
    tip:AddLine(" ")
    tip:AddDoubleLine(L["Left Click:"] or "Links-Klick:", L["Toggle Microbar"] or "Microbar Umschalten", 1, 0.82, 0, 1, 1, 1)
    tip:AddDoubleLine(L["Middle Click:"] or "Mittel-Klick:", L["Open Alt Dashboard"] or "Alts-Dashboard öffnen", 1, 0.82, 0, 1, 1, 1)
    tip:AddDoubleLine(L["Right Click:"] or "Rechts-Klick:", L["Open Options"] or "Optionen öffnen", 1, 0.82, 0, 1, 1, 1)
    tip:Show()
end

local function DT_OnEvent(self)
    self.text:SetText("|cff00ffd2A-UI|r")
end

-- Registrierung im ElvUI DataText-System
if DT and DT.RegisterDatatext then
    DT:RegisterDatatext("A-UI", "A-UI", {"PLAYER_ENTERING_WORLD"}, DT_OnEvent, nil, DT_OnClick, DT_OnEnter, nil, "A-UI")
end