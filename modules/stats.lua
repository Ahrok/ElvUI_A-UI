local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local S = E:GetModule('Skins')

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

-- =====================================================================
-- 1. DEFAULTS (VERSIONSABHÄNGIG)
-- =====================================================================
P["AUI"] = P["AUI"] or {}
P["AUI"]["characterStats"] = {
    enable = true,
    hideBlizzardStats = true,
    showItemLevel = true,
    showDurability = true,
    showRepairCost = true,
    showEnchants = true,
    showMissingEnchants = true,
    missingEnchantGlow = true,
    showResistanceIcons = true,
    resistanceOrientation = "VERTICAL",
    categories = isRetail and {
        attributes = true,
        enhancements = true,
        defense = true,
        general = true,
    } or {
        attributes = true,
        melee = true,
        ranged = true,
        spell = true,
        defense = true,
        resistances = true,
        general = true,
    }
}

-- =====================================================================
-- 2. STATS FRAME & EXTERNE SCROLLBAR
-- =====================================================================
local StatsFrame = CreateFrame("Frame", "AUI_CharacterStatsFrame", _G.CharacterFrame or UIParent, "BackdropTemplate")
StatsFrame:SetWidth(245)
StatsFrame:SetTemplate("Transparent")
StatsFrame:Hide()

local scrollFrame = CreateFrame("ScrollFrame", "AUI_StatsScrollFrame", StatsFrame)
scrollFrame:SetPoint("TOPLEFT", StatsFrame, "TOPLEFT", 6, -6)
scrollFrame:SetPoint("BOTTOMRIGHT", StatsFrame, "BOTTOMRIGHT", -6, 6)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(233, 1)
scrollFrame:SetScrollChild(scrollChild)

local scrollBar = CreateFrame("Slider", "AUI_StatsScrollBar", StatsFrame, "BackdropTemplate")
scrollBar:SetPoint("TOPLEFT", StatsFrame, "TOPRIGHT", 1, 0)
scrollBar:SetPoint("BOTTOMLEFT", StatsFrame, "BOTTOMRIGHT", 1, 0)
scrollBar:SetWidth(4)
scrollBar:SetTemplate("Transparent")

local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
thumb:SetTexture(E.media.normTex)
thumb:SetVertexColor(0.35, 0.35, 0.35, 1)
thumb:SetSize(4, 30)
scrollBar:SetThumbTexture(thumb)
scrollBar:SetOrientation("VERTICAL")
scrollBar:SetMinMaxValues(0, 1)
scrollBar:SetValue(0)

local isUpdatingScroll = false
scrollFrame:SetScript("OnScrollRangeChanged", function(_, xrange, yrange)
    scrollBar:SetMinMaxValues(0, math.max(1, yrange))
    if yrange <= 0 then
        scrollBar:Hide()
    else
        scrollBar:Show()
    end
end)

scrollFrame:SetScript("OnVerticalScroll", function(_, offset)
    if not isUpdatingScroll then
        isUpdatingScroll = true
        scrollBar:SetValue(offset)
        isUpdatingScroll = false
    end
end)

scrollBar:SetScript("OnValueChanged", function(_, value)
    if not isUpdatingScroll then
        isUpdatingScroll = true
        scrollFrame:SetVerticalScroll(value)
        isUpdatingScroll = false
    end
end)

StatsFrame:EnableMouseWheel(true)
StatsFrame:SetScript("OnMouseWheel", function(_, delta)
    local cur = scrollFrame:GetVerticalScroll()
    local maxScroll = scrollFrame:GetVerticalScrollRange()
    local step = 25
    if delta > 0 then
        local newScroll = math.max(0, cur - step)
        scrollFrame:SetVerticalScroll(newScroll)
        scrollBar:SetValue(newScroll)
    else
        local newScroll = math.min(maxScroll, cur + step)
        scrollFrame:SetVerticalScroll(newScroll)
        scrollBar:SetValue(newScroll)
    end
end)

local scanTooltip
if not isRetail then
    scanTooltip = CreateFrame("GameTooltip", "AUI_StatsScanTooltip", UIParent, "GameTooltipTemplate")
    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
end

-- =====================================================================
-- 3. ZUVERLÄSSIGE WINDTOOLS ARMORY ERKENNUNG
-- =====================================================================
local function IsWindToolsArmoryActive()
    local loaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        loaded = C_AddOns.IsAddOnLoaded("ElvUI_WindTools") or C_AddOns.IsAddOnLoaded("WindTools")
    elseif IsAddOnLoaded then
        loaded = IsAddOnLoaded("ElvUI_WindTools") or IsAddOnLoaded("WindTools")
    end

    if _G.ElvUI_WindTools or _G.WindTools or _G.WT then
        loaded = true
    end

    if not loaded then return false end

    -- 1. Private & DB Configs von WindTools prüfen
    if E.private and E.private.WT then
        if E.private.WT.armory and E.private.WT.armory.enable ~= false then return true end
        if E.private.WT.characterArmory and E.private.WT.characterArmory.enable ~= false then return true end
        if E.private.WT.itemLevel and E.private.WT.itemLevel.enable ~= false then return true end
    end
    if E.db and E.db.WT then
        if E.db.WT.armory and E.db.WT.armory.enable ~= false then return true end
        if E.db.WT.characterArmory and E.db.WT.characterArmory.enable ~= false then return true end
        if E.db.WT.itemLevel and E.db.WT.itemLevel.enable ~= false then return true end
    end

    -- 2. Modul-Instanzen in ElvUI prüfen
    if E.GetModule then
        if E:GetModule("WT-Armory", true) or E:GetModule("WindTools", true) or E:GetModule("WT", true) then
            return true
        end
    end

    -- 3. UI-Elemente prüfen
    local checkFrames = {
        "WTCharacterArmory", "WTCharacterArmoryFrame", "ElvUI_WindTools_Armory",
        "WT_CharacterFrame", "WindTools_CharacterFrame", "WTItemLevelFrame"
    }
    for _, name in ipairs(checkFrames) do
        if _G[name] then return true end
    end

    return true
end

-- =====================================================================
-- 4. HILFSFUNKTIONEN FÜR ROWS & TOOLTIPS
-- =====================================================================
local rows = {}
local rowIndex = 0
local font = E.media.normFont or "Interface\\AddOns\\ElvUI\\Core\\Media\\Fonts\\Expressway.ttf"

local function ResetRows()
    rowIndex = 0
    for _, r in ipairs(rows) do
        r:Hide()
        r.tooltipFunc = nil
        r.tooltipTitle = nil
        r.tooltipDesc = nil
        if r.headerBg then r.headerBg:Hide() end
        if r.zebraBg then r.zebraBg:Hide() end
    end
end

local function Row_OnEnter(self)
    if not self.tooltipFunc and not self.tooltipTitle then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.tooltipFunc then
        self.tooltipFunc(GameTooltip)
    elseif self.tooltipTitle then
        GameTooltip:AddLine(self.tooltipTitle, 1, 1, 1)
        if self.tooltipDesc then
            GameTooltip:AddLine(self.tooltipDesc, 1, 0.82, 0, true)
        end
    end
    GameTooltip:Show()
end

local function Row_OnLeave()
    GameTooltip:Hide()
end

local function GetRow()
    rowIndex = rowIndex + 1
    if not rows[rowIndex] then
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(233, 16)
        row:EnableMouse(true)
        row:SetScript("OnEnter", Row_OnEnter)
        row:SetScript("OnLeave", Row_OnLeave)

        row.headerBg = row:CreateTexture(nil, "BACKGROUND")
        row.headerBg:SetAllPoints()
        row.headerBg:SetTexture(E.media.normTex)
        row.headerBg:SetVertexColor(0.18, 0.18, 0.18, 0.95)
        row.headerBg:Hide()

        row.zebraBg = row:CreateTexture(nil, "BACKGROUND")
        row.zebraBg:SetAllPoints()
        row.zebraBg:SetColorTexture(1, 1, 1, 0.02)
        row.zebraBg:Hide()

        row.leftText = row:CreateFontString(nil, "OVERLAY")
        row.leftText:FontTemplate(font, 11, "OUTLINE")
        row.leftText:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.leftText:SetJustifyH("LEFT")

        row.rightText = row:CreateFontString(nil, "OVERLAY")
        row.rightText:FontTemplate(font, 11, "OUTLINE")
        row.rightText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.rightText:SetJustifyH("RIGHT")

        rows[rowIndex] = row
    end
    return rows[rowIndex]
end

local function AddCategoryHeader(title)
    local row = GetRow()
    row:SetSize(233, 18)
    row.headerBg:Show()
    row.zebraBg:Hide()
    row.leftText:FontTemplate(font, 11, "OUTLINE")
    row.leftText:SetTextColor(1, 0.82, 0)
    row.leftText:SetText(title:upper())
    row.rightText:SetText("")
    row.tooltipFunc = nil
    row:Show()
end

local function AddStatLine(name, value, isEven, r, g, b, tooltipData)
    local row = GetRow()
    row:SetSize(233, 15)
    row.headerBg:Hide()
    if isEven then row.zebraBg:Show() else row.zebraBg:Hide() end

    row.leftText:FontTemplate(font, 11, "OUTLINE")
    row.leftText:SetTextColor(r or 0.8, g or 0.8, b or 0.8)
    row.leftText:SetText(name)

    row.rightText:FontTemplate(font, 11, "OUTLINE")
    row.rightText:SetTextColor(1, 1, 1)
    row.rightText:SetText(value or "-")

    if type(tooltipData) == "function" then
        row.tooltipFunc = tooltipData
    elseif type(tooltipData) == "table" then
        row.tooltipTitle = tooltipData.title
        row.tooltipDesc = tooltipData.desc
    else
        row.tooltipFunc = nil
    end

    row:Show()
end

local function FormatCostShort(money)
    if not money or money <= 0 then return "" end
    local g = math.floor(money / 10000)
    local s = math.floor((money % 10000) / 100)
    local c = money % 100
    if g > 0 then
        return string.format("|cffffd100%dg|r", g)
    elseif s > 0 then
        return string.format("|cffe0e0e0%ds|r", s)
    else
        return string.format("|cffeda55f%dc|r", c)
    end
end

local function FormatCostFull(money)
    if not money or money <= 0 then return "0 |cffeda55fc|r" end
    local g = math.floor(money / 10000)
    local s = math.floor((money % 10000) / 100)
    local c = money % 100
    local str = ""
    if g > 0 then str = str .. string.format("|cffffd100%d|r|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:1:0|t ", g) end
    if s > 0 or g > 0 then str = str .. string.format("|cffe0e0e0%d|r|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:1:0|t ", s) end
    str = str .. string.format("|cffeda55f%d|r|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:1:0|t", c)
    return str
