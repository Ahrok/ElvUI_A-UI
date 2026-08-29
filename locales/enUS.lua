local E = unpack(ElvUI)
local L = E.Libs.ACL:NewLocale("ElvUI", "enUS", true, true)

-- =====================================================================
-- 1. GENERAL, INFO & CHANGELOG
-- =====================================================================
L["AUI_SUBTITLE"] = "A-UI is a lightweight convenience and quality-of-life plugin collection for ElvUI."
L["AUI_CREDITS_TEXT"] = "A huge thank you goes to the Tukui & ElvUI community, all addon developers, and everyone testing and providing feedback!"
L["Info & Help"] = true
L["Credits & Inspiration"] = true
L["F.A.Q. (Frequently Asked Questions)"] = true
L["Question: How do I move the microbar?"] = true
L["Answer: Open the ElvUI toggle anchors mode and move the 'A-UI Microbar' anchor."] = true
L["Question: Why are some tooltips missing?"] = true
L["Answer: Make sure you have enabled the extended tooltips in the microbar options."] = true
L["Changelog"] = true
L["No changelog text found."] = true

-- =====================================================================
-- 2. INSTALLER & PROFILE SETUP
-- =====================================================================
L["Welcome to A-UI"] = true
L["Thank you for choosing A-UI!"] = true
L["This short setup will configure your interface and ensure all required plugins are present."] = true
L["Click 'Continue' below to proceed, or 'Close' to abort."] = true
L["System and Plugin Check"] = true
L["A-UI uses synergies with other ElvUI plugins. Here is the status of your system:"] = true
L[" (Installed & Active)"] = true
L[" (Missing - Recommended!)"] = true
L["Don't worry: If plugins are missing, A-UI will automatically adjust the layout to prevent errors."] = true
L["Click the button below to install the A-UI main profile."] = true
L["Profile tags are calculated live and adjusted to your installed addons."] = true
L["Install Layout"] = true
L["Installation Complete"] = true
L["Your A-UI layout has been successfully configured!"] = true
L["All supported plugins have been considered and your interface is now ready for Midnight."] = true
L["All supported plugins have been considered and your interface is now ready for TBC Classic."] = true
L["Have fun and good loot!"] = true
L["Close"] = true
L["Installation"] = true
L["A-UI Installer"] = true
L["A-UI Installation & Profile"] = true
L["A-UI uses synergies with the following ElvUI plugins:\n\n"] = true
L["Active"] = "Active"
L["Missing"] = "Missing"
L["Layout Installation"] = true
L["Run the installer to apply the standard A-UI layout to this character (frame positions, custom texts, etc.).\n"] = true
L["Start Installer"] = true
L["Profile Transfer"] = true
L["Here you can export or import only your specific A-UI settings (microbar, icons, tooltips) as text.\n"] = true
L["Export"] = true
L["Import"] = true
L["Profile: "] = true
L["Copy the string with Ctrl+C:"] = true
L["1. Paste the profile string here (Ctrl+V):"] = true
L["Cancel"] = true
L["Warning: LibDeflate not found. Using standard ElvUI export."] = true
L["Critical Error: Profile could not be converted to a string."] = true
L["Error: The text field is empty. Please paste a profile string."] = true
L["Settings were imported into the active profile."] = true
L["|cffff0000Critical error during import!|r"] = true
L["The pasted string is invalid, incomplete, or does not originate from A-UI."] = true

-- =====================================================================
-- 3. OPTIONS, MICROBAR & TOOLTIP DESIGN
-- =====================================================================
L["Enable"] = true
L["Size"] = true
L["Spacing"] = true
L["Per Row"] = true
L["Reverse Order"] = true
L["Main Bar"] = true
L["Padding"] = true
L["Backdrop"] = true
L["Alpha"] = true
L["Colorize"] = true
L["Class Color"] = true
L["Custom Color"] = true
L["Color"] = true
L["Border"] = true
L["Buttons"] = true
L["Visibility"] = true
L["Show on Mouseover"] = true
L["Show Mail Button"] = true
L["Hide if Empty"] = true
L["Show Calendar Button"] = true
L["Show Teleport Button"] = true
L["Macro Conditionals"] = true
L["Icon Effects"] = true
L["Notifications"] = true
L["Talent Glow"] = true
L["Vault Glow"] = true
L["Calendar Glow"] = true
L["Collections Glow"] = true
L["Mail Glow"] = true
L["Enable Glow Effects"] = true
L["Global Glow Effect"] = true
L["Pixel Glow"] = true
L["AutoCast Glow"] = true
L["Blizzard Standard"] = true
L["Colorize on Mail"] = true
L["Animations"] = true
L["Fish-Eye Hover"] = true
L["Icon Selection"] = true
L["Colors"] = true
L["Desaturate All"] = true
L["Color All"] = true
L["Icon Customization"] = true
L["Choose icons and individual colors below."] = true
L["Default"] = true
L["Color Mode"] = true
L["Coloring"] = true

