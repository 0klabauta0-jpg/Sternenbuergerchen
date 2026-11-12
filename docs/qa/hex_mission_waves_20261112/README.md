# Tatsächliche Wellenzulassung, kleine Probe

Basis306a07790. Tatsächlicher EnemyWaveController, TestUnit, Root, Ground und
UnitRegistry in privatem Kopflosem Projekt, höchstens zwei Wellenfelder. Der
geerbte Bewegungscheck benutzt seine begrenzte Zwölffeldfixture. Nur Ready/UI
unterdrückt; der Schiffsmaskenproducer liefert hier bekannte Projektionsdaten.
Sein tatsächlicher Körper ist separat unter hex_ship_producer_20261112 geprüft.

Final Wellen60/0 und unmittelbar benachbarter Missionssetup62/0. Profil-, Quell-,
Isolations-, Exit-, Script- und Leakguards grün,134 Quellhashes im Manifest.
Originalberichte und äußere Logs aller Versuche im Archiv. Ein zusätzlicher
Testversuch versuchte den gerade sendenden Controller mit free() zu entfernen;
Godot verbietet das wegen seiner Signalsperre. Dieser fehlerhafte Testaufbau ist
archiviert und zählt nicht als sauberer Produkt-RED. Die gültige Lebensdauerprobe
benutzt queue_free(). Sauberer Initial-RED45/4→GREEN51/0, Reentry-Timer54/1→55/0,
Kontextpublikation und tatsächliche Folgewellengrenzen anschließend59/0.

Geprüft: ganze Gruppe bei Platzmangel dormant, kein Zählerfortschritt oder
Registryphantom, keine neue Planung bei unveränderten Claims auch über Rootticks,
Claimfreigabe/kurzer Retry, gestufte Folgeaktivierung und genau eine Endmeldung,
alte Rootkontexte/Lifecycles, Reinitialisierung aus Wellenmeldungen sowie
Kontextwechsel während sichtbarer Actorprojektion. Akzeptierte Schiffsmasken
blockieren Zulassung und ihre Änderung löst ohne Terrainmutation einen Retry aus.

Kein Runtime-Slotwechsel, Respawn, vollständiger AP6/7/8, Produktionsflag,
Mainintegration, EXE, native Spielfluss- oder Performanceabnahme. Große AP9 später.

Frischer Readonlyreview fand synchrones Reinitialisieren aus dem tatsächlichen
Actor-Deaktivierungssignal. Originalrepro hatte einen echten Scriptfehler trotz
Assertionmarker; Runner wies ihn korrekt zurück. Generation/Lebensdauer nach
diesem Callback geprüft; anschließend60/0 ohne Enginefehler.
