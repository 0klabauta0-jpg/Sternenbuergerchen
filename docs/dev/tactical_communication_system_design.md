# Fireteam-Kommunikationssystem – Designdokument

## Was ist das System?

Der Spieler sieht nicht in die Köpfe seiner Fireteams – er bekommt nur das,
was die Leader ihm melden. Wie viel, wie schnell und wie präzise diese Meldungen
sind, hängt direkt von den Werten des jeweiligen Leaders ab. Ein schlechter
Kommunikator meldet zu spät, zu vage, manchmal gar nicht. Ein exzellenter Leader
gibt dem Spieler ein klares Lagebild in Echtzeit.

Das System hat zwei Modi:
- **Passiv**: Sprechblasen poppen kurz auf, verschwinden von selbst
- **Aktiv** (Taste gehalten, z.B. `C`): Alle aktuellen Meldungen aller
  Fireteams gleichzeitig sichtbar, plus interne Member-Kommunikation

---

## Kommunikationswerte

Es gibt keine neuen Skills. Die Werte werden aus bestehenden Skills abgeleitet:

### Kommunikationsquantität
*Wie oft meldet der Leader von sich aus?*

```
Basis: leader.leadership

< 30   → Schweiger: meldet nur bei kritischen Ereignissen
           (Member down, Leader down, Mission-Ereignis)
30–60  → Normal: meldet Feindkontakt, Befehle, Suppression
> 60   → Proaktiv: meldet auch kleinere Lageänderungen,
           Wegpunkt erreicht, Verdachtskontakte, Bound-Wechsel
```

### Kommunikationsqualität
*Wie präzise und schnell sind die Meldungen?*

```
Basis: leader.leadership / 100

Trait-Modifikation:
  "calm"      → +0.20
  "steady"    → +0.10
  "cautious"  → +0.05
  "aggressive"→ -0.10
  "reckless"  → -0.30

Ergebnis clamp(0.0, 1.0) → Qualitätsstufe 0–3:
  0.0 – 0.30 → Stufe 0
  0.30– 0.60 → Stufe 1
  0.60– 0.80 → Stufe 2
  0.80– 1.00 → Stufe 3
```

---

## Qualitätsstufen im Detail

### Stufe 0 – Schlechte Kommunikation
- **Verzögerung**: 2–4 Sekunden nach dem auslösenden Ereignis
- **Inhalt**: unvollständig, unsicher, manchmal falsch eingeschätzt
- **Kein Icon**: nur Text, manchmal nur ein Wort
- **Beispiele**:
  - Feindkontakt: *"...da ist was... glaub ich"*
  - Unter Beschuss: *"Scheiße scheiße—"*
  - Befehl empfangen: *"Ja... okay"*
  - Member down: *"...Delta ist weg glaub ich"*
- **Wichtig**: Stufe 0 kann keine Fakten ausgeben die nicht stimmen.
  Die Ungenauigkeit kommt durch Weglassen, nicht durch falsche Aussagen.
  *"Glaub ich"*, *"irgendwo"*, *"weiß nicht genau"* – nie *"alles klar"*
  wenn es nicht klar ist.

### Stufe 1 – Ausreichende Kommunikation
- **Verzögerung**: 0.5–1.5 Sekunden
- **Inhalt**: korrekt, aber knapp und ohne Detail
- **Manchmal Icon**: einfaches Symbol, kein Text dazu
- **Beispiele**:
  - Feindkontakt: *"Kontakt Nordost"*
  - Unter Beschuss: *"Unter Feuer!"*
  - Befehl empfangen: *"Verstanden"*
  - Member down: *"Delta ist down"*

### Stufe 2 – Gute Kommunikation
- **Verzögerung**: quasi keine (< 0.3 Sekunden)
- **Inhalt**: vollständig mit Richtung und Kontext
- **Icon + kurzer Text**: Daumen hoch, Warnsymbol etc. mit Begleittext
- **Beispiele**:
  - Feindkontakt: *"Zwei Feinde Nordost, hinter Deckung"* + Kontakt-Icon
  - Unter Beschuss: *"Schwerer Beschuss Südwest, brauche Deckung"* + Warn-Icon
  - Befehl empfangen: *"Bewege mich zur Position"* + Bewegungs-Icon
  - Member down: *"Delta down, Nordseite"* + Down-Icon

### Stufe 3 – Exzellente Kommunikation
- **Verzögerung**: keine (sofort)
- **Inhalt**: präzise Lageeinschätzung mit Position, Anzahl, Zustand
- **Klares Icon + vollständiger Text**
- **Beispiele**:
  - Feindkontakt: *"Zwei Feinde bestätigt, 40m Nordost, hinter Mauer,
    schwere Bewaffnung"* + Kontakt-Icon
  - Unter Beschuss: *"Drei Feinde Südwest, supprimiert, Delta ist down,
    brauche sofortige Unterstützung"* + Warn-Icon
  - Befehl empfangen: *"Alpha-Team, Bounding-Vorgehen, Ziel in 60 Metern,
    Bravo deckt"* + Bewegungs-Icon
  - Member down: *"Delta down, Nordseite hinter Mauer, braucht Erstversorgung"*
    + Down-Icon

