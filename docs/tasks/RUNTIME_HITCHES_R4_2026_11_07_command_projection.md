# R4: lokale Befehlsprojektion und GO-Feedback

## Ziel / Problem / Ursache
Teilauftrag von `RUNTIME_HITCHES_R4_2026_11_07.md`. Der regulaere
`_refresh_order_visuals` erzeugt dieselben Quellen fuer den kompatiblen
2D-Visualizer und den primaeren 3D-Payload erneut. Der Preview-Builder liest
Plaene und Anker nochmals: pro Projektion derzeit vier Plan-/Ankerbuilds und
zwei Builds der uebrigen fuenf Quellen. Erfolgreiches regulaeres GO aktualisiert
Buttons direkt und nochmals im unmittelbar anschliessenden Feedbackpfad.
Die Quelle bleibt der aktuelle Runtime-/Planowner; nur identische synchrone
Lesearbeit innerhalb desselben Aufrufs darf entfallen.

## Umfang / Nicht-Ziele
- Ein frischer lokaler Quellensatz pro Visualprojektion; 2D, 3D und echte
  Intent-Preview erhalten identische aktuelle Quellen.
- Bestehende nullargumentige Methodensignaturen fuer Derived-Probes und
  standalone Aufrufe beibehalten; neue explizite Helper duerfen teilen.
- Explizit leere Quellen bleiben leer, auch wenn Ownerdaten vorhanden sind.
- Ein Buttonfeedback nach erfolgreichem GO, mit denselben Gates, Callbacks,
  Plaenen, Queue-Commands und synchronem Planungssignal.
- Keine persistente Frame-/Befehls-/Snapshotcache-Wahrheit, keine Aenderung an
  Simulation, LOS, KI, Commands oder der Zwei-Schritt-Menuevorschau.
- Insbesondere nicht nur den Test-Rightclick-Wrapper schneller machen oder die
  erste regulaere Create-Vorschau entfernen. Beide Refreshaufrufe bleiben
  fachlich moeglich und lesen jeweils frisch.

## Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, `mission_hud_projection_authority_contract.md`, R4-Haupttask.

## Akzeptanz / lokale Pruefung
1. Echter RED mit Test-only Controller-Subclass gegen unveraendertes Produkt:
   jeder der sieben Visualquellen wird in einer regulaeren Projektion genau
   einmal gelesen; Aufrufer und verschachtelte Zeitbereiche werden separat
   protokolliert und nicht als additive Framezeit ausgegeben.
2. Die tatsaechlichen 2D-/3D-Consumerfelder entsprechen den frisch direkt vom
   Owner gebauten Referenzdaten einschliesslich echter Intent-Preview.
3. Wiederholte Projektion und interleavter oeffentlicher Planbefehl lesen neu;
   ein explizit leerer Helperpayload faellt nicht auf Ownerdaten zurueck.
4. Praesentation aendert weder Actor, Tick, Plaene noch Command-/Effectqueue.
   Erfolgreiches oeffentliches GO aktiviert den realen Plan, enqueued echte
   tokenisierte Move-Commands und publiziert im selben Inputframe. Seine
   Buttonprojektion erfolgt einmal und behaelt Policy und Callbackidentitaet.
5. Bestehender Command-HUD-Batch- und R3-Controller-Verifier bleiben gruen.
   Native Performance ist ein getrennter Root-Vollbildvergleich; der neue
   Verifier ist ein synthetischer Komponenten-/Schedulingnachweis.

## Betroffene Dateien / Risiken / Status
Produkt: `scripts/tests/mission_tactical_sandbox_controller.gd` (Controllerhunks
nach echtem RED exklusiv an den Commandagenten delegiert; danach Sourcefreeze).
Verifier:
`scripts/tests/runtime_hitches_r4_20261107_command_projection_verifier.gd`.
Risiko: veraenderte virtuelle Signaturen, Verlust versteckter 2D-Daten,
staler Zwischencache oder fehlender explizit leerer Payload. Diese Faelle sind
eigene Gates. Kein Engine-/Gitlauf durch den Auditagenten.

## Aktuelle Nachweise
- Echter Root-RED: `output/runtime_hitches_r4_20261107/command_red/20261107T085155Z-2c0d4bd5/`,
  22 bestanden, 5 fehlgeschlagen, keine Enginefehler. Quellenzaehlung zeigt
  Anker/Plaene4x und uebrige Quellen samt echter Preview2x. Beide regulaeren
  GO-Buttonprojektionen haben identische aktuelle Plaene, Gates und Callbacks.
- Patch liest sieben Quellen frisch in einem lokalen Dictionary, teilt diese
  mit 2D, 3D und Preview und behaelt die bisherigen Standalone-Signaturen.
  Der erfolgreiche GO-Endpfad belaesst den Buttonpass im Feedbackowner.
- Sourcefreeze nach den zwei delegierten Controllerbereichen (Befehlsprojektion
  und separater nativer Kartentask): Controller-SHA256
  `f43c959c225ead428b206928b9de703808c5bbc0ef83b699c622c3e265f53752`.
  Commandverifier unveraendert:
  `0f787bf2ffe0ee450919b93c84328d17bc947c59476caa31132d3decbf96d69b`.
- `git diff --check` sauber. GREEN, Nachbargates und native Messung stehen
  noch aus und werden ausschliesslich vom Root ausgefuehrt.
