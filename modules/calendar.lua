local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local S = E:GetModule('Skins')

local CalendarModule = CreateFrame("Frame", "AUI_CalendarFrame", E.UIParent, "BackdropTemplate")
AUI.Calendar = CalendarModule

-- =====================================================================
-- 1. STATISCHE FEIERSTAGE & ROTATIONEN (TBC)
-- =====================================================================
local HOLIDAYS = {
    { name = "New Year's Eve",          startM = 12, startD = 31, endM = 1,  endD = 1,  icon = "Interface\\Icons\\INV_Misc_Toy_10" },
    { name = "Lunar Festival",          startM = 1,  startD = 22, endM = 2,  endD = 12, icon = "Interface\\Icons\\INV_Misc_Coin_01" },
    { name = "Love is in the Air",      startM = 2,  startD = 11, endM = 2,  endD = 16, icon = "Interface\\Icons\\INV_ValentineChocolate01" },
    { name = "Noblegarden",             startM = 4,  startD = 9,  endM = 4,  endD = 15, icon = "Interface\\Icons\\INV_Egg_02" },
    { name = "Children's Week",         startM = 5,  startD = 9,  endM = 5,  endD = 16, icon = "Interface\\Icons\\INV_Misc_Toy_07" },
    { name = "Midsummer Fire Festival", startM = 6,  startD = 21, endM = 7,  endD = 5,  icon = "Interface\\Icons\\INV_SummerFest_FireFlowerBlue" },
    { name = "Brewfest",                startM = 9,  startD = 20, endM = 10, endD = 4,  icon = "Interface\\Icons\\INV_Drink_04" },
    { name = "Harvest Festival",        startM = 9,  startD = 1,  endM = 9,  endD = 8,  icon = "Interface\\Icons\\INV_Misc_Food_14" },
    { name = "Hallow's End",            startM = 10, startD = 18, endM = 11, endD = 1,  icon = "Interface\\Icons\\INV_Misc_Food_Pumpkin_01" },
    { name = "Feast of Winter Veil",    startM = 12, startD = 15, endM = 1,  endD = 2,  icon = "Interface\\Icons\\INV_Holiday_Christmas_Present_01" },
}

local DMF_LOCATIONS = {
    [0] = "Mulgore (Thunder Bluff)",
    [1] = "Elwynn Forest (Goldshire)",
    [2] = "Terokkar Forest (Shattrath)",
}

function CalendarModule:GetDMFInfo(year, month)
    local firstDayTime = time({year = year, month = month, day = 1, hour = 12})
    local wday = tonumber(date("%w", firstDayTime))
    local daysUntilFriday = (5 - wday) % 7
    local setupDay = 1 + daysUntilFriday
    local openDay = setupDay + 3
    local closeDay = openDay + 6

    local totalMonths = (year - 2007) * 12 + (month - 1)
    local locIndex = totalMonths % 3
    return {
        setupDay = setupDay,
        openDay = openDay,
        closeDay = closeDay,
        location = DMF_LOCATIONS[locIndex]
    }
end

function CalendarModule:GetDayStatus(year, month, day)
    local dmf = self:GetDMFInfo(year, month)
    local dmfStatus = nil
    if day >= dmf.setupDay and day < dmf.openDay then
        dmfStatus = L["Darkmoon Faire Setup"] .. " (" .. (L[dmf.location] or dmf.location) .. ")"
    elseif day >= dmf.openDay and day <= dmf.closeDay then
        dmfStatus = L["Darkmoon Faire Active"] .. " (" .. (L[dmf.location] or dmf.location) .. ")"
    end

    local holidayName, holidayIcon = nil, nil
    for _, hol in ipairs(HOLIDAYS) do
        if (hol.startM == month and day >= hol.startD and day <= (hol.startM == hol.endM and hol.endD or 31)) or
           (hol.endM == month and day <= hol.endD) then
            holidayName = L[hol.name] or hol.name
            holidayIcon = hol.icon
            break
        end
    end

    local t = time({year = year, month = month, day = day, hour = 12})
    local isReset = (tonumber(date("%w", t)) == 3)

    return dmfStatus, holidayName, holidayIcon, isReset
end

-- =====================================================================
-- 2. INSTANZ-LOCKS & RESETS
-- =====================================================================
function CalendarModule:GetSavedInstancesForDate(dateKey)
    if not GetNumSavedInstances then return {} end
    local num = GetNumSavedInstances()
    if num == 0 then return {} end

    local resetsToday = {}
    local now = time()

    for idx = 1, num do
        local name, _, resetTime, _, locked, _, _, isRaid, _, diffName, numEncounters, progress = GetSavedInstanceInfo(idx)
        if locked and resetTime and resetTime > 0 then
            local expDateKey = date("%Y-%m-%d", now + resetTime)
            if expDateKey == dateKey then
                table.insert(resetsToday, {
                    name = name,
                    isRaid = isRaid,
                    diff = diffName,
                    progress = (numEncounters and numEncounters > 0 and progress) and (progress .. "/" .. numEncounters) or nil,
                    resetClock = date("%H:%M", now + resetTime)
                })
            end
        end
    end
    return resetsToday
end

-- =====================================================================
-- 3. DATENBANK LOGIK & FORMATIERUNG
-- =====================================================================
local function GetDB()
    if not _G["ElvUI_AUIDB"] then _G["ElvUI_AUIDB"] = {} end
    local db = _G["ElvUI_AUIDB"]
    db.CalendarEvents = db.CalendarEvents or {}
    return db.CalendarEvents
end

function CalendarModule:GetEventsForDate(dateKey)
    local db = GetDB()
    return db[dateKey] or {}
end

local function DateStringToTimestamp(dateStr)
    local y, m, d = dateStr:match("(%d%d%d%d)-(%d%d)-(%d%d)")
    if y and m and d then
        return time({year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12})
    end
    return nil
end

local function FormatShortDate(dateStr)
    if not dateStr then return "" end
    local y, m, d = dateStr:match("(%d%d%d%d)-(%d%d)-(%d%d)")
    if d and m then
        return string.format("%02d.%02d", tonumber(d), tonumber(m))
    end
    return dateStr
end

local function GetEventDisplayTime(ev)
    if not ev then return "" end
    if ev.startDate and ev.endDate and ev.startDate ~= ev.endDate then
        return FormatShortDate(ev.startDate) .. " - " .. FormatShortDate(ev.endDate)
    end
    return (ev.time ~= "" and ev.time or L["All-Day"])
end

