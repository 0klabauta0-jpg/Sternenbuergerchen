# Polisa-Rundflug: isolierter Headless-Nachweis

12.11.2026, Godot 4.6.2, Ausgangscommit `e10b2cd7f2261a873fc9bb5db899d23feaf4dc80` mit dem nachträglich ergänzten Profilguard im Verifier. Produktcode ist `b5e1fe397`; Basis ist der nicht auf main integrierte Parallelstand `62a14dd76`.

Ausführung: `pwsh -File scripts/tests/run_polisa_roundtrip.ps1`. Ein frisches temporäres APPDATA und `POLISA_TEST_PROFILE` isolieren das Testprofil. Der Runner vergleicht die SHA-256-Hashes seiner fünf benannten Quellpfade vor und nach dem Lauf. Ergebnis: Exit 0, keine `SCRIPT ERROR`, `ERROR` oder `FAIL`, keine Änderung an diesen Quellen. Der rohe Lauf liegt lokal im temporären Profil; SHA-256 des Logs: `A91EA2D9B83D60D8A00139D2BB0ACD36DC791EAF3AA1FCF4AE30500985A447BB`.

Geprüfte Quellen beim Lauf:

- `scripts/meta/meta_layer_flow.gd`: `52DE22113E56098452424B9319A6D42CE8CA77A36CDE50F365DCB2B13B51305D`
- `scripts/meta/singleplayer_runtime_adapter.gd`: `AD9826C9908FD366B68B38AF79B3F8B3B8631D6BD4BB64EEA2A359A775135D3E`
- `scripts/tests/mission_tactical_sandbox_controller.gd`: `F6F43E5FDC582877F2F6F4EA5FA346855A301F5C899C0E3C87C1CC63C85FEE7D`
- `scripts/core/simulation_root.gd`: `78BE36C36092E44C013996F05BAB108B861CA4FD63E0BAAB92D9DE2EDCA1B867`
- `scripts/tests/polisa_real_roundtrip_verifier.gd`: `7907F28A230855E9F27BFE28C5F97BEFEC070536B1FD48DC0BF9B90A6B802895`

Ergebnis: **25 bestanden, 0 fehlgeschlagen**. Der Lauf umfasst echte Kampagne und Crew, Start, Quantum nach Polisa, Karten- und Padwahl, Landung und Ausstieg der ganzen Crew, Kauf mit Einbuchung ins Schiff und Start des 3D-Aufzugsknotens, Tanken, Boarding, Abflug, Quantum zurück und Heimatlandung mit erhaltener Fracht. Das Basisboarding wird über den vorhandenen Debug-Takt beschleunigt.

Ergänzende Prüfungen auf derselben Produktbasis: `polisa_real_visit_board_retire_probe.gd` 37/37; `polisa_services_remainder_check.gd` 11/11; `polisa_landing_owner_cycle_verifier.gd` und `polisa_cargo_lift_check.gd` jeweils Exit 0. Der Ownerzyklus verwendet Fixtures.

Dies ist keine manuelle oder visuelle Abnahme. Die 3D-Aufzugsgestaltung und Steuerbarkeit wurden nicht am Bildschirm beurteilt; die Ware wird beim Kauf gebucht und nicht physikalisch oder zeitlich verzögert transportiert. Der lokale Orbitflag blieb aus. Der gegen den laufenden Parallelstand integrierte Code benötigt dessen erneuten gemeinsamen Testlauf.
