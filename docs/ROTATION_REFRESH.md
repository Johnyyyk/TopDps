# Предварительное обновление эффектов

## Назначение

`refresh` — необязательная декларативная возможность способности ротации. Это не новый тип способности и не часть cooldown lookahead.

Она нужна для заклинаний, которые накладывают поддерживаемый эффект и имеют время каста. Рекомендация может появиться до окончания текущего эффекта, если новый каст завершится уже после его окончания.

Пример:

```lua
immolate = {
    spellIds = { 348 },
    refresh = {
        auraSpellIds = { 348 },
        unit = "target",
        filter = "HARMFUL",
        ownOnly = true,
        lead = addon.REFRESH_LEAD_CAST_TIME,
    },
}
```

При `lead = CAST_TIME` категория разрешается, когда оставшееся время ауры меньше или равно фактическому времени каста способности на панели действий.

`cooldownLookahead` применяется только к готовности способности по cooldown и не прибавляется к refresh lead. Поэтому увеличение lookahead не приводит к преждевременному клипу последнего тика DoT.

Для фиксированного окна `lead` может быть неотрицательным числом секунд.

## Эквивалентные эффекты

Если refresh зависит не от конкретной ауры, а от семантической группы взаимозаменяемых raid debuff/buff, runtime-проверка должна идти через `EffectService`.

```lua
scorch = {
    spellIds = { Mage.SPELL_IDS.scorch },
    refresh = {
        auraSpellIds = addon.EffectService:GetSpellIds(
            addon.EFFECT_SPELL_CRIT_TAKEN,
            addon.EFFECT_QUALITY_FULL
        ),
        effectId = addon.EFFECT_SPELL_CRIT_TAKEN,
        effectMinimumQuality = addon.EFFECT_QUALITY_FULL,
        unit = "target",
        filter = "HARMFUL",
        lead = 3,
    },
}
```

`auraSpellIds` в таком определении формируется из того же централизованного каталога и сохраняет обычный контракт `refresh`. Если задан `effectId`, `RefreshService` получает активную ауру через `EffectService`, поэтому учитываются требования семантической группы, включая качество эффекта и минимальное число стаков.

Так, неполный `Winter's Chill` не должен считать +5% spell crit debuff полностью закрытым, тогда как пять стаков, `Improved Scorch` или `Shadow Mastery` закрывают одно и то же требование.

Общая проверка выполняется в `RefreshService` до specialization-specific `IsCategoryAllowed`. Специализация не должна дублировать проверку наличия/остатка ауры, если её можно выразить декларативным `refresh`.
