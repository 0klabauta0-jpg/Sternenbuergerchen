# Editor-Neuimport: nativen Abbruch eingrenzen — 13.11.2026

## Ziel / Ursache / Basis
Nutzerauftrag „Mach weiter“ nach Mainintegration6bdc3b5ef. Offener Gesamtimport
endete beim Fontimport mit Exit1. Windowsereignisse1000/1001 belegen jetzt
Godot4.6.2-Zugriffsverletzung0xc0000005, Moduloffset0x3cde7c2.
Keine Scriptfehlermeldung vor dem Abbruch; letzter Fortschrittseintrag benennt
kenney_input_nintendo_gamecube.ttf, was allein keine Ursache beweist.
Branch task/editor-import-font-20261113 auf aktuellem origin/main.

## Umfang / Nichtziele
Reproduzierbare kleine private Font-/Importerproben, dann tatsächlicher voller
Neuimport. Dateidaten, Einstellungen, Parallelität und Editorplugins getrennt
prüfen; erst nach Ursachennachweis minimal korrigieren. Vorhandene Assets,
Referenzen, Cache, Spielerstände, Gameplay und aktive Mainfeatures erhalten.
Kein Desktopinput, Enginewechsel, allgemeiner Assetumbau, neue Grafikbalance,
EXE oder Behauptung nativer FPS-/Gesamtabnahme.

## Verträge / Akzeptanz
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, aktueller Status/Roadmap,
docs/qa/main_hex_review_20261113/README.md, HTML-Workbenchvertrag.
Kleiner Fall erfasst Engineversion, Argumente, Zeitlimit, Returncode, Log,
Quellenhashes und private user://-Bindung. Tatsächliche Importergebnisse prüfen,
nicht nur Quit0. Keine Cacheübernahme als Neuimport ausgeben. Relevante
Regressionschecks nach einem Fix, HTMLbericht aktualisieren und mobil prüfen.

## Dateien / lokale Prüfung / Risiken
Neue Probe/QA unter docs/qa/editor_import_font_20261113/ bzw scripts/tests/.
Produkt-/Importeinstellungen erst nach bestätigtem Befund minimal ändern.
Native Fehler können ohne Godotstack enden; Prozess-/Windowsbelege separat
sichern. Gleichzeitige Importjobs nicht als Erfolg werten oder mehrfach blind
wiederholen. Temporärer Wachhalteprozess, keine permanenten Energieänderungen.

## Ergebnis
Diagnoseschritt abgeschlossen: nativen vorherigen Crash über Windows/WER belegt,
Fontstruktur durch read-only Agent geprüft, 3 frische Fontproben mit exaktem
Profilguard, Metadatenhash und Logprüfung bestanden. Vollständige Quellkopie mit
leerem Cache und originalen Plugins importiert: Exit0, 358,12s, 21.074 Importdateien,
33.838 Originalquellen unverändert. Beide Fonts und echtes Hauptmenü aus diesem
Cache im privaten Runtimepfad geladen/instanziiert, Profilvergleich bestanden.
Echter Launcher-/Kindprozess-Timeouttest bestanden. Keine Produktänderung;
Ursache des früheren Access-Violation-Crashs bleibt unbewiesen. Eine StringName-
Aufräumdiagnose beim Editorende bleibt sichtbar. Neue vollständige Importprobe
mit den nachträglich verschärften Runnerguards wurde nicht behauptet.
Evidenz und genaue Grenzen: docs/qa/editor_import_font_20261113/README.md.
