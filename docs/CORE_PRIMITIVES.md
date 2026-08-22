# Универсальные примитивы ядра

Этот документ фиксирует минимальный общий API, добавленный по результатам аудита #26 перед массовым добавлением специализаций WotLK 3.3.5a.

Цель — вынести в Engine только повторяющиеся игровые механики. Правила конкретного класса или специализации по-прежнему должны оставаться в `Specs/<Class>`.

Полноценные rotation provider'ы предназначены только для DPS-специализаций. Для healer/tank-спеков TopDps использует панель подсказок и состояний: обязательные бафы/состояния, проки, defensive/utility cooldown'ы и другие ситуационные элементы.

## UnitStateService

`Engine/UnitStateService.lua` централизует чтение состояния юнитов:

- здоровье: current / maximum / missing / fraction / percent;
- текущий основной ресурс юнита;
- чтение конкретного power type при необходимости;
- тип активного ресурса;
- regen основного ресурса игрока через `power.regen.base/casting`;
- combo points игрока на текущей цели;
- level / class / classification / creature type;
- connected / dead / deadOrGhost / inCombat / isPlayer;
- attackable;
- boss-like состояние.

Снимок игрока дополнительно содержит состояние движения:

```lua
context.player.movement = {
    speed = number,
    moving = boolean,
    falling = boolean,
}
```

`moving` считается активным при ненулевой скорости или падении. Core только предоставляет этот факт; решение о mobile-priority остаётся за DPS provider'ом. Правила интеграции, instant-proc edge cases и per-spec настройка описаны в `docs/ROTATION_MOVEMENT.md`.

`ContextBuilder` публикует готовые снимки как `context.player` и `context.target`, а сам сервис как `context.unitState`.

Руны DK намеренно не входят в этот сервис: их отдельные cooldown-состояния являются class-specific механикой и должны жить в `Specs/DeathKnight/Common`.

## CastService

`Engine/CastService.lua` читает текущий cast/channel юнита и нормализует старую 3.3.5a и более новые/private-core раскладки return values, включая варианты с отсутствующим `notInterruptible`.

Состояние содержит:

- active;
- name / icon;
- spellId / castId, когда клиент их предоставляет;
- isChannel;
- startTime / endTime;
- duration / remaining;
- notInterruptible, если клиент предоставляет это значение.

Для каналов доступен `GetChannelTickState(state, tickCount)`. Спек передаёт только количество тиков конкретного channel spell, а Core вычисляет:

- tickDuration;
- completedTicks;
- nextTickIndex;
- nextTickAt;
- nextTickRemaining.

Это позволяет Mind Flay / Drain Soul / Arcane Missiles-подобной логике принимать решение о clip между тиками без class-specific таймера в Core.

В `context.cast` находится состояние текущего каста игрока. Решение о том, можно ли прерывать канал или начинать следующий spell заранее, остаётся за specialization provider.

## SwingService

`Engine/SwingService.lua` предоставляет:

- скорость main-hand/off-hand;
- время последней известной автоатаки;
- расчётное время следующей автоатаки;
- remaining до следующего swing;
- `IsActionQueued(action)` для next-swing abilities вроде Heroic Strike / Cleave / Maul.

Сервис получает исходящие `SWING_DAMAGE` / `SWING_MISSED` из combat log и реагирует на `UNIT_ATTACK_SPEED`. При изменении haste текущий таймер масштабируется по уже пройденной доле swing, а не пересчитывается как `lastSwing + newSpeed`.

На ядрах, где combat log отдаёт явный `isOffHand`, используется он. На ядрах без этого поля dual-wield рука определяется по состоянию двух swing-таймеров: первый неизвестный удар считается main-hand, второй — off-hand, затем выбирается рука с более ранним ожидаемым swing. Сразу после `/reload` посреди dual-wield боя до наблюдения обеих рук точность этого fallback ограничена самим API.

Способности, которые заменяют/сбрасывают автоатаку и поэтому приходят как spell-события, объявляются в spec metadata:

```lua
ability = {
    spellIds = { ... },
    swingReset = "MAIN_HAND", -- MAIN_HAND / OFF_HAND / BOTH
}
```

Core не знает ID Heroic Strike / Cleave / Maul / Raptor Strike и подобных способностей. Он только применяет универсальное `swingReset`.

## EquipmentSetService

`Engine/EquipmentSetService.lua` умеет:

- найти надетые предметы из переданного набора item ID;
- посчитать количество совпадений;
- проверить достижение требуемого количества частей.

Списки конкретных T7/T8/T9/T10 и правила их влияния остаются в классе/спеке.

## Active enemy count

Старое имя `enemyCount` было слишком сильным: `CombatTracker` не знает реальное количество противников в радиусе AoE. Он знает только цели, которые недавно участвовали в боевых событиях с игроком, его pet/guardian или текущей атакуемой целью.

Поэтому основной контракт теперь называется:

- `CombatTracker:GetActiveEnemyCount()`;
- `context.activeEnemyCount`.

`context.enemyCount` и `CombatTracker:GetEnemyCount()` временно оставлены как compatibility alias для существующих специализаций.

Текущая дружественная цель не добавляется в счётчик. Pet и собственные guardians учитываются через GUID/`COMBATLOG_OBJECT_AFFILIATION_MINE`, когда ядро предоставляет соответствующие flags.

Это значение следует воспринимать только как автоматическую эвристику, а не как точный spatial scan.

## Нестандартный refresh

Обычный `ability.refresh` по-прежнему работает декларативно через остаток ауры и `lead`.

Для механик, которые нельзя выразить только временем окончания, определение может добавить:

```lua
isRefreshDue = function(context, aura, remaining, lead)
    -- true  -> эффект пора обновлять
    -- false -> эффект обновлять нельзя/не нужно
    -- nil   -> использовать стандартную логику RefreshService
end
```

Callback валидируется при создании provider. Это escape hatch для snapshot/overwrite/indirect-refresh механик. Отдельный SnapshotService намеренно не добавляется, пока несколько реальных специализаций не докажут необходимость общего stateful tracker.

## Автоматические проверки

`tools/test_core_primitives.lua` проверяет через Lua 5.1 наиболее рискованные runtime-контракты:

- legacy и alternative/private layout `UnitCastingInfo` / `UnitChannelInfo`;
- расчёт тиков channel;
- fallback определения dual-wield рук;
- явный off-hand flag;
- сохранение прогресса swing при изменении attack speed;
- `ability.swingReset` и queued action.

`tools/test_movement_priority.lua` отдельно проверяет movement state, private-core fallback и movement-aware приоритеты существующих Warlock provider'ов. `tools/test_movement_backlash.lua` покрывает instant-cast `Incinerate` от Backlash на движении.

Все smoke-тесты запускаются в общем workflow `Проверка проекта` после Lua syntax check.

## Что намеренно остаётся вне Core

- DK rune model;
- Shaman totem model;
- Hunter/Warlock pet policy;
- stance/form/presence/seal/aspect rules;
- позиционные проверки конкретных способностей;
- snapshot rules конкретного DoT;
- конкретные execute/resource thresholds;
- mobile-priority конкретной специализации: Core сообщает только состояние движения;
- healer/tank rotation logic и выбор friendly-target: для этих ролей используется ситуационная панель, а не RotationEngine.

Для них Core предоставляет факты, а решение принимает class/spec-код либо соответствующий panel definition.