function CalendarModule:SaveEventData(startDateKey, endDateKey, titleStr, descStr, timeStr, color, isAllDay, editIndex, oldSeriesId)
    local db = GetDB()
    local sTimestamp = DateStringToTimestamp(startDateKey)
    local eTimestamp = (endDateKey and endDateKey ~= "") and DateStringToTimestamp(endDateKey) or sTimestamp

    if not sTimestamp then return end
    if not eTimestamp or eTimestamp < sTimestamp then eTimestamp = sTimestamp end

    if oldSeriesId then
        for dKey, events in pairs(db) do
            for idx = #events, 1, -1 do
                if events[idx].seriesId == oldSeriesId then
                    table.remove(events, idx)
                end
            end
            if #events == 0 then db[dKey] = nil end
        end
    end

    local seriesId = "series_" .. tostring(time()) .. "_" .. tostring(math.random(1000, 9999))
    local eventColor = {
        r = color and color.r or 0,
        g = color and color.g or 1,
        b = color and color.b or 0.8
    }

    local finalEndDate = (endDateKey and endDateKey ~= "") and endDateKey or startDateKey

    local payload = {
        title = titleStr or "",
        desc = descStr or "",
        time = isAllDay and L["All-Day"] or (timeStr or ""),
        isAllDay = isAllDay,
        color = eventColor,
        seriesId = seriesId,
        startDate = startDateKey,
        endDate = finalEndDate,
    }

    if editIndex and sTimestamp == eTimestamp and not oldSeriesId then
        db[startDateKey] = db[startDateKey] or {}
        db[startDateKey][editIndex] = payload
    else
        local cur = sTimestamp
        while cur <= eTimestamp do
            local dKey = date("%Y-%m-%d", cur)
            db[dKey] = db[dKey] or {}
            table.insert(db[dKey], {
                title = payload.title,
                desc = payload.desc,
                time = payload.time,
                isAllDay = payload.isAllDay,
                color = { r = eventColor.r, g = eventColor.g, b = eventColor.b },
                seriesId = seriesId,
                startDate = payload.startDate,
                endDate = payload.endDate,
            })
            cur = cur + 86400
        end
    end
    self:UpdateCalendar()
end

function CalendarModule:DeleteEvent(dateKey, index)
    local db = GetDB()
    if db[dateKey] and db[dateKey][index] then
        local ev = db[dateKey][index]
        local sId = ev.seriesId

        if sId then
            for dKey, events in pairs(db) do
                for i = #events, 1, -1 do
                    if events[i].seriesId == sId then
                        table.remove(events, i)
                    end
                end
                if #events == 0 then db[dKey] = nil end
            end
        else
            table.remove(db[dateKey], index)
            if #db[dateKey] == 0 then db[dateKey] = nil end
        end
        self:UpdateCalendar()
    end
end

-- =====================================================================
-- 4. TIME & DATE PICKER
-- =====================================================================
local TimePickerMenu = CreateFrame("Frame", "AUI_CalendarTimePicker", E.UIParent, "BackdropTemplate")

function CalendarModule:InitTimePicker()
    TimePickerMenu:SetSize(90, 160)
    TimePickerMenu:SetTemplate("Default")
    TimePickerMenu:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    TimePickerMenu:SetFrameStrata("TOOLTIP")
    TimePickerMenu:SetClampedToScreen(true)
    TimePickerMenu:EnableMouse(true)
    TimePickerMenu:Hide()

    local scroll = CreateFrame("ScrollFrame", "AUI_TimePickerScroll", TimePickerMenu, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -22, 4)

    if S and S.HandleScrollBar then
        local sb = _G["AUI_TimePickerScrollScrollBar"]
        if sb then S:HandleScrollBar(sb) end
    end

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(70, 48 * 20)
    scroll:SetScrollChild(content)

    local times = {}
    for h = 0, 23 do
        table.insert(times, string.format("%02d:00", h))
        table.insert(times, string.format("%02d:30", h))
    end

    for i, tStr in ipairs(times) do
        local b = CreateFrame("Button", nil, content)
        b:SetSize(68, 18)
        b:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * 19)

        b.text = b:CreateFontString(nil, "OVERLAY")
        b.text:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
        b.text:SetPoint("LEFT", 4, 0)
        b.text:SetText(tStr)

        b.highlight = b:CreateTexture(nil, "HIGHLIGHT")
        b.highlight:SetAllPoints()
        b.highlight:SetColorTexture(1, 1, 1, 0.15)

        b:SetScript("OnClick", function()
            if TimePickerMenu.targetButton then
                TimePickerMenu.targetButton.text:SetText(tStr)
            end
            TimePickerMenu:Hide()
        end)
    end
end

local function OpenTimePickerFor(anchorBtn)
    if not TimePickerMenu.targetButton and not TimePickerMenu:GetScript("OnShow") then
        CalendarModule:InitTimePicker()
    end

    if TimePickerMenu:IsShown() and TimePickerMenu.targetButton == anchorBtn then
        TimePickerMenu:Hide()
        return
    end

    TimePickerMenu.targetButton = anchorBtn
    TimePickerMenu:ClearAllPoints()
    TimePickerMenu:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)
    TimePickerMenu:Show()
end

local DatePicker = CreateFrame("Frame", "AUI_CalendarDatePicker", E.UIParent, "BackdropTemplate")

