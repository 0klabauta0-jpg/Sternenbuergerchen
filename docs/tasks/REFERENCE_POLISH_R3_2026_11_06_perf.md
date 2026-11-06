# R3: gleiche Darstellung mit weniger HUD-/Fog-Arbeit

## Ziel und bestaetigter Befund
Untertask zu `REFERENCE_POLISH_R3_2026_11_06.md`, Basis Main173a1e3c3.
Resthitches besitzen mehrere Anteile. Im genehmigten alten 90-s-Lauf kostet
der groesste HUD-Aufruf79.633ms. Zu dessen getrennten Teilbereichen gehoeren
Craftstyles7.575ms, Labelpass6.941ms, MiniCards9.570ms und Strategictext13.563ms.
Im 140.208-ms-Frame liegen gleichzeitig54.283ms HUD und39.677ms Fog vor.
Das sind inklusive Diagnosewerte, keine isolierten Ursachenbeweise oder
addierbaren Parent-/Childsummen. Ein neuer Root-Vorlauf bleibt erforderlich.

## Ursachen und enger Entwurf
1. `TacticalUITheme` schreibt gleiche Overrides wiederholt. Godot4.6.2
   `Control::add_theme_*_override` besitzt dafuer keinen Equalityguard;
   jeder Aufruf meldet Themeaenderung, Font/Style verbindet Ressourcen neu.
   Eigene kleine Setter pruefen vorhandenen Override und tatsaechlichen
   Wert bzw. Ressourcenidentitaet. Fremde Overrides werden weiterhin repariert.
   Actiontiles erhalten ihre finalen Margin-/Fontwerte direkt statt einer
   generischen Zwischenphase. Kein Signaturcache und keine neue UI-Wahrheit.
2. `MissionSetup._process` verarbeitet erst einen Fog-Slice und kann im
   100ms-Sync nach dessen Completion sofort noch einen neuen verarbeiten.
   Der normale Processpfad darf hoechstens einen Service-Slice verbrauchen.
   Expliziter Sync/Force bleibt standardmaessig unmittelbar; normaler Sync
   kann einen neuen Job fuer den naechsten Frame einreihen. Workbudget512,
   DynamicTarget-LOS, atomarer Commit und Terrain-/Modeinvalidierung bleiben.
3. Der Legacy-Labelpass setzt native A5-Primary-Texte/Icons/Font zurueck,
   bevor der vorhandene native Presenter sie wiederherstellt. Diese neun
   Controls behalten auch fuer Labels/Icons ihren finalen Besitzer. Tooltip,
   Meta, Disabled, Kontexttools, ROE, Legacy und Callbackgrenzen bleiben.

