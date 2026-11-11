# Hexsicht, Erkennung und Feldbelegung: Arbeitsauftrag vom 11.11.2026

## Status

Konkreter Arbeitsplan erstellt; keine Runtime-Umsetzung. Der Nutzer verlangt
ausdrücklich, größere Tests später durchzuführen. Diese Planungsrunde prüft
nur Dokumente, Schnittstellen und Git-Diff, startet keine Engine.

Nachfolgende autorisierte Ausführung auf einem eigenen Branch: AP0 auf
97e00aba14ced147b268113085854ac67dc764c5 übernommen; isolierte Grundbausteine
mit kleinen Checks umgesetzt, siehe `HEX_RUNTIME_FOUNDATION_2026_11_11.md`.
Die folgenden Angaben zur reinen Planungsrunde bleiben deren historische Basis.

Planungsbranch: `task/hex-sight-occupancy-plan-20261111`, bewusst auf dem noch
nicht integrierten Kampagnenstand `e4b407fe0598f1f601b40177c7fec408fd73618c`.
Nicht auf dem alten `integration/core-foundation` vom August implementieren.
Der native Kartenstand `4e44521fd1c0e512d725d28e58fc910d4948e56b` und dessen
laufende Rampenarbeit sind getrennte Integrationsvoraussetzungen. Dieser
Doku-Branch übernimmt weder deren uncommittete Änderungen noch fremde WIP.

## Ziel / Problem

Sicht und Erkennung sollen verbindliche Hexpositionen verwenden und dieselbe
Sichtgeometrie bei unveränderten Eingaben wiederverwenden. Jeder am Boden
befindliche NPC belegt genau ein Feld. Zeitliche Feld-/Kantenreservierungen
sollen Kolonnen, Gegenverkehr und Engstellen ohne gegenseitiges Überlappen
abwickeln; die sichtbare Bewegung bleibt kontinuierlich.

## Sinnhaftigkeit / Ursache

Die aktuelle Diagnose zeigt laufende Erkennungsprüfungen und Gegner-Sicherung
als relevante CPU-Kosten. Der Sichtcache ist ticklokal und berücksichtigt
kontinuierliche Weltpositionen. Es bestehen bereits Wiederverwendung und
beobachtete Zielindizes; diese dürfen nicht durch einen zweiten Wahrnehmungsowner
ersetzt werden. Der vorhandene Engpassresolver liefert überwiegend Pläne und
Metadaten und ist keine vollständige Belegungs-/Bewegungsautorität.

Die Diagnose bezieht sich auf Square-Fixtures und einen älteren Quellstand.
Sie beweist weder den Zeitgewinn dieses Plans noch die Leistung nativer großer
Hexkarten. Die reine Würfellogik ist nach der engen Probe kein Hauptengpass.

## Umfang und Nicht-Ziele

Umfang: gemeinsamer logischer Ground-State, Hexsicht und Erkennungsablauf,
Feldexklusivität, tatsächliche Reservierungsausführung, Rampenanschlüsse,
kontinuierliche Projektion, Missions-/Basis-/Transport-Lifecycle und versionierte
Save-/Netzwerkgrenzen. Kleine lokale Prüfungen sind Bestandteil der späteren
Implementierung. Große Abnahme bleibt ein eigenes zurückgestelltes Paket.

Nicht-Ziele: neue Rüstungs-/Schadenswürfe, neue Kampf- oder Skillbalance,
Klettermechanik, neue Schallphysik, Umbau der Kartenkunst, geänderte Kartengrößen,
vollständige Neuarchitektur von Combat/FTL, neue Multiplayer-Funktionen,
Mainintegration oder EXE in dieser Planungsrunde.

## Relevante Dokumente