-- Tooltip Options & Styles
L["Icon Tooltips"] = true
L["Configure extended information displayed in the tooltips of each button.\n"] = true
L["Guild Roster"] = true
L["System Stats"] = true
L["Character Stats"] = true
L["Profession Stats"] = true
L["Talent Stats"] = true
L["Adventure Guide Stats"] = true
L["Group Finder Stats"] = true
L["Appearance"] = true
L["Headers"] = true
L["Font Size"] = true
L["Default (Gold)"] = true

-- =====================================================================
-- 4. COLORING (DATATEXTS & BORDERS)
-- =====================================================================
L["DataTexts"] = true
L["Gradient"] = true
L["Class Gradient"] = true
L["Color 1 (Start)"] = true
L["Color 2 (End)"] = true
L["Top & Bottom Panels"] = true
L["Left Chat"] = true
L["Right Chat"] = true
L["Minimap"] = true
L["Color 1 (Left)"] = true
L["Color 2 (Center)"] = true
L["Color 3 (Right)"] = true
L["Invert Gradient"] = true
L["Gradient Direction"] = true
L["Horizontal (Left -> Right)"] = true
L["Horizontal (Right -> Left)"] = true
L["Vertical (Bottom -> Top)"] = true
L["Vertical (Top -> Bottom)"] = true
L["Colorize EditBox"] = true
L["Apply the same border coloring to the chat editbox."] = true
L["Alts Dashboard"] = true

-- =====================================================================
-- 5. BUTTON LABELS & CURATED ICON PRESETS
-- =====================================================================
L["Character"] = true
L["Professions"] = true
L["Talents"] = true
L["Spellbook"] = true
L["Achievements"] = true
L["Questlog"] = true
L["Housing"] = true
L["Guild"] = true
L["Collections"] = true
L["LFD"] = true
L["Group Finder"] = true
L["Store"] = true
L["Adventure"] = true
L["Menu"] = true
L["Help"] = true
L["Mail"] = true
L["Calendar"] = true
L["Teleports"] = true
L["Alts"] = true
L["Delves"] = true

L["Human"] = true
L["Orc"] = true
L["Anvil & Hammer"] = true
L["Blue Book"] = true
L["Green Book"] = true
L["Classic (Talent Tree)"] = true
L["Gears"] = true
L["Holy"] = true
L["Chalice"] = true
L["Amulet"] = true
L["Scroll"] = true
L["Map"] = true
L["Sealed Parchment"] = true
L["Open Parchment"] = true
L["Golden Key"] = true
L["Silver Key"] = true
L["Tavern Sign"] = true
L["Handshake"] = true
L["Guild Shield"] = true
L["Banner"] = true
L["Pet Paw"] = true
L["Gryphon"] = true
L["Wyvern"] = true
L["Shield"] = true
L["PvP (Swords)"] = true
L["Group Search"] = true
L["Gold Coin"] = true
L["Copper Coins"] = true
L["Gold Sack"] = true
L["Compass & Map"] = true
L["Spyglass"] = true
L["Journal"] = true
L["Yellow Gear"] = true
L["Wrench"] = true
L["Punch Card"] = true
L["Envelope"] = true
L["Package"] = true
L["Red"] = true
L["Blue"] = true
L["Portal"] = true
L["Curio"] = true
L["Masks"] = true
L["Question Mark"] = true

