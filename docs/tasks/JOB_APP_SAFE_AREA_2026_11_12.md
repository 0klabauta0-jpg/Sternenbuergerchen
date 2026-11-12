# Auftragsapp und freie BedienflÃ¤che â€“ Playtest 12.11.2026

## Problem/Ziel und Ursache
Nutzer: Beim ersten Auftrag schlieÃŸt die Auftragsapp vor mÃ¶glicher Annahme.
Smart Mobile und Details werden vom unteren Band verdeckt. Ursache zunÃ¤chst
ungeklÃ¤rt; tatsÃ¤chlichen Control-/Input-/Refreshpfad reproduzieren.

## Umfang und Nicht-Ziele
Gezielte UI-/PrÃ¤sentationskorrektur ab Main3446f3040 im isolierten Rootcheckout.
Bestehende Runtimecommands, Kampagnenbedingungen, Inventar und Reiseowner bleiben
die Wahrheit. Keine neue Missionslogik, Karten- oder Modellrunde; keine breiten
Gefechts-/Performancetests. Kein aktiver Nutzerdesktop und keine Nutzerprofile.

## VertrÃ¤ge / Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS;
homebase_operations_ux_contract, BASE_MANAGEMENT_VISUALS_2026_11_10;
homebase_operations_presenter, singleplayer_job_board_presenter, homebase_screen
und gezielter echter Scene-/Inputverifier. Exakte Ã„nderungen nach Befund.

## Akzeptanz
- Smart Mobile bleibt bei Auswahl/DetailÃ¶ffnung des ersten angebotenen Auftrags
  bedienbar, bis explizites SchlieÃŸen oder gewÃ¼nschter Ansichtswechsel erfolgt.
- Echte Annahme erreicht den vorhandenen Campaignowner genau einmal; keine
  kÃ¼nstliche Freischaltung oder UI-eigene Auftragswahrheit.
- Smart Mobile und Charakterdetails einschlieÃŸlich relevanter Aktionen liegen
  vollstÃ¤ndig oberhalb des unteren Bands, auch nach Resize bei1280Ã—720 und
  1920Ã—1080. Scrollinhalte bleiben erreichbar.
- Andere SchlieÃŸen-/Navigationswege bleiben funktional.

## PrÃ¼fung / Risiken
ZunÃ¤chst fokussierter roter Scene-/Inputnachweis, danach gleicher Pfad grÃ¼n.
Private Nativecaptures nur bei Layout-/Hit-Testbedarf; niemals Desktopaktivierung.
MÃ¶gliche Ursache kann Ereignisweitergabe, Refresh oder verÃ¤nderte MindestgrÃ¶ÃŸe
sein. Native EXE nach gezielter PrÃ¼fung neu bauen, alten Paketordner bewahren.

## Umsetzung und fokussierter Nachweis
- Aktives Flyout und sein Schließen-Knopf stehen auch in der GUI-Geschwisterfolge
  vor der Außenklickfläche. Außenklick und explizites Schließen bleiben erhalten.
- Read-only Dockrechteck und Geometriesignal liefern die freie Overlayfläche.
  App und Details enden acht Pixel über dem sichtbaren Basisband.
- Auftragsaktionen bleiben außerhalb des scrollenden Briefings erreichbar.
- Inventarspaltenbreite berücksichtigt die tatsächliche Mindestbreite der
  Charakterwerte und Panelränder; Figurhöhe und Runtimecommands bleiben erhalten.
- Verifier: scripts/tests/job_app_safe_area_verifier.gd. Echte Controlereignisse
  statt direkt ausgelöster pressed-Signale; eigene neue Kampagne und Testprofile.
- Roter Ausgangslauf: output/job_app_safe_area_red/20261112T183214Z-pid43524,
  13 Prüfungen / 9 Fehler. Nach Eingabekorrektur nur Layoutfehler.
- Final headless: output/job_app_safe_area_final5/20261112T190101Z-pid47468,
  24 Prüfungen / 0 Fehler. Import-/Ladezeitüberschreitungen der Zwischenläufe
  sind keine bestandenen Prüfungen; final mit vorhandenen Importen ausgeführt.
- Kein großer Gefechts-, Performance- oder Multiplayernachweis.
