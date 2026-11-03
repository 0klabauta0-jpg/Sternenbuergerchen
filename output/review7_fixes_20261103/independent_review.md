# Unabhaengiges Nachreview REVIEW7

Basis: Main `668423dcf5b76a7b7bb1010ae59337376911522e`.
Task: `docs/tasks/REVIEW7_2026_11_03_performance_architecture_fixes.md`.
Enddiff: `final_tracked.diff`; Produkt-/Test-/Harnessfingerprints: `final_source_snapshot.json`.

## Ergebnis

APPROVED fuer die sieben kommentierten Befunde. Zwei voneinander getrennte
Nachreviews auf dem finalen Source finden keine offenen Must-fixes.
Die breite Abschlussmatrix und der abschliessende native Wiederholungslauf
werden vom Root getrennt ausgewertet.

## Pruefgrenzen und gefundene Nachkorrekturen

- Separation: eigener Implementierer, unabhaengiger Geometrie-/Runtime-Nachreview.
  Kein zweites Hoehenregelwerk: tatsaechliche Segmentzellen lesen ausschliesslich
  `TerrainPathfinder.can_traverse_step`. Kosten proportional zur Korrekturlaenge,
  keine Kartenvollenumeration. Getestet sind beide Topologien, H1/H2 auf/ab,
  Halb-/Vollkorrektur, legale Haenge, Zwischenloecher, Square-Diagonalen und
  ein versetztes Segment mit vom Centerline-Pfad uebersehenem Blocker.
- Multiplayer: unabhaengiger Review des echten UI-Consumers fand die fehlende
  Prompt-Aktualisierung und den weiterhin falschen Default-Maplaunch. Beide
  sind korrigiert und mit echten ENet-Lobbys plus geladener TerrainRegistry
  abgesichert. Alte Offers, lokale Client-Hostsetter, Snapshotflag und Start-RPC
  koennen die lokale Consentgrenze nicht freigeben. Versus-/Reconnectfixes
  einschliesslich zweiter Mission gegengeprueft.
- Kamera/Animation: anderer Reviewer bestaetigt stabile Kontaktidentitaet und
  echten Animationstime-Fortschritt als Redrawgrund. Keine Bonescans im Hotpath.
  Laufende Animationen verursachen notwendige Renderarbeit; keine FPS-Zusage.
- FoW: getrennte Nachreviews fanden und schlossen drei Consumer-/Jobluecken:
  Targetupdates starteten den echten Overlay neu; harte Inputwechsel konnten
  unmittelbar vor Commit durchrutschen; reine Observerbewegung konnte Jobs
  staendig verwerfen. Positionsstichproben werden nun fertiggestellt und
  ehrlich mit ihrer eigenen Signatur publiziert. Neueste Positionen folgen
  getaktet; harte Inputs invalidieren vor dem naechsten Slice.
- Fortlaufende +1-Deltas aktualisieren bereits vorhandene Slots waehrend des
  Initialbuilds. Restliche Initialslices lesen den neuesten vollstaendigen State.
  Die Safetyabdeckung bleibt bis zum Initialabschluss; eine Revisionsluecke
  benoetigt einen Fullbuild. Dies ist mit echtem View, nicht nur Sink, geprueft.

## Renderingnachweis

Headless-Dummy kann gesetzte MultiMeshfarben und Transformationen nicht
zuruecklesen: ein unabhaengiges Eininstanz-Objekt liefert Alpha 1/Origin 0
statt gesetztem Alpha 0/Origin (5,7,11). Diese Diagnose blieb als Rohlog erhalten.
CPU-Tilestates, vollstaendige eindeutige Slots, Meshidentitaet, Cursor und
Safetylebensdauer sind auch headless zwingend. Der native Gate verlangt
zusaetzlich funktionierendes GPU-Pufferruecklesen und prueft echte Alphawerte.

Erster nativer Beleg: D3D12/Forward+, RTX 4070 Ti SUPER, 39/0, drei echte
1920x1080-SubViewport-PNGs. Root sah 128/2048, der unabhaengige Reviewer alle drei:
sichtbare Tiles und erkundete Spur innerhalb des unbekannten schwarzen Gebiets,
keine verbleibende globale Safetyabdeckung. Feste Karte/Kamera; keine
Langzeit-, FPS-, Gesamtspiel- oder Releaseabnahme.

## Bewusste Grenzen

TASK228 laesst den Netzwerk-Payloadtransport ausdruecklich ausserhalb V1.
Der Acceptbutton wartet weiterhin auf Payload; der existierende explizite
Payload-API-Pfad ist validiert. Kein neuer Download-RPC oder Assettransfer.
Terrainrevisionen sind atomare Stichproben und koennen waehrend Bewegung
zeitversetzt sein. Der initiale Vollscan ist kein 350-ms-Dirty-Budgetnachweis.

Die Originalrosterdatei ist unabhaengig in Hash, Laenge und Schreibzeit
geschuetzt. Kein Reviewer startete Engines, aenderte Nutzerdaten oder Git.

## Zusaetzlicher Belegaudit

Ein dritter Reviewer bestaetigte 114 unveraenderte Fingerprints, den mit Main
byte-identischen Isolationsrunner und 1672/1672 archivierte Originalskript-/
Projektdateien gegen Git `668423dcf`. Die drei Fehler der vorlaeufigen Matrix
gleichen der Originalbaseline in Fehlertext, Assertionzahlen und Exitcode:
TASK839 29/2, TASK1122 9/2, Lobby-/Assetfollowup 35/3. Keine Timeouts.
Der Summaryhelfer prueft Manifestnamen und Reihenfolge, alle Isolationsflags,
eindeutige Userpfade, Rosterwerte und einen nativen Wiederholungsstart erst nach
Abschluss der finalen Matrix. Endzaehlen und finale Belege werden im Index
`verification_summary.json` festgehalten.