-- =====================================================================
-- 6. TOOLTIPS (MICROBAR & STATS)
-- =====================================================================
L["Primary Professions"] = "Primary Professions:"
L["Secondary Professions"] = "Secondary Professions:"
L["No professions learned."] = "No professions learned."
L["Primary Professions of %s"] = "Primary Professions of %s"
L["No primary professions learned."] = "No primary professions learned."
L["Current Specialization:"] = true
L["Active Build:"] = true
L["Loot Specialization:"] = true
L["Current Specialization"] = true
L["Talent Distribution (TBC):"] = "Talent Distribution (TBC):"
L["|cffffffff%d|r Points"] = "|cffffffff%d|r Points"
L["Available Talent Points: %d"] = "Available Talent Points: %d"
L["Guild & Communities"] = true
L["MOTD:"] = true
L["Online: "] = true
L["Note"] = true
L["Zone"] = true
L["Class & Level"] = true
L["more"] = true
L["Item Level:"] = true
L["Durability:"] = true
L["New Mail!"] = true
L["No Mail!"] = true
L["Mail from:"] = true
L["Daily Reset"] = "Daily Reset:"
L["Weekly Reset"] = "Weekly Reset:"
L["Saved Raids"] = "Saved Raids:"
L["Saved Dungeons"] = "Saved Dungeons:"
L["World Bosses"] = "World Bosses:"
L["Defeated"] = true
L["Home Latency:"] = true
L["World Latency:"] = true
L["Local Time:"] = true
L["Server Time:"] = true
L["Session:"] = true
L["Volume:"] = true
L["Addon Memory:"] = true

-- =====================================================================
-- 7. TELEPORTER MODULE
-- =====================================================================
L["Hearthstones"] = "Hearthstones & Items"
L["Toys"] = "Toys"
L["Engineering"] = "Engineering & Portals"
L["Racial Abilities"] = "Racial Abilities"
L["Death Knight"] = true
L["Druid"] = true
L["Monk"] = true
L["Shaman"] = true
L["Mage Teleports"] = "Mage Teleports"
L["Mage Portals"] = "Mage Portals"
L["Bind Location"] = "Bind Location: "
L["Cooldowns"] = "Cooldowns:"
L["No items found."] = "No items found."

-- =====================================================================
-- 8. TBC CLASSIC CURRENCIES & BADGES
-- =====================================================================
L["TBC PvE & PvP Badges:"] = "TBC PvE & PvP Badges:"
L["Badge of Justice"] = "Badge of Justice"
L["Honor Points"] = "Honor Points"
L["Arena Points"] = "Arena Points"
L["Battleground Marks:"] = "Battleground Marks:"
L["Warsong Gulch Mark of Honor"] = "Warsong Gulch Mark of Honor"
L["Arathi Basin Mark of Honor"] = "Arathi Basin Mark of Honor"
L["Alterac Valley Mark of Honor"] = "Alterac Valley Mark of Honor"
L["Eye of the Storm Mark of Honor"] = "Eye of the Storm Mark of Honor"

-- =====================================================================
-- 9. RETAIL MIDNIGHT CURRENCIES & DELVES
-- =====================================================================
L["Catalyst Charges:"] = true
L["PvE Crests:"] = true
L["Type"] = true
L["Owned"] = true
L["Earned"] = true
L["Source"] = true
L["Mythic"] = true
L["Hero"] = true
L["Champion"] = true
L["Veteran"] = true
L["Adventurer"] = true
L["Mythic, +9"] = true
L["Heroic, +4"] = true
L["Normal, +2"] = true
L["LFR"] = true
L["World Content"] = true
L["No Crests found."] = true
L["PvP Currencies:"] = true
L["Honor"] = true
L["Conquest"] = true
L["Bloody Tokens"] = true
L["Unrated PvP"] = true
L["Rated PvP"] = true
L["War Mode"] = true
L["Currencies:"] = true
L["Trader's Tender:"] = true
L["Bountiful Coins:"] = true
L["Coffer Key Shards:"] = true
L["Restored Coffer Key:"] = true
L["This Week"] = "this week"
L["Bountiful Delves (Active):"] = true
L["None (or all completed)"] = true
L["Midnight Factions:"] = true
L["Renown"] = true
L["Delve Companion:"] = true
L["Level"] = true
L["Season Progress:"] = true

