# Kampagnenbeobachtung — schmale frische Projektion

11.11.2026, isolierter Taskbranch auf85fd00afc. Enger CPU-Fix, keine
Änderung an Aufträgen, Fortschritt, Inventar oder physischem Boarding.

## Ursache und Änderung

Der viertelsekündliche Beobachter baute auch im Gefecht vollständige
Operations-UI-Daten und unbenutzten Service-/Departure-Kontext auf.
Vier Abschlussstatuswerte erzeugten zusätzlich zur anfänglichen Projektion
jeweils einen neuen tiefen Kampagnensnapshot. Jetzt stammen alle zehn
Fortschrittsfelder aus einer frischen lokalen Projektion nach unveränderter
Chip-Recovery. Kein persistenter Cache, kein neuer Throttle und kein await.
UI-Readiness nur zuhause beim angenommenen ersten Satellitenauftrag, wo
base_ready tatsächlich wahr werden kann. Physisches Boarding, Pilotzuweisung
und vorhandenes Payloadgate bleiben vollständig erhalten.

## Gemessene Operationen und gezielte Prüfungen

Godot4.6.2, ausschließlich Headless, private APPDATA unter
output/native_glut_maps/private_observe*. Keine Nutzerstände verwendet.
Probe-Snapshotlesungen für die Fortschrittsprojektion5→1; unbenutzter
Servicekontext1→0; Operations-UI im Gefecht1→0. Zuhause beim accepted-Erstjob
weiter1 UI-Projektion und dieselben Gates. Die zusätzliche echte Chip-Recovery
wird nicht als eingesparte Arbeit ausgegeben; der Operationszähler testet
bewusst die Projektion nach dieser Recovery.

- Neuer campaign_observe_projection_test: RED16Checks/6Fehler → GREEN16/0.
  Alle zehn Evidencefelder, Zuhause/Mission/Transit/Schiff-away, beide
  physischen Presencegates, Pilot/Payload, frische Folgemutationen,
  Recovery-Reihenfolge und Nichtkampagnenweg.
- campaign_five_missions_chain_test:54/0.
- campaign_tutorial_single_projection_verifier:7/0.
- Unabhängige lesende Source-Review ohne konkreten Blocker: review.md.

## Ausdrücklich nicht grüne Altverifier

campaign_onboarding_state_test erwartet alte dreistufige Onboardingfakten,
meldet satellite returned/trade full loop completes und faultet anschließend
auf completion_receipt; nach8s beendet. Dieser Test lädt den geänderten
Adapter überhaupt nicht, seine Core-/Testquellen sind unverändert gegenüber
85fd00afc. Keine Reparatur fremder Erwartungen in diesem engen Fix.

base_personnel_runtime_verifier meldet vier identische Fehler vor und nach
unserem Adapterfix: sleep blocks incompatible movement; continue restores
actual sleeping person and exclusive bed; wake frees sleeping person;
checkpoint accepts any actual roster person as pilot and other person as leader.
Baseline nutzt private unveränderte85fd00afc-Adapter-/Flow-Kopien, nur deren
res://-Bindungen angepasst. Beide vollständig beendeten Läufe Exit1,
BASE_PERSONNEL failed=4. Ein früherer Afterlauf war nach60s unvollständig;
seine drei bis dahin sichtbaren Fehler werden nicht als kompletter Vergleich
verwendet. Der neue vollständige Afterlauf nutzte ein frisches privates Profil.
Damit keine allgemeine Suite-/Basisfunktionsfreigabe behauptet.

## Messgrenzen und Wiederholung

Gleichzeitige Art-/Headlessarbeit verhindert hier belastbare Walltime-/FPS-
Aussagen. Die früheren nativen6–11ms sind Ursachenhinweis; ein isoliertes
nativeres B-Paar muss nach GPU-Freigabe folgen. Der Fix hat eine deterministisch
geprüfte Reduktion unnötiger Arbeit, keine zugesagte Gesamtframerate.

Produktiver Verifier: godot_console.exe --headless --path WORKTREE --script
res://scripts/tests/campaign_observe_projection_test.gd mit privater APPDATA.
Counts-Baseline: git show85fd00afc:scripts/meta/singleplayer_runtime_adapter.gd
in eigenen output-Pfad schreiben und im Probe-Subclass nur extends darauf
umbinden. Vorher-/Nachher-Operationlogs sind erhalten. Keine Produktion für
Baseline temporär überschrieben. Quellenhashes und Ergebnisse im Manifest.
Kein Main-/EXE-Schritt.
