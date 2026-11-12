# Eine echte Medical-Verbraucherreihenfolge — RED reproduziert

`check.log` ist der kanonische enge Lauf. Exit0/Marker bedeutet erfolgreiche
Fehlerreproduktion, KEINEN Produktpass. report.json führt product_pass=false.
Originalprofil-, Quell- und privater Canaryguard true; Godot4.6.2, kein GPU/Main.

Echtes Root/Manager/TestUnit-Rig aus vorhandenem hex_respawn_verifier, nur dessen
12-Feld-Aufbauhilfe aufgerufen. Echter Driverhandler; nur Ready und UI-/Broadcast-
Grenzen werden kontrolliert. Kein medizinischer Zustand oder Rootresult gefälscht.

Ein früher Subscriber am echten Managercompleted-Signal liest den erfolgreichen
Receipt, Fitstatus und neues Groundziel, ruft dann echtes Actor.apply_damage(1000).
Dessen echtes Vitalsignal ruft den echten Driver-Vitalhandler auf: neuer Downlinger
vorhanden. Erst danach läuft der echte Drivercompleted-Handler und entfernt diesen
neuen Linger; letzter Eventtext/Broadcast ist RESPAWN READY trotz Actorstatus down.
Diese eine Reihenfolge ist der Nachweis, kein Actorersetzungs-/Netz-/Gesamttest.

Das Rootcommit ist korrekt abgeschlossen; ein späterer Signalsubscriber benötigt
seinen eigenen aktuellen Zustands-/Bindungscheck, bevor er Downmetadaten löscht
oder veraltetes READY meldet. Keine Produktänderung in diesem Reprotask.

Harnesshinweis: Der erste Lauf startete über den geerbten Fixturekonstruktor
unbeabsichtigt dessen76er-Verifier zusätzlich. `harness_inherited_first.log`
bewahrt ihn, wird aber NICHT als zusätzliche angeforderte Abnahme gewertet.
Privater `_run`-Override verhindert das; kanonischer Zweitlauf enthält allein
die eine Verbraucherrepro. Keine Sharedrunneränderung, kein Stage/Commit.

Artefakte: check.gd, run.py, import.log, check.log, report.json, dieser Bericht,
.gdignore, SHA256SUMS.txt; historischer erster Harnesslog separat benannt.
