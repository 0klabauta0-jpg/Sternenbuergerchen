# Spielrunde, Paket 3a: Ausfall und Rückzug in der Kampagne (15.11.2026)

Status: Entwurf. Regeln mit [B] hat Björn am 15.11.2026 entschieden (Projektdokument `claude/Spielvision.md`, Abschnitt 4). Regeln mit [V] sind Vorschläge und noch nicht freigegeben.
Arbeitsplan: `docs/superpowers/plans/2026-11-15-ausfall-und-rueckzug.md`.

## Ziel / Problem

Heute steht jede ausgefallene Person nach 30 Sekunden wieder auf (Respawn), in jedem Spielmodus. Bleibt am Ende trotzdem jemand liegen, wertet die Kampagne den Einsatz als Niederlage und springt zum letzten Basisstand zurück. Ein Einsatz kann dadurch weder knapp ausgehen noch etwas kosten, und ein Rückzug gilt als gescheiterter Auftrag.

Ziel ist die Runde aus der Spielvision: Missionen dürfen misslingen, man zieht sich zurück, wird mit Nebenaufträgen stärker und kommt wieder.

## Regeln

Sie gelten nur in der Kampagne. Skirmish und Mehrspieler bleiben unverändert.

1. **Kein Respawn für eigene Leute.** [B]
2. **Versorgungsfrist.** Wer ausfällt, liegt 60 Sekunden „am Boden“. In dieser Zeit kann ein Sanitäter ihn wieder aufrichten. Danach ist er „kritisch“ und kann im Feld nicht mehr aufgerichtet werden. [V]
3. **Tot ist nur, wer zurückbleibt.** [B] Solange es das Tragen noch nicht gibt (Paket 3b), gilt als geborgen [V]:
   - bei Sieg jeder Ausgefallene (das Gebiet ist gesichert);
   - sonst, wer an Bord ist oder höchstens 72 Einheiten vom gelandeten Schiff entfernt liegt.
4. **Verwundungsstufen.** [B: abgestuft; Zuordnung V]
   - leicht: im Einsatz ausgefallen und vom Sanitäter wieder aufgerichtet;
   - mittel: am Ende „am Boden“ und geborgen;
   - schwer: am Ende „kritisch“ und geborgen.
5. **Ausfallzeit in Echtzeit**, auch während andere im Einsatz sind: leicht 3 Minuten, mittel 15 Minuten, schwer 40 Minuten. Die Werte stehen in `data/singleplayer/casualty_rules.json` und sind vorläufig. [V]
6. **Einsatzsperre.** Verwundete können an der Basis nicht eingeschifft werden; die Ablehnung nennt Name, Stufe und Restzeit. [B]
7. **Totalverlust.** Fällt der Pilot aus, ist am Ende niemand vom Bodentrupp mehr einsatzfähig, oder bliebe nach den Toten kein Truppführer oder kein Pilot im Kader, dann stirbt niemand: Der Einsatz gilt wie heute als verloren und die Kampagne springt zum letzten Basisstand zurück. [V]
8. **Rückzug ist ein normaler Ausgang.** Nach „Evakuieren“ bleibt der Auftrag angenommen und kann ohne „Erneut annehmen“ wieder angeflogen werden; die Zahl der Rückzüge wird mitgezählt. [B]

## Nicht-Ziele dieses Pakets

- Tragen und Bergen von Ausgefallenen (Paket 3b; braucht den Missionscontroller und die Einzelsteuerung).
- Der Ort merkt sich nach einem Rückzug getötete Gegner, Türen und Aufklärung (Paket 3c).
- Krankenstation, die Ausfallzeiten verkürzt (Etappe 2).
- Änderungen an Skirmish, Mehrspieler, Gegner-Respawn, Eingabe oder Missionsansicht.

## Relevante Verträge

`docs/dev/campaign_introduction_contract.md` (Zeilen 82 und 117–121 werden geändert), `docs/dev/mission_evacuation_abort_contract.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/dev/singleplayer_locations_jobs_contract.md`, `docs/dev/base_automatic_rest_contract.md`, `docs/dev/mission_interaction_point_contract.md`. Neu: `docs/dev/campaign_casualty_retreat_contract.md`.

## Akzeptanz

1. In einem Kampagneneinsatz steht ein Ausgefallener nicht von selbst wieder auf; in Skirmish weiterhin nach 30 Sekunden.
2. Ein Sieg mit einem Ausgefallenen endet als Sieg mit Belohnung; die Person ist danach verwundet und für die Ausfallzeit gesperrt.
3. Ein Rückzug mit einem Ausgefallenen außerhalb des Radius: Die Person ist tot und aus Kader, Basis, Trupp und Schiffsbelegung entfernt; der Auftrag bleibt angenommen.
4. Pilot ausgefallen oder ganzer Bodentrupp ausgefallen: Rücksprung zum Basisstand wie heute, niemand stirbt.
5. Speichern und Fortsetzen erhält Verwundung, Restzeit und Tote. Ein mehrfach zugestelltes Missionsergebnis wendet Verluste genau einmal an.

## Betroffene Dateien

Siehe Arbeitsplan. Geteilte Datei: `scripts/tests/mission_tactical_sandbox_controller.gd`, nur `request_campaign_crew_boarding` und `get_campaign_pilot_flight_guard`; vor Beginn in der Abstimmungsnotiz eintragen.

## Risiken / offene Punkte

- Der Kampagnen-Checkpoint verlangt den Truppführer an Kaderplatz 0 und den Piloten an Platz 1; Tod des ersten Truppführers braucht eine Nachrückregel (Aufgabe 6 im Plan).
- Ob der Respawn auf Hex-Karten heute überhaupt greift, ist ungeklärt (`begin_hex_respawn` hat keinen Aufrufer). Aufgabe 2 prüft das zuerst.
- Balance der Ausfallzeiten ist ungespielt.
