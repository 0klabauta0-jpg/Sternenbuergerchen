# Charakterdetails und aufgeräumte Basisnavigation — 10.11.2026
## Ziel / Ursache
Nutzer möchte doppelte Navigation entfernen, Tankservice unter Flugdeck und
Charakterdetails ohne breite Textkolonnen: voller NPC mit Slots, freie Lagerware,
kompakte Werte, einklappbare Fahrzeug-/Herleitungszweige, vertikale Hoverwerte.
## Umfang / Nicht-Ziele
Aufbau auf noch nicht integriertem Task5df2d3b6f, Mainbasis1e3cca237.
Vorhandene Runtime-/Supply-/Profilquellen behalten. Kein neues Rüstungsmodell,
keine Änderung von Scores, Inventargegenständen, Punktbudgets oder Saves.
Vorhandenes NPC-Modell für Ausrüstungsvorschau wiederverwenden. Kein Asset-Rework.
## Quellen / Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, TASK_ROADMAP;
homebase_direct_dropship_flow_contract, inventory_transfer_contract.
HomebaseOperationsPresenter, HomebaseScreen, CharacterSheetView/Formatter,
PersonnelInventoryPanel, BadgeResolver und kleine UI-Vorschaukomponente.
## Akzeptanz
Kein Zur-Truppansicht-Doppelbutton. Tankservice als Unterpunkt Flugdeck.
Detailsfenster nutzt volle verfügbare Höhe, bleibt bei1280/1920/3440 im Viewport.
Ganzer vorhandener NPC, Rüstung beim Torso, Primär/Sekundär links/rechts an Hüfte;
Slots lösen die bestehenden Inventarbefehle aus. Basislager zeigt freien Bestand,
getragenes bleibt als Ausrüstung kenntlich und wird nicht nochmals abgezogen.
Fahrzeuge und Herkunftsbaum einklappbar; nummerische Werte/formale Berechnung
unverändert; Faktoren in Hovertext zeilenweise. Keine Zukunftshinweise als Rauschen.
## Prüfung / Risiken
Gezielte Profil-/Inventarverifier und native Detailansichten; Rendering ist keine
Stilabnahme. Bestehende Popup-/Nodepfade bewahren, Editormetriken nicht umbauen.
Kein Main/EXE-Schritt ohne aktuellen Integrationsauftrag. Modellvorschau darf
keine Actorprozesse oder Simulation starten; Controls nur bei Änderungen bauen.
