# N6 · Reise, Fracht und Flugaufträge

Bestätigter Auftrag vom 21.09.2026. Arbeitsbasis db29391, eigener Branch.

1. Klare Wege: linke Werkzeugleiste mit angrenzenden Kontextkarten; Crew rechts. Systemmenü im Header, Spielaktionen getrennt. Büro als auswählbarer Crew-Arbeitsplatz, verständliche Fähigkeiten und Ausrüstung.
2. Lager/Fracht: nur vorhandene Waren als Symbolkarten, Mengen in Stück (je ein Frachtplatz; keine erfundene kg-Physik). Drag-and-drop mit Mengenwahl, sichtbares Ziel und Hostbestätigung. Blackbox erst ausladen, dann 260 Cr und Bauplan abholen; beide Schritte am Lager sichtbar.
3. Systemkarte: eigener Flackerstern Asche, Rostwelt und zwei weitere Planetengruppen. Bestehende getrennte Karten behalten IDs und Risiken. Inspiration: RSI Galactic Guide Pyro; keine fremden Bilder im Produkt.
4. Reiseanimation: aus tatsächlicher Reisezeit und Ziel abgeleitete Flugansicht, Pause bleibt wirksam. Keine zweite UI-Simulation, kein Fortschrittsbalken für Reisen.
5. Flug: deterministische Umwege um hohe statische Hindernisse mit Abstand für die gesamte Hülle; alle Piloten sicher, bestehender Skill beeinflusst Geschwindigkeit. Patrouille, Suchraster mit Radar/Identifikation und Halt. Host führt aus; gespeicherter optionaler ship.order-Zusatz zu Schema5 wird streng geprüft. Fehlendes Feld älterer Karrieren bedeutet Halt/Einzelziel; Pfadcache wird neu berechnet.
6. Prüfen: reale Transaktionen, Hindernisse über Flugsegmente, Pause/Save/Load, tatsächliche UI-Mauswege, bestehender Missionsweg, zwei Prozesse. Paket und Handybericht aktualisieren.

Grenzen: ein aktives Gebiet, kein autonomer regionsübergreifender Handel, keine Rekrutierung/XP, keine Schiffsinnenräume. Büro verwaltet die vorhandene Crew. Planeten sind navigierbare Gruppen der bestehenden Karten, keine zusätzlichen Oberflächen.
