local E, L, V, P, G = unpack(ElvUI)
local AUI = E:NewModule('A-UI', 'AceEvent-3.0', 'AceHook-3.0')
local EP = LibStub("LibElvUIPlugin-1.0")
local addonName = "ElvUI_A-UI"

AUI.loginTime = GetTime() 

-- =====================================================================
-- 1. DEFAULTS IN ELVUI'S P-TABLE
-- =====================================================================
P["AUI"] = {
    microbar = {
        enable = true,
        size = 21,
        spacing = 13,
        buttonsPerRow = 16,
        reverseOrder = false,
        mouseover = false,
        visibilityStr = "[petbattle] hide; [vehicleui] hide; show",
        showMailButton = true,
        hideMailEmpty = false,
        showCalendarButton = true,
        showTeleportButton = true,
        extendedGuildTooltip = true,
        extendedSystemTooltip = true,
        extendedCharacterTooltip = true,
        extendedProfessionTooltip = true,
        extendedTalentTooltip = true,
        extendedAdventureTooltip = true,
        extendedLFDTooltip = true,
        
        tooltipBackdropAlpha = 0.8,
        tooltipBackdropColorEnable = false,
        tooltipBackdropColor = { r = 0.1, g = 0.1, b = 0.1 },
        tooltipBorderColorEnable = false,
        tooltipBorderClassColor = false,
        tooltipBorderColor = { r = 1, g = 1, b = 1 },

        titleFontSize = 16,
        titleColorMode = "CLASS",
        titleColor = { r = 1, g = 0.82, b = 0 },

        barPadding = 4,
        barBackdrop = true,
        barBackdropAlpha = 0.5,
        barBackdropColorEnable = false,
        barBackdropClassColor = false,
        barBackdropColor = { r = 0.1, g = 0.1, b = 0.1 },
        barBorder = true,
        barBorderColorEnable = false,
        barBorderClassColor = true,
        barBorderColor = { r = 1, g = 1, b = 1 },
        buttonBackdrop = true,
        buttonBackdropAlpha = 0.5,
        buttonBackdropColorEnable = false,
        buttonBackdropClassColor = false,
        buttonBackdropColor = { r = 0.1, g = 0.1, b = 0.1 },
        buttonBorder = true,
        buttonBorderColorEnable = false,
        buttonBorderClassColor = true,
        buttonBorderColor = { r = 1, g = 1, b = 1 },
        customIcons = {},
        desaturateAll = false,
        colorAll = false,
        globalClassColor = false,
        globalIconColor = { r = 1, g = 1, b = 1 },
        individualIconColors = {},
        
        glowEnable = true,
        glowType = "pixel",
        talentGlow = true,
        mailGlow = true,
        vaultGlow = true,
        calendarGlow = true,
        collectionsGlow = true,
        
        mailColorEnable = true,
        mailColor = { r = 0, g = 1, b = 0 },
        fisheye = true,
    },
    map = {
        enablePins = true,
        pinSize = 12,
        pinScaleMin = 1,
        pinScaleMax = 1,
        delvePins = true,
    },
    coloring = {
        datatexts = {
            enable = true,
            colorMode = "CLASS", 
            customColor = { r = 1, g = 0.82, b = 0 }, 
            gradientColor = { r = 1, g = 0.2, b = 0 },
        },
        borders = {
            topBottom = { enable = false, colorMode = "CLASS_GRADIENT", color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0}, color3 = {r=0.5,g=0,b=0} },
            minimap = { enable = false, colorMode = "CLASS_GRADIENT", color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0}, orientation = "HORIZONTAL" },
            leftChat = { enable = false, colorMode = "CLASS_GRADIENT", color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0}, invert = false },
            rightChat = { enable = false, colorMode = "CLASS_GRADIENT", color1 = {r=1,g=0.82,b=0}, color2 = {r=1,g=0.2,b=0}, invert = false },
        }
    }
}

