# Letzter Korridorausstieg: sparse Routenindex

Integrationsreview nach e8088870b fand einen direkten schedules[id]-Zugriff,
obwohl Ground ausschließlich nichtleere Routen indiziert. Letztes Mitglied
außerhalb der Gruppe plus abgelaufenes Ausstiegssegment traf den fehlenden Key.

Kleine tatsächliche Ownerfixture mit sieben Feldern reproduziert den Scriptfehler.
RED hatte Engine0 und36/0 Assertions, wird wegen SCRIPT ERROR vom Runner korrekt
als fehlgeschlagen gewertet. GREEN36/0 ohne Script-/Leakfehler; Isolations-,
Quell- und Originalprofilguards grün. Helper liest jetzt schedules.get(id,[]).
Vor Handoff und während lebender Ausstiegskante bleibt die Gruppe erhalten;
am Segmentende wird sie freigegeben. Keine Actorbewegung oder große Tests.

Originale zwei Reports/Logs in exit_runs.zip. Manifest enthält tatsächlich
getestete Quellen. Runnerkopie trägt bereits vorbereitete zusätzliche Cachecases;
diese Änderung ist nicht Teil des kleinen Fixcommits und wird hier nicht benötigt.
Historisches AP4-Manifestergebnis bleibt unverändert.