function CalendarModule:InitDatePicker()
    DatePicker:SetSize(220, 230)
    DatePicker:SetTemplate("Default")
    DatePicker:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    DatePicker:SetFrameStrata("TOOLTIP")
    DatePicker:SetClampedToScreen(true)
    DatePicker:EnableMouse(true)
    DatePicker:Hide()

    DatePicker.pYear = tonumber(date("%Y"))
    DatePicker.pMonth = tonumber(date("%m"))

    DatePicker.Title = DatePicker:CreateFontString(nil, "OVERLAY")
    DatePicker.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "SHADOWOUTLINE")
    DatePicker.Title:SetPoint("TOP", DatePicker, "TOP", 0, -10)

    local prev = CreateFrame("Button", nil, DatePicker, "BackdropTemplate")
    prev:SetSize(20, 18)
    prev:SetTemplate("Default")
    prev:SetPoint("TOPLEFT", DatePicker, "TOPLEFT", 8, -8)
    prev.t = prev:CreateFontString(nil, "OVERLAY")
    prev.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    prev.t:SetPoint("CENTER")
    prev.t:SetText("<")
    prev:SetScript("OnClick", function()
        DatePicker.pMonth = DatePicker.pMonth - 1
        if DatePicker.pMonth < 1 then DatePicker.pMonth = 12; DatePicker.pYear = DatePicker.pYear - 1 end
        DatePicker:Render()
    end)

    local nextB = CreateFrame("Button", nil, DatePicker, "BackdropTemplate")
    nextB:SetSize(20, 18)
    nextB:SetTemplate("Default")
    nextB:SetPoint("TOPRIGHT", DatePicker, "TOPRIGHT", -8, -8)
    nextB.t = nextB:CreateFontString(nil, "OVERLAY")
    nextB.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    nextB.t:SetPoint("CENTER")
    nextB.t:SetText(">")
    nextB:SetScript("OnClick", function()
        DatePicker.pMonth = DatePicker.pMonth + 1
        if DatePicker.pMonth > 12 then DatePicker.pMonth = 1; DatePicker.pYear = DatePicker.pYear + 1 end
        DatePicker:Render()
    end)

    local wLabels = (GetLocale() == "deDE") and {"M", "D", "M", "D", "F", "S", "S"} or {"M", "T", "W", "T", "F", "S", "S"}
    for i = 1, 7 do
        local l = DatePicker:CreateFontString(nil, "OVERLAY")
        l:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 10, "NONE")
        l:SetPoint("TOPLEFT", DatePicker, "TOPLEFT", 10 + (i - 1) * 29, -32)
        l:SetSize(26, 12)
        l:SetJustifyH("CENTER")
        l:SetText(wLabels[i])
        l:SetTextColor(1, 0.82, 0)
    end

    DatePicker.Cells = {}
    for i = 1, 42 do
        local btn = CreateFrame("Button", nil, DatePicker)
        btn:SetSize(26, 22)
        local col = (i - 1) % 7
        local row = math.floor((i - 1) / 7)
        btn:SetPoint("TOPLEFT", DatePicker, "TOPLEFT", 10 + col * 29, -48 - row * 24)

        btn.highlightBox = btn:CreateTexture(nil, "BACKGROUND")
        btn.highlightBox:SetAllPoints()
        btn.highlightBox:Hide()

        btn.t = btn:CreateFontString(nil, "OVERLAY")
        btn.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
        btn.t:SetPoint("CENTER")

        btn:SetScript("OnClick", function(self)
            if not self.dayNum then return end
            local key = string.format("%04d-%02d-%02d", DatePicker.pYear, DatePicker.pMonth, self.dayNum)
            if DatePicker.TargetEditBox then
                DatePicker.TargetEditBox:SetText(key)
            end
            DatePicker:Hide()
        end)
        DatePicker.Cells[i] = btn
    end

    function DatePicker:Render()
        self.Title:SetText(string.format("%s %04d", date("%B", time({year = self.pYear, month = self.pMonth, day = 1})), self.pYear))
        local fDay = time({year = self.pYear, month = self.pMonth, day = 1, hour = 12})
        local startW = (tonumber(date("%w", fDay)) + 6) % 7
        local dInMonth = tonumber(date("%d", time({year = self.pYear, month = self.pMonth + 1, day = 0})))

        local realTodayStr = date("%Y-%m-%d")
        local selectedDateStr = self.TargetEditBox and self.TargetEditBox:GetText() or ""

        for i = 1, 42 do
            local c = self.Cells[i]
            local dNum = i - startW
            if dNum > 0 and dNum <= dInMonth then
                c.dayNum = dNum
                c.t:SetText(dNum)
                c.highlightBox:Hide()

                local thisDateStr = string.format("%04d-%02d-%02d", self.pYear, self.pMonth, dNum)

                if thisDateStr == selectedDateStr then
                    c.highlightBox:SetColorTexture(0, 1, 0.8, 0.35)
                    c.highlightBox:Show()
                    c.t:SetTextColor(0, 1, 0.8)
                elseif thisDateStr == realTodayStr then
                    c.highlightBox:SetColorTexture(1, 0.82, 0, 0.25)
                    c.highlightBox:Show()
                    c.t:SetTextColor(1, 0.82, 0)
                else
                    c.t:SetTextColor(1, 1, 1)
                end
                c:Show()
            else
                c.dayNum = nil
                c.t:SetText("")
                c.highlightBox:Hide()
                c:Hide()
            end
        end
    end
end

local function OpenDatePickerFor(targetEditBox, anchorFrame)
    if not DatePicker.Title then CalendarModule:InitDatePicker() end

    if DatePicker:IsShown() and DatePicker.currentAnchor == anchorFrame then
        DatePicker:Hide()
        DatePicker.currentAnchor = nil
        return
    end

    DatePicker.currentAnchor = anchorFrame
    DatePicker.TargetEditBox = targetEditBox
    local text = targetEditBox:GetText() or ""
    local y, m = text:match("(%d%d%d%d)-(%d%d)")
    if y and m then
        DatePicker.pYear = tonumber(y)
        DatePicker.pMonth = tonumber(m)
    else
        DatePicker.pYear = tonumber(date("%Y"))
        DatePicker.pMonth = tonumber(date("%m"))
    end
    DatePicker:ClearAllPoints()
    DatePicker:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -4)
    DatePicker:Render()
    DatePicker:Show()
end

-- =====================================================================
-- 5. HAUPTKALENDER GRID UI (FEST DEFINIERTE TITELBREITE & PFEILE)
-- =====================================================================
local currentYear = tonumber(date("%Y"))
local currentMonth = tonumber(date("%m"))
local dayButtons = {}