- [Entwurfsgrundlage](../superpowers/specs/2026-11-11-hex-sight-occupancy-design.md)
- [Ausführbarer Arbeitsplan](../superpowers/plans/2026-11-11-hex-sight-occupancy.md)
- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- `docs/dev/hex_grid_v1_contract.md`, `docs/dev/contact_report_contract.md`
- `docs/dev/fog_of_war_modes_contract.md`, `docs/dev/combat_loop_authority_contract.md`
- `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/base_automatic_rest_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/dev/multiplayer_snapshot_replication_contract.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/tasks/TASK_151_engpass_reservierung_mapf_light.md`
- Voraussetzung: `docs/dev/explicit_hex_ramps_contract.md` aus dem Kartenchat.
  Beim Planlesen noch in dessen Worktree, nicht in diesem Branch verfügbar:
  `C:/dev/SternenBuergerchen-worktrees/native-glut-maps-20261110/`.
  Gelesener SHA256 einschließlich breiter Rampenbänder und Editorergänzung:
  `783d7779ad2e7d27148e457eb2f071f89536011f3f2b0a0612885f8cb0f681c3`.
- Lokale Diagnose: `output/performance_hex_audit_20261111/20261111T133734/BERICHT.md`.

## Akzeptanzkriterien des Plans

- Nutzerentscheidungen und neue Planungsannahmen sind getrennt benannt.
- Jedes Umsetzungspaket nennt Dateien, Schnittstellen, kleine Prüfungen und
  einen integrierbaren Commit; spätere Abnahme ist sichtbar zurückgestellt.
- A*, HPA, Bewegung und Reservierung konsumieren dieselben Rampenanschlüsse.
- H0/H1-Plateaukante gesperrt; Rampenzentrum H+0,5, keine Float-Abschneidung.
- Seitliche Endpunkthöhe H+0,5 verbindet nur passende Rampen; breite Bänder
  und Innen-/Außenecken lesen dieselben Übergänge und gelten nicht pauschal
  als einspuriger Gang. Normale seitliche Plateauanschlüsse bleiben gesperrt.
- Ein autoritativer logischer Ground-State; kein UI-/Mesh- oder Registryowner
  mit einer zweiten Mission-, NPC-, Wahrnehmungs- oder Belegungswahrheit.
- Erkennungstimer, Kontaktwissen, aktuelle Sicht und Schusszulässigkeit bleiben
  getrennt; keine neue Wurfserie je Renderframe.
- Feldwechsel und Engpassdurchlass besitzen verbindliche Konflikt-, Warte-,
  Abbruch- und Lifecycle-Regeln; kein unbewiesenes Deadlockfreiheitsversprechen.
- Altstände ohne Versionskennung werden nicht still umgedeutet.
- Keine Performance- oder Spielflussfreigabe ohne spätere native Vergleichsserie.

## Betroffene Dateien dieser Planungsrunde

Nur diese Taskdatei, Entwurfsgrundlage und Arbeitsplan sowie ein knapper
Planungsstatus in `docs/IMPLEMENTATION_STATUS.md` und `docs/TASK_ROADMAP.md`.
Die späteren Produktdateien sind je Paket im Arbeitsplan aufgelistet.

## Lokale Prüfung

Markdown-/Referenzprüfung, Abgleich der vorhandenen und angekündigten APIs,
Selbstreview auf Scope, Besitz und Deferred-Gates; `git diff --check`.
Keine Godot-, Gefechts-, Matrix-, Grafik- oder Performance-Läufe jetzt.

## Risiken / offene Punkte

- Die fremde Rampenarbeit muss vor AP1 als Commit integriert und neu gepinnt
  sein. Ihre API ist im Plan Eingabe, kein zu kopierender Alternativvertrag.
- 120 Grad, sechs Blickrichtungen, Wechsel an der Hexkante und technische
  Budgets sind vorgeschlagene V1-Defaults, keine bisherigen Nutzerfreigaben.
- Spawn-/Aussteigeflächen und alte Saves können mehrere Personen im selben
  Feld enthalten; Einführungs-/Kompatibilitätsregeln sind daher Pflicht.
- Vollständig belegte einspurige Gänge ohne Ausweichraum können keine freie
  Durchfahrt garantieren; begrenztes Warten und eindeutiges Feedback gehören dazu.
- Halbhohe Deckung und Augen-/Haltungsprofile dürfen keine unbemerkte neue
  Balance erhalten. Neue Zahlen bleiben außerhalb dieses Umbaus.