Die Engineursache ist gegen die versionierte Primaerquelle geprueft:
[Godot4.6.2 Control](https://raw.githubusercontent.com/godotengine/godot/4.6.2-stable/scene/gui/control.cpp),
Zeilen2736-2739 und3115-3152. Der daraus abgeleitete Millisekundengewinn bleibt
bis zur Root-Gegenmessung unbekannt.

## Umfang und Nicht-Ziele
Nur bestehende Presenter/Runtime-Scheduling aufraeumen; keine Zeit-, Sicht-,
Unit-, Nav-/LOS-/Cover-, Interaktions- oder Qualitaetsreduktion. Kein persistenter
Displaycache, kein neuer Owner, kein Gameplay aus UI. Strategictext und
MiniCards bleiben zunaechst Diagnosekandidaten, nicht blind mitveraendert.
Alte Rohdaten, Saves, Roster und fremde WIP bleiben unveraendert.

## Besitz und Dateien
Agent darf erst nach Roots frischem Vorlauf und echtem RED implementieren:
- `scripts/ui/tactical_ui_theme.gd` (enge Style-/Setterhunks).
- `scripts/tests/mission_test_setup.gd` nur `_process` und `_sync_fog_of_war_visual_state`.
- Controller nur `_apply_drop_light_hud_button_labels`, praeziser Ownerhelper
  und ggf. gemeinsamer Iconpass; gemeinsame Datei nur per apply_patch.
- Neue `reference_polish_r3_20261106_*_verifier.gd`, dieser Untertask.
Root besitzt Kamera, weitere Controllerhunks, saemtliche Engines und Git.

## Akzeptanz / Regression
- Wiederholtes gleiches Styling im Tree erzeugt keine Theme-Notifications;
  Ergebnisstyles, Farben, Fonts, Margins, PopupTheme und Callbacks stimmen.
  Statuswechsel und externe Overrides werden korrekt angewandt; explizite
  lokale Overrides werden auch bei gleichem geerbtem Wert installiert.
- Ein realer MissionSetup-Processaufruf mit echtem Fogservice verbraucht
  hoechstens einen Slice, auch bei Completion plus naechster Bewegung.
  Expliziter Force verarbeitet weiterhin einen Slice. Folgeframes publizieren
  ohne Hunger; Vollscanorakel, atomarer Zustand, Sichtbarkeit und Budget bleiben.
- Native Primary-Labels/Icons/Fonts erfahren am Legacy/Native-Uebergang keine
  Zwischenmutation. Finale sichtbare Ausgabe und die bestehenden Tooltip-/
  Gate-/Callbackdaten bleiben gleich. Legacy ohne A5 behaelt seine Tokens.
- Nach Root-RED/GREEN: betroffene Nachbarn und nativer Vergleich bei Kamera34,
  gleicher Qualitaet und normaler1x-Route. Laufzeit bleibt autoritativ.

## Prueflogik und Grenzen
Neue Verifier sind kontrollierte Komponentenfixtures. Synthetic Fogobserver-
Positionen, manuelle Processdelta und Popup-/Controlaenderungen sind keine
physische Spiel- oder Performanceabnahme. Engine-/Git-Runs ausschliesslich
bei Root, seriell und mit frischen isolierten Nutzerdaten. Reale Profilierung
und Vollbildbilder sind getrennte Abschlussgates.

## Durchfuehrung / aktueller Stand
Root hat zwei frische native 90-s-Vorlaeufe jeweils 63/63 bestaetigt:
`baseline_native/20261106T182737Z-85865690` und
`baseline_native_repeat/20261106T183555Z` unter dem neuen R3-Ausgabeordner.
Die neuen Komponentenchecks reproduzierten danach ohne Fixture-/Enginefehler:
- Theme RED: 34 bestanden, 17 erwartete Fehlschlaege;
  `theme_red/20261106T184025Z-8a96f65f`.
- Fog RED: 18 bestanden, ein erwarteter Doppelslice-Fehlschlag;
  `fog_red/20261106T184027Z-53a462f2`.
- Native Labels RED: 85 bestanden, fuenf erwartete Zwischenmutationen;
  `native_labels_red/20261106T184029Z-d293e5b1`.
Root gab danach die drei engen Produktkorrekturen frei. Sie sind jetzt fuer
das serielle GREEN eingefroren; ein bestandenes GREEN oder nativer Gewinn
wird noch nicht behauptet. A5-Layout und weitere Kamera-/UI-Revisionen bleiben
ausdruecklich bei Root. Der Target-Icon-Fallback folgt dem vorhandenen
Legacy-Cache, solange `ICON_IDS` dafuer keinen nativen Besitzer benennt.

Root bestaetigte anschliessend das serielle GREEN, jeweils Exit0, keine
Engine-/Fixturefehler und stabile Quellen waehrend des Laufs:
- Theme: 52/52, `theme_green/20261106T184439Z-df403d60`.
  Die exportierten `R3_THEME_OUTPUT_FACTS` stimmen exakt mit RED ueberein.
- Fog: 21/21, `fog_green/20261106T184440Z-9a07f9e1`.
- Native Labels: 90/90, `native_labels_green/20261106T184443Z-953fdbbe`.

Ausgabebasis ist jeweils `output/reference_polish_r3_20261106/`.
Damit sind die drei engen Komponentenursachen korrigiert und ihre
Regressionsgrenzen geprueft. Quellen und Verifier bleiben eingefroren.
Roots zwei optimierte native 90-s-Vergleiche sowie unabhaengiges Review und
die weitere Grafik-/UX-Runde stehen als getrennte Gates noch aus; dieses
Komponenten-GREEN behauptet weder einen FPS-Gewinn noch Main-Integration.

## Nachreview: drei weitere Controller-Doppelarbeiten
Roots unabhaengiges Review benennt drei am aktuellen Code bestaetigte P2.
Diese Folgefreigabe betrifft ausschliesslich den Controller und einen neuen
fokussierten Verifier; Produktkorrekturen beginnen erst nach Roots echtem RED.

- Mini-Karten: Der bestehende Legacy-Stylepass setzt vor dem nativen A5-Pass
  Card-Minimum/Panel, Title-Fontgroesse/uneditable-Farbe und Stage-Fontgroesse
  zurueck. Bereits als `native_a5_portrait_team_card` praesentierte Karten
  behalten fuer genau diese Felder ihren nativen Endbesitzer. Initialisierung,
  Heading-Font, editierbare Titelfarbe, versteckte Member-Schrift und bisherige
  Kompatibilitaetsmetas bleiben im Legacy-Pass. Kein Gesamtcache, keine
  Wartezeit und kein Entfernen versteckter Status-/Portraitbuilder.
- Strategictext: Seine bereits berechnete `interaction_density` geht als
  vierter vorhandener Override in den Debrief-Handoff. Der bestehende reine
  Builder und sein Fallback bleiben erhalten. RAW-Text muss exakt gleich sein.
- Target: Die spaete `ST/ZL`-Zuweisung in `_update_ui` gilt nur ohne nativen
  Primary-Besitzer. Native A5 behaelt `Ziel`; Armed-State, Callback und Gates
  bleiben unveraendert.

Zusaetzliche Akzeptanz:
1. Ein realer vollstaendiger Mini-Karten-Refresh fuer gleiche Eingaben behaelt
   sichtbare Endstyles/-texte, Hidden-Details, Statussnapshot, Tooltips,
   Portraitidentitaeten, Callbackidentitaeten und bisherige Metas. Im darin
   beobachteten Legacy-Pass entstehen keine nativen Zwischenmutationen oder
   Theme-Notifications der sichtbaren Card-/Title-/Stage-Controls.
2. Neue Karten und ein expliziter Legacy-Kompatibilitaetspfad initialisieren
   weiterhin Heading-Font, Member-/Stage-Schrift, Mindestmass und alle Metas.
   Auswahlwechsel lesen aktuellen State, ohne Actor-/Runtime-Aenderungen.
3. Ein echter Strategictext-Build reicht seine aktuelle Density unveraendert
   weiter; der Handoff baut keine zweite Density. Der RAW-Text entspricht dem
   selben realen Builder mit dem bisherigen expliziten Fallback. Commands,
   Effects, Planowner und Simulationsstand bleiben dabei unveraendert.
4. Der echte `_update_ui`-Durchlauf behaelt das native Target-Label bereits
   vor seinem abschliessenden Layoutpass, fuer beide Armed-Zustaende.
   Legacy zeigt weiterhin `ZL/ST`; originale Signalbindungen bleiben erhalten.

Testgeruest: eine reale Missionsszene mit abgeleitetem Controller an dessen
urspruenglichem NodePath und kopierten Szenenexports. Beobachtungs-Overrides
delegieren an Produktfunktionen. Ein expliziter UI-Kompatibilitaetsmodus
erzwingt nur den alten Style-/Density-Pfad als Vergleichsorakel; keine Actor-
Positionen, Gesundheit, Kampfdaten oder Simulationszeiten werden manipuliert.
Diese Komponentenevidenz ersetzt weiterhin keine normale Spiel-/FPS-Abnahme.

Der neue Check liegt in
`scripts/tests/reference_polish_r3_20261106_controller_ownership_verifier.gd`.
Root meldete fuer `controller_ownership_red/20261106T231500Z-af15272c`
25 bestanden/14 fehlgeschlagen, Fehler0 und stabile Quellen. Davon waren
sechs Mini-Style- und vier Density-Pruefungen echte REDs; vier Target-Checks
erreichten wegen des leichten `_update_ui(false,false)`-Fixturepfads ihre
spaete Grenze noch nicht und zaehlen ausdruecklich nicht als Produkt-RED.
Nach Freigabe wurden Mini/Density korrigiert und der Verifier auf den echten
vollstaendigen `_update_ui(true,false)`-Pfad berichtigt. Root bestaetigte dann
`controller_target_red/20261106T231647Z-dfbd4998`: 41 bestanden, exakt zwei
echte native Target-Zwischenmutationen fehlgeschlagen, Fehler0/stabile Quellen.
Erst danach wurde der Target-Guard ueber denselben bestehenden nativen
Primary-Ownerhelper umgesetzt. Quellen und Verifier wurden erneut eingefroren.
Alle Pfade beziehen sich auf die neue
R3-Ausgabebasis, historische Belege bleiben erhalten.

## Finale fokussierte Controller-Gates
Die weitere Target-Diagnose trennte zwei Ursachen: Der reale Legacy-Layoutpfad
aktiviert A5 am Ende, weshalb die Fixture das Legacyflag vor jedem Armed-Fall
neu setzen musste; ausserdem schrieb der vorhandene Firefight-Primary-Polish
den nativen Text nochmals zurueck. Nur dessen Labelzuweisung erhielt nach
Freigabe denselben bestehenden nativen Ownerguard. Tooltips und Enhancement-
Metas blieben erhalten. Das echte anschliessende GREEN ist43/43 unter
`controller_owner_target_final_green/20261106T232431Z-ad77d9f6`.

Der unabhaengige Reviewer ergaenzte danach den gesonderten Primary-/GO-Style-
Verifier mit drei logischen Bildschirmgroessen, activefalse/true und echtem
vollstaendigem UI-Durchlauf. Sein korrigiertes fehlerfreies RED war82/60 unter
`command_style_owner_red_corrected/20261106T233050Z-b0aa40b4`: ausschliesslich
native Zwischen-Presentation/Theme-Notifications schlugen fehl. Nach Roots
Freigabe schuetzen die zwei vorhandenen Polishfunktionen auch clip/font_size,
aktive self_modulate und die vier aktiven GO-Fontfarben. Readiness, originale
Gates/Callbacks, Tooltips, Enhancement-Metas und ROE bleiben im bisherigen Pfad.
Das echte GREEN-Log bestaetigt142/142 unter
`command_style_owner_green/20261106T233206Z-29d021d1`.

Der gesonderte lokale Strategic-Next-Loop-Untertask ist55/55 gruen; dessen
Quelle sinkt in sechs Faellen von2/4 auf1 pro Assembly, beide Guards bleiben0,
RAW bleibt identisch. Details stehen in
`REFERENCE_POLISH_R3_2026_11_06_strategic_loop.md`.

Alle Produkt- und Testquellen sind jetzt final eingefroren. Root plant40
Regressionen und zwei native90-s-Vergleiche des aktuellen Gesamtstands.
Diese finalen Gesamtnachweise, Mainintegration und Push bleiben bis zu deren
tatsaechlichem Abschluss offen. Keine Engine-/Git-Ausfuehrung durch den Agenten.

## Quellbindung beim finalen Freeze
SHA256, auf dem aktuellen Gesamtstand vor Roots finalen Regressionen gelesen.
Diese Bindung ersetzt nicht die jeweilige historische Run-Receipt; insbesondere
Root hat MissionSetup inzwischen um die separat beauftragte Kamera erweitert.

| Datei | SHA256 |
| --- | --- |
| scripts/ui/tactical_ui_theme.gd | `87df9617a029fb292f4aa808b10422c3be082b22714112111960a603fc533729` |
| scripts/tests/mission_test_setup.gd | `64da64da090566e3bc06da06eb6a754161a943033b191d3572c218dc98bd2aaf` |
| scripts/tests/mission_tactical_sandbox_controller.gd | `2434f55be706c284c9838e4c58aa76ed45624d6ddfe43e730e7cf25b9c9b8235` |
| scripts/tests/reference_polish_r3_20261106_theme_idempotency_verifier.gd | `6fd76af33849b21170706b5289a1f0e54e6f9eeff246584da723160afa9f9ef1` |
| scripts/tests/reference_polish_r3_20261106_fog_single_slice_verifier.gd | `0c38d5db25dfbf8a37ea1a3549d339314423d4f931d2f2ee48e400bfc5e7fa45` |
| scripts/tests/reference_polish_r3_20261106_native_labels_verifier.gd | `7a2a7f04c5af96c578ff719d459e257c26add992f401768ae2871745d6c21361` |
| scripts/tests/reference_polish_r3_20261106_controller_ownership_verifier.gd | `2906a14b586267116d694b3a4f86ff47aee7ef69ab66578de6148f4de0c2e7a2` |
| scripts/tests/reference_polish_r3_20261106_strategic_loop_verifier.gd | `ff5dd5162121954e77e6755dc0979467f21b971643d504a0db7cbc71a6516563` |
| scripts/tests/reference_polish_r3_20261106_command_style_owner_verifier.gd | `258e4dc8bdcbc9c2df19a62841b695d8053306751cd0556a991b8b623b2bd5dc` |

## Relevante Vertraege
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, mission_hud_projection_authority_contract,
mission_command_feedback_contract, runtime_script_layout_contract;
Godot-Performance-Workflow und vorangegangene HUD-Architektur-QA.
