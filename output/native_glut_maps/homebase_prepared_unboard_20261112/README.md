# Homebase prepared unboard: Produktfreeze

Reiner ADDITIVER Screen-Staging-/Projectionanschluss. Keine Root/Base/Ground-
Gameplaymutation. Bestehende normale Handler/Buy/Reise/Cardbuilder unveraendert.

API:
prepare_base_unboard(craft_id:String,fireteam_id:String)->Dictionary
  {ok,prepared:RefCounted,craft_id,fireteam_id,source_craft_id,source_fireteam_id,
   unit_ids,removed_fireteam_ids,removed_unit_ids,fireteam_definition}
validate_prepared_base_unboard(prepared:RefCounted)->{ok,prepared_id}
_publish_prepared_base_unboard(prepared:RefCounted,validation:Dictionary)->{ok}
finalize_base_unboard(prepared:RefCounted)->Dictionary

Prepare gibt leeren inprocess Handle plus detached SourceDTO. Max32 weak Records.
Bindung: genaue Screen-/AircraftManager-/Basebridgeidentitaet; bestehender
SelectedContext nur fuer Staleness, KEINE Auswahlberechtigung. Explizites anderes
Craft als Selector ist erlaubt. Bekannte Craftdefinition/eindeutige Payload-/
Fireteamzuordnung, echte Memberdaten und Boardingcraft werden gelesen/geprueft.
Keine Sanitizer/Migration/Reparatur/Handleraufrufe in Prepare/Validate.

Root/Source muss ALLE Root/Base/Screen/Groundguards VOR erstem Write validieren.
Nach erfolgreichem Groundcommit kommt dieser private Screen-Payloadtail, dann
alle Basezustandswerte, erst danach Actorprojektion, state_changed und Finalize.
Tail schreibt nur vier bestehende Projektionen plus interne Bridgephase/generation:
_homebase_dropship_staged_fireteam_ids_by_craft,
_homebase_direct_boarding_state_by_fireteam_id,
_homebase_dropship_staged_fireteam_ids,
_homebase_dropship_payload_craft_id.
Keine Signals/Refresh/Rebuild/Getters/Ownercallbacks im Tail. Bestehender Selector
bleibt unveraendert. Legacyaggregate und aktiver Payloadspiegel folgen verbleibenden
realen Mitgliedsteams entsprechend bestehendem Ownerweg.

Finalize markiert VOR echter Kontextsignalemission konsumiert; Reentry/Replay
emittiert nie doppelt. Nach Observer Lebenszeit/Context/queuedFree pruefen, erst
dann bei Treepraesenz bestehender UIrebuild. Bereits vor Finalize geaenderter
Screenkontext wird konsumiert mit ok/context_changed/emitted:false behandelt:
kein postcommitTransaktionsreject und kein veraltetes Kontextsignal.

RED0/1 fehlende APIs:
prepared_unboard-64fb5e04bbd24a05a4cea168e4e2a34d/
GREEN18/0 incl private Compile/Import:
prepared_unboard-cda5a78f8ab544c7b4000272f7fe9baf/
Exit0, keine Script-/Enginefehler, Originalprofil/Quellen identisch, Canary wahr.

Echte HomebaseScreen.new ohne Subclass/Override/FakeScreen; echte AircraftManager-
und Payloadhelper, echte fireteam_context_changed-Signale mit reentrantem Observer.
Read-only Prepare, DTO/Signalnoalias, Fremdhandle/craft und StaleSelected/Boarding,
stiller Publish und vollstaendige Projektionssicht beim Callback, Reentry/Replay,
Reset nach/vor Emission und Legacyspiegel bei leerem anderem Payloadteam.
Screen bleibt fuer diese Ownerprobe ausserhalb SceneTree: Signalweg ist echt,
kein nativer UI-/Root/Base-Gruppencommit- oder Szenenaufbau-/Rendernachweis.
Source besitzt den echten Runtimeanschluss; keine volle Ausstiegsfreigabe daraus.

Eigener Runner mit realer Preload-/Ressourcenclosure, privater Projekt-/Userkopie:
python output/native_glut_maps/homebase_prepared_unboard_20261112/run.py
Keine Hauptszene/GPU/grosse Matrix/Sharedrunneredits/Gitaktionen.
