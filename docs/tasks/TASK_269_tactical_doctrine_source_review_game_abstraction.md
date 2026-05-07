# TASK_269 - Tactical Doctrine Source Review Game Abstraction

## Ziel
Taktiken, Befehle und Fireteam-Verhalten sollen aus mehreren Quellen breit, aber spielgeeignet abgeleitet werden. Der Task erstellt keinen echten Einsatzleitfaden, sondern eine sichere Game-Design-Abstraktion fuer Sternenbuergerchen.

Die Recherche soll bewusst nicht nur US-lastig sein. Sie soll US-Doktrin, deutsche/Bundeswehr-Quellen, franzoesische Infanterie-/Taktikquellen und Arma-/MilSim-Quellen vergleichen und daraus ein kompaktes Befehls- und Verhaltensvokabular ableiten.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_109 - TacticalStanceController und TacticalStancePanel
- TASK_110 - FireteamMovementController und Bewegungsmuster
- TASK_111 - FireteamSecurityController und Overwatch
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_200 - Enemy Team Tactics Contract and Editor Config
- TASK_263 - Contextual Help Popup UX Contract

## Kontext
Bestehende Systeme kennen bereits Stance, Movement Styles, Security, Area Orders und Statusfeedback. Was fehlt, ist ein zusammenhaengender Design-Review: Welche Befehle gehoeren auf Commander-Ebene, welche Entscheidungen trifft der Fireteam-Leader, welche Ausbrueche sind erlaubt, und wie wird das fuer den Spieler sichtbar?

Quellen sollen nur als Inspiration fuer Spielebenen dienen: Rollen, Absicht, Koordination, Kommunikation, Tempo, Sicherung, Feuerregeln und Abweichungen. Keine realen Schritt-fuer-Schritt-Gefechtsverfahren.

## Quellenanker
- US Army ATP 3-21.8 Infantry Platoon and Squad, 2024.
- Bundeswehr/Heer oeffentliche Seiten zu Infanterie, Jaeger/Gebirgsjaeger und verbundenen Faehigkeiten.
- Armee de Terre / CDEC oeffentliche Texte zu Infanterie, combat debarque, tactique generale und Fuehrungsebenen.
- Bohemia Interactive Arma 3 Field Manual: Commanding, Infantry Controls, Formations, Command Responses.
- Arma-/MilSim-Guides nur als Game-UX-Vergleich, nicht als echte Doktrin.

## Umfang
1. Quellenmatrix:
   - Quelle, Ebene, relevante Konzepte, Spielableitung, Nicht-uebernehmen.
   - Begriffe neutralisieren, keine Nationen als direkte Ingame-Schubladen.
2. Befehlsebenen:
   - Commander gibt Absicht, Ziel, Regeln, Prioritaet.
   - Fireteam-Leader entscheidet Ausfuehrungsstil innerhalb der Regeln.
   - einzelne NPCs fuehren nur ueber FTL-/Team-Logik aus.
3. Taktikvokabular:
   - Move, Take, Defend, Engage, Secure, Recon/Probe, Withdraw, Support, Breach/Bypass, Hold.
   - Feuerregeln, Tempo, Formation/Spread, Security, Contact Response.
4. Ausbrueche:
   - Contact, pinned/suppressed, casualty, blocked path, low ammo, LZ threatened, leader down, air asset threatened.
   - Wann darf FTL abweichen, wann braucht er Rueckfrage?
5. UI-/Feedback-Vokabular:
   - Was sieht der Spieler auf Karte, #17/#18, Bubbles/Radio, Help-Popups.
   - Kurze Statuslabels statt langer Doktrintexte.
6. Dev-Dokument:
   - `docs/dev/tactical_command_doctrine_game_abstraction.md`.
   - klare Folge-Tasks fuer Vertrag, UI, AI, Air Assets und Verifier.

## Nicht-Ziele
- Keine reale Ausbildung oder Einsatzanleitung.
- Keine 1:1-Uebernahme nationaler Doktrin.
- Keine neue KI-Implementierung in diesem Task.
- Kein politisches/nationales Framing im Spiel.

## Akzeptanzkriterien
- [x] Quellenmatrix mit US, deutsch, franzoesisch und Arma-/Game-Quellen existiert.
- [x] Begriffe sind fuer Sternenbuergerchen neutralisiert.
- [x] Commander-, FTL- und Unit-Ebene sind klar getrennt.
- [x] Taktikvokabular und Ausbruchsfaelle sind als Spielvertrag beschrieben.
- [x] Sicherheitsnotiz: keine realen Schritt-fuer-Schritt-Taktiken, nur Game-Abstraktion.
- [x] Ein Verifier prueft Pflichtabschnitte und Folge-Task-Referenzen.

## Erwartete Dateien
- `docs/dev/tactical_command_doctrine_game_abstraction.md`
- `docs/research/tactical_doctrine_source_matrix.md`
- `scripts/tests/task_269_tactical_doctrine_source_review_game_abstraction.gd`
- `docs/tasks/TASK_269_tactical_doctrine_source_review_game_abstraction.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_269_tactical_doctrine_source_review_game_abstraction.gd`
- [x] `git diff --check`

## Risiken
- Zu nah an realer Doktrin waere fuer ein Spiel unnoetig und unschoen. Das Ziel ist lesbare Spielsystematik.
- Zu abstrakt waere belanglos. Der Task muss konkrete Spielbegriffe und Folgeaufgaben liefern.

## Naechster Schritt
Nach TASK_269 kann TASK_270 den eigentlichen Commander-zu-FTL-Delegationsvertrag bauen.
