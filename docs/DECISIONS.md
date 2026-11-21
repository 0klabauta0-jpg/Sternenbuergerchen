# DECISIONS

## Format
- Datum:
- Entscheidung:
- Warum:
- Auswirkung:

## Bisher fest
- Godot 4.6.2 wird verwendet
- Codex arbeitet lokal gegen `C:\dev\SternenBuergerchen`
- Spieler ist Commander
- direkte Steuerung nur bis FTL
- Echtzeit ohne Pause
- Heimatbasis und FOB bleiben menügetrieben
- Multiplayer-Prototyp V1 mit Testteams
- Friendly Fire ist an
- Damage ist datenbasiert
- Respawn ist unbegrenzt mit Zeitverzögerung

## Architektur-Entscheidungen
- SimulationRoot ist die einzige autoritative Stelle fuer State-Mutationen; keine Gameplay-Wahrheit in UI oder Szenen-Glue
- Server-autoritativer SimulationRoot im Multiplayer: nur der Server verarbeitet Commands/Effects, Clients erhalten Snapshots
- Isometrisches 2D-Grid als Koordinatensystem; Tile-Positionen werden ueber konfigurierbare Iso-Konvertierung abgebildet
- A*-Pathfinding auf dem Iso-Grid mit drei Kostenvariablen: walkable, Hoehenunterschied, Surface-Kosten
- Datenbasiertes Combat statt Physik-Ballistik: Trefferchance und Schaden ueber Formeln mit Skill-, Cover- und Terrain-Modifikatoren
- Unit-Skills (accuracy, speed, leadership, toughness) als statische Werte pro Unit; beeinflussen Combat und Bewegung direkt
- Persoenlichkeitsmerkmale (Traits) als Skill-Modifikatoren ohne eigene Gameplay-Subsysteme
- Phasensystem (APPROACH, ASSAULT, HOLD) beeinflusst Feuerverhalten, Geschwindigkeit und Deckungswerte
- Fireteams (BLUE, GOLD) als Untereinheiten fuer selektive Befehlsvergabe
- Terrain-Daten (walkable, blocks_los, cover_value, height_level, surface_type) als leichtgewichtige RefCounted-Objekte in TerrainRegistry
- Respawn-Timer-Staffelung: Rover 30s, FOB 150s, Homebase 270s
- Host/Join ueber ENetMultiplayerPeer auf Port 7777 fuer V1; kein Matchmaking
- Multiplayer V1 bleibt Godot High-Level Multiplayer/ENet Direct-IP mit optionalem UPnP; Node.js/WebSocket ist keine aktuelle Architekturvorgabe
- `sternenbuerger-gdd.docx` ist Alt-GDD/Design-Inspiration und Migrationsquelle; bindend werden Inhalte erst nach Ueberfuehrung in Markdown-Docs/Tasks/Decisions
- Terrain-Konfiguration als JSON-Datei unter `res://maps/`; kein Godot-Resource-Format, damit auch externe Tools die Daten lesen koennen
- Map Editor als Runtime-Szene im Spiel, kein Godot-EditorPlugin; interner Workflow-Editor, nicht spielerseitig in V1

## Kampagne: Ausfall und Rückzug (15.11.2026, Paket 3a)

Vertrag: `docs/dev/campaign_casualty_retreat_contract.md`. Aufgabendatei: `docs/tasks/SPIELRUNDE_AUSFALL_RUECKZUG_2026_11_15.md`. Gilt nur in der Kampagne; Skirmish und Mehrspieler bleiben unverändert. Mit [B] gekennzeichnet sind Entscheidungen von Björn.

### Kein Respawn für eigene Leute in der Kampagne [B]
- Datum: 15.11.2026
- Entscheidung: In der Kampagne stehen eigene Ausgefallene nicht mehr nach einer Zeit von selbst wieder auf. Wer ausfällt, liegt 60 Sekunden „am Boden“ (ein Sanitäter kann ihn aufrichten), danach ist er „kritisch“. Tot ist nur, wer zurückbleibt; wer geborgen wird (Sieg, an Bord, höchstens 180 Einheiten vom Schiff), ist verwundet (leicht, mittel, schwer) und für 3, 15 bzw. 40 Minuten Echtzeit gesperrt. Ein Rückzug ist ein normaler Ausgang: Der Auftrag bleibt angenommen. Die Entscheidung ändert den Eintrag „Respawn ist unbegrenzt mit Zeitverzögerung“ für eigene Leute in der Kampagne; für Skirmish, Mehrspieler und Gegner gilt er weiter.
- Warum: Missionen sollen misslingen dürfen (Spielvision): Man zieht sich zurück, wird mit Nebenaufträgen stärker und kommt wieder. Mit Respawn kann ein Einsatz weder knapp ausgehen noch etwas kosten.
- Auswirkung: Die Ausfallzeiten und der Bergungsradius stehen in `data/singleplayer/casualty_rules.json` und sind vorläufig (ungespielt). Tragen und Bergen von Ausgefallenen folgt in Paket 3b.

### Was als Rückzug zählt [B, 15.11., 12:05]
- Entscheidung: „Evakuieren“ und jeder Abflug vom Einsatzort bei aktivem Auftrag, nach dem keine einsatzfähige eigene Person mehr am Ort bleibt, sind ein Rückzug. Bleiben Einsatzfähige am Ort, ist der Abflug in keiner Form ein Rückzug.
- Warum: Man soll mit nur einem Schiff Leute nachholen oder einen Außenposten halten können, während das Schiff weiterfliegt.
- Auswirkung: Die Regel ist im Code festgeschrieben (`_campaign_departure_empties_location`); gebaut wird „Truppen bleiben am Ort“ erst in Paket 3c.

