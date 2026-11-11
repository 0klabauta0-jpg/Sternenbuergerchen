# Beobachtungsfreie Abflugvorschau

## Ziel / Ursache

Der künftige gemeinsame Orbitanflug braucht einen Abflugcheck ohne vorherige
Chiprückgewinnung oder Onboardingmutation. Bisher ruft `validate_departure`
`observe_campaign_progress` auf und kann dadurch bereits Ownercommands auslösen.

## Umfang / Nicht-Ziele

Ein neuer, noch nicht produktiv aufgerufener `preview_departure` nutzt dieselben
bestehenden Gates ohne diesen Beobachtungsschritt. `validate_departure` behält
seine bisherige Reihenfolge und Beobachtung. Keine Autorisierung, kein Debit,
kein neuer Reise-/Saumbeweis, keine Änderung an Root oder Wirtschaftsownern.

## Verträge / Akzeptanz

ORBIT_DEPARTURE_ATOMICITY_AUDIT, orbital_approach_contract und
AP5_TO_AP8_CONTINUATION. Vorschau ruft keine Recovery-/Onboardingbeobachtung
auf; alte Validierung tut dies weiterhin nach dem Pilotgate. Beide verwenden
denselben Gatekörper. Noch kein produktiver Anfluganschluss daraus.

## Dateien / lokale Prüfung

`scripts/meta/singleplayer_runtime_adapter.gd`, schmale In-memory-Probe mit
gezählten Beobachtungsaufrufen und check-only Compile. Keine große Testsuite.

## Risiken / offene Punkte

Die Vorschau liest bestehende Runtimeprojektionen. Sie ist kein atomarer
Beleg gegen nachfolgende Änderungen; Root muss sämtliche tatsächlichen
Flight-/Pilot-/Payload-/Wirtschaftsbedingungen vor dem gemeinsamen Commit
erneut prüfen. Zusammenführung und Produktaktivierung folgen gesondert.

## Ergebnis

Implementiert ohne produktiven neuen Aufrufer. Vier kleine Prüfungen am echten
Adapter mit gezählten Beobachtungsaufrufen: Kampagnenvorschau ohne Beobachtung,
bisherige Validierung weiterhin mit Beobachtung, Pilotgate davor und identische
Nichtkampagnen-Zielprüfung. 4/0, Prozess 0; die Probe lädt und kompiliert den
tatsächlichen Adapter. Log/Fixture unter
`output/native_glut_maps/orbit_departure_preview_20261111/`.
Die übrigen Verbraucher sind Testdoubles; kein echter Flug/Ownergruppencommit,
kein Profil-/Saveguard und keine große oder native Prüfung beansprucht.
