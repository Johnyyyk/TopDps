# Универсальные примитивы ядра

Этот документ фиксирует минимальный общий API, добавленный по результатам аудита #26 перед массовым добавлением специализаций WotLK 3.3.5a.

Цель — вынести в Engine только повторяющиеся игровые механики. Правила конкретного класса или специализации по-прежнему должны оставаться в `Specs/<Class>`.

## UnitStateService

`Engine/UnitStateService.lua` централизует чтение состояния юнитов:

- здоровье: current / maximum / missing / fraction / percent;
- текущий основной ресурс юнита;
- тип ресурса;
- combo points игрока на текущей цели;
- level / classification / creature type;
- boss-like состояние;
- dead / attackable.

`ContextBuilder` публикует готовые снимки как `context.player` и `context.target`, а сам сервис как `context.unitState`.

Руны DK намеренно не входят в этот сервис: их отдельные cooldown-состояния являются class-specific механикой и должны жить в `Specs/DeathKnight/Common`.

## CastService

`Engine/CastService.lua` читает текущий cast/channel юнита и возвращает:

- active;
- name / icon;
- isChannel;
- startTime / endTime;
- duration / remaining;
- notInterruptible, если клиент предоставляет это значение.

В `context.cast` находится состояние текущего каста игрока. Решение о том, можно ли прерывать канал или начинать следующий spell заранее, остаётся за specialization provider.

## SwingService

`Engine/SwingService.lua` предоставляет:

- скорость main-hand/off-hand;
- время последней известной автоатаки;
- расчётное время следующей автоатаки;
- remaining до следующего swing;
- `IsActionQueued(action)` для next-swing abilities вроде Heroic Strike / Cleave / Maul.

Сервис получает исходящие `SWING_DAMAGE` / `SWING_MISSED` из combat log и реагирует на `UNIT_ATTACK_SPEED`.

У различных 3.3.5a/private-server ядер payload combat log может отличаться наличием `isOffHand`. Если off-hand нельзя определить однозначно, событие консервативно считается main-hand: сервис не должен выдавать ложную точность.

## GroupService

`Engine/GroupService.lua` предоставляет общий доступ к party/raid:

- список unit token'ов;
- снимки состояния участников;
- подсчёт наличия ауры;
- список участников без ауры;
- подсчёт участников ниже заданного HP threshold;
- поиск участника с минимальным относительным HP.

Сам сервис не принимает решений для хилов и не выбирает spell. Он только даёт данные specialization-level логике.

## EquipmentSetService

`Engine/EquipmentSetService.lua` умеет:

- найти надетые предметы из переданного набора item ID;
- посчитать количество совпадений;
- проверить достижение требуемого количества частей.

Списки конкретных T7/T8/T9/T10 и правила их влияния остаются в классе/спеке.

## Active enemy count

Старое имя `enemyCount` было слишком сильным: `CombatTracker` не знает реальное количество противников в радиусе AoE. Он знает только цели, которые недавно участвовали в боевых событиях с игроком, плюс текущую цель.

Поэтому основной контракт теперь называется:

- `CombatTracker:GetActiveEnemyCount()`;
- `context.activeEnemyCount`.

`context.enemyCount` и `CombatTracker:GetEnemyCount()` временно оставлены как compatibility alias для существующих специализаций.

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

Это escape hatch для snapshot/overwrite/indirect-refresh механик. Отдельный SnapshotService намеренно не добавляется, пока несколько реальных специализаций не докажут необходимость общего stateful tracker.

## Что намеренно остаётся вне Core

- DK rune model;
- Shaman totem model;
- Hunter/Warlock pet policy;
- stance/form/presence/seal/aspect rules;
- позиционные проверки конкретных способностей;
- snapshot rules конкретного DoT;
- выбор цели лечения;
- конкретные execute/resource thresholds.

Для них Core предоставляет факты, а решение принимает class/spec-код.
