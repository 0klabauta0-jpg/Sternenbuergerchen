# R3: unabhaengiges Nachreview der Performancekorrekturen

Stand: 07.11.2026. Branch `task/reference-polish-r3-20261106`, Mainbasis
`173a1e3c33b733a78a396a93db9cedf631d84998`.

## Urteil und Umfang
**APPROVED scoped.** Im final gepinnten Performance-Diff keine offene
belegte P1-/P2-Korrektheitsregression gefunden. Der zusaetzlich bestaetigte
Primary-/GO-Darstellungsbefund ist nach echtem RED eng korrigiert und im
aktuellen Root-GREEN geschlossen.

Gelesen wurden der gesamte Produktdiff dieser drei Dateien, TacticalUITheme
vollstaendig, die betroffenen Controller-/Fog-Funktionen mit unmittelbar
benoetigten Aufrufern, nativen Endpresentern, reinen Loop-Contracts sowie
die neuen Komponentenfixtures. Dies ist kein Vollreview aller historischen
31.000 Controllerzeilen. Kamera, Missions-UI, Homebase und Weltdressing haben
eigene Reviews. Fuer MissionSetup umfasst dieses Urteil den Fog-Slice;
die separat gepruefte initiale Kamera ist hier kein zusaetzlicher Gegenstand.

Der Reviewer aenderte keinen Produktcode und startete weder Engine, Import,
Benchmark noch Gitmutation. Der neue Primary-/GO-Verifier und seine Task-AC
wurden auf konkrete Rootfreigabe geschrieben. Alle RED/GREEN-Ausfuehrungen
besitzt Root; die unten referenzierten Reports und Logzaehler wurden lesend
kontrolliert. Vollbildmessung, finaler Nachbarlauf, Mainintegration, EXE und
gestalterische Nutzerabnahme sind getrennte Gates dieses Quellurteils.

## Quellbindung
SHA-256 der final gelesenen Arbeitsbaumdateien:

| Datei | SHA-256 |
| --- | --- |
| `scripts/ui/tactical_ui_theme.gd` | `87df9617a029fb292f4aa808b10422c3be082b22714112111960a603fc533729` |
| `scripts/tests/mission_test_setup.gd` | `64da64da090566e3bc06da06eb6a754161a943033b191d3572c218dc98bd2aaf` |
| `scripts/tests/mission_tactical_sandbox_controller.gd` | `2434f55be706c284c9838e4c58aa76ed45624d6ddfe43e730e7cf25b9c9b8235` |
| `scripts/tests/reference_polish_r3_20261106_command_style_owner_verifier.gd` | `258e4dc8bdcbc9c2df19a62841b695d8053306751cd0556a991b8b623b2bd5dc` |
| `scripts/tests/reference_polish_r3_20261106_controller_ownership_verifier.gd` | `2906a14b586267116d694b3a4f86ff47aee7ef69ab66578de6148f4de0c2e7a2` |
| `scripts/tests/reference_polish_r3_20261106_strategic_loop_verifier.gd` | `ff5dd5162121954e77e6755dc0979467f21b971643d504a0db7cbc71a6516563` |

Spaetere Produktdeltas brauchen eine neue Bindung. Bereits gelesene alte
Rohbelege wurden nicht auf aktuelle Quellen umbeschriftet.

## Theme und Fog
`TacticalUITheme:251-320` prueft vorhandene lokale Overrides und deren
tatsaechliche Werte/Ressourcen. Gleiche geerbte Werte verhindern nicht das
Installieren eines benoetigten lokalen Overrides; externe Ersetzungen werden
weiter repariert. Es gibt keine neue erinnerte Stilwahrheit. Actiontiles
erhalten ihre bisherigen Endmargins und Font11 direkt, Focus bleibt separat.
Popup-Theme, Farben, Selection und Statuswechsel behalten ihre Semantik.