function CalendarModule:InitUI()
    local UI = CalendarModule
    UI:SetSize(940, 830)
    UI:SetPoint("CENTER", E.UIParent, "CENTER", 0, 0)
    UI:SetTemplate("Transparent")
    UI:SetMovable(true)
    UI:EnableMouse(true)
    UI:RegisterForDrag("LeftButton")
    UI:SetScript("OnDragStart", UI.StartMoving)
    UI:SetScript("OnDragStop", UI.StopMovingOrSizing)
    UI:SetFrameStrata("HIGH")
    UI:Hide()

    tinsert(UISpecialFrames, "AUI_CalendarFrame")

    -- 1. Textfeld für Monat/Jahr mit fester Breite und zentrierter Ausrichtung
    UI.Title = UI:CreateFontString(nil, "OVERLAY")
    UI.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 20, "SHADOWOUTLINE")
    UI.Title:SetPoint("TOP", UI, "TOP", 0, -14)
    UI.Title:SetWidth(250)
    UI.Title:SetJustifyH("CENTER")

    -- 2. Linker Pfeil fest an der linken Kante des Title-Blocks
    local prevBtn = CreateFrame("Button", nil, UI, "BackdropTemplate")
    prevBtn:SetSize(24, 24)
    prevBtn:SetTemplate("Default")
    prevBtn:SetPoint("RIGHT", UI.Title, "LEFT", -6, 0)
    prevBtn.text = prevBtn:CreateFontString(nil, "OVERLAY")
    prevBtn.text:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
    prevBtn.text:SetPoint("CENTER")
    prevBtn.text:SetText("<")
    prevBtn:SetScript("OnClick", function()
        currentMonth = currentMonth - 1
        if currentMonth < 1 then currentMonth = 12; currentYear = currentYear - 1 end
        CalendarModule:UpdateCalendar()
    end)

    -- 3. Rechter Pfeil fest an der rechten Kante des Title-Blocks
    local nextBtn = CreateFrame("Button", nil, UI, "BackdropTemplate")
    nextBtn:SetSize(24, 24)
    nextBtn:SetTemplate("Default")
    nextBtn:SetPoint("LEFT", UI.Title, "RIGHT", 6, 0)
    nextBtn.text = nextBtn:CreateFontString(nil, "OVERLAY")
    nextBtn.text:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
    nextBtn.text:SetPoint("CENTER")
    nextBtn.text:SetText(">")
    nextBtn:SetScript("OnClick", function()
        currentMonth = currentMonth + 1
        if currentMonth > 12 then currentMonth = 1; currentYear = currentYear + 1 end
        CalendarModule:UpdateCalendar()
    end)

    UI.CloseButton = CreateFrame("Button", nil, UI, "UIPanelCloseButton")
    UI.CloseButton:SetPoint("TOPRIGHT", UI, "TOPRIGHT", -4, -4)
    E:GetModule("Skins"):HandleCloseButton(UI.CloseButton)

    local weekDays = (GetLocale() == "deDE") and { "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag" } or { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" }
    for i = 1, 7 do
        local wd = UI:CreateFontString(nil, "OVERLAY")
        wd:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 13, "NONE")
        wd:SetPoint("TOPLEFT", UI, "TOPLEFT", 22 + (i - 1) * 128, -46)
        wd:SetSize(126, 18)
        wd:SetJustifyH("CENTER")
        wd:SetText(weekDays[i])
        wd:SetTextColor(1, 0.82, 0)
    end

    for i = 1, 35 do
        local btn = CreateFrame("Button", nil, UI, "BackdropTemplate")
        btn:SetSize(126, 148)
        btn:SetTemplate("Default")

        local col = (i - 1) % 7
        local row = math.floor((i - 1) / 7)
        btn:SetPoint("TOPLEFT", UI, "TOPLEFT", 22 + col * 128, -68 - row * 150)

        btn.DayText = btn:CreateFontString(nil, "OVERLAY")
        btn.DayText:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
        btn.DayText:SetPoint("TOPLEFT", btn, "TOPLEFT", 6, -6)

        btn.EventIcon = btn:CreateTexture(nil, "ARTWORK")
        btn.EventIcon:SetSize(22, 22)
        btn.EventIcon:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -6, -6)

        btn.EventBars = {}
        for bIdx = 1, 3 do
            local bar = CreateFrame("Frame", nil, btn, "BackdropTemplate")
            bar:SetSize(114, 25)
            bar:SetPoint("TOPLEFT", btn, "TOPLEFT", 6, -34 - (bIdx - 1) * 28)
            bar:SetTemplate("Default")
            bar:SetBackdropColor(0.08, 0.08, 0.08, 0.95)

            bar.t = bar:CreateFontString(nil, "OVERLAY")
            bar.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
            bar.t:SetPoint("LEFT", bar, "LEFT", 5, 0)
            bar.t:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
            bar.t:SetJustifyH("LEFT")
            bar.t:SetTextColor(1, 1, 1)
            bar:Hide()

            btn.EventBars[bIdx] = bar
        end

        btn:SetScript("OnEnter", function(self)
            if self.dateKey then 
                CalendarModule:ShowDayTooltip(self)
                self:SetBackdropColor(0.24, 0.24, 0.24, 0.95)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self.dateKey then
                if CalendarModule.selectedDateKey and CalendarModule.selectedDateKey == self.dateKey then
                    self:SetBackdropColor(0.12, 0.16, 0.18, 0.98)
                else
                    self:SetBackdropColor(unpack(E.media.backdropcolor))
                end
            end
        end)

        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn:SetScript("OnClick", function(self)
            if self.dateKey then
                CalendarModule:OpenDayDetailManager(self.dateKey)
            end
        end)

        dayButtons[i] = btn
    end

    CalendarModule:BuildDetailManagerUI()
    CalendarModule:BuildEditDialog()
end

-- =====================================================================
-- 6. UPDATE LOGIK (35 TAGE)
-- =====================================================================
function CalendarModule:UpdateCalendar()
    local UI = CalendarModule
    UI.Title:SetText(string.format("%s %04d", date("%B", time({year = currentYear, month = currentMonth, day = 1})), currentYear))

    local firstDayTimestamp = time({year = currentYear, month = currentMonth, day = 1, hour = 12})
    local startWeekday = (tonumber(date("%w", firstDayTimestamp)) + 6) % 7
    local daysInMonth = tonumber(date("%d", time({year = currentYear, month = currentMonth + 1, day = 0})))
    local daysInPrevMonth = tonumber(date("%d", time({year = currentYear, month = currentMonth, day = 0})))

    local todayStr = date("%Y-%m-%d")

    if RequestRaidInfo then RequestRaidInfo() end

    for i = 1, 35 do
        local btn = dayButtons[i]
        local dayNumber = i - startWeekday
        local isAdjacentMonth = false
        local actualYear, actualMonth, actualDay

        if dayNumber <= 0 then
            isAdjacentMonth = true
            actualDay = daysInPrevMonth + dayNumber
            actualMonth = currentMonth - 1
            actualYear = currentYear
            if actualMonth < 1 then actualMonth = 12; actualYear = actualYear - 1 end
        elseif dayNumber > daysInMonth then
            isAdjacentMonth = true
            actualDay = dayNumber - daysInMonth
            actualMonth = currentMonth + 1
            actualYear = currentYear
            if actualMonth > 12 then actualMonth = 1; actualYear = actualYear + 1 end
        else
            isAdjacentMonth = false
            actualDay = dayNumber
            actualMonth = currentMonth
            actualYear = currentYear
        end

        local dateKey = string.format("%04d-%02d-%02d", actualYear, actualMonth, actualDay)
        btn.dateKey = dateKey
        btn.DayText:SetText(actualDay)
        btn.isAdjacent = isAdjacentMonth

        local dmfStatus, holName, holIcon, isReset = self:GetDayStatus(actualYear, actualMonth, actualDay)
        btn.dmfStatus = dmfStatus
        btn.holiday = holName
        btn.isReset = isReset

        btn.EventIcon:Hide()
        if holIcon then
            btn.EventIcon:SetTexture(holIcon)
            btn.EventIcon:Show()
        elseif dmfStatus then
            btn.EventIcon:SetTexture("Interface\\Icons\\INV_Misc_Ticket_Tarot_TwistingNether_01")
            btn.EventIcon:Show()
        end

        if self.selectedDateKey and self.selectedDateKey == dateKey then
            btn:SetBackdropBorderColor(0, 1, 0.8, 1)
            btn:SetBackdropColor(0.12, 0.16, 0.18, 0.98)
        elseif dateKey == todayStr then
            btn:SetBackdropBorderColor(1, 0.82, 0, 1)
            btn:SetBackdropColor(unpack(E.media.backdropcolor))
        else
            btn:SetBackdropBorderColor(unpack(E.media.bordercolor))
            btn:SetBackdropColor(unpack(E.media.backdropcolor))
        end

        local userEvents = self:GetEventsForDate(dateKey)
        local savedInstances = self:GetSavedInstancesForDate(dateKey)

        local combinedEntries = {}
        for _, inst in ipairs(savedInstances) do
            local shortName = inst.name:gsub("Karazhan", "Kara"):gsub("Magtheridon", "Mag"):gsub("Gruul's Lair", "Gruul")
            table.insert(combinedEntries, {
                title = (inst.isRaid and "[Raid] " or "[HC] ") .. shortName,
                color = { r = 1, g = 0.5, b = 0 },
                isLock = true
            })
        end
        for _, ev in ipairs(userEvents) do
            table.insert(combinedEntries, ev)
        end

        for bIdx = 1, 3 do
            local bar = btn.EventBars[bIdx]
            local ev = combinedEntries[bIdx]
            if ev then
                local c = ev.color or { r = 0, g = 1, b = 0.8 }
                bar:SetBackdropBorderColor(c.r, c.g, c.b, 1)
                local label = (ev.title and ev.title ~= "") and ev.title or ev.desc
                bar.t:SetText(label)
                bar.t:SetTextColor(ev.isLock and 1 or 1, ev.isLock and 0.85 or 1, ev.isLock and 0.4 or 1)
                bar:Show()
            else
                bar:Hide()
            end
        end

        if isAdjacentMonth then
            btn:SetAlpha(0.35)
            btn.DayText:SetTextColor(0.5, 0.5, 0.5)
        else
            btn:SetAlpha(1)
            btn.DayText:SetTextColor(1, 1, 1)
        end

        btn:Show()
    end
