# Weltraumkampf: begrenzte Prüfbelege

Basis: Weltraumkampf-Branch mit integriertem Warp-Equipmentstand
`1ced3be19`. Alle hier abgelegten Logs stammen aus frischen headless
Läufen mit privatem APPDATA; keine echten Spielerprofile wurden verwendet.

- Raumreiseowner: 69/69; alte Erwartungen an die Sternsystemdaten zuvor an
  die vorhandenen sieben Himmelskörper und Polisa-Ortsbindung angepasst.
- Flottenreise: 8/8; zwei unabhängige Flugzustände und gemeinsamer Tick.
- Echter Szenenpfad: 14/14, Auftrag/Boarding/Abflug/Warp, Heimatansicht,
  Sternkartenrückkehr und Abbruch; Renderbegrenzungen30/60/144.
- Root-/Takt-/Aufnahmecheck: 27/27; gekoppelt an den Fixture-Flugresolver.
- Warp-Owner/Root: 42/42 und7/7 nach Integration des Parallelstands.
- Isolierter Flugresolver8/8 und Rottenowner19/19; kein fertiger Kampffluss.
- Fixture-Flug über Root-Physiktakt 8/8; Root-Tick- und Batchregressionen
  ebenfalls erfolgreich. Produktive Schiffe bleiben für diesen Pfad gesperrt.
- Rottenpanel-Vorstufe 8/8, Adapter 9/9 und Sternkarten-UI 89/89;
  headless, keine native Sichtabnahme. Erstes Layout verschob vorhandene
  Aktionen aus dem Fenster; erneute Prüfung nach Umordnung erfolgreich.
- AP03 Kostenprobe: jeweils25 wiederholte, identische Einzel-Sweeps in einem
  headless Lauf. Einfeldjäger P95 106→93µs, dreizelliger Rumpf 833→442µs
  nach geometrischer Kandidatenbegrenzung; Dateien `space_sweep_cost_before.log`
  und `space_sweep_cost_after.log`. Einzelprobe bei laufender Fremdlast,
  keine Messung eines vollständigen Frames, kein allgemeiner FPS-Nachweis.

Die alte umfassendere Orbitfixture hat vier veraltete Satelliten-Orbitannahmen
und ist daher keine grüne Gesamtabnahme. Keine native Sicht-/Stil-, GPU-,
Leistungs- oder Mehrspielerfreigabe; keine Validierung des gesamten Kampfplans.
