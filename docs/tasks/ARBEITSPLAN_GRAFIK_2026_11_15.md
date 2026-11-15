# Arbeitsplan Grafik-Strang, Stand 15.11.2026 vormittags

Der Plan entsteht im Hauptchat. Die Pakete werden von Hilfsagenten abgearbeitet, je Paket ein eigener
Arbeitsordner und Branch. Der Hauptchat prueft das Ergebnis, laesst die Tests auf dem Windows-Rechner laufen
und bringt es nach `main`.

## Erledigt (auf `main` seit 15.11., `6568233a1`)
P1 bis P3 wie unten, dazu P4 Ruestungsvergleich, P5 schwere Ruestung R08, P6 UI-Dichte Heimatbasis.

### P1: Pads der Heimatbasis anheben, alte Stationskarten aus der Auswahl
- Heimatbasis: Die Landepads liegen heute buendig im Boden. Ziel: Deckoberkante 0,12 ueber dem Boden wie auf den
  Missionskarten (`PAD_DECK_TOP` in `scripts/terrain/place_reference_dressing.gd`). Schiffe und Personen auf dem
  Pad stehen auf dem Deck. Einstiegspunkte und Bedienung bleiben unveraendert.
- `station_outpost_64x64` und `station_outpost_192x192` verschwinden aus der Kartenauswahl des Spielers. Die
  Dateien bleiben als Testkarten; alle Tests laufen weiter.

### P2: Flugabwehr, Anflugstil und Reparatur
- Der Anflugstil (vorsichtig / normal / aggressiv) wird gespeichert und wirkt:
  - vorsichtig: Tiefflug (Profil `low`), dreht bei Beschuss ab, Landestreuung x 1,5
  - normal: normale Hoehe, dreht bei Beschuss ab
  - aggressiv: normale Hoehe, fliegt unter Beschuss weiter und landet
- Reparatur: Der Reparaturdienst eines Pads stellt auch die Integritaet aus dem Flugabwehr-Schaden wieder her.
- Feststellen und aufschreiben, ob dieser Schaden ueber die Mission hinaus bestehen bleibt.

### P3: Bestandsaufnahme Bedienoberflaeche (nur lesen und messen)
- Nutzerurteil 14.11.: Die Oberflaeche wirkt klobig und breit, "eher Handy als PC". Zielbild ist
  `Referenzbilder_Bestaetigt/03_UI/mockup_a5_mission_zweireihig.png` (kompaktes Band unten, kleine Quadrate).
- Ergebnis: Bilder des heutigen Zustands bei 1920 x 1080, gemessene Groessen, wo die zentralen Stilwerte liegen,
  und eine Tabelle mit Vorschlagswerten fuer eine PC-Dichte. Keine Aenderung am Spiel.

## Laufende Pakete (15.11. vormittags)

### P7: Missionsansicht an Entwurf A5 angleichen
- Plan mit allen Zielwerten: `docs/tasks/MISSION_HUD_A5_ANGLEICHUNG_2026_11_15.md`.
- Kern: Truppkarte 312 x 136 mit 88 hohen Portraits; Haltung, Feuerregel und Aufsitzen wandern ins Befehlsband;
  Dropship-Karte 312 breit und hoechstens 196 hoch; Zielkarte 440 x 64; Protokoll 312 x 120; Band 152 hoch.
- Branch `task/claude-p7-mission-a5-20261115`. Belegt aus den geteilten Dateien: eine Zeile in `mission_tactical_sandbox_controller.gd`.

### P8: Schwere Ruestung, Helm und Kragen zweite Runde (R09)
- Plan mit Form, Massen und Messkriterien: `docs/tasks/RUESTUNG_SCHWER_HELM_R09_2026_11_15.md`.
- Kern: Visier tief und breit unter einer Stirnwulst, kurze dunkle Maske, Ohrscheiben auf Visierhoehe, Helm sitzt im Kragen.
  Render- und Messwerkzeug kommt diesmal ins Repo.
- Branch `task/claude-p8-helm-r09-20261115`.

## Danach (noch nicht begonnen)
- Hauptmenue verdichten (Schiene 520 auf ca. 380, Knoepfe einheitlich), Sternkarte und Befehlsleiste der Heimatbasis.
- Schwere Ruestung dritte Runde: Schulterplatten, Oberarme.
- Begehbare Gebaeude am Freihafen (groessere Grundflaechen, Dach als eigenes Modellteil).
- Dachmodelle, Schiffssymbole der Sternenkarte, Warpblase.
- Flugabwehr: Fahrzeug als Bodeneinheit, Panzerfaust und Schienengewehr im Laden, Transportschiff.
