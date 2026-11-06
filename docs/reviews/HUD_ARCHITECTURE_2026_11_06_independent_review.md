# Unabhaengiger Architektur- und Regressionsreview, 06.11.2026

## Urteil und Umfang

**APPROVED scoped.** Keine offenen bestaetigten P1/P2 im unten gepinnten Produktstand. Geprueft: begrenzter HUD-Projektionspass, vorwaertiger Live-DAG, Buttonstyle-Owner, unsichtbare A5-Mitgliedskarten, Door-Runtime-Producer samt reinen Gettern und die beiden kleinen Homebase-/A5-Readout-Aenderungen.

Basis: `task/hud-architecture-20261106`, Main `be1dd404a61317f18307e0eff42a0530f07fa647`. Pflichtdokumente, Haupttask, enge Untertasks und aktuelle Produkt-/Testhunks wurden gelesen; separater lesender Testoracle-Review einbezogen. Keine eigenen Engines, Gameplay-/Save-/Produkt-/Testaenderungen oder Gitmutationen. Nur dieser Review wurde geschrieben. Kein konfiguriertes `.ai-game-studio/project.json`; massgeblich sind die konkreten Repository- und Taskvertraege.

Native normale 1x-Frame-/Bewegungsbelege, finaler Vorher/Nachher-Bildabgleich, Wiederholung der 15 Nachbargates nach den letzten Controllerkorrekturen und Mainintegration bleiben separate Root-Gates. Diese Freigabe bestaetigt keine allgemeine Fluessigkeit, physische Schussbeobachtung, Hostmigration, LAN/WAN-, EXE-, gestalterische oder Releaseabnahme.

## Bestaetigte und geschlossene Befunde

### P2: Hidden-A5-Dispatch verlor die Reveal-Invalidierung

Der versteckte Dispatch konsumierte Gruppensignatur X, ohne den Selected-Kartenbaum von Y auf X aufzubauen. Nur die Reihe sichtbar zu machen oder A5-Meta abzuschalten liess X unveraendert; der normale `false`-Dispatch konnte die nun erforderlichen Karten dauerhaft ueberspringen. Der erste neue Verifier maskierte dies durch `force=true` und einen weiteren `preview_mode`-Wechsel.

`_build_periodic_fireteam_cards_signature()` (`mission_tactical_sandbox_controller.gd:5389`) erfasst jetzt effektive Rowsichtbarkeit und A5-Besitz. Die ergaenzten Handoffs wechseln nur Sichtbarkeit/Besitz, behalten alle Selected-Quelldaten bei, pruefen den echten nicht erzwungenen Aufbau und danach einen ruhigen unveraenderten Dispatch. `hidden_cards_reveal_green/20261106T143125Z-d5e20312`: **77/0**, Exit0, Fehler0, isoliert, Quellen stabil. Derselbe Verifier besteht im finalen Komponentenlauf erneut.

### P2: Reine Getter liessen Startup-Grace-Fortschritt ohne Publisher stehen

Nach Entfernung der Getter-Schreibeffekte konnte der bestehende fruehe Staging-Return Hold/Countdown und den Wechsel zur Hostauthority veralten lassen. Im bereits autoritaetsgeprueften Grace-Zweig publiziert nun der bestehende Runtime-Countdown-/Gatepfad (`mission_combat_loop_driver.gd:1606`), bevor die Combat-Grace unveraendert zurueckkehrt. Clients schreiten dabei nicht lokal fort.

Der korrigierte Verifier wartet mindestens 50 echte Wandzeit-Millisekunden bei 1x; er ersetzt keine Fortschritts-/Ratenassertion. Mit genau dem einen Publisheraufruf entfernt: `door_startup_grace_wallclock_red/20261106T143122Z-8ca8d71f`, **82/3**, exakt Hold, Countdownrate und Authoritytransition rot. Mit wiederhergestelltem Aufruf: `door_startup_grace_wallclock/20261106T143004Z-63731b07`, **85/0**; im finalen Komponentenlauf nochmals **85/0**. Echte lokale ENet-APIs pruefen Client-/Hostcallback-Zweige; der kontrollierte Callbackharness ist kein kompletter Client-Ready-/Hostmigrations- oder physischer Missionsbeleg.

