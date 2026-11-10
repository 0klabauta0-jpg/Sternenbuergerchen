# Kampagne und vorbereitete Skirmish-Starts — Prüfbericht

Stand: 10.11.2026. Godot 4.6.2, eigener Branch
`task/campaign-skirmish-rebuild-20261110` auf e765f507c. Bewusst auf noch nicht
integrierten Orts-/Gebäudearbeiten. Vorhandenes fremdes Terrain-/Playtest-WIP
wird nicht übernommen oder überschrieben.

## Umsetzung
Fünf datengesteuerte Aufträge auf drei großen 96 × 98-Bodenkarten und einem
separaten orbitalen Gefecht. Physische Chip-/Kistenfracht, Heimkehr/Upload,
Blueprints/Herstellung, NPC-Zuwachs 2 → 3 → 4 und zweites Schiff/Pad.
Cutlass feindlich; Buccaneer neutral. Persönliche Namen und reales Inventar
werden über die vorhandenen Owner/Commands geändert. Drei Skirmish-Vorlagen
laden getrennt Early 8/3, Mid 20/5 und Late 30/6 Personen/Schiffe mit erreichbarer
Betten-/Padkapazität. Kampagnenreihenfolge sperrt Skirmish nicht.

## Aussagegrenze
Mid-/Late-Schiffe ohne vorhandene Modelle bleiben bezeichnete Platzhalter.
Trägerhangar, Fahrzeugtransport, Aufmunitionieren, Medic-Bed und allgemeiner
Flottenraumkampf sind damit nicht als fertig freigegeben. Keine neue EXE,
Mainintegration, Multiplayer- oder allgemeine Performancefreigabe.
SVG-Icons/Feldbetten sind vorläufige Funktionsdarstellungen; vorhandene
Schiffs-/Gebäudequellen unverändert. Quellenstatus: visual_sources.json.
Native Gestaltung und menschlicher Spielspaß wurden hier nicht abgenommen.

## Testumgebung und Belege
Headless ohne Fokuswechsel. Isolierte Projektkonfigurationen unter
`output/campaign_rebuild_20261110/probe_project` und `probe_regression` verwenden
getrennte Benutzerdaten; Spielquellen und Assets sind über lokale Junctions
identisch. Die Regressionen verändern keine echten Teamdateien.
Vollständige Rohlogs liegen unter `output/campaign_rebuild_20261110/`.
Ausgewählte finale Logs werden diesem Bericht beigelegt.

| Prüfung | Ergebnis |
| --- | --- |
| Kampagnenowner: Sperren, Chip/Upload, Restore/Tamper |15/0|
| Fünf Aufträge über die Zustandsowner, Flotte, leere Ortsressourcen, echte Herstellung |54/0|
| Physische Questfracht, volle Fracht und Wiederholungen |PASS|
| Raumgefecht: reale Zeitschritte, neutraler Schutz, Sieg/Verlust |PASS|
| Szenario-/Mapparser, Inhalte, Hex-Erreichbarkeit |68/0|
| Mining/Salvage: Sichtlinie, Werkzeug, Dauer, Unterbrechung, endlicher Ertrag |14/0|
| Vorbereitete Skirmish-Daten/Menü |209/0|
| Drei echte Skirmish-Flowstarts, Ausrüstung/Flotte, Teamisolation |97/0|
| Betten-/Padkapazität mit echten AStar-Verbindungen |169/0|
| Basis-/Rekrutenruntime und Umbenennen |41/0|
| Echter Kampagnenstart inklusive Pistole/leichter Rüstung beider NPCs |13/0|
| Bestehendes Kampagnenmenü |29/0|
| Inventartransfer und tatsächlicher Inventar-UI-Pfad |PASS|
| Reiseowner inklusive vier Außenzielen |67/0|
| Datengesteuerte Sternkartenorte und echte Auswahl-/Anflugbuttons |26/0|
| Bestehende Sternkarten-UI/Kamera |91/0 und18/0|
| Stationäre Interaktion, aktiver MOVE vor Use, Sammeln und Ausfallgrenzen beim Rückflug |21/0|
| Bestehende Ankunft-/Hold-Regressionsprüfung |10/0|
| Echter erster Ausflug mit Heimtransport/Upload/Speichern |55/0 bei 4× Simulation|
| Letzter tatsächlicher Missionslauf ab geprüftem Basisstand, finaler Save und echtes Continue mit 4 Personen/2 Schiffen/Pad 2 |77/0|
| Skirmish-Herstellung über tatsächliche Adapter/Owner und sichtbare Aktion |12/0|

Die Domainkette verwendet ausdrücklich Testbelege für Missionsgates. Davon
getrennt führen die tatsächlichen Ausflugsverifier Bewegung, GO, zeitgesteuertes
Use, Kampf, Boarding, Flug und Landung über die produktiven Runtimepfade aus.
Fortsetzungen an geprüften Basis-Checkpoints gehören zu diesem Lauf; kein
ununterbrochener nativer Fünf-Missionen-Playtest wird behauptet.

## Reproduzierte und korrigierte Blockaden
- Leeres Verteidigerteam verschwand aus der Taktikliste; es bleibt nun als
  tatsächlich beobachtete Gruppe mit Zählwert0 bekannt. Nicht gespawnte,
  unbekannte Gruppen zählen nicht automatisch als besiegt.
- Die echte Vitalität verwendet down/bleedout/respawning, nicht downed/dead.
  Nur fit blockiert den Verteidigergate. Regressionen mit echtem TestUnit.
- Authored weak guard metadata wird im neuen endlichen Kampagnengefecht
  tatsächlich als Pistole übernommen. Historische Szenarien bleiben unverändert.
- Wiederbesuch/Retry bekommt frische Szenariogates, behält aber endliche
  Ressourcen. Orbitzuordnung und Sternkarten-UI kennen die neuen Orte.
- Volle normale Fracht blockiert keine einmalige, reservierte Questfracht.
  Lieferung prüft die wirkliche Kiste vor Abflug; Chips zahlen erst zuhause.
- Bereits erreichbare Computer erzwingen kein erneutes Bounding-Manöver.
  Explizites GO kann eine noch offene Annäherung zum selben Computer ablösen;
  die echte Use-Zeit und Kontakt-/Reichweiten-/Aufenthaltsgrenzen bleiben aktiv.
- Bekannte Orte ohne Miningvorkommen dürfen einen leeren Ressourcenstand
  speichern; unbekannte Orte und manipulierte Mengen bleiben ungültig.

## Spielstandbereinigung und Git
Genau ein alter Kampagnenstand wurde auf ausdrücklichen Nutzerauftrag entfernt:
`campaigns/introduction/checkpoint_v1.json`. Alle 61 zuvor erfassten Profildateien
sind nach SHA-256 bytegleich erhalten. Einstellungen, Editor-/Mapdateien und
Quellen wurden nicht gelöscht. Beleg: save_cleanup_result.json.

Alle 24 hier beigelegten finalen Logs sind ohne Script-/Runtimefehler. Frühere
rote Läufe dienten der Reproduktion; die Tabelle nennt die abschließenden
Resultate. Arbeitsbranch und gezielt gewählte eigene Dateien werden nach dieser
Prüfung committed und gepusht; fremdes WIP bleibt lokal erhalten.
