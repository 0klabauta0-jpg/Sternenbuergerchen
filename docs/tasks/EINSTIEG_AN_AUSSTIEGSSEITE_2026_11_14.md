# Einstieg auf der Ausstiegsseite (14.11.2026)

## Ziel / Problem
`campaign_two_moon_roundtrips_real_verifier` schlaegt mit 75 / 1 fehl: "actual crew begins boarding at outpost".
Nach der Landung am Handelsaussenposten antwortet `request_campaign_crew_boarding` mit `crew_not_at_ship`,
obwohl die Besatzung gerade erst ausgestiegen ist und direkt am Schiff steht.

## Ursache (gemessen auf dem Windows-Rechner, 14.11.2026)
- Ausstieg: `_advance_hex_drop_unit` sucht ab `lz + _get_unload_offset(0, Anflugrichtung)` das naechste freie Feld
  ausserhalb des Rumpfs. Im Lauf standen die beiden Personen auf (4,12) und (4,13), westlich des Schiffs.
- Einstieg: `get_campaign_ground_ship_access` suchte ab der Rumpfmitte (7,12) und fand (10,12), oestlich des
  Schiffs. Abstand zu den Personen 434 Welteinheiten, erlaubt sind 128 (`CAMPAIGN_BOARDING_RADIUS`).
- Derselbe Fehlschlag tritt mit der Karte von `f4799d6a6` auf; er haengt nicht an Mauer oder Vorfeld.

## Umfang
`get_campaign_ground_ship_access` beginnt die Suche am selben Ausstiegsanker wie der Ausstieg. Die Anflugrichtung
geht in die Cache-Signatur ein.

## Nicht-Ziele
- Keine Aenderung am Ausstieg, am Boarding-Radius oder an den Schiffsmasken.
- Playtest-Punkt L03 (Einstiegspunkte) des Bedien-Strangs wird nicht vorweggenommen; dies ist nur die
  Angleichung der beiden Suchanfaenge.

## Akzeptanzkriterien
- Die Besatzung kann direkt nach dem Ausstieg wieder einsteigen.
- `campaign_two_moon_roundtrips_real_verifier` besteht den Punkt "actual crew begins boarding at outpost".
- Tests, die `get_campaign_ground_ship_access` benutzen, verhalten sich wie vorher.

## Betroffene Dateien
`scripts/tests/mission_tactical_sandbox_controller.gd` (eine Funktion).

## Lokale Pruefung
Siehe Commit-Nachricht und `docs/qa/freihafen_flugabwehr_20261114/README.md`, Abschnitt "Einstieg".

## Risiken / offene Punkte
- Der Zielpunkt fuer "zum Schiff laufen" liegt jetzt auf der Ausstiegsseite. Wer sich an die alte Seite gewoehnt
  hat, sieht den Marker an anderer Stelle.