end

-- =====================================================================
-- 7. TOOLTIP
-- =====================================================================
function CalendarModule:ShowDayTooltip(btn)
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(btn.dateKey, 1, 0.82, 0)

    if btn.isReset then
        GameTooltip:AddDoubleLine(L["Weekly Reset"], "09:00", 0.4, 1, 0.4, 1, 1, 1)
    end
    if btn.dmfStatus then
        GameTooltip:AddLine(btn.dmfStatus, 1, 0.5, 1)
    end
    if btn.holiday then
        GameTooltip:AddLine(btn.holiday, 1, 0.82, 0)
    end

    local locks = self:GetSavedInstancesForDate(btn.dateKey)
    if #locks > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Instance Lockout Resets:"] or "Instanz-Resets:", 1, 0.5, 0)
        for _, inst in ipairs(locks) do
            local left = "|TInterface\\Icons\\INV_Misc_Key_03:14:14|t " .. inst.name .. (inst.progress and (" (" .. inst.progress .. ")") or "")
            GameTooltip:AddDoubleLine(left, inst.resetClock, 1, 1, 1, 1, 0.82, 0)
        end
    end

    local events = self:GetEventsForDate(btn.dateKey)
    if #events > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Custom Event"], 0, 1, 0.8)
        for _, ev in ipairs(events) do
            local r, g, b = (ev.color and ev.color.r or 1), (ev.color and ev.color.g or 1), (ev.color and ev.color.b or 1)
            local displayTitle = (ev.title and ev.title ~= "") and ev.title or ev.desc
            local timeText = GetEventDisplayTime(ev)
            GameTooltip:AddDoubleLine(timeText, displayTitle, r, g, b, 1, 1, 1)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Left-Click: Open Event Dialog"], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

-- =====================================================================
-- 8. TAGES-MANAGER
-- =====================================================================
local detailRows = {}

function CalendarModule:BuildDetailManagerUI()
    local dm = CreateFrame("Frame", "AUI_CalendarDayManager", CalendarModule, "BackdropTemplate")
    dm:SetSize(420, 390)
    dm:SetPoint("CENTER", CalendarModule, "CENTER", -190, 0)
    dm:SetTemplate("Default")
    dm:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    dm:SetFrameStrata("DIALOG")
    dm:EnableMouse(true)
    dm:Hide()

    dm.Title = dm:CreateFontString(nil, "OVERLAY")
    dm.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 16, "SHADOWOUTLINE")
    dm.Title:SetPoint("TOP", dm, "TOP", 0, -12)

    local function CloseDayManagerAndClearSelection()
        CalendarModule.selectedDateKey = nil
        dm:Hide()
        if CalendarModule.EditDialog then CalendarModule.EditDialog:Hide() end
        if DatePicker:IsShown() then DatePicker:Hide() end
        if TimePickerMenu:IsShown() then TimePickerMenu:Hide() end
        if ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
        CalendarModule:UpdateCalendar()
    end

    dm.Close = CreateFrame("Button", nil, dm, "UIPanelCloseButton")
    dm.Close:SetPoint("TOPRIGHT", dm, "TOPRIGHT", -4, -4)
    E:GetModule("Skins"):HandleCloseButton(dm.Close)
    dm.Close:SetScript("OnClick", CloseDayManagerAndClearSelection)

    local addBtn = CreateFrame("Button", nil, dm, "BackdropTemplate")
    addBtn:SetSize(140, 24)
    addBtn:SetTemplate("Default")
    addBtn:SetPoint("BOTTOMLEFT", dm, "BOTTOMLEFT", 20, 16)
    addBtn.t = addBtn:CreateFontString(nil, "OVERLAY")
    addBtn.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    addBtn.t:SetPoint("CENTER")
    addBtn.t:SetText(L["Add Event"])
    addBtn:SetScript("OnClick", function()
        CalendarModule:OpenEditDialog(dm.currentDateKey, nil)
    end)

    local closeBtn = CreateFrame("Button", nil, dm, "BackdropTemplate")
    closeBtn:SetSize(100, 24)
    closeBtn:SetTemplate("Default")
    closeBtn:SetPoint("BOTTOMRIGHT", dm, "BOTTOMRIGHT", -20, 16)
    closeBtn.t = closeBtn:CreateFontString(nil, "OVERLAY")
    closeBtn.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    closeBtn.t:SetPoint("CENTER")
    closeBtn.t:SetText(L["Cancel"])
    closeBtn:SetScript("OnClick", CloseDayManagerAndClearSelection)

    for i = 1, 7 do
        local row = CreateFrame("Button", nil, dm, "BackdropTemplate")
        row:SetSize(380, 34)
        row:SetPoint("TOPLEFT", dm, "TOPLEFT", 20, -42 - (i - 1) * 38)
        row:SetTemplate("Default")
        row:EnableMouse(true)

        row:SetScript("OnClick", function(self)
            if self.eventIndex then
                CalendarModule:OpenEditDialog(dm.currentDateKey, self.eventIndex)
            end
        end)

        row.ColorBar = row:CreateTexture(nil, "ARTWORK")
        row.ColorBar:SetSize(4, 30)
        row.ColorBar:SetPoint("LEFT", row, "LEFT", 2, 0)

        row.Time = row:CreateFontString(nil, "OVERLAY")
        row.Time:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
        row.Time:SetPoint("LEFT", row.ColorBar, "RIGHT", 6, 0)
        row.Time:SetTextColor(1, 0.82, 0)

        row.Title = row:CreateFontString(nil, "OVERLAY")
        row.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
        row.Title:SetPoint("LEFT", row.Time, "RIGHT", 8, 0)
        row.Title:SetPoint("RIGHT", row, "RIGHT", -75, 0)
        row.Title:SetJustifyH("LEFT")

        local delBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        delBtn:SetSize(24, 20)
        delBtn:SetTemplate("Default")
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        delBtn.t = delBtn:CreateFontString(nil, "OVERLAY")
        delBtn.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 10, "NONE")
        delBtn.t:SetPoint("CENTER")
        delBtn.t:SetText("X")
        delBtn.t:SetTextColor(1, 0.2, 0.2)
        delBtn:SetScript("OnClick", function()
            CalendarModule:DeleteEvent(dm.currentDateKey, row.eventIndex)
            CalendarModule:OpenDayDetailManager(dm.currentDateKey)
        end)

        local editBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        editBtn:SetSize(38, 20)
        editBtn:SetTemplate("Default")
        editBtn:SetPoint("RIGHT", delBtn, "LEFT", -4, 0)
        editBtn.t = editBtn:CreateFontString(nil, "OVERLAY")
        editBtn.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 10, "NONE")
        editBtn.t:SetPoint("CENTER")
        editBtn.t:SetText(L["Edit"])
        editBtn:SetScript("OnClick", function()
            CalendarModule:OpenEditDialog(dm.currentDateKey, row.eventIndex)
        end)

        detailRows[i] = row
    end

    CalendarModule.DayManager = dm
