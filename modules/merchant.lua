local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local S = E:GetModule('Skins')

-- =====================================================================
-- 1. DEFAULTS
-- =====================================================================
P["AUI"] = P["AUI"] or {}
P["AUI"]["merchant"] = {
    enable = true,
    cols = 4,   -- Wird in 2er Schritten (ganze Seitenblöcke) gerechnet
    rows = 5,
}

local ITEM_WIDTH = 153
local ITEM_HEIGHT = 44
local SPACING_X = 12
local SPACING_Y = 16    
local START_X = 22      
local START_Y = -68     

-- =====================================================================
-- 2. GRID SETTINGS LOGIK (Atmendes Fenster)
-- =====================================================================
local function GetGridSettings()
    local isBuyback = (_G.MerchantFrame and _G.MerchantFrame.selectedTab == 2)
    local COLS = E.db.AUI.merchant.cols or 4
    if COLS % 2 ~= 0 then COLS = COLS + 1 end
    local ROWS = E.db.AUI.merchant.rows or 5
    
    -- Dynamisches Schrumpfen für den Rückkauf-Reiter
    if isBuyback then
        COLS = 2
        ROWS = 6 -- Rückkauf braucht immer exakt 6 Reihen für 12 Items
    end
    
    return COLS, ROWS, isBuyback
end

-- =====================================================================
-- 3. SUCHFUNKTION
-- =====================================================================
local function UpdateSearch()
    if not E.db.AUI.merchant.enable or not _G.AUI_MerchantSearchBox then return end
    
    local searchText = _G.AUI_MerchantSearchBox:GetText():lower()
    local COLS, ROWS, isBuyback = GetGridSettings()
    local TOTAL_ITEMS = isBuyback and (_G.BUYBACK_ITEMS_PER_PAGE or 12) or (COLS * ROWS)
    local currentPage = _G.MerchantFrame.page or 1

    for i = 1, TOTAL_ITEMS do
        local itemFrame = _G["MerchantItem" .. i]
        if itemFrame and itemFrame:IsShown() then
            local itemName
            if isBuyback then
                itemName = GetBuybackItemInfo(i)
            else
                local itemIndex = ((currentPage - 1) * TOTAL_ITEMS) + i
                itemName = GetMerchantItemInfo(itemIndex)
            end
            
            if itemName then
                if searchText == "" or itemName:lower():find(searchText) then
                    itemFrame:SetAlpha(1)
                    if itemFrame.ItemButton and itemFrame.ItemButton.icon then
                        itemFrame.ItemButton.icon:SetDesaturated(false)
                    end
                else
                    itemFrame:SetAlpha(0.25)
                    if itemFrame.ItemButton and itemFrame.ItemButton.icon then
                        itemFrame.ItemButton.icon:SetDesaturated(true)
                    end
                end
            end
        end
    end
end

local function CreateSearchBox()
    if _G.AUI_MerchantSearchBox then return end
    
    local searchBox = CreateFrame("EditBox", "AUI_MerchantSearchBox", _G.MerchantFrame, "SearchBoxTemplate")
    searchBox:SetSize(ITEM_WIDTH, 20)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(40)
    
    if S and S.HandleEditBox then
        S:HandleEditBox(searchBox)
    end
    
    searchBox:SetScript("OnTextChanged", function(self)
        SearchBoxTemplate_OnTextChanged(self)
        UpdateSearch()
    end)
    
    searchBox:SetScript("OnHide", function(self)
        self:SetText("")
    end)
end

