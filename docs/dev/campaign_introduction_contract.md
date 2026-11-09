# Kampagneneinfuehrung und Modusgrenze

Freigegebener Entwurf: `docs/tasks/CAMPAIGN_START_2026_11_09_DESIGN.md`.

## Einstieg und Team

Das Hauptmenue trennt **Kampagne**, **Skirmish** und **Multiplayer**. Der Teameditor und die Teambibliothek bearbeiten das bestehende Skirmish-Profil `local_player`. Kampagne verwendet dieses Profil weder als Startroster noch als Speicherziel fuer Missionsergebnisse.

`game_start_contract.gd` transportiert ausschliesslich den einmaligen Startwunsch `mode`/`action` bis zum Flow. Ohne Wunsch bleibt der direkte Szenenstart kompatibel zu Skirmish. Multiplayer und Editor entfernen den Wunsch; Karten-/Szenario-Handoffs bleiben ihre bestehenden autoritativen Pfade.

Eine neue Kampagne besitzt genau zwei NPCs: `campaign_leader` als einsatzfaehigen Leader und `campaign_pilot` als getrennten Dropship-Piloten. Ein einziger Leader darf einen realen Fireteam-Einsatz ausfuehren. Automatische Alt-Bootstrap-Auffuellung darf kein weiteres Personal erzeugen. Profile kommen beim Missions-Handoff aus dem Kampagnenroster; die umgangene FOB-Anzeige ist keine Profilquelle.

## Orte und Reihenfolge

| Etappe | Reale Voraussetzung | Freischaltung |
| --- | --- | --- |
| Basis vorbereiten | Satellitenauftrag angenommen, Satellitenort ausgewaehlt, Pilot zugewiesen, Leader als Payload fertig geboardet | Satellitenflug |
| Satellit bergen | Bestehende Szenariogates `secure_satellite` und `return_to_ship`, bestaetigter Auftragserfolg, reale Heimkehr | Handelsort |
| Versorgung sichern | Echter Handelsflug, Haendler-Use, erfolgreicher Kauf, erfolgreiche Betankung und reale Heimkehr | Einfuehrung abgeschlossen, vorhandene Orte frei besuchbar |

Ein Popup schliessen, ein Panel oeffnen oder einen Ortsnamen waehlen ist kein Missionsabschluss. Fehlschlag bleibt wiederholbar ueber `Erneut annehmen`; vergangene Ergebnis-/Command-Belege duerfen weder Wiederholung blockieren noch erneut Fuel, Waren oder Belohnungen erzeugen.

Basisdarstellung verwendet `maps/campaign_intro_base.json`: nach Nutzerkorrektur wieder die groessere36x28-Heimatbasis mit beiden vorhandenen moeblierten Cutaway-Gebaeuden und beiden stabilen Pad-Flaechen. Der Startumfang bleibt klein (zwei NPCs und ein reales Schiff); die Karte wird deshalb nicht verkleinert. Skirmish behaelt dieselbe grosse Basisgrundlage. Satelliten- und Handelsort laden weiterhin ihre eigenen Karten und Szenarien. Ort, Auftrag, Karte, Szenario und Startmodus sind getrennte Begriffe.

Die vereinfachte Behandlung des Handelspostens ist keine Gestaltungsvorgabe fuer die Heimatbasis. Die erhaltenen `structures_pass04`-GLBs bleiben unveraendert; kahle Ersatzwaende werden dort nicht an ihrer Stelle aufgebaut. Vorlage und Nachweis: `docs/tasks/BASE_ORIGINAL_ROOMS_2026_11_09.md`.

## Autoritaet und Hilfe

`campaign_onboarding_state.gd` ist der an `SimulationRoot` gebundene Fortschrittsowner. Nur der Runtime-Adapter liefert vertrauenswuerdige Evidenz aus Bereitschaft, echten Missions-/Transportdaten und bestaetigten Versorgungskommandos. UI-Payloads sind keine Evidenz. `campaign_tutorial_presenter.gd` liest Snapshots; dessen Ausblenden-, Gelesen- und Popup-Zustand ist Praesentation.

Kleine aktuelle Anleitung, schliessbare Ersthinweise, wieder aufrufbare Hilfe und Hover-/Fokushilfen verwenden den bestehenden Kontext-Hilfevertrag und Katalog. Hilfe-Aus schaltet keine Hover-Popups heimlich wieder ein. Echtzeit bleibt unveraendert, keine Tutorial-Pause.

## Checkpoint

Nur ein konsistenter Stand an der Heimatbasis wird in `user://campaigns/introduction/checkpoint_v1.json` geschrieben. Roster, Fireteam-/Mitgliederausruestung, Pilot, Craft, Ressourcen, Auftragsstatus, Fortschritt und Belege werden zusammen validiert und ueber eine temporaere Datei ersetzt. Kein Speichern waehrend Mission oder Transport. `Fortsetzen` stellt den letzten Basis-Meilenstein her; abgebrochene Ausfluege werden dadurch auf diesen Stand zurueckgesetzt. Keine Wiederaufnahme mitten im Gefecht versprochen.

Ungueltige/veraltete Staende werden vor Mutation abgelehnt. `Neue Kampagne` ersetzt einen vorhandenen Stand nur nach Menuebestaetigung. Save-/Ladefehler duerfen keinen Skirmish-Fallback oder stillen Kampagnenneustart ausloesen.

## Pruefung

Domainpruefungen decken Reihenfolge, unzulaessige Restore-Fakten, Wiederholung, Save-Roundtrip und Belegkonsistenz ab. Menue- und Flow-Gates pruefen getrennte Einstiege, genau zwei NPCs, den echten Profil-Handoff und Ortsgrenzen. `campaign_intro_loop_smoke.gd` verwendet denselben realen Flug-/Bewegungs-/Use-Treiber wie der bisherige Einzelspieler-Smoke, mit einem Leader und echten Checkpoint-Neuladungen nach beiden Ausfluegen. Native Bedienbarkeit und Lernerfolg bleiben getrennte Nutzerabnahme.