end

local function CleanEnchantString(text)
    if not text then return nil end
    text = text:gsub("^Enchanted:%s*", "")
    text = text:gsub("^Verzaubert:%s*", "")
    local val = text:match("%((%+?%d+%s*[^%)]+)%)")
    if val then return val end
    text = text:gsub("^Reinforced%s*", "")
    text = text:gsub("^Verstärkt%s*", "")
    return text
end

local function GetSlotRepairCost(slotID)
    if isRetail then
        if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
            local data = C_TooltipInfo.GetInventoryItem("player", slotID)
            if data and data.repairCost then return data.repairCost end
        end
    else
        scanTooltip:ClearLines()
        local hasItem, _, cost = scanTooltip:SetInventoryItem("player", slotID)
        if hasItem and cost and cost > 0 then return cost end
    end
    return 0
end

local function GetSlotEnchant(slotID, itemLink)
    if not itemLink then return nil end
    local enchantID = itemLink:match("item:%d+:(%d+)")
    if not enchantID or tonumber(enchantID) == 0 then return nil end

    if isRetail then
        if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
            local data = C_TooltipInfo.GetInventoryItem("player", slotID)
            if data and data.lines then
                for _, line in ipairs(data.lines) do
                    local text = line.leftText
                    if text and line.leftColor and line.leftColor.g > 0.8 and line.leftColor.r < 0.2 then
                        return CleanEnchantString(text)
                    end
                end
            end
        end
    else
        scanTooltip:ClearLines()
        local hasItem = scanTooltip:SetInventoryItem("player", slotID)
        if not hasItem then return nil end

        local numLines = scanTooltip:NumLines()
        for i = 2, numLines do
            local line = _G["AUI_StatsScanTooltipTextLeft" .. i]
            if line then
                local text = line:GetText()
                local r, g, b = line:GetTextColor()
                if text and text ~= "" and r < 0.2 and g > 0.8 and b < 0.2 then
                    local lower = text:lower()
                    if not lower:find("^equip:") and not lower:find("^anlegen:") 
                       and not lower:find("^chance on hit:") and not lower:find("^trefferchance:")
                       and not lower:find("^use:") and not lower:find("^benutzen:")
                       and not lower:find("^set:") and not lower:find("^set :")
                       and not lower:find("<made by") and not lower:find("<hergestellt") then
                        return CleanEnchantString(text)
                    end
                end
            end
        end
    end
    return nil
end

-- =====================================================================
-- 5. RESISTENZ-ICONS (NUR CLASSIC / TBC)
-- =====================================================================
local function UpdateResistanceIconsLayout()
    if isRetail then return end

    local db = E.db.AUI.characterStats
    local showIcons = db.showResistanceIcons
    local orientation = db.resistanceOrientation or "VERTICAL"

    local activeFrames = {}
    for i = 1, 5 do
        local f = _G["MagicResFrame" .. i] or _G["CharacterMagicResist" .. i] or _G["MagicResistant" .. i]
        if f then table.insert(activeFrames, f) end
    end

    if not showIcons or not (_G.CharacterFrame and _G.CharacterFrame:IsShown()) then
        for _, f in ipairs(activeFrames) do
            f:Hide()
            f:SetAlpha(0)
            f:EnableMouse(false)
        end
        return
    end

    local baseFrameLevel = (_G.PaperDollFrame and _G.PaperDollFrame:GetFrameLevel() or 1) + 6

    for i, f in ipairs(activeFrames) do
        f:SetAlpha(1)
        f:EnableMouse(true)
        f:Show()
        f:SetFrameLevel(baseFrameLevel)
        f:ClearAllPoints()

        if orientation == "HORIZONTAL" then
            local startX = -58
            local spacing = 29
            local offsetX = startX + ((i - 1) * spacing)
            f:SetPoint("TOP", _G.PaperDollFrame, "TOP", offsetX, -56)
        else
            if i == 1 then
                f:SetPoint("TOPRIGHT", _G.PaperDollFrame, "TOPRIGHT", -92, -76)
            else
                f:SetPoint("TOP", activeFrames[i - 1], "BOTTOM", 0, -3)
            end
        end
    end
end

-- =====================================================================
-- 6. ITEM OVERLAYS
-- =====================================================================
local slotNames = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot",
    "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
    "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
}
if not isRetail then
    table.insert(slotNames, "RangedSlot")
end

local enchantableSlots = isRetail and {
    BackSlot = true, ChestSlot = true, WristSlot = true,
    LegsSlot = true, FeetSlot = true, Finger0Slot = true,
    Finger1Slot = true, MainHandSlot = true, SecondaryHandSlot = true
} or {
    HeadSlot = true, ShoulderSlot = true, BackSlot = true, ChestSlot = true,
    WristSlot = true, HandsSlot = true, LegsSlot = true, FeetSlot = true,
    MainHandSlot = true, SecondaryHandSlot = true, RangedSlot = true
}

local leftSideSlots = {
    HeadSlot = true, NeckSlot = true, ShoulderSlot = true, BackSlot = true,
    ChestSlot = true, ShirtSlot = true, TabardSlot = true, WristSlot = true
}

local rightSideSlots = {
    HandsSlot = true, WaistSlot = true, LegsSlot = true, FeetSlot = true,
    Finger0Slot = true, Finger1Slot = true, Trinket0Slot = true, Trinket1Slot = true
}

function AUI:UpdateItemOverlays()
    if not _G.CharacterFrame or not _G.CharacterFrame:IsShown() then return end
    local db = E.db.AUI.characterStats
    local wtArmory = IsWindToolsArmoryActive()

    for _, slotName in ipairs(slotNames) do
        local slot = _G["Character" .. slotName]
        if slot then
            if not slot.auiOverlayFrame then
                slot.auiOverlayFrame = CreateFrame("Frame", nil, slot)
                slot.auiOverlayFrame:SetAllPoints()
                slot.auiOverlayFrame:SetFrameLevel(slot:GetFrameLevel() + 10)

                slot.auiILvlText = slot.auiOverlayFrame:CreateFontString(nil, "OVERLAY")
                slot.auiILvlText:FontTemplate(font, 14, "THICKOUTLINE")
                slot.auiILvlText:SetPoint("BOTTOM", slot, "BOTTOM", 0, 2)
                slot.auiILvlText:SetShadowOffset(1, -1)
                slot.auiILvlText:SetShadowColor(0, 0, 0, 1)

                slot.auiDurText = slot.auiOverlayFrame:CreateFontString(nil, "OVERLAY")
                slot.auiDurText:FontTemplate(font, 10, "OUTLINE")
                slot.auiDurText:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)

                slot.auiRepText = slot.auiOverlayFrame:CreateFontString(nil, "OVERLAY")
                slot.auiRepText:FontTemplate(font, 9, "OUTLINE")
                slot.auiRepText:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -2, -2)

                slot.auiEnchantText = slot.auiOverlayFrame:CreateFontString(nil, "OVERLAY")
                slot.auiEnchantText:FontTemplate(font, 10, "OUTLINE")
                slot.auiEnchantText:SetWidth(100)
                slot.auiEnchantText:SetWordWrap(false)

                slot.auiMissingBorder = CreateFrame("Frame", nil, slot, "BackdropTemplate")
                slot.auiMissingBorder:SetAllPoints()
                slot.auiMissingBorder:SetBackdrop({ edgeFile = E.media.blankTex, edgeSize = 2 })
                slot.auiMissingBorder:SetBackdropBorderColor(1, 0.15, 0.15, 0.95)
                slot.auiMissingBorder:SetFrameLevel(slot:GetFrameLevel() + 11)
                slot.auiMissingBorder:Hide()

                if leftSideSlots[slotName] then
                    slot.auiEnchantText:SetPoint("LEFT", slot, "RIGHT", 6, 0)
                    slot.auiEnchantText:SetJustifyH("LEFT")
                elseif rightSideSlots[slotName] then
                    slot.auiEnchantText:SetPoint("RIGHT", slot, "LEFT", -6, 0)
                    slot.auiEnchantText:SetJustifyH("RIGHT")
                else
                    slot.auiEnchantText:SetPoint("TOP", slot, "BOTTOM", 0, -3)
                    slot.auiEnchantText:SetJustifyH("CENTER")
                end
            end

            -- Wenn WindTools Armory aktiv ist, unterdrücken wir alle A-UI Overlays
            if wtArmory then
                slot.auiILvlText:Hide()
                slot.auiDurText:Hide()
                slot.auiRepText:Hide()
                slot.auiEnchantText:Hide()
                slot.auiMissingBorder:Hide()
            else
                local slotID = slot:GetID()
                local itemLink = GetInventoryItemLink("player", slotID)

                -- 1. ItemLevel
                if db.showItemLevel and itemLink then
                    local iLvl, quality
                    if isRetail then
                        iLvl = C_Item.GetDetailedItemLevelInfo(itemLink) or select(4, GetItemInfo(itemLink))
                        quality = C_Item.GetItemQualityByID(itemLink)
                    else
                        _, _, quality, iLvl = GetItemInfo(itemLink)
                    end

                    if iLvl and iLvl > 1 then
                        local r, g, b = 1, 1, 1
                        if quality and BAG_ITEM_QUALITY_COLORS and BAG_ITEM_QUALITY_COLORS[quality] then
                            r, g, b = BAG_ITEM_QUALITY_COLORS[quality].r, BAG_ITEM_QUALITY_COLORS[quality].g, BAG_ITEM_QUALITY_COLORS[quality].b
                        elseif quality and GetItemQualityColor then
                            r, g, b = GetItemQualityColor(quality)
                        end
                        slot.auiILvlText:SetText(iLvl)
                        slot.auiILvlText:SetTextColor(r, g, b)
                        slot.auiILvlText:Show()
                    else
                        slot.auiILvlText:Hide()
                    end
                else
                    slot.auiILvlText:Hide()
                end

                -- 2. Haltbarkeit
                if db.showDurability and itemLink then
                    local curDur, maxDur = GetInventoryItemDurability(slotID)
                    if curDur and maxDur and maxDur > 0 then
                        local pct = (curDur / maxDur) * 100
                        if pct < 100 then
                            local r, g, b = E:ColorGradient(pct * 0.01, 1, 0, 0, 1, 1, 0, 0, 1, 0)
                            slot.auiDurText:SetFormattedText("|cff%02x%02x%02x%.0f%%|r", r * 255, g * 255, b * 255, pct)
                            slot.auiDurText:Show()
                        else
                            slot.auiDurText:Hide()
                        end
                    else
                        slot.auiDurText:Hide()
                    end
                else
                    slot.auiDurText:Hide()
                end

                -- 3. Reparaturkosten
                if db.showRepairCost and itemLink then
                    local cost = GetSlotRepairCost(slotID)
                    if cost and cost > 0 then
                        slot.auiRepText:SetText(FormatCostShort(cost))
                        slot.auiRepText:Show()
                    else
                        slot.auiRepText:Hide()
                    end
                else
                    slot.auiRepText:Hide()
                end

                -- 4. Verzauberungen & Fehlende Verzauberungen
                local isEnchanted = false
                if itemLink then
                    local enchant = GetSlotEnchant(slotID, itemLink)
                    if enchant and enchant ~= "" then
                        isEnchanted = true
                        if db.showEnchants then
                            slot.auiEnchantText:SetTextColor(0, 1, 0)
                            slot.auiEnchantText:SetText(enchant)
                            slot.auiEnchantText:Show()
                        else
                            slot.auiEnchantText:Hide()
                        end
                    end
                end

                local isEnchantable = enchantableSlots[slotName]
                if itemLink and isEnchantable and not isEnchanted then
                    if db.showMissingEnchants then
                        slot.auiEnchantText:SetTextColor(1, 0.2, 0.2)
                        slot.auiEnchantText:SetText(L["Missing"] or "Fehlt")
                        slot.auiEnchantText:Show()
                    elseif not isEnchanted then
                        slot.auiEnchantText:Hide()
                    end

                    if db.missingEnchantGlow then
                        slot.auiMissingBorder:Show()
                    else
                        slot.auiMissingBorder:Hide()
                    end
                else
                    slot.auiMissingBorder:Hide()
                    if not isEnchanted then
                        slot.auiEnchantText:Hide()
                    end
                end
            end
        end
    end
