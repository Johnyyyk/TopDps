# TopDps

TopDps is a priority helper addon for World of Warcraft 3.3.5a.

Current version: **0.1.0**

## Supported specializations

- Paladin — Retribution

Support for additional classes and specializations is planned.

## Features

- Shows the next recommended ability on the standard Blizzard action bars.
- Blizzard and Cheese-style highlighting.
- Optional center-screen recommendation icons.
- Configurable display modes: everywhere, dungeons and raids, raids only, or disabled.
- Movable minimap button.
- Russian and English localization.
- Debug page with recommendation output and addon logs.

## Installation

1. Download the addon release.
2. Extract the `TopDps` folder into:
   `World of Warcraft/Interface/AddOns/`
3. Restart the game or run `/reload`.

The final path should look like:

```text
World of Warcraft/Interface/AddOns/TopDps/TopDps.toc
```

## Commands

- `/topdps` — open addon settings.
- `/td` — short alias.

## Compatibility

TopDps targets WoW **3.3.5a** and currently supports the standard Blizzard action bars.

## Development

Architecture, extension points and contribution notes are documented in [CONTRIBUTING.md](CONTRIBUTING.md).