end

function CalendarModule:OpenDayDetailManager(dateKey)
    local dm = self.DayManager
    self.selectedDateKey = dateKey
    self:UpdateCalendar()

    dm.currentDateKey = dateKey
    dm.Title:SetText(dateKey)

    local events = self:GetEventsForDate(dateKey)
    for i = 1, 7 do
        local row = detailRows[i]
        local ev = events[i]
        if ev then
            row.eventIndex = i
            row.Time:SetText(GetEventDisplayTime(ev))
            row.Title:SetText((ev.title and ev.title ~= "") and ev.title or ev.desc)
            local c = ev.color or { r = 0, g = 1, b = 0.8 }
            row.ColorBar:SetColorTexture(c.r, c.g, c.b, 1)
            row:Show()
        else
            row.eventIndex = nil
            row:Hide()
        end
    end
    dm:Show()
    if AUI.UpdateCalendarBorders then AUI:UpdateCalendarBorders() end
end

-- =====================================================================
-- 9. EVENT EDIT-DIALOG
-- =====================================================================
local function CreateDatePickerButton(parent, targetEditBox)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(22, 22)
    btn:SetTemplate("Default")

    btn.t = btn:CreateFontString(nil, "OVERLAY")
    btn.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    btn.t:SetPoint("CENTER")
    btn.t:SetText("[#]")
    btn.t:SetTextColor(1, 0.82, 0)

    btn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 0.82, 0) end)
    btn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(E.media.bordercolor)) end)
    btn:SetScript("OnClick", function(self) OpenDatePickerFor(targetEditBox, self) end)

    return btn
end

local function GetCurrentPickerRGB()
    if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.GetColorRGB then
        local r, g, b = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
        if r then return r, g, b end
    end
    if ColorPickerFrame.Wheel and ColorPickerFrame.Wheel.GetColorRGB then
        local r, g, b = ColorPickerFrame.Wheel:GetColorRGB()
        if r then return r, g, b end
    end
    if ColorPickerFrame.GetColorRGB then
        local r, g, b = ColorPickerFrame:GetColorRGB()
        if r then return r, g, b end
    end
    return nil
end

