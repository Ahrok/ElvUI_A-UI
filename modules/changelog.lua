local E, L, V, P, G = unpack(ElvUI)
local AUI = E:GetModule('A-UI')

-- =====================================================================
-- CHANGELOG (DEUTSCH)
-- =====================================================================
AUI.Changelog_deDE = [[
|cff00ffd2Version 1.3.0|r
• |cffffd100Neues Modul: Kalender (TBC Classic & Retail):|r
  - TBC Classic Kalender: Vollwertiger Kalender für Classic-Clients mit Monats-Rasteransicht und Microbar-Anbindung.
  - Dunkelmond-Jahrmarkt (DMF): Automatische Berechnung von Aufbau, aktiver Laufzeit und Standortwechsel (Mulgore, Goldhain, Shattrath).
  - Weltereignisse & Resets: Statische TBC-Feiertage (Braufest, Schlotternächte etc.) und automatische Mittwochs-Raidresets.
  - Termine & Notizen: Erstellen, Bearbeiten und Löschen von ganztägigen oder zeitbasierten Events mit Start-/Enddatum.
  - Farbcodierte Event-Balken: Bis zu 3 Event-Balken pro Tag mit benutzerdefinierter Rahmenfarbe via integriertem Farbwähler.
  - Vollständiges Löschen: Mehrtägige Terminserien können mit einem Klick über den gesamten Zeitraum entfernt werden.
  - Microbar-Tooltip: Kalender-Button zeigt aktive Weltereignisse und heutige Termine live im Tooltip an.

• |cffffd100Händlerfenster (Merchant):|r
  - Dynamisches Raster: Konfigurierbare Spalten- und Zeilenanzahl für das Händler- und Rückkauf-Fenster.
  - Suchfunktion: Integrierte Echtzeit-Suchleiste oben rechts zum Filtern von Items via Hervorhebung und Ausgrauen.
  - Layout-Optimierung: Relative Ankerpunkte verhindern verschobene Buttons und Abstandsfehler bei unterschiedlichen Fenstergrößen.

• |cffffd100Minimap Bag & Buttons:|r
  - Neues Minimap-Button-Sammelmodul (Minimap Bag) zur sauberen Kapselung von Addon-Minimap-Icons.
  - Layer- & Strata-Fix: Addon-Buttons rendern nun ohne Transparenzverlust oder Backdrop-Überlappung zuverlässig im Vordergrund.

• |cffffd100Erweitertes Coloring & Rahmen:|r
  - Neue Gradient-Optionen für Kalender, Charakterfenster, Stats-Panel, Inspect-Fenster und Minimap-Bag.
  - Ziel-Klassenfarben: Inspect-Rahmen unterstützt nun dynamische Zielfarben (Target Class & Target Class Gradient).
  - Volle Farbmodus-Unterstützung (Klassenfarbe, Verlauf, Eigene Farben) inkl. Richtung und Umkehrung.

• |cffffd100Alts Dashboard (Midnight & Spielzeit):|r
  - Tracking für gespielte Gesamtzeit (/played) via diskreter Serverabfrage ohne störende Chatmeldungen.
  - Neues Tracking für Katalysator-Aufladungen und Vorbereitung für Midnight-Währungen (Schlüssel & Wappen).
  - Absolute Pixel-Koordinaten für eine exakte Spaltenausrichtung im Tabellenkopf.

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
|cff00ffd2Version 1.3.0|r
• |cffffd100New Module: Calendar (TBC Classic & Retail):|r
  - TBC Classic Calendar: Dedicated monthly grid calendar for Classic clients hooked directly into the microbar.
  - Darkmoon Faire (DMF): Automatic tracking of setup, active duration, and location rotation (Mulgore, Goldshire, Shattrath).
  - World Events & Resets: Static TBC holidays (Brewfest, Hallow's End, etc.) and automatic Wednesday raid reset indicators.
  - Custom Events & Notes: Create, edit, and delete all-day or time-based events with custom start and end date pickers.
  - Color-Coded Event Bars: Up to 3 stacked event bars per day cell with custom border tinting via color picker.
  - Series Deletion: Multi-day event spans can now be deleted in their entirety with a single click.
  - Microbar Tooltip Integration: Calendar microbar button dynamically shows active world events and today's planned notes.

• |cffffd100Merchant Frame Extension:|r
  - Dynamic Grid: Configurable columns and rows for both vendor and buyback interfaces.
  - Instant Search: Integrated search box in the top-right corner that fades and desaturates non-matching items.
  - Layout Fix: Relative anchoring ensures consistent button placement across any custom frame size.

• |cffffd100Minimap Button Bag:|r
  - Added dedicated Minimap Bag module to neatly bundle all third-party minimap buttons.
  - Rendering Fix: Restructured frame strata and parent hierarchy so addon icons render fully opaque in the foreground.

• |cffffd100Extended Coloring & Borders:|r
  - Added gradient border support for Calendar, Character Frame, Stats Panel, Inspect Frame, and Minimap Bag.
  - Target Class Colors: Inspect frame now supports dynamic target class coloring and target class gradients.
  - Full orientation control (horizontal/vertical) and gradient inversion support.

• |cffffd100Alts Dashboard (Midnight & Playtime):|r
  - Silent played-time tracking (/played) without chat output.
  - Added tracking for Catalyst charges and configured Midnight currency IDs (Coffer Keys & Crests).
  - Pixel-perfect column alignments for all header elements and data rows.

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