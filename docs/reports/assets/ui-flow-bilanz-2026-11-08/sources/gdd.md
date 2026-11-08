# GDD_STATUS

Stand: 2026-05-11

## Status
`sternenbuerger-gdd.docx` ist Alt-GDD, Design-Inspiration und Migrationsquelle. Es ist nicht direkt bindend fuer Code, Tests oder neue Tasks.

Bindend sind aktuell:
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/DECISIONS.md`
- `docs/IMPLEMENTATION_STATUS.md`
- konkrete Markdown-Task-Dateien unter `docs/tasks/`

Wenn ein Inhalt aus dem DOCX bindend werden soll, muss er vorher in Markdown ueberfuehrt und gegen Architektur, Scope und aktuelle Tests abgeglichen werden.

## Konkrete Konflikte
- Das DOCX beschreibt Phase 1 ohne Multiplayer. Der aktuelle Repo-Stand hat Multiplayer V1 bereits als Godot/ENet Direct-IP/UPnP-Prototyp.
- Das DOCX nennt fuer spaeter einen Node.js-WebSocket-Server. Die aktuelle Architekturentscheidung ist Godot High-Level Multiplayer ueber ENet; WebSocket ist keine aktuelle technische Vorgabe.
- Das DOCX formuliert teils auf Basis externer Universums-/IP-Begriffe. Fuer das Repo sind diese Begriffe nur Inspiration, nicht bindende Produkt-, Naming- oder Lore-Vorgaben.
- Das DOCX spricht groesser von 15 bis 100 NPCs und Teamleader-Slices mit 4 bis 15 NPCs. Der aktuelle V1-Pfad arbeitet kleiner und testbarer mit Fireteams, Dropship-Payloads und festen Meta-/Mission-Flows.
- Das DOCX beschreibt mehrere operative Ebenen wie Deep Space, Orbit, Atmosphaere, Planet und Interior. Der aktuelle Arbeitsstand bindet vor allem Homebase, FOB und Mission Map.
- Das DOCX enthaelt tiefe NPC-Sozial-, Sympathie- und Stat-Systeme. Im aktuellen Code sind nur Teile davon als V1-/Folgepfad abgebildet; daraus darf kein stiller Scope-Zuwachs entstehen.

## Arbeitsregel
Bei Widerspruch gewinnt die Markdown-Dokumentation. Das DOCX darf fuer Ideen, Vokabular und Langfrist-Richtung gelesen werden, aber jede konkrete Uebernahme braucht einen Task oder eine Decision.
