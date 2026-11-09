# Kampagnenstart und Skirmish — Entwurf vom 09.11.2026

Status: Konkreter Entwurf am 09.11.2026 vom Nutzer mit „Ja, so umsetzen“ freigegeben, implementiert und lokal in Main integriert. Frischer Main-Lauf78/0, Skirmish60/0; native Bedienung/Lernerfolg noch offen. Umsetzung siehe `docs/superpowers/plans/2026-11-09-campaign-onboarding.md`, Nachweise in `docs/qa/campaign_intro_20261109/README.md`.

## Ziel und Ursache

Der bisherige Einzelspieler-Einstieg fuehlt sich wie Skirmish an und bleibt als solcher erhalten. Ein eigener Kampagneneinstieg soll mit zwei NPCs und einer kleinen Basis die Bedienung anhand echter, aufeinander aufbauender Handlungen vermitteln.

Basis ist Main `6bf468a4c1452d8fba661294bf28a294eca3f5cc`. Aktuell existieren drei Orte, aber nur ein Bergungsauftrag. Der bisherige Bootstrap ergaenzt mindestens zwei Einsatzmitglieder plus Pilot und startet standardmaessig mit drei Einsatzmitgliedern plus Pilot. Kampagnenstart darf diese automatische Auffuellung nicht erben.

## Ansatz

Eine eigene Kampagnen-Startkonfiguration und ein getrennter Kampagnen-Spielstand verwenden dieselben bestehenden Operations-, Transport-, Missions- und Ortsdienste. Keine duplizierte Missionssimulation. Eine blosse Umbenennung des vorhandenen Einzelspieler-Buttons reicht fuer getrennte Teams und Fortschritt nicht aus; ein zweiter vollstaendiger Spielmodus mit eigener Transportlogik wuerde die vorhandene Architektur verdoppeln.

## Menue und Besitz

- **Kampagne:** eigener Einstieg mit `Neue Kampagne` und bei vorhandenem Stand `Fortsetzen`. Neustart ersetzt einen existierenden Kampagnenstand nur nach ausdruecklicher Bestaetigung.
- **Skirmish:** bisheriger freier Einzelspielerablauf mit dem im Hauptmenue bearbeiteten Team. Teameditor und Teambibliothek werden sichtbar diesem Modus zugeordnet.
- **Multiplayer:** bestehender Host-/Join-Einstieg bleibt erhalten. Kampagnenroster und Tutorial werden hier nicht automatisch eingespielt.
- Eigene IDs und Speicherpfade fuer Kampagnenroster, Ressourcen und Fortschritt. Skirmish-Profil bleibt erhalten; keine Kampagnenbelohnung oder Roster-Reparatur schreibt in dieses Profil.

## Startausstattung — konkrete Entwurfsentscheidung

Genau **zwei NPCs insgesamt**: ein Pilot und ein einsatzfaehiger Fireteam-Leader. Der einzelne Leader fuehrt den ersten ruhigen Ausseneinsatz aus; kein zusaetzlicher versteckter NPC. Commander bleibt die Spielerrolle. Die Kampagnenkonfiguration muss einen Einpersonen-Trupp ausdruecklich erlauben und den alten Roster-Floor umgehen, ohne Skirmish-Regeln zu aendern.

Kleine Startbasis mit den fuer den Loop notwendigen Personal-/Ausrues­tungsfunktionen und einem nutzbaren Schiff/Pad. Vorhandene Basisbausteine wiederverwenden; keine neue Art-Pipeline. Anfangsausstattung und Treibstoff reichen fuer beide Einfuehrungsrundfluege. Konkrete Startwerte bleiben datenbasiert und werden auf Erreichbarkeit geprueft.

## Drei bestaetigte Tutorial-Etappen

| Etappe | Spielerhandlung | Bestaetigter Abschluss und Folge |
| --- | --- | --- |
| 1 — Basis vorbereiten | Basis orientieren, die zwei NPCs kennenlernen, Leader/Trupp und Ausruestung pruefen, Pilot und Boarding vorbereiten; Smart Mobile und Zielwahl kennenlernen. | Reale Bereitschaft fuer den Satellitenflug ist hergestellt. Erst dann wird Etappe 2 aktiv. Nur Hinweise wegklicken reicht nicht. |
| 2 — Satellit bergen | Auftrag annehmen, Satellitenort waehlen, abfliegen, landen, Trupp absetzen, Bewegungsziel und GO benutzen, Satellit mit Use sichern, zum Schiff zurueckkehren. | Bestehender echter Missionsabschluss und Rueckkehr an die Basis. Belohnung genau einmal; dann Auftrag zum Versorgen freischalten. |
| 3 — Versorgung sichern | Zum Handelsposten fliegen, Haendler erreichen und Use ausfuehren, einen passenden Gegenstand kaufen, tanken, zum Schiff und zur Basis zurueckkehren. | Reale Kauf-/Tankbelege und abgeschlossene Heimkehr. Einfuehrung abgeschlossen; vorhandene Orte bleiben frei besuchbar. Weitere Kapitel sind noch nicht enthalten. |

Etappe 1 ist eine Basislektion, kein fingierter Ausseneinsatz. Etappen 2 und 3 verwenden ihre unterschiedlichen Ortskarten. Vorgezogene Aktionen duerfen die Folge nicht unbeabsichtigt abschliessen; Wiederholung oder erneute Ergebnisanzeige erzeugt keine zweite Belohnung. Bei Fehler/Abbruch bleibt eine klare wiederholbare Aufgabe sichtbar.

