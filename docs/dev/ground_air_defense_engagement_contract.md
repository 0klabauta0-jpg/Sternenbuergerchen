# Bodengestuetzte Flugabwehr gegen anfliegende Schiffe (Contract)

Stand 15.11.2026. Nutzerentscheidungen vom 14.11. sind mit **[N]** markiert. Alles andere ist Vorschlag
des Grafik-Strangs und noch nicht vom Nutzer bestaetigt.

## Zweck
Die Fahrzeuge "Hagel" (Flak-Lkw) und "Donnerkeil" (Raketen-Lkw) sollen im Spiel etwas tun: Sie erfassen ein
Schiff im Landeanflug, schiessen darauf, und der Pilot entscheidet mit seinem Koennen, wie viel das Schiff
abbekommt. Zuerst als Gegner **[N]**.

## Was es schon gibt und hier weiterverwendet wird
- Warnung vor Schaden, Statusmodell des Luftfahrzeugs: `docs/dev/air_asset_threat_damage_contract.md`,
  `scripts/combat/air_asset_threat_resolver.gd` (rechnet ein Risiko ohne Wuerfel, hat keinen Aufrufer im Spiel).
- Schild und Rumpf eines Schiffs: `scripts/tactical/space_component_systems.gd` (`apply_hit`: erst Schild, dann
  Rumpf), Bauteile aus `data/space/ship_components.json`.
- Pilotenkoennen: `dropship_piloting` der Figur (0..1), wie bei der Landegenauigkeit.
- Gesaeter Zufall: gleiche Bauart wie `scripts/mission/dropship_lz_accuracy_contract.gd`.
- Panzerbrechende Infanteriewaffen: `rocket_launcher` und `rail_gun` in `scripts/core/weapon_data.gd`.

## Stand der Umsetzung
| Teil | Stand |
| --- | --- |
| Werte der beiden Fahrzeuge | `data/combat/air_defense_units.json` |
| Regelkern Anflug gegen Flugabwehr, gewuerfelt | `scripts/combat/air_defense_engagement.gd`, geprueft durch `scripts/tests/air_defense_engagement_verifier.gd` |
| Anschluss an den echten Landeanflug: Fahrzeuge aus den Map-Props, Salven entlang des Anflugwegs, Schaden am Schiff, Abbruch oder Landung | `scripts/mission/air_defense_approach_plan.gd`, ein Aufruf in `_try_start_drop_sequence`; geprueft durch `air_defense_approach_plan_verifier` und `air_defense_approach_landing_verifier`. Task `docs/tasks/FLUGABWEHR_ANSCHLUSS_2026_11_14.md` |
| Schaden am Schiff im Spiel | `AirAssetStatus`-Integritaet je Schiff (0..100 = Rumpfanteil) ueber `air_asset_status_update` in `SimulationRoot` |
| Reparatur der Integritaet | Servicepad-Reparatur (`_repair_ground_ship_at_service`) setzt auch den `AirAssetStatus` auf 100 / intakt; gleicher Preis, gleiche Bedingungen. Task `docs/tasks/FLUGABWEHR_ANFLUGSTIL_REPARATUR_2026_11_15.md` |
| Integritaet ueber das Missionsende | **nicht gespeichert**; Befund mit Belegen in der Task-Datei vom 15.11. |
| Anflugstil je Schiff (statt Abfrage "abdrehen?") | `approach_style` in Schiffskarte und Planungszustand, Befehl `set_dropship_approach_style`, Dreier-Zeile "Vorsichtig / Normal / Aggressiv" in der Schiffskarte; Regeln unten |
| Tiefflug mit Preis | Profil `low` bei "vorsichtig", Streukreis der Kampagnen-Feldlandung x 1,5 |
| Sichtlinie gegen Gelaende im Anflug | **offen**; heute immer frei |
| Absturz im Anflug | **offen**; Zerstoerung wird zum erzwungenen Abbruch mit Rumpf 1 % |
| Start und Bergung (Abflug) unter Beschuss | **offen** |
| Fahrzeug als Einheit am Boden (Besatzung, Schaden, Herausschiessen, Uebernehmen) | **offen**, Regeln unten |
| Panzerfaust und Schienengewehr im Laden | **offen**, Preisvorschlag unten |
| Transportschiff fuer Fahrzeuge | **offen**, eigenes Modell und eigene Regel |

Der Regelkern besitzt keinen Zustand. Er liefert einen Vorschlag (`runtime_authority = "SimulationRoot"`,
`ui_sets_gameplay_truth = false`); wer ihn aufruft, schreibt das Ergebnis fest.

