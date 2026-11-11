# Local Travel Lifecycle Guard (unverdrahtete Reaktivierung)

## Ziel / Ursache
Alte Travelaktionen schreiben strategische Flightposen. Nach Aufnahme in eine lokale Orbitkarte muss dieser Weg vor jeder Mutation geschlossen werden; der bestehende strategische Invariantassert ist keine Localfreigabe. Eine spaetere Oberflaechenrueckkehr soll den vorhandenen inaktiven lokalen Flight reaktivieren, ohne Pose, Bereich oder Owner auszutauschen.

## Scope / Nicht-Ziele
Nur scripts/core/singleplayer_space_travel_state.gd und Fleet, falls erforderlich, plus diese eigene Task/QA. Kein Root-, Flight-, Adapter-, Supply-, Campaign- oder Commandrouteredit. Bestehender Tacticalguard und strategische Legacyreplays bleiben erhalten. `_set_travel_pose` samt strategischem Invariantassert bleibt unveraendert.

Bei local-Frame werden alte Reiseaktionen nach vorhandenen Trust-/Replaychecks und vor dem ersten Statewrite abgewiesen. Einzige neue Durchlassbedingung: ausdruecklich vertrauenswuerdiges finish_approach, bestehende Phase approach und Flightmode inactive. Dieser vorhandene Command schreibt nur Reisephase/Receipt, keine Pose. Keine neue UIauthority und keine LocalstartQuantum-/beginApproachfreigabe.

Prepared enter_orbit darf SourceLocal nur verwenden, wenn Frame local, mode inactive und tatsächliche Flightarea gleich SourceArea und kanonischer Target-Bodylayout-ID sind. Flightobjektidentitaet, CraftID, Revision, Frame, Area und Mode werden im Kandidaten gebunden und bei Validate erneut gelesen. Der private Publicationtail liest Flight danach nicht erneut: Root darf nach gemeinsamer Revalidierung zuerst seinen Activitycommit ausfuehren und danach den stillen Travelpatch publizieren. SourceArea leer bleibt der strategische Legacyfall; prepared advance fuer Warpabschluss bleibt ausschliesslich strategisch. Kein vorbereiteter warp_departure- oder PaidSurfaceanschluss.

## Quellen / Arbeitsbasis
0024b80a8 im isolierten gemeinsamen Integrationsworktree; Pflichtdocs, orbital_approach_contract, prepared_space_area_travel_contract und abgestimmter SourceActivityvertrag. SourceFlight besitzt mode inactive und validate_space_activity_transition/commit_space_activity_transition; Import von f967bb8e7 wird durch Root vorgenommen. Bis dahin nur echte bisherige local travel/tactical-Guardchecks, kein Fakeinactive als Produktbeweis.

## Akzeptanz / kleine lokale Pruefung
8-12 kleine Checks mit echtem Flight: Local travel/tactical lehnen alte Aktionen ohne Travel-/Receipt-/Posemutation ab, strategischer Legacyreplay bleibt; danach nur bei vorhandenem importiertem ActivityAPI echte inactive/finish/reactivation-Checks. Candidateflightstaleness und stiller Tail nach echter Flightaktivierung pruefen. Einzelcompile, keine GPU-/Native-/Gefechts-/alte Matrix, kein Commit/Push.

## Risiken / offen
Root besitzt spaeter echten freien Saum, Registry und Activity-/Travel-Gruppencommit. Dieser Slice schaltet den produktiven Localwriteweg nur zu und bereitet den reinen Reaktivierungspatch vor. Keine generelle Reise-/Warp-/Surfacefreigabe. ActivityAPI muss tatsaechlich integriert sein, bevor positive Modusbelege gelten.

## Umgesetzt / aktueller kleiner Beleg
SourceActivity f967bb8e7 wurde durch Root als e8d108aa2 integriert. Positive Nachweise laufen jetzt gegen diese echte API, nicht gegen gefaelschte Modusfelder. owner_check.gd: 11/0, runtime_reactivation_wired=false. Echter Localtravel-Guard ueber alle alten Reiseaktionen ohne State-/Pose-/Receiptwrite; Tacticalguard und strategischer Replay bleiben erhalten. Echte tactical->inactive Activity erhaelt Area/Pose, untrusted finish wird verweigert, trusted finish schreibt nur Phase. Prepared inaktiver Localreturn ist mutationsfrei; echter Activityreactivation-Commit macht public Travelcommit stale, waehrend zuvor validierter privater Travelpublicationtail danach ohne erneutes Flightlesen erfolgreich bleibt. Strategischer vorbereiteter Warpabschluss weiterhin posefrei.

Nur scripts/core/singleplayer_space_travel_state.gd wurde geaendert; keine Fleet-/Root-/Flight-/Adapter-/Supply-/Campaignproduktdatei. Einzelcompile Exit0 und Diffpruefung sauber. QA output/native_glut_maps/local_travel_lifecycle_20261111. Kein privates Godotprofil gesetzt; Inmemoryownerprobe ohne Save-/Restoreaufruf, kein Profilguard behauptet. Kein produktiver Rootreactivation-/Gate-/Registrybeweis, kein Nativeflug/Gefecht, keine grosse Matrix und kein Commit/Push.
