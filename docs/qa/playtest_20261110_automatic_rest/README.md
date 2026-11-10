# Automatische Basisruhe – 10.11.2026

Auf Taskbasis 274f142c2 im isolierten Checkout playtest-rest-resources-20261110.

RED: automatic_rest_verifier brach am fehlenden Runtime-Owner-Verhalten ab.
GREEN: automatic_rest_verifier 15 Assertions, null Fehler; echte Wege zu zwei
unterschiedlichen Betten, kein Teleport, manuelle Bewegung/Ausruestung wecken,
beide echten CheckButtons steuern denselben NPC-Zustand, deaktiviert bleibt er
stehen, Save und echtes Continue erhalten die Einstellung. Isoliertes APPDATA.
Zwei komplette reale Kampagnen-Ausfluege mit Wiedereinsteigen und Continue:
152 Assertions, null Fehler, keine Engine-/Scriptfehler.

Native D3D12/1920x1080 nach 35 Sekunden zeigt beide NPCs liegend im Basiszimmer,
auswaehlbare Anja Voss und Automatisch-ruhen-Schalter, Einsteigen/Ausruesten aktiv.
Lokale Aufnahme: output/playtest_20261110/native/base.png. Ruhender Lauf:
P95 3.973 ms, P99 10.517 ms, Maximum 126.072 ms, Start 25.38 s. Dies ist keine
allgemeine Performance- oder Stilabnahme. Es existiert kein Needs-/Heilungsowner,
also erzeugt Schlaf keinen erfundenen Heilungseffekt.

UI-Probe fand zuerst einen WeakRef-Aufruf statt des Zielnodes und eine im Test
noch nicht geoeffnete Basisansicht; beides korrigiert, anschliessend sauber erneut
geprueft. Keine Nutzerspielstaende benutzt und keine EXE veroeffentlicht.
