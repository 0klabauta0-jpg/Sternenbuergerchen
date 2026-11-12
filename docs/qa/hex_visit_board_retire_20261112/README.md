# Tatsächlicher Crew-/Visitverbund

Basis ffac078d4. Produktänderungen: Source-Root und Controller. Keine Source-
MetaFlow-, Space-, Stationsadmission- oder Renderdatei überschrieben. Sieben
vorhandene Controllerabhängigkeiten aus Parent2bfebc601 selektiv übernommen:
Flightguard, Pilotassigment, Boarding, Retirement, Crew-ID-/Actorgetter und
Stationsexaktheitsgetter. Basishashes in parent_baseline_methods.json.
Davon getrennt stehen die neuen Commit-, Ownership- und Callbackguards.

Die tatsächliche Flowquelle ist ausdrücklich eine private gepinnte Abhängigkeit:
zuerst2bfebc601 für den Space-Repro a85932807, zuletzt1645bc28a mit dem dort
getrennt implementierten gebundenen Aufrufer. Runner kopiert diesen Gitblob nur
ins private Projekt. Fehlende Sparseabhängigkeiten stammen aus angegebenen
unveränderlichen Gitrefs. Workspaceguard kontrolliert auch die unveränderte,
hier unbenutzte Source-Flowdatei. Manifest unterscheidet Workspacehashes,
tatsächlich getestete Hashes je Fall und Dependencyrefs. Gemeinsame Parentprobe
nach Import bleibt ein eigener Nachweis.

Final tatsächlicher Flow/Controller/Root/Known/Registry/Ground37/0, direkter
Deploymentphasen-Nachbar95/0. Private UUID-Projekte/-Profile, maximal zwölf Felder,
alle Exit-/Script-/Leak-/Quell-/Profil-/Isolationsguards grün. Actor, Card,
Landezustand und UIanzeigen sind bekannte Eingaben; Flowbindings/Rootcommits sind
Produktcode.427 Runtimequellen im Verbund,49 im Nachbarn,410 kontrollierte
Workspacedateien. Originale aller zwölf Versuche im Archiv, keine Assetkopien.

Originalrepro exakt4/3→7/0. Gruppen-, andere Schiff-/Crew-/FTLplan-, Registry-
reparatur-, Lifecycle-/Visit-/Kontext- und Legacygrenzen erweitert. Sichtcallback
mit Wiederaufnahme eines Members24/1→25/0: übrige unveränderte Bordpersonen
werden trotzdem verborgen. Nachpublikation25/2→27/0. Enger Review belegte
Visitwechsel/entfernten Controller und fremden Cardpiloten27/6; unabhängige
Eingabefälle ebenso27/6, danach33/0. Pilotassigment besaß im Parent bereits eigene
Guards und wurde als ältere Sourceabhängigkeit übernommen. Gemeinsame explizite
Membershipprüfung zusätzlich vor Board/Retire/Pilotänderung. Echter Caller-Wait/
Repairverbund und logische Distanz36/1→37/0.

Root übernimmt die ganze zulässige Gruppe synchron ohne Ground-/Moveclaims.
Controllerindices/Sequence stehen vor ersten Sicht-/Planungscallbacks vollständig.
Hexdistanz liest Feldmitte, dieselbe bisherige Boardingradiuszahl bleibt erhalten.
Ausstehende echte Ausstiegsslots sperren Flugbereitschaft. Legacyboarding behält
Queuekadenz. Fremde explizite Visits überstimmen den bloßen Cardpiloten.

Retirement liefert committed/waiting/stale. Opake inprocess Bindingkopie enthält
Rootinstance/-kontext, Actor-/Lifecyclegenerationen und Visitfingerprint; weder
Save- noch Netzwerkpayload. Fehler vor Rootcommit erhalten Feld, Move und
Controllerprojektion. Tatsächlicher Parent-Flow hält auch Location/Remember und
bestehenden per-craft Pendingmarker zurück. Ursprüngliche Registryreparatur
schließt über denselben gebundenen Retry Root, Controller und Flow ab. Veraltete
Bindungen/neue Callbackzulassungen beenden alte Fortsetzungen; historischer
Commit wird nicht zurückgerollt.

parent_controller_only.patch ist enge Integrationshilfe gegen2bfebc601, kein
Wholefileoverwrite oder Ersatz für aktuellen Konfliktabgleich. Andere Mitglieder
behalten hier Controllerpläne/Rootintents. Vollständiger FMC-Member-/Slotlifecycle
ist das nächste Paket. AP7/8, native Spielfluss-/Performanceabnahme und große AP9
bleiben offen. Keine Produktionskennung, Main oder EXE.
