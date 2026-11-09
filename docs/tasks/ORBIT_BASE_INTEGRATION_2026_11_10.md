# Gemeinsame Mainintegration: Orbit, Basiswelt und UI

## Ziel / Ursache

Aktuelle Nutzerfreigabe: Erst nach Abschluss des anderen Chats
`Einzelspieler: Basis, Orte und UI — Umsetzungsplan For agen…`
(`01a1c1d2-5f36-72d0-8c82-570dd6bd95d2`) beide fertigen Arbeitsstaende
zusammenfuehren, gemeinsam pruefen, Main committen/pushen und daraus eine
einzige neue EXE erstellen. Keine vorgezogene Einzel-EXE.

## Ausgang / Umfang / Nicht-Ziele

Orbitprodukt7011ce4b2 plus folgende dokumentierte Nutzerergaenzungen;
anderer Main-Zwischenstand2302ac85a (Originalraeume) und dessen noch aktive
Personalweltarbeit. Nur fertige Commits integrieren; fremde WIP erhalten.
Kein Force-Push, keine Raumkampfmechanik, keine generelle Performanceabnahme.

## Relevante Vertraege

Projektpflichtdokumente; `orbit_quantum_travel_contract.md`, aktueller
`campaign_introduction_contract.md`, `homebase_map_services_contract.md`,
Personalwelt-/Pilotensitzvertrag des abgeschlossenen anderen Tasks;
`CHARACTER_DETAIL_IDENTITY_2026_11_10.md` und `UI_CLARITY_2026_11_09.md`.

## Akzeptanz und vorlaeufige Integrationsnaehte

Diese Befunde stammen aus laufendem anderen WIP und muessen gegen dessen
fertigen Stand erneut geprueft werden; keine blinde Uebernahme:

- Reiseowner und BasePersonnelRuntime behalten ihre SimulationRoot-Routen;
  Personalbewegung darf bei ausgeblendeter Ansicht/Padvorschau nicht anhalten.
- Die zusaetzliche Padvorschau darf auf `_model=null` bei Personalowner nicht
  zugreifen und dessen autoritative Queues/Physik nicht stoppen oder leeren.
- Echter Abflug in den Mondorbit prueft den physisch besetzten Pilotenplatz;
  ein Guard nur am alten `validate_departure`-Pfad reicht nicht.
- Personalwelt erkennt Orbit/Quantum nicht als zuhause, auch wenn noch keine
  Mission oder Transferqueue besteht. Heimkehr/Checkpoint erst nach Landung.
- Beide echten NPCs, alternativer Pilot, temporaerer Missionspayload,
  Rueckflug/Embark-Belege, Ergebnislatches und naechster Ausflug bleiben korrekt.
- Orbit-Anflug bindet erst nach Zielwahl die richtige Karte/Szenario; Abbruch,
  Fuel-/Ergebnisreplay und echter Handelsrueckflug bleiben erhalten.
- Kleine Portrait-/Rangkarten bleiben gestalterisch erhalten; grosse
  Detailkarte und reale Pad-/Weltraumvorschau werden im Verbund geprueft.

## Betroffene Dateien / lokale Pruefung

Gepruefte Mergekonflikte voraussichtlich in MetaLayerFlow, Runtimeadapter,
SimulationRoot, HomebaseScreen/Operations/ExplorableHomebase und Contracts.
Gezielte Tests fuer Personalwelt/World-UI/Pilot-Ground-Handoff sowie Orbit-
Domain/Einstieg/Flow/Sicherheit; echter Kampagnen-Zweiausflug mit Fortsetzen,
naechster Sortie und freier Skirmish. Main-Fastforward aus geprueftem
Integrationsbranch, normaler Push mit exaktem Remote-HEAD-Beleg. Danach Export
aus getrackt sauberem identischem Main und Start-/Ablaufprobe der echten EXE
mit privatem APPDATA; unveraenderte laufende Builds/persoenliche Profile.

## Risiken / offene Punkte

Abschluss des anderen Chats steht noch aus. Keine eigene oder andere EXE
wird vor diesem Gate erstellt. Abweichende UI-/Geometrievorstellungen bleiben
von technischen Headless-Belegen getrennt; native Gestaltung nicht behaupten.
