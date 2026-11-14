# Windows R2 – 2026-11-14

Quelle: `8571be32c9502669a313dbdb2e2a67729257646e`, Godot 4.6.2. Exportpipeline Exit 0; Startcheck `pass`. Paket-README nennt R2 und die [öffentliche Anleitung](https://sternenbuergerchen-spielanleitung.klabauta.chatgpt.site).

Paket: `C:\dev\SternenBuergerchen-releases\2026-11-14-r2-8571be32c`.
ZIP: `C:\dev\SternenBuergerchen-releases\SternenBuergerchen-Windows-R2-2026-11-14-8571be32c.zip` (188699405 Bytes).
SHA256: `020c3a4966febbb700d4de824401c5497806f268ac38a3db70d44426ab6522fa`.

Die tatsächlich exportierte EXE startete ihren normalen Einstieg headless mit isoliertem APPDATA und beendete sich nach 120 Frames mit Exit 0 (2,21 Sekunden). Keine Enginefehler oder Leaks; echtes Benutzerprofil unverändert. Keine Desktopbedienung.

Alle acht ZIP-Mitglieder sind vollständig gegen die Paketdateien hashgeprüft: EXE, Konsolenstarter, PCK, zwei GDExtension-DLLs, README, Buildprovenienz und SHA256SUMS. Provenienz und PCK-Hash stimmen. R1-ZIP ist unverändert. `build_summary.json` enthält alle Einzelhashes; `package_smoke.json` und `start_check.json` dokumentieren die Paketprüfung. Das rohe Exportlog bleibt lokal; sein Hash und die kompakte Auswertung liegen in `export_log_summary.json`.

Produktnachweise vor Export: 81 Kernprüfungen, 25 native Prüfungen und drei gezielte bestehende Regressionen bestanden (siehe ../map_services_20261114). Paketprüfung ist ein begrenzter Startnachweis: kein grafischer EXE-Spielablauf, kein vollständiger Fünfmissionen-Sieg, keine allgemeine WAN-/FPS-Abnahme.
