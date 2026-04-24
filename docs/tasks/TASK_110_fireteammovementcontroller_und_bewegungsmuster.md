# TASK_110 - FireteamMovementController und Bewegungsmuster

## Ziel
Ein `FireteamMovementController` steuert die Relativbewegung der Members innerhalb eines Fireteams. Die Ausfuehrung folgt dem bereits abgeleiteten Verhalten und setzt `rush`, `bounding` und `caterpillar` als eigenstaendige Bewegungsmuster auf dem bestehenden Command-/Effect-Pfad um.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_100_globaler_phasecontroller_und_plan_ausfuehrung.md](docs/tasks/TASK_100_globaler_phasecontroller_und_plan_ausfuehrung.md)
- Lies [docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md](docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md)
- Lies [docs/tasks/TASK_109_tacticalstancecontroller_und_panel.md](docs/tasks/TASK_109_tacticalstancecontroller_und_panel.md)
- Lies [docs/tasks/TASK_088_leadership_bonus.md](docs/tasks/TASK_088_leadership_bonus.md)
- Pruefe den Git-Status

## Kontext
- Dieser Task setzt das bereits abgeleitete Bewegungsprofil aus `FireteamBehaviorResolver` um; er wird nicht zur zweiten Wahrheitsquelle fuer Verhaltensformeln.
- `Inter-Fireteam-Koordination` bleibt bei TASK_104, auch wenn mehrere Fireteams zeitgleich in dieselbe Richtung marschieren.

## Aufgabe

### 1. `FireteamMovementController`
- Fuehre Fireteam-Bewegung als eigenstaendige Schicht ein.
- Der Controller schreibt nicht direkt auf `TestUnit`, sondern erzeugt weiter Commands oder Effects fuer den autoritativen Pfad.
- Bewegungsmuster werden pro aktivem Wegpunkt aus dem Laufzeitprofil abgeleitet, nicht persistent gespeichert.
- Eingaben sind mindestens: aktiver Waypoint, aktuelles `advance_style`, `cohesion_threshold`, Leader-/Member-Skills und der aktuelle Missionszustand der Fireteam-Members.

### 2. Bewegungsmuster `rush`
- Alle fit Members bewegen sich gleichzeitig.
- Keine Deckungsgruppe bleibt zurueck.
- Langsame Members begrenzen die Gruppengeschwindigkeit, sobald die Kohaesion zu weit aufreisst.

### 3. Bewegungsmuster `bounding`
- Fireteam wird in Bewegungs- und Deckungsgruppe aufgeteilt.
- Die Deckungsgruppe haelt und deckt bekannte Feindrichtungen.
- Nach Erreichen einer Zwischenposition signalisiert die Bewegungsgruppe `bound_complete`, danach wechselt die andere Gruppe.

### 4. Bewegungsmuster `caterpillar`
- Immer nur ein Member bewegt sich gleichzeitig.
- Alle anderen Members bleiben als Deckungsgruppe zurueck.
- Das Muster priorisiert maximale Sicherung vor Geschwindigkeit.

### 5. Gruppenaufteilung
- Hohes `speed` bevorzugt die erste Bewegungsgruppe.
- Hohes `accuracy` bevorzugt die Deckungsgruppe.
- Der Lead bleibt bis zum letzten Bound in der Deckungsgruppe, ausser bei Trait `reckless`.
- Sind mehr als 50% der Members `down` oder `bleedout`, darf der Controller koordinierte Muster kontrolliert auf einen vereinfachten gleichzeitigen Vormarsch herunterbrechen, statt eine neue Sonderarchitektur einzufuehren.

### 6. Integrationsgrenzen
- Keine strukturelle Aenderung an `RuntimeLeader`, `SimulationRoot` oder `CommandToFTLTaskTranslator`.
- Wegpunkt-Abschluss und Phasenlogik bleiben bei den bestehenden Plan-/Phase-Systemen.
- Der Controller ergaenzt nur das intra-Fireteam-Verhalten waehrend aktiver Bewegung.
- Sicherungssektoren, Overwatch und Kontaktgedaechtnis werden nicht in diesen Controller hineingezogen.

## Nicht-Ziele
- keine Inter-Fireteam-Koordination
- keine Overwatch-Regeln
- keine neue Formation-Editor-UI

## Akzeptanzkriterien
- `rush`, `bounding` und `caterpillar` koennen zur Laufzeit sichtbar unterschieden werden.
- Bounding und Caterpillar teilen Fireteams nachvollziehbar in Bewegungs- und Deckungsrollen auf.
- Gruppenwechsel erfolgen ueber explizite Laufzeitereignisse wie `bound_complete`.
- Alle Bewegungswirkungen laufen weiterhin ueber den bestehenden autoritativen Command-/Effect-Pfad.

## Umsetzung
- `scripts/tactical/fireteam_movement_controller.gd` fuehrt `rush`, `bounding` und `caterpillar` als eigene Laufzeit-Orchestrierung pro aktivem Waypoint ein.
- `MissionTacticalSandboxController` nutzt den Controller fuer geplante und ad-hoc-Bewegungen, setzt ihn bei Standard-Hold-/Interrupt-Pfaden zurueck und zeigt den aktuellen Bewegungsmodus als `MOVE RSH/BND/CAT` im Statuspanel.
- `EventRouter` erweitert den Signalvertrag um `fireteam_bound_complete`, damit Gruppenwechsel explizit gemeldet werden koennen.
- `scripts/tests/task_110_verifier.gd` deckt Rush-Kohaesion, Bounding-Rotation, Caterpillar-Sequenz, Verlust-Downshift und die Mission-Integration headless ab.
