local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

-- =====================================================================
-- CHANGELOG (DEUTSCH)
-- =====================================================================
AUI.Changelog_deDE = [[
|cff00ffd2Version 1.2.0|r
• |cffffd100Alts Dashboard:|r
  - TBC Classic: Automatische Rollen-Erkennung (Tank, Heal, DPS) anhand der Talentbäume.
  - Notizen-Funktion: Rechtsklick auf einen Charakter öffnet ein Fenster zum Hinzufügen, Bearbeiten oder Löschen von Notizen.
  - Tabellen-Layout optimiert und ungenutzte Spalten entfernt.
  - Neuer 3-Farben-Farbverlauf für den Rahmen des Alts-Fensters (Top & Bottom Panel Stil).

• |cffffd100Coloring & Rahmen:|r
  - Chat EditBox: Option hinzugefügt, um den Rahmen des Texteingabefelds im linken Chat mit Klassenfarbe oder Farbverläufen einzufärben.
  - Alts-Dashboard: Vollständige Integration in das Coloring-Menü mit Unterstützung für Klassenverläufe und eigene Farben.

• |cffffd100Lokalisierung & Optionen:|r
  - Vollständige deutsche und englische Synchronisierung aller Menüs (Installer, Microbar-Tooltips, Optik-Einstellungen).
  - Doppelten "Info & Help"-Reiter in den ElvUI-Optionen behoben.
  - Versionsanzeige in der ElvUI-Kopfzeile sauber über LibElvUIPlugin angebunden.

• |cffffd100Stabilität & Kompatibilität:|r
  - Client-Weichen für TBC Classic und Retail (Midnight) weiter verfeinert.
  - Tooltip-Berechnungen und Datatext-Hooks gegen seltene Nil-Fehler abgesichert.
]]

-- =====================================================================
-- CHANGELOG (ENGLISCH)
-- =====================================================================
AUI.Changelog_enUS = [[
|cff00ffd2Version 1.2.0|r
• |cffffd100Alts Dashboard:|r
  - TBC Classic: Automatic role detection (Tank, Heal, DPS) based on talent tree point distribution.
  - Interactive Notes: Right-click any character row to add, edit, or remove custom notes.
  - Optimized table layout and removed unused columns.
  - Added 3-color gradient border styling matching the Top & Bottom panels.

• |cffffd100Coloring & Borders:|r
  - Chat EditBox: Added setting to apply class colors or gradients to the text input box border.
  - Alts Dashboard: Full integration into the Coloring settings with class gradient and custom color support.

• |cffffd100Localization & Options:|r
  - Full synchronization of English and German localizations across all installer, tooltip, and design settings.
  - Resolved the duplicate "Info & Help" tab issue in AceConfig.
  - Plugin version display cleanly hooked into the ElvUI header via LibElvUIPlugin.

• |cffffd100Stability & Cross-Client:|r
  - Refined client checks for TBC Classic and Retail (Midnight).
  - Hardened tooltip calculations and DataText font hooks against nil errors.
]]