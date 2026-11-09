# Heimatbasis: Originalraeume und groessere Karte

Nutzerkorrektur: Die Heimatbasis soll gross bleiben und die vorhandenen huebschen kleinen Raeume zeigen. Die einfache Behandlung war fuer den Handelsposten gedacht.

## Ursache und Korrektur

Die Kampagne hatte eine22x24-Karte mit nur einem Gebaeudebereich erhalten. Zusaetzlich blendete die Basisdarstellung beide moeblierten Original-GLBs aus und baute stattdessen leere Hex-Wandkandidaten. Das wird korrigiert:

- Kampagnenbasis wieder36x28, beide Gebaeudebereiche und beide stabilen Pad-Flaechen.
- Habitat- und Hallenmodell aus `structures_pass04` wieder sichtbar, mit ihrer bestehenden Inneneinrichtung und ihren bestehenden Materialien.
- Keine zusaetzlichen kahlen Ersatzwaende in der Basis. Originalmeshes bleiben unveraendert.
- Zwei NPCs und ein Startschiff bleiben erhalten. Keine neue Kampagne und kein Reset bestehender Spielstaende erforderlich.
- Handelspostenkarte und Gameplay-/Save-Owner unveraendert.

## Referenzstatus und Grenzen

Erhaltene historische native Quellenaufnahme: [moeblierte Raeume](../../reports/assets/grafik-2026-11-01/engine_pass07_paths/after/cutaway.png). Dies ist eine Vorlage, keine frisch gerenderte Nachheraufnahme. Modell-/Bildquellen mit SHA256: [sources.json](sources.json).

Die gespeicherten Navigations-/Wand-/Tuerfakten wurden beibehalten. Deren technische Erreichbarkeit ist geprueft; das beweist keine pixelgenaue native Passung von Originalmodell, Moebeln, Tueren und Laufwegen. Es gab keine neue native Fenster-/Gestaltungsabnahme, damit der Nutzer seinen PC weiter benutzen kann. Die Originalmodelle wurden nicht umgebaut und keine neue Grafikvariante erfunden.

## Verifikation

RED am Ausgangsstand:3 bestanden/13 fehlgeschlagen. Danach:

| Pruefung | Ergebnis |
| --- | --- |
| Tatsaechliche Basisinstanzen Kampagne und Skirmish:36x28, zwei sichtbare unveraenderte Originalmodelle, keine Ersatzwaende |16/0 |
| Kampagnenkarte und Terminal-/Padpfade |9/0 |
| Bestehende Basis-Innenraeume, Tueren, Waende und echtes Commander-Laufen |139/0 |
| Echter Kampagnenstart, zwei NPCs und erster Checkpoint |11/0 |
| Geaenderte Vorbereitung und echtes Fortsetzen |10/0 |

Alle Exit0, headless/private Profile/niedrige Prioritaet, keine sichtbaren Fenster oder Fokuswechsel. Rohlogs unter `raw/`. Read-only Review ohne blockierenden Codebefund: [review.md](review.md). Die dort benannten veralteten Vertrags-/Statusbeschreibungen wurden nachgezogen.

Lokale Mainintegration und aktualisierter Testbuild werden im zugehoerigen Buildbericht ausserhalb des Repositorys dokumentiert. Kein Push.
