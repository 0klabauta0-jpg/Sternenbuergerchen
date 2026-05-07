# TASK_290 - User Handbuch Weekly Closeout

## Ziel
Als letzter Task der Woche soll ein echtes User-Handbuch fuer Sternenbuergerchen entstehen. Es beschreibt das Spiel aus Spielersicht: was man sieht, was man tun kann, wie Menues, Missionen, Teams, Befehle, Editor, Multiplayer und Einstellungen funktionieren.

Das Handbuch darf keine interne Designnotiz sein. Es soll Spielern helfen, das Spiel zu starten, zu verstehen und wiederzufinden, ohne Code- oder Taskwissen vorauszusetzen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_283 - Post Tactical Docs Consistency Audit
- TASK_284 - Gameplay Truth Architecture Boundary Audit
- TASK_285 - Tactical Decision Branch Integrity Review
- TASK_286 - UI Feedback Truth Regression Review
- TASK_287 - Editor Save Multiplayer Contract Regression Review
- TASK_288 - Regression Gate Coverage Gap Audit
- TASK_289 - Final Sneaky Code Review Patch Queue

## Kontext
Nach den vielen Taskreihen ist viel Wissen ueber Gameplay, UI, Editor, Multiplayer, Fog of War, Fireteams, NPC-Verhalten, Waffen, Audio, Assets, Huegel, Deckung und Hilfesystem entstanden. Dieses Wissen soll nicht nur in Taskdateien liegen, sondern als kompakter Einstieg fuer User verfuegbar werden.

Wichtig: Das Handbuch dokumentiert nur, was nach Review und Patchqueue als wirkliches Spielverhalten gilt. Geplante Features duerfen nur in einem klar getrennten Abschnitt "Noch in Arbeit" auftauchen.

## Umfang
1. Struktur des Handbuchs:
   - kurzer Spielueberblick.
   - Hauptmenue: Einzelspieler, Multiplayer, Editor, Einstellungen.
   - erster Spielstart und Team-/Roster-Erstellung.
   - Mission Map und Missionsstart.
   - Kamera, Auswahl, Befehle und Fireteam Leader.
   - NPCs, Gegner, Abstand, Deckung, Sichtlinien und Gefechtsrichtung.
   - Waffen, Reichweiten, Ausruestung, Gewicht und Spezialrollen.
   - Heiler-/Medic-Regeln.
   - Terrain: Huegel, Hoehen, Waende, Klippen, Sand, Randregeln.
   - Fog of War und Sichtmodi.
   - Audio, Rueckmeldungen, Sprechblasen, Gedanken und Help-Popups.
   - Multiplayer: Host, Join, Map-Download und Grenzen.
   - Editor-Grundlagen.
   - Einstellungen: Fenster, Aufloesung, Hilfe, Fog of War, Audio.
   - Troubleshooting und bekannte Einschraenkungen.
   - Glossar fuer wichtige Begriffe.
2. Schreibstil:
   - usernah, knapp, konkret.
   - keine internen Tasknummern als Pflichtwissen.
   - keine falschen Versprechen.
   - geplante oder unsichere Features klar kennzeichnen.
3. Quellen:
   - finale Spiel-Doku und Review-Reports aus TASK_283 bis TASK_289.
   - bestehende Dev-Dokumente nur als Grundlage, nicht als Usertext.
   - UI darf nicht zur Wahrheit werden; Handbuch gleicht gegen Runtime-/Simulation-Verhalten ab.
4. Format:
   - Markdown-Datei `docs/User-Handbuch.md`.
   - klare Ueberschriften.
   - kurze Abschnitte statt Textwand.
   - optional Bilder nur, wenn sie im Projektordner liegen und stabil referenziert sind.
5. Pflegehinweise:
   - Am Ende kurzer Abschnitt, welche Handbuchbereiche bei neuen Features mitgepflegt werden muessen.

## Nicht-Ziele
- Kein Entwicklerhandbuch.
- Keine komplette Lore-Bibel.
- Keine Marketingseite.
- Keine Dokumentation von Features, die nur in Tasks geplant sind.
- Kein Ersatz fuer Help-Popups im Spiel.

## Akzeptanzkriterien
- [x] `docs/User-Handbuch.md` existiert und ist aus User-Sicht lesbar.
- [x] Das Handbuch beschreibt nur bestaetigtes Verhalten oder markiert "Noch in Arbeit" eindeutig.
- [x] Hauptmenue, Einstellungen, Singleplayer, Multiplayer, Editor und Mission Map sind enthalten.
- [x] Fireteam-/Befehlssystem, NPC-Verhalten, Waffen, Medic, Terrain/Huegel und Fog of War sind erklaert.
- [x] Help-Popups, Sprechblasen, Audio und Feedback werden als Spielerfunktionen beschrieben.
- [x] Kein Abschnitt macht UI-State zur autoritativen Gameplay-Wahrheit.
- [x] Interne Tasknummern tauchen nur optional im Pflegehinweis auf, nicht als notwendige Usererklaerung.
- [x] Markdown-Link- und Formatcheck laufen sauber.
- [x] `git diff --check` ist sauber.

## Erwartete Dateien
- `docs/User-Handbuch.md`
- optional `docs/assets/manual/...`
- `scripts/tests/task_290_user_handbuch_weekly_closeout.gd`
- `docs/tasks/TASK_290_user_handbuch_weekly_closeout.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_290_user_handbuch_weekly_closeout.gd`
- [x] Markdown-Link-/Pfadcheck fuer `docs/User-Handbuch.md`
- [x] `git diff --check`

## Umsetzung
- `docs/User-Handbuch.md` beschreibt Hauptmenue, Homebase/FOB, Mission Map, Kamera, Befehle, Fireteam Leader, NPC-Verhalten, Waffen, Medic-Regeln, Terrain/Huegel, Fog of War, Feedback, Help, Audio, Multiplayer, Editor, Settings, Troubleshooting und Glossar aus Spielersicht.
- Der Abschnitt "Noch in Arbeit / bekannte Einschraenkungen" trennt manuelle Restchecks und kleine P2/P3-Folgepunkte klar von bestaetigtem Verhalten.
- `scripts/tests/task_290_user_handbuch_weekly_closeout.gd` prueft Pflichtabschnitte, Spielerperspektive, UI-Truth-Grenze, Kernthemen, bekannte Einschraenkungen und Markdown-Links.

## Risiken
- Das Handbuch darf keine Wunschliste werden. Wenn ein Feature noch nicht stabil ist, gehoert es in "Noch in Arbeit".
- Zu viel Entwicklertext schreckt User ab. Begriffe muessen erklaert werden, nicht vorausgesetzt.
- Nach TASK_289 koennen Patchqueue-Findings entstehen, die einzelne Handbuchabschnitte blockieren oder bewusst als bekannt markieren.

## Naechster Schritt
Bei neuen spielbaren Features `docs/User-Handbuch.md` im selben Patch mitpflegen und die TASK_290-Pruefung erneut laufen lassen.