---

## Persönlichkeit beeinflusst die Darstellung

Die **Qualitätsstufe** bestimmt *was* gesagt wird.
Der **Trait** bestimmt *wie* es aussieht und klingt.

```
"reckless" / "aggressive":
  → Sprechblase größer
  → Schrift fetter, Großbuchstaben bei Stressereignissen
  → Dickere, leuchtendere Kontur
  → Schreit in den Funk
  → Beispiel statt "Kontakt Nordost" → "KONTAKT NORDOST"

"calm" / "steady":
  → Kompakte, ruhige Blase
  → Normale Schriftgröße
  → Dünne, gedämpfte Kontur
  → Beispiel: "Kontakt Nordost. Wir reagieren."

"cautious":
  → Leicht kleinere Blase
  → Kursivschrift für unsichere Aussagen
  → Beispiel: "Möglicher Kontakt Nordost... warten wir ab"
```

Zusätzlich: Bei hohem Stress (Suppression + Member down gleichzeitig) wird
die Blase bei jedem Trait größer und hektischer – auch ein ruhiger Leader
verliert kurz die Kontrolle.

---

## Auslöser und Quantitätsfilter

### Immer (unabhängig von Quantität)
- Member geht `down`
- Leader geht `down` / Nachfolge tritt ein
- Objective-Zustand ändert sich
- Mission endet (Sieg oder Niederlage)

### Ab mittlerer Quantität (leadership > 30)
- Feindkontakt `confirmed`
- Befehl empfangen (Phasenübergang oder Ad-hoc)
- Suppression beginnt / endet
- Autonomes Flankieren durch Leader eingeleitet
- Rückkehr zum Plan nach Unterbrechung

### Nur bei hoher Quantität (leadership > 60)
- Feindkontakt `suspected` oder `spotted`
- Wegpunkt abgeschlossen
- Haltungsänderung (Stance)
- Bound-Wechsel bei Bounding/Caterpillar-Vorgehen
- Sektor-Alarm (Bewegung in ungesichertem Sektor)
- Feind verloren (`lost`)

---

## Cooldown und Spam-Schutz

Damit der Funk nicht zur Geräuschkulisse wird:

```
Pro Trigger-Typ: Cooldown 4 Sekunden
  (kein zweiter "Kontakt"-Ruf innerhalb von 4 Sekunden vom selben Fireteam)

Pro Fireteam: Max. 2 gleichzeitig sichtbare Blasen (älteste wird verdrängt)

Globaler Überlagerschutz:
  Sind mehr als 4 Blasen gleichzeitig aktiv → nur noch kritische Ereignisse
  werden als neue Blasen ausgespielt
```

---

## Anzeigedauer und Verhalten der Blasen

```
Passiver Modus (Blase poppt auf):
  Stufe 0:  3.5 Sekunden (langsam weil verzögert gemeldet, auch langsam weg)
  Stufe 1:  2.5 Sekunden
  Stufe 2:  2.0 Sekunden + Icon bleibt 0.5 Sekunden länger
  Stufe 3:  2.0 Sekunden + Icon bleibt 1.0 Sekunde länger

Aktiver Modus (Taste C gehalten):
  Alle Blasen aller Fireteams sichtbar
  Die letzten 3 Meldungen pro Fireteam gestapelt (älteste obendrüber, blasser)
  Member-interne Kommunikation zusätzlich sichtbar (kleiner, grauer Text)
  Lässt los → alle verschwinden außer der aktuell aktiven Blase
```

---

## Position der Blasen

- Blasen hängen direkt an der Leader-Unit auf der Karte
- Nicht an einer UI-Card oder einem Panel
- Damit bleibt der Fokus auf der taktischen Lage
- Überlappungsschutz: Wenn zwei Fireteams nah beieinander sprechen,
  wird die zweite Blase leicht nach oben versetzt
- Im aktiven Modus (C gehalten): Blasen werden leicht von der Unit
  weggezogen damit die Karte lesbar bleibt

---

## Die Textdatei: `comms_lines.json`

Das ist das Herzstück. Jeder Eintrag hat:
- Einen **Trigger** (was hat das Ereignis ausgelöst)
- Eine **Qualitätsstufe** (0–3)
- **Bedingungen** die vor der Ausgabe geprüft werden (Spielzustand)
- Mehrere **Varianten** damit es nicht repetitiv klingt
- Optionale **Trait-Varianten** für Persönlichkeit

### Struktur eines Eintrags

