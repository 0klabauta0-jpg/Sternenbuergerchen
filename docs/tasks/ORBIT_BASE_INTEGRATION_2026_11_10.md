# Gemeinsame Mainintegration: Orbit, Basiswelt und UI

## Ziel / Ursache

Aktuelle Nutzerfreigabe: Erst nach Abschluss des anderen Chats
`Einzelspieler: Basis, Orte und UI — Umsetzungsplan For agen…`
(`01a1c1d2-5f36-72d0-8c82-570dd6bd95d2`) beide fertigen Arbeitsstaende
zusammenfuehren, gemeinsam pruefen, Main committen/pushen und daraus eine
einzige neue EXE erstellen. Keine vorgezogene Einzel-EXE.

## Ausgang / Umfang / Nicht-Ziele

Integrationsgate10.11.2026 erfuellt: anderer Chat als completed beobachtet,
fertiger Main43b1f153b14d59e4299e94fe0bb4d26eb48e5e05. Eigener fertiger
Stand0f2425aa7 (Produkt03807239a). Zusammenfuehrung im separaten Branch
`task/orbit-base-integration-20261110`; die nachfolgenden alten Zwischenstands-
Hinweise bleiben Herkunft, nicht aktueller Abschlussstatus.

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
- Deutsche Verlustauswertung behaelt konkrete Schiffsfolge und Reparatur-/
  Ersatzdauer sichtbar; die Uebersetzung darf diese bisherigen Informationen
  nicht durch einen allgemeinen Verweis auf den Originalbericht ersetzen.

## Betroffene Dateien / lokale Pruefung

Gepruefte Mergekonflikte voraussichtlich in MetaLayerFlow, Runtimeadapter,
SimulationRoot, HomebaseScreen/Operations/ExplorableHomebase und Contracts.
Gezielte Tests fuer Personalwelt/World-UI/Pilot-Ground-Handoff sowie Orbit-
Domain/Einstieg/Flow/Sicherheit; echter Kampagnen-Zweiausflug mit Fortsetzen,
naechster Sortie und freier Skirmish. Main-Fastforward aus geprueftem
Integrationsbranch, normaler Push mit exaktem Remote-HEAD-Beleg. Danach Export
aus getrackt sauberem identischem Main und Start-/Ablaufprobe der echten EXE
mit privatem APPDATA; unveraenderte laufende Builds/persoenliche Profile.

## Rein lesende Vorpruefung der fertigen Zwischencommits

Eigener Stand03807239a gegen Personalwelt c9d84f58d und Verlustfix aec4e3f34:
Die drei ersten Naehte oben sind im Code bestaetigt. Keine fremde WIP wurde
geaendert oder vor Abschluss des anderen Chats integriert. aec behebt den
vorherigen endlosen Boardingversuch bei toter Besatzung; diesen ueberholten
Befund nicht erneut implementieren.

Kombinierter Pruefplan:
- Pilot zugewiesen, aber draussen: bereits Mondabflug verweigert; Fuel,
  Auftrag, Missions-/Reisephase bleiben unveraendert.
- Reale `base_board`-Commands und tatsaechliche Ankunft fuer beide Personen;
  naechste Sortie, alternativer Pilot und beide Checkpoint-Neuladungen.
- Pilot am Boden: Rueckflug gesperrt, Naehe allein reicht nicht; erst echter
  Embark-Effekt erlaubt den Versorgungs-Rueckflugbutton.
- Padpreview waehrend laufender Basisbewegung und wiederholter Ansichtswechsel:
  keine Nullmodellfehler, kein Stoppen/Leeren der gemeinsamen Simulation.
- Echte Orbit-Hinreise plus terminaler Personalausfall: Debrief und beide
  Retrycallbacks erhalten. Zusaetzlich beschaedigtes Schiff pruefen: der alte
  AirAsset-Recoveryhelper darf keinen physischen Ort `homebase` vortaeuschen,
  waehrend der Reiseowner `surface` ist; kein neuer Checkpoint durch Serviceticks.

Vorhandene Kampagnen-/Skirmish-Loops aus beiden Staenden zusammenfuehren.
Skirmish braucht keine kuenstliche BasePersonnelRuntime; diese ist derzeit nur
an die Kampagne gebunden. Onboarding `get_operations_snapshot(false)` erhalten,
damit der gemeinsame Snapshotpfad nicht rekursiv wird. Nach dem endgueltigen
Abschluss alle Aussagen gegen dessen tatsaechlichen Commit erneut pruefen.

## Risiken / offene Punkte

Integrationsgate und gemeinsame Produktpruefung abgeschlossen. Kampagne152/0
(beide Continue), Skirmish105/0, Verlustfaelle159/0 und fokussierte Gates.
Unabhaengige Reviews ohne Restbefund; QA/source manifest unter
`docs/qa/orbit_base_combined_20261110/`. TASK503 bleibt als identischer
Baselinebefund ausgewiesen. Der fruehere Rueckflugtest mit isoliertem Panel
wurde durch die staerkere Probe des echten Flow-Panels ersetzt; kein
ungepruefter Service-/Ownerfix. Beauftragter Git-/Exportabschluss folgt aus
diesem geprueften Stand, mit separatem Beleg beim Paket. Native Gestaltung
bleibt von technischen Headless-Belegen getrennt.
