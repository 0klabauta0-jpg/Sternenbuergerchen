# TASK_1148 - Connected Release Dropship First Decision Playtest

## Ziel / Problem
TASK_1147 beweist die echte Release-Verbindung bis zur gemeinsamen Mission. Noch offen ist der Spielergriff von LZ und Drop bis zur ersten getrennten Fireteam-Entscheidung aus Host- und Client-Sicht.

## Umfang
- Zwei exportierte EXE-Prozesse in Full-HD-tauglicher Darstellung starten.
- LZ, Drop, Deboard und erste Move-/Combat-Entscheidung durchlaufen.
- Host-`blue`- und Client-`gold`-Perspektive sowie Authority-Feedback vergleichen.
- Wartezeiten, Screenshot, Trace und sichtbare Reibungen dokumentieren.

## Nicht-Ziele
- Keine Firewall-Regel automatisiert aendern.
- Kein Internet-/Matchmaking-Test.
- Kein Gameplay-Rewrite ohne reproduzierbaren Befund.

## Akzeptanzkriterien
- Beide Release-Prozesse bleiben durch Drop und Deboard verbunden.
- Jeder Peer sieht und kommandiert nur sein zugewiesenes Fireteam.
- Erste Entscheidung und Host-Antwort sind in beiden Perspektiven lesbar.
- Ein echter Fehler wird minimal reproduziert und separat behoben.

## Risiken / offene Punkte
Zwei Full-HD-Fenster passen nicht gleichzeitig auf jeden Monitor. Direkte Fenster-Captures bleiben deshalb der stabile Beleg; der Windows-Firewall-Erststart wird als Umgebungsgrenze behandelt.

## Betroffene Dateien
- `scripts/mission/multiplayer_dropship_bootstrap.gd`
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/tools/capture_release_host_client_entry_playtest.ps1`
- `scripts/tests/task_1148_*.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Ergebnis
- Der normale Produkt-Multiplayer startet nicht mehr direkt mit bereits frei stehenden Fireteams, sondern mit einem Host-autoritativen Dropship pro zugewiesenem Fireteam.
- Host/Blue und Client/Gold setzen getrennte LZs, starten getrennte Drops, deboarden alle acht Marines und senden danach je eine erste Move-/GO-Entscheidung.
- Der erste echte Lauf deckte einen Testtreiberfehler auf: per-frame Craft-Selektion liess Blue bei etwa 55 Prozent Inbound stehen. Craft-Selektion erfolgt nun nur noch bei LZ- und Drop-Submission.
- Das Release-Gate wartet zusaetzlich auf leere Embarked-Listen und identische Deployed-Anzahlen. Der finale Lauf erreicht nach 57,6 Sekunden `first_decision_accepted` auf beiden Peers, `deployment_converged = true`, 8/8 deployte Units und Client-Feedback `COMMANDER_INTENT GOLD HOST OK`.
- Direkte Host-/Client-Captures liegen in 1600x900 vor.

## Sichtbarer Folgefund
Die Fireteam-Mini-Cards links zeigen nach dem GO noch unterschiedliche/stale Zustandsworte (`STABIL` auf Host, `WARTET` auf Client), obwohl die Member-Cards bereits `Marschiert` melden. Die Client-Routenlinie verlaesst ausserdem den nutzbaren Kartenfokus. Das ist TASK_1149.

## Lokale Pruefung
- `task_1148_multiplayer_dropship_bootstrap.gd`: 14/14
- `task_1148_release_drop_decision_deeplink.gd`: 7/7
- `task_1148_release_drop_decision_harness.gd`: 10/10
- `task_1104_product_lobby_multi_client_parallel_interaction_playtest.gd`: 31/31
- `task_1101_connected_interaction_reconnect_state_recovery.gd`: 46/46
- echter Zwei-EXE-Lauf: `release_host_client_drop_decision_playtest.json` Gate `pass`
