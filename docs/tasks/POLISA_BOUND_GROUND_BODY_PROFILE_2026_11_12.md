# Polisa: gebundenes Bodenschiffsprofil

## Ziel und Ursache
Stationskauf-Admit prueft bisher bereits geparkte Schiffe erneut ueber den
aktuellen Renderer inklusive Kamera-Yaw. Kameradrehen darf ihre physische
Belegungsflaeche nicht aendern. Das einmal zur Aufnahme gepruefte Profil wird
am bestehenden `_field_landing_by_craft`-Eintrag gebunden.

## Umfang / Nicht-Ziele
Nur Controllerbodies `preview_station_craft_admission` / `admit_station_craft`,
ein reiner Profilvalidator sowie kleine isolierte Controller-QA. Keine neue
Positionswahrheit, keine Root-/Ground-/Renderer-/Anflug-/Crewaenderung. Normale
ankommende Dropships brauchen spaeter ihren eigenen expliziten Bindungsproducer
im Tabletop-Paket; ungebundene belegte Altstaende werden hier nicht repariert.

## Dokumente
`docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`,
`docs/dev/polisa_local_ship_pickup_contract.md`,
`docs/dev/graphics_reference_revision_contract.md`,
`docs/dev/polisa_bound_ground_body_profile_contract.md`.

## Akzeptanz
Preview liefert detached validiertes `ground_body_profile`. Admit bindet es
synchron mit vorhandener Position/Pad-ID; belegte Schiffe lesen ausschliesslich
ihre gebundenen Profile. Kameraaenderung ruft fuer sie keinen Renderer an.
Fehlende/ungueltige/fremde Craft-/Modell-/Assetprofile scheitern ohne Mutation.
Keine externen Object-/Array-/Dictionaryaliase im gespeicherten Profil.

## Dateien / lokale Pruefung
`scripts/tests/mission_tactical_sandbox_controller.gd` (nur zwei Bodies), neuer
`scripts/mission/polisa_ground_body_profile.gd`, eigene QA unter
`output/native_glut_maps/polisa_bound_ground_body_20261112/`.
Kleine echte Controllerprobe mit FakeView/Map/Registry, roter Ausgangslauf und
isolierter gruener Kontrolllauf; keine grosse Suite/GPU/native Grafikabnahme.

## Risiken
Failclosed kann Kauf bei ungebundenem normalem Besucher vorlaeufig blockieren.
Das ist eine Aktivierungsgrenze, kein Anlass zum stillen Kamerabindungsfallback.
Gebundene Profile sind Runtimewerte, keine neue Save-/Receiptversion.