```json
{
  "trigger": "enemy_contact",
  "quality_level": 0,
  "delay_seconds": 3.0,
  "icon": null,
  "variants": [
    {
      "text": "...da ist was... glaub ich",
      "conditions": {
        "detection_state": ["suspected", "spotted"]
      }
    },
    {
      "text": "Kontakt... irgendwo vorne",
      "conditions": {
        "detection_state": ["confirmed"]
      }
    }
  ],
  "trait_overrides": {
    "reckless": {
      "variants": [
        {
          "text": "KONTAKT! IRGENDWO—",
          "conditions": { "detection_state": ["confirmed"] }
        }
      ]
    }
  }
}
```

### Bedingungsfelder (welche können geprüft werden)

```
detection_state      – Erkennungszustand des Feindes
                       ["unknown","suspected","spotted","confirmed","lost"]

friendly_status      – Zustand der eigenen Members
                       ["all_fit", "casualties", "critical"]
                       (critical = mehr als 50% down/bleedout)

suppressed           – true / false

objective_state      – ["uncaptured", "contested", "captured", "lost"]

active_command       – ["move", "defend", "engage", "flank", "take", "none"]

phase                – aktuelle Phasennummer (1, 2, 3...)

enemy_count          – "single", "few" (2-3), "many" (4+)
                       (abgeleitet aus bekannten confirmed-Kontakten)
```

### Wichtige Designregel
Kein Text darf eine positivere Lage beschreiben als tatsächlich vorhanden.
Die Qualitätsstufe 0 darf *weglassen* und *unsicher klingen*, aber nie
eine falsche Tatsache behaupten. Das Bedingungssystem stellt das sicher:
*"Situation clear"* ist nur spielbar wenn `detection_state == "unknown"`
für alle bekannten Feinde.

---

## Trigger-Kategorien (vollständige Liste)

```
enemy_contact          – Feind suspected/spotted/confirmed
enemy_lost             – Feind war confirmed, jetzt lost
taking_fire            – Fireteam unter aktivem Beschuss
suppression_start      – Suppression beginnt
suppression_end        – Suppression endet
member_down            – Member geht down
leader_down            – Leader geht down
leader_succession      – Neuer Leader übernimmt
order_confirmed        – Befehl (Phase oder Ad-hoc) empfangen
waypoint_reached       – Wegpunkt abgeschlossen
flanking_initiated     – Flankierbefehl gestartet (geplant oder autonom)
bounding_switch        – Bound-Wechsel (A deckt, B läuft)
sector_alert           – Bewegung in ungesichertem Sektor
objective_contested    – Objective wird bestritten
objective_captured     – Objective eingenommen
objective_lost         – Objective verloren
all_clear              – Kein Feindkontakt mehr (nur wenn wirklich clear)
returning_to_plan      – Rückkehr zum Plan nach Unterbrechung
```

---

## Interne Member-Kommunikation (nur bei gehaltenem C)

Wenn C gehalten wird, sieht der Spieler auch was der Leader intern
zu seinen Members sagt. Diese Texte sind kürzer, funktionaler, weniger
poliert – echte Feldkommunikation:

```
Stufe 2 / 3 Leader:
  "Bravo, du deckst – Alpha, vor!"
  "Sektor Nord, halten!"
  "Delta, bleib hinter mir"

Stufe 0 / 1 Leader:
  "Äh... ihr da vorne, warte mal"
  "Halt! Nein, weiter. Warte."
```

Members antworten (nur bei Stufe 3):
  "Roger"
  "Verstanden"
  "Auf dem Weg"

---

## Was das System nicht macht

- Keine Sprachausgabe (kein Voice Acting in dieser Implementierung)
- Keine permanente Log-Ansicht (kein Chat-Fenster)
- Keine Meldungen von Members direkt an den Spieler – immer nur über den Leader
- Keine Meldungen die den Spielzustand verfälschen

---

## Designentscheidungen (final)

1. **Sprache**: Militärischer Mix – Deutsch und Englisch gemischt.
   Kommandos und Funkjargon auf Englisch ("Contact!", "Roger", "Moving!"),
   Lageberichte und emotionale Aussagen auf Deutsch.

2. **Namen in Meldungen**: Leader nennt Members beim **Namen oder Fireteam**,
   je nach Kontext. Im Gefecht eher Fireteam ("Bravo ist down"),
   bei ruhigerer Lage eher Name ("Rodriguez, deckung!").
   Namen werden zur Laufzeit aus den Unit-Daten eingesetzt via Platzhalter
   z.B. `{member_name}` und `{fireteam_id}`.

3. **Außerhalb Sichtbereich**: Wenn die Unit nicht im sichtbaren Kartenbereich
   ist, erscheint die Meldung an der NPC-Karte im UI-Panel statt auf der Karte.

4. **Textdatei**: Wird als `comms_lines.json` direkt mitgeliefert.
