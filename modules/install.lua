local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')
local PI = E:GetModule('PluginInstaller')

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

local function IsAddonActive(id)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(id)
    elseif IsAddOnLoaded then
        return IsAddOnLoaded(id)
    end
    return false
end

-- =====================================================================
-- SEITE 1: BEGRÜSSUNG
-- =====================================================================
local function Step1()
    PluginInstallFrame.SubTitle:Show()
    PluginInstallFrame.SubTitle:SetText(L["Welcome to A-UI"])
    
    PluginInstallFrame.Desc1:Show()
    PluginInstallFrame.Desc1:SetText(L["Thank you for choosing A-UI!"])
    
    PluginInstallFrame.Desc2:Show()
    PluginInstallFrame.Desc2:SetText(L["This short setup will configure your interface and ensure all required plugins are present."])
    
    PluginInstallFrame.Desc3:Show()
    PluginInstallFrame.Desc3:SetText(L["Click 'Continue' below to proceed, or 'Close' to abort."])
    
    PluginInstallFrame.Option1:Hide()
    PluginInstallFrame.Option2:Hide()
    PluginInstallFrame.Option3:Hide()
    PluginInstallFrame.Option4:Hide()
end

-- =====================================================================
-- SEITE 2: PLUGIN-CHECKER
-- =====================================================================
local function Step2()
    PluginInstallFrame.SubTitle:Show()
    PluginInstallFrame.SubTitle:SetText(L["System and Plugin Check"])
    
    PluginInstallFrame.Desc1:Show()
    PluginInstallFrame.Desc1:SetText(L["A-UI uses synergies with other ElvUI plugins. Here is the status of your system:"])
    
    local plugins = {
        { id = "ElvUI_EltreumUI", name = "Eltreum UI" },
        { id = "ElvUI_NutsAndBolts", name = "Nuts & Bolts" }
    }
    
    if isRetail then
        table.insert(plugins, 2, { id = "ElvUI_WindTools", name = "WindTools" })
    end
    
    local statusText = ""
    for _, p in ipairs(plugins) do
        if IsAddonActive(p.id) then
            statusText = statusText .. "|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t |cff00ff00" .. p.name .. (L[" (Installed & Active)"] or " (Installiert & Aktiv)") .. "|r\n"
        else
            statusText = statusText .. "|TInterface\\RaidFrame\\ReadyCheck-NotReady:16|t |cffff0000" .. p.name .. (L[" (Missing - Recommended!)"] or " (Fehlt - Empfohlen!)") .. "|r\n"
        end
    end
    
    PluginInstallFrame.Desc2:Show()
    PluginInstallFrame.Desc2:SetText(statusText)
    
    PluginInstallFrame.Desc3:Show()
    PluginInstallFrame.Desc3:SetText(L["Don't worry: If plugins are missing, A-UI will automatically adjust the layout to prevent errors."])
    
    PluginInstallFrame.Option1:Hide()
    PluginInstallFrame.Option2:Hide()
end

