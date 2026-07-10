# TASK_1083 - Two-Instance ROE Ownership Playtest

## Status: IMPLEMENTIERT

## Ziel / Problem

TASK_1082 belegt Contract, Host-Commit und Snapshot isoliert. Jetzt muss derselbe Weg ueber zwei echte lokale ENet-MultiplayerAPI-Subtrees und den Mission-Controller laufen: Client-Setter, RPC, Host-Queue, Commit, Snapshot und sichtbares Reject-Feedback.

## Ursache / Sinnhaftigkeit

Der vorhandene TASK_607-ENet-Smoke oeffnet eine Verbindung, schliesst sie aber vor den Mission-Instanzen und reicht Commands danach direkt am Host ein. Er beweist deshalb weder den ROE-Buttonpfad noch eine Rueckmeldung an den Client bei abgewiesener Fireteam-Ownership.

## Umfang

- Zwei lokale Mission-Instanzen mit getrennten `MultiplayerAPI`-Subtrees und offenem ENet-Paar.
- Client ruft den bestehenden Fire-Rule-Setter auf.
- Host empfaengt `request_command`, validiert und committed.
- Host-Snapshot repliziert Fire Rule und Revision zum Client.
- Abgewiesene Requests liefern ein sanitisiertes Resultat an den sendenden Client.
- Controller zeigt kompaktes akzeptiert-/blockiert-Feedback ohne Gameplay-Wahrheit.

## Nicht-Ziele

- Kein Lobby-Redesign.
- Kein Internet-/NAT-Test.
- Kein neuer ROE- oder Combat-Regelsatz.
- Kein automatischer visueller Screenshot-Akzeptanzentscheid.

## Akzeptanzkriterien

- Client-Request fuer das zugewiesene Fireteam erreicht den Host ueber echten RPC.
- Erst der Host-Tick committed Fire Rule und Revision.
- Host und Client zeigen danach dieselbe Fire Rule/Revision.
- Der Client erzeugt beim Snapshot-Apply keine Gameplay-Commands.
- Request fuer ein fremdes Fireteam wird vom Host abgewiesen.
- Der sendende Client erhaelt Grund und kompaktes `ROE BLOCKED`-Feedback.

## Betroffene Dateien

- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1083_two_instance_roe_ownership_playtest.gd`
- Status-, Roadmap-, Contract- und HTML-Berichtsdokumentation

## Lokale Pruefung

- `task_1083_two_instance_roe_ownership_playtest.gd`
- TASK_1082, TASK_607, TASK_1081 und `git diff --check`

## Risiken / offene Punkte

- Lokales ENet prueft Prozess-/API-Grenzen, aber nicht Internetlatenz oder NAT.
- Ein echter sichtbarer Zwei-Fenster-Screenshot bleibt manuelle Folgeabnahme, falls der automatisierte Bedienpfad gruen ist.

## Ergebnis

- Der Client-Setter sendet ueber eine echte lokale ENet-Verbindung und mutiert vor Host-Commit keine ROE.
- Host-Validierung, Command-Verarbeitung, Fire-Rule-Revision und Client-Snapshot sind in zwei getrennten MultiplayerAPI-Subtrees belegt.
- Akzeptierte Requests liefern `HOST OK`; fremde Fireteams liefern `ROE BLOCKED fireteam_not_assigned_to_peer` an den Client.
- Der echte Lauf deckte einen 14,7-KB-`unreliable_ordered`-Snapshot auf. Der State wird jetzt binaer/ZSTD komprimiert, als ungeordnete `unreliable`-Chunks mit maximal 1000 Byte Nutzlast gesendet und erst als vollstaendiger Tick angewendet.
- TASK_1083 ist 24/24, TASK_1082 21/21, TASK_168 20/20, TASK_169 15/15, TASK_221 63/63, TASK_281 33/33 und TASK_607 41/41 gruen. Der frische echte Lauf reduziert 14.740 Raw-Bytes auf 2.282 Wire-Bytes in drei ungeordnet reassemblierbare Chunks; Packen lag bei 151 us, Reassembly/Apply bei 1.590 us. Absichtlich rueckwaerts zugestellte Chunks werden ebenfalls korrekt zusammengesetzt.
