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
