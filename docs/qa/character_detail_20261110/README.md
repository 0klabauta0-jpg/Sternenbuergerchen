# Grosser Charakterbogen und Portraitzuordnung — 10.11.2026

Auftrag: `docs/tasks/CHARACTER_DETAIL_IDENTITY_2026_11_10.md`.
Aufbau auf Orbitprodukt7011ce4b2; noch keine gemeinsame Mainintegration/EXE.

## Grosser Bogen, kleine Karten

Der grosse Bogen nutzt den Raum neben dem Portrait fuer Name, Startrolle,
aktuelle Aufgabe und Status. Wichtigste Eignung mit echter Resolverbegruendung
und der Zusammenhang Eigenschaften -> aktuelle Werte -> Eignung stehen vor
den Detailgruppen. Eigenschaften und die wichtigsten gespeicherten Beziehungen
erscheinen nebeneinander sichtbar vor den Werte-/Verlauf-Foldouts.

Beziehungen verwenden aktuelle Namen aus dem Roster, signierte Affinitaeten,
deutsche Standardtags und den gespeicherten Grund. Eigene Begruendungen bleiben
inklusive Leerraum erhalten. Keine Beziehung wird aus gleichen Traits erfunden;
fehlende Daten bleiben als unbekannt erkennbar. Profile und Scores werden beim
Rendern nicht geaendert. Kleine Portrait-/Rangkarten und ihr Layout bleiben
unveraendert. Die globale Kampagnenhilfe verdeckt weder den grossen Detailkopf
noch die Sternkartenueberschrift; diese Ansichten besitzen eigene Hinweise.

## Name und Bild

Belegter Standardfehler: Anja Voss verwendete Portrait003 (laut archivierter
Bildvorgabe maennlich). Der Standard und neue Kampagnen verwenden nun004
(dokumentierte weibliche Commander-Vorlage), mit zusammenpassender ID/Pfad.
Vorhandene gespeicherte/custom Identitaeten werden nicht automatisch migriert;
ihre Daten enthalten keinen verlaesslichen Beleg fuer eine unveraenderte
Standardportraitwahl.

Der Katalog besitzt nun ausdrueckliche Praesentationsmetadaten mit Prompt- und
Quadrantenquelle. Neue synthetische Roster verwenden explizite Namensgruppen
und waehlen dazu ein kompatibles Portrait. Keine Inferenz ueber reale Menschen
oder beliebige gespeicherte Namen. Die androgyn dokumentierte Vorlage019 bleibt
unbestimmt. Reicht eine passende Gruppe nicht fuer Eindeutigkeit, wird nur ein
kompatibles Portrait wiederholt; es gibt keinen gegenteiligen Gruppenfallback.

Die bereits vorhandenen Zufallsziehungen, Namen und saemtliche Nicht-Portrait-
Profildaten bleiben erhalten. Eingefrorene Signaturen fuer20/24/30 Figuren
stimmen exakt mit dem vorherigen Generator ueberein; Bilder/Atlasregionen,
Artquellen und ihre Hashes sind unveraendert. `seeded_baseline.json` liegt unter
`../character_identity_20261110/`.

## Nachweise

- [Fuenf frische Root-Gates](../orbit_quantum_20261109/raw/character-detail-frozen-root/results.json): Identitaet152/0, echter grosser Bogen25/0, Abflug/Hinweis41/0, Beziehungen23/0, Generierung321/0; alle Exit0/errors0.
- [Detail-/Editorregressionen](../orbit_quantum_20261109/raw/character-detail-final/results.json): Werte, Beziehungen und editierbarer Teameditor bleiben erhalten; abschliessender Detailtest25/0 in `character-detail-owner-final/`.
- [Unabhaengiger Identitaetsreview](../orbit_quantum_20261109/raw/identity-independent-review/):152/0 und Artquellpruefung.
- [Hinweisgrenze](../orbit_quantum_20261109/raw/detail-overlay-clean-red/) zuerst41Checks/2erwartete Fehler, danach [GREEN](../orbit_quantum_20261109/raw/detail-overlay-green/).

Reale Control-Grenzen:1280x720 und1920x1080, Popup736x656 bzw.736x760,
kompakter Kopf und sichtbare Beziehungsgruppe vor der Scrollgrenze.
Headless/private Profile, kein Fokuswechsel. Keine subjektive Gestaltungs-
abnahme behauptet. Zwei gegenseitige unabhaengige Quellreviews ohne Restbefund.
Zwei alte englische Beziehungstestlabels und ein alter Teammenue-Captiontest
wurden gegen bereits vorher vorhandene deutsche Beschriftungen aktualisiert;
Owner-/Roundtrip-/Cohesion-/Gameplayassertions bleiben bestehen.

## Naechster Schritt

Der andere Basis-/Orte-/UI-Chat muss seinen aktuellen Task abschliessen.
Danach gemeinsame Integration mit echter Personalwelt/Pilotenpraesenz,
gemeinsame Tests, Main-Commit und normaler Push; erst anschliessend gemeinsame
EXE. `docs/tasks/ORBIT_BASE_INTEGRATION_2026_11_10.md` beschreibt die Naehte.
