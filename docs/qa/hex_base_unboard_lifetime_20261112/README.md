# AP6: Screenlebensdauer nach erfolgreichem Gruppencommit

Direkter Integrationsreviewbefund zu `d2466d512`: Ein Observer des gemeinsamen
Basisereignisses kann den vorbereiteten Screen freigeben oder ersetzen. Der alte
Caller sprach anschließend die mutable `_screen`-Property mit dem alten Handle an.

Tatsächlicher vollständiger Screen und Basis-/Rootpfad wie in der vorherigen
Unboardprobe. Die Freigabe reproduziert den echten Produktfehler
`Cannot call method 'call' on a previously freed instance` im Basisunboardkörper.
Separater sauberer Assertion-RED44/1 beweist die falsche Finalisierung am Ersatz.

Vor Publikation werden Owner und vorbereiteter Screen als WeakRef gebunden.
Nach dem Basisereignis wird nur derselbe noch lebende, nicht zur Freigabe
vorgemerkte und weiter zugeordnete Screen finalisiert. Bereits bestätigter
Modellerfolg bleibt bestehen, ohne erneute Payloadänderung oder Rollback.

GREEN46/0: bisherige vollständige Publikation, Ticketcancel, Screenfree und
Ersetzung. Unmittelbarer tatsächlicher Boardingnachbar53/0, Quellen-/Isolations-
und Originalprofilguards grün. Originalausgaben einschließlich Produktfehler im
ZIP; Quellhashes im Manifest. Keine große Kampagnen-/Grafik-/Save-/MP-/FPSprobe.
