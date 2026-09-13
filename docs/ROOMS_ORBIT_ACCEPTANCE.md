# Abnahme · Räume, Suche und Raumkontakt

13.09.2026 · Godot 4.6.2.stable.official.71f334935 · Basiscommit 3eef3d7b7474c22ca6ca320e3aa769af3d73d604.

## Ergebnis

Die bestätigte Erweiterung ist spielbar: vier getrennte Basisräume mit Mittelgang, Küche/Auftragscomputer und freien Modulflächen; größere einzeln geladene Gebiete; orbitaler Stationsmarkt; Suchflug mit unbekannten Radarkontakten, Identifikation in der Nähe und Landung; zufälliger Raumkontakt mit Freibeuter, Pilot und Turmschütze, Ausweichzielen, Angriff und Rückzug. Niederlage führt beide Crewmitglieder und das beschädigte Schiff heim. Werkbankstufen, einfacher Helm samt tatsächlicher Ausrüstung und die erste Crewakte ergänzen den Fortschritt. Die weißen Kenney-Helmfiguren und das kompakte Icon-HUD bleiben erhalten.

Kartenflächen: Basis 320×320 m, Satellitengebiet 640×640 m, Station 160×160 m, Raumkontakt 480×480 m. Nur die aktive Karte hängt im Szenenbaum. Raumflug bleibt planar; die Stationsreise würfelt einmalig 35 % Begegnungschance. Zufallszustand, Entdeckung, Rollen und Kampf sind autoritativ und speicherbar. Schema-v1-Karrieren werden vor der v2-Migration geprüft.

## Bestandene Prüfungen

| Bereich | Bestanden | Ausführung / Beleg |
|---|---:|---|
| Neue Kernfunktionen | 67/67 | `tests/next_stage_core_test.gd` |
| Bestehende Kernregressionen | 100/100 | `tests/core_flow_test.gd` |
| Tatsächliches Produktfenster mit Maus | 63/63 | `tests/product_flow_test.gd`, `output/product-result.json` |
| Rahmenauswahl, Rechtsklick, Kamera | 13/13 | `tests/control_window_test.gd`, `output/control-result.json` |
| Welt, Kartenwechsel, Radar und Darstellung | 43/43 | `scripts/world/world_orbit_probe.gd`, `output/rooms-orbit/world-results.json` |
| Zwei echte ENet-Produktprozesse | 75/75 | `tests/network_run.ps1 -Visual -Port 28073`, `tests/network_report.md` |
| Vier Starts, Speichern und v1-Migration | 10/10 | `tests/save_lifecycle_run.ps1` |

Der Produktpfad benutzt reale Commands, GUI-Klicks und Welt-Raycasts: Werkstatt, Pause, Piratenkontakt, Station, Radar/Fund, Bergung/Auszahlung, Werkbankausbau, Verkauf, Helmherstellung/Ausrüstung und Crewakte. Der Startseed macht die Begegnung reproduzierbar; Erfolg und Inventar werden nicht in den Produktzustand injiziert.

Der ENet-Nachweis nutzt zwei getrennte Prozesse: Host besitzt Ida/Pilot, Gast Jaro/Turm. Drei vollständige Snapshot-Paare stimmen überein, einschließlich Pause, Raumkontakt und Wiederverbindung. Suche, Bergung, Turmkampf, unzulässige Besitzbefehle, Laden und einmalige Auszahlung sind geprüft. Beide finalen Fehlerlogs sind leer. Netzbelege: `C:/Users/bjoer/AppData/Local/Temp/sternenbuergerchen-network-e7849408add542848e41c5f26f8daa3a`. Speicherbelege: `C:/Users/bjoer/AppData/Local/Temp/sternenbuergerchen-lifecycle-n2-88e447a169a946eeaf80bc2f8ee1ed37`. Normale Nutzerkarrieren wurden nicht verwendet.

Sieben tatsächliche Spielansichten liegen im privaten Gesamtplan; lokale Belege unter `output/rooms-orbit/` und `output/product-crew-sheet.png`. Kurze Darstellungsstichproben pro Region ergeben etwa 13,4–13,5 ms Frameabstand p95 bei rund 75 Bildern/s. Bedingungen und Grenzen: `docs/FREIBEUTER_ASSET_METRICS.md`. Das ist keine allgemeine Leistungsfreigabe.

## Verbleibende Grenzen

- Wände/Felsen sind visuell. Hindernisnavigation, Türen als Spielsystem und Deckung folgen noch.
- Freie Modulflächen sind vorbereitet; Raumkauf und tatsächliches Anbauen sind noch nicht implementiert.
- Crewakte, Fähigkeiten und Ausrüstung sind real; Traits, Erfahrungslaufbahn, Bewerbungen und volle Charakterentwicklung folgen.
- Der erste Raumkampf enthält einen schwachen Gegner. Vollständiges Verwundungs-/Evakuierungs-/Respawnsystem, Bunker, Mining, Raum-Salvage, Hauling und PvP stehen aus.
- Koop ist mit zwei lokalen ENet-Prozessen geprüft. Internetvermittlung, Matchmaking, weitere Gäste und kompetitive Pausenregeln sind nicht abgenommen.
- Technische Prüfung und visuelle Sichtung ersetzen keine menschlichen Verständlichkeits- und Spielspaßtests.

## Veröffentlichung

Zusätzliche Lieferprüfung des Laufzeitcommits `d2d0c5b3bf9e77b1f59fc51325ecd6b06be0e93b`: Ein frisches Git-Archiv ohne `assets/local` wurde in Godot 4.6.2 importiert und mit isoliertem APPDATA gestartet. Import, kurzer Start und `tests/asset_delivery_test.gd` jeweils Exit 0, keine Fehler oder Warnungen. Sowohl Shuttle als auch Freibeuter besitzen ein gültiges Kenney-Ersatzmesh; der Pirat ist zusätzlich rötlich eingefärbt. Die gleiche Assetprüfung mit den lokalen Blender-Schiffen besteht ebenfalls. Evidenz: `C:/Users/bjoer/AppData/Local/Temp/sternenbuergerchen-delivery-fixed-97fa7723358b45358063f76b78feddae/result.json`. Der Reportgenerator wurde im ursprünglichen frischen Archiv auch ohne Bildbelege erfolgreich ausgeführt und kennzeichnet fehlende lokale Bilder.

Der mobile Gesamtplan ist als eigenständige private ChatGPT-Site veröffentlicht: https://sternenbuergerchen-neustart.klabauta.chatgpt.site. Er enthält Texte und tatsächliche Spielbilder, keine Spielquellen oder herunterladbaren Schiffsmodelle. Die lokale HTML wird aus `docs/reports/ROSTGRENZE_SPIELPLAN_TEMPLATE.html` und vorhandenen Bildern mit `tools/build_report.py` erzeugt. Lokale Blender-Modelle bleiben Git-ignoriert; im Clone stehen Kenney-Ersatzmodelle bereit.