-- =====================================================================
-- SEITE 3: DAS SMARTE LAYOUT
-- =====================================================================
local function InstallLayout()
    local hasEltruism = IsAddonActive("ElvUI_EltreumUI")
    local hasWindTools = isRetail and IsAddonActive("ElvUI_WindTools")
    local hasNutsAndBolts = IsAddonActive("ElvUI_NutsAndBolts")
    
    -- =====================================================================
    -- 1. DATATEXT PANELS ERSCHAFFEN (ACCOUNTWEIT / GLOBAL)
    -- =====================================================================
    E.global.datatexts = E.global.datatexts or {}
    E.global.datatexts.customPanels = E.global.datatexts.customPanels or {}
    
    -- Panel: A-UI_Bot-Mid_L (2 Slots)
    if not E.global.datatexts.customPanels["A-UI_Bot-Mid_L"] then
        E.global.datatexts.customPanels["A-UI_Bot-Mid_L"] = {
            ["name"] = "A-UI_Bot-Mid_L",
            ["numPoints"] = 2,
            ["width"] = 440,
            ["height"] = 24,
            ["frameStrata"] = "LOW",
            ["frameLevel"] = 1,
            ["backdrop"] = false,
            ["panelTransparency"] = false,
            ["fonts"] = {
                ["enable"] = true,
                ["fontOutline"] = "SHADOWOUTLINE",
                ["fontSize"] = 14,
            },
            ["border"] = false,
        }
    end

    -- Panel: A-UI_Bot-Mid_R (2 Slots)
    if not E.global.datatexts.customPanels["A-UI_Bot-Mid_R"] then
        E.global.datatexts.customPanels["A-UI_Bot-Mid_R"] = {
            ["name"] = "A-UI_Bot-Mid_R",
            ["numPoints"] = 2,
            ["width"] = 440,
            ["height"] = 24,
            ["frameStrata"] = "LOW",
            ["frameLevel"] = 1,
            ["backdrop"] = false,
            ["panelTransparency"] = false,
            ["fonts"] = {
                ["enable"] = true,
                ["fontOutline"] = "SHADOWOUTLINE",
                ["fontSize"] = 14,
            },
            ["border"] = false,
        }
    end

    -- Panel: A-UI_Bot-Mid_Time (1 Slot)
    if not E.global.datatexts.customPanels["A-UI_Bot-Mid_Time"] then
        E.global.datatexts.customPanels["A-UI_Bot-Mid_Time"] = {
            ["name"] = "A-UI_Bot-Mid_Time",
            ["numPoints"] = 1,
            ["width"] = 100,
            ["height"] = 20,
            ["frameStrata"] = "LOW",
            ["frameLevel"] = 1,
            ["backdrop"] = false,
            ["panelTransparency"] = false,
            ["fonts"] = {
                ["enable"] = true,
                ["fontOutline"] = "SHADOWOUTLINE",
                ["fontSize"] = 26,
            },
            ["border"] = false,
        }
    end

    -- Panel: A-UI_Bot-R (4 Slots)
    if not E.global.datatexts.customPanels["A-UI_Bot-R"] then
        E.global.datatexts.customPanels["A-UI_Bot-R"] = {
            ["name"] = "A-UI_Bot-R",
            ["numPoints"] = 4,
            ["width"] = 457,
            ["height"] = 24,
            ["frameStrata"] = "LOW",
            ["frameLevel"] = 1,
            ["backdrop"] = false,
            ["panelTransparency"] = false,
            ["fonts"] = {
                ["enable"] = true,
                ["fontOutline"] = "SHADOWOUTLINE",
                ["fontSize"] = 14,
            },
            ["border"] = false,
        }
    end

    -- =====================================================================
    -- 2. PROFIL-EXPORT BEFÜLLUNG
    -- =====================================================================
    E.db["datatexts"] = E.db["datatexts"] or {}
    E.db["datatexts"]["panels"] = E.db["datatexts"]["panels"] or {}
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_L"] = E.db["datatexts"]["panels"]["A-UI_Bot-Mid_L"] or {}
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_R"] = E.db["datatexts"]["panels"]["A-UI_Bot-Mid_R"] or {}
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_Time"] = E.db["datatexts"]["panels"]["A-UI_Bot-Mid_Time"] or {}
    E.db["datatexts"]["panels"]["A-UI_Bot-R"] = E.db["datatexts"]["panels"]["A-UI_Bot-R"] or {}
    E.db["datatexts"]["panels"]["LeftChatDataPanel"] = E.db["datatexts"]["panels"]["LeftChatDataPanel"] or {}
    E.db["datatexts"]["panels"]["RightChatDataPanel"] = E.db["datatexts"]["panels"]["RightChatDataPanel"] or {}

    if hasEltruism and E.db["ElvUI_EltreumUI"] then
        E.db["ElvUI_EltreumUI"]["borders"]["alternativeclassbar"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["altpowerbar"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["arenaborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["auraborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["aurabordernp"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["auraborderuf"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["bar1borders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["bar2borders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["bar3borders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["bar4borders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["bar5borders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["bar6borders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["bossborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["chatborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["comboclassbar"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["experiencebar"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["focusborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["focuscastborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["focuspowerborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["minimapborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["partyborders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["petactionborders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["petborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["playercastborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["playerpower"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["playerpowersizex"] = 229.3
        E.db["ElvUI_EltreumUI"]["borders"]["playerpowersizey"] = 23.8
        E.db["ElvUI_EltreumUI"]["borders"]["raid2borders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["raid40borders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["raidborders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["reputationbar"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["staggerclassbar"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["stanceborders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["tankassistborders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["targetcastborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["targetpower"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["targettargetborder"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["texture"] = "RenFade"
        E.db["ElvUI_EltreumUI"]["borders"]["tooltipborders"] = false
        E.db["ElvUI_EltreumUI"]["borders"]["tooltipsize"] = 4
        E.db["ElvUI_EltreumUI"]["borders"]["tooltipsizex"] = 5
        E.db["ElvUI_EltreumUI"]["borders"]["tooltipsizey"] = 6
        E.db["ElvUI_EltreumUI"]["borders"]["universalborderssettings"]["thickness"] = 5
        E.db["ElvUI_EltreumUI"]["borders"]["xplayer"] = 230
        E.db["ElvUI_EltreumUI"]["borders"]["xtarget"] = 230
        E.db["ElvUI_EltreumUI"]["borders"]["yplayer"] = 50
        E.db["ElvUI_EltreumUI"]["borders"]["ytarget"] = 50
        E.db["ElvUI_EltreumUI"]["otherstuff"]["bagProfessionIcons"] = true
        E.db["ElvUI_EltreumUI"]["otherstuff"]["datatextclasscolorbar"] = false
        E.db["ElvUI_EltreumUI"]["otherstuff"]["dctagicon"] = "6"
        E.db["ElvUI_EltreumUI"]["otherstuff"]["deadtagicon"] = "4"
        E.db["ElvUI_EltreumUI"]["otherstuff"]["minimapcardinaldirections"]["enable"] = true
        E.db["ElvUI_EltreumUI"]["otherstuff"]["minimapcardinaldirections"]["fontsize"] = 16
        E.db["ElvUI_EltreumUI"]["otherstuff"]["minimapcardinaldirections"]["offset"] = 15
        E.db["ElvUI_EltreumUI"]["otherstuff"]["worldmapscale"] = false
        E.db["ElvUI_EltreumUI"]["skins"]["auctionator"] = true
        E.db["ElvUI_EltreumUI"]["skins"]["clique"] = true
        E.db["ElvUI_EltreumUI"]["skins"]["details"] = true
        E.db["ElvUI_EltreumUI"]["skins"]["groupfinderSpecIcons"] = false
        E.db["ElvUI_EltreumUI"]["unitframes"]["blizzardraidframes"] = false
        E.db["ElvUI_EltreumUI"]["unitframes"]["darkmode"] = true
        E.db["ElvUI_EltreumUI"]["unitframes"]["darkpowercolor"] = true
        E.db["ElvUI_EltreumUI"]["unitframes"]["models"]["ufalphadark"] = 0.25
        E.db["ElvUI_EltreumUI"]["unitframes"]["models"]["ufdesaturation"] = 0.1
        E.db["ElvUI_EltreumUI"]["unitframes"]["models"]["unitframe"] = true
        E.db["ElvUI_EltreumUI"]["unitframes"]["portraits"]["party"]["enable"] = false
        E.db["ElvUI_EltreumUI"]["unitframes"]["portraits"]["player"]["enable"] = false
        E.db["ElvUI_EltreumUI"]["unitframes"]["portraits"]["shadow"]["enable"] = false
        E.db["ElvUI_EltreumUI"]["unitframes"]["portraits"]["shadow"]["inner"] = false
        E.db["ElvUI_EltreumUI"]["unitframes"]["portraits"]["target"]["enable"] = false
        E.db["ElvUI_EltreumUI"]["unitframes"]["sparkcustomcolor"]["enable"] = true
        E.db["ElvUI_EltreumUI"]["unitframes"]["thinmodeaurabars"] = true
        E.db["ElvUI_EltreumUI"]["unitframes"]["uftextureversion"] = "V2"
    end

    if hasNutsAndBolts and E.db["NutsAndBolts"] then
        E.db["NutsAndBolts"]["ElvUIPanels"] = E.db["NutsAndBolts"]["ElvUIPanels"] or {}
        E.db["NutsAndBolts"]["ElvUIPanels"]["bottom"] = E.db["NutsAndBolts"]["ElvUIPanels"]["bottom"] or {}
        E.db["NutsAndBolts"]["ElvUIPanels"]["bottom"]["height"] = 26
        E.db["NutsAndBolts"]["ElvUIPanels"]["bottom"]["shadows"] = true
        E.db["NutsAndBolts"]["ObjectiveTracker"] = E.db["NutsAndBolts"]["ObjectiveTracker"] or {}
        E.db["NutsAndBolts"]["ObjectiveTracker"]["enable"] = true
    end

    if hasWindTools and E.db["WT"] then
        E.db["WT"]["announcement"] = E.db["WT"]["announcement"] or {}
        E.db["WT"]["announcement"]["enable"] = false
        E.db["WT"]["announcement"]["keystone"] = E.db["WT"]["announcement"]["keystone"] or {}
        E.db["WT"]["announcement"]["keystone"]["enable"] = false
        E.db["WT"]["announcement"]["utility"] = E.db["WT"]["announcement"]["utility"] or {}
        E.db["WT"]["announcement"]["utility"]["enable"] = false
        E.db["WT"]["combat"] = E.db["WT"]["combat"] or {}
        E.db["WT"]["combat"]["combatAlert"] = E.db["WT"]["combat"]["combatAlert"] or {}
        E.db["WT"]["combat"]["combatAlert"]["animation"] = false
        E.db["WT"]["combat"]["combatAlert"]["enable"] = false
        E.db["WT"]["combat"]["combatAlert"]["text"] = false
        E.db["WT"]["combat"]["raidMarkers"] = E.db["WT"]["combat"]["raidMarkers"] or {}
        E.db["WT"]["combat"]["raidMarkers"]["backdrop"] = false
        E.db["WT"]["combat"]["raidMarkers"]["enable"] = false
        E.db["WT"]["combat"]["raidMarkers"]["readyCheck"] = false
        E.db["WT"]["item"] = E.db["WT"]["item"] or {}
        E.db["WT"]["item"]["extraItemsBar"] = E.db["WT"]["item"]["extraItemsBar"] or {}
        E.db["WT"]["item"]["extraItemsBar"]["bar1"] = E.db["WT"]["item"]["extraItemsBar"]["bar1"] or {}
        E.db["WT"]["item"]["extraItemsBar"]["bar1"]["anchor"] = "BOTTOMLEFT"
        E.db["WT"]["item"]["extraItemsBar"]["bar1"]["buttonWidth"] = 32
        E.db["WT"]["item"]["extraItemsBar"]["bar1"]["buttonsPerRow"] = 1
        E.db["WT"]["item"]["extraItemsBar"]["bar1"]["numButtons"] = 7
        E.db["WT"]["item"]["extraItemsBar"]["bar2"] = E.db["WT"]["item"]["extraItemsBar"]["bar2"] or {}
        E.db["WT"]["item"]["extraItemsBar"]["bar2"]["anchor"] = "BOTTOMLEFT"
        E.db["WT"]["item"]["extraItemsBar"]["bar2"]["buttonWidth"] = 32
        E.db["WT"]["item"]["extraItemsBar"]["bar2"]["buttonsPerRow"] = 1
        E.db["WT"]["item"]["extraItemsBar"]["bar2"]["numButtons"] = 7
        E.db["WT"]["item"]["extraItemsBar"]["bar3"] = E.db["WT"]["item"]["extraItemsBar"]["bar3"] or {}
        E.db["WT"]["item"]["extraItemsBar"]["bar3"]["anchor"] = "BOTTOMLEFT"
        E.db["WT"]["item"]["extraItemsBar"]["bar3"]["buttonWidth"] = 32
        E.db["WT"]["item"]["extraItemsBar"]["bar3"]["buttonsPerRow"] = 1
        E.db["WT"]["item"]["extraItemsBar"]["bar3"]["numButtons"] = 7
        E.db["WT"]["item"]["trade"] = E.db["WT"]["item"]["trade"] or {}
        E.db["WT"]["item"]["trade"]["enable"] = false
        E.db["WT"]["item"]["trade"]["thanksButton"] = false
        E.db["WT"]["misc"] = E.db["WT"]["misc"] or {}
        E.db["WT"]["misc"]["gameBar"] = E.db["WT"]["misc"]["gameBar"] or {}
        E.db["WT"]["misc"]["gameBar"]["backdrop"] = false
        E.db["WT"]["misc"]["gameBar"]["enable"] = false
        E.db["WT"]["quest"] = E.db["WT"]["quest"] or {}
        E.db["WT"]["quest"]["turnIn"] = E.db["WT"]["quest"]["turnIn"] or {}
        E.db["WT"]["quest"]["turnIn"]["enable"] = false
        E.db["WT"]["social"] = E.db["WT"]["social"] or {}
        E.db["WT"]["social"]["chatBar"] = E.db["WT"]["social"]["chatBar"] or {}
        E.db["WT"]["social"]["chatBar"]["backdrop"] = true
        E.db["WT"]["social"]["chatBar"]["backdropSpacing"] = 2
        E.db["WT"]["social"]["chatBar"]["buttonHeight"] = 6
        E.db["WT"]["social"]["chatBar"]["buttonWidth"] = 56
        E.db["WT"]["social"]["chatBar"]["enable"] = false
        E.db["WT"]["social"]["chatBar"]["spacing"] = 3
        E.db["WT"]["social"]["chatText"] = E.db["WT"]["social"]["chatText"] or {}
        E.db["WT"]["social"]["chatText"]["abbreviation"] = "DEFAULT"
        E.db["WT"]["social"]["emote"] = E.db["WT"]["social"]["emote"] or {}
        E.db["WT"]["social"]["emote"]["size"] = 14
        E.db["WT"]["unitFrames"] = E.db["WT"]["unitFrames"] or {}
        E.db["WT"]["unitFrames"]["absorb"] = E.db["WT"]["unitFrames"]["absorb"] or {}
        E.db["WT"]["unitFrames"]["absorb"]["enable"] = true
    end

    -- =====================================================================
    -- SICHERHEITS-INITIALISIERUNGEN (Verhindert Abstürze bei frischen Profilen)
    -- =====================================================================
    E.db["movers"] = E.db["movers"] or {}
    E.db["unitframe"] = E.db["unitframe"] or {}
    E.db["unitframe"]["units"] = E.db["unitframe"]["units"] or {}
    
    E.db["unitframe"]["units"]["party"] = E.db["unitframe"]["units"]["party"] or {}
    E.db["unitframe"]["units"]["party"]["customTexts"] = E.db["unitframe"]["units"]["party"]["customTexts"] or {}
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"] = E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"] or {}
    
    E.db["unitframe"]["units"]["player"] = E.db["unitframe"]["units"]["player"] or {}
    E.db["unitframe"]["units"]["player"]["customTexts"] = E.db["unitframe"]["units"]["player"]["customTexts"] or {}
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"] = E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"] or {}
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"] = E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"] or {}
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"] = E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"] or {}
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"] = E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"] or {}
    
    E.db["unitframe"]["units"]["target"] = E.db["unitframe"]["units"]["target"] or {}
    E.db["unitframe"]["units"]["target"]["customTexts"] = E.db["unitframe"]["units"]["target"]["customTexts"] or {}
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"] = E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"] or {}
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"] = E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"] or {}
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"] = E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"] or {}
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"] = E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"] or {}
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"] = E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"] or {}
    
    E.db["unitframe"]["units"]["raid1"] = E.db["unitframe"]["units"]["raid1"] or {}
    E.db["unitframe"]["units"]["raid1"]["customTexts"] = E.db["unitframe"]["units"]["raid1"]["customTexts"] or {}
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"] = E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"] or {}
    
    E.db["unitframe"]["units"]["raid3"] = E.db["unitframe"]["units"]["raid3"] or {}
    E.db["unitframe"]["units"]["raid3"]["customTexts"] = E.db["unitframe"]["units"]["raid3"]["customTexts"] or {}
    E.db["unitframe"]["units"]["raid3"]["customTexts"]["EltreumRaid3Name"] = E.db["unitframe"]["units"]["raid3"]["customTexts"]["EltreumRaid3Name"] or {}

    -- =====================================================================
    -- HAUPT-PROFILKONFIGURATION
    -- =====================================================================
    if P.actionbar and E.db.actionbar then E:CopyTable(E.db.actionbar, P.actionbar) end
    
    E.db["actionbar"]["bar1"]["buttonSize"] = 38
    E.db["actionbar"]["bar1"]["buttonSpacing"] = 1
    E.db["actionbar"]["bar2"]["buttonSize"] = 38
    E.db["actionbar"]["bar2"]["buttonSpacing"] = 1
    E.db["actionbar"]["bar2"]["buttonsPerRow"] = 6
    E.db["actionbar"]["bar2"]["enabled"] = true
    E.db["actionbar"]["bar2"]["mouseover"] = true
    E.db["actionbar"]["bar2"]["visibility"] = "[petbattle] hide; show"
    E.db["actionbar"]["bar3"]["buttonSize"] = 38
    E.db["actionbar"]["bar3"]["buttonSpacing"] = 1
    E.db["actionbar"]["bar3"]["buttons"] = 12
    E.db["actionbar"]["bar3"]["buttonsPerRow"] = 12
    E.db["actionbar"]["bar3"]["mouseover"] = true
    E.db["actionbar"]["bar3"]["visibility"] = "[petbattle] hide; show"
    E.db["actionbar"]["bar4"]["mouseover"] = true
    E.db["actionbar"]["bar4"]["visibility"] = "[petbattle] hide; show"
    E.db["actionbar"]["bar5"]["buttonSize"] = 38
    E.db["actionbar"]["bar5"]["buttonSpacing"] = 1
    E.db["actionbar"]["bar5"]["buttons"] = 12
    E.db["actionbar"]["bar5"]["mouseover"] = true
    E.db["actionbar"]["bar5"]["visibility"] = "[petbattle] hide; show"
    E.db["actionbar"]["bar6"]["buttonSize"] = 38
    E.db["actionbar"]["bar6"]["buttonSpacing"] = 1
    E.db["actionbar"]["bar6"]["enabled"] = true
    if E.db["actionbar"]["bar6"]["paging"] then
        E.db["actionbar"]["bar6"]["paging"]["DRUID"] = "[bonusbar:1] 13; [bonusbar:3] 14; 6"
    end
    E.db["actionbar"]["bar6"]["visibility"] = "[petbattle] hide; show"
    E.db["actionbar"]["barPet"]["buttonSize"] = 28
    E.db["actionbar"]["barPet"]["buttonsPerRow"] = 10
    if E.db["actionbar"]["extraActionButton"] then
        E.db["actionbar"]["extraActionButton"]["clean"] = true
        E.db["actionbar"]["extraActionButton"]["scale"] = 0.97
    end
    E.db["actionbar"]["flashAnimation"] = true
    E.db["actionbar"]["font"] = "Expressway"
    E.db["actionbar"]["microbar"]["buttonHeight"] = 20
    E.db["actionbar"]["microbar"]["buttonSize"] = 23
    E.db["actionbar"]["microbar"]["buttonSpacing"] = 3
    E.db["actionbar"]["microbar"]["keepSizeRatio"] = true
    E.db["actionbar"]["stanceBar"]["buttonSpacing"] = 1
    E.db["actionbar"]["stanceBar"]["point"] = "BOTTOMLEFT"
    E.db["actionbar"]["transparent"] = true
    if E.db["actionbar"]["vehicleExitButton"] then
        E.db["actionbar"]["vehicleExitButton"]["size"] = 31
    end

    E.db["auras"]["buffs"]["countFont"] = "Expressway"
    E.db["auras"]["buffs"]["countFontSize"] = 14
    E.db["auras"]["buffs"]["size"] = 40
    E.db["auras"]["buffs"]["smoothbars"] = true
    E.db["auras"]["debuffs"]["countFont"] = "Expressway"
    E.db["auras"]["debuffs"]["countFontSize"] = 14
    E.db["auras"]["debuffs"]["size"] = 40

    E.db["bags"]["bagSize"] = 40
    E.db["bags"]["bagWidth"] = 660
    E.db["bags"]["bankCombined"] = true
    E.db["bags"]["bankSize"] = 36
    E.db["bags"]["countFont"] = "Expressway"
    E.db["bags"]["countFontSize"] = 14
    E.db["bags"]["itemLevelCustomColorEnable"] = true
    E.db["bags"]["itemLevelFont"] = "Expressway"
    E.db["bags"]["itemLevelFontSize"] = 14
    E.db["bags"]["junkDesaturate"] = true
    E.db["bags"]["junkIcon"] = true
    E.db["bags"]["moneyCoins"] = false
    E.db["bags"]["moneyFormat"] = "BLIZZARD"
    if E.db["bags"]["scrapIcon"] ~= nil then E.db["bags"]["scrapIcon"] = true end
    E.db["bags"]["split"]["bag5"] = true
    E.db["bags"]["split"]["bagSpacing"] = 7
    E.db["bags"]["split"]["bank"] = true
    E.db["bags"]["split"]["player"] = true
    E.db["bags"]["transparent"] = true
    E.db["bags"]["vendorGrays"]["details"] = true
    E.db["bags"]["vendorGrays"]["enable"] = true
    if isRetail then E.db["bags"]["warbandSize"] = 36 end

    E.db["chat"]["copyChatLines"] = true
    E.db["chat"]["fadeTabsNoBackdrop"] = false
    E.db["chat"]["font"] = "Expressway"
    E.db["chat"]["fontSize"] = 14
    E.db["chat"]["historySize"] = 500
    E.db["chat"]["lfgIcons"] = false
    E.db["chat"]["panelHeight"] = 236
    E.db["chat"]["panelTabBackdrop"] = true
    E.db["chat"]["panelWidth"] = 472
    E.db["chat"]["tabFont"] = "Expressway"
    E.db["chat"]["tabFontSize"] = 14
    E.db["chat"]["tabSelector"] = "BOX"
    E.db["chat"]["tabSelectorColor"]["b"] = 0.82
    E.db["chat"]["tabSelectorColor"]["g"] = 0.51
    E.db["chat"]["tabSelectorColor"]["r"] = 0.09
    E.db["chat"]["timeStampFormat"] = "%H:%M "

    E.db["convertPages"] = true
    if E.db["databars"] and E.db["databars"]["azerite"] then E.db["databars"]["azerite"]["enable"] = false end
    if E.db["databars"] and E.db["databars"]["experience"] then E.db["databars"]["experience"]["width"] = 380 end
    if E.db["databars"] and E.db["databars"]["reputation"] then E.db["databars"]["reputation"]["enable"] = true end
    if E.db["databars"] and E.db["databars"]["threat"] then
        E.db["databars"]["threat"]["enable"] = false
        E.db["databars"]["threat"]["height"] = 24
        E.db["databars"]["threat"]["width"] = 472
    end

    E.db["datatexts"]["font"] = "Expressway"
    E.db["datatexts"]["fontSize"] = 14
    
    -- Dynamische Datatext-Zuordnung
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_L"][1] = isRetail and "Talent/Loot Specialization" or "Talents"
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_L"][2] = "Durability"
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_L"]["battleground"] = false
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_L"]["enable"] = true
    
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_R"][1] = "Friends"
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_R"][2] = "Guild"
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_R"]["battleground"] = false
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_R"]["enable"] = true
    
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_Time"][1] = "Time"
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_Time"]["battleground"] = false
    E.db["datatexts"]["panels"]["A-UI_Bot-Mid_Time"]["enable"] = true
    
    E.db["datatexts"]["panels"]["A-UI_Bot-R"][1] = "System"
    E.db["datatexts"]["panels"]["A-UI_Bot-R"][2] = isRetail and "Quests" or "Gold"
    E.db["datatexts"]["panels"]["A-UI_Bot-R"][3] = "Bags"
    E.db["datatexts"]["panels"]["A-UI_Bot-R"][4] = "Gold"
    E.db["datatexts"]["panels"]["A-UI_Bot-R"]["battleground"] = false
    E.db["datatexts"]["panels"]["A-UI_Bot-R"]["enable"] = true
    
    E.db["datatexts"]["panels"]["LeftChatDataPanel"][3] = "QuickJoin"
    E.db["datatexts"]["panels"]["LeftChatDataPanel"]["enable"] = false
    E.db["datatexts"]["panels"]["LeftChatDataPanel"]["panelTransparency"] = true
    if E.db["datatexts"]["panels"]["MinimapPanel"] then E.db["datatexts"]["panels"]["MinimapPanel"]["enable"] = false end
    E.db["datatexts"]["panels"]["RightChatDataPanel"]["enable"] = false
    E.db["datatexts"]["panels"]["RightChatDataPanel"]["panelTransparency"] = true

    E.db["general"]["autoTrackReputation"] = true
    E.db["general"]["backdropfadecolor"]["b"] = 0.054
    E.db["general"]["backdropfadecolor"]["g"] = 0.054
    E.db["general"]["backdropfadecolor"]["r"] = 0.054
    if E.db["general"]["bonusObjectivePosition"] then E.db["general"]["bonusObjectivePosition"] = "AUTO" end
    if E.db["general"]["bottomPanelSettings"] then E.db["general"]["bottomPanelSettings"]["height"] = 26 end
    E.db["general"]["font"] = "Expressway"
    E.db["general"]["fontSize"] = 14
    E.db["general"]["fontStyle"] = "SHADOW"
    E.db["general"]["fonts"]["cooldown"]["outline"] = "SHADOW"
    if E.db["general"]["minimap"]["icons"] and E.db["general"]["minimap"]["icons"]["mail"] then
        E.db["general"]["minimap"]["icons"]["mail"]["xOffset"] = -3
        E.db["general"]["minimap"]["icons"]["mail"]["yOffset"] = -3
    end
    E.db["general"]["minimap"]["resetZoom"]["enable"] = true
    E.db["general"]["minimap"]["resetZoom"]["time"] = 10
    E.db["general"]["minimap"]["size"] = 220
    if E.db["general"]["objectiveFrameAutoHide"] ~= nil then E.db["general"]["objectiveFrameAutoHide"] = false end
    if E.db["general"]["objectiveFrameHeight"] then E.db["general"]["objectiveFrameHeight"] = 400 end
    if E.db["general"]["talkingHeadFrameScale"] then E.db["general"]["talkingHeadFrameScale"] = 1 end
    if E.db["general"]["totems"] then
        E.db["general"]["totems"]["growthDirection"] = "HORIZONTAL"
        E.db["general"]["totems"]["size"] = 50
        E.db["general"]["totems"]["spacing"] = 8
    end

    -- =====================================================================
    -- MOVERS
    -- =====================================================================
    E.db["movers"]["AUI_MicrobarMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,1"
    E.db["movers"]["AdditionalPowerMover"] = "BOTTOM,ElvUIParent,BOTTOM,-521,505"
    if isRetail then E.db["movers"]["AddonCompartmentMover"] = "TOPRIGHT,UIParent,TOPRIGHT,-227,-229" end
    E.db["movers"]["AlertFrameMover"] = "TOP,ElvUIParent,TOP,0,-20"
    if isRetail then E.db["movers"]["AltPowerBarMover"] = "TOPRIGHT,UIParent,TOPRIGHT,-995,-269" end
    E.db["movers"]["ArenaHeaderMover"] = "BOTTOMRIGHT,ElvUIParent,RIGHT,-106,-166"
    if isRetail then E.db["movers"]["AzeriteBarMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-3,-246" end
    E.db["movers"]["BNETMover"] = "TOPRIGHT,UIParent,TOPRIGHT,-781,-4"
    if isRetail then E.db["movers"]["BelowMinimapContainerMover"] = "TOPRIGHT,UIParent,TOPRIGHT,-51,-300" end
    if isRetail then E.db["movers"]["BossBannerMover"] = "TOP,ElvUIParent,TOP,0,-126" end
    if isRetail then E.db["movers"]["BossButton"] = "BOTTOM,ElvUIParent,BOTTOM,207,358" end
    E.db["movers"]["BossHeaderMover"] = "BOTTOMRIGHT,ElvUIParent,RIGHT,-106,-166"
    E.db["movers"]["BuffsMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-227,-3"
    E.db["movers"]["ClassBarMover"] = "BOTTOM,ElvUIParent,BOTTOM,-400,559"
    E.db["movers"]["DTPanelA-UI_Bot-Mid_LMover"] = "BOTTOM,ElvUIParent,BOTTOM,-600,0"
    E.db["movers"]["DTPanelA-UI_Bot-Mid_RMover"] = "BOTTOM,ElvUIParent,BOTTOM,600,0"
    E.db["movers"]["DTPanelA-UI_Bot-Mid_TimeMover"] = "BOTTOM,ElvUIParent,BOTTOM,0,0"
    E.db["movers"]["DTPanelA-UI_Bot-RMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-4,0"
    E.db["movers"]["DebuffsMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-227,-171"
    E.db["movers"]["DurabilityFrameMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,141,-4"
    E.db["movers"]["ElvAB_1"] = "BOTTOM,UIParent,BOTTOM,0,280"
    if isRetail then E.db["movers"]["ElvAB_13"] = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-4,442" end
    E.db["movers"]["ElvAB_2"] = "BOTTOM,ElvUIParent,BOTTOM,351,280"
    E.db["movers"]["ElvAB_3"] = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-4,264"
    E.db["movers"]["ElvAB_4"] = "RIGHT,ElvUIParent,RIGHT,-4,0"
    E.db["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,-352,280"
    E.db["movers"]["ElvAB_6"] = "BOTTOM,UIParent,BOTTOM,0,319"
    E.db["movers"]["ElvUF_AssistMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,4,-249"
    E.db["movers"]["ElvUF_FocusCastbarMover"] = "TOPLEFT,ElvUF_Focus,BOTTOMLEFT,0,-1"
    E.db["movers"]["ElvUF_FocusMover"] = "BOTTOM,ElvUIParent,BOTTOM,335,453"
    E.db["movers"]["ElvUF_PartyMover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,778,26"
    E.db["movers"]["ElvUF_PetCastbarMover"] = "TOPLEFT,ElvUF_Pet,BOTTOMLEFT,0,-1"
    E.db["movers"]["ElvUF_PetMover"] = "BOTTOM,UIParent,BOTTOM,-400,447"
    E.db["movers"]["ElvUF_PlayerCastbarMover"] = "BOTTOM,ElvUIParent,BOTTOM,-400,485"
    E.db["movers"]["ElvUF_PlayerMover"] = "BOTTOM,ElvUIParent,BOTTOM,-400,519"
    E.db["movers"]["ElvUF_Raid1Mover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,778,26"
    E.db["movers"]["ElvUF_Raid2Mover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,778,26"
    E.db["movers"]["ElvUF_Raid3Mover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,778,26"
    E.db["movers"]["ElvUF_TankMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,4,-187"
    E.db["movers"]["ElvUF_TargetCastbarMover"] = "BOTTOM,ElvUIParent,BOTTOM,400,485"
    E.db["movers"]["ElvUF_TargetMover"] = "BOTTOM,ElvUIParent,BOTTOM,400,519"
    E.db["movers"]["ElvUF_TargetTargetMover"] = "BOTTOM,ElvUIParent,BOTTOM,446,453"
    E.db["movers"]["ElvUF_TargetTargetTargetMover"] = "BOTTOM,ElvUIParent,BOTTOM,446,432"
    E.db["movers"]["ElvUIBagMover"] = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-4,264"
    E.db["movers"]["ElvUIBankMover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,4,266"
    if isRetail then E.db["movers"]["EventToastMover"] = "TOP,ElvUIParent,TOP,0,-150" end
    E.db["movers"]["ExperienceBarMover"] = "TOP,UIParent,TOP,0,0"
    E.db["movers"]["GMMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,251,-5"
    if isRetail then E.db["movers"]["HonorBarMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-3,-236" end
    E.db["movers"]["LeftChatMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,28"
    E.db["movers"]["LootFrameMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,419,-187"
    if isRetail then E.db["movers"]["LossControlMover"] = "TOP,UIParent,TOP,-409,-594" end
    E.db["movers"]["MicrobarMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,1"
    E.db["movers"]["MinimapMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-3,-3"
    E.db["movers"]["MirrorTimer1Mover"] = "TOP,ElvUIParent,TOP,-1,-96"
    E.db["movers"]["ObjectiveFrameMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-163,-325"
    E.db["movers"]["PetAB"] = "BOTTOM,ElvUIParent,BOTTOM,0,247"
    E.db["movers"]["PlayerPowerBarMover"] = "BOTTOM,UIParent,BOTTOM,-400,505"
    if isRetail then E.db["movers"]["PowerBarContainerMover"] = "TOP,ElvUIParent,TOP,0,-75" end
    if isRetail then E.db["movers"]["PrivateAurasMover"] = "TOPRIGHT,UIParent,TOPRIGHT,-247,-229" end
    if isRetail then E.db["movers"]["PrivateRaidWarningMover"] = "TOP,RaidBossEmoteFrame,TOP,0,0" end
    if isRetail then E.db["movers"]["QueueStatusMover"] = "TOPRIGHT,UIParent,TOPRIGHT,-4,-29" end
    if isRetail then E.db["movers"]["ReputationBarMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-3,-226" end
    E.db["movers"]["RightChatMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-4,28"
    E.db["movers"]["ShiftAB"] = "BOTTOM,ElvUIParent,BOTTOM,-152,358"
    if isRetail then E.db["movers"]["SocialMenuMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,4,-187" end
    E.db["movers"]["TargetPowerBarMover"] = "BOTTOM,ElvUIParent,BOTTOM,400,504"
    E.db["movers"]["ThreatBarMover"] = "BOTTOM,UIParent,BOTTOM,487,58"
    E.db["movers"]["TooltipMover"] = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-4,287"
    if isRetail then E.db["movers"]["TopCenterContainerMover"] = "TOP,ElvUIParent,TOP,0,-30" end
    if isRetail then E.db["movers"]["TorghastChoiceToggle"] = "BOTTOM,UIParent,BOTTOM,0,679" end
    E.db["movers"]["TotemTrackerMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,491,4"
    if isRetail then E.db["movers"]["VOICECHAT"] = "TOPLEFT,ElvUIParent,TOPLEFT,369,-210" end
    if isRetail then E.db["movers"]["VehicleLeaveButton"] = "BOTTOM,UIParent,BOTTOM,0,357" end
    if isRetail then E.db["movers"]["VehicleSeatMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,4,-4" end
    if isRetail then E.db["movers"]["ZoneAbility"] = "BOTTOM,ElvUIParent,BOTTOM,154,358" end

    -- WINDTOOLS MOVERS (Nur wenn WindTools aktiv ist)
    if hasWindTools then
        E.db["movers"]["WTChatBarMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,264"
        E.db["movers"]["WTCustomEmoteFrameMover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,492,72"
        E.db["movers"]["WTExitPhaseDivingButtonMover"] = "BOTTOM,ElvUIParent,BOTTOM,141,358"
        E.db["movers"]["WTExtraItemsBar1Mover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-556,28"
        E.db["movers"]["WTExtraItemsBar2Mover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-478,28"
        E.db["movers"]["WTExtraItemsBar3Mover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-517,28"
        E.db["movers"]["WTExtraItemsBar4Mover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-1044,-46"
        E.db["movers"]["WTExtraItemsBar5Mover"] = "TOPRIGHT,UIParent,TOPRIGHT,-1044,-4"
        E.db["movers"]["WTGameBarAnchor"] = "TOPLEFT,UIParent,TOPLEFT,682,-68"
        E.db["movers"]["WTMinimapButtonBarAnchor"] = "TOPRIGHT,UIParent,TOPRIGHT,-4,-264"
        E.db["movers"]["WTRaidMarkersBarAnchor"] = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-4,264"
        E.db["movers"]["WTSwitchButtonBarMover"] = "TOPRIGHT,UIParent,TOPRIGHT,-4,-245"
    end

    -- =====================================================================
    -- NAMEPLATES
    -- =====================================================================
    E.db["nameplates"]["colors"]["selection"][0]["b"] = 0.25
    E.db["nameplates"]["colors"]["selection"][0]["g"] = 0.25
    E.db["nameplates"]["colors"]["selection"][0]["r"] = 0.78
    E.db["nameplates"]["colors"]["selection"][2]["b"] = 0.36
    E.db["nameplates"]["colors"]["selection"][2]["g"] = 0.76
    E.db["nameplates"]["colors"]["selection"][2]["r"] = 0.85
    E.db["nameplates"]["colors"]["selection"][3]["b"] = 0.3
    E.db["nameplates"]["colors"]["selection"][3]["g"] = 0.67
    E.db["nameplates"]["colors"]["selection"][3]["r"] = 0.29
    E.db["nameplates"]["colors"]["threat"]["badColor"]["b"] = 0.25
    E.db["nameplates"]["colors"]["threat"]["badColor"]["g"] = 0.25
    E.db["nameplates"]["colors"]["threat"]["badColor"]["r"] = 0.78
    E.db["nameplates"]["colors"]["threat"]["goodColor"]["b"] = 0.3
    E.db["nameplates"]["colors"]["threat"]["goodColor"]["g"] = 0.67
    E.db["nameplates"]["colors"]["threat"]["goodColor"]["r"] = 0.29
    E.db["nameplates"]["colors"]["threat"]["goodTransition"]["b"] = 0.36
    E.db["nameplates"]["colors"]["threat"]["goodTransition"]["g"] = 0.76
    E.db["nameplates"]["colors"]["threat"]["goodTransition"]["r"] = 0.85
    E.db["nameplates"]["font"] = "Expressway"
    E.db["nameplates"]["threat"]["badScale"] = 1.4
    E.db["nameplates"]["threat"]["beingTankedByPet"] = false
    E.db["nameplates"]["threat"]["goodScale"] = 1.05
    E.db["nameplates"]["threat"]["indicator"] = true
    
    -- ENEMY NPC
    E.db["nameplates"]["units"]["ENEMY_NPC"]["buffs"]["countFontSize"] = 18
    E.db["nameplates"]["units"]["ENEMY_NPC"]["castbar"]["iconPosition"] = "LEFT"
    E.db["nameplates"]["units"]["ENEMY_NPC"]["castbar"]["showIcon"] = false
    E.db["nameplates"]["units"]["ENEMY_NPC"]["debuffs"]["attachTo"] = "BUFFS"
    E.db["nameplates"]["units"]["ENEMY_NPC"]["eliteIcon"]["enable"] = true
    E.db["nameplates"]["units"]["ENEMY_NPC"]["eliteIcon"]["position"] = "LEFT"
    E.db["nameplates"]["units"]["ENEMY_NPC"]["eliteIcon"]["xOffset"] = -4
    E.db["nameplates"]["units"]["ENEMY_NPC"]["eliteIcon"]["yOffset"] = 1
    E.db["nameplates"]["units"]["ENEMY_NPC"]["health"]["text"]["format"] = "[perhp<%]"
    E.db["nameplates"]["units"]["ENEMY_NPC"]["health"]["width"] = 160
    E.db["nameplates"]["units"]["ENEMY_NPC"]["level"]["fontSize"] = 12
    E.db["nameplates"]["units"]["ENEMY_NPC"]["level"]["xOffset"] = 7
    E.db["nameplates"]["units"]["ENEMY_NPC"]["level"]["yOffset"] = -21
    E.db["nameplates"]["units"]["ENEMY_NPC"]["name"]["format"] = "[reactioncolor][name:abbrev:short] || [range]"
    E.db["nameplates"]["units"]["ENEMY_NPC"]["name"]["xOffset"] = -7
    E.db["nameplates"]["units"]["ENEMY_NPC"]["name"]["yOffset"] = -8
    if E.db["nameplates"]["units"]["ENEMY_NPC"]["smartAuraPosition"] then
        E.db["nameplates"]["units"]["ENEMY_NPC"]["smartAuraPosition"] = "FLUID_DEBUFFS_ON_BUFFS"
    end
    E.db["nameplates"]["units"]["ENEMY_NPC"]["title"]["enable"] = true
    E.db["nameplates"]["units"]["ENEMY_NPC"]["title"]["fontSize"] = 12
    E.db["nameplates"]["units"]["ENEMY_NPC"]["title"]["format"] = "[threat]"
    E.db["nameplates"]["units"]["ENEMY_NPC"]["title"]["position"] = "TOPLEFT"
    E.db["nameplates"]["units"]["ENEMY_NPC"]["title"]["xOffset"] = -3
    E.db["nameplates"]["units"]["ENEMY_NPC"]["title"]["yOffset"] = -21
    
    -- ENEMY PLAYER
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["buffs"]["countFontSize"] = 18
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["health"]["height"] = 14
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["health"]["text"]["format"] = "[perhp<%]"
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["health"]["width"] = 160
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["name"]["format"] = "[namecolor][name][realm:dash]"
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["portrait"]["classicon"] = false
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["portrait"]["enable"] = true
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["portrait"]["position"] = "LEFT"
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["portrait"]["xOffset"] = 0
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["portrait"]["yOffset"] = 0
    E.db["nameplates"]["units"]["ENEMY_PLAYER"]["title"]["format"] = "[namecolor][guild:brackets]"
    
    -- FRIENDLY NPC
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["buffs"]["countFontSize"] = 18
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["castbar"]["smoothbars"] = true
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["health"]["height"] = 14
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["health"]["text"]["format"] = "[perhp<%]"
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["health"]["width"] = 140
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["name"]["format"] = "[namecolor][name]"
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["power"]["enable"] = true
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["title"]["enable"] = true
    E.db["nameplates"]["units"]["FRIENDLY_NPC"]["title"]["format"] = "[namecolor][npctitle:brackets]"
    
    -- FRIENDLY PLAYER
    E.db["nameplates"]["units"]["FRIENDLY_PLAYER"]["buffs"]["countFontSize"] = 18
    E.db["nameplates"]["units"]["FRIENDLY_PLAYER"]["health"]["height"] = 14
    E.db["nameplates"]["units"]["FRIENDLY_PLAYER"]["health"]["text"]["format"] = "[perhp<%]"
    E.db["nameplates"]["units"]["FRIENDLY_PLAYER"]["name"]["format"] = "[namecolor][name:title][realm:dash]"
    E.db["nameplates"]["units"]["FRIENDLY_PLAYER"]["pvpindicator"]["enable"] = true
    E.db["nameplates"]["units"]["FRIENDLY_PLAYER"]["title"]["format"] = "[namecolor][guild:brackets]"
    
    -- PLAYER PLATE
    E.db["nameplates"]["units"]["PLAYER"]["health"]["smoothbars"] = true
    E.db["nameplates"]["units"]["PLAYER"]["name"]["enable"] = true
    E.db["nameplates"]["units"]["PLAYER"]["visibility"]["showAlways"] = true
    E.db["nameplates"]["visibility"]["showAll"] = false

    -- =====================================================================
    -- TOOLTIPS
    -- =====================================================================
    E.db["tooltip"]["alwaysShowRealm"] = true
    E.db["tooltip"]["font"] = "Expressway"
    E.db["tooltip"]["headerFont"] = "Expressway"
    E.db["tooltip"]["headerFontSize"] = 14
    E.db["tooltip"]["healthBar"]["font"] = "Expressway"
    E.db["tooltip"]["itemCount"]["bank"] = true
    E.db["tooltip"]["itemCount"]["stack"] = true
    E.db["tooltip"]["smallTextFontSize"] = 14
    E.db["tooltip"]["textFontSize"] = 14

    -- =====================================================================
    -- UNITFRAME COLORS & SETTINGS
    -- =====================================================================
    E.db["unitframe"]["colors"]["auraBarBuff"]["b"] = 0.1
    E.db["unitframe"]["colors"]["auraBarBuff"]["g"] = 0.1
    E.db["unitframe"]["colors"]["auraBarBuff"]["r"] = 0.1
    E.db["unitframe"]["colors"]["castColor"]["b"] = 0.1
    E.db["unitframe"]["colors"]["castColor"]["g"] = 0.1
    E.db["unitframe"]["colors"]["castColor"]["r"] = 0.1
    E.db["unitframe"]["colors"]["classbackdrop"] = true
    E.db["unitframe"]["colors"]["colorhealthbyvalue"] = false
    E.db["unitframe"]["colors"]["disconnected"]["b"] = 0.65098041296005
    E.db["unitframe"]["colors"]["disconnected"]["g"] = 0.74901962280273
    E.db["unitframe"]["colors"]["disconnected"]["r"] = 0.83921575546265
    E.db["unitframe"]["colors"]["healPrediction"]["absorbs"]["a"] = 0.5
    E.db["unitframe"]["colors"]["healPrediction"]["maxOverflow"] = 0.01
    E.db["unitframe"]["colors"]["healPrediction"]["personal"]["b"] = 0.50196078431373
    E.db["unitframe"]["colors"]["health"]["b"] = 0.086274512112141
    E.db["unitframe"]["colors"]["health"]["g"] = 0.086274512112141
    E.db["unitframe"]["colors"]["health"]["r"] = 0.086274512112141
    E.db["unitframe"]["colors"]["health_backdrop"]["b"] = 0
    E.db["unitframe"]["colors"]["health_backdrop"]["g"] = 0
    E.db["unitframe"]["colors"]["health_backdrop"]["r"] = 0
    E.db["unitframe"]["colors"]["healthbackdropbyvalue"] = true
    E.db["unitframe"]["colors"]["tapped"]["b"] = 0.63921570777893
    E.db["unitframe"]["colors"]["tapped"]["g"] = 0.63921570777893
    E.db["unitframe"]["colors"]["tapped"]["r"] = 0.63921570777893
    E.db["unitframe"]["colors"]["transparentAurabars"] = true
    E.db["unitframe"]["colors"]["transparentCastbar"] = true
    E.db["unitframe"]["colors"]["transparentHealth"] = true
    E.db["unitframe"]["colors"]["transparentPower"] = true
    E.db["unitframe"]["colors"]["useDeadBackdrop"] = true
    E.db["unitframe"]["font"] = "Expressway"
    E.db["unitframe"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["fontSize"] = 14

    -- ARENA & ASSIST
    if E.db["unitframe"]["units"]["arena"] then
        E.db["unitframe"]["units"]["arena"]["colorOverride"] = "FORCE_OFF"
        E.db["unitframe"]["units"]["arena"]["width"] = 220
    end
    if E.db["unitframe"]["units"]["assist"] then
        E.db["unitframe"]["units"]["assist"]["colorOverride"] = "FORCE_OFF"
    end

    -- BOSS
    if E.db["unitframe"]["units"]["boss"] then
        E.db["unitframe"]["units"]["boss"]["buffs"]["maxDuration"] = 300
        E.db["unitframe"]["units"]["boss"]["buffs"]["sizeOverride"] = 27
        E.db["unitframe"]["units"]["boss"]["buffs"]["yOffset"] = 16
        E.db["unitframe"]["units"]["boss"]["castbar"]["width"] = 246
        E.db["unitframe"]["units"]["boss"]["colorOverride"] = "FORCE_OFF"
        E.db["unitframe"]["units"]["boss"]["debuffs"]["maxDuration"] = 300
        E.db["unitframe"]["units"]["boss"]["debuffs"]["sizeOverride"] = 27
        E.db["unitframe"]["units"]["boss"]["debuffs"]["yOffset"] = -16
        E.db["unitframe"]["units"]["boss"]["health"]["text_format"] = "[healthcolor][eltruism:hpstatusnopc]"
        E.db["unitframe"]["units"]["boss"]["height"] = 60
        E.db["unitframe"]["units"]["boss"]["infoPanel"]["height"] = 17
        E.db["unitframe"]["units"]["boss"]["width"] = 246
    end

    -- FOCUS
    if E.db["unitframe"]["units"]["focus"] then
        E.db["unitframe"]["units"]["focus"]["castbar"]["width"] = 90
        E.db["unitframe"]["units"]["focus"]["height"] = 30
        E.db["unitframe"]["units"]["focus"]["name"]["text_format"] = "[namecolor][name:eltruism:abbreviate] [eltruism:IconOutline:player] [eltruism:raidmarker]"
        E.db["unitframe"]["units"]["focus"]["width"] = 90
    end

    -- PARTY
    E.db["unitframe"]["units"]["party"]["colorOverride"] = "FORCE_OFF"
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["enable"] = true
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["font"] = "Expressway"
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["justifyH"] = "CENTER"
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["size"] = 14
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["text_format"] = "[eltruism:status]"
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["xOffset"] = 0
    E.db["unitframe"]["units"]["party"]["customTexts"]["A-UI_Status"]["yOffset"] = -8
    E.db["unitframe"]["units"]["party"]["height"] = 50
    E.db["unitframe"]["units"]["party"]["name"]["yOffset"] = 7
    E.db["unitframe"]["units"]["party"]["power"]["height"] = 13
    if E.db["unitframe"]["units"]["party"]["raidRoleIcons"] then
        E.db["unitframe"]["units"]["party"]["raidRoleIcons"]["scale"] = 1.8
    end
    E.db["unitframe"]["units"]["party"]["rdebuffs"]["font"] = "Expressway"
    if E.db["unitframe"]["units"]["party"]["roleIcon"] then
        E.db["unitframe"]["units"]["party"]["roleIcon"]["damager"] = false
        E.db["unitframe"]["units"]["party"]["roleIcon"]["size"] = 19
        E.db["unitframe"]["units"]["party"]["roleIcon"]["xOffset"] = -8
        E.db["unitframe"]["units"]["party"]["roleIcon"]["yOffset"] = -10
    end
    E.db["unitframe"]["units"]["party"]["width"] = 220

    -- PET
    E.db["unitframe"]["units"]["pet"]["castbar"]["height"] = 12
    E.db["unitframe"]["units"]["pet"]["castbar"]["iconSize"] = 32
    E.db["unitframe"]["units"]["pet"]["castbar"]["width"] = 220
    E.db["unitframe"]["units"]["pet"]["colorOverride"] = "FORCE_OFF"
    E.db["unitframe"]["units"]["pet"]["debuffs"]["enable"] = true
    E.db["unitframe"]["units"]["pet"]["disableTargetGlow"] = false
    E.db["unitframe"]["units"]["pet"]["height"] = 34
    E.db["unitframe"]["units"]["pet"]["infoPanel"]["height"] = 14
    E.db["unitframe"]["units"]["pet"]["width"] = 220

    -- PLAYER
    if E.db["unitframe"]["units"]["player"]["CombatIcon"] then
        E.db["unitframe"]["units"]["player"]["CombatIcon"]["size"] = 32
        E.db["unitframe"]["units"]["player"]["CombatIcon"]["texture"] = "Eltruism16"
        E.db["unitframe"]["units"]["player"]["CombatIcon"]["xOffset"] = 8
    end
    if E.db["unitframe"]["units"]["player"]["RestIcon"] then
        E.db["unitframe"]["units"]["player"]["RestIcon"]["size"] = 26
    end
    E.db["unitframe"]["units"]["player"]["aurabar"]["enable"] = false
    E.db["unitframe"]["units"]["player"]["buffs"]["attachTo"] = "FRAME"
    E.db["unitframe"]["units"]["player"]["castbar"]["insideInfoPanel"] = false
    E.db["unitframe"]["units"]["player"]["castbar"]["smoothbars"] = true
    E.db["unitframe"]["units"]["player"]["castbar"]["width"] = 220
    if E.db["unitframe"]["units"]["player"]["classAdditional"] then
        E.db["unitframe"]["units"]["player"]["classAdditional"]["height"] = 55
        E.db["unitframe"]["units"]["player"]["classAdditional"]["orientation"] = "VERTICAL"
        E.db["unitframe"]["units"]["player"]["classAdditional"]["width"] = 20
    end
    E.db["unitframe"]["units"]["player"]["classbar"]["detachFromFrame"] = true
    E.db["unitframe"]["units"]["player"]["classbar"]["detachedWidth"] = 220
    E.db["unitframe"]["units"]["player"]["classbar"]["fill"] = "spaced"
    E.db["unitframe"]["units"]["player"]["classbar"]["height"] = 12
    E.db["unitframe"]["units"]["player"]["classbar"]["smoothbars"] = true
    E.db["unitframe"]["units"]["player"]["colorOverride"] = "FORCE_OFF"
    
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["enable"] = true
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["justifyH"] = "LEFT"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["size"] = 16
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["text_format"] = "[classcolor][curhp< || ][perhp<%]"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["xOffset"] = 2
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_HP"]["yOffset"] = -10
    
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["enable"] = true
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["justifyH"] = "RIGHT"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["size"] = 16
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["text_format"] = "[factioncolor][level]"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["xOffset"] = 0
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Level"]["yOffset"] = 10
    
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["enable"] = true
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["justifyH"] = "LEFT"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["size"] = 16
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["text_format"] = "[classcolor][name][realm:dash:translit]"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["xOffset"] = 2
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Name"]["yOffset"] = 10
    
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["attachTextTo"] = "Power"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["enable"] = true
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["justifyH"] = "LEFT"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["size"] = 14
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["text_format"] = "||cFF007ACC[curpp< || ][perpp<%]||r"
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["xOffset"] = 2
    E.db["unitframe"]["units"]["player"]["customTexts"]["A-UI_Power"]["yOffset"] = 0
    
    E.db["unitframe"]["units"]["player"]["debuffs"]["attachTo"] = "BUFFS"
    E.db["unitframe"]["units"]["player"]["disableMouseoverGlow"] = true
    E.db["unitframe"]["units"]["player"]["healPrediction"]["absorbStyle"] = "NORMAL"
    E.db["unitframe"]["units"]["player"]["health"]["position"] = "RIGHT"
    E.db["unitframe"]["units"]["player"]["health"]["smoothbars"] = true
    E.db["unitframe"]["units"]["player"]["health"]["text_format"] = ""
    E.db["unitframe"]["units"]["player"]["health"]["xOffset"] = -2
    E.db["unitframe"]["units"]["player"]["height"] = 40
    E.db["unitframe"]["units"]["player"]["name"]["position"] = "TOPRIGHT"
    E.db["unitframe"]["units"]["player"]["name"]["xOffset"] = -2
    E.db["unitframe"]["units"]["player"]["name"]["yOffset"] = -2
    E.db["unitframe"]["units"]["player"]["portrait"]["overlayAlpha"] = 0.3
    E.db["unitframe"]["units"]["player"]["power"]["attachTextTo"] = "Power"
    E.db["unitframe"]["units"]["player"]["power"]["detachFromFrame"] = true
    E.db["unitframe"]["units"]["player"]["power"]["detachedWidth"] = 220
    E.db["unitframe"]["units"]["player"]["power"]["height"] = 14
    E.db["unitframe"]["units"]["player"]["power"]["position"] = "LEFT"
    E.db["unitframe"]["units"]["player"]["power"]["powerPrediction"] = true
    E.db["unitframe"]["units"]["player"]["power"]["smoothbars"] = true
    E.db["unitframe"]["units"]["player"]["power"]["text_format"] = ""
    E.db["unitframe"]["units"]["player"]["power"]["xOffset"] = 2
    if E.db["unitframe"]["units"]["player"]["pvp"] then E.db["unitframe"]["units"]["player"]["pvp"]["position"] = "TOP" end
    if E.db["unitframe"]["units"]["player"]["pvpIcon"] then
        E.db["unitframe"]["units"]["player"]["pvpIcon"]["anchorPoint"] = "BOTTOMRIGHT"
        E.db["unitframe"]["units"]["player"]["pvpIcon"]["enable"] = true
        E.db["unitframe"]["units"]["player"]["pvpIcon"]["scale"] = 0.95
        E.db["unitframe"]["units"]["player"]["pvpIcon"]["xOffset"] = 14
        E.db["unitframe"]["units"]["player"]["pvpIcon"]["yOffset"] = -10
    end
    E.db["unitframe"]["units"]["player"]["width"] = 220

    -- RAID 1 (Group Frame)
    E.db["unitframe"]["units"]["raid1"]["colorOverride"] = "FORCE_OFF"
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["enable"] = true
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["font"] = "Expressway"
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["justifyH"] = "CENTER"
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["size"] = 14
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["text_format"] = "[group]"
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["xOffset"] = 38
    E.db["unitframe"]["units"]["raid1"]["customTexts"]["A-UI_GrpNR"]["yOffset"] = 6
    E.db["unitframe"]["units"]["raid1"]["growthDirection"] = "RIGHT_UP"
    E.db["unitframe"]["units"]["raid1"]["height"] = 35
    E.db["unitframe"]["units"]["raid1"]["infoPanel"]["enable"] = true
    E.db["unitframe"]["units"]["raid1"]["name"]["attachTextTo"] = "InfoPanel"
    E.db["unitframe"]["units"]["raid1"]["name"]["position"] = "BOTTOMLEFT"
    E.db["unitframe"]["units"]["raid1"]["name"]["xOffset"] = 2
    E.db["unitframe"]["units"]["raid1"]["numGroups"] = 8
    E.db["unitframe"]["units"]["raid1"]["rdebuffs"]["font"] = "Expressway"
    E.db["unitframe"]["units"]["raid1"]["rdebuffs"]["size"] = 30
    E.db["unitframe"]["units"]["raid1"]["rdebuffs"]["xOffset"] = 30
    E.db["unitframe"]["units"]["raid1"]["rdebuffs"]["yOffset"] = 25
    if E.db["unitframe"]["units"]["raid1"]["readycheckIcon"] then E.db["unitframe"]["units"]["raid1"]["readycheckIcon"]["size"] = 23 end
    if E.db["unitframe"]["units"]["raid1"]["resurrectIcon"] then E.db["unitframe"]["units"]["raid1"]["resurrectIcon"]["attachTo"] = "BOTTOMRIGHT" end
    if E.db["unitframe"]["units"]["raid1"]["roleIcon"] then
        E.db["unitframe"]["units"]["raid1"]["roleIcon"]["attachTo"] = "InfoPanel"
        E.db["unitframe"]["units"]["raid1"]["roleIcon"]["damager"] = false
        E.db["unitframe"]["units"]["raid1"]["roleIcon"]["size"] = 18
        E.db["unitframe"]["units"]["raid1"]["roleIcon"]["xOffset"] = 0
    end
    E.db["unitframe"]["units"]["raid1"]["width"] = 90

    -- RAID 2
    E.db["unitframe"]["units"]["raid2"]["colorOverride"] = "FORCE_OFF"
    E.db["unitframe"]["units"]["raid2"]["height"] = 30
    E.db["unitframe"]["units"]["raid2"]["rdebuffs"]["font"] = "Expressway"
    if E.db["unitframe"]["units"]["raid2"]["roleIcon"] then
        E.db["unitframe"]["units"]["raid2"]["roleIcon"]["damager"] = false
        E.db["unitframe"]["units"]["raid2"]["roleIcon"]["enable"] = true
    end

    -- RAID 3
    E.db["unitframe"]["units"]["raid3"]["colorOverride"] = "FORCE_OFF"
    E.db["unitframe"]["units"]["raid3"]["customTexts"]["EltreumRaid3Name"]["enable"] = true
    E.db["unitframe"]["units"]["raid3"]["customTexts"]["EltreumRaid3Name"]["text_format"] = "[namecolor][name:eltruism:abbreviateshort]"
    E.db["unitframe"]["units"]["raid3"]["rdebuffs"]["font"] = "Expressway"

    -- TANK
    if E.db["unitframe"]["units"]["tank"] then
        E.db["unitframe"]["units"]["tank"]["colorOverride"] = "FORCE_OFF"
        E.db["unitframe"]["units"]["tank"]["name"]["text_format"] = "[namecolor][name:eltruism:abbreviate]"
    end

    -- TARGET
    if E.db["unitframe"]["units"]["target"]["CombatIcon"] then
        E.db["unitframe"]["units"]["target"]["CombatIcon"]["size"] = 32
        E.db["unitframe"]["units"]["target"]["CombatIcon"]["texture"] = "Eltruism16"
        E.db["unitframe"]["units"]["target"]["CombatIcon"]["xOffset"] = -8
    end
    E.db["unitframe"]["units"]["target"]["aurabar"]["enable"] = false
    E.db["unitframe"]["units"]["target"]["auras"]["anchorPoint"] = "TOPLEFT"
    E.db["unitframe"]["units"]["target"]["auras"]["enable"] = false
    E.db["unitframe"]["units"]["target"]["auras"]["filter"] = "HELPFUL"
    E.db["unitframe"]["units"]["target"]["auras"]["perrow"] = 8
    E.db["unitframe"]["units"]["target"]["auras"]["priority"] = ""
    E.db["unitframe"]["units"]["target"]["auras"]["sizeOverride"] = 0
    E.db["unitframe"]["units"]["target"]["auras"]["xOffset"] = 0
    E.db["unitframe"]["units"]["target"]["buffs"]["anchorPoint"] = "TOPLEFT"
    E.db["unitframe"]["units"]["target"]["buffs"]["growthX"] = "RIGHT"
    E.db["unitframe"]["units"]["target"]["buffs"]["priority"] = "Blacklist,Whitelist,blockNoDuration,Personal,NonPersonal"
    E.db["unitframe"]["units"]["target"]["castbar"]["insideInfoPanel"] = false
    E.db["unitframe"]["units"]["target"]["castbar"]["smoothbars"] = true
    E.db["unitframe"]["units"]["target"]["castbar"]["width"] = 220
    E.db["unitframe"]["units"]["target"]["colorOverride"] = "FORCE_OFF"
    
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["enable"] = true
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["justifyH"] = "RIGHT"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["size"] = 16
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["text_format"] = "[classcolor][curhp< || ][perhp<%]"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["xOffset"] = -2
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_HP"]["yOffset"] = -10
    
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["enable"] = true
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["justifyH"] = "LEFT"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["size"] = 16
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["text_format"] = "[difficulty][level]"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["xOffset"] = 2
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Level"]["yOffset"] = 10
    
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["enable"] = true
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["justifyH"] = "RIGHT"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["size"] = 16
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["text_format"] = "[classcolor][name:abbrev:medium]"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["xOffset"] = -2
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Name"]["yOffset"] = 10
    
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["attachTextTo"] = "Power"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["enable"] = true
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["justifyH"] = "RIGHT"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["size"] = 14
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["text_format"] = "||cFF007ACC[curpp< || ][perpp<%]||r"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["xOffset"] = -2
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Power"]["yOffset"] = 0
    
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["attachTextTo"] = "Health"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["enable"] = true
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["font"] = "PT Sans Narrow"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["fontOutline"] = "SHADOW"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["justifyH"] = "LEFT"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["size"] = 16
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["text_format"] = "[threat]"
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["xOffset"] = 2
    E.db["unitframe"]["units"]["target"]["customTexts"]["A-UI_Threat"]["yOffset"] = -16
    
    E.db["unitframe"]["units"]["target"]["debuffs"]["anchorPoint"] = "TOPLEFT"
    E.db["unitframe"]["units"]["target"]["debuffs"]["growthX"] = "RIGHT"
    E.db["unitframe"]["units"]["target"]["debuffs"]["maxDuration"] = 0
    E.db["unitframe"]["units"]["target"]["debuffs"]["perrow"] = 6
    E.db["unitframe"]["units"]["target"]["debuffs"]["priority"] = "Blacklist,Personal,NonPersonal"
    E.db["unitframe"]["units"]["target"]["debuffs"]["sizeOverride"] = 36
    if E.db["unitframe"]["units"]["target"]["debuffs"]["sourceText"] then E.db["unitframe"]["units"]["target"]["debuffs"]["sourceText"]["class"] = false end
    E.db["unitframe"]["units"]["target"]["disableMouseoverGlow"] = true
    E.db["unitframe"]["units"]["target"]["healPrediction"]["absorbStyle"] = "NORMAL"
    E.db["unitframe"]["units"]["target"]["health"]["smoothbars"] = true
    E.db["unitframe"]["units"]["target"]["health"]["text_format"] = ""
    E.db["unitframe"]["units"]["target"]["height"] = 40
    E.db["unitframe"]["units"]["target"]["name"]["position"] = "TOPRIGHT"
    E.db["unitframe"]["units"]["target"]["name"]["text_format"] = ""
    E.db["unitframe"]["units"]["target"]["name"]["xOffset"] = -2
    E.db["unitframe"]["units"]["target"]["name"]["yOffset"] = -2
    E.db["unitframe"]["units"]["target"]["orientation"] = "LEFT"
    E.db["unitframe"]["units"]["target"]["portrait"]["overlayAlpha"] = 0.3
    E.db["unitframe"]["units"]["target"]["power"]["attachTextTo"] = "Power"
    E.db["unitframe"]["units"]["target"]["power"]["detachFromFrame"] = true
    E.db["unitframe"]["units"]["target"]["power"]["detachedWidth"] = 220
    E.db["unitframe"]["units"]["target"]["power"]["height"] = 14
    E.db["unitframe"]["units"]["target"]["power"]["powerPrediction"] = true
    E.db["unitframe"]["units"]["target"]["power"]["smoothbars"] = true
    E.db["unitframe"]["units"]["target"]["power"]["text_format"] = ""
    if E.db["unitframe"]["units"]["target"]["privateAuras"] then
        E.db["unitframe"]["units"]["target"]["privateAuras"]["duration"]["enable"] = true
        E.db["unitframe"]["units"]["target"]["privateAuras"]["enable"] = true
    end
    if E.db["unitframe"]["units"]["target"]["raidRoleIcons"] then E.db["unitframe"]["units"]["target"]["raidRoleIcons"]["yOffset"] = 0 end
    if E.db["unitframe"]["units"]["target"]["resurrectIcon"] then E.db["unitframe"]["units"]["target"]["resurrectIcon"]["size"] = 34 end
    E.db["unitframe"]["units"]["target"]["width"] = 220

    -- TARGET TARGET & TARGET TARGET TARGET
    E.db["unitframe"]["units"]["targettarget"]["colorOverride"] = "FORCE_OFF"
    E.db["unitframe"]["units"]["targettarget"]["debuffs"]["enable"] = false
    E.db["unitframe"]["units"]["targettarget"]["disableMouseoverGlow"] = true
    E.db["unitframe"]["units"]["targettarget"]["health"]["smoothbars"] = true
    E.db["unitframe"]["units"]["targettarget"]["height"] = 30
    E.db["unitframe"]["units"]["targettarget"]["power"]["enable"] = false
    if E.db["unitframe"]["units"]["targettarget"]["raidicon"] then
        E.db["unitframe"]["units"]["targettarget"]["raidicon"]["attachTo"] = "LEFT"
        E.db["unitframe"]["units"]["targettarget"]["raidicon"]["enable"] = false
        E.db["unitframe"]["units"]["targettarget"]["raidicon"]["xOffset"] = 2
        E.db["unitframe"]["units"]["targettarget"]["raidicon"]["yOffset"] = 0
    end
    E.db["unitframe"]["units"]["targettarget"]["threatStyle"] = "GLOW"
    E.db["unitframe"]["units"]["targettarget"]["width"] = 128

    if E.db["unitframe"]["units"]["targettargettarget"] then
        E.db["unitframe"]["units"]["targettargettarget"]["debuffs"]["enable"] = false
        E.db["unitframe"]["units"]["targettargettarget"]["enable"] = true
        E.db["unitframe"]["units"]["targettargettarget"]["health"]["smoothbars"] = true
        E.db["unitframe"]["units"]["targettargettarget"]["height"] = 20
        E.db["unitframe"]["units"]["targettargettarget"]["power"]["enable"] = false
        E.db["unitframe"]["units"]["targettargettarget"]["width"] = 128
    end

    -- =====================================================================
    -- 3. SMARTE FALLBACKS (Korrektur, falls Plugins fehlen)
    -- =====================================================================
    if not hasEltruism then
        if E.db.unitframe.units.boss and E.db.unitframe.units.boss.health then 
            E.db.unitframe.units.boss.health.text_format = "[healthcolor][health:current-percent]" 
        end
        if E.db.unitframe.units.focus and E.db.unitframe.units.focus.name then 
            E.db.unitframe.units.focus.name.text_format = "[namecolor][name:medium]" 
        end
        if E.db.unitframe.units.party and E.db.unitframe.units.party.customTexts and E.db.unitframe.units.party.customTexts["A-UI_Status"] then
            E.db.unitframe.units.party.customTexts["A-UI_Status"].text_format = "[status]"
        end
        if E.db.unitframe.units.raid3 and E.db.unitframe.units.raid3.customTexts and E.db.unitframe.units.raid3.customTexts["EltreumRaid3Name"] then
            E.db.unitframe.units.raid3.customTexts["EltreumRaid3Name"] = nil
        end
        if E.db.unitframe.units.tank and E.db.unitframe.units.tank.name then 
            E.db.unitframe.units.tank.name.text_format = "[namecolor][name:medium]" 
        end
    end

    -- 4. ElvUI zwingen, das neue Profil live zu updaten
    E:UpdateAll(true)
    
    -- Setze den Installations-Marker
    E.db.AUI.install_version = "1.0"
    
    -- 5. Automatisch auf den Endscreen wechseln
    PI:SetPage(4)
end

local function Step3()
    PluginInstallFrame.SubTitle:Show()
    PluginInstallFrame.SubTitle:SetText(L["Layout Installation"])
    
    PluginInstallFrame.Desc1:Show()
    PluginInstallFrame.Desc1:SetText(L["Click the button below to install the A-UI main profile."])
    
    PluginInstallFrame.Desc2:Show()
    PluginInstallFrame.Desc2:SetText(L["Profile tags are calculated live and adjusted to your installed addons."])
    
    PluginInstallFrame.Desc3:Hide()
    
    PluginInstallFrame.Option1:Show()
    PluginInstallFrame.Option1:SetText(L["Install Layout"])
    PluginInstallFrame.Option1:SetScript("OnClick", InstallLayout)
    
    PluginInstallFrame.Option2:Hide()
end

-- =====================================================================
-- SEITE 4: ENDSCREEN
-- =====================================================================
local function Step4()
    PluginInstallFrame.SubTitle:Show()
    PluginInstallFrame.SubTitle:SetText(L["Installation Complete"])
    
    PluginInstallFrame.Desc1:Show()
    PluginInstallFrame.Desc1:SetText(L["Your A-UI layout has been successfully configured!"])
    
    PluginInstallFrame.Desc2:Show()
    local readyText = isRetail and "All supported plugins have been considered and your interface is now ready for Midnight." or "All supported plugins have been considered and your interface is now ready for TBC Classic."
    PluginInstallFrame.Desc2:SetText(readyText)
    
    PluginInstallFrame.Desc3:Show()
    PluginInstallFrame.Desc3:SetText(L["Have fun and good loot!"])
    
    PluginInstallFrame.Option1:Show()
    PluginInstallFrame.Option1:SetText(L["Close"] or "Schließen")
    PluginInstallFrame.Option1:SetScript("OnClick", function()
        PluginInstallFrame:Hide()
        ReloadUI()
    end)
    PluginInstallFrame.Option2:Hide()
end

-- =====================================================================
-- INSTALLER REGISTRIEREN
-- =====================================================================
AUI.InstallerData = {
    Title = "|cff00ffd2A-UI|r " .. (L["Installation"] or "Installation"),
    Name = "A-UI",
    Pages = {
        [1] = Step1,
        [2] = Step2,
        [3] = Step3,
        [4] = Step4,
    },
    Step1 = Step1,
    Step2 = Step2,
    Step3 = Step3,
    Step4 = Step4
}

function AUI:RunInstaller()
    PI:Queue(AUI.InstallerData)
end

E:RegisterChatCommand("aui", function() AUI:RunInstaller() end)