## Regeln im Anflug (umgesetzt im Regelkern)

### Erfassen
- Ein Fahrzeug sieht ein Schiff per Radar (grosse Reichweite) oder mit den Augen der Besatzung (kurze Reichweite).
- **0-Grad-Horizont [N]:** Radar und Waffe wirken nur auf Ziele auf oder ueber der eigenen Hoehe. Liegt das
  Schiff tiefer als die Lafette, wird es weder erfasst noch beschossen. Die Lafette sitzt eine Hoehenstufe
  ueber dem Boden des Fahrzeugs.
- Gelaende zwischen Fahrzeug und Schiff verdeckt das Schiff (Sichtlinie).
- **Tiefflug [N]:** Anflugprofil `low` haelt eine Hoehenstufe ueber dem Boden unter dem Schiff, `normal` sechs.
  Tiefflug ueber tieferem Gelaende bleibt damit unter dem Horizont einer Stellung auf dem Kamm. Auf gleicher
  Hoehe wie die Stellung schuetzt er nicht. Preis: Landegenauigkeit schlechter (Streukreis x 1,5,
  `approach_profiles.low.lz_radius_factor`), umgesetzt am 15.11.

### Anflugstil je Schiff (umgesetzt am 15.11.)
Vorschlag des Grafik-Strangs, vom Nutzer am 14.11. als Richtung bestaetigt: Abdrehen, Tiefflug, Weiterfliegen.
| Stil | Profil | unter Beschuss | Preis |
| --- | --- | --- | --- |
| Vorsichtig | `low` | abdrehen | Streukreis der Landung x 1,5 |
| Normal (Standard) | `normal` | abdrehen | - |
| Aggressiv | `normal` | weiter anfliegen, Landung trotz Treffern, Meldung "Flugabwehr: N Treffer, Rumpf N %" | Schaden |
- Unbekannter Stil gilt als "normal"; der Befehl `set_dropship_approach_style` lehnt ihn ab.
- Auch bei "aggressiv" dreht der Pilot unter 35 % Rumpf von sich aus ab; Zerstoerung bleibt erzwungener Abbruch
  mit Rumpf 1 %.
- Der Stil wird je Schiff gespeichert wie der Anflugwinkel (Schiffskarte, Planungszustand, Netzbefehl).
- Der "Donnerkeil" braucht Radar. Der "Hagel" kann auch nach Sicht richten.

### Warnung vor Schaden
- Der erste Kontakt ist nur eine Meldung ("Radar erfasst"). Der "Donnerkeil" braucht danach einen Schritt zum
  Aufschalten ("aufgeschaltet"), erst dann startet eine Rakete.
- Nach der ersten Salve, die auf das Schiff geht, steht die Entscheidung: **weiter anfliegen oder abdrehen [N]**.

### Wuerfeln
Der Anflug laeuft in Salven. Jede Salve wird gewuerfelt, gesaet ueber Schiff, Landezone und Pilot.
- **Hagel:** 8 Schuss je Salve, jeder Schuss einzeln. Trefferchance 0,30, ab halber Reichweite fallend bis auf
  die Haelfte, mal (1 - Ausweichen). 7 Schaden je Treffer.
- **Donnerkeil:** eine Rakete, dann drei Salven Nachladen, zwei Raketen an Bord. Trefferchance 0,70, durch
  Ausweichen gemindert. 55 Schaden.
- **Flares [N]:** Hat das Schiff Flares und reagiert der Pilot (Wurf, 0,35 + 0,60 x Koennen), verbraucht er
  eins; es lenkt die Rakete mit 0,75 ab. Cutlass und Buccaneer tragen vorlaeufig je 2.
- Schaden geht erst in den Schild, dann in den Rumpf. Ohne Beschuss laedt der Schild nach.

### Der Pilot [N]
| Koennen | reagiert nach | Ausweichen danach | braucht zum Abdrehen noch |
| --- | --- | --- | --- |
| 0,0 | 3 Salven unter Beschuss | 0,15 | 2 Salven |
| 0,5 | 2 Salven | 0,38 | 1 Salve |
| 1,0 | sofort | 0,60 | keine |

- Vor der Reaktion weicht das Schiff nicht aus.
- Abdrehen beginnt erst, wenn der Pilot reagiert hat, fruehestens nach der ersten Salve.
- Faellt der Rumpf unter 35 %, dreht der Pilot von sich aus ab, auch gegen den Befehl.

