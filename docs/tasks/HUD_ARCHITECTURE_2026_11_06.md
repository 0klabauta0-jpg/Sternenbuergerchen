# HUD-Architektur, Ruckelspitzen und Vorlagenabgleich

## Ziel / Problem
Der Nutzer verlangt eine weitere Verbesserungsrunde: echte Ruckelspitzen
abbauen, die eine Gameplaywahrheit kontrollieren, sieben alte Gates bestaetigen
und die Naehe zu den originalen 2D-Zielen ehrlich bewerten und verbessern.

## Basis / Ursache
Main be1dd404a61317f18307e0eff42a0530f07fa647; frischer Taskbranch
`task/hud-architecture-20261106`. Die historische normale90-s-Messung zeigt
288.544ms Framezeit, davon204.286ms vollerHUD. Die Aufrufkette baut mehrfach
Combat-/Decision-/Strategic-Projektionen und zieht alte QA-/Akzeptanzbuilder
in die produktive Commandmatrix. Buttonstyles wechseln imselbenPass erst
neutral und dann aktiv. Einzelanteile werden vor Korrektur frisch gemessen.
Eine neue zweite Simulationsautoritaet ist damit noch nicht nachgewiesen.

## Umfang / Nicht-Ziele
- Bestehende Owner und Contracts erhalten; UI liest und sendet Commands.
- Sichtbare Projektionen innerhalb eines begrenzten HUD-Lesevorgangs teilen,
  versteckte Legacydarstellung nicht durch unnoetige Akzeptanzberechnungen
  aktualisieren; notwendige Action-/Callback-/Detailpfade erhalten.
- Endgueltige Buttondarstellung gezielt anwenden; keine neutrale Zwischenphase.
- Kleiner referenzbelegter UX-Pass: konkreter Auftrag statt mehrfacher
  Ausfuehrungstexte, eindeutige Homebase-Titel und Statusfarben. Kein Rueckbau
  zu FOB, keine neue Gameplaylogik und keine spontane Vollarchitekturmigration.
- Keine Qualitaets-, Einheiten-, Zeit- oder Gameplayworkloadreduktion.
- Keine Actor-/HP-/Positions-/Timerpatches fuer physischen Spielbeweis.
- Originale und fruehere QA-Pakete bleiben unveraendert. Kein HTMLreport.

## Dokumente
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, runtime_script_layout_contract, fireteam_behavior_modes_contract,
mission_command_feedback_contract, ui_native_design_contract,
graphics_reference_revision_contract; CONTINUE_2026_11_05 und dessen QA.
Die geklaerte Grenze steht nun in
`docs/dev/mission_hud_projection_authority_contract.md`.

## Akzeptanzkriterien
- Normale 1x-Route, aktueller echter Vollbildmonitor, gleiche Renderer-/Kamera-
  und Qualitaetseinstellungen, gleiche Messinstrumente vor/nach und Rohdaten.
- HUD-Kosten und Gesamtframes getrennt ausweisen; Ziel ist der Wegfall der
  bestaetigten100-200ms-HUDspitzen, ohne neue sichtbare Rueckmeldungsverzoegerung.
- Aufrufe/Aufbauzaehler zeigen die vermiedene Arbeit, Ausgabeparitaet bzw.
  beabsichtigte UX-Differenzen sind geprueft. Keine persistenten Parallelwerte.
- Selection, Move, GO, Kontakt, FireEvent, Ablauf der Darstellungspersistenz,
  ROE, Transport und neu geoeffnete Details lesen aktuelle Ownerdaten.
- Reine HUD-Refreshes erzeugen keine Commands, Effects oder Gameplaymutationen.
- Alle sieben historischen Gates erneut pruefen; alte rote Artefakte erhalten.
- Vorlagenzuordnung und sichtbarer Abstand pro Bildschirm, keine erfundene
  Prozentnaehe. Nativer Vorher/Nachhervergleich der tatsaechlichen UX-Aenderung.
- Unabhaengiges Nachreview, Mainintegration und Push im fortgesetzten Auftrag.
- Geschuetzte Dateien und Roster bleiben nach Bytes, Groesse und mtime gleich.

## Betroffene Dateien / Besitz
Root: Controller-HUD-Pass, Profilierung, ReadModel, Verifikation, einzige
Enginekoordination, Git. Delegierte Hunk-Besitzer werden einzeln freigegeben.
Wahrscheinliche Dateien: mission_tactical_sandbox_controller,
mission_hud_read_model, mission_a5_hud_layout, homebase_operations_presenter,
neue fokussierte Verifier/Runner und QA unter eigenem20261106Namespace.

## Lokale Pruefung
Frische isolierte Userdaten und Fail-closed-Rosterguard; Headlesskomponenten
seriell, danach normale native Vergleichslaeufe und realePNG-Sichtpruefung.
GPUzeit wird ohne nativeTimer nicht erfunden. Source-/Outputpins unterscheiden.

## Risiken / offene Punkte
Verschachtelte Builder aktualisieren zeitgebundene Darstellungspersistenz und
rekursive Fallbacks. Diese duerfen nicht unbegrenzt oder als Wahrheit gecacht
werden. Legacy-Akzeptanzbuilder besitzen viele Leseketten; sichtbare Details
und optionale Aktionen duerfen nicht durch einen Guard veralten. Der Abstand
zur atmosphaerischen 2D-Szenenkomposition ist groesser als ein Rahmenpolish.