### Personen, die die Kampagne voraussetzt, sterben nicht [B, 15.11., 23:07]
- Entscheidung: `campaign_outpost_recruit`, `campaign_rescue_pilot`, der Pilot eines Schiffs und der Anwerber des Polisa-Marktes können nicht sterben; sie überleben schwer verwundet.
- Warum: Der Kampagnenfortschritt setzt sie im Kader voraus; sonst entstünde ein unspielbarer Stand.
- Auswirkung: Ihr Eintrag in `casualties` trägt `protected_from_death`; sie zählen als schwer verwundet geborgen, mit Ausfallzeit und Einsatzsperre. Die Prüfung gilt je Person, nie für den ganzen Einsatz.

### Einsatzsperre nur an der Heimatbasis [B, 15.11., 23:07]
- Entscheidung: Ein Schiff mit einer Verwundeten an Bord darf direkt den nächsten Einsatzort anfliegen. Die Einsatzsperre gilt nur an der Heimatbasis (Einschiffen und Start eines dort gelandeten Schiffs). Das ist gewollt, keine Lücke.
- Warum: Unterwegs darf eine Verwundete an Bord keinen Flug sperren, sonst könnte ein Schiff nach einem Einsatz nirgends mehr anlegen.
- Auswirkung: Ketteneinsätze umgehen die Einsatzsperre bewusst.

### Treibstoff: so weit, wie er reicht [B, 15.11., 23:07]
- Entscheidung: Das Schiff fliegt so weit, wie der Treibstoff reicht: entweder nicht in den Orbit oder in den Orbit; für den Warpsprung muss der Treibstoff vorher reichen; im Zweifel kommt später ein Tankschiff.
- Warum: Der Treibstoff bleibt eine echte Grenze; im Zweifel hilft ein Tankschiff (wie die Starfarer).
- Auswirkung: Umgesetzt am 21.11. im Tanker-Auftrag, Abschnitt T1: Jede Etappe (Abheben, Sprung, Anflug, Ortsabflug, Landung) bucht ihren eigenen Anteil genau einmal, wenn sie beginnt; die Summe je Strecke bleibt der bisherige Wert. Die pauschale Hin-und-Rückflug-Reserve (Übergangsregel von Paket 3a) entfällt; "liegen geblieben" ist ein abgeleiteter Zustand. Tankschiff und Notdienst folgen in späteren Abschnitten.

### Malus bei Totalverlust [B: es muss einen geben; Ausgestaltung V]
- Entscheidung: Bei Totalverlust (Pilot ausgefallen, niemand vom Bodentrupp einsatzfähig, oder kein Truppführer oder Pilot im Kader übrig) stirbt niemand; der Rücksprung zum Basisstand gilt als Notbergung und kostet 25 % des Guthabens (mindestens 50 Credits), macht alle am Boden Gelegenen leicht verwundet und senkt die Moral um 0,08.
- Warum: Der Rücksprung soll etwas kosten und sich nicht durch Neuladen umgehen lassen.
- Auswirkung: Umgesetzt (Task 5b, Commits `ad3428128`, `e947cded6`), Prüfung läuft (Stand 16.11.2026). Der Malus wird beim Laden des Basisstands angewendet, der Basis-Checkpoint danach sofort neu geschrieben; Einzelheiten im Vertrag, Regel 7.

### Ausstehender Malus in einer Zusatzdatei [Ruling des Koordinators, 16.11.2026, Björn zur Kenntnis]
- Entscheidung: Die Checkpoint-Datei bleibt beim Totalverlust unberührt. Der ausstehende Malus steht in einer Zusatzdatei `pending_total_loss_v1.json` neben `checkpoint_v1.json` (mit `loss_id`, `job_id`, `penalty` und der Prüfsumme des Stands, auf den sie sich bezieht). Beim Laden wird er angewendet, wenn die Prüfsumme passt; danach wird der Basis-Checkpoint geschrieben und die Zusatzdatei gelöscht. Eine veraltete oder unlesbare Zusatzdatei wird ohne Wirkung gelöscht, eine neue Kampagne löscht sie.
- Warum: Die ältere Zusicherung „ein verlorener Einsatz überschreibt den letzten sicheren Stand nie“ gilt seit vor diesem Paket und wird von Tests geprüft. Die erste Bauart (Eintrag im Checkpoint) brach sie (`campaign_casualty_debrief_retry_test` 161/3).
- Auswirkung: Wer die Zusatzdatei von Hand löscht, entgeht dem Malus (privates Projekt, hingenommen). Ändert ein Speichervorgang den Checkpoint zwischen Totalverlust und Laden, entfällt der Malus; im Normalfall sperrt der Checkpoint-Guard das Speichern. Der Test `astra_campaign_fixes_20261113.gd` Zeile 57 wird bewusst falsch (nicht lauffähig ohne Isolations-Setup).

### Lange Testläufe werden nachgeholt [B, 15.11., 18:27]
- Entscheidung: Lange Testläufe (alles über etwa 5 Minuten) werden in den Aufgaben ausgelassen und nach dem Merge gesammelt nachgeholt.
- Warum: Anweisung von Björn („überspringe so lange Tests und mach die später“). Der Kern der neuen Tests und die kurzen Läufe laufen weiter.
- Auswirkung: Was nicht gelaufen ist, gilt nicht als bestanden; die Nachhol-Liste steht in der Aufgabendatei.
