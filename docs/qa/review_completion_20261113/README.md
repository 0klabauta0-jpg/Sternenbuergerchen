# Hex, Bedienung und Grafik – Umsetzungsnachweise

Arbeitsbasis ist Main `dc2ca9aca`, Umsetzung auf
`task/review-completion-20261113`. Der Hauptcheckout mit fremden Änderungen wird
nicht umgeschaltet. Aktueller Integrationsstand und akzeptierte Prüfläufe stehen
in `summary.json`. Die technische Regression ist abgeschlossen; persönliche Grafikabnahme und WAN-/Gesamtspiel-Leistungsmessung bleiben ausdrücklich offen.

## Änderungen

- Alle 14 produktiven Missions-/Sandboxkarten und drei Basisdateien verwenden
  die gemeinsame Hexgeometrie. Bodenbewegung, Belegung, Sicht und Schussfreigabe
  lesen die vorhandenen autoritativen Owner. Alte eigene Karten werden am
  Runtime-Einstieg konvertiert; sieben mitgelieferte Square8-Originale sind
  unter `maps/legacy` byteerhalten archiviert.
- Gameplaywürfe sind normalisiert: intern 0..1, Anzeige 0..100 %. Der Root
  speichert getrennte Boden-, Raum- und Luftsequenzen. Diagnose- und UI-Leser
  verbrauchen keine Würfe. Die Navigation entscheidet Wege, ohne dafür zu würfeln.
- Die Hostinteraktionskomponente ist aus dem großen Driver ausgelagert.
  Befehlsannahme, Abbruch und Veröffentlichung behalten ihre bisherigen Owner.
  Die Basisdarstellung liest vier benötigte Werte statt voller tiefer Snapshots.
- Speicherdialoge zeigen den tatsächlich fortsetzbaren Stand. Der erste normale
  Basisstart schreibt einen Checkpoint; fehlgeschlagene Saves werden kurzfristig
  wiederholt. Alte echte Dateipaare werden durch Continue → Hex-Save → Continue
  geprüft, einschließlich der nächsten Zufallsfolge.
- Sternkarte und Smart Mobile erhalten den aufklappbaren Ortsbaum, gemeinsame
  Anzeigenamen und die tatsächlichen Kampagnenfreigaben. Farbige Bilder, Porträts
  und Icons bleiben erhalten. Lokale Rajdhani-Schriften und gecachte Controls
  setzen die kompakte Gestaltung um.
- Das System heißt **Börner**. Jeder Planet und Mond besitzt einen OM-Knopf und
  eine gemeinsame Körper-Orbitkarte. Frühere nummerierte Ankunftspunkte bleiben
  als kompatible Reise-IDs erhalten; sie erzeugen keine zusätzlichen Karten.
  Orts-/Orbitinspektion verändert keine Reise. Unbekannte Ansichten bleiben
  schwarz; bekannte Orte lesen ihren vorhandenen Erkundungsstand.
- Koop, PvP und Koop-PvP teilen die Steuerung innerhalb des Teams. Gleichzeitige
  Karten besitzen getrennte SimulationRoots und Sichtstände; jeder Peer wählt
  seine Ansicht unabhängig. Auswahl und Kamera bleiben bei fremdem Rejoin
  erhalten. Terrainwissen stammt auch auf Replikaten ausschließlich vom Host.
- Kenney-Bodenmodule bekommen sechseckige Fußabdrücke. Hexkonturen folgen
  Gelände, allen Rampenrichtungen und begehbaren Modellböden. Figuren verwenden
  dieselbe rein visuelle Stützhöhe. Logische Höhe, Kollision und Sicht bleiben
  bei Terrain-/Groundowner. Farbkorrektur, Schattenbatches und 46 Personenpaletten
  sind getrennt gegen Originalquellen geprüft.
- Stationswände, Ecken, Tore und dünne Böden folgen den freigegebenen
  Lagerhausachsen. Alle neun Ensembles der großen Station sind enthalten.
  Boden unter Wänden und Props bleibt sichtbar; an Baugrenzen kann derselbe
  Hexboden innen hell und außen rot erscheinen. Unnötige Rohre sind entfernt,
  Raumprops erhalten, Felsen gezielt gruppiert und freie Flächen sparsam mit
  rein dekorativen Kieseln ergänzt. Der Kenney-Katalog nennt tatsächliche
  Verwendungen, Quellenprüfsummen und Anpassungen.
