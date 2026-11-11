# AP6b: Slots für einzelne Aussteigephasen

Basis `86347ca54`, Godot 4.6.2. Private isolierte Headlessprojekte, keine
Hauptszene/Kampagne oder native Darstellung, kein EXE-/Last-/Gefechtslauf.

Final: AdmissionSlots87/0 einschließlich63 bestehender Move-/Lifecyclechecks,
Backoff55/0, Planer26/0, Owner56/0. Alle Quellen-, Originalprofil- und
Isolationsguards bestanden. `manifest.json` bindet47 geladene Quellpfade und
den Runner bytegenau; `slot_runs.zip` enthält13 ursprüngliche Versuche samt
Reports/Logs. Saubere REDs: fehlendes Slot-API63/1, alte Queuepayloads79/2,
Despawn81/2 und nach sicherem Registrygetter Registry-/Despawnfälle81/3.
Zwei fehlerhafte Versuche sind ausdrücklich keine validen REDs/Erfolge: erster
Slot-GREENversuch verwendete im Verifier eine falsche Commitargumentzahl;
erster staleRegistry-Repro löste im alten typisierten Getter einen SCRIPT ERROR
aus. Runner verwarf beide trotz gedruckter PASSmarker.

Nachgewiesen: ganze Gruppenvormerkung ohne Groundunit an Bord, echte einzelne
Root-Deploy-/Embarkeffects, staged Actoraktivierung, Slot-/Tür-/Motionexklusivität,
unabhängiger Ownerreject eines gefälschten Bewegungsplans, falsches Ticket,
Abbruch ohne Verlust bereits ausgestiegener Personen, Wiederaufnahme wartender
Bewegung, Terraininvalidierung, Kontextwechsel und alte Payloads nach Readmission.
Echtes Actor.free() räumt Ground/Registry über Tree-Exit, auch bei vorgemerkter
Gruppe. Ein unabhängiger Review fand einen stalen Registrykey und den leeren
Releasegrund; beide geschlossen und durch echte Pfade geprüft.

Offen in AP6: konkrete gestaffelte Controllerproducer, Setup und Basisadapter.
Neue Hexpersonen benötigen jetzt ein vom Root vorbereitetes Ticket; produktive
Karten bleiben deshalb bis zur vollständigen Anbindung inaktiv. Fremde geparkte
Schiffsflächen müssen aus dem vorhandenen Visit-/Landungsowner konsumiert werden.
AP7 Restore/Authority und AP8 kleiner integrierter Kandidat folgen. Keine globale
Deadlock-, Native-, Balance- oder Performancefreigabe; große AP9-Tests später.
