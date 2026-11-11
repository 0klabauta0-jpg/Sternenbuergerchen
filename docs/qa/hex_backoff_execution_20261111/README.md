# AP5 tatsächliches Ausweichen und Wiederaufnahme

Basis e4c098f63. Root-Moveadapter hält Originalziel/Command und nimmt höchstens
ein neues vorgeschlagenes Ausweichmanöver je Tick an. Die Recoveryroute wird
im nächsten Tick wieder gemeinsam geplant/committet; keine Ownerumgehung.
Reiner Planer vermeidet mit kleinem16×5-Zielindex eine Bay unmittelbar auf dem
Gegenweg; gemeinsame Rücksetzsuche bleibt bei64 untersuchten Knoten.

Isolierte Godot4.6.2-Privatprojekte, tatsächliche Produktionsquellen:
`python scripts/tests/run_hex_tactical_check.py --case CASE`.

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| backoff |55 /0|
| reservation |26 /0|
| reservation_owner |36 /0|

Backoff enthält dieselben42 Bewegungsbasisprüfungen des Vorgängers. Alle finalen
Prozesse0, Originalprofil-/Quell-/Canaryguards grün, keine Script-/Leakfehler.
Manifest nennt genaue finale Quellhashes; backoff_runs.zip archiviert unveränderte
Reports/Logs einschließlich Fehler. Keine Hauptszene, UI oder Nativegrafik gestartet.

Höchstens zwölf Felder: echte Rootqueue/UnitRegistry/CapabilityActors mit
entgegengesetzten Zielaufträgen. Niedrigerer Score weicht aus, Belegung bleibt
exklusiv, Originalziele/UnitCommands bleiben gleich, keine frühe Bayankunft.
Langsamer Gegenverkehr behält seine Route, Bay liegt seitlich; wartender NPC
startet keine neue Suche und setzt vor Ende eines entfernten Gegenverkehrsziels
fort. Navbudget1 mit versetzt fertigen Suchen, invalidiertes Ausweichziel, echter
Hold während Recovery, fehlende Ausweichmöglichkeit und erhaltenes Wartealter.

RED46/2→erster GREEN48/0. Danach49/2 (Bay auf dem Gegenweg und neue Suche beim
Baywarten)→51/0. Getaktete Anfragen und Terraininvalidierung51/2→53/0: nur gültige
gecachte Konkurrenzrequests werden im bestehenden gemeinsamen Limit ergänzt.
Wartealter53/1→54/0: Recoveryfortschritt setzt den Zähler nicht zurück. Bereits
geräumte Clearancezelle verschwindet54/1→55/0: ungültiger Claimread löst private
Wartebindung und Watcher, der Originalauftrag wird sicher neu geplant. Ein letzter
Review-P3 fand Vollpfad.has im Beziehungscheck; nun derselbe Pfadindex/Cursor.
Zwischenversuch beim Lookupfix hatte meine falsche Einrückung und lief in den
30s-Prozessguard; er ist kein valider Produkt-RED und unverändert archiviert.
Enger Nachreview ohne verbleibende Befunde, Reviewer ohne Engine oder Edits.

Kein SceneTree- oder Feldwechsel×Orders-Vollscan. Pfadindex wird bei ohnehin
notwendigem Timingaufbau erzeugt; Reverseindex beobachtet committed Passage.
Bestehende Pfadrestkopien und Planerarbeit bleiben, eingesparte Millisekunden/FPS
sind nicht gemessen. Keine allgemeine Deadlockfreiheit oder optimale Trafficlösung.
Ausdrücklich haltende NPCs und unerfüllbare Zielwünsche werden nicht umgedeutet.

AP7 muss ursprüngliches Ziel, Recoveryphase/-ziel, konkurrierende Identitäten,
Passagebeobachtung und Fairnessalter konsistent restaurieren; Cache-/Such-/Dauer-
und Reverseindexdaten werden nicht gespeichert. AP6 Lifecycle und AP8 kleiner
integrierter Kandidat offen. Keine Produktionsflag-/Main-/EXE-/große Testfreigabe.
