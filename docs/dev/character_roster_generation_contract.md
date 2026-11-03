# Character Roster Generation Contract

## Zweck
Der Start-Roster-Generator erzeugt beim ersten Spielstart ein lokales Spielerteam. Dieses Team ist die Grundlage fuer spaetere Persistenz, Progression, Beziehungen und Multiplayer-Ownership.

## V1-Vertrag
- Generator: `scripts/meta/start_roster_generator.gd`
- Schema-Version: `1`
- Defaultgroesse: `24` NPCs
- Erlaubter Bereich: `20` bis `30` NPCs
- Seed: string-basiert und reproduzierbar
- Spielergrenze: `player_profile_local`
- Persistenz: noch nicht Teil von TASK_232; Save/Load folgt in TASK_234

## Profilstruktur
Jeder Eintrag ist als `MetaUnitProfile` nutzbar und enthaelt:
- stabile `unit_id`
- `display_name`
- `callsign`
- `portrait_path`
- `team_id = team_alpha`
- `fireteam_id` als Vorschlagszuordnung
- `roster_role_category`
- Skills aus dem bestehenden Skill-/Trait-/Profile-Math-Pfad
- Traits aus dem bestehenden Trait-System
- maximal drei ableitbare Rank-Badges aus TASK_207

### Basiswerte und effektive Skills
Die Generierungsgrenzen `MIN_SKILL_VALUE`/`MAX_SKILL_VALUE` gelten fuer die
zufaellig erzeugten Basiswerte vor Traits. Gespeicherte `skill_values` enthalten
bereits Trait-/Profile-Math-Ergebnisse und verwenden den bestehenden
endlichen Runtime-Skillbereich 0.0 bis 1.0 (TASK_046). Beispielsweise ergibt Pilot-Toughness
0.36 mit `reckless` (-0.15) gueltige 0.21. Validierung und Save/Load erhalten
diese effektiven Werte; sie werden nicht an die Basisgrenzen angehoben.
Fehlende Pflichtwerte und nicht endliche Werte werden abgelehnt.

## Rollenmix
Der Generator muss diese Startkategorien abdecken:
- `leader`
- `medic`
- `shooter`
- `engineer`
- `pilot`
- `heavy_support`
- `scout_sniper`

Der Mix ist bewusst nicht perfekt. Jede erzeugte Runde hat Staerken und Luecken, damit Teamzusammenstellung interessant bleibt.

## Fireteam-Vorschlaege
Der Generator liefert erste Fireteam-Vorschlaege:
- jedes Roster-Mitglied erscheint genau einmal
- jeder Vorschlag hat `fireteam_id`, `unit_ids`, `leader_unit_id`
- Vorschlaege sind `balanced_not_optimal`
- Spieler duerfen spaeter umbauen

## Main-Menu-Ausloeser
Das Hauptmenue prueft beim Start, ob ein gueltiges In-Memory-Startroster existiert. Fehlt es, wird eines erzeugt.

Der Button `Neues Team generieren` ersetzt ein vorhandenes Roster nicht sofort:
1. erster Klick setzt eine Bestaetigungsgrenze
2. zweiter Klick erzeugt das neue Team
3. Persistentes Ersetzen und Archivieren bleiben TASK_234

## Multiplayer-Grenze
Roster sind pro Spielerprofil lokal. Host und Join duerfen eigene Roster besitzen. Ein voller privater Roster darf nicht ungefragt in Multiplayer-Snapshots veroeffentlicht werden; spaetere Modi muessen dafuer explizite Consent- oder Szenario-Regeln definieren.
