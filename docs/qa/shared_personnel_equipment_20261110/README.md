# Gemeinsame Charakter-/Ausrüstungsansicht — 10.11.2026

Taskbranch `task/shared-personnel-equipment-view-20261110`, auf `e004843e7`.
Mainbasis `1e3cca237604d3b293097585e19953ac08c11c7b`. Dieser Schritt ist Quellcode
auf dem Taskbranch; keine Mainintegration und keine neue EXE.

## Ergebnis

Truppausrüstung, Heimat-Charakterdetails und Einsatz-Charakterdetails verwenden
dasselbe PersonnelInventoryPanel. Ursprüngliches Porträt beim Namen, größere
Figur (bis 300×450), links Ausrüstung mit feinen Verbindungslinien, rechts bei
ausreichender Breite der tatsächliche Rucksack. Ausrüstung/Transfers laufen über
die bestehenden autoritativen Commands und Zugriffsregeln. Der Schalter für
automatisches Ruhen steht unmittelbar links am Text in einer kurzen Zeile.

Hauptrolle liest das vorhandene role_name, Nebenrolle secondary_specialty;
Eignungsbadges und Status kommen aus demselben Profil. Es entsteht keine neue
Rollenzuweisung. Die Herkunftsübersichtsbox entfällt; genaue Ableitungen sind
weiter einklappbar. Unveränderte Charakterprojektionen behalten Controls und
geöffnete Äste, auch Modell-/Inventarcontrols auf der Einsatzkarte. Ein Wechsel
zum bearbeitbaren Bogen invalidiert den Cache korrekt.

Smart Mobile zeigt Details nach Klick auf den Auftragstitel und klappt sie wieder
zu. Weitere freigeschaltete Aufträge können in derselben Liste ausgewählt werden.
Anfangs bleibt nur der Satellitenauftrag sichtbar. Annahme/Kartenbefehl unverändert.
Blueprintkarten lesen die tatsächlichen Rezeptkosten aus dem SupplyOwner und die
Waffenwerte aus WeaponData. Basisschaden/Reichweite sind keine Trefferprognose.
Rüstungsklasse und Werkzeugfunktion werden als solche benannt; keine neuen Werte.

Kampagnenhilfe und objektbezogene Meldung verdecken den geöffneten Einsatzbogen
nicht; sie erscheinen nach dem Schließen wieder. Nur Präsentation wird verborgen.

## Nachweise

- Native D3D12 Seitenfenster: **107 Prüfungen, 0 Fehler**.
- Abschließender Headless-Seitenfensterlauf: **111/0**, zusätzlich echter kurzer
  Ruhezeilen-Rechtecktest und Abstand zur Ausrüstung (Regression des zunächst
  beobachteten zeichenweisen Umbruchs).
- Native Charakteransicht: **35/0**, tatsächliches Anlegen eines vorhandenen
  Sanitätsgeräts verbraucht es einmal aus freiem Lager und legt Pistole zurück.
  Eigene Modellinstanz in eingefrorener Idle-Pose, Slots ohne Figurenüberdeckung,
  tatsächliche Badges, voller Fensterhöhenbereich und einklappbare Werte geprüft.
- Compact-Bogen: **25/0**, einschließlich Cacheerhalt und Editor-Rückwechsel.
- Vollständiger nativer Kampagnenausflug **102/0**: tatsächliches Sichern legt
  genau einen Chip in den Rucksack des aktuellen Leads, Bild im gemeinsamen
  Einsatzbogen, Cacheerhalt, Hinweise verborgen/wieder sichtbar, wirkliche
  Heimkehr/Schlafen, einmaliger Upload/Belohnung, Herstellung und Save/Restore.
  Keine Positionen/HP/Belege zum Bestehen verändert. Beschleunigte Simulation
  wie im bestehenden Ausflugverifier; kein normaler 1×-Performancenachweis.
- Menüicons/Briefing **19/0**, getrennte Rifle-/Pistolen-/Miningtool-Zellen und
  tatsächliche Zielortauflösung unverändert.

`raw/` enthält unveränderte Logs und native Prozessmetadaten. Je nativer Lauf
zwei bekannte UID-Pfadfallback-Warnungen, keine Enginefehler. Testprofile liegen
unter output/shared_equipment_20261110/profiles; Nutzerspielstände bleiben unangetastet.

Die nativen Screenshots verwenden D3D12 in einem versteckten 1280×720-Hostfenster.
Die Verifier ändern die logische Viewportgröße auf 1280/1920 bzw. 3440; das sind
keine drei physischen Monitore/Fensterauflösungen. 1280 benötigt für Lager und
untere Aktionen weiterhin Scrollen. Bilder sind echte Engineaufnahmen, keine Mockups.
Die technische Prüfung ist keine ästhetische Nutzerabnahme und kein FPS-/Releasegate.
Kein vollständiger Kampagne-4-/Skirmish-/Multiplayertest in dieser Runde.

## Bilder

- `images/inventory_1920.png`: kompakte gemeinsame Ausrüstung, gesamter freier Bestand.
- `images/inventory_1280.png`: größere Darstellung im engen Viewport mit Scrollbereich.
- `images/details_1920.png`: gemeinsame Ausrüstung neben dem detaillierten Wertebaum.
- `images/details_1280.png`, `images/details_3440.png`: weitere logische Layoutgrößen.
- `images/workshop_1280.png`: echte Rezeptkosten/Waffenwerte, neue Menüillustrationen.
- `images/jobs_1280.png`: aufgeklappter Satellitenauftrag mit Auftraggeber/Zielen.
- `images/satellite_carried_on_map.png`: tatsächlicher geborgener Chip im gemeinsamen
  Einsatzbogen; Missionshilfe verdeckt ihn nicht.
