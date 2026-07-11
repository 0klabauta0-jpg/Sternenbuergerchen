# TASK_1093 - Connected Station Route Full Interaction Trace

## Ziel / Problem
Door laeuft verbunden ueber Arrival/Hold, AA, Computer und Cargo besitzen aber noch keine neutrale Network-Projektion. Die komplette Route muss einmal ueber echte Client-RPC, Host-Runtime und Client-Snapshot durchlaufen.

## Umfang
- Generischer Builder projiziert bestehende Interaction-Intents in Commander-Commands.
- Nur Absichtsdaten werden uebertragen; kein Runtime-State, Progress oder Complete.
- AA, Door, Computer und Cargo laufen sequenziell ueber denselben Host-Arrival-/Hold-Pfad.
- Gate-Reihenfolge und Client-Replikation werden geprueft.

## Nicht-Ziele
- Noch kein Umbau des sichtbaren GO-Buttons auf RPC.
- Kein Lobby-/Internet-Test und kein neuer Movement-Resolver.

## Akzeptanzkriterien
- Alle vier Commands werden vom Host akzeptiert.
- Jeder Schritt wird erst nach Host-Ankunft/Hold komplett.
- Route endet mit `all_gates_complete` auf Host und Client.
- Client erzeugt keine Gameplay-Commands.
- Wrong-Team-/State-Mutation-Guards bleiben gruen.

## Lokale Pruefung
- TASK_1093, TASK_1092, TASK_1091, TASK_714, TASK_697
- HTML-JavaScript, `git diff --check`, Export und Startcheck

## Risiken / offene Punkte
Nach diesem Contracttrace bleibt der sichtbare Client-GO-zu-RPC-Handoff als naechster UI-Integrationsslice offen.

## Ergebnis
- 19/19: AA, Door, Computer und Cargo laufen ueber echte lokale ENet-RPC.
- Jeder Schritt wird aus Host-Ankunft und authored Hold-Dauer abgeschlossen und zum Client repliziert.
- Host und Client melden am Ende `all_gates_complete`; Client-Snapshots erzeugen keine Commands.
- Der neutrale Builder transportiert Absicht und Authoring-Metadaten, aber keinen Runtime-State oder Progress.
- Naechster Schritt: TASK_1094 - Connected Client GO Interaction RPC Handoff.
