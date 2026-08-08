# Contributing to TopDps

TopDps is structured so class/spec rotation logic is isolated from the generic engine and UI.

## Project structure

```text
Core/           namespace, constants, database, API wrappers, logging, settings
Rotation/       generic priority engine and action-bar services
Specs/          class/spec-specific providers
Presentation/   action-button highlighting and center-screen icons
UI/             options pages and minimap button
Vendor/         bundled third-party/adapted visual components
Textures/       addon textures
Bootstrap.lua   addon initialization and event wiring
TopDps.toc      addon manifest and load order
```

## Adding another class or specialization

1. Create a provider under `Specs/<Class>/<Spec>.lua`.
2. Implement the provider contract used by `Rotation/SpecRegistry.lua` and `Rotation/Engine.lua`.
3. Register the provider with `TopDps.SpecRegistry:Register(provider)`.
4. Add the file to `TopDps.toc` before `Bootstrap.lua`.

The current reference implementation is `Specs/Paladin/Retribution.lua`.

A provider currently exposes at least:

```text
id
categories
Initialize()
IsActive()
GetSpellCategory(spellId, spellName)
GetPriority(context)
IsCategoryAllowed(category, context)
CanTreatUnusableAsUsable(category, entry, context)
IsEntryInRange(actionBar, entry, category, context)
GetRecommendationName(category, entries)
```

Rotation changes for a specific specialization should normally stay inside its provider rather than being added to the generic engine.

## WoW 3.3.5a notes

- The addon targets interface version `30300`.
- The standard Interface Options addon panel is approximately `413x429` px; `UI/OptionsWidgets.lua` keeps controls inside that area and reserves room for scrollbars.
- `Core/GameApi.lua` contains compatibility wrappers for API differences found in 3.3.5a clients/private-server builds.
- The addon currently assumes standard Blizzard action bars.

## Debug page

The debug options page can be hidden globally in `Core/Namespace.lua`:

```lua
addon.SHOW_DEBUG_OPTIONS = false
```

When changing rotation detection or WoW API compatibility, enable debug logging and verify the recognized action IDs and recommendation state in-game.

## Versioning

The project uses semantic versioning. The initial public version is `0.1.0`.
