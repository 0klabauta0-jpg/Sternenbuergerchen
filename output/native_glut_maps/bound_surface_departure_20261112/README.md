# Gebundener Surface-Abschluss: enger Flowcaller

Produkt nur scripts/meta/meta_layer_flow.gd. Privater Caller benutzt echten
Flow, bestehenden Transporttimer und vorhandene Lookup-/Pendingwege. Kontrolliert
sind Controllerreceipt, Root-Kontextread und Missionsresultatobserver. Kein
angenommener Root-/Groundretirementerfolg oder Source-API-End-to-end-Pass.

caller_red.log: vorher2/2 rot, Waiting publizierte verfrueht Abschluss/Abbruch.
Zwischenstand12/0: opakes Ticket unveraendert, Marker bleibt ueber echten
Timeraufruf bestehen, Commit einmal, stale Visit/Rootkontext/Rootinstanz laesst
frischen Transfer unberuehrt, Hexvoid bleibt geschlossen, Legacyvoid kompatibel.
completion_observer_red.log:13/1 bestaetigt anschliessend echten Callerfehler:
neuer Visit im Abschlussobserver wurde vom alten Flowtail ueberschrieben.
Dieser Tail wurde vor das letzte Observerevent gezogen.

home_deferred_red.log:17/3 vor gebundener Deferredaufnahme/Homefortsetzung.
Final check.log/report.json:18/0, Source/Realprofil/Canary true,
changed_paths=[]. Vorhandener Timer bearbeitet max16 Recordkeys pro Aufruf;
Marker bleiben bis zur exakten Freigabe im vorhandenen Save-/Transportgate.
Andere Schiffe am selben Ort werden vom neuen Craftguard nicht gesperrt.
Produkt SHA256BE532CC75184BB91954249DD707147D1CE94A964D93F27A1BAA42BDA27DBC2B8.
legacy_fuel_red.log:18/1 vor Reihenfolgefix, Capture+Travelread liegen nun vor
authorize_return, das im Legacyfall bereits echten Routefuelcommit aufrufen
kann. Fehlende Controllerpreflight ruft diese Kostenbuchung nicht mehr auf.

Fruehes HomeLanding hat keine Membershipwrites, spaeterer gebundener Tail
restauriert vorhandene Profile erst nach committed. Anschliessender aborted-
Observer darf einen neuen Visit setzen, ohne von altem Flowcode ueberschrieben
zu werden. Dies ist ein Flowcaller-, kein BasePersonnel-/Travelownerbeweis.

Private Quelle und Realprofil werden im Runner verglichen. Der Observer-RED
traf parallele Quelldrift in der importierten Compileclosure; daher dort kein
source_unchanged-Pass. Die finale Probe muss eine stabile Closure ausweisen.
Weder Flow-Ready noch echte Mission-/Mapszene werden gestartet; Packedscenes
und LimboExtension werden nur fuer deren bestehende Preloadclosure importiert.
Keine native/grosse/GPU-/Peerabnahme, kein Stage/Commit.