end

-- =====================================================================
-- 7. STATS RENDERN
-- =====================================================================
local function UpdateClassicStats()
    local cfg = E.db.AUI.characterStats.categories or {}
    local lineCount = 0
    local _, playerClass = UnitClass("player")
    local playerLevel = UnitLevel("player")

    -- 1. ATTRIBUTE
    if cfg.attributes ~= false then
        AddCategoryHeader(L["Attributes"] or "Attribute")
        lineCount = 0

        -- Stärke
        lineCount = lineCount + 1
        local _, strStat, strPos, strNeg = UnitStat("player", 1)
        local strValStr = tostring(strStat)
        if strPos > 0 then strValStr = strValStr .. " |cff00ff00(+" .. strPos .. ")|r" end
        if strNeg < 0 then strValStr = strValStr .. " |cffff0000(" .. strNeg .. ")|r" end

        AddStatLine(L["Strength"] or "Stärke", strValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %d", SPELL_STAT1_NAME or (L["Strength"] or "Stärke"), strStat), 1, 1, 1)
            local apPerStr = (playerClass == "WARRIOR" or playerClass == "PALADIN" or playerClass == "SHAMAN" or playerClass == "DRUID") and 2 or 1
            local strAP = strStat * apPerStr
            local strBlock = math.max(0, math.floor((strStat / 20) - 1))
            local blockValue = (GetShieldBlock and GetShieldBlock()) or 0
            tt:AddLine(string.format(L["Increases attack power by %d."] or "Erhöht Angriffskraft um %d.", strAP), 1, 0.82, 0, true)
            if playerClass == "WARRIOR" or playerClass == "PALADIN" or playerClass == "SHAMAN" then
                tt:AddLine(string.format(L["Increases shield block value by %d (Current total: %d)."] or "Erhöht Schild-Blockwert um %d (Aktuell gesamt: %d).", strBlock, blockValue), 1, 0.82, 0, true)
            end
        end)

        -- Beweglichkeit
        lineCount = lineCount + 1
        local _, agiStat, agiPos, agiNeg = UnitStat("player", 2)
        local agiValStr = tostring(agiStat)
        if agiPos > 0 then agiValStr = agiValStr .. " |cff00ff00(+" .. agiPos .. ")|r" end
        if agiNeg < 0 then agiValStr = agiValStr .. " |cffff0000(" .. agiNeg .. ")|r" end

        AddStatLine(L["Agility"] or "Beweglichkeit", agiValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %d", SPELL_STAT2_NAME or (L["Agility"] or "Beweglichkeit"), agiStat), 1, 1, 1)
            local armorGained = agiStat * 2
            local critGained = GetCritChance()
            local dodgeGained = GetDodgeChance()
            tt:AddLine(string.format(L["Increases armor by %d.\nIncreases critical strike chance by %.2f%%.\nIncreases dodge chance by %.2f%%."] or "Erhöht Rüstung um %d.\nErhöht Chance auf kritische Treffer um %.2f%%.\nErhöht Ausweichchance um %.2f%%.", armorGained, critGained, dodgeGained), 1, 0.82, 0, true)
        end)

        -- Ausdauer
        lineCount = lineCount + 1
        local _, staStat, staPos, staNeg = UnitStat("player", 3)
        local staValStr = tostring(staStat)
        if staPos > 0 then staValStr = staValStr .. " |cff00ff00(+" .. staPos .. ")|r" end
        if staNeg < 0 then staValStr = staValStr .. " |cffff0000(" .. staNeg .. ")|r" end

        AddStatLine(L["Stamina"] or "Ausdauer", staValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %d", SPELL_STAT3_NAME or (L["Stamina"] or "Ausdauer"), staStat), 1, 1, 1)
            local _, race = UnitRace("player")
            local hpPerSta = (race == "Tauren") and 10.5 or 10
            local hpGained = math.floor(staStat * hpPerSta)
            tt:AddLine(string.format(L["Increases maximum health by %d HP."] or "Erhöht maximale Gesundheit um %d HP.", hpGained), 1, 0.82, 0, true)
        end)

        -- Intelligenz
        lineCount = lineCount + 1
        local _, intStat, intPos, intNeg = UnitStat("player", 4)
        local intValStr = tostring(intStat)
        if intPos > 0 then intValStr = intValStr .. " |cff00ff00(+" .. intPos .. ")|r" end
        if intNeg < 0 then intValStr = intValStr .. " |cffff0000(" .. intNeg .. ")|r" end

        AddStatLine(L["Intellect"] or "Intelligenz", intValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %d", SPELL_STAT4_NAME or (L["Intellect"] or "Intelligenz"), intStat), 1, 1, 1)
            local manaGained = intStat * 15
            local spellCrit = GetSpellCritChance(2)
            tt:AddLine(string.format(L["Increases maximum mana by %d.\nIncreases spell critical strike chance by %.2f%%."] or "Erhöht maximales Mana um %d.\nErhöht Chance auf kritische Zaubertreffer um %.2f%%.", manaGained, spellCrit), 1, 0.82, 0, true)
        end)

        -- Willenskraft
        lineCount = lineCount + 1
        local _, spiStat, spiPos, spiNeg = UnitStat("player", 5)
        local spiValStr = tostring(spiStat)
        if spiPos > 0 then spiValStr = spiValStr .. " |cff00ff00(+" .. spiPos .. ")|r" end
        if spiNeg < 0 then spiValStr = spiValStr .. " |cffff0000(" .. spiNeg .. ")|r" end

        AddStatLine(L["Spirit"] or "Willenskraft", spiValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %d", SPELL_STAT5_NAME or (L["Spirit"] or "Willenskraft"), spiStat), 1, 1, 1)
            local baseRegen, castingRegen = GetManaRegen()
            local baseHpRegen = GetUnitHealthRegenRateFromSpirit and GetUnitHealthRegenRateFromSpirit("player") or 0
            tt:AddLine(string.format(L["Increases health regen out of combat by %.1f HP/sec.\nIncreases mana regen while not casting by %.0f MP5 (While casting: %.0f MP5)."] or "Erhöht Gesundheitsregeneration außerhalb des Kampfes um %.1f HP/Sek.\nErhöht Manaregeneration außerhalb des Zauberwirkens um %.0f MP5 (Im Zaubern: %.0f MP5).", baseHpRegen, (baseRegen or 0) * 5, (castingRegen or 0) * 5), 1, 0.82, 0, true)
        end)
    end

    -- 2. NAHKAMPF
    if cfg.melee ~= false then
        AddCategoryHeader(L["Melee"] or "Nahkampf")
        lineCount = 0
        local minDmg, maxDmg = UnitDamage("player")
        local speed = UnitAttackSpeed("player")
        local ap, posAP, negAP = UnitAttackPower("player")
        
        local crit = GetCritChance()
        local critRating = (GetCombatRating and GetCombatRating(CR_CRIT_MELEE or 9)) or 0
        local critStr = (critRating > 0) and string.format("%.2f%% (%d)", crit, critRating) or string.format("%.2f%%", crit)

        local hit = GetHitModifier() or 0
        local hitRating = (GetCombatRating and GetCombatRating(CR_HIT_MELEE or 6)) or 0
        local hitStr = (hitRating > 0) and string.format("%.2f%% (%d)", hit, hitRating) or string.format("%.2f%%", hit)

        local expStr = "0 (0.00%)"
        if GetExpertise then
            local mainExp = GetExpertise()
            local mainExpPct = (GetExpertisePercent and GetExpertisePercent()) or (mainExp * 0.25)
            local expRating = (GetCombatRating and GetCombatRating(CR_EXPERTISE or 24)) or 0
            if expRating > 0 then
                expStr = string.format("%d (%.2f%%) (%d)", mainExp, mainExpPct, expRating)
            else
                expStr = string.format("%d (%.2f%%)", mainExp, mainExpPct)
            end
        end

        lineCount = lineCount + 1
        AddStatLine(L["Damage"] or "Schaden", string.format("%d - %d", math.floor(minDmg), math.ceil(maxDmg)), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Damage"] or "Nahkampfschaden", 1, 1, 1)
            tt:AddLine(string.format(L["Damage Range: %d - %d\nAttack Speed: %.2f sec."] or "Schadensspanne: %d - %d\nAngriffstempo: %.2f Sek.", minDmg, maxDmg, speed), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Attack Speed"] or "Angriffstempo", string.format("%.2f", speed), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Attack Speed"] or "Angriffstempo", 1, 1, 1)
            tt:AddLine(string.format(L["Weapon Speed: %.2f seconds per swing."] or "Waffengeschwindigkeit: %.2f Sekunden pro Schwung.", speed), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Attack Power"] or "Angriffskraft", tostring(ap + posAP + negAP), lineCount % 2 == 0, nil, nil, nil, function(tt)
            local totalAP = ap + posAP + negAP
            local dpsGain = totalAP / 14
            tt:AddLine(string.format("%s: %d", STAT_ATTACK_POWER or (L["Attack Power"] or "Angriffskraft"), totalAP), 1, 1, 1)
            tt:AddLine(string.format(L["Increases melee damage dealt by %.1f DPS."] or "Erhöht den verursachten Nahkampfschaden um %.1f DPS.", dpsGain), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Hit Chance"] or "Trefferchance", hitStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            local hitBonus = GetCombatRatingBonus and GetCombatRatingBonus(CR_HIT_MELEE or 6) or 0
            local armorPen = (GetArmorPenetration and GetArmorPenetration()) or (GetCombatRating and GetCombatRating(CR_ARMOR_PENETRATION or 25)) or 0
            tt:AddLine(string.format("%s: %d", STAT_HIT_RATING or (L["Hit Chance"] or "Trefferwertung"), hitRating), 1, 1, 1)
            tt:AddLine(string.format(L["Increases melee hit chance against level %d targets by %.2f%%."] or "Erhöht die Chance, Ziele der Stufe %d mit Nahkampfangriffen zu treffen, um %.2f%%.", playerLevel, hitBonus), 1, 0.82, 0, true)
            if armorPen > 0 then
                tt:AddLine(string.format(L["\nArmor Penetration: %d\nIgnores up to %d enemy armor."] or "\nRüstungsdurchschlag: %d\nIgnoriert bis zu %d Rüstung des Gegners.", armorPen, armorPen), 1, 0.82, 0, true)
            end
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Critical Strike"] or "Kritisch", critStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            local critBonus = GetCombatRatingBonus and GetCombatRatingBonus(CR_CRIT_MELEE or 9) or 0
            tt:AddLine(string.format("%s: %d", STAT_CRIT_MELEE_RATING or (L["Critical Strike"] or "Kritische Trefferwertung"), critRating), 1, 1, 1)
            tt:AddLine(string.format(L["Increases melee critical strike chance by %.2f%%."] or "Erhöht die Chance auf kritische Nahkampftreffer um %.2f%%.", critBonus), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Expertise"] or "Waffenkunde", expStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(STAT_EXPERTISE or (L["Expertise"] or "Waffenkunde"), 1, 1, 1)
            tt:AddLine(string.format(L["Reduces enemy chance to dodge or parry your attacks by %.2f%%."] or "Verringert die Chance, dass Gegner euren Nahkampfangriffen ausweichen oder sie parieren, um %.2f%%.", (GetExpertisePercent and GetExpertisePercent()) or 0), 1, 0.82, 0, true)
        end)
    end

    -- 3. FERNKAMPF
    if cfg.ranged ~= false then
        local rangedAP, rPos, rNeg = UnitRangedAttackPower("player")
        if (rangedAP + rPos + rNeg) > 0 then
            AddCategoryHeader(L["Ranged"] or "Fernkampf")
            lineCount = 0
            local rSpeed, rMin, rMax = UnitRangedDamage("player")
            local rCrit = GetRangedCritChance()
            local rCritRating = (GetCombatRating and GetCombatRating(CR_CRIT_RANGED or 10)) or 0
            local rCritStr = (rCritRating > 0) and string.format("%.2f%% (%d)", rCrit, rCritRating) or string.format("%.2f%%", rCrit)

            local rHit = (GetRangedHitModifier and GetRangedHitModifier()) or (GetHitModifier and GetHitModifier()) or 0
            local rHitRating = (GetCombatRating and GetCombatRating(CR_HIT_RANGED or 7)) or 0
            local rHitStr = (rHitRating > 0) and string.format("%.2f%% (%d)", rHit, rHitRating) or string.format("%.2f%%", rHit)

            lineCount = lineCount + 1
            AddStatLine(L["Damage"] or "Schaden", string.format("%d - %d", math.floor(rMin), math.ceil(maxDmg)), lineCount % 2 == 0, nil, nil, nil, function(tt)
                tt:AddLine(L["Ranged"] or "Fernkampfschaden", 1, 1, 1)
                tt:AddLine(string.format(L["Damage Range: %d - %d\nAttack Speed: %.2f sec."] or "Schadensspanne: %d - %d\nAngriffstempo: %.2f Sek.", rMin, rMax, rSpeed), 1, 0.82, 0, true)
            end)

            lineCount = lineCount + 1
            AddStatLine(L["Attack Speed"] or "Angriffstempo", string.format("%.2f", rSpeed), lineCount % 2 == 0)
            
            lineCount = lineCount + 1
            AddStatLine(L["Attack Power"] or "Angriffskraft", tostring(rangedAP + rPos + rNeg), lineCount % 2 == 0, nil, nil, nil, function(tt)
                local totalRAP = rangedAP + rPos + rNeg
                local rDpsGain = totalRAP / 14
                tt:AddLine(string.format("%s: %d", STAT_ATTACK_POWER or (L["Attack Power"] or "Fernkampf-Angriffskraft"), totalRAP), 1, 1, 1)
                tt:AddLine(string.format(L["Increases ranged damage dealt by %.1f DPS."] or "Erhöht den verursachten Fernkampfschaden um %.1f DPS.", rDpsGain), 1, 0.82, 0, true)
            end)
            
            lineCount = lineCount + 1
            AddStatLine(L["Hit Chance"] or "Trefferchance", rHitStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
                local rHitBonus = GetCombatRatingBonus and GetCombatRatingBonus(CR_HIT_RANGED or 7) or 0
                local armorPen = (GetArmorPenetration and GetArmorPenetration()) or (GetCombatRating and GetCombatRating(CR_ARMOR_PENETRATION or 25)) or 0
                tt:AddLine(string.format("%s: %d", STAT_HIT_RATING or (L["Hit Chance"] or "Trefferwertung"), rHitRating), 1, 1, 1)
                tt:AddLine(string.format(L["Increases ranged hit chance against level %d targets by %.2f%%."] or "Erhöht die Chance, Ziele der Stufe %d mit Fernkampfangriffen zu treffen, um %.2f%%.", playerLevel, rHitBonus), 1, 0.82, 0, true)
                if armorPen > 0 then
                    tt:AddLine(string.format(L["\nArmor Penetration: %d\nIgnores up to %d enemy armor."] or "\nRüstungsdurchschlag: %d\nIgnoriert bis zu %d Rüstung des Gegners.", armorPen, armorPen), 1, 0.82, 0, true)
                end
            end)

            lineCount = lineCount + 1
            AddStatLine(L["Critical Strike"] or "Kritisch", rCritStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
                local rCritBonus = GetCombatRatingBonus and GetCombatRatingBonus(CR_CRIT_RANGED or 10) or 0
                tt:AddLine(string.format("%s: %d", STAT_CRIT_RANGED_RATING or (L["Critical Strike"] or "Kritische Trefferwertung"), rCritRating), 1, 1, 1)
                tt:AddLine(string.format(L["Increases ranged critical strike chance by %.2f%%."] or "Erhöht die Chance auf kritische Fernkampftreffer um %.2f%%.", rCritBonus), 1, 0.82, 0, true)
            end)
        end
    end

    -- 4. ZAUBER
    if cfg.spell ~= false then
        AddCategoryHeader(L["Spell"] or "Zauber")
        lineCount = 0

        local healBonus = GetSpellBonusHealing()
        local spellCrit = GetSpellCritChance(2)
        local spellCritRating = (GetCombatRating and GetCombatRating(CR_CRIT_SPELL or 11)) or 0
        local spellCritStr = (spellCritRating > 0) and string.format("%.2f%% (%d)", spellCrit, spellCritRating) or string.format("%.2f%%", spellCrit)

        local spellHit = GetSpellHitModifier and GetSpellHitModifier() or 0
        local spellHitRating = (GetCombatRating and GetCombatRating(CR_HIT_SPELL or 8)) or 0
        local spellHitStr = (spellHitRating > 0) and string.format("%.2f%% (%d)", spellHit, spellHitRating) or string.format("%.2f%%", spellHit)

        local spellHasteRating = (GetCombatRating and GetCombatRating(CR_HASTE_SPELL or 20)) or 0
        local spellHastePct = (GetHaste and GetHaste()) or 0
        local manaRegen = GetManaRegen()

        local spellSchools = {
            { id = 2, key = "Holy", fallback = "Heilig" },
            { id = 3, key = "Fire", fallback = "Feuer" },
            { id = 4, key = "Nature", fallback = "Natur" },
            { id = 5, key = "Frost", fallback = "Frost" },
            { id = 6, key = "Shadow", fallback = "Schatten" },
            { id = 7, key = "Arcane", fallback = "Arkan" },
        }

        for _, school in ipairs(spellSchools) do
            lineCount = lineCount + 1
            local dmg = GetSpellBonusDamage(school.id) or 0
            local schoolName = L[school.key] or school.fallback
            local name = schoolName .. " " .. (L["Damage"] or "Schaden")
            AddStatLine(name, tostring(dmg), lineCount % 2 == 0, nil, nil, nil, function(tt)
                tt:AddLine(name, 1, 1, 1)
                tt:AddLine(string.format(L["Increases damage done by %s spells by up to %d."] or "Erhöht den durch %szauber verursachten Schaden um bis zu %d.", schoolName, dmg), 1, 0.82, 0, true)
            end)
        end

        lineCount = lineCount + 1
        AddStatLine(L["Healing"] or "Heilung", tostring(healBonus), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Healing"] or "Heilung", 1, 1, 1)
            tt:AddLine(string.format(L["Increases healing done by spells by up to %d."] or "Erhöht die durch Heilzauber hervorgerufene Heilung um bis zu %d.", healBonus), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Spell Crit"] or "Zauberkrit", spellCritStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            local sCritBonus = GetCombatRatingBonus and GetCombatRatingBonus(CR_CRIT_SPELL or 11) or 0
            tt:AddLine(string.format("%s: %d", STAT_CRIT_SPELL_RATING or (L["Spell Crit"] or "Kritische Zaubertrefferwertung"), spellCritRating), 1, 1, 1)
            tt:AddLine(string.format(L["Increases spell critical strike chance by %.2f%%."] or "Erhöht die Chance auf kritische Zaubertreffer um %.2f%%.", sCritBonus), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Spell Hit"] or "Zaubertreffer", spellHitStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            local sHitBonus = GetCombatRatingBonus and GetCombatRatingBonus(CR_HIT_SPELL or 8) or 0
            local spellPen = (GetSpellPenetration and GetSpellPenetration()) or 0
            tt:AddLine(string.format("%s: %d", STAT_HIT_RATING or (L["Spell Hit"] or "Trefferwertung"), spellHitRating), 1, 1, 1)
            tt:AddLine(string.format(L["Increases spell hit chance against level %d targets by %.2f%%."] or "Erhöht die Chance auf Zaubertreffer gegen Ziele der Stufe %d um %.2f%%.", playerLevel, sHitBonus), 1, 0.82, 0, true)
            tt:AddLine(string.format(L["\nSpell Penetration: %d\nReduces enemy magic resistances by %d."] or "\nZauberdurchschlag: %d\nVerringert die Magiewiderstände der Ziele um %d.", spellPen, spellPen), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Spell Haste"] or "Zaubertempo", string.format("(%d) %.2f%%", spellHasteRating, spellHastePct), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %d", STAT_HASTE_SPELL_RATING or (L["Spell Haste"] or "Zaubertempowertung"), spellHasteRating), 1, 1, 1)
            tt:AddLine(string.format(L["Increases spell casting speed by %.2f%%."] or "Erhöht die Zauberausführungsgeschwindigkeit um %.2f%%.", spellHastePct), 1, 0.82, 0, true)
        end)

        if manaRegen and manaRegen > 0 then
            lineCount = lineCount + 1
            AddStatLine(L["Mana Regen (MP5)"] or "Manareg (MP5)", string.format("%.0f", manaRegen * 5), lineCount % 2 == 0, nil, nil, nil, function(tt)
                local baseRegen, castingRegen = GetManaRegen()
                tt:AddLine(MANA_REGEN_TOOLTIP or (L["Mana Regen (MP5)"] or "Manaregeneration"), 1, 1, 1)
                tt:AddLine(string.format(L["While not casting: %.0f MP5\nWhile casting: %.0f MP5"] or "Außerhalb des Zauberns: %.0f MP5\nWährend des Zauberns: %.0f MP5", (baseRegen or 0) * 5, (castingRegen or 0) * 5), 1, 0.82, 0, true)
            end)
        end
    end

    -- 5. VERTEIDIGUNG
    if cfg.defense ~= false then
        AddCategoryHeader(L["Defense"] or "Verteidigung")
        lineCount = 0

        local _, armor = UnitArmor("player")
        local armorReduction = 0
        if PaperDollFrame_GetArmorReduction then
            armorReduction = PaperDollFrame_GetArmorReduction(armor, playerLevel)
        elseif armor > 0 then
            armorReduction = (armor / (armor + 400 + 85 * playerLevel)) * 100
        end
        local armorStr = string.format("%d |cff00ff00(%.2f%%)|r", armor, armorReduction)

        local def, posDef = UnitDefense("player")
        local totalDef = def + posDef
        local baseDef = playerLevel * 5
        local extraDef = totalDef - baseDef

        local dodge = GetDodgeChance()
        local parry = GetParryChance()
        local block = GetBlockChance()
        local resilienceRating = (GetCombatRating and GetCombatRating(CR_RESILIENCE_CRIT_TAKEN or 15)) or 0
        local resilienceCrit = (GetCombatRatingBonus and GetCombatRatingBonus(CR_RESILIENCE_CRIT_TAKEN or 15)) or 0

        local defCritReduction = extraDef * 0.04
        local totalCritReduction = defCritReduction + resilienceCrit
        local critImmuneNeeded = 5.60

        local critImmuneStr
        if totalCritReduction >= critImmuneNeeded then
            critImmuneStr = string.format("|cff00ff00%.2f%% / 5.6%% (%s)|r", totalCritReduction, L["Immune"] or "Immun")
        else
            critImmuneStr = string.format("%.2f%% / 5.6%%", totalCritReduction)
        end

        local bossMiss = math.max(0, 4.40 + (extraDef * 0.04))
        local totalAvoidance = bossMiss + dodge + parry + block
        local avoidanceStr = string.format("%.2f%%", totalAvoidance)

        lineCount = lineCount + 1
        AddStatLine(L["Armor"] or "Rüstung", armorStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(ARMOR or (L["Armor"] or "Rüstung"), 1, 1, 1)
            tt:AddLine(string.format(L["Reduces physical damage taken from level %d enemies by %.2f%%."] or "Verringert den erlittenen physischen Schaden von Gegnern der Stufe %d um %.2f%%.", playerLevel, armorReduction), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Defense"] or "Verteidigung", tostring(totalDef), lineCount % 2 == 0, nil, nil, nil, function(tt)
            local defRating = (GetCombatRating and GetCombatRating(CR_DEFENSE_SKILL or 2)) or 0
            tt:AddLine(string.format("%s: %d", DEFENSE or (L["Defense"] or "Verteidigung"), totalDef), 1, 1, 1)
            tt:AddLine(string.format(L["Defense Rating: %d\nIncreases Dodge, Parry, Block and Miss chance by %.2f%%.\nReduces chance to be critically hit by %.2f%%."] or "Verteidigungswertung: %d\nErhöht Ausweichen, Parieren, Blocken und Verfehlen um %.2f%%.\nVerringert Chance, kritisch getroffen zu werden, um %.2f%%.", defRating, extraDef * 0.04, extraDef * 0.04), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Dodge"] or "Ausweichen", string.format("%.2f%%", dodge), lineCount % 2 == 0, nil, nil, nil, function(tt)
            local dodgeRating = (GetCombatRating and GetCombatRating(CR_DODGE or 3)) or 0
            tt:AddLine(string.format("%s: %.2f%%", DODGE or (L["Dodge"] or "Ausweichen"), dodge), 1, 1, 1)
            tt:AddLine(string.format(L["Dodge Rating: %d"] or "Ausweichwertung: %d", dodgeRating), 1, 0.82, 0)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Parry"] or "Parieren", string.format("%.2f%%", parry), lineCount % 2 == 0, nil, nil, nil, function(tt)
            local parryRating = (GetCombatRating and GetCombatRating(CR_PARRY or 4)) or 0
            tt:AddLine(string.format("%s: %.2f%%", PARRY or (L["Parry"] or "Parieren"), parry), 1, 1, 1)
            tt:AddLine(string.format(L["Parry Rating: %d"] or "Parrierwertung: %d", parryRating), 1, 0.82, 0)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Block"] or "Blocken", string.format("%.2f%%", block), lineCount % 2 == 0, nil, nil, nil, function(tt)
            local blockRating = (GetCombatRating and GetCombatRating(CR_BLOCK or 5)) or 0
            local blockValue = (GetShieldBlock and GetShieldBlock()) or 0
            tt:AddLine(string.format("%s: %.2f%%", BLOCK or (L["Block"] or "Blocken"), block), 1, 1, 1)
            tt:AddLine(string.format(L["Block Rating: %d\nBlock Value: %d damage"] or "Blockwertung: %d\nBlockwert: %d Schaden", blockRating, blockValue), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Resilience"] or "Abhärtung", tostring(resilienceRating), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %d", RESILIENCE or (L["Resilience"] or "Abhärtung"), resilienceRating), 1, 1, 1)
            tt:AddLine(string.format(L["Reduces chance to be critically hit by %.2f%%.\nReduces damage taken from critical strikes by %.2f%%."] or "Verringert die Chance, kritisch getroffen zu werden, um %.2f%%.\nVerringert den Schaden von kritischen Treffern um %.2f%%.", resilienceCrit, resilienceCrit * 2), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Crit Immunity"] or "Krit-Immunität", critImmuneStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Crit Immunity (vs Level +3 Raid Boss)"] or "Krit-Immunität (gegen Level +3 Raidboss)", 1, 1, 1)
            tt:AddLine(string.format(L["Required: 5.60%%\nFrom Defense: %.2f%%\nFrom Resilience: %.2f%%\nTotal: %.2f%%"] or "Benötigt: 5.60%%\nAus Verteidigung: %.2f%%\nAus Abhärtung: %.2f%%\nGesamt: %.2f%%", defCritReduction, resilienceCrit, totalCritReduction), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Avoidance"] or "Vermeidung (Gesamt)", avoidanceStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Total Avoidance"] or "Gesamte Vermeidung", 1, 1, 1)
            tt:AddLine(string.format(L["Boss Miss: %.2f%%\nDodge: %.2f%%\nParry: %.2f%%\nBlock: %.2f%%\n-----------------\nTotal: %.2f%%"] or "Gegner-Verfehlen: %.2f%%\nAusweichen: %.2f%%\nParieren: %.2f%%\nBlocken: %.2f%%\n-----------------\nGesamtsumme: %.2f%%", bossMiss, dodge, parry, block, totalAvoidance), 1, 0.82, 0, true)
        end)
    end

    -- 6. RESISTENZEN
    if cfg.resistances ~= false then
        AddCategoryHeader(L["Resistances"] or "Resistenzen")
        lineCount = 0

        local resSchools = {
            { id = 2, key = "Fire", fallback = "Feuer" },
            { id = 3, key = "Nature", fallback = "Natur" },
            { id = 4, key = "Frost", fallback = "Frost" },
            { id = 5, key = "Shadow", fallback = "Schatten" },
            { id = 6, key = "Arcane", fallback = "Arkan" },
            { id = 1, key = "Holy", fallback = "Heilig" },
        }

        for _, school in ipairs(resSchools) do
            lineCount = lineCount + 1
            local base, total, bonus, minus = UnitResistance("player", school.id)
            local valStr = tostring(total or 0)
            if bonus and bonus > 0 then valStr = valStr .. " |cff00ff00(+" .. bonus .. ")|r" end
            if minus and minus < 0 then valStr = valStr .. " |cffff0000(" .. minus .. ")|r" end
            
            AddStatLine(L[school.key] or school.fallback, valStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
                local resName = _G["SPELL_SCHOOL" .. school.id .. "_CAP"] or (L[school.key] or school.fallback)
                tt:AddLine(string.format("%s: %d", resName, total or 0), 1, 1, 1)
                tt:AddLine(string.format(L["Base: %d | Bonus: +%d | Penalty: %d"] or "Basis: %d | Bonus: +%d | Abzug: %d", base or 0, bonus or 0, minus or 0), 1, 0.82, 0, true)
            end)
        end
    end

    -- 7. ALLGEMEIN
    if cfg.general ~= false then
        AddCategoryHeader(L["General"] or "Allgemein")
        lineCount = 0
        local curDur, maxDur = 0, 0
        local totalRepairCost = 0

        for slot = 1, 18 do
            if slot ~= 4 and slot ~= 19 then
                local v1, v2 = GetInventoryItemDurability(slot)
                if v1 and v2 then curDur = curDur + v1; maxDur = maxDur + v2 end
                totalRepairCost = totalRepairCost + GetSlotRepairCost(slot)
            end
        end

        local durPercent = (maxDur > 0) and (curDur / maxDur * 100) or 100
        local rD, gD, bD = E:ColorGradient(durPercent * 0.01, 1, 0, 0, 1, 1, 0, 0, 1, 0)
        lineCount = lineCount + 1
        AddStatLine(L["Durability:"] or "Haltbarkeit", string.format("|cff%02x%02x%02x%.0f%%|r", rD * 255, gD * 255, bD * 255, durPercent), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Durability:"] or "Haltbarkeit", 1, 1, 1)
            tt:AddLine(string.format(L["Current: %d / %d (%.1f%%)"] or "Aktuell: %d / %d (%.1f%%)", curDur, maxDur, durPercent), 1, 0.82, 0, true)
        end)
        
        lineCount = lineCount + 1
        AddStatLine(L["Repair Cost:"] or "Reparaturkosten:", FormatCostFull(totalRepairCost), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Repair Cost:"] or "Reparaturkosten", 1, 1, 1)
            tt:AddLine(string.format(L["Total repair cost of all equipped items: %s"] or "Gesamtkosten aller angelegten Gegenstände: %s", FormatCostFull(totalRepairCost)), 1, 0.82, 0, true)
        end)
    end
end

local function UpdateRetailStats()
    local cfg = E.db.AUI.characterStats.categories or {}
    local lineCount = 0

    -- 1. ATTRIBUTE (Primary)
    if cfg.attributes ~= false then
        AddCategoryHeader(L["Attributes"] or "Attribute")
        lineCount = 0

        -- 1. Stärke
        lineCount = lineCount + 1
        local _, strStat, strPos, strNeg = UnitStat("player", 1)
        local strValStr = BreakUpLargeNumbers(strStat)
        if strPos > 0 then strValStr = strValStr .. " |cff00ff00(+" .. BreakUpLargeNumbers(strPos) .. ")|r" end
        if strNeg < 0 then strValStr = strValStr .. " |cffff0000(" .. BreakUpLargeNumbers(strNeg) .. ")|r" end

        AddStatLine(L["Strength"] or "Stärke", strValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %s", SPELL_STAT1_NAME or "Stärke", BreakUpLargeNumbers(strStat)), 1, 1, 1)
            tt:AddLine(string.format("Erhöht die Angriffskraft um %s.", BreakUpLargeNumbers(strStat)), 1, 0.82, 0, true)
        end)

        -- 2. Beweglichkeit
        lineCount = lineCount + 1
        local _, agiStat, agiPos, agiNeg = UnitStat("player", 2)
        local agiValStr = BreakUpLargeNumbers(agiStat)
        if agiPos > 0 then agiValStr = agiValStr .. " |cff00ff00(+" .. BreakUpLargeNumbers(agiPos) .. ")|r" end
        if agiNeg < 0 then agiValStr = agiValStr .. " |cffff0000(" .. BreakUpLargeNumbers(agiNeg) .. ")|r" end

        AddStatLine(L["Agility"] or "Beweglichkeit", agiValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %s", SPELL_STAT2_NAME or "Beweglichkeit", BreakUpLargeNumbers(agiStat)), 1, 1, 1)
            tt:AddLine(string.format("Erhöht die Angriffskraft um %s.", BreakUpLargeNumbers(agiStat)), 1, 0.82, 0, true)
        end)

        -- 3. Ausdauer
        lineCount = lineCount + 1
        local _, staStat, staPos, staNeg = UnitStat("player", 3)
        local staValStr = BreakUpLargeNumbers(staStat)
        if staPos > 0 then staValStr = staValStr .. " |cff00ff00(+" .. BreakUpLargeNumbers(staPos) .. ")|r" end
        if staNeg < 0 then staValStr = staValStr .. " |cffff0000(" .. BreakUpLargeNumbers(staNeg) .. ")|r" end

        AddStatLine(L["Stamina"] or "Ausdauer", staValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %s", SPELL_STAT3_NAME or "Ausdauer", BreakUpLargeNumbers(staStat)), 1, 1, 1)
            tt:AddLine(string.format("Erhöht die maximale Gesundheit um %s HP.", BreakUpLargeNumbers(staStat * 20)), 1, 0.82, 0, true)
        end)

        -- 4. Intelligenz
        lineCount = lineCount + 1
        local _, intStat, intPos, intNeg = UnitStat("player", 4)
        local intValStr = BreakUpLargeNumbers(intStat)
        if intPos > 0 then intValStr = intValStr .. " |cff00ff00(+" .. BreakUpLargeNumbers(intPos) .. ")|r" end
        if intNeg < 0 then intValStr = intValStr .. " |cffff0000(" .. BreakUpLargeNumbers(intNeg) .. ")|r" end

        AddStatLine(L["Intellect"] or "Intelligenz", intValStr, lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %s", SPELL_STAT4_NAME or "Intelligenz", BreakUpLargeNumbers(intStat)), 1, 1, 1)
            tt:AddLine(string.format("Erhöht die Zaubermacht um %s.", BreakUpLargeNumbers(intStat)), 1, 0.82, 0, true)
        end)
    end

    -- 2. ENHANCEMENTS (Midnight Retail Stats)
    if cfg.enhancements ~= false then
        AddCategoryHeader(STAT_CATEGORY_ENHANCEMENT or "Verstärkungen")
        lineCount = 0

        -- Kritisch
        lineCount = lineCount + 1
        local crit = GetCritChance()
        local critRating = GetCombatRating(CR_CRIT_SPELL or 9) or 0
        local critBonus = GetCombatRatingBonus(CR_CRIT_SPELL or 9) or 0

        AddStatLine(STAT_CRITICAL_STRIKE or "Kritisch", string.format("%.2f%%", crit), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %.2f%%", STAT_CRITICAL_STRIKE or "Kritisch", crit), 1, 1, 1)
            tt:AddLine(string.format("Kritische Trefferwertung: %s (+%.2f%%)\nErhöht die Chance auf kritische Treffer und kritische Heilungen.", BreakUpLargeNumbers(critRating), critBonus), 1, 0.82, 0, true)
        end)

        -- Tempo
        lineCount = lineCount + 1
        local haste = GetHaste()
        local hasteRating = GetCombatRating(CR_HASTE_SPELL or 20) or 0

        AddStatLine(STAT_HASTE or "Tempo", string.format("%.2f%%", haste), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %.2f%%", STAT_HASTE or "Tempo", haste), 1, 1, 1)
            tt:AddLine(string.format("Tempowertung: %s\nErhöht Angriffs- und Zaubertempo sowie die Ressourcenregeneration.", BreakUpLargeNumbers(hasteRating)), 1, 0.82, 0, true)
        end)

        -- Meisterschaft
        lineCount = lineCount + 1
        local mastery = GetMasteryEffect()
        local masteryRating = GetCombatRating(CR_MASTERY or 26) or 0

        AddStatLine(STAT_MASTERY or "Meisterschaft", string.format("%.2f%%", mastery), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %.2f%%", STAT_MASTERY or "Meisterschaft", mastery), 1, 1, 1)
            tt:AddLine(string.format("Meisterschaftswertung: %s\nVerstärkt die Meisterschaft eurer Spezialisierung.", BreakUpLargeNumbers(masteryRating)), 1, 0.82, 0, true)
        end)

        -- Vielseitigkeit
        lineCount = lineCount + 1
        local versatility = (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0) + (GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE) or 0)
        local versatilityDef = (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) or 0) + (GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN) or 0)
        local versRating = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE or 29) or 0

        AddStatLine(STAT_VERSATILITY or "Vielseitigkeit", string.format("%.2f%% / %.2f%%", versatility, versatilityDef), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(string.format("%s: %.2f%% / %.2f%%", STAT_VERSATILITY or "Vielseitigkeit", versatility, versatilityDef), 1, 1, 1)
            tt:AddLine(string.format("Vielseitigkeitswertung: %s\nErhöht verursachten Schaden und Heilung um %.2f%%.\nVerringert erlittenen Schaden um %.2f%%.", BreakUpLargeNumbers(versRating), versatility, versatilityDef), 1, 0.82, 0, true)
        end)

        -- Lebensraub
        local leech = GetLifesteal()
        if leech > 0 then
            lineCount = lineCount + 1
            local leechRating = GetCombatRating(CR_LIFESTEAL or 17) or 0
            AddStatLine(STAT_LIFESTEAL or "Lebensraub", string.format("%.2f%%", leech), lineCount % 2 == 0, nil, nil, nil, function(tt)
                tt:AddLine(string.format("%s: %.2f%%", STAT_LIFESTEAL or "Lebensraub", leech), 1, 1, 1)
                tt:AddLine(string.format("Lebensraubwertung: %s\nHeilt Euch um %.2f%% des verursachten Schadens und der gewirkten Heilung.", BreakUpLargeNumbers(leechRating), leech), 1, 0.82, 0, true)
            end)
        end

        -- Vermeidung
        local avoidance = GetAvoidance()
        if avoidance > 0 then
            lineCount = lineCount + 1
            local avoidanceRating = GetCombatRating(CR_AVOIDANCE or 21) or 0
            AddStatLine(STAT_AVOIDANCE or "Vermeidung", string.format("%.2f%%", avoidance), lineCount % 2 == 0, nil, nil, nil, function(tt)
                tt:AddLine(string.format("%s: %.2f%%", STAT_AVOIDANCE or "Vermeidung", avoidance), 1, 1, 1)
                tt:AddLine(string.format("Vermeidungswertung: %s\nVerringert erlittenen Flächenschaden um %.2f%%.", BreakUpLargeNumbers(avoidanceRating), avoidance), 1, 0.82, 0, true)
            end)
        end

        -- Geschwindigkeit
        local speed = GetSpeed()
        if speed > 0 then
            lineCount = lineCount + 1
            local speedRating = GetCombatRating(CR_SPEED or 14) or 0
            AddStatLine(STAT_SPEED or "Geschwindigkeit", string.format("%.2f%%", speed), lineCount % 2 == 0, nil, nil, nil, function(tt)
                tt:AddLine(string.format("%s: %.2f%%", STAT_SPEED or "Geschwindigkeit", speed), 1, 1, 1)
                tt:AddLine(string.format("Geschwindigkeitswertung: %s\nErhöht eure Bewegungsgeschwindigkeit um %.2f%%.", BreakUpLargeNumbers(speedRating), speed), 1, 0.82, 0, true)
            end)
        end
    end

    -- 3. VERTEIDIGUNG
    if cfg.defense ~= false then
        AddCategoryHeader(L["Defense"] or "Verteidigung")
        lineCount = 0

        local _, armor = UnitArmor("player")
        local dodge = GetDodgeChance()
        local parry = GetParryChance()
        local block = GetBlockChance()

        lineCount = lineCount + 1
        AddStatLine(L["Armor"] or "Rüstung", BreakUpLargeNumbers(armor), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(ARMOR or "Rüstung", 1, 1, 1)
            tt:AddLine(string.format("Gesamte Rüstung: %s\nVerringert erlittenen physischen Schaden.", BreakUpLargeNumbers(armor)), 1, 0.82, 0, true)
        end)

        if dodge > 0 then
            lineCount = lineCount + 1
            AddStatLine(L["Dodge"] or "Ausweichen", string.format("%.2f%%", dodge), lineCount % 2 == 0, nil, nil, nil, function(tt)
                local dodgeRating = GetCombatRating(CR_DODGE or 3) or 0
                tt:AddLine(string.format("%s: %.2f%%", DODGE or "Ausweichen", dodge), 1, 1, 1)
                tt:AddLine(string.format("Ausweichwertung: %s", BreakUpLargeNumbers(dodgeRating)), 1, 0.82, 0)
            end)
        end
        if parry > 0 then
            lineCount = lineCount + 1
            AddStatLine(L["Parry"] or "Parieren", string.format("%.2f%%", parry), lineCount % 2 == 0, nil, nil, nil, function(tt)
                local parryRating = GetCombatRating(CR_PARRY or 4) or 0
                tt:AddLine(string.format("%s: %.2f%%", PARRY or "Parieren", parry), 1, 1, 1)
                tt:AddLine(string.format("Parrierwertung: %s", BreakUpLargeNumbers(parryRating)), 1, 0.82, 0)
            end)
        end
        if block > 0 then
            lineCount = lineCount + 1
            AddStatLine(L["Block"] or "Blocken", string.format("%.2f%%", block), lineCount % 2 == 0, nil, nil, nil, function(tt)
                local blockRating = GetCombatRating(CR_BLOCK or 5) or 0
                tt:AddLine(string.format("%s: %.2f%%", BLOCK or "Blocken", block), 1, 1, 1)
                tt:AddLine(string.format("Blockwertung: %s", BreakUpLargeNumbers(blockRating)), 1, 0.82, 0)
            end)
        end
    end

    -- 4. ALLGEMEIN
    if cfg.general ~= false then
        AddCategoryHeader(L["General"] or "Allgemein")
        lineCount = 0
        local curDur, maxDur = 0, 0
        local totalRepairCost = 0

        for slot = 1, 18 do
            if slot ~= 4 and slot ~= 19 then
                local v1, v2 = GetInventoryItemDurability(slot)
                if v1 and v2 then curDur = curDur + v1; maxDur = maxDur + v2 end
                totalRepairCost = totalRepairCost + GetSlotRepairCost(slot)
            end
        end

        local durPercent = (maxDur > 0) and (curDur / maxDur * 100) or 100
        local rD, gD, bD = E:ColorGradient(durPercent * 0.01, 1, 0, 0, 1, 1, 0, 0, 1, 0)
        lineCount = lineCount + 1
        AddStatLine(L["Durability:"] or "Haltbarkeit", string.format("|cff%02x%02x%02x%.0f%%|r", rD * 255, gD * 255, bD * 255, durPercent), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Durability:"] or "Haltbarkeit", 1, 1, 1)
            tt:AddLine(string.format(L["Current: %d / %d (%.1f%%)"] or "Aktuell: %d / %d (%.1f%%)", curDur, maxDur, durPercent), 1, 0.82, 0, true)
        end)

        lineCount = lineCount + 1
        AddStatLine(L["Repair Cost:"] or "Reparaturkosten:", FormatCostFull(totalRepairCost), lineCount % 2 == 0, nil, nil, nil, function(tt)
            tt:AddLine(L["Repair Cost:"] or "Reparaturkosten", 1, 1, 1)
            tt:AddLine(string.format(L["Total repair cost of all equipped items: %s"] or "Gesamtkosten aller angelegten Gegenstände: %s", FormatCostFull(totalRepairCost)), 1, 0.82, 0, true)
        end)
    end