## Tutorial und Hilfen

- Kleine dauerhafte Anzeige: aktuelle Etappe, naechster konkreter Schritt, nachvollziehbarer Sperrgrund. Fortschritt folgt bestaetigtem Runtime-State, nicht dem Oeffnen von Panels oder Popup-Klicks.
- Kurze, schliessbare Ersthinweise an den relevanten Stellen: Trupp/Pilot, Ausruestung/Boarding, Ziel/Abflug, Landung/Absetzen, Bewegung/GO, Use, Handel/Tanken und Rueckkehr.
- Hilfe jederzeit erneut aufrufbar; Tutorials ausblenden veraendert keinen Gameplay-Fortschritt. Keine automatische Pause und keine neue Pausemechanik im Echtzeiteinsatz.
- Bestehende Kontext-Hilfe und Katalog erweitern: kompakte Hover-/Fokushilfe, Details nach bestehendem Vertrag; auch ueber sichtbare Hilfe erreichbar. Kein essentielles Wissen ausschliesslich per Hover.
- Popups verdecken weder den benoetigten Button noch aktive Missionsbefehle. Kein Vollbild-Handbuch vor dem ersten Spielschritt.

## Runtime, Speichern und Karten

`SimulationRoot` und die vorgesehenen Domain-Owner besitzen Fortschritt und Ressourcen. Adapter verbindet bestaetigte Transport-/Missionsereignisse; UI liest Snapshots und sendet Commands. Tutorial-Praesentation besitzt nur Anzeige-/Gelesen-Zustand.

Kampagnenstand speichert Roster, Ausstattung, Ressourcen, Fortschritt und Reward-/Kaufbelege an sicheren Basis-Meilensteinen. `Fortsetzen` stellt einen konsistenten Basisstand her. Vollstaendige Wiederaufnahme mitten im laufenden Gefecht ist kein Bestandteil dieser Einfuehrung; ein unterbrochener Ausflug faellt auf den letzten Basis-Meilenstein zurueck, ohne Skirmish-Daten anzufassen. Dieser Umfang muss im Menue klar erkennbar sein.

Startmodus, Ort, Karte und Szenario bleiben getrennte IDs. Ortsdaten bestimmen die passende Karte; Auftragsdaten bestimmen Ziele und Voraussetzungen. Multiplayer benutzt weiterhin den autoritativen Host-/Lobby-Handoff fuer Karte und Szenario. Keine globale Standardkarte und kein Kampagnen-Menueflag darf einen spaeteren MP-Ort ueberschreiben. Neue Multiplayer-Spielregeln oder Kampagnen-Coop sind nicht Teil dieses Tasks.

## Relevante Dokumente und betroffene Pfade

`docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/dev/contextual_help_popup_ux_contract.md`, `docs/dev/player_roster_save_contract.md` sowie die bestehenden Einzelspieler-Orts-/Auftrags-/Versorgungsvertraege.

Voraussichtlich betroffen: `scripts/ui/main_menu_screen.gd`, zugehoerige Menueszene, `scripts/meta/meta_layer_flow.gd`, `singleplayer_runtime_adapter.gd`, `player_roster_store.gd`, `scripts/core/singleplayer_campaign_state.gd`, Kampagnen-Start-/Speichervertrag, `data/singleplayer/*`, `data/contextual_help_catalog.json`, Operations-/Missionshilfen, gezielte Tests und Statusdoku.

## Akzeptanz und lokale Pruefung

1. Menue bietet Kampagne und Skirmish getrennt; neues Kampagnenprofil hat genau zwei NPCs, funktionierenden Pilot und einen einsatzfaehigen Leader.
2. Skirmish-Teamdateien bleiben bei Kampagnenstart, Fortschritt, Neustart und Fortsetzen unveraendert; MP-Handoff bleibt frei von Kampagnenkonfiguration.
3. Echter Lauf fuehrt in Reihenfolge durch alle drei Etappen, Satellitenkarte und Handelskarte sowie zweimalige Heimkehr. Kein kuenstliches Setzen von Sieg oder Tutorial-Fortschritt.
4. Sperren, Abbruch, Wiederholung, doppelte Commands/Ergebnisse und fehlende/veraltete Speicherdateien werden gezielt geprueft; kein doppelter Reward oder Softlock.
5. Fortsetzen nach jedem Basis-Meilenstein erhaelt Identitaeten, Ausstattung, Ressourcen und genau den erlaubten Fortschritt.
6. Kontext-Hilfekatalog bleibt schema-konform. Technische Headless-Pruefungen belegen Ablauf und Zustand; Verstaendlichkeit, Gestaltung und native Bedienung bleiben vom Nutzer zu testen.

Alle Agententests im Hintergrund, ohne sichtbare Fenster oder Fokuswechsel, mit niedriger Prioritaet. Kein Push. Die bereits erstellte Main-EXE `2026-11-09-main-6bf468a4c` enthaelt diesen Entwurf noch nicht.

## Risiken und Nicht-Ziele

Einpersonen-Trupp und bestehende Bootstrap-Reparaturen benoetigen gezielte Regressionen. Session-State ist bisher noch kein vollstaendiger Kampagnen-Save. Hilfetexte allein beweisen keinen gelungenen Einstieg. Keine weiteren Missionen/Kapitel, keine MP-Kampagne, kein Umbau der bestehenden Combat-/Transportarchitektur und kein allgemeiner Performance- oder Grafikauftrag.
