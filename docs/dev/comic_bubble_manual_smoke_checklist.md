# Comic Bubble Manual Smoke Checklist

## Ziel
Kurzer Sichtcheck fuer TASK_214 nach den Headless-Verifiern. Der Check bewertet Lesbarkeit, Timing, Nervfaktor und Abschaltbarkeit der Comic-Bubbles in der Mission-Map.

## Vorbereitung
- Godot 4.6.1/4.6.x starten.
- Mission-Testszene mit aktivem `TacticalController` und 2.5D-Primary-View oeffnen.
- Eine Karte mit mindestens einem aktiven blauen Fireteam, Objective, Contact-Moeglichkeit und sichtbaren Friendly-Rollen nutzen.

## Ablauf
1. Bubble-Modus `Normal` aktivieren.
2. Move, Defend, Take/Objective und GO ausloesen.
3. Pruefen: FTL-Bubbles erscheinen kurz ueber/nahe beim Fireteamlead, folgen dem Unit-Anker und verschwinden ohne dauerhafte HUD- oder Objective-Verdeckung.
4. Einen blockierten Befehl erzeugen, zum Beispiel ohne gueltiges Ziel oder mit deaktiviertem Flow.
5. Pruefen: Ablehnung ist knapp, visuell wichtiger als normale ACKs und veraendert das Command-Ergebnis nicht.
6. Bubble-Modus `Minimal` aktivieren.
7. Pruefen: normale ACKs sind ruhig oder weg, Blocked/Contact/Warning bleibt sichtbar.
8. Bubble-Modus `Aus` aktivieren.
9. Pruefen: Befehle bleiben spielbar, aber es erscheinen keine FTL- oder NPC-Bubbles.
10. Wieder `Normal` aktivieren und `show_npc_thoughts` halten.
11. Pruefen: NPC-Gedanken erscheinen nur solange die Taste gehalten wird, bleiben auf ausgewaehlte/visible Friendlys begrenzt und zeigen keine versteckten Gegnerinfos.
12. Zwischen Rollen wechseln oder Fireteam mit Medic/Pilot/Engineer/Leader ansehen.
13. Pruefen: Texte unterscheiden sich passend zur Rolle, bleiben kurz und wirken nicht wie neue Spielregeln.
14. Kamera zoomen/schwenken.
15. Pruefen: Bubbles bleiben lesbar oder verschwinden sauber; kein Flackern, kein dauerhafter Spam.

## Akzeptanznotizen
- Maximalzahl wirkt sichtbar: keine Bubble-Wolke bei schnellen Eingaben.
- Cooldown wirkt sichtbar: wiederholte gleiche Befehle spammen nicht.
- FTL-Text ist Rueckmeldung, NPC-Text ist Gedanke; beide bleiben Anzeige.
- Snapshot-/Viewer-Clients duerfen Bubbles zeigen, aber keine Commands, Effects, Damage, Heal oder KI-Entscheidungen erzeugen.

## Offene Sichtfragen
- Sind Dauer und Opacity angenehm?
- Verdecken Contact-/Objective-Marker zu oft wichtige Tiles?
- Sind Low-Skill-Texte unsicher, aber nicht verwirrend?
- Muss Minimal-Modus noch strenger werden?