end

function AUI:UpdateCharacterStats()
    if not E.db.AUI.characterStats.enable or not (_G.CharacterFrame and _G.CharacterFrame:IsShown()) then return end
    
    -- Wenn WindTools Armory aktiv ist, Advanced Stats komplett deaktivieren
    if IsWindToolsArmoryActive() then
        StatsFrame:Hide()
        AUI:UpdateItemOverlays()
        return
    end

    ResetRows()

    if isRetail then
        UpdateRetailStats()
    else
        UpdateClassicStats()
    end

    local yOffset = 0
    for i = 1, rowIndex do
        local r = rows[i]
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - (r:GetHeight() + 1)
    end
    scrollChild:SetHeight(math.abs(yOffset) + 25)

    AUI:UpdateItemOverlays()
end

-- =====================================================================
-- 8. BLIZZARD STATS HIDING (NUR CLASSIC / TBC)
-- =====================================================================
local function HideDropDownCompletely(ddFrame)
    if not ddFrame then return end
    ddFrame:Hide()
    ddFrame:SetAlpha(0)
    ddFrame:EnableMouse(false)

    local name = ddFrame:GetName()
    if name then
        local left = _G[name .. "Left"]
        local mid = _G[name .. "Middle"]
        local right = _G[name .. "Right"]
        local btn = _G[name .. "Button"]
        local txt = _G[name .. "Text"]
        if left then left:SetAlpha(0) end
        if mid then mid:SetAlpha(0) end
        if right then right:SetAlpha(0) end
        if btn then btn:Hide(); btn:EnableMouse(false) end
        if txt then txt:SetText("") end
    end