-- =====================================================================
-- 2. HILFSFUNKTION: DEFAULTS SICHER IN DIE AKTIVE DB LADEN
-- =====================================================================
local function InsertDefaults(db, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if db[k] == nil then db[k] = {} end
            InsertDefaults(db[k], v)
        else
            if db[k] == nil then db[k] = v end
        end
    end
end

function AUI:InitDelveDatabase()
    _G["ElvUI_AUIDB"] = _G["ElvUI_AUIDB"] or {}
    local DB = _G["ElvUI_AUIDB"]
    
    DB.DelveStats = DB.DelveStats or {
        history = {},
        bestTimes = {},
        totalRuns = 0
    }
    
    AUI.DB = DB
end

-- =====================================================================
-- 3. PROFIL-UPDATE CALLBACK
-- =====================================================================
function AUI:ProfileUpdate()
    E.db.AUI = E.db.AUI or {}
    InsertDefaults(E.db.AUI, P.AUI)
    
    if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end
    if AUI.UpdateIcons then AUI:UpdateIcons() end
    if AUI.RefreshMapPins then AUI:RefreshMapPins() end
    if AUI.ColorDatatextFonts then AUI:ColorDatatextFonts() end
    if AUI.UpdateBorderColors then AUI:UpdateBorderColors() end
end

-- =====================================================================
-- 4. OPTIONEN MENÜ-GENERATOR (RAHMEN)
-- =====================================================================
local function GetBorderOptions(name, order, dbKey, isThreeColor)
    local group = {
        order = order, type = "group", name = name,
        get = function(info) return E.db.AUI.coloring.borders[dbKey][info[#info]] end,
        set = function(info, value) E.db.AUI.coloring.borders[dbKey][info[#info]] = value; if AUI.UpdateBorderColors then AUI:UpdateBorderColors() end end,
        args = {
            enable = { order = 1, type = "toggle", name = L["Enable"] or "Aktivieren", width = "full" },
            colorMode = {
                order = 2, type = "select", name = L["Color Mode"] or "Farbmodus",
                disabled = function() return not E.db.AUI.coloring.borders[dbKey].enable end,
                values = { 
                    ["CLASS"] = "Klassenfarbe", 
                    ["CUSTOM"] = "Eigene Farbe", 
                    ["GRADIENT"] = "Farbverlauf", 
                    ["CLASS_GRADIENT"] = "Klassenverlauf" 
                }
            },
            color1 = {
                order = 3, type = "color", name = isThreeColor and "Farbe 1 (Links)" or "Farbe 1 (Start)", hasAlpha = false,
                disabled = function() local m = E.db.AUI.coloring.borders[dbKey].colorMode; return not E.db.AUI.coloring.borders[dbKey].enable or m == "CLASS" or m == "CLASS_GRADIENT" end,
                get = function() local t = E.db.AUI.coloring.borders[dbKey].color1; return t.r, t.g, t.b, 1 end,
                set = function(_, r, g, b) local t = E.db.AUI.coloring.borders[dbKey].color1; t.r, t.g, t.b = r, g, b; if AUI.UpdateBorderColors then AUI:UpdateBorderColors() end end,
            },
            color2 = {
                order = 4, type = "color", name = isThreeColor and "Farbe 2 (Mitte)" or "Farbe 2 (Ende)", hasAlpha = false,
                disabled = function() local m = E.db.AUI.coloring.borders[dbKey].colorMode; return not E.db.AUI.coloring.borders[dbKey].enable or m == "CLASS" or m == "CLASS_GRADIENT" or m == "CUSTOM" end,
                get = function() local t = E.db.AUI.coloring.borders[dbKey].color2; return t.r, t.g, t.b, 1 end,
                set = function(_, r, g, b) local t = E.db.AUI.coloring.borders[dbKey].color2; t.r, t.g, t.b = r, g, b; if AUI.UpdateBorderColors then AUI:UpdateBorderColors() end end,
            },
            color3 = isThreeColor and {
                order = 5, type = "color", name = "Farbe 3 (Rechts)", hasAlpha = false,
                disabled = function() local m = E.db.AUI.coloring.borders[dbKey].colorMode; return not E.db.AUI.coloring.borders[dbKey].enable or m == "CLASS" or m == "CLASS_GRADIENT" or m == "CUSTOM" end,
                get = function() local t = E.db.AUI.coloring.borders[dbKey].color3; return t.r, t.g, t.b, 1 end,
                set = function(_, r, g, b) local t = E.db.AUI.coloring.borders[dbKey].color3; t.r, t.g, t.b = r, g, b; if AUI.UpdateBorderColors then AUI:UpdateBorderColors() end end,
            } or nil,
        }
    }

    if dbKey == "leftChat" or dbKey == "rightChat" then
        group.args.invert = {
            order = 6, type = "toggle", name = "Verlauf invertieren",
            disabled = function() local m = E.db.AUI.coloring.borders[dbKey].colorMode; return not E.db.AUI.coloring.borders[dbKey].enable or m == "CLASS" or m == "CUSTOM" end,
        }
    elseif dbKey == "minimap" then
        group.args.orientation = {
            order = 6, type = "select", name = "Verlaufsrichtung", width = "double",
            disabled = function() local m = E.db.AUI.coloring.borders[dbKey].colorMode; return not E.db.AUI.coloring.borders[dbKey].enable or m == "CLASS" or m == "CUSTOM" end,
            values = {
                ["HORIZONTAL"] = "Von Links nach Rechts",
                ["HORIZONTAL_REV"] = "Von Rechts nach Links",
                ["VERTICAL"] = "Von Unten nach Oben",
                ["VERTICAL_REV"] = "Von Oben nach Unten"
            }
        }
    end

    return group
end

-- =====================================================================
-- 5. OPTIONEN
-- =====================================================================
function AUI:InsertOptions()
    E.Options.args.AUI = {
        type = "group",
        name = "|TInterface\\AddOns\\ElvUI_A-UI\\media\\A-UI.tga:16:16|t |cff00ffd2A-UI|r",
        args = {
            installer = {
                type = "group", 
                name = "A-UI Installer", 
                order = 1,
                args = {
                    header = {
                        order = 1,
                        type = "header",
                        name = "|TInterface\\AddOns\\ElvUI_A-UI\\media\\A-UI.tga:16:16|t |cff00ffd2A-UI Installation & Profile|r",
                    },
                    addonList = {
                        order = 2,
                        type = "description",
                        name = function()
                            local text = "A-UI nutzt Synergien mit folgenden ElvUI-Plugins:\n\n"
                            local plugins = {
                                { id = "ElvUI_EltreumUI", name = "Eltreum UI" },
                                { id = "ElvUI_WindTools", name = "WindTools" },
                                { id = "ElvUI_NutsAndBolts", name = "Nuts & Bolts" }
                            }
                            for _, p in ipairs(plugins) do
                                if C_AddOns.IsAddOnLoaded(p.id) then
                                    text = text .. "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t |cff00ff00" .. p.name .. " (Aktiv)|r\n"
                                else
                                    text = text .. "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14|t |cffff0000" .. p.name .. " (Fehlt)|r\n"
                                end
                            end
                            return text .. "\n"
                        end,
                        fontSize = "medium",
                    },
                    installGroup = {
                        name = "|cff00ffd2Layout Installation|r",
                        type = "group", order = 3, guiInline = true,
                        args = {
                            desc1 = { order = 1, type = "description", name = "Führe den Installer aus, um das Standard A-UI Layout auf diesem Charakter anzuwenden (Fensterpositionen, Custom Texts, etc.).\n", width = "full" },
                            installBtn = { order = 2, type = "execute", name = "Installer starten", func = function() if AUI.RunInstaller then AUI:RunInstaller() end end },
                        },
                    },
                    transferGroup = {
                        name = "|cff00ffd2Profil Transfer|r",
                        type = "group", order = 4, guiInline = true,
                        args = {
                            desc2 = { order = 1, type = "description", name = "Hier kannst du nur deine speziellen A-UI Einstellungen (Microbar, Icons, Tooltips) als Text exportieren/importieren.\n", width = "full" },
                            exportBtn = { order = 2, type = "execute", name = L["Export"] or "Exportieren", func = function() if AUI.ExportProfile then AUI:ExportProfile() end end },
                            importBtn = { order = 3, type = "execute", name = L["Import"] or "Importieren", func = function() if AUI.ShowTransferWindow then AUI:ShowTransferWindow(false) end end },
                        },
                    },
                },
            },
            microbar = {
                type = "group", name = "Microbar", order = 2,
                get = function(info) return E.db.AUI.microbar[info[#info]] end,
                set = function(info, value) 
                    E.db.AUI.microbar[info[#info]] = value
                    if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end
                    if AUI.UpdateIcons then AUI:UpdateIcons() end 
                end,
                args = {
                    enable = { 
                        order = 1, type = "toggle", name = L["Enable"] or "Aktivieren",
                        set = function(info, value)
                            E.db.AUI.microbar.enable = value
                            if E.db.actionbar and E.db.actionbar.microbar then E.db.actionbar.microbar.enabled = not value end
                            E:StaticPopup_Show("PRIVATE_RL")
                        end
                    },
                    barGroup = {
                        order = 2, type = "group", name = L["Main Bar"] or "Hauptleiste", guiInline = true,
                        args = {
                            barPadding = { order = 1, type = "range", name = L["Padding"] or "Abstand", min = 0, max = 30, step = 1 },
                            barBackdropGroup = {
                                order = 2, type = "group", name = L["Backdrop"] or "Hintergrund", guiInline = true,
                                args = {
                                    barBackdrop = { order = 1, type = "toggle", name = L["Enable"] or "Aktivieren" },
                                    barBackdropAlpha = { order = 2, type = "range", name = L["Alpha"] or "Transparenz", min = 0, max = 1, step = 0.05, disabled = function() return not E.db.AUI.microbar.barBackdrop end },
                                    barBackdropColorEnable = { order = 3, type = "toggle", name = L["Colorize"] or "Färben", disabled = function() return not E.db.AUI.microbar.barBackdrop end },
                                    barBackdropClassColor = { order = 4, type = "toggle", name = L["Class Color"] or "Klassenfarbe", disabled = function() return not E.db.AUI.microbar.barBackdrop or not E.db.AUI.microbar.barBackdropColorEnable end },
                                    barBackdropColor = { order = 5, type = "color", name = L["Color"] or "Farbe", hasAlpha = false, disabled = function() return not E.db.AUI.microbar.barBackdrop or not E.db.AUI.microbar.barBackdropColorEnable or E.db.AUI.microbar.barBackdropClassColor end, get = function() local t = E.db.AUI.microbar.barBackdropColor; return t.r, t.g, t.b, 1 end, set = function(_, r, g, b) local t = E.db.AUI.microbar.barBackdropColor; t.r, t.g, t.b = r, g, b; if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end end },
                                }
                            },
                            barBorderGroup = {
                                order = 3, type = "group", name = L["Border"] or "Rahmen", guiInline = true,
                                args = {
                                    barBorder = { order = 1, type = "toggle", name = L["Enable"] or "Aktivieren" },
                                    barBorderColorEnable = { order = 2, type = "toggle", name = L["Colorize"] or "Färben", disabled = function() return not E.db.AUI.microbar.barBorder end },
                                    barBorderClassColor = { order = 3, type = "toggle", name = L["Class Color"] or "Klassenfarbe", disabled = function() return not E.db.AUI.microbar.barBorder or not E.db.AUI.microbar.barBorderColorEnable end },
                                    barBorderColor = { order = 4, type = "color", name = L["Color"] or "Farbe", hasAlpha = false, disabled = function() return not E.db.AUI.microbar.barBorder or not E.db.AUI.microbar.barBorderColorEnable or E.db.AUI.microbar.barBorderClassColor end, get = function() local t = E.db.AUI.microbar.barBorderColor; return t.r, t.g, t.b, 1 end, set = function(_, r, g, b) local t = E.db.AUI.microbar.barBorderColor; t.r, t.g, t.b = r, g, b; if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end end },
                                }
                            }
                        }
                    },
                    buttonGroup = {
                        order = 3, type = "group", name = L["Buttons"] or "Buttons", guiInline = true,
                        args = {
                            size = { order = 1, type = "range", name = L["Size"] or "Größe", min = 12, max = 50, step = 1 },
                            spacing = { order = 2, type = "range", name = L["Spacing"] or "Abstand", min = -5, max = 50, step = 1 },
                            buttonsPerRow = { order = 3, type = "range", name = L["Per Row"] or "Pro Reihe", min = 1, max = 30, step = 1 },
                            reverseOrder = { order = 4, type = "toggle", name = L["Reverse Order"] or "Umgekehrte Reihenfolge" },
                            btnBackdropGroup = {
                                order = 5, type = "group", name = L["Backdrop"] or "Hintergrund", guiInline = true,
                                args = {
                                    buttonBackdrop = { order = 1, type = "toggle", name = L["Enable"] or "Aktivieren" },
                                    buttonBackdropAlpha = { order = 2, type = "range", name = L["Alpha"] or "Transparenz", min = 0, max = 1, step = 0.05, disabled = function() return not E.db.AUI.microbar.buttonBackdrop end },
                                    buttonBackdropColorEnable = { order = 3, type = "toggle", name = L["Colorize"] or "Färben", disabled = function() return not E.db.AUI.microbar.buttonBackdrop end },
                                    buttonBackdropClassColor = { order = 4, type = "toggle", name = L["Class Color"] or "Klassenfarbe", disabled = function() return not E.db.AUI.microbar.buttonBackdrop or not E.db.AUI.microbar.buttonBackdropColorEnable end },
                                    buttonBackdropColor = { order = 5, type = "color", name = L["Color"] or "Farbe", hasAlpha = false, disabled = function() return not E.db.AUI.microbar.buttonBackdrop or not E.db.AUI.microbar.buttonBackdropColorEnable or E.db.AUI.microbar.buttonBackdropClassColor end, get = function() local t = E.db.AUI.microbar.buttonBackdropColor; return t.r, t.g, t.b, 1 end, set = function(_, r, g, b) local t = E.db.AUI.microbar.buttonBackdropColor; t.r, t.g, t.b = r, g, b; if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end end },
                                }
                            },
                            btnBorderGroup = {
                                order = 6, type = "group", name = L["Border"] or "Rahmen", guiInline = true,
                                args = {
                                    buttonBorder = { order = 1, type = "toggle", name = L["Enable"] or "Aktivieren" },
                                    buttonBorderColorEnable = { order = 2, type = "toggle", name = L["Colorize"] or "Färben", disabled = function() return not E.db.AUI.microbar.buttonBorder end },
                                    buttonBorderClassColor = { order = 3, type = "toggle", name = L["Class Color"] or "Klassenfarbe", disabled = function() return not E.db.AUI.microbar.buttonBorder or not E.db.AUI.microbar.buttonBorderColorEnable end },
                                    buttonBorderColor = { order = 4, type = "color", name = L["Color"] or "Farbe", hasAlpha = false, disabled = function() return not E.db.AUI.microbar.buttonBorder or not E.db.AUI.microbar.buttonBorderColorEnable or E.db.AUI.microbar.buttonBorderClassColor end, get = function() local t = E.db.AUI.microbar.buttonBorderColor; return t.r, t.g, t.b, 1 end, set = function(_, r, g, b) local t = E.db.AUI.microbar.buttonBorderColor; t.r, t.g, t.b = r, g, b; if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end end },
                                }
                            }
                        }
                    },
                    tooltips = {
                        order = 10, type = "group", name = "Icon-Tooltips",
                        args = {
                            info = { order = 0, type = "description", name = "Konfiguriere hier, welche erweiterten Informationen in den Tooltips der einzelnen Buttons angezeigt werden sollen.\n", fontSize = "medium" },
                            extendedGuildTooltip = { order = 1, type = "toggle", name = L["Guild Roster"] or "Gildenmitglieder", width = "full" },
                            extendedSystemTooltip = { order = 2, type = "toggle", name = L["System Stats"] or "System-Infos", width = "full" },
                            extendedCharacterTooltip = { order = 3, type = "toggle", name = L["Character Stats"] or "Charakter-Infos", width = "full" },
                            extendedProfessionTooltip = { order = 4, type = "toggle", name = L["Profession Stats"] or "Berufe-Infos", width = "full" },
                            extendedTalentTooltip = { order = 5, type = "toggle", name = L["Talent Stats"] or "Talent-Infos", width = "full" },
                            extendedAdventureTooltip = { order = 6, type = "toggle", name = L["Adventure Guide Stats"] or "Abenteuerführer-Infos", width = "full" },
                            extendedLFDTooltip = { order = 7, type = "toggle", name = L["Group Finder Stats"] or "Gruppensuche-Infos", width = "full" },
                            
                            appearanceGroup = {
                                order = 10, type = "group", name = "Optik", guiInline = true,
                                args = {
                                    bgHeader = { order = 1, type = "header", name = "Hintergrund" },
                                    tooltipBackdropAlpha = { order = 2, type = "range", name = "Transparenz", min = 0, max = 1, step = 0.05 },
                                    tooltipBackdropColorEnable = { order = 3, type = "toggle", name = "Färben" },
                                    tooltipBackdropColor = {
                                        order = 4, type = "color", name = "Farbe", hasAlpha = false,
                                        disabled = function() return not E.db.AUI.microbar.tooltipBackdropColorEnable end,
                                        get = function() local t = E.db.AUI.microbar.tooltipBackdropColor; return t.r, t.g, t.b, 1 end,
                                        set = function(_, r, g, b) local t = E.db.AUI.microbar.tooltipBackdropColor; t.r, t.g, t.b = r, g, b; end,
                                    },
                                    borderHeader = { order = 5, type = "header", name = "Rahmen" },
                                    tooltipBorderColorEnable = { order = 6, type = "toggle", name = "Färben" },
                                    tooltipBorderClassColor = { 
                                        order = 7, type = "toggle", name = "Klassenfarbe", 
                                        disabled = function() return not E.db.AUI.microbar.tooltipBorderColorEnable end 
                                    },
                                    tooltipBorderColor = {
                                        order = 8, type = "color", name = "Farbe", hasAlpha = false,
                                        disabled = function() return not E.db.AUI.microbar.tooltipBorderColorEnable or E.db.AUI.microbar.tooltipBorderClassColor end,
                                        get = function() local t = E.db.AUI.microbar.tooltipBorderColor; return t.r, t.g, t.b, 1 end,
                                        set = function(_, r, g, b) local t = E.db.AUI.microbar.tooltipBorderColor; t.r, t.g, t.b = r, g, b; end,
                                    },
                                    titleHeader = { order = 10, type = "header", name = "Überschriften" },
                                    titleFontSize = { order = 11, type = "range", name = "Schriftgröße", min = 8, max = 24, step = 1 },
                                    titleColorMode = { 
                                        order = 12, type = "select", name = "Färbung", 
                                        values = { ["DEFAULT"] = "Standard (Gold)", ["CLASS"] = "Klassenfarbe", ["CUSTOM"] = "Eigene Farbe" } 
                                    },
                                    titleColor = {
                                        order = 13, type = "color", name = "Eigene Farbe", hasAlpha = false,
                                        disabled = function() return E.db.AUI.microbar.titleColorMode ~= "CUSTOM" end,
                                        get = function() local t = E.db.AUI.microbar.titleColor; return t.r, t.g, t.b, 1 end,
                                        set = function(_, r, g, b) local t = E.db.AUI.microbar.titleColor; t.r, t.g, t.b = r, g, b; end,
                                    },
                                }
                            }
                        }
                    },
                    visibilityGroup = {
                        order = 15, type = "group", name = L["Visibility"] or "Sichtbarkeit", guiInline = true,
                        args = {
                            mouseover = { order = 1, type = "toggle", name = L["Show on Mouseover"] or "Nur bei Mouseover" },
                            showMailButton = { order = 2, type = "toggle", name = L["Show Mail Button"] or "Post anzeigen", set = function(_, v) E.db.AUI.microbar.showMailButton = v; if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end; end },
                            hideMailEmpty = { order = 3, type = "toggle", name = L["Hide if Empty"] or "Verstecken wenn leer", disabled = function() return not E.db.AUI.microbar.showMailButton end },
                            showCalendarButton = { order = 4, type = "toggle", name = L["Show Calendar Button"] or "Kalender anzeigen", set = function(_, v) E.db.AUI.microbar.showCalendarButton = v; if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end; end },
                            showTeleportButton = { order = 5, type = "toggle", name = L["Show Teleport Button"] or "Teleport-Button anzeigen", set = function(_, v) E.db.AUI.microbar.showTeleportButton = v; if AUI.UpdateMicrobar then AUI:UpdateMicrobar() end; end },
                            spacerVis = { order = 6, type = "description", name = " ", width = "full" },
                            visibilityStr = { order = 7, type = "input", width = "full", name = L["Macro Conditionals"] or "Sichtbarkeits-Bedingungen", desc = "[combat] hide; [vehicleui] hide; show" },
                        }
                    },
                    iconEffects = {
                        order = 20, type = "group", name = L["Icon Effects"] or "Icon-Effekte",
                        args = {
                            headerGlows = { order = 1, type = "header", name = L["Notifications"] or "Benachrichtigungen" },
                            
                            talentGlow = { order = 2, type = "toggle", name = L["Talent Glow"] or "Talente", width = 1.0, disabled = function() return not E.db.AUI.microbar.glowEnable end },
                            vaultGlow = { order = 3, type = "toggle", name = L["Vault Glow"] or "Schatzkammer", width = 1.0, disabled = function() return not E.db.AUI.microbar.glowEnable end },
                            calendarGlow = { order = 4, type = "toggle", name = L["Calendar Glow"] or "Kalender", width = 1.0, disabled = function() return not E.db.AUI.microbar.glowEnable end },
                            
                            collectionsGlow = { order = 5, type = "toggle", name = L["Collections Glow"] or "Sammlungen", width = 1.5, disabled = function() return not E.db.AUI.microbar.glowEnable end },
                            mailGlow = { order = 6, type = "toggle", name = L["Mail Glow"] or "Post", width = 1.0, disabled = function() return not E.db.AUI.microbar.glowEnable end },
                            
                            spacer1 = { order = 7, type = "description", name = "\n", width = "full" },

                            glowEnable = {
                                order = 8, type = "toggle", name = "|cff00ffd2" .. (L["Enable Glow Effects"] or "Alle Leuchteffekte aktivieren") .. "|r",
                                width = 1.2,
                            },
                            glowStyle = {
                                order = 9, type = "select", name = L["Global Glow Effect"] or "Leuchteffekt-Stil",
                                width = 1.3,
                                disabled = function() return not E.db.AUI.microbar.glowEnable end,
                                values = { ["pixel"] = L["Pixel Glow"] or "Pixel", ["autocast"] = L["AutoCast Glow"] or "Auto-Cast", ["blizzard"] = L["Blizzard Standard"] or "Blizzard Standard" },
                                get = function() return E.db.AUI.microbar.glowType or "pixel" end,
                                set = function(_, v) E.db.AUI.microbar.glowType = v; if AUI.UpdateIcons then AUI:UpdateIcons() end end,
                            },

                            spacer2 = { order = 10, type = "description", name = "\n", width = "full" },

                            mailColorEnable = { order = 11, type = "toggle", name = L["Colorize on Mail"] or "Färben bei Post", width = 1.2 },
                            mailColor = { 
                                order = 12, type = "color", name = L["Color"] or "Farbe", width = 0.5,
                                disabled = function() return not E.db.AUI.microbar.mailColorEnable end,
                                get = function() local t = E.db.AUI.microbar.mailColor; return t.r, t.g, t.b, 1 end,
                                set = function(_, r, g, b) local t = E.db.AUI.microbar.mailColor; t.r, t.g, t.b = r, g, b; if AUI.UpdateIcons then AUI:UpdateIcons() end end 
                            },
                            
                            headerAnims = { order = 20, type = "header", name = L["Animations"] or "Animationen" },
                            fisheye = { order = 21, type = "toggle", name = L["Fish-Eye Hover"] or "Fish-Eye Effekt", width = "full" },
                        }
                    },
                    iconSelection = {
                        order = 30, type = "group", name = L["Icon Selection"] or "Icon-Auswahl",
                        args = {
                            headerColors = { order = 1, type = "header", name = L["Colors"] or "Farben" },
                            desaturateAll = { order = 2, type = "toggle", name = L["Desaturate All"] or "Alle entsättigen", set = function(_, v) E.db.AUI.microbar.desaturateAll = v; if AUI.UpdateIcons then AUI:UpdateIcons() end end },
                            colorAll = { order = 3, type = "toggle", name = L["Color All"] or "Alle färben", set = function(_, v) E.db.AUI.microbar.colorAll = v; if AUI.UpdateIcons then AUI:UpdateIcons() end end },
                            globalClassColor = { order = 4, type = "toggle", name = L["Class Color"] or "Klassenfarbe", disabled = function() return not E.db.AUI.microbar.colorAll end, set = function(_, v) E.db.AUI.microbar.globalClassColor = v; if AUI.UpdateIcons then AUI:UpdateIcons() end end },
                            globalIconColor = { order = 5, type = "color", name = L["Color"] or "Farbe", disabled = function() return not E.db.AUI.microbar.colorAll or E.db.AUI.microbar.globalClassColor end, get = function() local t = E.db.AUI.microbar.globalIconColor; return t.r, t.g, t.b, 1 end, set = function(_, r, g, b) local t = E.db.AUI.microbar.globalIconColor; t.r, t.g, t.b = r, g, b; if AUI.UpdateIcons then AUI:UpdateIcons() end end },
                            spacerGlobal = { order = 6, type = "description", name = " ", width = "full" },
                            headerIndividuals = { order = 7, type = "header", name = L["Icon Customization"] or "Individuelle Anpassung" },
                            info = { order = 8, type = "description", name = L["Choose icons and individual colors below."] or "Wähle hier Icons und eigene Farben.", fontSize = "medium", width = "full" }
                        }
                    },
                },
            },
            map = {
                type = "group", name = L["World Map"] or "Weltkarte", order = 3,
                get = function(info) return E.db.AUI.map[info[#info]] end,
                set = function(info, value) E.db.AUI.map[info[#info]] = value; if AUI.RefreshMapPins then AUI:RefreshMapPins() end end,
                args = {
                    header = { order = 1, type = "header", name = L["Custom Map Pins"] or "Eigene Karten-Pins" },
                    enablePins = { order = 2, type = "toggle", name = L["Enable Pins"] or "Pins aktivieren", width = "full" },
                   
                    pinSize = { 
                        order = 3, type = "range", name = L["Pin Size"] or "Pin-Größe", min = 8, max = 30, step = 1,
                        disabled = function() return not E.db.AUI.map.enablePins end 
                    },
                    
                    spacer = { order = 4, type = "description", name = "\n", width = "full" },  
                    
                    pinScaleMin = { 
                        order = 4, type = "range", name = L["Zoom-Out Factor"] or "Zoom-Out Faktor", min = 0.75, max = 1.5, step = 0.05,
                        disabled = function() return not E.db.AUI.map.enablePins end 
                    },
                    pinScaleMax = { 
                        order = 5, type = "range", name = L["Zoom-In Factor"] or "Zoom-In Faktor", min = 0.75, max = 1.5, step = 0.05,
                        disabled = function() return not E.db.AUI.map.enablePins end 
                    },
                }
            },
            -- =================================================================
            -- NEUES TAB-MENÜ FÜR EINFÄRBUNGEN
            -- =================================================================
            coloring = {
                type = "group", name = "Einfärbungen", order = 4, childGroups = "tab",
                args = {
                    datatexts = {
                        order = 1, type = "group", name = "Datatexte",
                        get = function(info) return E.db.AUI.coloring.datatexts[info[#info]] end,
                        set = function(info, value) 
                            E.db.AUI.coloring.datatexts[info[#info]] = value
                            if AUI.ColorDatatextFonts then AUI:ColorDatatextFonts() end 
                            local DT = E:GetModule('DataTexts')
                            if DT and DT.LoadDataTexts then DT:LoadDataTexts() end
                        end,
                        args = {
                            enable = { order = 1, type = "toggle", name = "Aktivieren", width = "full" },
                            colorMode = {
                                order = 2, type = "select", name = "Farbmodus",
                                disabled = function() return not E.db.AUI.coloring.datatexts.enable end,
                                values = { 
                                    ["CLASS"] = "Klassenfarbe", 
                                    ["CUSTOM"] = "Eigene Farbe",
                                    ["GRADIENT"] = "Farbverlauf",
                                    ["CLASS_GRADIENT"] = "Klassenverlauf" 
                                }
                            },
                            customColor = {
                                order = 3, type = "color", name = "Farbe 1 (Start)", hasAlpha = false,
                                disabled = function() local m = E.db.AUI.coloring.datatexts.colorMode; return not E.db.AUI.coloring.datatexts.enable or m == "CLASS" or m == "CLASS_GRADIENT" end,
                                get = function() local t = E.db.AUI.coloring.datatexts.customColor; return t.r, t.g, t.b, 1 end,
                                set = function(_, r, g, b) 
                                    local t = E.db.AUI.coloring.datatexts.customColor; 
                                    t.r, t.g, t.b = r, g, b; 
                                    if AUI.ColorDatatextFonts then AUI:ColorDatatextFonts() end 
                                    local DT = E:GetModule('DataTexts'); if DT and DT.LoadDataTexts then DT:LoadDataTexts() end
                                end,
                            },
                            gradientColor = {
                                order = 4, type = "color", name = "Farbe 2 (Ende)", hasAlpha = false,
                                disabled = function() local m = E.db.AUI.coloring.datatexts.colorMode; return not E.db.AUI.coloring.datatexts.enable or m == "CLASS" or m == "CUSTOM" end,
                                get = function() local t = E.db.AUI.coloring.datatexts.gradientColor; return t.r, t.g, t.b, 1 end,
                                set = function(_, r, g, b) 
                                    local t = E.db.AUI.coloring.datatexts.gradientColor; 
                                    t.r, t.g, t.b = r, g, b; 
                                    if AUI.ColorDatatextFonts then AUI:ColorDatatextFonts() end 
                                    local DT = E:GetModule('DataTexts'); if DT and DT.LoadDataTexts then DT:LoadDataTexts() end
                                end,
                            }
                        }
                    },
                    topBottom = GetBorderOptions("Top & Bottom Panels", 2, "topBottom", true),
                    leftChat = GetBorderOptions("Linker Chat", 3, "leftChat", false),
                    rightChat = GetBorderOptions("Rechter Chat", 4, "rightChat", false),
                    minimap = GetBorderOptions("Minimap", 5, "minimap", false),
                }
            }
        },
    }
    
    if AUI.MicroIcons then
        for i, data in ipairs(AUI.MicroIcons) do
            local dropValues = {}
            if AUI.CuratedIconsList and AUI.CuratedIconsList[i] then
                for path, label in pairs(AUI.CuratedIconsList[i]) do
                    if path == "dynamic_a" or path == "dynamic_b" or path == "dynamic_c" then
                        local day, prefix = date("%d"), (path == "dynamic_a" and "a" or (path == "dynamic_b" and "b" or "c"))
                        local realPath = "Interface\\AddOns\\ElvUI_A-UI\\media\\calendar\\" .. prefix .. day .. ".tga"
                        dropValues[path] = "|T"..realPath..":18:18:0:0:64:64:4:60:4:60|t  "..label
                    elseif path ~= "" and path ~= "portrait" then
                        dropValues[path] = "|T"..path..":18:18:0:0:64:64:4:60:4:60|t  "..label
                    else dropValues[path] = label end
                end
            end
            
            E.Options.args.AUI.args.microbar.args.iconSelection.args["icon"..i] = {
                order = 10 + (i * 2), type = "select", name = data.name, values = dropValues, width = 1.2,
                get = function() local val = E.db.AUI.microbar.customIcons[i]; if i == 14 and (not val or val == "") then return "dynamic_a" end return tostring(val or "") end,
                set = function(_, v) if i == 14 and (not v or v == "") then v = "dynamic_a" end E.db.AUI.microbar.customIcons[i] = (v == "") and nil or v; if AUI.UpdateIcons then AUI:UpdateIcons() end end,
            }
            E.Options.args.AUI.args.microbar.args.iconSelection.args["color"..i] = {
                order = 10 + (i * 2) + 1, type = "color", name = "", width = 0.2, disabled = function() return E.db.AUI.microbar.colorAll end, 
                get = function() local c = E.db.AUI.microbar.individualIconColors[i] or {r=1, g=1, b=1}; return c.r, c.g, c.b, 1 end,
                set = function(_, r, g, b) E.db.AUI.microbar.individualIconColors[i] = {r=r, g=g, b=b}; if AUI.UpdateIcons then AUI:UpdateIcons() end end,
            }
        end
    end
end

-- =====================================================================
-- 6. INITIALISIERUNG
-- =====================================================================
function AUI:Initialize()
    -- 1. Lade Defaults in die aktive DB, falls sie fehlen
    E.db.AUI = E.db.AUI or {}
    InsertDefaults(E.db.AUI, P.AUI)

    -- 2. Hooke Profil-Updates von ElvUI (Zwingend für Profil-Wechsel!)
    hooksecurefunc(E, "UpdateAll", function() AUI:ProfileUpdate() end)

    EP:RegisterPlugin(addonName, AUI.InsertOptions)
    
    if E.db.AUI.microbar.enable and E.db.actionbar and E.db.actionbar.microbar and E.db.actionbar.microbar.enabled then
        E.db.actionbar.microbar.enabled = false
    end
    
    if E.db.AUI.microbar.enable then E:Delay(2, function() if AUI.CreateMicrobar then AUI:CreateMicrobar() end end) end
    
    E:Delay(2.5, function()
        if not E.db.AUI.install_version and AUI.RunInstaller then
            AUI:RunInstaller()
        end
    end)
    
    -- 3. Farben bei Addon-Start initialisieren
    E:Delay(3, function()
        if AUI.UpdateBorderColors then AUI:UpdateBorderColors() end
        if AUI.ColorDatatextFonts then AUI:ColorDatatextFonts() end
    end)
end

E:RegisterModule(AUI:GetName())

_G.ElvUI_AUI_CompartmentClick = function()
    if E.ToggleOptions then E:ToggleOptions() end
    E:Delay(0.1, function() if E.Libs and E.Libs.AceConfigDialog then E.Libs.AceConfigDialog:SelectGroup("ElvUI", "AUI") end end)
end