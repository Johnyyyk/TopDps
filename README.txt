TopDps 2.0.1
=============

Installation
------------
Copy the TopDps folder to Interface\AddOns and run /reload.

Commands
--------
/topdps
/td
/rtd (legacy alias)

Architecture
------------
Core/
  Namespace.lua       Addon namespace and module factory.
  Constants.lua       Global configuration constants and defaults.
  Database.lua        SavedVariables validation and migration.
  GameApi.lua         Compatibility wrappers for WoW 3.3.5 APIs.
  Logger.lua          Debug log and protected calls.
  Settings.lua        Runtime setting changes.

Rotation/
  SpecRegistry.lua    Registry of supported class/spec providers.
  ActionBarService.lua Standard action-bar discovery and readiness checks.
  CombatTracker.lua   Approximate active enemy count.
  Engine.lua          Generic priority engine independent of class/spec.

Specs/
  Paladin/Retribution.lua
                      Retribution spell catalog, conditions, equipment
                      detection and priority tables. Rotation changes should
                      normally be made only in this file.

Presentation/
  HighlightManager.lua Selects the configured highlight renderer.
  BlizzardHighlight.lua Blizzard AutoCastShine renderer.
  CenterIcons.lua      Center-screen recommendation icons.
  RecommendationPresenter.lua
                      Connects the rotation result to all visual outputs.

UI/
  OptionsWidgets.lua  Shared 3.3.5 options-panel layout helpers.
  GeneralOptions.lua  Main settings page.
  DebugOptions.lua    Debug settings and log page.
  MinimapButton.lua   Minimap control.
  OptionsController.lua Options-page coordinator.

Vendor/Cheese/
  Original Cheese-style animation implementation and templates.

Adding another class or specialization
--------------------------------------
1. Create a provider under Specs/<Class>/<Spec>.lua.
2. Implement at least:
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
3. Register it with:
   TopDps.SpecRegistry:Register(provider)
4. Add the file to TopDps.toc before Bootstrap.lua.

Debug page
----------
Set this in Core/Namespace.lua to hide the debug page:

addon.SHOW_DEBUG_OPTIONS = false

Interface Options size
----------------------
WoW 3.3.5a uses a 413x429 addon panel container. OptionsWidgets.lua keeps
all text and controls inside this exact area and reserves space for scrollbars.

Notes
-----
The addon supports the standard Blizzard action bars. Priority logic is isolated in the spec provider. Version 2.0.1 also adds
3.3.5-specific action spell-ID compatibility and simpler Ret availability checks.
