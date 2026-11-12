# AP6: atomare Ausstiegspublikation am tatsächlichen Screen

Tatsächlicher vollständiger HomebaseScreen, AircraftManager, Baseowner,
Baseactors, Root/Ground und Registry. Nur Screen-Ready, Rebuild und Sichtbarkeits-UI
sind unterdrückt. Keine extrahierten Produktkörper. Kleine private Sechsfeldprobe
und geerbte zwölf Felder der Movebasis, keine Kampagnen-/Hauptszene.

Echter beobachtbarer Fehler des Integrationsstands `f0c65cf74`:

- Ohne Ticketcancel: Aufruf erfolgreich, Screenobserver sieht `[false]`, die zwei
  einzelnen Basisereignisse sehen `[false,true]` statt einer vollständigen Gruppe.
- Mit synchronem Ticketcancel aus dem tatsächlichen Screen-Kontextsignal:
  Payload ist entfernt, Groundcommit lehnt `admission_ticket_unavailable` ab;
  Screenobserver `[false]`, keine Basisereignisse, Personen weiterhin an Bord.

Sauberes RED42/2, auch mit ursprünglichem Unboardkörper gezielt und mit
ausgegebenen Observerdaten reproduziert. Dieser alte Körper wurde danach wieder
durch den aktuellen Fix ersetzt. Der neue additive Screenvertrag aus Parent
`7855ee949` liegt als `f47e66c1e` vor; alte Handler wurden nicht ersetzt.

Nach vollständiger Vorvalidierung committet Root Ground ohne Actormetadaten oder
Transforms. Anschließend folgen stiller Payloadtail und alle Basiszustände ohne
einzelne Signale. Erst dann Actorprojektion, ein Basisereignis und Screenfinalize.
GREEN44/0: beide Fälle sehen Screen`[true]`, Basis`[true]`, erfolgreichen Abschluss.
Unmittelbare Boarding-/Ownernachbarn53/0 und63/0, alle Quell-/Originalprofilguards.

Ein privater Editorimport stürzte vor dem Runtime-/Isolationsmarker ab
(Exit3221226356, zusätzlich Unicodeausgabeproblem des Pythonterminals).
Dieser Originalversuch ist enthalten und kein GREEN. Ein unveränderter
Wiederholungslauf mit UTF-8-Terminalausgabe besteht. Keine Behauptung einer
allgemeinen Engine-, Grafik-, Save-, Multiplayer-, FPS- oder EXE-Abnahme.
AP6 Setup/Respawn/Member-Retirement und AP7/8 bleiben weitere Arbeit.
