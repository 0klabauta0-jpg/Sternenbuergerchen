# Mainintegration — 13.11.2026

Gezielter Port ab origin/main b1f47750b auf task/main-integration-hex-review-20261113.
Keine pauschalen Merges alter Kandidatenbäume; aktuelle Main-Save-/Orbit-/
Sternkartenowner erhalten. Fremdes WIP in C:/dev/SternenBuergerchen unangetastet.

## Frisch geprüfter Mainverbund
Fünf Gruppen, **207 Assertions, 0 Fehler**. Einzelreports in summary.json.
Alle Exit0, Marker, Source-/Originalprofil-/Canaryguards grün, keine finalen
Engine-/Scriptfehler oder Leaks. Erwartete UID-/Negativwarnungen in Rohlogs.

- Hex/ENet24/0: echte Peers sowie zwei Legacy-Driver-Sichtnachbarn.
- MovementSave30/0: frischer tatsächlicher Mainlauf.
- Mehrschiff57/0: reale Continue-Szenen, Pilot aus Schiff2, beide Payloads,
  partielle/geteilte Teams und tatsächliche Flug-/Landekommandos.
- Save-UI16/0: echte Kampagnendelegation/Continue getrennt von Szenenbookmarks,
  Hauptmenügrenzen, weiterlaufende Physik.
- Aktiver Missionssave80/0: echter Einsatz, Save, frisches Fortsetzen,
  Heimkehr, Chipupload und neuer Heimcheckpoint bei erhaltenem Altfile.

Der frische erste ENetlauf21/1 belegte einen fehlenden Main-Driveranschluss:
Groundfacing und Wiretick waren aktuell, rückwärtiger Gegner blieb sichtbar.
Der bestehende HexSightAdapter ist nun additiv angebunden, Legacyfallback
erhalten. Keine ganzen alten Driver-/Cache-/Rootkörper übernommen. UI-ROT9/7
vor kontextsensitivem Port dokumentiert. Frühe Runnerrefusals wegen fehlendem
Hilfsmodul/privater Testprofilkennung sind keine behaupteten Produktfehler.

## Importgrenze / Cache
Vollständiger Editorimport endete beim Fontreimport mit Exit1 ohne abschließende
Diagnose: kein sauberer Import-PASS. Originale Logs unverändert in import_logs.zip,
SHA256 in summary.json. Assets/Addons unverändert zu Main3446f3040 und aktuellem
Main; kein Asset-/Map-/Shaderdelta. Fehlende reine Importcachedateien lesend aus
dessen vorhandenem Mainworktree kopiert (cache_seed.json), Quelle unverändert.
Danach tatsächliche Runtimechecks mit eigenem geschütztem user:// bestanden.
Keine neue EXE-/GPU-/vollständige frische Editorabnahme.

## Weitere Grenzen
Keine neue Kartenaktivierung, Würfel-/Kampf-/Orbitalbalance, komplette
Live-Peer-Restore-/Rejoin- oder große AP9-/FPS-/Internetabnahme. Historische
Sourcebelege bleiben von frischen Mainreports getrennt. Testprofile und Cache
werden nicht eingecheckt. HTML-Workbench wird erneut offline/mobil/JSON geprüft.
