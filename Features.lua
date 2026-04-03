local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

local LCG = LibStub('LibCustomGlow-1.0', true)

-----------------------------------------------------------------------
-- HELPER FUNKTIONEN
-----------------------------------------------------------------------
local function AUIPrint(msg)
    print("|TInterface\\AddOns\\ElvUI_A-UI\\media\\A-UI.tga:16:16|t |cff00ffd2A-UI:|r " .. msg)
end

local function GetButtonData(btnName)
    if not AUI.buttons then return nil end
    for i, data in ipairs(AUI.buttons) do
        if data.btn and data.btn:GetName() == btnName then
            return data
        end
    end
    return nil
end

local function StartGlow(frame, style)
    if style == "pixel" and LCG then
        LCG.PixelGlow_Start(frame, {1, 0.82, 0, 0.95}, 8, 0.25, 6, 2)
    elseif style == "autocast" and LCG then
        LCG.AutoCastGlow_Start(frame, {1, 0.82, 0, 1}, 4, 0.25, 1)
    elseif style == "blizzard" and LCG then
        LCG.ButtonGlow_Start(frame, {1, 0.82, 0, 1})
    else
        if ActionButton_ShowOverlayGlow then ActionButton_ShowOverlayGlow(frame) end
    end
end

local function StopGlow(frame)
    if LCG then
        LCG.PixelGlow_Stop(frame)
        LCG.AutoCastGlow_Stop(frame)
        LCG.ButtonGlow_Stop(frame)
    end
    if ActionButton_HideOverlayGlow then ActionButton_HideOverlayGlow(frame) end
end

