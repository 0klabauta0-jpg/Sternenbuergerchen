# Original-2D und native Runtime: begrenzter Referenzabgleich

Stand: 06.11.2026. Originale und die unten benannten nativen PNGs wurden
tatsaechlich geoeffnet. Die Runtime gehoert sichtbar zur bestaetigten
UI-Familie; Screenkomposition und Weltinszenierung bleiben deutlich entfernt.
Die zwei kleinen UX-Korrekturen dieser Runde sind keine gestalterische
Gesamtabnahme. Der finale native Nachherbeleg ist geprueft, siehe unten.

## Autoritative Originale und Abgrenzung

Nach `ui_native_design_contract.md` bestimmen die letzten Original-2D-Ziele
und spaetere Nutzeranweisungen die Gestaltung. Native Captures sind Ist-Belege;
Brueckenbilder sind Uebersetzungshilfen. Keines davon ersetzt ein Originalziel.

| Original unter `docs/reports/assets/ui-2026-11-01/` | Zuordnung | SHA-256 |
|---|---|---|
| `menu_heimatbasis.png` | Personal, Team, Transporthierarchie | `2037cc5c58a8cf463040235d332c64c5522242a5a944c928e9040613bb495e92` |
| `menu_fob_loadout.png` | Fokussierte Identitaet, drei Ausruestungsfelder, Boarding | `ff97752096c4af99b2fc97beefd5337e396451c9d3c16d926467d3157b95cc1a` |
| `mockup_a5_mission_zweireihig.png` | Fireteamkarten links, zwei Aktionsreihen, Auftrag, Dropship, Weltkomposition | `fc9edb8b1d28921653ba5b438e7be8da4db3e0b32b8c751e9b18c4ef94918149` |

Ergaenzend wurde `board_charakterkarten.png` als Identitaets-/Kartenreferenz
angesehen. Beispielnamen, Zahlen und Schiffsillustrationen sind keine
Runtimewerte. Spaetere Nutzerkorrekturen haben Vorrang vor woertlicher Kopie:

- Die normale Vorbereitung liegt nun in der Heimatbasis, mit direktem
  Missionsstart und begehbarer Basis; ein erzwungener FOB-Umweg waere falsch.
- Teamparameter liegen auf Nutzerwunsch links unter den Fireteamkarten.
  Ihre Abweichung vom urspruenglichen unteren Teamblock ist beabsichtigt.
- Das Dropship verwendet exakt die aktive Ref03-Cutlass-Identitaet und ihren
  nativen Preview. Eine beliebige illustrierte A5-Schiffsform ersetzt sie nicht.

## Geoeffnete native Vergleichsbilder

Alle aktuellen Bilder liegen unter `output/hud_architecture_20261106/`.
Root bestaetigt fuer die aktuellen Vergleichslaeufe echtes 3440x1440-Vollbild.
Es wurden keine Bilder umgerastert, zugeschnitten oder ersetzt.

| Stand | Pfad relativ zum genannten Outputordner | Aussage |
|---|---|---|
| Vorher | `baseline_profile/20261106T132842Z-c93dc5aa/baseline_captures/02_homebase.png` | Missionsname doppelt; Schiffsbereitschaft gelb |
| Vorher | derselbe Captureordner, `06_go_movement.png` und `07_outpost_overview.png` | Generischer Ausfuehrungsauftrag, Kameramassstab und Weltkomposition |
| Aktueller Zwischenstand | `after_forward_projection/20261106T140743Z-49507f56/forward_captures/02_homebase.png` | `Einsatz` als Feldtitel, Missionsname im Selector; `Bereit` sichtbar Teal |
| Aktueller Zwischenstand | derselbe Captureordner, `06_go_movement.png` | Noch vor dem spaeteren A5-Textpatch; weiterhin `Auftrag: Wird ausgefuehrt` |
| Final nach beiden UX-Slices | `final_native_audited/20261106T144051Z-f2bdfc4c/audited_captures/02_homebase.png` und `06_go_movement.png` | Von Root zusammen mit den Originalen geoeffnet: eindeutiger Titel, Teal-Bereitschaft sowie `Auftrag: Bewegen` und separates laufendes Feedback sichtbar |

SHA-256 der vier Hauptvergleichsbilder in Tabellenreihenfolge:

```text
baseline 02: 1a0ef0ad98b1eff8c148cc2578b37213f19826fa98af2d89d962d188028ff2e4
baseline 06: ec0cf0cd1c1ffb536b96338ffa03f0f6733cf1b42821be7d392eee1d525168be
forward 02:  bea6b7a25996434d6d6f3fb4d4269e5a9d03c2df996430fb7da7f43447400c4c
forward 06:  13c85433ae21d4ff8050c07e11e7ee061eebaba96383a54dabb84f7e937d010e
```

Die zuvor geoeffneten Captures vom 05.11. unter
`output/continue_20261105/final_native_motion/20261105T143914Z-d2deebb0/final_captures/`
und die 1280er Homebaseaufnahme unter
`docs/qa/playtest_20261105/responsive_final/captures/homebase_1280.png`
bleiben historische Zusatzbelege. Sie sind keine neue 3440er oder finale
06.11.-Abnahme.

