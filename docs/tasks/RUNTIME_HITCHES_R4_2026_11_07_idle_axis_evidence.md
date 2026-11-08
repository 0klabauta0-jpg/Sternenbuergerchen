# R4: TASK174-Achsenannahmen gegen wirkliche Visuals pruefen

## Problem / Basis
TASK174 meldet bei seinem regulaeren Szenenstart81/2. Root hat exakt dieselben
beiden Ausfaelle auf Main3b12b2878 mit privat archivierten Originalquellen
reproduziert. Das ist derzeit ein Baselinebefund, keine R4-Regression.
Die zwei Pruefungen verwenden den BlasterVisual-Root als sichtbare Waffe und
Proxy+Z als NPC-Ruecken. Der bestehende Unit-Facingpfad richtet die importierte
Figur jedoch entlang Proxy-X aus; die inversen Welt-/Yawmethoden stimmen auf
dieser Achse ueberein. Der Blaster besitzt ausserdem eigene Child-Pivot-/Yaw-
Korrekturen. Erst echte Mesh-/Bone-/Posturemessung darf den alten Gateausschnitt
berichtigen; bloss die Schwelle zu senken waere kein Nachweis.

## Umfang / Nicht-Ziele
Nur ein lesender Inspector ueber denselben normalen Missionsstart und dieselben
beiden vorhandenen Identitaeten wie174. Keine Produkt-, TASK174-, Actor-, HP-,
Positions-, Posture-, Uhren-, Facing-, Command- oder Authoritymutation. Kein
synthetischer Fire-Event und kein inszeniertes Orientierungs-PASS.

## Dokumente / betroffene Dateien
AGENTS, ARCHITECTURE, CODEX_RULES, R4-Haupttask, Combat-Visual-Untertask,
`unit_facing_visual_contract.md`; alter
`task_174_character_helmet_blaster_attachment_verifier.gd` bleibt unangetastet.
Neu: `scripts/tests/runtime_hitches_r4_20261107_idle_axis_inspector.gd`.

## Akzeptanz / lokale Pruefung
- Normale Mission18 Prozessframes plus4 Physicsframes, bestehende unit_alpha
  und enemy_delta; wirkliche Proxy-/Weapon-/Mesh-/Socket-/RightHand-Bonedaten.
- Tatsächliche Runtime-/angezeigte Waffenposture und Animation protokollieren,
  bevor eine Aussage ueber Idle, Ready oder Aimed gemacht wird.
- Alte Root-Barrel-/Magazine-/Proxy+Z-Metrik und getrennt echte Meshfront,
  beide Mesh-Y-Richtungen, kanonische Proxy-X/+X-Achsen und Bonebasis erfassen.
  Die Dotwerte werden als Diagnose ausgegeben, ohne die Orientierung zu bestehen.
- Quelleneigentum bleibt unveraendert; Engine-/Baseline-/native Folgepruefung
  ausschliesslich durch Root. Falls die Messung eine veraltete Referenz belegt,
  konkrete Gatekorrektur erst danach gesondert und nachvollziehbar freigeben.

## Risiken / Status
Mesh-Y ist ohne Assetgeometrieanalyse keine belegte Magazinrichtung; deshalb
beide Vorzeichen ausgeben. Einzelne Headlessvektoren beweisen keine nativen
Pixel und koennen einen normalisierten Posevertrag nicht allein neu definieren.
Kein Engine-/Orientierungsnachweis durch den Autor.

## Gebundener Rootbefund / Folgeauftrag
- Rootinspector `idle_axis_inspection/20261107T094404Z-36b69d2a/`:5/5 rein
  strukturelle Read-/Puritychecks. Beide Originalfiguren sind lowered/idle.
  Rootfront-DOWN+.959 und sichtbare Meshfront-DOWN-.959 widersprechen sich;
  altes Root-UP/Proxy+Zback etwa-.13, Root-UP/kanonischesProxy+Xback etwa-.95,
  sichtbares Mesh-DOWN/kanonischesBack etwa+.95. Die sichtbare Mündung zeigt
  im alten Main-Assetpfad tatsaechlich nach oben.
- Originale GLB-Geometrie bestaetigt danach unabhaengig Mündung(-Z) und
  Magazin dominant(-Y). Der gesonderte Folgeauftrag
  `RUNTIME_HITCHES_R4_2026_11_07_attachment_idle_gate.md` dokumentiert die
  Gate-Reparatur, echten83/2-RED vor Produktfix und spaeteren85/0-Root-GREEN.
  Dieser Inspector bleibt ein Diagnosewerkzeug ohne Orientierungs-PASS.
