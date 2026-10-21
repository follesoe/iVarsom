# Localization style guide

The app ships in English, Norwegian Bokmål, Swedish, German, Spanish, French and Italian. Keys in `Localizable.strings` are the original English text; the English file's values are what English users see, so an English wording change edits the value, not the key. Keep every language's files in sync: the same keys, in the same order, with placeholders (`%@`, `%lld`, `${region}`) preserved. Siri phrases live in `AppShortcuts.strings`; once shipped, a phrase is a public contract, so add phrases rather than rewording them.

## Terminology

| Concept | en | nb | sv | de | es | fr | it |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Daily bulletin | forecast | varsel | prognos | Vorhersage | predicción | bulletin | bollettino |
| Region | region | region | område | Region | región | région | regione |
| Emergency warning | emergency warning | nødvarsel | akut varning | Notfallwarnung | aviso de emergencia | alerte d’urgence | avviso di emergenza |
| Danger level | danger level | faregrad | faronivå | Gefahrenstufe | nivel de peligro | niveau de danger | grado di pericolo |
| Avalanche problems | avalanche problems | skredproblemer | lavinproblem | Lawinenprobleme | problemas de avalanchas | problèmes avalancheux | problemi valanghivi |
| Exposed aspects | exposed aspects | utsatte himmelretninger | utsatta väderstreck | betroffene Hangrichtungen | orientaciones afectadas | orientations concernées | esposizioni coinvolte |
| Treeline | treeline | tregrensen | trädgränsen | Waldgrenze | límite del bosque | limite forestière | limite del bosco |
| Location | location | posisjon | plats | Standort | ubicación | position | posizione |

English avoids "warning" for the daily bulletin: in English it suggests an alert, even at Low danger. Danger level names follow the European Avalanche Warning Services (EAWS) for each language, for example Spanish level 2 is "Limitado", not "Moderado". Say "danger", not "risk" (EAWS terminology).

## Conventions

- English uses title case for buttons, menu items, titles and App Shortcut names ("Add to Favorites", "Share Summary"), and sentence case for body text and status labels ("Loading regions…"). Other languages use their own capitalization (sentence case, with German nouns capitalized).
- Address people as Apple does in each language: du (de), tú (es), vous (fr), tu (it); nb and sv use du.
- Use the ellipsis character (…), with a non-breaking space before it in German. Use typographic apostrophes (’) in app strings.
- Links don't end with a period. Error descriptions that Siri may read are full sentences.
- US English spelling (meters, color, Northeast).
- New user-visible strings need entries in all seven languages, including App Intents titles, parameter names and dialogs (`LocalizedStringResource` keys).