end

local function ShowDropDownCompletely(ddFrame)
    if not ddFrame then return end
    ddFrame:SetAlpha(1)
    ddFrame:EnableMouse(true)
    ddFrame:Show()

    local name = ddFrame:GetName()
    if name then
        local left = _G[name .. "Left"]
        local mid = _G[name .. "Middle"]
        local right = _G[name .. "Right"]
        local btn = _G[name .. "Button"]
        if left then left:SetAlpha(1) end
        if mid then mid:SetAlpha(1) end
        if right then right:SetAlpha(1) end
        if btn then btn:Show(); btn:EnableMouse(true) end
    end
end

local function ApplyBlizzardStatsVisibility()
    if isRetail then return end

    local hide = E.db.AUI.characterStats.hideBlizzardStats

    local dropDowns = {
        _G.PlayerStatFrameLeftDropDown,
        _G.PlayerStatFrameRightDropDown,
        _G.PlayerStatDropdown1,
        _G.PlayerStatDropdown2,
        _G.CharacterAttributesFrame and _G.CharacterAttributesFrame.PlayerStatFrameLeftDropDown,
        _G.CharacterAttributesFrame and _G.CharacterAttributesFrame.PlayerStatFrameRightDropDown,
    }

    if _G.CharacterFrame then
        table.insert(dropDowns, _G.CharacterFrame.LeftDropDown)
        table.insert(dropDowns, _G.CharacterFrame.RightDropDown)
    end
    if _G.PaperDollFrame then
        table.insert(dropDowns, _G.PaperDollFrame.LeftDropDown)
        table.insert(dropDowns, _G.PaperDollFrame.RightDropDown)
    end

    for _, dd in ipairs(dropDowns) do
        if hide then
            HideDropDownCompletely(dd)
        else
            ShowDropDownCompletely(dd)
        end
    end

    for i = 1, 12 do
        local leftStat = _G["PlayerStatFrameLeft" .. i]
        local rightStat = _G["PlayerStatFrameRight" .. i]
        local dropStat = _G["PlayerStatDropdown" .. i]

        if hide then
            if leftStat then leftStat:Hide(); leftStat:SetAlpha(0) end
            if rightStat then rightStat:Hide(); rightStat:SetAlpha(0) end
            if dropStat then HideDropDownCompletely(dropStat) end
        else
            if leftStat then leftStat:SetAlpha(1); leftStat:Show() end
            if rightStat then rightStat:SetAlpha(1); rightStat:Show() end
            if dropStat then ShowDropDownCompletely(dropStat) end
        end
    end

    if _G.CharacterAttributesFrame then
        if hide then
            _G.CharacterAttributesFrame:Hide()
            _G.CharacterAttributesFrame:SetAlpha(0)
        else
            _G.CharacterAttributesFrame:SetAlpha(1)
            _G.CharacterAttributesFrame:Show()
        end
    end

    if _G.CharacterModelFrame and _G.PaperDollFrame then
        _G.CharacterModelFrame:ClearAllPoints()
        if hide then
            _G.CharacterModelFrame:SetPoint("TOPLEFT", _G.PaperDollFrame, "TOPLEFT", 60, -55)
            _G.CharacterModelFrame:SetPoint("BOTTOMRIGHT", _G.PaperDollFrame, "BOTTOMRIGHT", -60, 30)
        else
            _G.CharacterModelFrame:SetPoint("TOPLEFT", _G.PaperDollFrame, "TOPLEFT", 65, -70)
            _G.CharacterModelFrame:SetPoint("BOTTOMRIGHT", _G.PaperDollFrame, "BOTTOMRIGHT", -65, 115)
        end
    end

    UpdateResistanceIconsLayout()
