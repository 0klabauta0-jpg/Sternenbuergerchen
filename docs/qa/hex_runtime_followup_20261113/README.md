# Hex-Fortsetzung — 13.11.2026

## Ausgang / Korrektur des alten Berichts
Der Reviewbranch8d0f9a597 enthielt den ursprünglichen Plan. Im getrennten
Karten-Kandidaten1b924b640 waren AP0–AP8 bereits opt-in integriert und begrenzt
geprüft: `docs/qa/ap678_bundle_20261112/` dieses Kandidaten dokumentiert genaue
Commitgrenzen. Der ältere Sourcezweig47fa17f51 ist keine geeignete neue Basis.
Diese APs wurden nicht doppelt gebaut oder pauschal erneut getestet.

Neue Arbeit auf `task/hex-enet-followup-20261113`, bewusst auf dem noch nicht
in Main integrierten Karten-/Hexkandidaten. Die bisherigen Reviewfixes und diese
Kandidatenarbeit sind verschiedene Branches; kein gemeinsam freigegebener Build.
Code und originale Evidenz sind in Commit `02e75d4f1` gesichert.

## Tatsächliche Weiterarbeit
Ein gültiger Remote-Move trägt die Truppkennung `fireteam_id: String`. Der
Movement-Savecodec wies dieses vorhandene Feld als unbekannt zurück. Der
belegte Produktfix ergänzt nur dieses Feld in dessen Stringallowlist.
Falsche Typen und unbekannte Zusatzfelder bleiben abgewiesen.

- Neuer tatsächlicher lokaler ENet-/Hexfall: **22/0**, Exit0. Echte UDPpeers und
  Command-/Result-/Snapshot-/Vital-RPCs, gültige Hexbewegung, fremder Kontext/
  fremdes Team, aktuelle Sicht und empfangene rohe DTOs vor Normalisierung.
- Exakter Root-JSON-Restore erhält die nächsten sechs Authoritywürfe nach
  fortgeschrittenem RNGzustand und das komplette gültige Commandfeld. Nur der
  Host konsumiert für den Queued-Damageeffekt einen Wurf; Clients spiegeln.
- Engster vorhandener Movement-Save-Nachbar: **30/0**, Exit0. Der neue Wrapper
  hatte zunächst einen falschen Marker. Dessen Auswertung wurde bei erhaltenem
  Originalreport separat berichtigt, kein zweiter Gameplaylauf behauptet.
- Finale Engine-/Script-/Leakprüfung sauber, Quellen/echtes Profil unverändert,
  private Canary grün. Root hat sämtliche90 übergebenen Quellenhashes selbst
  geprüft; siehe `summary.json`. Unabhängiger Patch-/Testreview clean.

## Rohbelege
`summary.json` verweist auf die geprüften Einzelreports. `candidate/` enthält
unveränderte Kopien der isolierten Läufe und die genaueren Teilagentennotizen.
Der Nachbar-Zusatzreport enthält den Hash des unveränderten Originaloutputs.
Rote Vorläufer bleiben rot; ihre Sicht-/Actorcapability-Fixturefehler werden
getrennt vom tatsächlich behobenen Savecodecfehler erklärt.

## Grenzen
Ein headless Prozess, zwei echte lokale Peers, sechs Felder, Capability-NPCs,
QuietDriver und manuelle Rootticks; kein menschlicher vollständiger Spieltest.
Der Rootrestore erfolgt am identischen Simulationstick nach RNGreads. Kein
Nachweis für Rejoin oder Live-Mehrspielerrestore mit rückwärts laufenden Ticks.
Keine neuen D6-/Rüstungs-/Balance- oder Orbitalregeln. Produktionskarten bleiben
unaktiviert; große AP9-/A/B/C-/GPU-/FPS-/LAN-/Internet-/Paketverlustabnahme offen.
Keine Mainintegration oder EXE. Der temporäre Wachhalteprozess verändert keine
dauerhaften Energieeinstellungen und wird nach dem Auftrag beendet.

## Bericht
`docs/reports/SPIELREVIEW_2026_11_12.html` enthält die Fortsetzung vom13.11.
Die ursprünglichen26Reviewgates bleiben als historische eigene Basis erkennbar.
Offline/file://, Handybreiten, Tabs und JSON-Export werden erneut geprüft.