function CalendarModule:BuildEditDialog()
    local ed = CreateFrame("Frame", "AUI_CalendarEditDialog", CalendarModule, "BackdropTemplate")
    ed:SetSize(400, 400)
    ed:SetPoint("TOPLEFT", CalendarModule.DayManager, "TOPRIGHT", 6, 0)
    ed:SetTemplate("Default")
    ed:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    ed:SetFrameStrata("DIALOG")
    ed:EnableMouse(true)
    ed:Hide()

    ed.Title = ed:CreateFontString(nil, "OVERLAY")
    ed.Title:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 14, "NONE")
    ed.Title:SetPoint("TOP", ed, "TOP", 0, -12)

    ed.Close = CreateFrame("Button", nil, ed, "UIPanelCloseButton")
    ed.Close:SetPoint("TOPRIGHT", ed, "TOPRIGHT", -4, -4)
    E:GetModule("Skins"):HandleCloseButton(ed.Close)
    ed.Close:SetScript("OnClick", function()
        ed:Hide()
        if DatePicker:IsShown() then DatePicker:Hide() end
        if TimePickerMenu:IsShown() then TimePickerMenu:Hide() end
        if ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
    end)

    local titleLbl = ed:CreateFontString(nil, "OVERLAY")
    titleLbl:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    titleLbl:SetPoint("TOPLEFT", ed, "TOPLEFT", 18, -36)
    titleLbl:SetText(L["Event Title:"])

    local titleBox = CreateFrame("EditBox", nil, ed, "BackdropTemplate")
    titleBox:SetSize(270, 22)
    titleBox:SetPoint("TOPLEFT", titleLbl, "BOTTOMLEFT", 0, -4)
    titleBox:SetTemplate("Default")
    titleBox:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    titleBox:SetTextInsets(6, 6, 0, 0)
    titleBox:SetAutoFocus(false)
    titleBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ed.TitleBox = titleBox

    local cLbl = ed:CreateFontString(nil, "OVERLAY")
    cLbl:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    cLbl:SetPoint("LEFT", titleLbl, "LEFT", 300, 0)
    cLbl:SetText(L["Event Color:"])

    ed.chosenColor = { r = 0, g = 1, b = 0.8 }

    local swatch = CreateFrame("Button", nil, ed, "BackdropTemplate")
    swatch:SetSize(22, 22)
    swatch:SetTemplate("Default")
    swatch:SetPoint("TOPLEFT", cLbl, "BOTTOMLEFT", 0, -4)
    swatch.tex = swatch:CreateTexture(nil, "OVERLAY")
    swatch.tex:SetInside(swatch, 2, 2)
    swatch.tex:SetColorTexture(ed.chosenColor.r, ed.chosenColor.g, ed.chosenColor.b, 1)

    local function ColorWheelCallback()
        local r, g, b = GetCurrentPickerRGB()
        if r and g and b then
            ed.chosenColor.r = r
            ed.chosenColor.g = g
            ed.chosenColor.b = b
            swatch.tex:SetColorTexture(r, g, b, 1)
        end
    end

    swatch:SetScript("OnClick", function()
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.func = ColorWheelCallback
        ColorPickerFrame.opacityFunc = nil
        ColorPickerFrame.cancelFunc = function(restore)
            if restore and type(restore) == "table" and restore.r then
                ed.chosenColor.r = restore.r
                ed.chosenColor.g = restore.g
                ed.chosenColor.b = restore.b
            else
                ColorWheelCallback()
            end
            swatch.tex:SetColorTexture(ed.chosenColor.r, ed.chosenColor.g, ed.chosenColor.b, 1)
        end

        ColorPickerFrame.previousValues = { r = ed.chosenColor.r, g = ed.chosenColor.g, b = ed.chosenColor.b }
        ColorPickerFrame:Hide()
        ColorPickerFrame:SetColorRGB(ed.chosenColor.r, ed.chosenColor.g, ed.chosenColor.b)
        ColorPickerFrame:Show()
    end)
    ed.Swatch = swatch

    ed:SetScript("OnUpdate", function(self, elapsed)
        if ColorPickerFrame:IsShown() and ColorPickerFrame.func == ColorWheelCallback then
            local r, g, b = GetCurrentPickerRGB()
            if r and g and b then
                if r ~= ed.chosenColor.r or g ~= ed.chosenColor.g or b ~= ed.chosenColor.b then
                    ed.chosenColor.r = r
                    ed.chosenColor.g = g
                    ed.chosenColor.b = b
                    swatch.tex:SetColorTexture(r, g, b, 1)
                end
            end
        end
    end)

    local allDayCheck = CreateFrame("CheckButton", "AUI_CalAllDayCheck", ed, "ChatConfigCheckButtonTemplate")
    allDayCheck:SetPoint("TOPLEFT", titleBox, "BOTTOMLEFT", -2, -6)
    allDayCheck.text = _G[allDayCheck:GetName().."Text"]
    allDayCheck.text:SetText(L["All-Day"])
    allDayCheck.text:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    E:GetModule("Skins"):HandleCheckBox(allDayCheck)
    ed.AllDayCheck = allDayCheck

    local sLbl = ed:CreateFontString(nil, "OVERLAY")
    sLbl:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    sLbl:SetPoint("TOPLEFT", allDayCheck, "BOTTOMLEFT", 2, -6)
    sLbl:SetText(L["Start Date"] .. ":")

    local sBox = CreateFrame("EditBox", nil, ed, "BackdropTemplate")
    sBox:SetSize(100, 22)
    sBox:SetPoint("TOPLEFT", sLbl, "BOTTOMLEFT", 0, -4)
    sBox:SetTemplate("Default")
    sBox:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    sBox:SetTextInsets(6, 6, 0, 0)
    sBox:SetAutoFocus(false)
    sBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ed.StartBox = sBox

    local sPickBtn = CreateDatePickerButton(ed, sBox)
    sPickBtn:SetPoint("LEFT", sBox, "RIGHT", 4, 0)

    local eLbl = ed:CreateFontString(nil, "OVERLAY")
    eLbl:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    eLbl:SetPoint("LEFT", sLbl, "LEFT", 195, 0)
    eLbl:SetText(L["End Date"] .. ":")
    ed.EndLabel = eLbl

    local eBox = CreateFrame("EditBox", nil, ed, "BackdropTemplate")
    eBox:SetSize(100, 22)
    eBox:SetPoint("TOPLEFT", eLbl, "BOTTOMLEFT", 0, -4)
    eBox:SetTemplate("Default")
    eBox:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    eBox:SetTextInsets(6, 6, 0, 0)
    eBox:SetAutoFocus(false)
    eBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ed.EndBox = eBox

    local ePickBtn = CreateDatePickerButton(ed, eBox)
    ePickBtn:SetPoint("LEFT", eBox, "RIGHT", 4, 0)
    ed.EndPickBtn = ePickBtn

    local stLbl = ed:CreateFontString(nil, "OVERLAY")
    stLbl:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    stLbl:SetPoint("TOPLEFT", sBox, "BOTTOMLEFT", 0, -8)
    stLbl:SetText(L["Start Time"] .. ":")
    ed.StartTimeLabel = stLbl

    local stBtn = CreateFrame("Button", nil, ed, "BackdropTemplate")
    stBtn:SetSize(80, 22)
    stBtn:SetTemplate("Default")
    stBtn:SetPoint("TOPLEFT", stLbl, "BOTTOMLEFT", 0, -4)
    stBtn.text = stBtn:CreateFontString(nil, "OVERLAY")
    stBtn.text:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    stBtn.text:SetPoint("CENTER")
    stBtn.text:SetText("19:00")
    stBtn:SetScript("OnClick", function(self) OpenTimePickerFor(self) end)
    ed.StartTimeBtn = stBtn

    local etLbl = ed:CreateFontString(nil, "OVERLAY")
    etLbl:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    etLbl:SetPoint("LEFT", stLbl, "LEFT", 195, 0)
    etLbl:SetText(L["End Time"] .. ":")
    ed.EndTimeLabel = etLbl

    local etBtn = CreateFrame("Button", nil, ed, "BackdropTemplate")
    etBtn:SetSize(80, 22)
    etBtn:SetTemplate("Default")
    etBtn:SetPoint("TOPLEFT", etLbl, "BOTTOMLEFT", 0, -4)
    etBtn.text = etBtn:CreateFontString(nil, "OVERLAY")
    etBtn.text:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    etBtn.text:SetPoint("CENTER")
    etBtn.text:SetText("23:00")
    etBtn:SetScript("OnClick", function(self) OpenTimePickerFor(self) end)
    ed.EndTimeBtn = etBtn

    allDayCheck:SetScript("OnClick", function(self)
        local isAllDay = self:GetChecked()
        if isAllDay then
            ed.StartTimeLabel:Hide()
            ed.StartTimeBtn:Hide()
            ed.EndTimeLabel:Hide()
            ed.EndTimeBtn:Hide()
            ed.EndLabel:Show()
            ed.EndBox:Show()
            ed.EndPickBtn:Show()
        else
            ed.StartTimeLabel:Show()
            ed.StartTimeBtn:Show()
            ed.EndTimeLabel:Show()
            ed.EndTimeBtn:Show()
            ed.EndLabel:Hide()
            ed.EndBox:Hide()
            ed.EndPickBtn:Hide()
            ed.EndBox:SetText(ed.StartBox:GetText())
        end
    end)

    local dLbl = ed:CreateFontString(nil, "OVERLAY")
    dLbl:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 11, "NONE")
    dLbl:SetPoint("TOPLEFT", stBtn, "BOTTOMLEFT", 0, -8)
    dLbl:SetText(L["Event Description:"])

    local scrollContainer = CreateFrame("ScrollFrame", "AUI_CalendarScrollFrame", ed, "UIPanelScrollFrameTemplate")
    scrollContainer:SetSize(360, 95)
    scrollContainer:SetPoint("TOPLEFT", dLbl, "BOTTOMLEFT", 0, -4)
    scrollContainer:SetTemplate("Default")

    local sb = _G["AUI_CalendarScrollFrameScrollBar"]
    if sb and S and S.HandleScrollBar then
        S:HandleScrollBar(sb)
        sb:ClearAllPoints()
        sb:SetPoint("TOPLEFT", scrollContainer, "TOPRIGHT", -14, -18)
        sb:SetPoint("BOTTOMRIGHT", scrollContainer, "BOTTOMRIGHT", -6, 18)
    end

    local descBox = CreateFrame("EditBox", nil, scrollContainer)
    descBox:SetMultiLine(true)
    descBox:SetSize(340, 95)
    descBox:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    descBox:SetAutoFocus(false)
    descBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollContainer:SetScrollChild(descBox)
    ed.DescBox = descBox

    local sBtn = CreateFrame("Button", nil, ed, "BackdropTemplate")
    sBtn:SetSize(90, 24)
    sBtn:SetTemplate("Default")
    sBtn:SetPoint("BOTTOMLEFT", ed, "BOTTOMLEFT", 18, 16)
    sBtn.t = sBtn:CreateFontString(nil, "OVERLAY")
    sBtn.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    sBtn.t:SetPoint("CENTER")
    sBtn.t:SetText(L["Save"])
    sBtn:SetScript("OnClick", function()
        local tTitle = titleBox:GetText() or ""
        local tDesc = descBox:GetText() or ""
        local sDate = sBox:GetText() or ""
        local isAllDay = allDayCheck:GetChecked()
        local eDate = isAllDay and (eBox:GetText() or sDate) or sDate

        local timeStr = ""
        if not isAllDay then
            local startT = stBtn.text:GetText() or "19:00"
            local endT = etBtn.text:GetText() or "23:00"
            timeStr = startT .. " - " .. endT
        end

        if ColorPickerFrame:IsShown() then
            local r, g, b = GetCurrentPickerRGB()
            if r and g and b then
                ed.chosenColor.r, ed.chosenColor.g, ed.chosenColor.b = r, g, b
            end
            ColorPickerFrame:Hide()
        end

        if (tTitle ~= "" or tDesc ~= "") and sDate ~= "" then
            local isolatedColor = { r = ed.chosenColor.r, g = ed.chosenColor.g, b = ed.chosenColor.b }
            CalendarModule:SaveEventData(sDate, eDate, tTitle, tDesc, timeStr, isolatedColor, isAllDay, ed.editIndex, ed.oldSeriesId)
            ed:Hide()
            if DatePicker:IsShown() then DatePicker:Hide() end
            if TimePickerMenu:IsShown() then TimePickerMenu:Hide() end
            CalendarModule:OpenDayDetailManager(sDate)
        end
    end)

    local cBtn = CreateFrame("Button", nil, ed, "BackdropTemplate")
    cBtn:SetSize(90, 24)
    cBtn:SetTemplate("Default")
    cBtn:SetPoint("BOTTOMRIGHT", ed, "BOTTOMRIGHT", -18, 16)
    cBtn.t = cBtn:CreateFontString(nil, "OVERLAY")
    cBtn.t:FontTemplate(E.Libs.LSM:Fetch("font", "Expressway"), 12, "NONE")
    cBtn.t:SetPoint("CENTER")
    cBtn.t:SetText(L["Cancel"])
    cBtn:SetScript("OnClick", function()
        ed:Hide()
        if DatePicker:IsShown() then DatePicker:Hide() end
        if TimePickerMenu:IsShown() then TimePickerMenu:Hide() end
        if ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
    end)

    CalendarModule.EditDialog = ed
