# AP8 integrierter Netzwerk-Owneranschluss

## Ziel / Ursache
Den bestehenden opt-in 12Hex-Integrationsslice ueber Purefilter hinaus an echte Session-/Rootbindung, Hostpublikation, Chunk-/Vitalsreceiver und Lebenszeitabweisung anschliessen. RootCheckpoint baut Source getrennt; der bestaetigte oeffentliche APIanschluss ist jetzt direkt enthalten, kein guessed API/Fakepass.

## Umfang / Nichtziele
Nur vorhandener scripts/tests/hex_tactical_slice_verifier.gd, neuer tests/hex_tactical_network_join.gd und scripts/tests/run_ap8_network_owner_join.py, diese Task und eigenes docs/qa/ap8_network_owner_join_20261112. Output ist nur generierte Evidenz. Keine Produktdateien, Flags, KartenJSON, Sharedrunner oder EXE; kein Stage/Commit. Laut Nutzer jetzt KEIN Compile/Testlauf.

## Vertraege
AP5_TO_AP8_CONTINUATION_2026_11_11; AP8_JOINT_PASSAGE_ROUNDTRIP_2026_11_12; AP7_MULTIPLAYER_RUNTIME_JOIN_2026_11_12; MULTIPLAYER_RUNTIME_CONTEXT_2026_11_12; MULTIPLAYER_VISIBLE_PROJECTION_2026_11_12. Vorhandener Ground-/Movementroundtrip bleibt erhalten.

## Akzeptanz / zusammenhaengender Codeblock
- Echter vorhandener 12Tile Root/Ground/Movement/Driver bleibt Host; echte aktuelle Hexsicht/Facing statt sichtbarer-IDstub.
- Echte Session mintet Runtimekontext aus kontrolliertem akzeptiertem Fixturemanifest, echter Root bindet ihn. Zweiter Start liefert neue Identitaet.
- Tatsachlicher Hostpublisher erzeugt proTeam Fullscopechunks und ReliableVitals. Test-only MultiplayerAPIExtension erfasst ausschliesslich RPCtransport; keine Root-/Sicht-/Filtermethoden werden ersetzt. Capturedbytes gehen in umgekehrter Chunkreihenfolge durch echten Rootreceiver.
- Anfangsactors in Registry/Known, eigene Daten/verborgene referenzierte Ziele, sichtbare Gegner und erneute Abwesenheit durch reale Hostfacingwechsel; echte ReceiverSignalabonnenten.
- Alte/fremde/fehlende Kontexte, Clear/Closed und erneute Bindung, Commands/READY/Result/Vitalsgrenzen ohne private Hostclaims im Peerpayload.
- SourceRootcheckpoint ueber bestaetigte oeffentliche API direkt im laufenden Passagezustand: guard/export/JSON/prepare/validate/commit(false)/finalize. Fehlende API ist Fail; kein Fallbackpass. Falsche Map bleibt ohne Teilmutation; Owner/Posen/Absichten/ganze Zusagen bleiben erhalten.

## Dateibesitz / Pruefung
Eigener opt-inRunner kopiert nur Preloadclosure in frisches Projekt/Profil und haelt historische15/0-Evidenz unveraendert. Neues Manifest status=prepared_unexecuted, keine erfundenen Zahlen/Passflags. Runner ist fuer spaeteren gebuendelten Aufruf vorbereitet und jetzt nicht ausgefuehrt.

## Risiken / offene Grenzen
Kontrollierte MultiplayerAPIExtension ist keine ENet/UDP-/Peerhandshake-/LAN-/Nativeabnahme. Replicaactors sind explizite Capabilitydoubles mit echtem UnitVitalStatus; Host Root/Ground/Movement/Driver/Session/Filter/Normalizer/Chunks sind echt. Manifestform wird durch echte Session geprueft, Dateidownload-/Hashmatching wird hier nicht behauptet. Rootcheckpoint-Implementierung/Import liegt beim Source; der echte Anschluss ist jetzt im Slice implementiert, noch nicht ausgefuehrt. Screen/Base/Freshload/Store und volle AP8-Abnahme bleiben gesonderte Integrationsgrenzen.

## Abgabe / Codefreeze
Der zusammenhaengende Fixtureblock ist vorbereitet, nicht ausgefuehrt und nicht compiled. Netzwerkhelper bleibt am kontrollierten Transport; Rootcheckpoint benutzt die bestaetigten echten Rootmethoden direkt in derselben laufenden12Tile-Passage. Keine neue Produktdatei/-flag/-JSON oder Sharedrunneraenderung. Bundleanschluss: python scripts/tests/run_ap8_network_owner_join.py. Erforderliche spaetere report.json-Felder: ap8_bounded_ready/partial_ready/root_checkpoint/host_publication/receiver/runtime_lifetime/source_unchanged/real_profile_unchanged/private_canary jeweils true, exit_code0. ap8_bounded_ready wird nach tatsaechlichem Sliceerfolg true; real_peer/native_acceptance bleiben false als AP9-Grenzen und blockieren AP8 nicht.

### Bounded-AP8-Semantik und getrackter Runner
Der bestehende12Felderablauf inklusive Rootcheckpoint+Hostpublisher+Receiver ist der begrenzte AP8-Kandidat. Dessen Endmarker AP8_BOUNDED_CANDIDATE_READY setzt nach spaeterem realem Durchlauf ap8_bounded_ready=true. Echte Peers/native/Produktionskarten gehoeren AP9; kein kuenstliches weiteres AP8-Hindernis. Eigene repo-faehige Runnerimplementierung liegt scripts/tests/run_ap8_network_owner_join.py, Vorbereitungsevidenz docs/qa/ap8_network_owner_join_20261112; keine alten ignorierten Outputpakete pauschal sichern. Bis zum angeordneten Lauf sind Manifestwerte explizit null/ausstehend, keine behauptete Abnahme.

## Gemeinsamer begrenzter Abschluss 12.11.2026

Code integriert; kleine Funktionsfälle Selection16/0, Base30/0, AP8-Root/Net38/0 und CampaignContinue17/0+3/0 mit sauberen Logs/Quell-/Profil-/Canaryguards. Originalberichte, genaue Commitgrenzen und Fixtureeinschränkungen: `docs/qa/ap678_bundle_20261112/README.md`. Dieser spätere Nachweis ersetzt den obigen Codefreeze-/Vorbereitungsstatus; keine AP9-/Native-/echtePeer-/Leistungsfreigabe, kein Mainmerge oder EXE.
