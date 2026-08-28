local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

function AUI:UpdateAlpha()
    local bar = _G["AUI_Microbar"]
    if not bar then return end
    local db = E.db.AUI and E.db.AUI.microbar
    if not db then return end
    
    if db.mouseover then
        if bar:IsMouseOver() then 
            E:UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), 1)
        else 
            E:UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), 0) 
        end
    else 
        E:UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), 1) 
    end
end

function AUI:UpdateVisibility()
    local bar = _G["AUI_Microbar"]
    if not bar then return end
    local db = E.db.AUI and E.db.AUI.microbar
    if not db then return end
    
    UnregisterStateDriver(bar, "visibility")
    if not db.enable then 
        bar:Hide()
        return 
    end
    
    local visString = db.visibilityStr
    if not visString or visString == "" then visString = "show" end
    RegisterStateDriver(bar, "visibility", visString)
    AUI:UpdateAlpha()
end

function AUI:UpdateIcons()
    if not AUI.buttons then return end
    local db = E.db.AUI and E.db.AUI.microbar
    if not db then return end
    local LCG = (E.Libs and E.Libs.CustomGlow) or LibStub('LibCustomGlow-1.0', true)
    
    for i, data in ipairs(AUI.buttons) do
        local tex = data.iconTex
        if tex then
            local userIcon = db.customIcons and db.customIcons[i]
            if not userIcon or userIcon == "" then userIcon = data.id end
            
            if userIcon == "portrait" then 
                SetPortraitTexture(tex, "player")
                tex:SetTexCoord(0.15, 0.85, 0.15, 0.85)
                tex:SetDesaturated(false)
                tex:SetVertexColor(1, 1, 1)
            else 
                if data.btn:GetName() == "AUI_CalendarButton" then
                    local day = date("%d")
                    if not userIcon or userIcon == "" or userIcon == "dynamic_a" or userIcon == "dynamic_calendar" then
                        tex:SetTexture("Interface\\AddOns\\ElvUI_A-UI\\media\\calendar\\a" .. day .. ".tga")
                    elseif userIcon == "dynamic_b" then
                        tex:SetTexture("Interface\\AddOns\\ElvUI_A-UI\\media\\calendar\\b" .. day .. ".tga")
                    elseif userIcon == "dynamic_c" then
                        tex:SetTexture("Interface\\AddOns\\ElvUI_A-UI\\media\\calendar\\c" .. day .. ".tga")
                    else
                        tex:SetTexture(tonumber(userIcon) or userIcon)
                    end
                else
                    tex:SetTexture(tonumber(userIcon) or userIcon)
                end
                
                tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                
                local isMailAndHasNew = (data.btn:GetName() == "AUI_MailButton" and HasNewMail())
                
                if isMailAndHasNew then
                    if db.mailColorEnable and db.mailColor then
                        tex:SetDesaturated(false)
                        tex:SetVertexColor(db.mailColor.r, db.mailColor.g, db.mailColor.b)
                    end
                    
                    if db.glowEnable and db.mailGlow and LCG then
                        if db.glowType == "pixel" then LCG.PixelGlow_Start(data.wrapper)
                        elseif db.glowType == "autocast" then LCG.AutoCastGlow_Start(data.wrapper)
                        else LCG.ButtonGlow_Start(data.wrapper) end
                    end
                else
                    tex:SetDesaturated(db.desaturateAll)
                    
                    if db.colorAll then
                        if db.globalClassColor then
                            local classColor = E:ClassColor(E.myclass) or RAID_CLASS_COLORS[E.myclass]
                            if classColor then tex:SetVertexColor(classColor.r, classColor.g, classColor.b)
                            else tex:SetVertexColor(1, 1, 1) end
                        else
                            local gc = db.globalIconColor or {r=1, g=1, b=1}
                            tex:SetVertexColor(gc.r, gc.g, gc.b)
                        end
                    elseif db.individualIconColors and db.individualIconColors[i] then
                        local c = db.individualIconColors[i]
                        tex:SetVertexColor(c.r, c.g, c.b)
                    else
                        tex:SetVertexColor(1, 1, 1)
                    end
                    
                    if LCG then
                        LCG.PixelGlow_Stop(data.wrapper)
                        LCG.AutoCastGlow_Stop(data.wrapper)
                        LCG.ButtonGlow_Stop(data.wrapper)
                    end
                end
            end
        end
    end
end

