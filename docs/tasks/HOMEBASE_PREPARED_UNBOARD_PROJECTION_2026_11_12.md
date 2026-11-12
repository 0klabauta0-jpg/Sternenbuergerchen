# Stille vorbereitete Homebase-Ausstiegsprojektion

## Ziel / Ursache
Normaler Screenhandler entfernt Payload und emittiert Kontext synchron, bevor
Root/Base Groundzulassung bestaetigt haben. Neue Bruecke trennt Vorbereitung,
stillen Valuepublish und nachgelagerte UI-/Kontextsignale.
## Umfang / Nichtziele
NUR additive neue Methoden/Helfer/private Felder in scripts/meta/homebase_screen.gd.
Bestehende Handler/Kauf/Reise/Cardbuilder unveraendert. Kein Root/Base/Ground-
Gameplayzustand, kein Sharedrunner. Keine neue Crew-/Missionwahrheit.
## API / Strategie
prepare_base_unboard(craft_id,fireteam_id) liefert leeren inprocess Handle und
detached SourceIDs/entfernteFT-/Unitdaten/FTdefinition. Echte eindeutige Zuordnung
und vorhandene Kontextdaten pruefen, keine Legacyreparatur oder stiller Fallback.
validate_prepared_base_unboard bindet Screen/Manager/Basebridge und relevante
Staging-/FT-/Member-/Boarding-/Craftwerte. Private Records mit weakrefs sind bounded.
_publish_prepared_base_unboard weist ausschliesslich vorbereitete vier vorhandene
Payloadprojektionen und interne Recordphase zu: by_craft,boarding_by_ft,legacy_ids,
active_payload_craft. Keine Signals/Refresh/Rebuild/fallible Owneroperationen.
finalize_base_unboard markiert VOR Emission abgeschlossen; bestehender Kontext-
signalweg und bei sichtbarem Tree bestehender UIrebuild danach. Replay/reentry
emittiert nie doppelt. Root/Base pruefen alle Gates separat VOR erstem Groundwrite.
## Akzeptanz / Dateien / Pruefung
Eigene echte Screenklasse ohne Methodendoubles/FakeScreen; bestehende echte
Signale mit reentrantem Observer. Prepare/Reject unveraendert, silent Publish,
Finalize sieht bereits vollstaendige Projektion, Fremdhandle/Stale/Noalias/Replay.
Eigene QA output/native_glut_maps/homebase_prepared_unboard_20261112.
## Dokumente / Risiken
PROJECT_BRIEF/ARCHITECTURE/CODEX_RULES, Hexruntimecontract/AP6. Root/Basecallback-
reihenfolge und Actorprojektion bleiben Sourcearbeit. Kein Gesamttest, GPU oder
Gitaktionen; vorhandener normaler Handler bleibt fuer Legacy unveraendert.

## Ergebnis / Freeze
Echte Screen18/0 inklusive private Compile/Import und alle Guards gruen.
Prepare liefert SourceDTO detached, kein Auswahlzwang fuer explizites anderes
Craft. Legacyspiegel beruecksichtigt echte verbleibende Memberteams. Reentry und
gewechselter Kontext vor/nach Signal sind abgedeckt; nach Commit kein spaeter
Transaktionsreject wegen Projectionreset. TestScreen ausserhalb SceneTree, kein
Fake/Override; echte Signale/Helper, aber kein nativer UI-/Root/Base-Gruppennachweis.
SourceRuntimeanschluss separat. README/Manifest enthalten exakte API und Logs.
