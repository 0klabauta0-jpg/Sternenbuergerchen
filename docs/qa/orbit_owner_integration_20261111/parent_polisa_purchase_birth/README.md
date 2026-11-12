# Polisa: echte Kaufbelege bei lokaler Erstaufnahme

Readonly Sourcee040c5d29 als25e4664d5; atomarer Anschluss1dabdca07 plus
Reviewfixa3c973d8f als8d568332d/0cf33d103 integriert. Unabhaengiger Review:
Publisher pruefte neuen Equipmentreceipt nicht; nach synchronem Fuelobserver
fehlte erneute Ownerpruefung. Fix prueft Equipment vor erstem Event und danach
Fleet/Flight/Supply/Epoche/Equipment/Fleetreceipt erneut. Mark-before-emit bleibt,
Invalidierung erzeugt kein veraltetes Birthereignis oder spaeteres Nachsenden.

Frisch im Parent privat: `python scripts/tests/run_orbit_owner_integration_check.py polisa_birth`
und `... polisa_birth_reentrant`, je42/0, Exit0, saubere Logs, alle Quell-/Profil-/
Canaryguards true. Echtes Adapter/Root/Supply/Equipment/Fleet/Flight, Kaufreceipt,
volle lokale Gateaufnahme, Pflichtrotte, Fuel-once, Replay und Ownerwechsel vor
sowie innerhalb Fuelcallback. Pilot-/Visit-/Floweingaben bleiben kontrollierte
Fixturewerte. Die Quellhashes und exakten Logs liegen daneben.

Expliziter Adapterpfad `enter_purchased_station_local_orbit`, kein fingierter
Vorflug/alter LocalActor. Neue Fleetoperation depart_station_purchase, Birth-ID
an Kaufreceipt und Craft gebunden; Fuelbeleg bleibt vorhandener Kauf-Rueckweg.
Noch kein produktiver UI-/Flowroutewechsel fuer Kaeufe und kein echter AP6-
Stationsbesuch oder Boardingnachweis. Automatischer lokaler Warp bleibt aus,
LiveJSON bleibtV2. Keine native Reise-/Grafik-/Gefechtsabnahme, keine EXE.
