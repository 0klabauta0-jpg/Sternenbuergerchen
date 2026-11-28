# Auftrag: Funk, Sprechblasen und Persönlichkeit (5 Pakete) – Kopie für Bearbeiter

## Björns Vorgaben (28.11., 12:24)
- Am Fireteam gibt es schon Sprechblasen. Sie sind aber kryptisch und sitzen falsch. Die Blase gehört an die Fireteam-Karte und muss verständlich sein. Dort steht nur, was der Truppführer sagt.
- Was die anderen Mitglieder sagen, steht unten im Band, wenn das Fireteam ausgewählt ist.
- Beides soll da sein, und beides lässt sich abschalten oder minimieren.
- Die Persönlichkeit zeigt sich im Ton und im Handeln.
- Ton: beides, also ernst und mit Humor, je nach Person.

## Sprachregel für jeden Satz, den der Spieler sieht
„Alles, was lebt, wird gerettet; Gegenstände und Tote werden geborgen." Echte Umlaute (ä, ö, ü, ß), keine Ersatzschreibung wie „bestaetigt". Kein Englisch im Spiel (statt „Air Asset", „ORDERS?", „BLOCK", „LZ", „Recovery" deutsche Wörter).

## Was heute da ist (am 28.11. im Code gelesen)
- Sätze der Truppführer-Blase: `data/tactical_communication_copy.json` (kryptisch: „{team} bestaetigt Q{quality}", „{team} {role_label} P{phase}", „Air Asset bedroht", „ORDERS?"). Q = Funkgüte, P = Phase.
- Weitere Textquellen der Blase, in dieser Reihenfolge: Befehlsprüfung, `command_context`, `scripts/tactical/comms_lines_resolver.gd` (Daten `data/comms_lines.json`), `scripts/ui/comic_bubble_text_resolver.gd`, Ersatztext in `scripts/ui/fireteamleader_feedback_bubble_resolver.gd` (`_resolve_text`).
- Ereignis → Blase in `scripts/tactical/tactical_communication_resolver.gd` (`build_bubble_payload`). Gezeichnet in `scripts/terrain/terrain_map_3d_view.gd`; Blase hängt an Weltposition des Truppführers. HUD-Stelle halb vorhanden (`anchor_space == "hud"`, `hud_anchor_position`, um Zeile 9020), unbenutzt.
- Gedanken der Mitglieder: `scripts/ui/npc_thought_bubble_resolver.gd`, nur bei gehaltener Taste V.
- Schalter: `scripts/ui/comic_bubble_settings.gd` (Stufen off, minimal, normal, debug; Kategorien `ftl_command_feedback`, `ftl_status_feedback`, `npc_thought_peek`). Gespeichert in `user://sternenbuergerchen_settings.cfg`, Abschnitt `comic_bubbles`.
- Charakterwerte: `scripts/meta/character_gameplay_resolver.gd`. Eine Persönlichkeit gibt es noch nicht.
- Fireteam-Karte und Band: `scripts/ui/mission_a5_hud_layout.gd` (FireteamCard) und `scripts/tests/mission_tactical_sandbox_controller.gd` (`_build_fireteam_card` um 7836, `_apply_fireteam_mini_member_portrait_strip` um 6723).

## Paket 1 – Truppführer-Blase an der Fireteam-Karte, verständliche Sätze
1. Blase an die Karte: `anchor_space = "hud"` mit `hud_anchor_position` rechts neben der jeweiligen Fireteam-Karte (Spitze zeigt auf die Karte). Je Trupp höchstens eine Blase. Darf keine anderen Karten, das Band oder die Schiffskarte überdecken. Über der Figur auf der Karte erscheint keine Truppführer-Blase mehr.
2. Nur der Truppführer spricht dort.
3. Sätze neu schreiben in `data/tactical_communication_copy.json` und `data/comms_lines.json`: kein „Q{quality}", kein „P{phase}", keine Kürzel („ACK", „BLOCK", „OBJ"). Ganze kurze Sätze, Ich-/Wir-Form, höchstens ~8 Wörter („Verstanden, wir rücken vor.", „Feindkontakt links!", „Kommen hier nicht weiter – brauche neuen Befehl.", „Ziel gesichert.", „Unser Schiff wird beschossen!"). Funkgüte zeigt sich in der Wortwahl: schlecht = kurz („Kontakt!"), gut = genauer („Kontakt Nordost, zwei Mann, gehen in Deckung."). Deutsch, echte Umlaute.
4. Eine einzige Satzquelle für die Truppführer-Blase (bis Paket 3: `tactical_communication_copy.json`). Andere Wege fallen weg oder liefern nur den Anlass. Befehlsprüfung behält Fehlermeldungen, aber verständlich formuliert.
5. Blase steht 2–4 s je nach Länge. Wichtige Meldungen (Kontakt, blockiert, getroffen, gefallen) haben Vorrang vor Bestätigungen.
Fertig, wenn: Befehl an FT1 → Blase an Karte FT1 mit lesbarem deutschem Satz; nichts über der Figur; bei 1280×720 lesbar und nichts überdeckt; Prüfer zu Text/Lage der Blase angepasst; kleiner neuer Prüfer für Lage und Text.

## Paket 2 – Mitglieder sprechen im Band
Mitglieder im Band haben kleine Sprechzeile/Blase am eigenen Bild, letzter Satz 3–5 s, dann verblassen. Truppführer nicht doppelt. Anlässe: getroffen, liegt, braucht Hilfe, Magazin leer/Nachladen, Gegner erledigt, Kamerad fällt, Sanitäter versorgt, eingestiegen, Angst/Mut je nach Moral. Taste V zeigt Gedanken auch im Band statt über Figuren. Kein Fireteam ausgewählt → Band nichts; wichtige Sätze (liegt/fällt) zusätzlich als Zeile im Meldungsfenster mit Namen. Bremse: je Person ein Satz alle paar Sekunden, Band höchstens 2 neue Sätze/s.

## Paket 3 – Persönlichkeit
Typen: `profi` Profi (ruhig, knapp, ernst); `draufgaenger` Draufgänger (laut, frech, ungeduldig); `vorsichtig` Vorsichtig (angespannt, ernst, warnt viel); `spassvogel` Spaßvogel (Witze, auch unter Beschuss); `brummbaer` Brummbär (meckert trocken, macht aber mit).
Neue Satzdatei `data/comms/funk_saetze.json`: Anlass → Persönlichkeit → Sätze. Platzhalter `{name}`, `{team}`, `{richtung}`, `{ziel}`, `{kamerad}`. Je Anlass und Typ 2–3 Fassungen. ~15 Anlässe: Befehl verstanden, unterwegs, Ziel erreicht, Feindkontakt, blockiert, braucht Befehl, getroffen, liegt, gerettet, Kamerad fällt, Gegner erledigt, Magazin leer, Nachladen, eingestiegen, abgesetzt, Schiff in Gefahr, Auftrag erfüllt, Rückzug. Persönlichkeit wählt den Satz, Funkgüte die kurze oder genaue Fassung. Spaßvogel witzelt nie über Gefallene; bei „Kamerad fällt" sprechen alle ernst.

## Paket 4 – Persönlichkeit im Handeln (Werte in `data/comms/persoenlichkeit_wirkung.json`, 10–20 %)
## Paket 5 – Abschalten/Minimieren (Truppführer-Funk und Sätze der Mitglieder getrennt: Aus/Minimiert/An; Knopf an jeder Fireteam-Karte)