-- =====================================================================
-- 10. ALTS DASHBOARD
-- =====================================================================
L["Class"] = true
L["Name"] = true
L["Realm"] = true
L["Spec"] = true
L["Role"] = true
L["Lvl"] = true
L["iLvl"] = true
L["Avg. iLvl"] = "Ø iLvl"
L["Playtime"] = true
L["Badges"] = true
L["Arena"] = true
L["PvP Rank"] = true
L["Notes / Details"] = true
L["Gold"] = true
L["Unspent"] = "Unspent"
L["Unknown"] = "Unknown"
L["Playtime (Account): |cffdddddd%s|r   |   Total Gold: |cff00ffd2%s|r"] = "Playtime (Account): |cffdddddd%s|r   |   Total Gold: |cff00ffd2%s|r"
L["Characters: |cff00ffd2%d|r"] = "Characters: |cff00ffd2%d|r"

-- =====================================================================
-- 11. DATATEXT & MAP PINS
-- =====================================================================
L["Left Click:"] = "Left-Click:"
L["Toggle Microbar"] = "Toggle Microbar"
L["Middle Click:"] = "Middle-Click:"
L["Open Alt Dashboard"] = "Open Alt Dashboard"
L["Right Click:"] = "Right-Click:"
L["Open Options"] = "Open Options"

L["World Map"] = true
L["Custom Map Pins"] = true
L["Enable Pins"] = true
L["Pin Size"] = true
L["Zoom-Out Factor"] = true
L["Zoom-In Factor"] = true
L["Click to Track"] = "Left-Click to track target"
L["Tracking"] = "Tracking"

L["Aldor Bank"] = "Bank of the Aldor"
L["Aldor Bank Desc"] = "Bank located in Aldor Tier"
L["Scryers Bank"] = "Bank of the Scryers"
L["Scryers Bank Desc"] = "Bank located on the Scryer's Tier"
L["Aldor Inn"] = "Aldor Inn"
L["Aldor Inn Desc"] = "Inn located in Aldor Tier"
L["Scryers Inn"] = "Scryer's Inn"
L["Scryers Inn Desc"] = "Inn located on Scryer's Tier"
L["Flight Master"] = "Flight Master"
L["Flight Master Desc"] = "Flight Master & Gryphons"
L["Capital Portals"] = "Capital Portals"
L["Capital Portals Desc"] = "Portals to Orgrimmar, Stormwind, etc."
L["Alchemy Lab"] = "Alchemy Lab"
L["Alchemy Lab Desc"] = "Special Alchemy Lab in Shattrath"
L["Blacksmithing / Mining"] = "Blacksmithing / Mining"
L["Blacksmithing Desc"] = "Forge & Anvil"
L["Jewelcrafting"] = "Jewelcrafting"
L["Jewelcrafting Desc"] = "Jewelcrafter & Supplies"
L["Leatherworking"] = "Leatherworking"
L["Leatherworking Desc"] = "Leatherworking & Skinning"
L["Bank of Silvermoon"] = "Bank of Silvermoon"
L["Bank Desc"] = "Royal Bank Vault"
L["Auction House"] = "Auction House"
L["Auction House Desc"] = "Bazaar Auction House"
L["Inn"] = "Inn"
L["Inn Desc"] = "Innkeeper & Rest"
L["Orb of Translocation"] = "Orb of Translocation"
L["Orb Desc"] = "Teleport to Undercity"
L["Alchemy"] = "Alchemy"
L["Blacksmithing"] = "Blacksmithing"
L["Enchanting"] = "Enchanting"
L["Engineering"] = "Engineering"
L["Tailoring"] = "Tailoring"
L["Mining"] = "Mining"
L["Herbalism"] = "Herbalism"
L["Inscription"] = "Inscription"
L["Profession Desc"] = "Trainer & Supplies"
L["Artisans Consortium"] = "Artisan's Consortium"
L["Consortium Desc"] = "Work Orders & Profession Hub"
L["Heirlooms & Transmog"] = "Heirlooms & Transmog"
L["Heirloom Desc"] = "Transmogrifier & Heirloom Vendor"
L["Item Upgrade"] = "Item Upgrade"
L["Upgrade Desc"] = "Upgrade Gear & Crests"
L["Stable Master"] = "Stable Master"
L["Stable Desc"] = "Pet Stables"
L["Catalyst"] = "Creation Catalyst"
L["Catalyst Desc"] = "Convert gear into Tier set pieces"
L["Delve Hub"] = "Delve Headquarters"
L["Delve Hub Desc"] = "Valeera & Brann Delve Hub"