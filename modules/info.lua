local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

local addonName = "ElvUI_A-UI" 

local function CreateInfoTab()
    if not E.Options.args.AUI then return end

    -- Version live aus der .toc auslesen
    local currentVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "Unknown"
    
    -- Automatische Spracherkennung für den Changelog-Text
    local locale = GetLocale()
    local changelogText = AUI.Changelog_enUS
    if locale == "deDE" then
        changelogText = AUI.Changelog_deDE
    end
    
    -- Untertitel und Header-Grafik zusammenbauen
    local subtitleText = L["AUI_SUBTITLE"] or "A-UI ist eine Sammlung von convenience Addons."
    local headerString = string.format("|TInterface\\AddOns\\ElvUI_A-UI\\media\\A-UI.tga:32:32:0:0|t  |cff00ffd2A-UI Version %s by Ahrok|r\n\n%s", currentVersion, subtitleText)

    E.Options.args.AUI.args.infoTab = {
        order = 100,
        type = "group",
        name = "|cff00ffd2" .. (L["Info & Help"] or "Info & Hilfe") .. "|r",
        args = {
            -- 1. HEADER (Logo + Untertitel)
            headerDesc = {
                order = 1, type = "description", fontSize = "medium",
                name = headerString, width = "full",
            },
            spacer1 = { order = 2, type = "description", name = " ", width = "full" },
            
            -- 2. CREDITS
            creditsHeader = { order = 3, type = "header", name = L["Credits & Inspiration"] or "Credits & Inspiration" },
            creditsDesc = {
                order = 4, type = "description", fontSize = "medium",
                name = L["AUI_CREDITS_TEXT"] or "Ein riesiges Dankeschön geht an...",
                width = "full",
            },
            spacer2 = { order = 5, type = "description", name = " ", width = "full" },

            -- 3. F.A.Q.
            faqHeader = { order = 6, type = "header", name = L["F.A.Q. (Frequently Asked Questions)"] or "F.A.Q." },
            faqDesc1 = {
                order = 7, type = "description", fontSize = "medium",
                name = "|cffffd100" .. (L["Question: How do I move the microbar?"] or "Frage: Wie verschiebe ich die Microbar?") .. "|r\n" .. (L["Answer: Open the ElvUI toggle anchors mode and move the 'A-UI Microbar' anchor."] or "Antwort: Öffne den ElvUI Installations-Modus...") .. "\n",
                width = "full",
            },
            faqDesc2 = {
                order = 8, type = "description", fontSize = "medium",
                name = "|cffffd100" .. (L["Question: Why are some tooltips missing?"] or "Frage: Warum fehlen manche Tooltips?") .. "|r\n" .. (L["Answer: Make sure you have enabled the extended tooltips in the microbar options."] or "Antwort: Stelle sicher, dass du...") .. "\n",
                width = "full",
            },
            spacer3 = { order = 9, type = "description", name = " ", width = "full" },

            -- 4. CHANGELOG
            changelogHeader = { order = 10, type = "header", name = L["Changelog"] or "Changelog" },
            changelogDesc = {
                order = 11, type = "description", fontSize = "medium",
                name = (changelogText or L["No changelog text found."]),
                width = "full",
            },
            spacer4 = { order = 12, type = "description", name = " ", width = "full" },
            
            -- 5. LINKS
            linkHeader = { order = 13, type = "header", name = "Links" },
            tukuiLink = {
                order = 14, type = "input", width = "full",
                name = "Tukui Community",
                get = function() return "https://www.tukui.org/" end,
                set = function() end, -- Machts Read-Only! So kann man den Link zwar markieren & kopieren, aber nicht versehentlich überschreiben
            }
        }
    }
end

hooksecurefunc(AUI, "InsertOptions", CreateInfoTab)