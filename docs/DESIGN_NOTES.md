# STERNENBUERGER – CORE GAME DESIGN

---

## 1. SPIELVISION

Sternenbürger ist ein taktisches Echtzeitspiel mit indirekter Kontrolle, bei dem der Spieler als Commander nicht einzelne Einheiten steuert, sondern Teams zusammenstellt und über Befehlsketten beeinflusst.

Der Fokus liegt auf:
- taktischen Entscheidungen im Einsatz
- Teamzusammenstellung
- Simulation von Verhalten statt deterministischer Kontrolle

Das Spiel soll sich anfühlen wie:
> „Ich gebe Befehle – und mein Team entscheidet, wie gut sie umgesetzt werden.“

---

## 2. INSPIRATIONEN

### 🎮 Referenzspiele

- **Star Citizen**
  - Gefühl von Rolle, Hierarchie und Einsatz
  - Fokus auf Immersion und Rollenverteilung
  - nicht die Simulationstiefe, sondern das *Gefühl der Verantwortung*

- Klassische Taktikspiele (Rainbow Six 1 / frühe Planungssysteme)
  - Phasenbefehle
  - indirekte Kontrolle
  - vorbereitete Abläufe

---

### 🧱 Technische / visuelle Basis

- **Kenny Tiles**
  - bewusst einfache, lesbare Darstellung
  - Fokus auf Funktion statt Grafik
  - schneller Iterationszyklus

👉 Wichtig:
Grafik ist aktuell **nur Mittel zum Zweck**, kein Designfokus.

---

## 3. SPIELERROLLE

Der Spieler ist:

👉 **Commander**

Nicht:
- Soldat
- einzelne Einheit
- klassischer RTS-Spieler

Sondern:
- gibt Befehle
- stellt Teams zusammen
- bewertet Ergebnisse

---

## 4. KERN-GAMEPLAY

### Befehlskette

```text
Commander (Spieler)
→ Fire Team Leader (FTL)
→ Units (führen aus)

Der Spieler sagt:

WAS passieren soll

Das System entscheidet:

WIE gut es umgesetzt wird
Beispiel

Befehl:

„Flankiere von links“

Ergebnis:

gute Teams → saubere Bewegung
schlechte Teams → Chaos, Fehler, Verzögerung
5. SPIELLOOP
Heimatbasis
→ Team zusammenstellen
→ FOB (Forward Operating Base)
→ Einsatz vorbereiten
→ Mission (Kern)
→ Debrief
→ zurück zur Heimatbasis
6. EINSATZ (KERN DES SPIELS)

Der Einsatz ist der wichtigste Teil des Spiels.

Elemente:
Echtzeit ohne Pause
indirekte Kontrolle
Sichtlinien (LOS)
Geräusche
Zustände (fit / down / bleedout)
einfache Physik / Wahrscheinlichkeiten
Befehlssystem

Commander gibt Befehle wie:

Move
Defend / Hold
Flank
Engage

FTL übersetzt diese in:

Bewegung
Positionierung
Feuerverhalten
7. TEAM-SYSTEM (KERNMECHANIK)

Das wichtigste System im Spiel.

Jede Unit hat:
Fähigkeiten (Schießen, Bewegung, Führung etc.)
Rollenpräferenzen
Eigenschaften / Persönlichkeit
Beziehungen zu anderen
Dynamik

Teams beeinflussen sich gegenseitig:

gute Kombination → bessere Leistung
schlechte Kombination → Konflikte

Beispiel:

Macho + emanzipierte Frau → negative Effekte
Konsequenz

👉 Der Spieler gewinnt nicht durch perfekte Befehle
👉 sondern durch gute Teamzusammenstellung

8. SIMULATION

Das Spiel basiert auf vereinfachter Simulation:

Trefferwahrscheinlichkeit statt Projektilphysik
Deckung als Wert
Verhalten als Ergebnis von Werten + Kontext

👉 Wichtig:
Keine vollständige Militärsimulation
→ sondern spielbare, nachvollziehbare Abstraktion

9. COMBAT

Minimaler Ansatz:

Treffer basierend auf:
Skill
Entfernung
Deckung
Zustände:
fit
down
bleedout
Friendly Fire möglich
10. META-LAYER
Heimatbasis
Team auswählen
Überblick über NPCs
Vorbereitung
FOB
Einsatzvorbereitung
Rollenwechsel
Mission starten

👉 bewusst:

menügetrieben
keine Simulation
keine offene Welt
11. DESIGNPRINZIPIEN
1. Indirekte Kontrolle

Spieler beeinflusst, steuert aber nicht direkt

2. Teams sind wichtiger als Units

Zusammenstellung schlägt Micro

3. Verhalten statt Skript

Ergebnisse variieren

4. Fehler sind Teil des Spiels

Nicht alles läuft perfekt

12. WAS DAS SPIEL NICHT IST
kein klassisches RTS
kein Shooter
kein Micromanagement-Spiel
kein Basebuilding-Spiel
13. PULSE / PERFORMANCE-GUIDELINES

(Wichtig für technische Umsetzung)

klare Systemtrennung:
SimulationRoot = Wahrheit
EventRouter = Kommunikation
RuntimeLeader = Verhalten
keine globalen SceneTree-Suchen
Batch-/Dirty-Updates statt Vollupdates
deterministische Tick-Verarbeitung

👉 Ziel:

viele Units möglich
stabile Performance
später Multiplayer-fähig
14. MULTIPLAYER-ZIEL

Langfristig:

PvP: Team vs Team
gleiche Voraussetzungen
eigene Teams aus Singleplayer mitbringen
15. LANGFRISTIGE FEATURES
Skillentwicklung
soziale Dynamik
persistente Teams
Map Editor
Fahrzeuge (Dropship, Rover etc.)
taktische Erweiterungen
16. KERN DES SPIELS (ZUSAMMENFASSUNG)
Der Spieler stellt ein Team zusammen,
gibt Befehle im Einsatz,
und erlebt, wie gut dieses Team diese Befehle umsetzt.