end

function CalendarModule:OpenEditDialog(dateKey, index)
    local ed = self.EditDialog
    ed.dateKey = dateKey
    ed.editIndex = index

    if index then
        local ev = self:GetEventsForDate(dateKey)[index]
        ed.oldSeriesId = ev.seriesId
        ed.Title:SetText(L["Edit"] .. " (" .. dateKey .. ")")
        ed.TitleBox:SetText(ev.title or "")
        ed.StartBox:SetText(ev.startDate or dateKey)
        ed.EndBox:SetText(ev.endDate or dateKey)
        ed.DescBox:SetText(ev.desc or "")

        if ev.color then
            ed.chosenColor.r = ev.color.r
            ed.chosenColor.g = ev.color.g
            ed.chosenColor.b = ev.color.b
        else
            ed.chosenColor.r = 0
            ed.chosenColor.g = 1
            ed.chosenColor.b = 0.8
        end

        if ev.isAllDay or ev.time == L["All-Day"] then
            ed.AllDayCheck:SetChecked(true)
        else
            ed.AllDayCheck:SetChecked(false)
            local sT, eT = ev.time:match("^(%d%d:%d%d)%s*-%s*(%d%d:%d%d)$")
            ed.StartTimeBtn.text:SetText(sT or "19:00")
            ed.EndTimeBtn.text:SetText(eT or "23:00")
        end
    else
        ed.oldSeriesId = nil
        ed.Title:SetText(L["Add Event"] .. " (" .. dateKey .. ")")
        ed.TitleBox:SetText("")
        ed.StartBox:SetText(dateKey)
        ed.EndBox:SetText(dateKey)
        ed.DescBox:SetText("")
        ed.AllDayCheck:SetChecked(true)
        ed.StartTimeBtn.text:SetText("19:00")
        ed.EndTimeBtn.text:SetText("23:00")
        ed.chosenColor.r = 0
        ed.chosenColor.g = 1
        ed.chosenColor.b = 0.8
    end

    ed.AllDayCheck:GetScript("OnClick")(ed.AllDayCheck)
    ed.Swatch.tex:SetColorTexture(ed.chosenColor.r, ed.chosenColor.g, ed.chosenColor.b, 1)
    ed:Show()
    ed.TitleBox:SetFocus()
end

function CalendarModule:Toggle()
    if not dayButtons[1] then self:InitUI() end
    if self:IsShown() then
        self.selectedDateKey = nil
        self:Hide()
        if self.DayManager then self.DayManager:Hide() end
        if self.EditDialog then self.EditDialog:Hide() end
        if DatePicker:IsShown() then DatePicker:Hide() end
        if TimePickerMenu:IsShown() then TimePickerMenu:Hide() end
        if ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
    else
        self:UpdateCalendar()
        self:Show()
        if AUI.UpdateCalendarBorders then AUI:UpdateCalendarBorders() end
    end
end

-- =====================================================================
-- 10. COMMANDS
-- =====================================================================
E:RegisterChatCommand("calendar", function() CalendarModule:Toggle() end)
E:RegisterChatCommand("kalender", function() CalendarModule:Toggle() end)