end

-- =====================================================================
-- 9. ANDOCK-LOGIK & EVENT-WATCHER
-- =====================================================================
function AUI:InitStatsModule()
    local function AnchorStatsFrame()
        local parent = _G.CharacterFrame
        if parent and parent:IsShown() then
            StatsFrame:ClearAllPoints()
            if isRetail then
                StatsFrame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 1, 0)
                StatsFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 1, 0)
            else
                StatsFrame:SetPoint("TOPLEFT", parent, "TOPRIGHT", -31, -12)
                StatsFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", -31, -12)
            end
            StatsFrame:SetFrameLevel(parent:GetFrameLevel() or 1)
        end
    end

    if not isRetail then
        if _G.PaperDollFrame_UpdateStats then
            hooksecurefunc("PaperDollFrame_UpdateStats", function()
                if E.db.AUI.characterStats.hideBlizzardStats then
                    ApplyBlizzardStatsVisibility()
                end
            end)
        end

        if _G.PaperDollFrame_UpdateResistances then
            hooksecurefunc("PaperDollFrame_UpdateResistances", function()
                UpdateResistanceIconsLayout()
            end)
        end

        if _G.PaperDollFrame then
            _G.PaperDollFrame:HookScript("OnShow", function()
                ApplyBlizzardStatsVisibility()
                if E.db.AUI.characterStats.enable and not IsWindToolsArmoryActive() then
                    AnchorStatsFrame()
                    AUI:UpdateCharacterStats()
                    StatsFrame:Show()
                else
                    StatsFrame:Hide()
                end
                AUI:UpdateItemOverlays()
            end)
        end
    end

    if _G.CharacterFrame then
        _G.CharacterFrame:HookScript("OnShow", function()
            if not isRetail then
                ApplyBlizzardStatsVisibility()
            end
            if E.db.AUI.characterStats.enable and not IsWindToolsArmoryActive() then
                AnchorStatsFrame()
                AUI:UpdateCharacterStats()
                StatsFrame:Show()
            else
                StatsFrame:Hide()
            end
            AUI:UpdateItemOverlays()
        end)
        _G.CharacterFrame:HookScript("OnHide", function()
            StatsFrame:Hide()
        end)
    end

    local statWatcher = CreateFrame("Frame")
    if isRetail then
        statWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        statWatcher:RegisterEvent("UNIT_STATS")
        statWatcher:RegisterEvent("UNIT_DAMAGE")
        statWatcher:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    else
        statWatcher:RegisterEvent("UNIT_INVENTORY_CHANGED")
        statWatcher:RegisterEvent("UNIT_STATS")
        statWatcher:RegisterEvent("UNIT_DAMAGE")
        statWatcher:RegisterEvent("UNIT_RESISTANCES")
        statWatcher:RegisterEvent("UNIT_ATTACK_SPEED")
        statWatcher:RegisterEvent("UNIT_ATTACK_POWER")
        statWatcher:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
        statWatcher:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    end

    statWatcher:SetScript("OnEvent", function(_, _, unit)
        if unit == "player" or not unit then
            if _G.CharacterFrame and _G.CharacterFrame:IsShown() then
                if not IsWindToolsArmoryActive() then
                    if StatsFrame:IsShown() then
                        AUI:UpdateCharacterStats()
                    end
                    AUI:UpdateItemOverlays()
                    if not isRetail then
                        UpdateResistanceIconsLayout()
                    end
                else
                    StatsFrame:Hide()
                    AUI:UpdateItemOverlays()
                end
            end
        end
    end)