`MissionSetup:300-318,1106-1178` verarbeitet im normalen Process zuerst einen
Service-Slice. Ein anschliessender 100ms-Sync fordert bei Bedarf den naechsten
Job an, verbraucht mit `advance_work=false` aber keinen zweiten Slice.
Explizite Aufrufer und Force behalten den unmittelbaren Default. Beide
Argumente passieren den Deferred-Retry. Die statische Invalidation zweigt
vor dem alten Serviceaufruf ab; ihr Ersatzjob erhaelt somit ebenfalls nur
einen Slice. DynamicTarget-LOS, atomare Terrainpublikation und Budget512
bleiben erhalten. Die synthetische 350ms-Assertion ist keine garantierte
reale Sichtlatenz bei langsamen Frames.

## Native Beschriftungen und Mini-Karten
Der bestehende A5-Setupmarker plus bekannte Primary-Namen begrenzt den
Ownerguard. Legacy-/frische Controls werden weiter vollstaendig initialisiert.
Native Primary-Icons folgen der aktuellen expliziten ICON_IDS-Zuordnung;
Legacy und der vorhandene unbekannte-Icon-Fallback bleiben erhalten.
Tooltips, Disabled, Togglegates, Kontexttools und Signalbindungen werden
nicht uebersprungen.

`Controller:5724-5781` nimmt ausschliesslich bereits nativ besessene
Card-Minima/Panel, Title-Groesse/uneditable-Farbe und Stage-Groesse vom
Legacy-Zwischenstil aus. Heading-Font, editierbare Titelfarbe, versteckte
Member-Schrift und alle vorhandenen Kompatibilitaetsmetas bleiben frisch.
Der native Kartenpresenter setzt die Endfelder weiter aus aktuellem State.
Es werden keine Status-/Portraitbuilder entfernt und keine Runtimewechsel
durch einen neuen Gesamtcache oder Timer verborgen.

## Strategic RAW: lokale Weitergabe statt zweiter Quelle
Die bei `Controller:9170` weitergegebene Density stammt aus derselben
synchronen RAW-Assembly. Der vorhandene Handoff-Fallback bleibt fuer andere
Aufrufer verfuegbar; RAW-Text bleibt auch fuer Matrix und Details erhalten.

`_build_strategic_loop_two_readout` bei9192 haelt zwei Strings ausschliesslich
lokal in dieser Assembly. Er baut den NextLoop unter demselben noch freien
vorhandenen Guard, unter dem der erste fruehere Helper gebaut haette.
Bei Hud-Guard0 wird dieser genommen; bei aktivem Hud-Guard und freiem
Polish-Guard wird letzterer genommen; bei beiden aktiven Guards entstehen
weiter zwei leere Zeilen ohne Sourcebuild. Die exakten vorherigen Depthwerte
werden vor den expliziten Helperaufrufen wiederhergestellt. Damit bleiben
auch die bestehenden Reentry-Fallbacks der einzelnen Helper erhalten.

Der nichtleere Readout markiert auch zwei leere Ergebnisstrings als bereits
gebaut. Ein spaeterer Prioritaetspass loest deshalb keinen neuen Sourcebuild
aus. Ein unabhaengiger RAW-Aufruf liest erneut frisch. Kein persistenter
UI-/Missioncache und keine neue autoritative Wahrheit. Die reinen
Playtest-/Polish-Contracts liefern bei fehlender Quelle ebenfalls leere
Zeilen; das Empty-Source-Return erfindet somit keinen spielbaren Loop.

## Zusaetzlicher Befund und gezielte Schliessung
Der Nachreview bestaetigte am Vorfixstand eine weitere vorhandene P2-
Doppelarbeit: `Primary` setzte trotz neuem Textguard noch Clipping, Font12
und aktive Modulation. `GO` setzte GO/Font13/Clipping, Modulation und vier
Fontfarben. Der native A5-Presenter stellte danach seine eigenen Werte
wieder her; abweichende Fonts/Modulation machten seinen Styleguard dirty.
Dies war verbleibende Bestandsschuld, keine neu eingefuehrte Regression.

