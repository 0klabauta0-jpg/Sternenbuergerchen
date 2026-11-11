# AP5 Türschluss gegen Belegung und Zusagen

Basis a74fbab2f. Problem: Der tatsächliche lokale Driver-Producer kann eine Tür
schließen/halb schließen, während Ground eine aktuelle Zelle, aktive Kante oder
künftige Passage zugesagt hat. Nur den Visual-/Registryread offen zu halten
würde den eigentlichen Interactionstate nicht schützen.

Owner: MissionCombatLoopDriver.update_mission_interaction_runtime_progress
committet den vorhandenen lokalen Interactionstate und projiziert ihn anschließend
über MissionInteractionDoorRuntimeCollisionLOS in die Registry. Es gibt hier keinen
_on_simulation_mission_interaction_runtime_event-Hook. Der Integrationschat hat
den tatsächlichen Producer freigegeben. Root/Ground liefern nur reine Claimreads.

Umfang: begrenzte Root-/Groundbatchabfrage (höchstens64 konkrete Türzellen),
Driver prüft einen bisher offenen, künftig nicht begehbaren Kandidaten vor Statecommit und vor einem
möglichen LocationResources.accept_progress-Seiteneffekt. Aktuelle Belegung,
nicht beendete Segmente an beiden Endpunkten und aktive vollständige Korridor-
grants sperren den Schluss. Öffnen und unbeanspruchtes Schließen bleiben möglich.
Bei Konflikt wird die Absicht mit lesbarem Grund abgelehnt; Ownerstate, Registry,
Revision und Reservierungen bleiben gleich. Kein versteckter Autoclose-Timer.

Verträge: hex_tactical_runtime_contract.md, hex_reservation_plan_contract.md,
explicit_hex_ramps_contract.md, mission_interaction_point_contract.md. Marker-/
Zustandsauflösung aus bestehendem DoorRuntimehelfer, keine zweite Geometrie.
Zuständiger Root muss dieselbe Registry besitzen; fehlender Nachweis fällt im
aktiven Hexkontext geschlossen aus. Legacyweg behält seine bisherigen Regeln.

Dateien: HexGroundRuntime, SimulationRoot, tatsächlicher schmaler Driverproducer,
kleiner hex_door_guard_verifier/isolierter Runner und Vertrags-/QAergänzungen.
Akzeptanz: Rootqueue führt NPC durch offene Tür; Schließen vor Eintritt, bei
Belegung und nach Handoff während aktiver Kante wird abgelehnt, nach kompletter
Freigabe erlaubt. Verwundete behalten ihre Zelle. Reine Claimreads und ungültige
Batch-/Registryeingaben mutieren nichts. Kein SceneTree-/Vollkartenscan.

Prüfung: neun Felder mit echtem Ausgangsraum, tatsächlicher Root/Registry/Actor und tatsächliche
Drivermutation mit unterdrücktem unbeteiligtem Szenenstartup; vorhandene kleine
Move-/Korridor-/Türnachbarn. Keine große Mission/Native-/Performanceabnahme.
Nichtziele: Szenariowechsel-/Neuaufbauzulassung AP6 und atomarer Save-/Multiplayer-
Snapshotrestore AP7; diese sind keine lokalen Türbefehle und bleiben vor
Aktivierung separat abzusichern. Kein Eingriff in ShipReturn-, Crew-, Basis-,
Orbit-/Rottenarbeit. Backoff/Lifecycle/Save/Netzwerk und AP9 bleiben offen.

Ergebnis: Ground-/Rootread und echter Driverguard angeschlossen. DoorGuard58/0
einschließlich42 Basisprüfungen, SightConsumers39/0, ReservationOwner36/0;
Quell-/Profil-/Canaryguards grün. Enger Review und Nachreview ohne Restbefunde.
Eigener fehlender-/inaktiverOwner-Nachfund56/2→58/0: geladene Opt-in-Karte darf
beim Schluss keinen Legacyfallback wählen. Neunfelderfixture besitzt echten
Ausgangsraum; erste tote Sackgasse war kein Nachweis einer freigegebenen Passage.
QA hex_door_guard_20261111. MP-/Szenariolifecyclegrenzen bleiben oben offen.