end

-- =====================================================================
-- 10. MENÜ
-- =====================================================================
local function InsertStatsOptions()
    if not E.Options.args.AUI or not E.Options.args.AUI.args then return end

    local categoryArgs = isRetail and {
        attributes = {
            order = 1,
            type = "toggle",
            name = L["Show Attributes"] or "Attribute anzeigen",
        },
        enhancements = {
            order = 2,
            type = "toggle",
            name = STAT_CATEGORY_ENHANCEMENT or "Verstärkungen anzeigen",
        },
        defense = {
            order = 3,
            type = "toggle",
            name = L["Show Defense"] or "Verteidigung anzeigen",
        },
        general = {
            order = 4,
            type = "toggle",
            name = L["Show General"] or "Allgemein anzeigen",
        },
    } or {
        attributes = {
            order = 1,
            type = "toggle",
            name = L["Show Attributes"] or "Attribute anzeigen",
        },
        melee = {
            order = 2,
            type = "toggle",
            name = L["Show Melee"] or "Nahkampf anzeigen",
        },
        ranged = {
            order = 3,
            type = "toggle",
            name = L["Show Ranged"] or "Fernkampf anzeigen",
        },
        spell = {
            order = 4,
            type = "toggle",
            name = L["Show Spell"] or "Zauber anzeigen",
        },
        defense = {
            order = 5,
            type = "toggle",
            name = L["Show Defense"] or "Verteidigung anzeigen",
        },
        resistances = {
            order = 6,
            type = "toggle",
            name = L["Show Resistances"] or "Resistenzen anzeigen",
        },
        general = {
            order = 7,
            type = "toggle",
            name = L["Show General"] or "Allgemein anzeigen",
        },
    }

    E.Options.args.AUI.args.characterStats = {
        type = "group",
        name = L["Character-Stats Panel"] or "Charakter-Stats",
        order = 7,
        get = function(info) return E.db.AUI.characterStats[info[#info]] end,
        set = function(info, value)
            E.db.AUI.characterStats[info[#info]] = value
            local charShown = _G.CharacterFrame and _G.CharacterFrame:IsShown()
            local wtArmory = IsWindToolsArmoryActive()

            if not E.db.AUI.characterStats.enable or wtArmory then 
                StatsFrame:Hide() 
            elseif charShown then 
                AUI:UpdateCharacterStats()
                StatsFrame:Show() 
            end
            
            if charShown then
                if not isRetail then
                    ApplyBlizzardStatsVisibility()
                    UpdateResistanceIconsLayout()
                end
                AUI:UpdateItemOverlays()
            end
        end,
        args = {
            header = {
                order = 1,
                type = "header",
                name = "|cff00ffd2" .. (L["Character-Stats Panel"] or "Charakter-Stats Panel") .. "|r",
            },
            desc = {
                order = 2,
                type = "description",
                name = (L["Displays a seamless ElvUI overview for all stats next to the character frame."] or "Zeigt eine nahtlos angedockte ElvUI-Übersicht für alle Werte neben dem Charakterfenster an.") .. "\n",
                fontSize = "medium",
            },
            enable = {
                order = 3,
                type = "toggle",
                name = L["Enable"] or "Aktivieren",
                width = "full",
            },
            hideBlizzardStats = not isRetail and {
                order = 4,
                type = "toggle",
                name = L["Hide Blizzard Stats"] or "Originale Blizzard-Stats ausblenden",
                desc = L["Hides the default Classic character stat dropdowns and stat text lines."] or "Blendet die standardmäßigen Classic-Dropdowns und Wertezeilen im Charakterfenster aus.",
                width = "full",
            } or nil,
            resistanceGroup = not isRetail and {
                order = 5,
                type = "group",
                guiInline = true,
                name = L["Resistance Icons"] or "Resistenz-Icons",
                args = {
                    showResistanceIcons = {
                        order = 1,
                        type = "toggle",
                        name = L["Show Resistance Icons"] or "Resistenz-Icons anzeigen",
                        desc = L["Displays the 5 resistance icons on the character model."] or "Blendet die 5 Resistenz-Icons auf dem Charaktermodell ein.",
                        width = "full",
                        set = function(info, value)
                            E.db.AUI.characterStats.showResistanceIcons = value
                            if _G.CharacterFrame and _G.CharacterFrame:IsShown() then
                                UpdateResistanceIconsLayout()
                            end
                        end,
                    },
                    resistanceOrientation = {
                        order = 2,
                        type = "select",
                        name = L["Icon Orientation"] or "Icon-Ausrichtung",
                        desc = L["Choose between vertical or horizontal layout for resistance icons."] or "Wähle zwischen vertikaler oder horizontaler Anordnung der Resistenz-Icons.",
                        disabled = function() return not E.db.AUI.characterStats.showResistanceIcons end,
                        values = {
                            ["VERTICAL"] = L["Vertical"] or "Vertikal",
                            ["HORIZONTAL"] = L["Horizontal"] or "Horizontal",
                        },
                        set = function(info, value)
                            E.db.AUI.characterStats.resistanceOrientation = value
                            if _G.CharacterFrame and _G.CharacterFrame:IsShown() then
                                UpdateResistanceIconsLayout()
                            end
                        end,
                    },
                }
            } or nil,
            overlaysGroup = {
                order = 6,
                type = "group",
                guiInline = true,
                name = L["Equipment Overlays"] or "Ausrüstungs-Overlays",
                args = {
                    showItemLevel = {
                        order = 1,
                        type = "toggle",
                        name = L["Item Level on Equipment"] or "Itemlevel auf Ausrüstung",
                        desc = L["Displays the item level of each equipment slot in quality color."] or "Blendet das Itemlevel jedes Ausrüstungsslots in der Qualitätsfarbe auf dem Icon ein.",
                        width = "full",
                    },
                    showDurability = {
                        order = 2,
                        type = "toggle",
                        name = L["Durability on Equipment"] or "Haltbarkeit auf Ausrüstung",
                        desc = L["Displays durability percentage on equipment icons with dynamic color."] or "Zeigt den Haltbarkeits-Prozentsatz auf den Ausrüstungs-Icons mit dynamischem Farbverlauf an.",
                        width = "full",
                    },
                    showRepairCost = {
                        order = 3,
                        type = "toggle",
                        name = L["Repair Cost on Equipment"] or "Reparaturkosten auf Ausrüstung",
                        desc = L["Displays repair costs on equipment icons."] or "Zeigt die Reparaturkosten auf den Ausrüstungs-Icons an.",
                        width = "full",
                    },
                    showEnchants = {
                        order = 4,
                        type = "toggle",
                        name = L["Show Enchants on Equipment"] or "Verzauberungen neben Ausrüstung",
                        desc = L["Displays the applied enchant name next to enchanted items."] or "Zeigt den Namen der aktiven Verzauberung neben den verzauberten Gegenständen an.",
                        width = "full",
                    },
                    showMissingEnchants = {
                        order = 5,
                        type = "toggle",
                        name = L["Missing Enchant Warning"] or "Warnung bei fehlender Verzauberung",
                        desc = L["Displays a warning text next to items missing an enchant."] or "Zeigt einen Warnhinweis neben Gegenständen an, denen eine Verzauberung fehlt.",
                        width = "full",
                    },
                    missingEnchantGlow = {
                        order = 6,
                        type = "toggle",
                        name = L["Missing Enchant Border"] or "Roter Rahmen bei fehlender Verzauberung",
                        desc = L["Colors the equipment slot border red if the item lacks an enchant."] or "Färbt den Slot-Rahmen rot ein, wenn dem Gegenstand eine Verzauberung fehlt.",
                        width = "full",
                    },
                }
            },
            categoriesGroup = {
                order = 7,
                type = "group",
                guiInline = true,
                name = L["Categories"] or "Kategorien",
                disabled = function() return not E.db.AUI.characterStats.enable end,
                get = function(info) 
                    local cat = info[#info]
                    if E.db.AUI.characterStats.categories[cat] == nil then return true end
                    return E.db.AUI.characterStats.categories[cat] 
                end,
                set = function(info, value)
                    local cat = info[#info]
                    E.db.AUI.characterStats.categories[cat] = value
                    if _G.CharacterFrame and _G.CharacterFrame:IsShown() then
                        AUI:UpdateCharacterStats()
                    end
                end,
                args = categoryArgs,
            }
        },
    }
end

-- =====================================================================
-- 11. INITIALISIERUNG
-- =====================================================================
hooksecurefunc(AUI, "Initialize", function()
    E.db.AUI = E.db.AUI or {}
    E.db.AUI.characterStats = E.db.AUI.characterStats or {
        enable = true,
        hideBlizzardStats = true,
        showItemLevel = true,
        showDurability = true,
        showRepairCost = true,
        showEnchants = true,
        showMissingEnchants = true,
        missingEnchantGlow = true,
        showResistanceIcons = true,
        resistanceOrientation = "VERTICAL",
        categories = isRetail and {
            attributes = true,
            enhancements = true,
            defense = true,
            general = true,
        } or {
            attributes = true,
            melee = true,
            ranged = true,
            spell = true,
            defense = true,
            resistances = true,
            general = true,
        }
    }
    AUI:InitStatsModule()
end)

hooksecurefunc(AUI, "InsertOptions", InsertStatsOptions)