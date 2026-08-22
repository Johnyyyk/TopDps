# Movement-aware ротации

Этот документ описывает контракт движения игрока и правила его использования в DPS rotation provider'ах.

## Граница ответственности

Core только сообщает факт движения. Он не решает, какие способности конкретного класса можно или выгодно использовать на ходу.

`UnitStateService:GetPlayerSnapshot()` публикует:

```lua
context.player.movement = {
    speed = 0,
    moving = false,
    falling = false,
}
```

- `speed` — текущая скорость игрока из `GetUnitSpeed("player")`;
- `falling` — состояние `IsFalling`;
- `moving` — `true`, если скорость больше нуля или игрок падает.

Для совместимости с private core чтение API выполняется безопасно. Если `GetUnitSpeed` отсутствует или завершается ошибкой, скорость считается нулевой. Для старых реализаций `IsFalling`, которые не принимают unit token, Core повторяет вызов без аргумента. Если получить состояние невозможно, используется безопасный fallback `moving = false`.

## Настройка specialization provider

Movement-aware поведение не должно включаться глобально для всех специализаций. Provider добавляет настройку только если для него действительно реализован отдельный приоритет на ходу:

```lua
{
    type = "checkbox",
    key = "useMovementPriority",
    labelKey = "ROTATION_USE_MOVEMENT_PRIORITY",
    default = true,
}
```

Настройка хранится существующим per-spec механизмом. При `false` provider обязан полностью игнорировать `context.player.movement` и возвращать обычный приоритет без изменения поведения.

Спеки, которым отдельная логика движения не нужна, не должны добавлять этот checkbox. Например, Retribution Paladin в текущей реализации его не имеет.

## Реализация в provider

Типовой шаблон:

```lua
local PRIORITY = {
    -- обычная ротация
}

local PRIORITY_MOVING = {
    -- только действительно применимые на ходу действия
}

local function IsMovementPriorityActive(provider, context)
    return provider:GetSetting("useMovementPriority") ~= false
        and context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true
end

function Provider:GetPriority(context)
    if IsMovementPriorityActive(self, context) then
        return PRIORITY_MOVING
    end

    return PRIORITY
end
```

Movement priority не должен быть механическим списком всех instant-способностей класса. В него входят только действия, которые имеют смысл в PvE-ротации конкретного спека. Class/spec-specific условия по-прежнему реализуются через `IsCategoryAllowed`, `GetReadyEntries` и другие provider callbacks.

Важно учитывать не только способности с постоянным instant cast, но и временные эффекты, которые делают обычный hard-cast мгновенным. Если такой proc существует, категория может оставаться в `PRIORITY_MOVING`, но `IsCategoryAllowed` обязан разрешать её только при активном proc.

## Текущие Warlock provider'ы

### Demonology

На ходу используется последовательность:

1. `Life Tap` — только если существующая логика требует обновить Glyph of Life Tap;
2. выбранное `Curse` — только если требуемое проклятие отсутствует;
3. `Corruption` — только если собственная Corruption отсутствует.

`Immolate`, `Shadow Bolt`, `Incinerate` и `Soul Fire` не рекомендуются movement-priority, потому что в стандартном Demonology PvE-билде они требуют остановиться для каста.

### Destruction

На ходу используется последовательность:

1. `Life Tap` по существующему условию;
2. выбранное `Curse`, если требуется;
3. `Conflagrate`, если на цели есть собственный `Immolate` и способность готова;
4. `Incinerate` только при активном `Backlash`, который уменьшает время следующего `Incinerate` на 100%;
5. `Corruption` как movement-only fallback, если она ещё не висит на цели.

`Corruption` добавлена в ability catalog Destruction, но не входит в обычный stationary priority. Поэтому при выключенной настройке `useMovementPriority` поведение спека остаётся прежним.

`Shadowflame` намеренно не добавлен в автоматический movement-priority. Способность действительно мгновенная и ситуативно полезна при движении, но является 10-yard frontal cone. Текущий общий range-контракт TopDps не умеет надёжно доказать, что цель находится в конусе и перед игроком; без этого автоматическая рекомендация могла бы быть ложной. До появления корректного positional/range primitive эта способность остаётся вне movement-рекомендаций.

## Правила для новых специализаций

При добавлении movement-aware логики:

1. Сначала проверить реальную WotLK 3.3.5a механику и PvE-priority спека.
2. Не добавлять проверку движения в Core и общие сервисы, если решение относится к конкретному классу.
3. Добавлять `useMovementPriority` только тем provider'ам, где есть отдельное полезное поведение на ходу.
4. При выключенной настройке гарантировать старый stationary priority даже во время движения.
5. Не рекомендовать hard-cast только потому, что `IsUsableAction` вернул true: этот API сам по себе не является movement-policy.
6. Если proc временно делает hard-cast мгновенным, разрешать его на ходу только по явно проверенному состоянию proc-ауры.
7. Не добавлять ability в обычный priority только ради movement fallback. Если способность нужна исключительно на ходу, держать её в ability catalog и отдельном `PRIORITY_MOVING`.
8. Для cone/position-dependent способностей не считать обычный `IsActionInRange` достаточным доказательством применимости.
9. Добавлять smoke-тест на включённую и выключенную настройку и отдельные instant-proc edge cases, если они есть.

## Автоматические проверки

`tools/test_movement_priority.lua` проверяет:

- stationary / moving / falling состояния;
- fallback старой сигнатуры `IsFalling`;
- отсутствие movement API;
- default `useMovementPriority = true` для Demo/Destro;
- mobile priority обоих Warlock provider'ов;
- возврат к обычной ротации после выключения настройки;
- movement-only Corruption у Destruction.

`tools/test_movement_backlash.lua` отдельно проверяет, что Destruction:

- не рекомендует `Incinerate` на ходу без `Backlash`;
- разрешает `Incinerate` на ходу при активном `Backlash`;
- при выключенной movement-aware настройке сохраняет обычное поведение `Incinerate`.

Оба movement-теста запускаются workflow `Проверка проекта` вместе с остальными Lua smoke-тестами.
