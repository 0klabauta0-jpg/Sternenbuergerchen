# Kontrollierte native NPC-Visualfixture

## Ziel und Ursache
Die normale Vollbildroute hat Flug und HUD nativ belegt, jedoch in ihrem
20-Sekundenfenster kein neues sichtbares Weaponfire-Ereignis geliefert.
Ein zusätzlicher, ausdrücklich kontrollierter Visualtest soll dieselbe
Figur gesund, verletzt, liegend, im Bleedout und nach Heilung/Respawn zeigen
sowie Flash, Schussglyph und deren Ablauf als native PNGs erfassen.

## Vertrag und Grenzen
Der neue Capture-Driver erweitert unverändert
`playtest_20261105_npc_combat_feedback_verifier.gd`; dessen 23 Assertions,
öffentliche Damage-/Heal-/Respawn-Aufrufe und synthetischer Weaponpayload
bleiben erhalten. Kamera und Belegoverlay sind ausschließlich testseitig.
Modell-/Weapon-/Unitidentität und tatsächlicher Zustand werden ausgelesen.
Keine Produktdatei und kein Actorpfad werden für diesen Beleg verändert.
Der Schuss ist ein synthetisches Visualereignis; die Bilder belegen weder
physisches Combat noch einen realen Schuss der normalen Mission.

## Akzeptanz und Prüfung
Root startet seriell im echten Vollbild auf dem aktiven Display bei 1x mit
isoliertem user://. Headless ist kein zulässiger Bildbeleg. Einblendung und
JSON nennen Fixturecharakter, Originalidentitäten, Display und Renderer.
Readbacks nahe Ereignisbeginn, nach mindestens 120 ms und nach über 850 ms
werden vor PNG-Encoding gesammelt; Istzeiten werden dokumentiert.
Die ursprünglichen 23 Assertions bleiben grün, eigene Captureprüfungen
werden gesondert gezählt. Visuelle Nutzerabnahme bleibt davon getrennt.

## Dateien, Dokumente und Risiken
Neu: `scripts/tests/playtest_20261105_npc_native_visual_capture.gd`.
Verbindlich: vier Kerndokumente, Vollbild-Playtestauftrag, Grafikreferenz-
und Unit-facing-Vertrag sowie der bestehende NPC-Feedback-Verifier.
GPU-Readbackzeiten können den 120-ms-Zielpunkt verzögern und werden deshalb
als Istzeiten ausgewiesen. Die frühe Schussaufnahme darf die ursprüngliche
300-ms-Flashassertion nicht durch PNG-Encoding verzögern.

## Native Ergebnisse
Rootlauf `output/playtest_20261105/npc_native_visual/20261105T081826Z-c460b66b`
mit Windows/Vulkan/Forward+, echtem **3440x1440**-Vollbild und **1x**:
**23/23** unveränderte Basisassertions sowie **19/19** Capturechecks,
Exit 0, keine Enginefehler und bestätigte isolierte Nutzerdaten.
Alle acht Gesundheitsbilder behalten `feedback_enemy` und dieselbe
Modellinstanz `105008597077`. Root hat Down/Bleedout tatsächlich angesehen:
die Originalfigur liegt horizontal, Zustandsglyphen sind sichtbar. Die
Schussbilder zeigen Flash und Glyph bei tatsächlichen **28 ms / 121 ms**;
bei **984 ms** sind Pulse, Flash und Glyph abgelaufen. Unabhängiger lesender
Driverreview meldet keine P1/P2.

Der Aufruf verwendete `--evidence-output=...`, während dieser neue Driver
das Leerzeichenformat liest. Daher liegen die Original-PNGs und das JSON im
isolierten Projekt unter `output/playtest_20261105/npc_visual_fixture_2677746*`;
Root übernimmt diese bytegleich in die zugehörige QA-Ausgabe. Vorhandene
Belege wurden nicht überschrieben. Der generische Runnerreport und das
23/19-Ergebnislog liegen bereits im oben genannten QA-Verzeichnis.

Die separate normale Route ist **77/77** grün unter
`output/playtest_20261105/native_visual_3440/20261105T075819Z-078ae826`.
Dort lautet `facts.real_weapon_temporal_capture.observed` ausdrücklich
**false**, Wartefenster **20 s**, kein neues sichtbares reales Ereignis.
Die synthetische Visualfixture schließt diese physische Combat-Prüflücke
nicht. Native Bildsichtung ist außerdem keine gestalterische Nutzerabnahme.
