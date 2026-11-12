# AP7 Session-, Sender- und Empfaengeranschluss

## Ziel / Ursache
Vorhandenen verifizierten Sessionkontext und reine Empfaengerprojektion an den echten Root-/Lobby-/Driverpfad anschliessen. Bisher werden gleiche Gesamtdaten an alle Peers versendet; fehlende Actors einer Vollprojektion verschwinden nicht automatisch.

## Umfang / Nichtziele
Root-Netzmethoden und additive Helfer, Lobby-Kontextbindung vor Missionactivation, Driver-CurrentSightgetter und Netzwerkereignisse. Session-READY und genau eine CommandFlow-Sendestelle sind eng vom Parent freigegeben; Controller nur vier bestehende Remote-Sendestellen ersetzt. Keine Source-Lifecycle-/Selection-/Checkpoint-/Store-/Loaderbodies, kein neues Netzwerkmodell. Kein Testlauf/Harness in diesem Codeblock.

## Bestehende Vertraege
MULTIPLAYER_RUNTIME_CONTEXT_2026_11_12.md; MULTIPLAYER_VISIBLE_PROJECTION_2026_11_12.md; MultiplayerSnapshotContract und MultiplayerCommandContract; Architektur/Registrybesitz unveraendert.

## Akzeptanz
- Verifizierter Runtimekontext vor Activation; explizit fremde oder fehlende Kontexte bei gebundenem Netzwerkpfad vor Mutation reject.
- Commands/Ergebnisse, Chunkreassembly, ReliableVitals, READY und direkte Effekte sind kontextgebunden.
- RawHostDTO mit Kopplungsreferenzen erreicht Filter vor V1-Normalisierung. Eigene und aktuell sichtbare Daten pro Team; keine globale Spectatorsicht als Fallback.
- Expliziter Fullscope-Receiver blendet fehlende fremde Known-/RegistryActors aus, einschliesslich initialer Szenenactors und erneuter Visualprojektion.
- Legacy ohne Manifest bleibt explizit kontextlos. Keine privaten Hexclaims/Queues/Hosthandles im Peerpayload.

## Dateibesitz / Anschluss
scripts/core/simulation_root.gd (nur Netzbereich+neue Helfer); scripts/tests/mission_combat_loop_driver.gd (Netzbereich+reiner Sichtgetter); scripts/ui/multiplayer_lobby_screen.gd (Binder/READY). Die vier bestehenden Controller-RPC-Sendestellen und eine CommandFlow-Stelle verwenden jetzt submit_multiplayer_command. Source ruft refresh_multiplayer_replica_presence nach vollstaendiger neuer Admission/Activation sowie clear_multiplayer_runtime_context bei wiederverwendetem Missionreset auf. _apply_session_assignments_to_simulation_root gibt jetzt bool zurueck; initialer Start bricht vor add_child bei ungueltigem explizitem Kontext ab. Der bestehende aktive Assignment-/Perspectiveaufrufer prueft diesen Return jetzt selbst vor dem Perspective-/Selectiontail. Registry besitzt keine Registrationssignale.

## Pruefung / Risiken
Tests werden laut Nutzer erst nach dem zusammenhaengenden Codeblock gebuendelt. Kein Peer-/Native-/Performance-/fullAP7-Nachweis. Unstrukturierte direkte Kampftexte besitzen keinen beweisbaren Referenzumfang und werden im gebundenen Modus durch gefilterte Snapshotereignisse ersetzt; Legacy bleibt unveraendert. Getter verwendet vorhandene aktuelle Sichtgeometrie, keine gespeicherten Kontakte als Sichtbeweis. Source-Aufruferhooks und finale Integration bleiben ausdruecklich sichtbar.

## Codeblock / Freeze
Produktblock fertig, bewusst noch ohne Compile/Testlauf. bind_multiplayer_runtime_context(context,recipient_team) liefert {ok,reason}; akzeptiert keinen neuen Token auf bereits gebundenem Root. Commands senden den Kontext als separaten RPCparameter, nicht im Commander-/Hexpayload. Lokale bestehende Autoritaetsaufrufe bleiben lokal; Remoteaufrufe ohne exakten Token reject. Fullscope-Envelope wird vor V1-Builder/Apply explizit validiert; fremde Anfangsactors und spaetere Wiederanzeige bleiben ueber Registry/Known-Visualgate verborgen. TerrainMap3DView._is_unit_base_world_visible liest tatsaechlich CanvasItem.visible. Sicht/Projektion einmal pro Team je Broadcast; keine dauerhafte zweite Sichtwahrheit. Zugewiesene Fireteams liefern Teamprovenienz auch wenn deren Personen gerade alle eingeschifft sind.

Offen fuer Sourceintegration: Admissionvisualhook und Resetclear; keine Peer-/Nativefreigabe. Session-READY vergleicht exakt mit bereits vorhandener Sessionkennung. Bestehende versionslose/manifestlose Legacywege bleiben erhalten. Tests laut ausdruecklicher Arbeitssteuerung spaeter gebuendelt.

### Abschluss der Wire-Abweisungsgrenze
Ein erfolgreich gebundener Root behaelt nach clear einen sticky required/closed Zustand. Ohne neue gueltige Bindung lehnen Commands vom Netz, Snapshot/Chunks/Vitals/Results und Driverereignisse ab und senden keine Legacydaten. Auch ein tatsaechlich als hex_tactical_v1 deklarierter geladener MissionSetup-Mapkontext erfordert die Kennung, obwohl Clients keinen autoritativen Ground konfigurieren. Echte nie gebundene/deklarierte Legacywege bleiben kontextlos. validate_multiplayer_runtime_context_binding ist reiner Preflight; Lobby ermittelt das lokale Zielteam vor den Tabellenwrites und prueft den Binder dort. Aktiver Assignmentcallback bricht bei false vor Perspective/Selection ab. Kein Testlauf in diesem Abschlussblock.