-----------------------------------------------------------------------
-- ALLE GLOW UPDATES
-----------------------------------------------------------------------
function AUI:UpdateTalentGlow()
    local data = GetButtonData("TalentMicroButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)

    local unspent = (C_ClassTalents.HasUnspentTalentPoints() or C_ClassTalents.HasUnspentHeroTalentPoints())
    if E.db.AUI.microbar.talentGlow and unspent then
        StartGlow(data.texFrame, E.db.AUI.microbar.talentGlowStyle)
        data.isGlowing = true
    else
        data.isGlowing = false
    end
end

function AUI:UpdateMailGlow()
    local data = GetButtonData("AUI_MailButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)

    local hasMail = HasNewMail()
    if E.db.AUI.microbar.showMailButton and E.db.AUI.microbar.mailGlow and hasMail then
        StartGlow(data.texFrame, E.db.AUI.microbar.mailGlowStyle)
        data.isMailGlowing = true
    else
        data.isMailGlowing = false
    end
    
    if E.db.AUI.microbar.mailColorEnable and hasMail then
        data.iconTex:SetDesaturated(false)
        data.iconTex:SetVertexColor(E.db.AUI.microbar.mailColor.r, E.db.AUI.microbar.mailColor.g, E.db.AUI.microbar.mailColor.b)
    else
        AUI:UpdateIcons() -- Stellt Standard-Farben wieder her
    end

    if E.db.AUI.microbar.hideMailEmpty then AUI:UpdateMicrobar() end
end

function AUI:UpdateVaultGlow()
    local data = GetButtonData("EJMicroButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)

    if E.db.AUI.microbar.vaultGlow and C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards() then
        StartGlow(data.texFrame, E.db.AUI.microbar.vaultGlowStyle)
    end
end

function AUI:UpdateCalendarGlow()
    local data = GetButtonData("AUI_CalendarButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)

    local pending = (C_Calendar and C_Calendar.GetNumPendingInvites()) or 0
    if E.db.AUI.microbar.calendarGlow and pending > 0 then
        StartGlow(data.texFrame, E.db.AUI.microbar.calendarGlowStyle)
    end
end

function AUI:UpdateCollectionsGlow()
    local data = GetButtonData("CollectionsMicroButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)

    local needsFanfare = false
    if C_MountJournal and C_MountJournal.GetNumMountsNeedingFanfare() > 0 then needsFanfare = true end
    if C_PetJournal and C_PetJournal.GetNumPetsNeedingFanfare() > 0 then needsFanfare = true end
    
    if E.db.AUI.microbar.collectionsGlow and needsFanfare then
        StartGlow(data.texFrame, E.db.AUI.microbar.collectionsGlowStyle)
    end
end

function AUI:UpdateAllGlows()
    AUI:UpdateTalentGlow()
    AUI:UpdateMailGlow()
    AUI:UpdateVaultGlow()
    AUI:UpdateCalendarGlow()
    AUI:UpdateCollectionsGlow()
end

-----------------------------------------------------------------------
-- FISH-EYE HOVER (Pop-Up Effekt)
-----------------------------------------------------------------------
function AUI:SetupFisheye()
    if not AUI.buttons then return end
    for _, data in ipairs(AUI.buttons) do
        local wrapper = data.wrapper
        local texFrame = data.texFrame
        local blizzBtn = data.btn
        
        if blizzBtn and not blizzBtn.fisheyeHooked then
            blizzBtn:HookScript("OnEnter", function()
                if E.db.AUI.microbar.fisheye then
                    texFrame:SetScale(1.2) 
                    wrapper:SetFrameLevel(20) 
                end
            end)
            blizzBtn:HookScript("OnLeave", function()
                texFrame:SetScale(1) 
                wrapper:SetFrameLevel(10)
            end)
            blizzBtn.fisheyeHooked = true
        end
    end
end

-----------------------------------------------------------------------
-- INITIALISIERUNG DER FEATURES
-----------------------------------------------------------------------
function AUI:InitFeatures()
    AUI:RegisterEvent("TRAIT_CONFIG_UPDATED", "UpdateTalentGlow")
    AUI:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTalentGlow")
    
    AUI:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMailGlow")
    AUI:RegisterEvent("MAIL_SHOW", "UpdateMailGlow")
    AUI:RegisterEvent("MAIL_CLOSED", "UpdateMailGlow")
    
    AUI:RegisterEvent("WEEKLY_REWARDS_UPDATE", "UpdateVaultGlow")
    AUI:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES", "UpdateCalendarGlow")
    AUI:RegisterEvent("PET_JOURNAL_LIST_UPDATE", "UpdateCollectionsGlow")
    AUI:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED", "UpdateCollectionsGlow")
    AUI:RegisterEvent("HEIRLOOMS_UPDATED", "UpdateCollectionsGlow")
    
    AUI:SetupFisheye()
    
    E:Delay(3, function() 
        AUI:UpdateAllGlows()
    end)
end

-----------------------------------------------------------------------
-- ACE-GUI TRANSFER FENSTER (VERBESSERT FÜR ELVUI)
-----------------------------------------------------------------------
function AUI:ShowTransferWindow(isExport, exportString)
    local AceGUI = LibStub("AceGUI-3.0")
    
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(isExport and "|cff1784d1ElvUI|r |cff00ffd2A-UI|r - " .. (L["Export"] or "Export") or "|cff1784d1ElvUI|r |cff00ffd2A-UI|r - " .. (L["Import"] or "Import"))
    frame:SetWidth(500)
    frame:SetHeight(isExport and 350 or 250)
    frame.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    
    if isExport then
        frame:SetLayout("Fill")
        local editBox = AceGUI:Create("MultiLineEditBox")
        editBox:SetFullWidth(true)
        -- Zeigt das aktuell aktive ElvUI Profil an!
        editBox:SetLabel((L["Profile: "] or "Profil: ") .. "|cff00ffd2" .. E.data:GetCurrentProfile() .. "|r\n\n" .. (L["Copy the string with Ctrl+C:"] or "Kopiere den Text mit Strg+C:"))
        editBox:SetText(exportString)
        if editBox.DisableButton then editBox:DisableButton(true) end
        frame:AddChild(editBox)
    else
        frame:SetLayout("Flow")
        local editBox = AceGUI:Create("MultiLineEditBox")
        editBox:SetFullWidth(true)
        editBox:SetLabel(L["1. Paste the profile string here (Ctrl+V):"] or "1. Füge den Profil-Text hier ein (Strg+V):")
        if editBox.button then editBox.button:Hide() end 
        frame:AddChild(editBox)
        
        local spacer = AceGUI:Create("Heading")
        spacer:SetText("")
        spacer:SetFullWidth(true)
        frame:AddChild(spacer)
        
        local importBtn = AceGUI:Create("Button")
        importBtn:SetText(L["Import"] or "Importieren")
        importBtn:SetRelativeWidth(0.48)
        importBtn:SetCallback("OnClick", function()
            local text = editBox:GetText()
            AUI:ImportProfile(text)
            frame:Release()
        end)
        frame:AddChild(importBtn)
        
        local cancelBtn = AceGUI:Create("Button")
        cancelBtn:SetText(L["Cancel"] or "Abbrechen")
        cancelBtn:SetRelativeWidth(0.48)
        cancelBtn:SetCallback("OnClick", function() frame:Release() end)
        frame:AddChild(cancelBtn)
    end
end

-----------------------------------------------------------------------
-- PROFIL EXPORT / IMPORT LOGIK MIT ERROR HANDLING
-----------------------------------------------------------------------
function AUI:ExportProfile()
    local profileData = E.db.AUI.microbar
    local LibSerialize = LibStub("LibSerialize", true)
    local LibDeflate = LibStub("LibDeflate", true)
    
    local exportString
    if LibSerialize and LibDeflate then
        local serialized = LibSerialize:Serialize(profileData)
        local compressed = LibDeflate:CompressDeflate(serialized)
        exportString = LibDeflate:EncodeForPrint(compressed)
    else
        AUIPrint(L["Warning: LibDeflate not found. Using standard ElvUI export."] or "Warnung: LibDeflate nicht gefunden. Nutze Standard-Export.")
        local serialData = E:Serialize(profileData)
        exportString = E:Config_Encode(serialData)
    end
    
    if exportString then
        AUI:ShowTransferWindow(true, exportString)
    else
        AUIPrint(L["Critical Error: Profile could not be converted to a string."] or "Kritischer Fehler beim Exportieren.")
    end
end

function AUI:ImportProfile(importString)
    if not importString or importString == "" then 
        AUIPrint(L["Error: The text field is empty. Please paste a profile string."] or "Fehler: Das Textfeld ist leer.")
        return 
    end
    
    local LibSerialize = LibStub("LibSerialize", true)
    local LibDeflate = LibStub("LibDeflate", true)
    local success, profile = false, nil
    
    if LibSerialize and LibDeflate then
        local decoded = LibDeflate:DecodeForPrint(importString)
        if decoded then
            local decompressed = LibDeflate:DecompressDeflate(decoded)
            if decompressed then success, profile = LibSerialize:Deserialize(decompressed) end
        end
    end

    if not success or not profile then
        local decSuccess, data = E:Config_Decode(importString)
        if decSuccess and data then success, profile = E:Deserialize(data) end
    end
    
    if success and profile then
        AUIPrint(L["Settings were imported into the active profile."] or "Einstellungen wurden erfolgreich ins aktuelle Profil importiert.")
        
        E.db.AUI.microbar = profile
        E:StaticPopup_Show("PRIVATE_RL")
    else
        AUIPrint(L["|cffff0000Critical error during import!|r"] or "|cffff0000Kritischer Fehler beim Import!|r")
        AUIPrint(L["The pasted string is invalid, incomplete, or does not originate from A-UI."] or "Der eingefügte Text ist ungültig oder stammt nicht von A-UI.")
    end
end