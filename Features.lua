local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local LCG = LibStub('LibCustomGlow-1.0', true)
local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

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
    if not frame then return end
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
    if not frame then return end
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
    local data = GetButtonData("PlayerSpellsMicroButton") or GetButtonData("TalentMicroButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)
    
    local unspent = false
    if isRetail and C_ClassTalents and C_ClassTalents.HasUnspentTalentPoints then
        unspent = (C_ClassTalents.HasUnspentTalentPoints() or (C_ClassTalents.HasUnspentHeroTalentPoints and C_ClassTalents.HasUnspentHeroTalentPoints()))
    elseif GetNumUnspentTalents then
        unspent = (GetNumUnspentTalents() or 0) > 0
    elseif UnitCharacterPoints then
        unspent = (UnitCharacterPoints("player") or 0) > 0
    end
    
    if E.db.AUI.microbar.talentGlow and unspent then
        StartGlow(data.texFrame, E.db.AUI.microbar.glowType or "pixel")
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
        StartGlow(data.texFrame, E.db.AUI.microbar.glowType or "pixel")
        data.isMailGlowing = true
    else
        data.isMailGlowing = false
    end
    
    if E.db.AUI.microbar.mailColorEnable and hasMail then
        data.iconTex:SetDesaturated(false)
        data.iconTex:SetVertexColor(E.db.AUI.microbar.mailColor.r, E.db.AUI.microbar.mailColor.g, E.db.AUI.microbar.mailColor.b)
    else
        AUI:UpdateIcons()
    end
    
    if E.db.AUI.microbar.hideMailEmpty and AUI.UpdateMicrobar then AUI:UpdateMicrobar() end
end

function AUI:UpdateVaultGlow()
    if not isRetail then return end
    local data = GetButtonData("EJMicroButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)
    if E.db.AUI.microbar.vaultGlow and C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards() then
        StartGlow(data.texFrame, E.db.AUI.microbar.glowType or "pixel")
    end
end

function AUI:UpdateCalendarGlow()
    local data = GetButtonData("AUI_CalendarButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)
    local pending = (C_Calendar and C_Calendar.GetNumPendingInvites and C_Calendar.GetNumPendingInvites()) or 0
    if E.db.AUI.microbar.calendarGlow and pending > 0 then
        StartGlow(data.texFrame, E.db.AUI.microbar.glowType or "pixel")
    end
end

function AUI:UpdateCollectionsGlow()
    if not isRetail then return end
    local data = GetButtonData("CollectionsMicroButton")
    if not data or not data.texFrame then return end
    StopGlow(data.texFrame)
    local needsFanfare = false
    if C_MountJournal and C_MountJournal.GetNumMountsNeedingFanfare and C_MountJournal.GetNumMountsNeedingFanfare() > 0 then needsFanfare = true end
    if C_PetJournal and C_PetJournal.GetNumPetsNeedingFanfare and C_PetJournal.GetNumPetsNeedingFanfare() > 0 then needsFanfare = true end
    
    if E.db.AUI.microbar.collectionsGlow and needsFanfare then
        StartGlow(data.texFrame, E.db.AUI.microbar.glowType or "pixel")
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
-- FISH-EYE HOVER
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
local function SafeRegister(event, handler)
    pcall(function() AUI:RegisterEvent(event, handler) end)
end

function AUI:InitFeatures()
    -- Universelle & Retail Events sicher registrieren
    SafeRegister("TRAIT_CONFIG_UPDATED", "UpdateTalentGlow")
    SafeRegister("PLAYER_TALENT_UPDATE", "UpdateTalentGlow")
    SafeRegister("CHARACTER_POINTS_CHANGED", "UpdateTalentGlow")
    
    SafeRegister("UPDATE_PENDING_MAIL", "UpdateMailGlow")
    SafeRegister("MAIL_SHOW", "UpdateMailGlow")
    SafeRegister("MAIL_CLOSED", "UpdateMailGlow")
    
    if isRetail then
        SafeRegister("WEEKLY_REWARDS_UPDATE", "UpdateVaultGlow")
        SafeRegister("CALENDAR_UPDATE_PENDING_INVITES", "UpdateCalendarGlow")
        SafeRegister("PET_JOURNAL_LIST_UPDATE", "UpdateCollectionsGlow")
        SafeRegister("MOUNT_JOURNAL_USABILITY_CHANGED", "UpdateCollectionsGlow")
        SafeRegister("HEIRLOOMS_UPDATED", "UpdateCollectionsGlow")
    end
    
    AUI:SetupFisheye()
    
    E:Delay(3, function() 
        AUI:UpdateAllGlows()
    end)
end

-----------------------------------------------------------------------
-- ACE-GUI TRANSFER FENSTER
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
-- PROFIL EXPORT / IMPORT LOGIK
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