- Der statische Karten-Cache hält kein zweites vollständiges Live-Hexraster.
  Alle drei großen Karten passen dadurch einschließlich vollständiger
  Übergabe an eine neue Ansicht unter das unveränderte 256-MiB-Limit.
  Die 18 Gebäude der großen Station teilen 86 Materialvarianten für 783
  Meshteile; konstante Materialgrenzen belegen keine Instanzuniforms mehr.

## Wie die Nachweise zu lesen sind

`summary.json` zählt pro aufgeführtem Fall ausschließlich den neuesten
akzeptierten Lauf mit Assertions, fehlerfreier Engine und bestandenen Guards.
Die vollständigen Versuche einschließlich roter Diagnosen, verworfener Fixtures
und Zeitlimits liegen in `regression_evidence.zip`. Ein früherer grüner Lauf
ersetzt keinen neueren fehlgeschlagenen Lauf desselben Falls.

Der Fünf-Einsätze-Fall verlangt an jedem Meilenstein den ausdrücklich
erzwungenen manuellen Savepfad und lädt die tatsächliche Datei wieder. Jobstand,
Personen und Flotte müssen zum lebenden Owner passen. Ein bloßes `ok` mit
`throttled` aus dem normalen Autosaveintervall ist kein Speichernachweis.
Die früheren Diagnoseversuche mit dieser zu schwachen Fixture bleiben im
Archiv; ihre physischen Heimkehren ersetzen keinen Dateinachweis.
Die separate `diagnostic_post_benit_continue` verwendet den unveränderten
tatsächlichen dritten Heimstand und erwartet nur zwei weitere Rückkehren.
Besteht diese Fortsetzung, schließt sie die belegte Kette der fünf Einsätze.
Sie ersetzt dann den unvollständigen Fünferlauf in der Abschlussliste, ohne
dessen 198 bestandene Einzelprüfungen zusätzlich mitzuzählen. Ein neuer
vollständiger Fünferlauf in einem Prozess wird damit nicht behauptet.
Herkunft, Datei und frühere Fehlversuche bleiben im Archiv.

Die tatsächlichen Programme laufen seriell in privaten Godotprofilen.
Native Bilder entstehen mit Godot 4.6.2 / GL Compatibility auf einem nie
aktivierten privaten Windows-Desktop. Viewport-Eingaben gehören zum Testprozess;
es werden keine Tastatur- oder Mausereignisse auf den Nutzerdesktop geschickt.
Quell-Snapshots und echte Benutzerprofile sind durch Prüfsummen geschützt.

`graphics_inventory.json` und die ergänzende UI-Galerie ordnen Originalreferenzen,
Vorher- und Nachherbilder sowie Quellenprüfsummen zu. Ein KI-Zielbild ist keine
Spielaufnahme. Die dritte UI-Revision bekam drei tatsächliche Spielbilder als
Eingabe; Prompts und Herkunft stehen unter `../starmap_mobile_20261113/references`.

## Grenzen

Diese Nachweise sind begrenzte automatisierte Funktions- und Darstellungstests,
kein menschlicher vollständiger Spieltest und keine pauschale Fehlerfreiheit.
Lokales ENet ist kein Internet-/WAN-Test. Die kleine CPU-Leseprobe beweist keine
Gesamtspiel-FPS oder GPU-Beschleunigung. Es wurde keine neue EXE angefordert.
Porträtpaletten ersetzen keine neu modellierten Gesichter und Frisuren.
Das persönliche Gestaltungsurteil bleibt im Websitebericht als Entscheidung
mit Kommentar und lokalem JSON-Export erfassbar.

Die Website behält ihre bestehende private Zielgruppe. Ein gesicherter Bericht,
ein Git-Push und ein erfolgreich veröffentlichtes Hosting sind getrennte
Ergebnisse; der tatsächliche Hostingstatus wird abschließend festgehalten.

## Abschließender Kampagnenumfang

Der vollständige Kampagnensieg bleibt unbestätigt. Drei tatsächliche Einsätze mit geschriebenen Heimständen sind nachgewiesen. Spätere Versuche zeigten Kampfverluste und zusätzliche Bewegungsblockaden. Die Blockaden sind gezielt behoben und regressionsgeprüft; ein erneuter vollständiger Erfolgslauf wurde zur Begrenzung des Aufwands nicht gestartet. Fehlgeschlagene Läufe werden nicht als bestanden mitgezählt. Die letzten Proben verwenden normale Boarding-, Sammel- und Angriffsbefehle, ohne Lebenspunkte oder Gegner zu verändern.
