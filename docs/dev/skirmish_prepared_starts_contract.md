# Vorbereitete Skirmish-Starts

Stand: 10.11.2026. Datenquelle: `data/skirmish/prepared_starts.json`.

## Einstieg und Trennung

Der Hauptmenübutton **Skirmish** öffnet die Auswahl von Early, Mid und Late Game.
Ein zusätzlicher Zugang startet weiterhin mit dem eigenen gespeicherten Team.
Ein Preset ist ein frischer, reproduzierbarer Weltstart, kein fremdes Teamprofil
und kein Kampagnencheckpoint. `game_start_contract.gd` transportiert ausschließlich
den validierten `preset_id` zusammen mit `mode=skirmish, action=new`.

`skirmish_start_configuration.gd` erzeugt aus diesem Schlüssel eine deterministische
Roster-/Flottenkonfiguration und gibt sie dem bestehenden Flow. Es liest und schreibt
keine Dateien der Teambibliothek. Der Flow darf auch nach Missionen kein Preset in
`local_player` zurückspeichern. Die Kampagnenführung bleibt für Presets ausgeschaltet.
Regionen, Karte und freie Auftragswahl verwenden die gemeinsamen autoritativen Owner;
keine zweite UI-Welt und keine Festlegung einer späteren Galaxienstruktur.

## Inhalte

| Start | Personen insgesamt | Flotte | Betten / Pads |
| --- | --- | --- | --- |
| Early | 8, davon 3 Piloten | Cutlass und zwei Buccaneer | 8 / 3 |
| Mid | 20, davon 5 Piloten | Vanguard, zwei Hornet, Valkyrie, Hercules | 20 / 5 |
| Late | 30, davon 6 Piloten | Idris, Valkyrie, Hercules, zwei Hornet, Jagdbomber | 30 / 6 |

Alle Personen beginnen mit echtem Sturmgewehr (`rifle`), Pistole und abwechselnd
mittlerer/schwerer Rüstung. Piloten zählen zu den angegebenen Gesamtzahlen;
es gibt keine zusätzlich erzeugte unsichtbare Besatzung. Bodentrupps bestehen
aus maximal vier Personen mit expliziter Zuordnung je Mitglied.

Mid/Late besitzen klar benannte Modellplatzhalter, bis der Nutzer die Modelle auswählt.
Jeep/Panzertransport, mobiler Idris-FOB, Trägerhangar, Wiederbewaffnung und Medic Bed
sind sichtbar als noch nicht bedienbare Ausbauziele vermerkt. Ein generischer
Transportplatzhalter ist kein Nachweis dieser Spezialfähigkeiten.

## Infrastruktur und Personen

`BasePersonnelRuntime` besitzt die echten Basisakteure. `base_capacity_layout.gd`
erweitert die vorhandene eingerichtete Basis bei Konfiguration oder Rekrutierung.
Die beiden ursprünglichen Habitatbetten bleiben unverändert. Zusätzliche Feldbetten
liegen in einem gesonderten Anbau-/Feldlagerbereich westlich der Pads. Bettinteraktionen
und weitere Pads müssen auf der echten feinen Navigation erreichbar sein. Visuals
lesen die vom Runtimeowner verwendete Layoutprojektion.

`sync_roster()` ergänzt neue Personen ohne bestehende Akteure, Schlafreservierungen
oder Wege neu anzulegen. `mark_recruit_remote(unit_id, craft_id)` darf nur vom
geprüften Rekrutierungs-Lifecycle aufgerufen werden: ein aufgenommenes Crewmitglied
bleibt an Bord seines tatsächlichen Schiffs, statt gleichzeitig zuhause zu erscheinen.
Ein Bett darf nur einmal belegt oder reserviert werden.

## Prüfung

- `skirmish_prepared_starts_test.gd`: Menübuttons, Startmetadaten, Größen,
  echte Loadout-IDs, deterministischer Neustart und unveränderte Teamdatei.
- `skirmish_prepared_flow_test.gd`: echter Flow-Handoff, Roster/Flotte,
  keine Kampagnensperren, tatsächliche Ausrüstung/Personen/Betten und Pads.
- `base_capacity_layout_test.gd`: unveränderte Originalbetten, passende
  Kapazitäten und echte AStar-Wege zu jedem Bett-/Padziel.
- `base_personnel_expansion_test.gd`: zustandserhaltende Rekrutierung,
  Schiffsanwesenheit und eindeutige Bettreservierung.

Native Gestaltung und Spielspaß sind durch diese technischen Prüfungen nicht abgenommen.
