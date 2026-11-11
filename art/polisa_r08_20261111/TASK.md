# Polisa R08 — gezielte Ergänzung der gelobten R07-Grundform

## Ziel und Ursache
Der Nutzer lobt die R07-Grundform. Sie bleibt erhalten. R08 ergänzt etwas größere Ringe/Solarflächen, leicht längere gerade Ausleger, klar erkennbare Dockingköpfe und baulich gefasste Übergänge zwischen Pads, Koncourse und Globusraum.

## Umfang / Nichtziele
Nur privates Artpaket und eigener Output. Keine Produktionsdateien, Registry, UI oder Runtimewahrheit, kein Commit/Push. Pads S8×6 aus der owning Heimatbasisquelle, M12×12/L16×24, Räume, Figuren und Grundriss unverändert. Offene Durchgänge sind statische Geometrie; keine interaktiven Türen oder erfundenen Türzustände. Keine Schiffs-Dockingfreigabe.

## Bestätigter Maß-/Wandplan vor Code
- Ringe Radius28/D56 statt24/D48, Breite3.2. Beide MittelpunkteY−12/Z19, Yaw0; gemeinsame gerade X-Achse unter der rückwärtigen Weghälfte.
- Solars14×22 statt12×18 beiX±63, orthogonale Z-Streben aufY−12. Achse bisX±88. Größere Dockingköpfe beiX±82, helle Einfassung/Cyan-Insets und DOCK L/R-Beschriftung.
- Niedrige Hull-/Glas-Trennwand Z24/X−36..29 mit fünf offenen2.5breiten Padzugängen. Vordere S-Reihe bleibt über bestehende Verbindungen erreichbar.
- Lobbyfrontwand Z20/X−14..14, mittiger4breiter Eingang. Kurze Seitenrückläufe X±14/Z16..20 verhindern das Umgehen der Wand über den Koncourse. Türrahmen mit rund2.3lichter Höhe, keine Schließfunktion.
- Drei native Ansichten: R07-Nahkamera62, vollständige Station mit beiden Dockköpfen112, ehrliche Ganzkarte320. Alle dieselbe Szene/Skala.

## Grundlagen / Akzeptanz
AGENTS.md; PROJECT_BRIEF; ARCHITECTURE; CODEX_RULES; IMPLEMENTATION_STATUS; graphics_reference_revision_contract.md; godot-procedural-worlds. R07 wird unverändert als vom Nutzer gelobte Grundform archiviert. Gleiche Layoutfakten erzeugen Wände, Öffnungen, Blocker und Marker. Alle sieben Padanker, fünf Räume und der Globusumlauf bleiben erreichbar. Waren bleiben ohne Kameradrehung sichtbar. Bestehender Root-Hexoverlay und dessen2.2Pixel-Kontrastkern werden genutzt.

## Prüfung / Risiken
Kleine Quellen-/Graphprüfung, check-only und drei gezielte geöffnete native Ansichten nach Root-GPU-Freigabe. Keine großen Tests. Rahmen dürfen die Raum-/Warenansicht nicht verdecken. Größere Ringe dürfen im nahen Bild angeschnitten sein; der zusätzliche Stationsüberblick muss beide Dockköpfe zeigen. Nutzerlob gilt der Grundform, nicht einer pauschalen Release- oder Runtimeabnahme.