-- =====================================================================
-- 4. HÄNDLER-ITEMS POSITIONIEREN (Hybrid-System)
-- =====================================================================
function AUI:PositionMerchantItems()
    if not E.db.AUI.merchant.enable or not _G.MerchantFrame then return end
    
    local COLS, ROWS, isBuyback = GetGridSettings()
    local TOTAL_ITEMS = isBuyback and (_G.BUYBACK_ITEMS_PER_PAGE or 12) or (COLS * ROWS)
    
    local PAGE_COLS = 2
    local ITEMS_PER_PAGE = PAGE_COLS * ROWS

    for i = 1, TOTAL_ITEMS do
        local itemFrame = _G["MerchantItem" .. i]
        if itemFrame then
            itemFrame:ClearAllPoints()
            
            local absCol, absRow
            
            if isBuyback then
                -- Hybrides Raster: Der Rückkauf füllt strikt zeilenweise auf
                absCol = (i - 1) % COLS
                absRow = math.floor((i - 1) / COLS)
            else
                -- Normaler Händler: 2xX Blöcke (Seite für Seite)
                local blockIndex = math.floor((i - 1) / ITEMS_PER_PAGE)
                local indexInBlock = (i - 1) % ITEMS_PER_PAGE
                
                local colInBlock = indexInBlock % PAGE_COLS
                local rowInBlock = math.floor(indexInBlock / PAGE_COLS)
                
                absCol = (blockIndex * PAGE_COLS) + colInBlock
                absRow = rowInBlock
            end
            
            local xOffset = START_X + (absCol * (ITEM_WIDTH + SPACING_X))
            local yOffset = START_Y - (absRow * (ITEM_HEIGHT + SPACING_Y))

            itemFrame:SetPoint("TOPLEFT", _G.MerchantFrame, "TOPLEFT", xOffset, yOffset)
            itemFrame:Show()
        end
    end

    local lastColX = START_X + ((COLS - 1) * (ITEM_WIDTH + SPACING_X))

    -- Rückkauf-Button: Bündig unter der letzten Spalte (ganz rechts)
    if _G.MerchantBuyBackItem then
        _G.MerchantBuyBackItem:ClearAllPoints()
        _G.MerchantBuyBackItem:SetPoint("BOTTOMLEFT", _G.MerchantFrame, "BOTTOMLEFT", lastColX, 45)

        if not _G.MerchantBuyBackItem.AUI_Label then
            _G.MerchantBuyBackItem.AUI_Label = _G.MerchantBuyBackItem:CreateFontString(nil, "OVERLAY")
            _G.MerchantBuyBackItem.AUI_Label:SetFont(E.media.normFont or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
            _G.MerchantBuyBackItem.AUI_Label:SetPoint("BOTTOMLEFT", _G.MerchantBuyBackItem, "TOPLEFT", 0, 5)
        end
        _G.MerchantBuyBackItem.AUI_Label:SetText("|cffffd100" .. (L["Buyback"] or "BUYBACK") .. "|r")
    end
    
    -- Reparatur-Buttons: Bündig unter der ersten Spalte (ganz links)
    local repairAll = _G.MerchantRepairAllButton
    local repairItem = _G.MerchantRepairItemButton
    local repairGuild = _G.MerchantGuildBankRepairButton

    if repairAll then
        repairAll:ClearAllPoints()
        repairAll:SetPoint("BOTTOMLEFT", _G.MerchantFrame, "BOTTOMLEFT", START_X, 45)
        repairAll:SetSize(ITEM_HEIGHT, ITEM_HEIGHT)
        
        if not repairAll.AUI_Label then
            repairAll.AUI_Label = repairAll:CreateFontString(nil, "OVERLAY")
            repairAll.AUI_Label:SetFont(E.media.normFont or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
            repairAll.AUI_Label:SetPoint("BOTTOMLEFT", repairAll, "TOPLEFT", 0, 5)
        end
        repairAll.AUI_Label:SetText("|cffffd100" .. (L["Repair"] or "REPARATUR") .. "|r")
        
        if _G.MerchantRepairText then _G.MerchantRepairText:SetText("") end
        
        local anchorBtn = repairAll
        if repairItem then
            repairItem:ClearAllPoints()
            repairItem:SetPoint("LEFT", anchorBtn, "RIGHT", 6, 0)
            repairItem:SetSize(ITEM_HEIGHT, ITEM_HEIGHT)
            anchorBtn = repairItem
        end
        
        if repairGuild then
            repairGuild:ClearAllPoints()
            repairGuild:SetPoint("LEFT", anchorBtn, "RIGHT", 6, 0)
            repairGuild:SetSize(ITEM_HEIGHT, ITEM_HEIGHT)
        end
    end

    -- Suchleiste an letzte Spalte andocken
    if _G.AUI_MerchantSearchBox then
        _G.AUI_MerchantSearchBox:ClearAllPoints()
        _G.AUI_MerchantSearchBox:SetPoint("BOTTOMLEFT", _G.MerchantFrame, "TOPLEFT", lastColX, START_Y + 12)
    end
    
    UpdateSearch()
end

-- =====================================================================
-- 5. HÄNDLER-FRAME DYNAMISCH BERECHNEN & BAUEN
-- =====================================================================
function AUI:ExpandMerchantFrame()
    if not E.db.AUI.merchant.enable or not _G.MerchantFrame then 
        if _G.AUI_MerchantSearchBox then _G.AUI_MerchantSearchBox:Hide() end
        return 
    end
    
    CreateSearchBox()
    _G.AUI_MerchantSearchBox:Show()

    local COLS, ROWS, isBuyback = GetGridSettings()
    local TOTAL_ITEMS = isBuyback and (_G.BUYBACK_ITEMS_PER_PAGE or 12) or (COLS * ROWS)

    if not isBuyback then
        _G.MERCHANT_ITEMS_PER_PAGE = TOTAL_ITEMS
    end

    -- Dynamischer unterer Puffer: Beim Rückkauf viel kürzer, da Reparieren/Blättern wegfällt
    local paddingBottom = isBuyback and 65 or 120
    
    local frameWidth = (COLS * ITEM_WIDTH) + ((COLS - 1) * SPACING_X) + (START_X * 2)
    local frameHeight = (ROWS * ITEM_HEIGHT) + ((ROWS - 1) * SPACING_Y) + math.abs(START_Y) + paddingBottom

    _G.MerchantFrame:SetWidth(frameWidth)
    _G.MerchantFrame:SetHeight(math.max(428, frameHeight))

    for i = 1, TOTAL_ITEMS do
        local btn = _G["MerchantItem" .. i]
        if not btn then
            btn = CreateFrame("Frame", "MerchantItem" .. i, _G.MerchantFrame, "MerchantItemTemplate")
            
            if S then
                btn:StripTextures(true)
                btn:CreateBackdrop("Transparent")
                
                local itemBtn = _G["MerchantItem" .. i .. "ItemButton"]
                if itemBtn then
                    itemBtn:StripTextures()
                    itemBtn:StyleButton()
                    itemBtn:SetTemplate("Default", true)
                    
                    if itemBtn.icon then
                        itemBtn.icon:SetTexCoord(unpack(E.TexCoords))
                        itemBtn.icon:SetInside()
                    end
                    if itemBtn.IconBorder then
                        itemBtn.IconBorder:SetAlpha(0)
                    end
                end
            end
        end
    end

    -- Ausgeblendete Rest-Items beim Tab-Wechsel sicher verstecken
    local maxPossible = math.max(12, (E.db.AUI.merchant.cols or 4) * (E.db.AUI.merchant.rows or 5)) + 10
    for i = TOTAL_ITEMS + 1, maxPossible do
        if _G["MerchantItem" .. i] then
            _G["MerchantItem" .. i]:Hide()
        end
    end

    if _G.MerchantPrevPageButton and _G.MerchantNextPageButton and _G.MerchantPageText then
        _G.MerchantPageText:ClearAllPoints()
        _G.MerchantPageText:SetPoint("BOTTOM", _G.MerchantFrame, "BOTTOM", 0, 58)

        _G.MerchantPrevPageButton:ClearAllPoints()
        _G.MerchantPrevPageButton:SetPoint("RIGHT", _G.MerchantPageText, "LEFT", -12, -2)

        _G.MerchantNextPageButton:ClearAllPoints()
        _G.MerchantNextPageButton:SetPoint("LEFT", _G.MerchantPageText, "RIGHT", 12, -2)
    end
end

-- =====================================================================
-- 6. OPTIONEN-MENÜ
-- =====================================================================
local function InsertMerchantOptions()
    if not E.Options.args.AUI or not E.Options.args.AUI.args then return end

    E.Options.args.AUI.args.merchant = {
        type = "group",
        name = L["Merchant"] or "Händlerfenster",
        order = 8,
        get = function(info) return E.db.AUI.merchant[info[#info]] end,
        set = function(info, value) 
            E.db.AUI.merchant[info[#info]] = value
            if _G.MerchantFrame and _G.MerchantFrame:IsShown() and E.db.AUI.merchant.enable then
                AUI:ExpandMerchantFrame()
                if _G.MerchantFrame_Update then
                    _G.MerchantFrame_Update()
                end
            end
        end,
        args = {
            header = {
                order = 1,
                type = "header",
                name = "|cff00ffd2" .. (L["Merchant Frame"] or "Händlerfenster Erweiterung") .. "|r",
            },
            enable = {
                order = 2,
                type = "toggle",
                name = L["Enable"] or "Aktivieren",
                set = function(info, value)
                    E.db.AUI.merchant.enable = value
                    E:StaticPopup_Show("PRIVATE_RL")
                end
            },
            spacer = { order = 3, type = "description", name = "\n", width = "full" },
            cols = {
                order = 4,
                type = "range",
                name = L["Columns"] or "Spalten (Breite)",
                desc = "Standard Blizzard: 2 Spalten (1 Seite). Erweitert das Fenster um ganze Seiten (4, 6, 8).",
                min = 2, max = 8, step = 2,
                disabled = function() return not E.db.AUI.merchant.enable end,
            },
            rows = {
                order = 5,
                type = "range",
                name = L["Rows"] or "Reihen (Höhe)",
                desc = L["Default Blizzard: 5 Rows."] or "Standard Blizzard: 5 Reihen.",
                min = 5, max = 15, step = 1,
                disabled = function() return not E.db.AUI.merchant.enable end,
            },
        }
    }
end

-- =====================================================================
-- 7. INITIALISIERUNG
-- =====================================================================
function AUI:InitMerchantModule()
    if _G.MerchantFrame then
        _G.MerchantFrame:HookScript("OnShow", function()
            AUI:ExpandMerchantFrame()
            AUI:PositionMerchantItems()
        end)

        -- Beim Tab-Wechsel müssen beide Funktionen zwingend getriggert werden!
        hooksecurefunc("MerchantFrame_Update", function()
            AUI:ExpandMerchantFrame()
            AUI:PositionMerchantItems()
        end)
    end
end

hooksecurefunc(AUI, "Initialize", function()
    E.db.AUI = E.db.AUI or {}
    E.db.AUI.merchant = E.db.AUI.merchant or { enable = true, cols = 4, rows = 5 }
    AUI:InitMerchantModule()
end)

hooksecurefunc(AUI, "InsertOptions", InsertMerchantOptions)