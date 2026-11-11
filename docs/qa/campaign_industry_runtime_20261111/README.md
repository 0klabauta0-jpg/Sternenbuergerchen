# Industrie: Bergungswerkzeug — begrenzter Runtimezweig

## Ergebnis / Basis / Kosten
Kandidat auf task/native-glut-maps-20261110. Aus dem breiten Workbenchvorschlag
research_industry wurde der tatsächlich vorhandene Werkzeug-/Wrackpfad gewählt:
Werkstattentwicklung + nachweislich gefertigtes Hand-Mining-Tool -> Entwicklung
Bergungswerkzeug160Cr -> Bauplan salvage_tool -> einzelne Herstellung40Cr.
160Cr ist ein Workbenchvorschlag,40Cr erster eigener Balancewert, keine finale
Wirtschaftsbalance. Entwicklung schenkt kein Werkzeug. Bestehende Kaufangebote
bleiben unverändert; hier wird die eigene Herstellung freigeschaltet.

SupplyState bleibt unverändert der Owner. Das neue Rezept verwendet seinen
bestehenden Katalog-Fallback, Lager-/Credits-/Heimat-/Replaypfad. Der vorhandene
Werkstattpresenter erhält genau eine zusätzliche Herstellungsaktion und einen
Bergungstext; das Mining-Werkzeugicon dient als vorhandener Icon-Fallback.
Keine neue Illustration oder neue UI-Gestaltung. Der Sperrtext liest eine
optionale Bezeichnung aus den Knotendaten und benennt korrekt das Mining-Tool;
der Schutztechniktext bleibt semantisch unverändert.

## Tatsächlich ausgeführte kleine Prüfungen
- campaign_industry_slice_check.gd:22Checks,0Fehler. Vier normalisierte echte
  Jobdefinitionen als vertrauenswürdige Fixtures, keine gespielten Missionen.
  Werkstatt-/Herstellungsprerequisite, Kauf genügt nicht, korrekter Sperrtext,
  Heimat-/Kampagnenautorität,160Cr einmal, separater40CrWerkzeugbau, Replay,
  kein Gratisitem, Zuordnung zum bestehenden freighter_wreck_01.required_tool
  sowie ein einzelner JSON-Domain-Roundtrip für den Forschungsbeleg.
- Bestehender enger Schutztechnik-Domaincheck unverändert:24Checks,0Fehler.
- Katalog und Werkstattpresenter Godot4.6.2 --headless --check-only: jeweils
  Exit0, keine Script-/Enginefehler oder Warnungen in den Logs.
- Begrenzter git diff --check für eigene Dateien ohne Befund.

Die ersten beiden Domainläufe scheiterten nur beim Roundtrip: Rohdaten des
outpost_recovery-Rewards enthalten kein blueprint_id-Feld, während der echte
CampaignOwner dieses Feld normalisiert. Die Fixture liest jetzt wie der
Restorevalidator die normalisierten Jobs vom vorhandenen CampaignOwner. Kein
Produktfix oder Abschwächen der Restoreprüfung dafür. Initial- und Diagnoselog
bleiben erhalten. Finale Probe22/0.

## Grenzen / offene Arbeit
Keine Rohstoffverarbeitung, Prospector-/Vulture-Aufträge, neuen Schiffe oder
Komponenten; der große Workbench-Industrievorschlag bleibt dafür offen. Bestehende
Ortsressourcen wurden nicht geändert. Die Probe vergleicht das erforderliche
Werkzeug mit dem gefertigten Item; sie führt keinen echten Abbau-/Bergungsweg aus.
Kein nativer Werkstattklick, Reise-/Missionstest, GPU-/Gefechts-/Benchmarklauf,
keine Save-Matrix oder vollständige Continue-Abnahme. Native Bedienung, reale
Ressourcenbergung und Gesamtbalance folgen der später gebündelten Prüfung.
Keine Mainintegration/EXE und kein Commit/Push durch diesen Teilagenten.

## Quellenfreeze
Exakte Dateien und SHA256 in manifest.json; Sourcefreeze nach finaler kleiner
Probe. Fremde parallele Änderungen und bereits vorhandene untracked Artefakte
gehören nicht zu diesem Teilpaket.

## Read-only Quellenbeleg Werkzeug -> bestehender Usepfad
- inventory_transfer_contract.gd:15 kennt salvage_tool; PersonnelInventoryPanel
  :13 benennt es Bergungswerkzeug, :67/:368 schicken den generischen Transfer
  in unit:<id>:backpack. Kein Waffen-/Toolslot erforderlich.
- SupplyState:327..332 verknüpft Basislager und Fertigungsbestand;
  :350..372 transferiert bekannte Items mit Zugang und Kapazitätsprüfung.
  Kampagnenpersonen starten ohne Rucksackkapazität; ein ausgerüsteter vorhandener
  Rucksack gibt über _change_backpack:400..429 die12Slots frei.
- RuntimeAdapter:_inventory_context:791 erlaubt Basislager und Personenrucksack;
  Feldkontext:813 erlaubt Rucksack sowie nahe geparkte Schiffsfracht.
- LocationResourceRuntime:_candidate:204..214 fragt für den realen lokalen NPC
  Supplypreview ab. accept_progress:217..228 verlangt echte Reichweite und volle
  Holdzeit; Adapter:997..999 akzeptiert nur den registrierten Ressourcenowner.
- Supplypreview:438..447 liest site.required_tool aus dem tatsächlichen
  Personenrucksack und prüft Platz. _collect_resource:448ff übernimmt den endlichen
  Bestand. freighter_wreck_01 verlangt bereits salvage_tool.
Dies belegt die vorhandene Sourceanbindung. Es ersetzt keinen nativen Transfer,
keinen realen6Sekunden-Wrack-Use und keine Reise-/Bergungsabnahme.

Read-only Zweitreview durch tabletop_ap1_review: kein Blocker; keine weiteren
Sourceänderungen oder Testläufe durch diesen Reviewer.
