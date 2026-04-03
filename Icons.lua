local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

AUI.MicroIcons = {
    { name = L["Character"],       id = "portrait", blizzBtn = "CharacterMicroButton" },
    { name = L["Professions"],     id = "Interface\\Icons\\INV_Misc_Book_09",     blizzBtn = "ProfessionMicroButton" },
    { name = L["Talents"],         id = "Interface\\Icons\\Ability_Marksmanship", blizzBtn = "PlayerSpellsMicroButton" },
    { name = L["Achievements"],    id = "Interface\\Icons\\Achievement_GuildPerk_HonorableMention", blizzBtn = "AchievementMicroButton" },
    { name = L["Questlog"],        id = "Interface\\Icons\\INV_Scroll_03",        blizzBtn = "QuestLogMicroButton" },
    { name = L["Housing"],         id = "Interface\\Icons\\INV_Garrison_Hearthstone", blizzBtn = "HousingMicroButton" },
    { name = L["Guild"],           id = "Interface\\Icons\\INV_Shirt_GuildTabard_01", blizzBtn = "GuildMicroButton" },
    { name = L["Collections"],     id = "Interface\\Icons\\Ability_Mount_RidingHorse",blizzBtn = "CollectionsMicroButton" },
    { name = L["LFD"],             id = "Interface\\Icons\\INV_Misc_Eye_01",      blizzBtn = "LFDMicroButton" },
    { name = L["Store"],           id = "Interface\\Icons\\WoW_Token01",          blizzBtn = "StoreMicroButton" },
    { name = L["Adventure"],       id = "Interface\\Icons\\INV_Misc_Book_11",     blizzBtn = "EJMicroButton" },
    { name = L["Menu"],            id = "Interface\\Icons\\INV_Misc_Gear_01",     blizzBtn = "MainMenuMicroButton" },
    { name = L["Mail"],            id = "Interface\\Icons\\INV_Letter_15",        blizzBtn = "AUI_MailButton" },
    { name = L["Calendar"],        id = "dynamic_a",                              blizzBtn = "AUI_CalendarButton" },
    { name = L["Teleports"] or "Teleporte", id = "134414",                        blizzBtn = "AUI_TeleportButton" },
}

AUI.CuratedIconsList = {
    [1] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material12.tga"] = "Material", ["Interface\\Icons\\Achievement_Character_Human_Male"] = L["Human"], ["Interface\\Icons\\Achievement_Character_Orc_Male"] = L["Orc"] },
    [2] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material25.tga"] = "Material", ["Interface\\Icons\\Trade_Blacksmithing"] = L["Anvil & Hammer"], ["Interface\\Icons\\INV_Misc_Book_08"] = L["Blue Book"], ["Interface\\Icons\\INV_Misc_Book_07"] = L["Green Book"] },
    [3] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material07.tga"] = "Material", ["Interface\\Icons\\Spell_Nature_NatureTouchGrow"] = L["Classic (Talent Tree)"], ["Interface\\Icons\\Trade_Engineering"] = L["Gears"], ["Interface\\Icons\\Spell_Holy_HolySmite"] = L["Holy"] },
    [4] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material01.tga"] = "Material", ["Interface\\Icons\\Achievement_Arena_2v2_1"] = L["Chalice"], ["Interface\\Icons\\INV_Jewelry_Talisman_08"] = L["Amulet"], ["Interface\\Icons\\Achievement_Quests_Completed_08"] = L["Scroll"] },
    [5] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material32.tga"] = "Material", ["Interface\\Icons\\INV_Misc_Map02"] = L["Map"], ["Interface\\Icons\\INV_Scroll_05"] = L["Sealed Parchment"], ["Interface\\Icons\\INV_Scroll_06"] = L["Open Parchment"] },
    [6] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material04.tga"] = "Material", ["Interface\\Icons\\INV_Misc_Key_03"] = L["Golden Key"], ["Interface\\Icons\\INV_Misc_Key_14"] = L["Silver Key"], ["Interface\\Icons\\Trade_Archaeology_Dwarven_InnkeeperSign"] = L["Tavern Sign"] },
    [7] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material05.tga"] = "Material", ["Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend"] = L["Handshake"], ["Interface\\Icons\\Achievement_Guild_Level10"] = L["Guild Shield"], ["Interface\\Icons\\INV_Misc_Tournaments_banner_Human"] = L["Banner"] },
    [8] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material52.tga"] = "Material", ["Interface\\Icons\\Tracking_WildPet"] = L["Pet Paw"], ["Interface\\Icons\\Ability_Mount_Gryphon_01"] = L["Gryphon"], ["Interface\\Icons\\Ability_Mount_Wyvern_01"] = L["Wyvern"] },
    [9] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material48.tga"] = "Material", ["Interface\\Icons\\Ability_Warrior_ShieldWall"] = L["Shield"], ["Interface\\Icons\\Achievement_BG_winWSG"] = L["PvP (Swords)"], ["Interface\\Icons\\INV_Misc_GroupNeedMore"] = L["Group Search"] },
    [10] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material59.tga"] = "Material", ["Interface\\Icons\\INV_Misc_Coin_01"] = L["Gold Coin"], ["Interface\\Icons\\INV_Misc_Coin_02"] = L["Copper Coins"], ["Interface\\Icons\\INV_Misc_Bag_11"] = L["Gold Sack"] },
    [11] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material22.tga"] = "Material", ["Interface\\Icons\\INV_Misc_Map_01"] = L["Compass & Map"], ["Interface\\Icons\\INV_Misc_Spyglass_02"] = L["Spyglass"], ["Interface\\Icons\\INV_Misc_Note_01"] = L["Journal"] },
    [12] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material06.tga"] = "Material", ["Interface\\Icons\\Trade_Engineering"] = L["Yellow Gear"], ["Interface\\Icons\\INV_Misc_Wrench_01"] = L["Wrench"], ["Interface\\Icons\\INV_Misc_PunchCards_Yellow"] = L["Punch Card"] },
    [13] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material15.tga"] = "Material", ["Interface\\Icons\\INV_Letter_15"] = L["Envelope"], ["Interface\\Icons\\INV_Letter_18"] = L["Package"] },
    [14] = { 
        ["dynamic_a"] = "Material", 
        ["dynamic_b"] = L["Red"], 
        ["dynamic_c"] = L["Blue"]
    },
    [15] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material21.tga"] = "Material", ["Interface\\Icons\\Spell_Arcane_TeleportDalaran"] = L["Portal"] },
    [16] = { [""] = L["Default"], ["Interface\\AddOns\\ElvUI_A-UI\\media\\material\\material42.tga"] = "Material", ["Interface\\Icons\\inv_misc_bag_08"] = L["Curio"] },
}