# Polisa: gepaarter Adapterpfad hinter ausgeschaltetem Lokalflag

Source069b1ac57 plus Replayfix036614ee1 als42cf96602/8570e1da0 integriert.
Review fand oeffentlichen Birthretry im generischen Returnzweig; Fix routet nur
passenden aktuellen Kauf/Fleet/Flight/Glut2Actor/Travelrevision zum Birthreceipt.
Nach spaeterem Dockfortschritt gewinnt der echte Returnweg. Folge-Review geschlossen.

Frisch privat: `python scripts/tests/run_orbit_owner_integration_check.py polisa_cycle`
und `... polisa_birth_retry`, letzterer42/0; beide Exit0, saubere Logs, alle Quell-/
Profil-/Canaryguards true. Oeffentliche Erstaufnahme/Retry ohne doppelte Fuelbuchung,
danach echte Dock-/Canceltransaktion mit eigenem Receipt. Polisa-Warpzyklus nutzt
jetzt den tatsaechlichen Adaptertick im innerhalb der Fixture eingeschalteten
Lokalmodus. Verkürzte Gateflugstrecken und kontrollierte Visit/Pilot/Floweingaben
bleiben die im vorherigen Ownerzyklus dokumentierten Grenzen.

Produktflag bleibt defaultfalse, LivekatalogV2. Bestehender strategischer Pfad
bei ausgeschaltetem Flag bleibt erhalten. Kein echter AP6-Besuch-/Crew-/Retire-/
UI-/nativer Gesamtnachweis und keine Aktivierungs- oder EXE-Freigabe.