## Bestaetigte frische Diagnose / naechste Korrekturgrenze
Der38-s-Vorlauf auf dem heute aktiven3440x1440Vollbildmonitor besteht61/61.
Ein voller HUD-Pass baut bis51CombatDensity- und34Decision-Projektionen.
Die beiden unsichtbaren Legacy-Buttonpfade kosten zusammen50-64ms und
laufen durch historische QA-/Playtest-Snapshotketten. Gameplayautoritaet
bleibt bei den bestehenden Owners; dies ist keine neue zweiteSimulation.

Der vorhandene MissionHudReadModel erhaelt einen synchron begrenzten
Projektions-Lesepass: nur oberste Builderergebnisse, defensiveKopien,
keine Speicherung rekursiverFallbackwerte, Ende/Framewechsel/Revision
verwerfen Werte. Ausserhalb eines Passes wird immer direkt neu gelesen.
Root bindet dies nur um den vorhandenen _update_ui-Aufbau und seine
benoetigten Combat-/Decision-Projektionen. Selection/Commandwechsel im
selbenFrame beginnen trotzdem einen neuenPass. KeineTimer-/Simulationsaenderung.
KontrollierteLegacyaktionen behalten eigeneCallbacks; ein unsichtbares
Darstellungselement erfordert keine wiederholte Akzeptanzberechnung.

## Aufgeloester Live-Lesekreislauf
Nach dem ersten Pass-Cache bestehen volleHUDaufbauten nochbis120ms.
Die Live-Matrix setzt deshalb ihre benoetigten Legacy-Darstellungsdaten
vorwaerts genau einmal zusammen, mit den bereits erzeugten aktuellen RAW-
Fireteam-/Missionstexten als expliziten Inputs. Sie ruft keine anderen
Paneltextbuilder erneut rueckwaerts auf. Bestehende Getter und deren QA-
Pfad bleiben fuer explizite Diagnoseaufrufe erhalten. Leere RAWquellen
blockieren diese reine Projektion, statt implizit neue Inputs zu erfinden.
Die Rohtextmetadaten am vorhandenen Label sind nur Anzeigezwischenspeicher,
keine Mission-/Unitwahrheit. Optionale Buttons behalten ihre Callback-/GO-
Grenze und erhalten dieselben Contractprojektionen als lokale Argumente.

## Geprueftes Ergebnis

- Zusaetzlich bestaetigt und korrigiert: Der HUD-/3D-Pfad schrieb den effektiven
  Tuerindex; vier Drivergetter aktualisierten Gates/Countdown. Diese Arbeit
  liegt jetzt bei den bestehenden Runtime-Updatepfaden. Kein neuer Owner und
  keine parallele Tuerwahrheit. Test ohne HUD/3D inklusive Lifecycle/Remote und
  echter Client-/Host-Gracekontexte: 85/85.
- Review-P2 fuer Reveal ohne Force behoben und 77/77 geprueft. Nativer
  Primary-Stylebesitz 134/134, Legacy-Basisstyles 605/605, ReadScope 34/34,
  Live-DAG 163/163, aktive Order 46/46 und Homebase 72/72.
- Die Komponentenmatrix bleibt als 10/11 erhalten; der allein veraltete
  Hidden-Member-Oracle wird durch den fokussierten Batchnachlauf 43/43
  sachgerecht ersetzt. Finale Nachbarmatrix nach allen Produktkorrekturen:
  15/15, einschliesslich aller sieben historischen Gates.
- Normaler echter 3440x1440-Vollbildlauf 63/63. Gleiches 0-38-s-Fenster:
  HUD-Maximum 207.868 -> 79.006 ms, Frame-Maximum 278.098 -> 140.208 ms,
  Frame-p95 89.415 -> 65.728 ms. Ganze 90 s: 3949 Frames, 5400 Ticks,
  Simulations-/Wandzeit 0.999834. Keine allgemeine Ruckelfreiheitsfreigabe.
- Vorheriger 60/1-Kameralauf wird ausgeschlossen; der gueltige Lauf hat keine
  Kameraaktion und nur eine unveraenderte Kameraprobe. Keine Ruecksetzung
  oder Behandlung der Inputs durch den zusaetzlichen lesenden Beobachter.
- Zwei neue echte GUI-Prozesse bestehen den lokalen Vollbild-Host-/Join-/
  Ready-/Drop-/Befehlspfad. Kein LAN/WAN-, Mehrrechner- oder EXE-Beleg.
- Echte finale PNGs gegen Original-2D geoeffnet. Kleine UX-Differenzen sind
  sichtbar; Welt-/Kamerakomposition und Homebasegewichtung bleiben deutlich
  entfernt. Kein erfundener Naehe-Prozentsatz und keine Nutzerabnahme.
- Unabhaengiger Produktreview APPROVED scoped; QA-Bericht und Rohbelege unter
  `docs/qa/hud_architecture_20261106`. Main-Smoke und Remotebindung werden
  nach der Integration separat in dessen `main_receipt.json` quittiert.