## Sichtbarer Abstand und tatsaechliche Aenderung

| Bereich | Bereits erkennbar umgesetzt | Noch sichtbarer Abstand |
|---|---|---|
| Personal/Portraets | Koharente grosse illustrierte Gesichter, echte Identitaeten und lesbare Auswahl. Der alte Pixelportraetbefund ist ueberholt. | Originale sind staerker grafisch stilisiert; diese Runde erzeugt keine neuen Gesichter. |
| Heimatbasis/Loadout | Personal, Vierertrupp, Fokusperson mit drei Selektoren und Abflug sind vorhanden. Feldtitel und Bereitschaftsfarbe sind jetzt nativ klarer. | Vier gleichfoermige Arbeitsflaechen, freie Bereiche und wenig atmosphaerische Szenenpraesenz; Originale besitzen eine staerkere Schrittfolge und eine grosse rechte Schiff-/Basisszene. |
| A5-Fireteam/Bedienung | Portraitkarten links, gelbe Auswahl, zwei Aktionsreihen, Auftrag und echte Ref03-Karte folgen der UI-Familie. | Zielblock wiederholt im geoeffneten Zwischenstand noch den Ausfuehrungsstatus. Der begrenzte neue Patch benennt die aktive Order konkret, ohne das Layout umzubauen. |
| Missionswelt | Rostpalette, Felsfamilie, helle Gebaeude mit Tealdach und stabile HUD-Gruppen sind vorhanden. | Vorher und Zwischenstand zeigen viel freie Sandflaeche sowie kleine entfernte Figuren. A5 zeigt ein naeheres, dicht gefuelltes Ensemble, deutlichere Gebaeudekonstruktion und lokal gut lesbare Figuren. Das ist vor allem Kamera-/Szenenkomposition und Hauptform, kein fehlender Rahmen. |

Die **zwei begrenzten Aenderungen** dieser Runde sind:

1. Homebase-Flightdeck: eindeutiger Einsatzfeldtitel plus semantische Farbe
   aus bestehenden Snapshotfeldern und `TacticalUITheme.status_color`.
   Nativ am Zwischenstand sichtbar; fokussiert 72/72 GREEN und bestehender
   Operations-Neighbor durch Root bestaetigt.
2. A5-Readout: konkreter laufender Auftrag aus bestehenden Movement-/Area-/
   Profilquellen, getrennt vom Ausfuehrungsfeedback. Fokus auf einen kuenftigen
   Planbefehl bleibt vorrangig; gemischte oder unvollstaendige Quellen behaupten
   keinen gemeinsamen Auftrag. Fokussiertes GREEN 46/46 unter
   `output/hud_architecture_20261106/active_order_green/20261106T141846Z-dad19117/`;
   bestehender Batch-Neighbor 40/40 unter
   `output/hud_architecture_20261106/command_order_neighbor_green/20261106T141914Z-9ca4e472/`.
   Root aktualisierte dessen zwei betroffene Textassertions; Command-/Plan-/
   GO-Pruefungen bleiben erhalten. Der spaetere finale Batchnachlauf besteht
   43/43 und bindet die sichtbare Portraitkarte statt der versteckten alten
   Memberreihe. Der finale native Bildbeleg bestaetigt die konkrete Move-Zeile.

Root hat die beiden finalen 3440x1440-PNGs und die Originale
`menu_heimatbasis.png` und `mockup_a5_mission_zweireihig.png` direkt geoeffnet.
Der normale 90-s-Vollbildlauf besteht 63/63; die Kamera blieb dabei unveraendert.
Diese Bildpruefung bestaetigt die beiden kleinen UX-Differenzen. Die grosse
freie Sandflaeche, entfernte Figuren und gleichfoermige Homebasegewichtung
bleiben sichtbar; sie ist keine gestalterische Gesamtabnahme.

Details und RED/GREEN-Grenzen stehen in den beiden Untertasks
`HUD_ARCHITECTURE_2026_11_06_homebase_flightdeck.md` und
`HUD_ARCHITECTURE_2026_11_06_active_order_readout.md`. Technische Tests sichern
Zustaende und Darstellungseingaben; sie nehmen das visuelle Ziel nicht ab.

## Offene gestalterische Entscheidung

Ein weiterer deutlicher Schritt zur Vorlage braucht einen eigens begrenzten
Kamera-/Szenenkompositionspass mit gleichem nativen Bildausschnitt vor/nach,
ohne diesen Schritt durch weniger Gameplayworkload zu erkaufen. Fuer die
Heimatbasis waere die Gewichtung von Arbeitsflaechen, Fokusidentitaet und
Szenenpraesenz getrennt zu entwerfen. Diese Vorschlaege sind nicht umgesetzt.
Keine erfundene Prozentnaehe und keine gestalterische Nutzerfreigabe.