Im finalen `Controller:11175-11232` bleiben ausschliesslich diese nativen
Darstellungsfelder bei ihrem vorhandenen Presenter. Beide Funktionen
berechnen weiter GO-Readiness und schreiben dieselben Tooltips sowie alle
Enhancement-Metadaten. Kein vorgezogener Gesamtreturn, keine Aenderung an
Authority, Disabled, Commands, Callbacks oder ROE. Legacy bekommt die
historischen Texte, Fonts und aktiven GO-Farben. Der neue Verifier erfasst
die Grenze vor dem reparierenden nativen Endpass, statt nur dessen Endbild
zu pruefen.

## Kontrollierte Root-Evidenz und Testbarkeit
Die folgenden Reports enthalten jeweils Exit0, Fehler0, Isolation und
stabile Eingangsquellen. Das sind gelesene Root-Ergebnisse, keine eigenen
Engineausfuehrungen des Reviewers:

| R3-Ausgabepfad unter `output/reference_polish_r3_20261106/` | Ergebnis |
| --- | --- |
| `theme_green/20261106T184439Z-df403d60` | 52/52 |
| `fog_green/20261106T184440Z-9a07f9e1` | 21/21 |
| `native_labels_green/20261106T184443Z-953fdbbe` | 90/90 |
| `controller_final_green/20261106T232107Z-6b745319` | 43/43 |
| `strategic_loop_green/20261106T232654Z-14b2f7ba` | 55/55 |
| `command_style_owner_green/20261106T233206Z-29d021d1` | 142/142 |

Die aelteren Einzel-GREENs binden ihre damaligen Quellen, nicht automatisch
den finalen Controllerpin. Root wiederholt die betroffenen Nachbarn separat.
Das letzte Style-GREEN bindet den hier gepinnten Controller exakt.

Primary/GO hatte zuvor im fehlerfreien korrigierten RED82/60 genau60
Presentation-/Theme-Fehler. Der erste Lauf mit eigener Fixture-Lifecycle-
Meldung wird ausdruecklich nicht als sauberes RED verwendet. Der korrigierte
Verifier prueft echte logische Groessen, aktive/inaktive Darstellung,
bereite/blockierte UI-Preconditions, echte Ressourcen/Stilwerte und
Theme-Signale. Er vergleicht Tooltip-/Meta-/Gate-/Callbackdaten mit dem
ausdruecklichen Legacyoracle sowie Command-/Effectqueues, Planowner, Tick
und vorhandene Actorwerte auf Unveraendertheit. Sein kontrollierter
Order-Anzeigegetter und GO-Disabled-Input sind Presenterfixtures, kein
Beleg fuer echte Orders, Authority oder physisches Spielen. Echte lokale
Authority wird positiv geprueft und nicht ersetzt.

## Architektur, Standards und Grenzen
- Keine neue Gameplay-, Mission-, Unit-, Transport- oder Combatwahrheit;
  keine Commands/Effects oder SceneTree-Vollscans im geprueften Diff.
- Bestehende Presenter, Contracts und Runtime-Scheduling werden eng benutzt.
  Tatsachen, Metadaten und Tooltips bleiben bei ihren vorhandenen Besitzern.
- Lange Legacyfunktionen/Controller und weitere noch doppelte historische
  Lesepfade bleiben technische Schuld; dies rechtfertigt keinen unbestellten
  grossen Refactor innerhalb dieses Diffs. Kein gesamtes Controller-SOLID-
  oder allgemeines Ruckelfreiheitsurteil.
- Keine konfigurierte `.ai-game-studio/project.json` und keine konkrete ADR
  im Task, Diff oder den zuletzt relevanten Commitbetreffs gefunden.
  Architektur gegen ARCHITECTURE/CODEX_RULES und die HUD-/Feedbackvertraege
  geprueft. Kein weiterer Spezialist oder konkurrierender Runner gestartet.
- Native Framedistribution, Backlog, normaler1x-Durchsatz, Grafik-/UX-
  Wirkung, finale Regression und Main-Push bleiben Roots gesonderte Belege.

Keine weitere Pflichtkorrektur fuer diesen gepinnten Performance-Slice.
