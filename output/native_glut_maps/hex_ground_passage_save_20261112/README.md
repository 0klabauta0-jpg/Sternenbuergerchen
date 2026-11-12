# Host Ground Passage Save: Produktfreeze

Schema hex_ground_v2 hat verpflichtend passage_commitments=[{cells:[[q,r],...],
unit_ids:[...]}]. Alle uebrigen v1-Felder bleiben gleich. v1 bleibt ausdruecklich
nur die alte offene Teilmenge; fehlende Zusagen bei Passagebewegung scheitern.
Keine Root-/Checkpoint-/MP-/Actor-/Backoff-/Actionintegration oder full_ap7.

Export benutzt ausschliesslich aktive bestehende Grants, behaelt ganze Mitglieder
auch ausserhalb der Passage, sortiert IDs und die Grantliste deterministisch;
Zellen bleiben exakt Registryreihenfolge. Restore begrenzt64 Zusagen,64Mitglieder
je Zusage,4096Gesamtzellen; nur cells/unit_ids, strikt sichere Integerpaare.
Echte Registryquery(origins,64) beweist identity/revision/query_complete und volle
ordered directed Komponente. Teilpassage, Kreis, falsche Reihenfolge, Duplikate,
Ueberlappungen und unbekannte Mitglieder werden abgelehnt. Bestehende Geometrie-
und Grantvalidatoren pruefen Aktivitaet/Richtung; private Candidategrants werden
VOR Policy/Grantconflict gesetzt. So bleibt monotones Raeumen von Nichtmitgliedern
zulaessig, ohne sie der Kohorte hinzuzufuegen. Kein privater Cache-/Queuestate.
Terrain-/pendingAdmission-/Topologieguards bleiben, Publish atomar im selben Owner.

Gezielter RED mit gesichertem524fd61d1 Ground ausschliesslich in privater Kopie:
../hex_ground_save_state_20261112/ground_save-e10452a2c6ed4ba28c2a14c6813e1fe4/
14/1, konkrete fehlende Passagefunktion, Exit1 ohne Scriptfehler.
Final GREEN inkl privatem Compile:33/0, Exit0, keine Engine-/Scriptfehler,
Originalprofil/Quellen identisch, privateCanary:
../hex_ground_save_state_20261112/ground_save-be73eb1d91e44a0498ba6f4b58846365/

Enge Cases: echte akzeptierte Passage; vor/nach Handoff; aktives Versprechen ohne
Segmente; ganze Kohorte mit ausserhalb stehendem Mitglied; erlaubtes Nichtmitglied-
Raeumen vor/nach Handoff; detach; fehlende V2Felder; partielle/ueberlappende/fremde/
doppelte/reverse/overflow Werte; Legacyoffen und fehlende Bewegungszusagen;
urspruengliche Terrain-/Admission-/Zentrierungs-/Konfliktchecks bleiben.

Runner: python output/native_glut_maps/hex_ground_save_state_20261112/run.py
Optional --baseline ersetzt NUR private Groundkopie per git show524fd61d1.
Keine grosse Matrix/GPU/Gitmutation. Root und Checkpoint bleiben Anschlussarbeit.

## Reviewkorrektur: gemeinsames Topologiebudget
remaining_nodes beginnt EINMAL pro Kandidat bei64, jede Registryquery zieht ihre
processed_nodes ab; spaetere Komponenten erhalten nur den Rest (ggf0). Kein
Reset je Zusage. Reale kalte disjunkte Komponenten32+48 belegen RED34/1:
../hex_ground_save_state_20261112/ground_save-3908ff96faee483eb43746477239aa57/
GREEN35/0 nach Korrektur:
../hex_ground_save_state_20261112/ground_save-79934f009aea446fafaa3561671a4415/
Erster Versuch prueft hoechstens64 neue Nodes und publiziert nichts; zweiter
begrenzter Versuch vervollstaendigt die Ableitung und restauriert beide Zusagen.
Compile/Exit0/Log-/Profil-/Quellen-/Canaryguards gruen. Neuer Produktfreeze.
