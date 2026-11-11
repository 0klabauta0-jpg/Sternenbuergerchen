# Vollständiger Korridorcache: begrenzte Integration

Basis21779cbaf, eigene gezielte Kopien des nativen Cachehelfers4753975d8 und
Reproducerfixes472f1ad8f sind4ba1b9e98/42443b34c. Kein Import übriger nativer
Karten-/Visualänderungen. Noch keine aktive Karte oder Actorprojektion.

## Kleine Prüfung

Godot4.6.2. Reproduktion über isolierten Runner:
`python scripts/tests/run_hex_tactical_check.py --case CASE`.

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| corridors |18 /0|
| corridor_integration |15 /0|
| reservation |26 /0|
| reservation_owner |36 /0|
| topology |23 /0|
| owner |51 /0|

Finale sechs Läufe mit Prozess0, Canary, unveränderten Quellen und Originalprofil.
Manifest nennt tatsächliche Quellhashes; Originalreports/-logs auch aller
Fehlversuche in corridor_runs.zip. Originalcachefixture unter output wird über
denselben isolierten Runner ausgeführt, ohne historische Logdatei zu verändern.

Schematische80/81-Felder-Linien mit0–2 Logikpersonen, keine große Spielszene:
64+16 Fortsetzung, keine abgeschnittene Freigabe,0Budget beim Ownerbeweis,
geschlossener/besetzter ferner Ausgang, unzulässiger Pfadrest, unabhängiger
Pendingjob und Terrainreklassifikation. Andere Fixtures höchstens zwölf Felder.

## RED/GREEN und Review

Fehlende Registry-API0/1, danach fehlender Vollkomponentenbeweis6/2 und GREEN8/0.
Reklassifikation11/0, ferner besetzter Ausgang12/0. Bestehende Ownerfixture
benutzte einen handgeschriebenen Grant ohne vorgewärmte zertifizierte Topologie;
auf echten Planerrequest umgestellt, gefälschte Gruppenfälle explizit warm
geprüft, damit ihre Ablehnung den Gruppenfehler und keinen kalten Cache trifft.

Frischer Review fand die freie vermeintliche Ausfahrt hinter einer inzwischen
geschlossenen Tür:12/3, dann15/0. Ein-/Austritt verwendet nun aktuellen
kanonischen Terrainübergang; Ganginnere prüft benachbarte Indizes in der
vollständigen geordneten Komponente. Enge Nachprüfung ohne offenen Befund.
Reviewer startete keine Engine und änderte keine Dateien.

## Grenzen

64 neue Klassifikationen pro Query ist ein Arbeitsbudget, kein Framezeitbeweis.
Kopieren, Ordnen und Indexieren vollständiger Komponenten sowie Lesen langer
Pfadlisten sind zusätzliche, noch nicht profilierte CPUarbeit. Lokaler64-Graph
bleibt für begrenzte Rücksetzvorschläge und alte Registryadapter. Allgemeine
Deadlockfreiheit, AP5-Actorbewegung/Commands, Lifecycle, Save/Netzwerk und große
native Gefechts-/GPU-/Performanceabnahme sind weiterhin offen. AP9 bleibt später.