local function GetStyleColor(prefix, typeStr)
    local db = E.db.AUI and E.db.AUI.microbar
    if not db then return 1, 1, 1 end
    local key = prefix .. typeStr
    
    if db[key.."ColorEnable"] then
        if db[key.."ClassColor"] then
            local color = E:ClassColor(E.myclass) or RAID_CLASS_COLORS[E.myclass]
            if color then return color.r, color.g, color.b end
        else 
            local c = db[key.."Color"]
            if c then return c.r, c.g, c.b end
        end
    end
    
    if typeStr == "Border" then
        return unpack(E.media.bordercolor)
    else
        return unpack(E.media.backdropcolor)
    end
end

function AUI:UpdateMicrobar()
    if InCombatLockdown() then
        AUI.MicrobarNeedsUpdate = true
        return
    end
    local db = E.db.AUI and E.db.AUI.microbar
    local bar = _G["AUI_Microbar"]
    if not bar or not db then return end
    
    AUI:UpdateVisibility()
    if not db.enable then return end
    
    local activeButtons = {}
    local hasMail = HasNewMail()
    
    for i, data in ipairs(AUI.buttons) do
        local btnName = data.btn:GetName()
        
        if btnName == "AUI_MailButton" then
            if not db.showMailButton then data.wrapper:Hide()
            elseif db.hideMailEmpty and not hasMail then data.wrapper:Hide()
            else data.wrapper:Show(); table.insert(activeButtons, data) end
            
        elseif btnName == "AUI_CalendarButton" then
            if not db.showCalendarButton then data.wrapper:Hide()
            else data.wrapper:Show(); table.insert(activeButtons, data) end
            
        elseif btnName == "AUI_TeleportButton" then
            if db.showTeleportButton == false then data.wrapper:Hide()
            else data.wrapper:Show(); table.insert(activeButtons, data) end
            
        elseif btnName == "AUI_DelveButton" then
            if not isRetail or db.showDelveButton == false then data.wrapper:Hide()
            else data.wrapper:Show(); table.insert(activeButtons, data) end
            
        elseif btnName == "AUI_AltsButton" then
            if db.showAltsButton == false then data.wrapper:Hide()
            else data.wrapper:Show(); table.insert(activeButtons, data) end
            
        else
            data.wrapper:Show(); table.insert(activeButtons, data)
        end
    end
    
    local padding = db.barPadding or 4
    local count = #activeButtons
    local buttonsPerRow = db.buttonsPerRow or 15
    local numCols = math.min(count, buttonsPerRow)
    local numRows = math.ceil(count / buttonsPerRow)
    
    if count > 0 then
        bar:SetSize((padding * 2) + (db.size * numCols) + (db.spacing * (numCols - 1)), (padding * 2) + (db.size * numRows) + (db.spacing * (numRows - 1)))
    else 
        bar:SetSize(padding * 2, padding * 2) 
    end
    
    for i, data in ipairs(activeButtons) do
        local wrapper = data.wrapper
        local visual = data.visual
        
        wrapper:SetSize(db.size, db.size)
        wrapper:ClearAllPoints()
        
        local displayIndex = db.reverseOrder and (count - i + 1) or i
        local col = (displayIndex - 1) % buttonsPerRow
        local row = math.floor((displayIndex - 1) / buttonsPerRow)
        local xPos = padding + (col * (db.size + db.spacing))
        local yPos = -(padding + (row * (db.size + db.spacing)))
        wrapper:SetPoint("TOPLEFT", bar, "TOPLEFT", xPos, yPos)
        
        visual:SetSize(db.size, db.size)
        visual:ClearAllPoints()
        visual:SetPoint("CENTER", wrapper, "CENTER", 0, 0)
        
        local innerSize = (db.buttonBackdrop or db.buttonBorder) and (db.size - 2) or db.size
        data.texFrame:SetSize(innerSize, innerSize)
        if not db.buttonBackdrop and not db.buttonBorder then 
            visual:SetTemplate("NoBackdrop")
        else
            visual:SetTemplate(db.buttonBackdrop and "Transparent" or "Default")
            if not db.buttonBackdrop then 
                visual:SetBackdropColor(0, 0, 0, 0)
            else 
                local r, g, b = GetStyleColor("button", "Backdrop")
                visual:SetBackdropColor(r, g, b, db.buttonBackdropAlpha or 0.5) 
            end
            
            if not db.buttonBorder then 
                visual:SetBackdropBorderColor(0, 0, 0, 0)
            else 
                local r, g, b = GetStyleColor("button", "Border")
                visual:SetBackdropBorderColor(r, g, b, 1) 
            end
        end
        data.texFrame:SetScale(1)
        visual:SetFrameLevel(10)
    end
    
    if not db.barBackdrop and not db.barBorder then
        bar:SetTemplate("NoBackdrop")
    else
        bar:SetTemplate(db.barBackdrop and "Transparent" or "Default")
        if not db.barBackdrop then 
            bar:SetBackdropColor(0, 0, 0, 0)
        else
            local r, g, b = GetStyleColor("bar", "Backdrop")
            bar:SetBackdropColor(r, g, b, db.barBackdropAlpha or 0.5)
        end
        
        if not db.barBorder then 
            bar:SetBackdropBorderColor(0, 0, 0, 0)
        else 
            local r, g, b = GetStyleColor("bar", "Border")
            bar:SetBackdropBorderColor(r, g, b, 1)
        end
    end
