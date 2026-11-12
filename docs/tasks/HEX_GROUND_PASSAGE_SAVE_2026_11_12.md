# Kanonischer Hostsave fuer Passagezusagen

## Ziel / Ursache
Angenommene ganze Passagekohorten muessen nach Hostrestore unveraendert gelten.
## Umfang / Nichtziele
Nur Groundruntime, eigener Verifier und QA. Keine Root-, Checkpoint-, MP-, Action-
oder Backoffintegration. Keine Peerclaims oder privaten Cache-/Queuedictionaries.
## Vertrag / Strategie
hex_ground_v2 verlangt passage_commitments mit cells und unit_ids. v1 bleibt
explizit offene Legacyteilmenge. Ganze aktive Kohorten, auch Mitglieder ausserhalb
der Passage, bleiben erhalten. Echte Registrytopologie mit Budget64 beweist volle
ordered directed Components und passende Revision. Max64 Zusagen, je64 Mitglieder,
4096 Gesamtzellen; keine doppelten/ueberlappenden Passagen. Bestehende Grants werden
im privaten Kandidaten vor Policypruefung gesetzt. Publish bleibt atomar inplace.
## Akzeptanz / Pruefung
Echte Passage vor/nach Handoff und wartende Kohorte, JSONdetach, fehlende/partielle/
ueberlappende/fremde Zusagen failclosed, Legacyoffen kompatibel; eigene private QA.
## Dateien / Risiken
scripts/core/hex_ground_runtime.gd, scripts/tests/hex_ground_save_state_verifier.gd,
output/native_glut_maps/hex_ground_save_state_20261112. Kalte Topologie darf bounded
pending ablehnen. Pendingadmissions bleiben Saveguard. Kein Commit.

Reviewkorrektur: EIN gemeinsames64Neunodebudget pro Restore/Exportkandidat;
processed_nodes reduziert den Rest jeder Komponentenanfrage. Echte32+48Coldprobe
RED34/1 zu GREEN35/0; begrenzter Retry, kein Teilpublish. Produktfreeze.