## Architektur und Korrektheit

- `MissionHudReadModel` teilt nur aeusserste synchrone Projektionen eines expliziten Passes. Verschachtelte Producer umgehen den Cache; Dictionary-/Arraywerte werden tief kopiert. Passende End-, Revisions-, Generation- und Engineframebarrieren verwerfen Werte. Ein neuer Pass im selben Frame liest neu; der Helper besitzt keine Simulationreferenz und sendet keine Commands/Effects.
- Der Live-DAG (`Controller:11086`) baut seine fuenf vollstaendigen Sections vorwaerts mit expliziten RAW-Inputs. Leere RAW-Quellen aktivieren keinen historischen Getterfallback. Identische Quelle/Clock/Trace liefern komplette Getterparitaet; Apply startet keinen zweiten DAG. Die bestehende feste Legacy-Empfehlungskontextschuld bleibt als solche dokumentiert und wird nicht als gemessener Combat-State ausgegeben.
- Buttonstyles erhalten pro Control ihre finale Basisdarstellung. Die neun nativen FIRST-/SECOND-Actions bleiben beim vorhandenen nativen Presenter (`Controller:17874`); derselbe synchrone Pfad erreicht ihn weiter. Die 16 anderen Basiskontrollen, Legacy und ROE behalten ihre bestehenden Owners. Der Ressourcen-/Dispatchnachweis ist keine gemessene Millisekundenersparnis.
- Versteckte A5-Mitgliedskarten werden nur beim periodischen Dispatch ausgelassen. Expliziter Refresh, Reveal/Besitzwechsel, Mini-Karten, Ad-hoc und offenes Charakteroverlay behalten aktuelle Profile und Callbacks. Keine pauschale Unsichtbarkeitscache-Regel.
- Der Driver besitzt die Door-Registryprojektion aus bestehenden Bindings, realen Mapmarkern und seinem Interaction-State. Die 85-Prozent-Grenze ist gemeinsam; Walkability/LOS/Hoehe/Cover lesen denselben abgeleiteten Index. Marker-/Registryidentitaet, Revision, Inplace-Markerfingerprint und tatsaechliche Overrides sichern Reconcile und verhindern die eigene Revisionsschleife. Der Fingerprint ist an Door-Bindings begrenzt, kein Mapvollscan. Zugriff auf vorhandenes privates MissionSetup-Mapfeld bleibt die dokumentierte bestehende Integrationsgrenze.
- Vier Drivergetter sowie Controller-Kompatibilitaetsgetter lesen defensiv kopierte Receipts; sie reparieren keinen Registryzustand. `producer_applied` bezeichnet den letzten Producerpass, `producer_index_current` wird nur in der Rueckgabekopie validiert. Objektreaktionen verwenden einen aktuellen angewandten Receipt auch bei lokalem Out-of-range. Remote-Apply reconciliert ohne lokale Commands/Effects. Im regulaeren Clientpfad geschieht dies bei Snapshotpublikation; ein isolierter Clientregistrywechsel ohne weitere Remote-Publikation ist kein hier belegter Lifecyclepfad.
- ActiveOrder erhaelt unbekannte/leere Slots, fokussierte kuenftige Befehle und den n-von-m-Fallback; Profilrest allein erfindet keine Execution. Bewegungsstate wird am echten Executionende geloescht. Homebasefarbe liest bestehende Snapshotfelder und gemeinsame Themefarben; Titel, IDs, Selector-/Startcallbacks und Gates bleiben getrennt von der Darstellung.

## Tatsaechliche Abschlussbelege

