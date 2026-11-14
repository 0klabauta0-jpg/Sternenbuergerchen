# Arbeitsplan Grafik-Strang, Stand 14.11.2026 nachts

Der Plan entsteht im Hauptchat. Die Pakete werden von Hilfsagenten abgearbeitet, je Paket ein eigener
Arbeitsordner und Branch. Der Hauptchat prueft das Ergebnis, laesst die Tests auf dem Windows-Rechner laufen
und bringt es nach `main`.

## Laufende Pakete

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

## Danach (noch nicht begonnen)
- UI-Durchgang nach dem Ergebnis von P3.
- Schwere Ruestung nach `Referenzbilder_Bestaetigt/01_Ruestungen/03_Schwer_Mehransichten.png`.
- Begehbare Gebaeude am Freihafen (groessere Grundflaechen, Dach als eigenes Modellteil).
- Dachmodelle, Schiffssymbole der Sternenkarte, Warpblase.
- Flugabwehr: Fahrzeug als Bodeneinheit, Panzerfaust und Schienengewehr im Laden, Transportschiff.