### Was dabei herauskommt (je 400 Wuerfe, ein Fahrzeug, Anflug bis auf 4 Felder)
| Schiff | Gegner | Pilot 0,1 weiter | Pilot 0,1 dreht ab | Pilot 0,9 dreht ab |
| --- | --- | --- | --- | --- |
| Cutlass (Schild 48, Rumpf 100) | Hagel | Rumpf im Mittel 46 %, 9 Verluste | 72 %, kein Verlust | 100 % |
| Cutlass | Donnerkeil | 81 % | 81 % | 99 % |
| Buccaneer (Schild 24) | Hagel | 25 %, 62 Verluste | 48 %, 3 Verluste | 100 % |
| Buccaneer | Donnerkeil | 65 % | 65 % | 96 % |

Ein einzelner Treffer zerstoert kein Schiff **[N]**.

## Die Fahrzeuge
| | Hagel | Donnerkeil |
| --- | --- | --- |
| Besatzung | Fahrer (Kabine), Schuetze (offener Stand) | Fahrer, Bediener (beide Kabine) |
| Rumpf | 220 | 180 |
| Schild / Kraftwerk **[N]** | Groesse 1, Guete D (`shield_s1`, `power_s1`) | ebenso |
| Sicht der Besatzung | 14 Felder | 14 Felder |
| Radar | 30 Felder | 60 Felder |
| Waffenreichweite | bis 16 Felder | 6 bis 45 Felder |
| Bodenziele | ja | nein |
| Preis (Gefechtspunkte) | 260 | 320 |

Zum Vergleich: Cutlass 340, Buccaneer 230, Veteran 145 Punkte. Aufruestbar spaeter **[N]**.

## Regeln am Boden (Vorschlag, nicht umgesetzt)
- **Schaden:** Nur panzerbrechende Waffen (`rocket_launcher`, `rail_gun`) schaedigen Schild und Rumpf. Gewehre
  treffen nur ungeschuetzte Besatzung.
- **Herausschiessen [N: ja]:** Der Schuetze des "Hagel" sitzt offen und ist mit Deckung 40 normal treffbar.
  Besatzung in der Kabine trifft nur eine panzerbrechende Waffe (Kabinentreffer statt Rumpftreffer, mit Abzug).
- **Ohne Besatzung:** ohne Schuetze oder Bediener kein Feuer, ohne Fahrer keine Bewegung.
- **Uebernehmen [N: ja]:** Steht ein Fahrzeug ohne lebende Besatzung da, steigt eine eigene Figur vom Nachbarfeld
  als Zeitaktion ein (8 s). Das Fahrzeug wechselt die Seite. Fahren braucht `ground_vehicle_handling`; den
  Schuetzenplatz kann jeder besetzen, ohne Ausbildung mit Abzug.
- **Ziel "Flugabwehr ausschalten":** erfuellt, wenn kein Fahrzeug der Gruppe mehr feuern kann (zerstoert,
  besatzungslos oder uebernommen). Heute zaehlt nur, ob alle Gegner der Gruppe tot sind.
- **Konter im Laden:** Panzerfaust (`rocket_launcher`) 60 Punkte, Schienengewehr (`rail_gun`) 75 Punkte. Beide
  Waffen gibt es, sie stehen nur nicht im Laden.

## Nicht-Ziele
- Keine Flugsimulation. Der Anflug bleibt eine Folge von Salven.
- Kein Fahrzeug in Spielerhand, bevor es ein Transportschiff und Fahrregeln gibt.

## Offene Entscheidungen
- Was ein abgebrochener Anflug kostet (Treibstoff, Zeit). Eine Abfrage "abdrehen?" waehrend des Anflugs gibt es
  nicht; der vorher gewaehlte Anflugstil entscheidet.
- Ob die Integritaet ueber das Missionsende gespeichert wird.
- Flares je Schiffstyp und ob sie Geld kosten.
- Ob ein uebernommenes Fahrzeug gegen feindliche Schiffe eingesetzt werden kann.

## Pruefung
`godot --headless -s scripts/tests/air_defense_engagement_verifier.gd` (37 Pruefpunkte).
`godot --headless --path . -s scripts/tests/air_defense_approach_plan_verifier.gd` (32 Pruefpunkte, GM02-Kartendaten).
`godot --headless --path . -s scripts/tests/air_defense_approach_landing_verifier.gd` (25 Pruefpunkte, echter Controller auf GM02).
`godot --headless --path . -s scripts/tests/map_services_verifier_20261114.gd` (Reparatur am Servicepad, auch `AirAssetStatus`).