`output/hud_architecture_20261106/final_components/20261106T143141Z-89d3e189/report.json` bleibt **10/11**, nicht nachtraeglich 11/11: Der historische Batchverifier forderte noch einen Aufbau der absichtlich versteckten Selected-Karten (**39/1**). Produktquellen wurden danach nicht geaendert. Das Orakel prueft jetzt aktuelle sichtbare Portraitkarten einschliesslich identischem Owner-Movement-State/Statuslabel, erhaltene versteckte Instanzen und unveraenderte Command-/Plan-/GO-/Interleaving-/Detailsgrenzen.

Der fokussierte Ersatzlauf `command_hidden_contract_green/20261106T143429Z-4144e1b4` besteht **43/0**. Abschluss ist somit **zehn gruene Komponenten plus ein separater gruener Batchnachlauf**. Reports melden Exit0, Fehler0, kein Timeout, verifizierte Userdaten-/Outputisolation und stabile Vorher/Nachher-Sourcepins; Rosterbytes, Laenge und mtime bleiben gleich.

| Finaler Komponentenbeleg | Assertions |
| --- | ---: |
| Styles | 605/0 |
| Homebase Flightdeck | 72/0 |
| ReadScope | 34/0 |
| Live-Projektion, volle fuenf-Section-Paritaet | 163/0 |
| Door Authority / Grace | 85/0 |
| ActiveOrder | 46/0 |
| HiddenCards / nicht erzwungener Reveal | 77/0 |
| Native-Style-Owner (Komponentenfixture) | 134/0 |
| TASK1044 | 15/0 |
| Homebase Operations | 62/0 |
| Separater aktueller Commandbatch | 43/0 |

Die aeltere Nachbarmatrix `architecture_neighbors_and_seven_gates/20261106T142141Z-0de386f4` besteht **15/15**, einschliesslich der sieben historischen Gates. Sie liegt vor den letzten Hidden-/Style-/Gracekorrekturen und wird ausdruecklich nicht als deren finaler Nachbarbeleg umetikettiert. Root plant deren Wiederholung nach dem laufenden nativen Vergleich.

Overlays teilen Quellen ueber Junctions. Historische Laufbindung stammt aus den erfassten `source_inputs_before/after` und deren Stabilitaetsgate, nicht aus heutigem Nachhashen eines Overlaypfads. Die folgenden aktuellen Produktpins stimmen mit dem finalen Batchreport ueberein:

| Produktdatei | SHA256 |
| --- | --- |
| `scripts/tests/mission_tactical_sandbox_controller.gd` | `bb68b68d2624258c2d574f9d8f875d16e3898774e9a0647fc60fb81468dfc1e7` |
| `scripts/tests/mission_combat_loop_driver.gd` | `1c7ff89738c05f965c1c191af5ca2ab42763c087f05a83b40df5126e8ecb6ca1` |
| `scripts/tactical/mission_hud_read_model.gd` | `7fc4e05a8c505132a4da7b78f8aa71af68ff0a4faa7272c3731443f856f830ff` |
| `scripts/ui/mission_a5_hud_layout.gd` | `31283d6437d7c04950b53423e1faff1a9f9774e9bad8f685813c02592a708ec2` |
| `scripts/mission/mission_interaction_door_runtime_collision_los.gd` | `2b2592007033d09a5b24ea6b9be06a149f9f534282772a0d686ad3d37cd7f368` |
| `scripts/mission/mission_interaction_object_reaction.gd` | `bc2a144191e93e5df128571389b0ddb01af9d8d914fb30af00a4b5b01681ed25` |
| `scripts/meta/homebase_operations_presenter.gd` | `84959f74a6c5471b7f580bcfc795810a5d72ac514bef5db77414e0c21881c836` |

Eine weitere Produktkorrektur erfordert einen passenden Nachreview/Nachweis. Das aktuelle Codeurteil bleibt von Roots noch laufender nativer Messung und spaeterer Integrationsentscheidung getrennt.
