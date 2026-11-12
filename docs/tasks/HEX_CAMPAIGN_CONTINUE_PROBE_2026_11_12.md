# Kleiner Store-/Continue-Ownerfall

## Ziel und Ursache
Den tatsächlichen neuen Speicher-/Fortsetzen-Anschluss nach dem AP6/7/8-Codejoin
prüfen. In-place Root/Netzprüfung beweist keinen frischen Kampagnenstart.

## Umfang und Grenzen
Ein serieller Fall mit realem CampaignStart, Store, Adapter, Base, BaseActors,
Root und dem vollständigen tatsächlichen BaseInteriorNavigation-Raster384x392,
16x8. Nur ungenutzte UI-Darstellung und Szenen-Startloops im Fixture unterdrücken.
Pilot läuft real zum Schiff und wird gespeichert. Frisches Continue samt echter
Candidatevorprüfung muss Zustand, Tick/RNG und Hiddenprojektion vor Basissignal
erhalten. Kein FakeRoot, coarseMap, Saveaktivator oder Produktionskartenumbau.

Runner kopiert Quellen und eigenes user://, gibt nur der privaten positiven
Navigationskopie ausdrücklich hex_tactical_v1 und protokolliert diese Grenze.
Zweiter Prozess erhält dieselben gespeicherten Daten und die exakten unflagged
Originalbytes: Continue muss vor Flowwrites ablehnen. Unbekannte Version und
unvollständiger V2-Block werden als wenige bestehende Formatgrenzen geprüft.

## Verträge und Dateien
HEX_CHECKPOINT_ROOT_JOIN_2026_11_12; AP7_MULTIPLAYER_RUNTIME_JOIN_2026_11_12;
hex_ground_runtime_contract und Rampenvertrag. Neue Dateien ausschließlich
scripts/tests/hex_campaign_continue_verifier.gd und run_hex_campaign_continue.py.
Keine Änderungen an den drei Parent-Metadateien.

## Akzeptanz und lokale Prüfung
`python scripts/tests/run_hex_campaign_continue.py --execute` erst nach Parent-
Codefreeze seriell zum bestehenden Bundle. Zwei erfolgreiche Abschlussmarker,
keine Script-/Parse-/Teardownfehler, Quellen- und echtes Profil unverändert,
private Canary vorhanden. Report liegt unter .godot/hex_campaign_continue/.
Vorbereitung ist ausdrücklich kein bestandener Lauf. Keine Performance-/Peer-/
Native-/Main-/EXE-Abnahme; große Performanceprüfungen folgen später.

Erste tatsächliche Parentprobe: FineMap, neuer Kampagnenstart, tatsächliche
Registry und echtes Pilotboarding bestanden; Save wird rot bei
invalid_hex_checkpoint_transport (PackedStringArray aus bestehendem
PersonnelLoadoutState gegen neue Array-only-Eingangsprüfung). Metawriter
korrigiert diesen Produkteingang. Im Test außerdem fehlenden rein visuellen
FOB-Refresh-Override ergänzt; keine Bord-/Roster-/Ownerlogik ersetzt.
Source-/echtesProfil-/Canaryguards der roten Probe waren erfolgreich.
