local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local DT = E:GetModule('DataTexts')

local function DT_OnClick(self, button)
    if button == "LeftButton" then
        local db = E.db.AUI.microbar
        db.enable = not db.enable
        if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end
    else
        if _G.ElvUI_AUI_CompartmentClick then
            _G.ElvUI_AUI_CompartmentClick()
        end
    end
end

local function DT_OnEnter(self)
    DT:SetupTooltip(self)
    DT.tooltip:AddLine("|TInterface\\AddOns\\ElvUI_A-UI\\media\\A-UI.tga:16:16|t |cff00ffd2A-UI|r Microbar")
    DT.tooltip:AddLine(L["Left Click: Toggle Microbar"] or "Links-Klick: Microbar Umschalten", 1, 1, 1)
    DT.tooltip:AddLine(L["Right Click: Open Options"] or "Rechts-Klick: Optionen Öffnen", 1, 1, 1)
    DT.tooltip:Show()
end

local function DT_OnEvent(self)
    self.text:SetText("|cff00ffd2A-UI|r")
end

DT:RegisterDatatext("A-UI", "A-UI", {"PLAYER_ENTERING_WORLD"}, DT_OnEvent, nil, DT_OnClick, DT_OnEnter, nil, "A-UI")