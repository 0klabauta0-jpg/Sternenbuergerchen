# Wellenretirement und serielles Actorstaging

Folgefix zu785cbd715, Basis01b06f8c6 einschließlich der additiven vorbereiteten
Actor-Medical-API aus Parentaf56a0fcf. Medicalverbund selbst war während dieser
Probe privat beiseitegelegt; er ist kein Produktteil dieses Fixes.

Parentreview fand zwei tatsächliche Reste: initialize([]) verlor den Zugriff auf
vorherige aktive Mitglieder, und synchrone Reinitialisierung desselben Actors aus
deactivate_for_wave konnte dessen innere Neuaktivierung wieder unsichtbar machen.
Echte Actor-/Root-/Ground-/Registry-/Sichtprobe sauber RED60/3→GREEN63/0. Prüfung
eines anschließenden expliziten Resets nach Rootkontextwechsel zusätzlich63/1→64/0.
Direkter initialer Setupnachbar62/0. Exit-, Engine-/Leak-, Profil-, Quell- und
Isolationsguards grün. Originale und134 Quellhashes im Manifest/Archiv.

Initialisierung deaktiviert alte und neu übergebene Mitglieder vollständig, bevor
sie neue Slots aufbaut. Reentry während medizinischer Actoraufrufe oder laufender
Wellenpublikation wird serialisiert; identische laufende Anforderungen werden
zusammengefasst. Höchstens eine ausstehende Initialisierung wird unmittelbar
nachgezogen; weitere Arbeit erhält der nächste normale Processaufruf.
Rootpublikation prüft den gebundenen Generationguard vor jedem sichtbaren Actor.
Die Probe prüft tatsächlichen Ground-/Registryabbau und beide Sichtbarkeiten,
einschließlich einer Reinitialisierung aus visibility_changed des ersten Actors.

Kein vollständiger AP6/7/8, keine native Spielfluss-/Performanceabnahme, EXE,
Mainintegration oder Produktionskennung. Große Prüfungen bleiben zurückgestellt.