end

local CombatCatch = CreateFrame("Frame")
CombatCatch:RegisterEvent("PLAYER_REGEN_ENABLED")
CombatCatch:SetScript("OnEvent", function()
    if AUI.MicrobarNeedsUpdate then
        AUI.MicrobarNeedsUpdate = false
        if AUI.UpdateMicrobar then 
            AUI:UpdateMicrobar() 
        end
    end
end)

function AUI:UpdateMailState()
    if not AUI.buttons then return end
    AUI:UpdateIcons()
    AUI:UpdateMicrobar()
end

function AUI:CreateMicrobar()
    local bar = CreateFrame("Frame", "AUI_Microbar", E.UIParent, "BackdropTemplate")
    bar:SetPoint("BOTTOM", E.UIParent, "BOTTOM", 0, 250)
    E:CreateMover(bar, "AUI_MicrobarMover", "A-UI Microbar", nil, nil, nil, "ALL,SOLO")
    bar:SetScript("OnEnter", function() AUI:UpdateAlpha() end)
    bar:SetScript("OnLeave", function() AUI:UpdateAlpha() end)

    local AB = E:GetModule('ActionBars')
    if AB then 
        AB.UpdateMicroButtonsParent = function() end
        AB.UpdateMicroPositionDimensions = function() end 
    end
    
    if _G["ElvUI_MicroBar"] then 
        _G["ElvUI_MicroBar"]:Hide() 
        _G["ElvUI_MicroBar"]:UnregisterAllEvents()
        _G["ElvUI_MicroBar"]:SetScript("OnShow", function(self) self:Hide() end)
    end

    -- -----------------------------------------------------------------
    -- CUSTOM BUTTONS
    -- -----------------------------------------------------------------
    if not _G["AUI_MailButton"] then 
        CreateFrame("Button", "AUI_MailButton", E.UIParent) 
    end
    
    if not _G["AUI_CalendarButton"] then 
        local calBtn = CreateFrame("Button", "AUI_CalendarButton", E.UIParent)
        calBtn:RegisterForClicks("AnyUp")
        calBtn:SetScript("OnClick", function() 
            if ToggleCalendar then 
                ToggleCalendar() 
            elseif _G["GameTimeFrame"] and _G["GameTimeFrame"].Click then
                _G["GameTimeFrame"]:Click()
            end
        end)
    end

    if not _G["AUI_TeleportButton"] then
        local tpBtn = CreateFrame("Button", "AUI_TeleportButton", E.UIParent, "SecureActionButtonTemplate")
        tpBtn:RegisterForClicks("AnyUp")
        tpBtn:SetScript("OnClick", function(self)
            if InCombatLockdown() then 
                print("|cffff0000A-UI:|r Teleport-Menü kann im Kampf nicht geöffnet werden.")
                return 
            end
            if AUI.ToggleTeleportMenu then AUI:ToggleTeleportMenu(self) end
        end)
    end

    -- LFG Button für TBC Classic
    if not isRetail and not _G["AUI_LFGButton"] then
        local lfgBtn = CreateFrame("Button", "AUI_LFGButton", E.UIParent)
        lfgBtn:RegisterForClicks("AnyUp")
        lfgBtn:SetScript("OnClick", function()
            if ToggleLFGParentFrame then
                ToggleLFGParentFrame()
            elseif ToggleLFDParentFrame then
                ToggleLFDParentFrame()
            elseif PVEFrame_ToggleFrame then
                PVEFrame_ToggleFrame()
            elseif _G["LFGParentFrame"] then
                if _G["LFGParentFrame"]:IsShown() then HideUIPanel(_G["LFGParentFrame"]) else ShowUIPanel(_G["LFGParentFrame"]) end
            end
        end)
    end
    
    if isRetail and not _G["AUI_DelveButton"] then
        local delveBtn = CreateFrame("Button", "AUI_DelveButton", E.UIParent, "SecureActionButtonTemplate")
        delveBtn:RegisterForClicks("AnyUp")
        delveBtn:SetScript("OnClick", function(self)
            if InCombatLockdown() then 
                print("|cffff0000A-UI:|r Tiefen-Dashboard kann im Kampf nicht geöffnet werden.")
                return 
            end
            if AUI_DelveInfoFrame then
                if AUI_DelveInfoFrame:IsShown() then 
                    AUI_DelveInfoFrame:Hide() 
                else 
                    if AUI.UpdateDelveUI then AUI:UpdateDelveUI() end
                    AUI_DelveInfoFrame:Show() 
                end
            end
        end)
    end

    if not _G["AUI_AltsButton"] then
        local altsBtn = CreateFrame("Button", "AUI_AltsButton", E.UIParent, "SecureActionButtonTemplate")
        altsBtn:RegisterForClicks("AnyUp")
        altsBtn:SetScript("OnClick", function(self)
            if InCombatLockdown() then 
                print("|cffff0000A-UI:|r Alts-Dashboard kann im Kampf nicht geöffnet werden.")
                return 
            end
            if AUI_AltInfoFrame then
                if AUI_AltInfoFrame:IsShown() then 
                    AUI_AltInfoFrame:Hide() 
                else 
                    if AUI.UpdateAltUI then AUI:UpdateAltUI() end
                    AUI_AltInfoFrame:Show() 
                end
            end
        end)
    end

    -- Fallback-Injector (Tiefen nur in Retail, Alts in beiden)
    if AUI.MicroIcons then
        local hasDelve, hasAlts = false, false
        for _, iconData in ipairs(AUI.MicroIcons) do
            if iconData.blizzBtn == "AUI_DelveButton" then hasDelve = true end
            if iconData.blizzBtn == "AUI_AltsButton" then hasAlts = true end
        end
        if isRetail and not hasDelve then
            table.insert(AUI.MicroIcons, { name = "Tiefen", blizzBtn = "AUI_DelveButton", id = "Interface\\Icons\\INV_Misc_Map_01" })
        end
        if not hasAlts then
            table.insert(AUI.MicroIcons, { name = "Alts", blizzBtn = "AUI_AltsButton", id = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend" })
        end
    end

    AUI.buttons = {}
    for i, data in ipairs(AUI.MicroIcons) do
        local blizzBtn = _G[data.blizzBtn]
        if blizzBtn then
            local wrapper = CreateFrame("Frame", "AUI_MicroWrapper"..i, bar)
            wrapper:SetFrameLevel(10)
            
            local visual = CreateFrame("Frame", nil, wrapper, "BackdropTemplate")
            visual:SetPoint("CENTER", wrapper, "CENTER", 0, 0)
            visual:SetFrameLevel(10)
            
            local texFrame = CreateFrame("Frame", nil, visual)
            texFrame:SetPoint("CENTER", visual, "CENTER", 0, 0)
            local tex = texFrame:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints(texFrame)
            
            blizzBtn:SetParent(wrapper)
            blizzBtn:ClearAllPoints()
            blizzBtn:SetAllPoints(wrapper)
            blizzBtn:SetAlpha(0)
            if not blizzBtn.auiHookedAlpha then
                hooksecurefunc(blizzBtn, "SetAlpha", function(self, alpha) if alpha > 0 then self:SetAlpha(0) end end)
                blizzBtn.auiHookedAlpha = true
            end
            blizzBtn:Show()
            blizzBtn.ClearAllPoints = function() end
            blizzBtn.SetPoint = function() end
            blizzBtn.SetParent = function() end
            blizzBtn.Hide = function() end
            
            blizzBtn:SetScript("OnEnter", function(self) 
                AUI:UpdateAlpha()
                if E.db.AUI.microbar.buttonBorder then visual:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor)) end
                
                if E.db.AUI.microbar.fisheye then
                    visual:SetScale(1.15)
                    visual:SetFrameLevel(20)
                end
                local bName = self:GetName()
                E:Delay(0.05, function()
                    if not self:IsMouseOver() then return end
                    if AUI.ShowMicroButtonTooltip then
                        AUI:ShowMicroButtonTooltip(wrapper, bName, data)
                    end
                end)
            end)
            
            blizzBtn:SetScript("OnLeave", function() 
                AUI:UpdateAlpha()
                if E.db.AUI.microbar.buttonBorder then 
                    local r, g, b = GetStyleColor("button", "Border")
                    visual:SetBackdropBorderColor(r, g, b, 1) 
                end
                
                if E.db.AUI.microbar.fisheye then
                    visual:SetScale(1)
                    visual:SetFrameLevel(10)
                end
                if AUI.ClearTooltipStyle then AUI:ClearTooltipStyle() end
                GameTooltip:Hide()
            end)
            
            table.insert(AUI.buttons, { wrapper = wrapper, visual = visual, texFrame = texFrame, btn = blizzBtn, id = data.id, iconTex = tex, isGlowing = false, isMailGlowing = false })
        end
    end
    
    AUI:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMailState")
    
    AUI:UpdateIcons()
    AUI:UpdateMicrobar()
end