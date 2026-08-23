# Экспериментальные функции

Экспериментальные функции TopDps всегда работают по двойному opt-in и не должны менять поведение аддона после обновления без явного действия пользователя.

## Пользовательская модель

В главных настройках есть глобальная галочка `Использовать экспериментальные функции`.

- по умолчанию она выключена;
- выключенная галочка скрывает экспериментальные параметры specialization provider'ов и блокирует их выполнение;
- включение глобальной галочки только показывает и разрешает экспериментальные настройки, но не включает их автоматически;
- каждый экспериментальный feature-toggle хранится в существующих per-spec настройках и также должен быть выключен по умолчанию;
- выключение глобального opt-in не стирает per-spec выбор пользователя, но временно блокирует все экспериментальные функции.

В настройках ротации экспериментальные параметры автоматически группируются в отдельный раздел `Экспериментальные функции`. Раздел появляется и исчезает динамически без `/reload`.

Глобальный gate применяется не только в UI. `SpecProvider:GetSetting()` для setting с `experimental = true` при выключенном global opt-in возвращает безопасный `default`, а не сохранённое экспериментальное значение. `SpecProvider:SetSetting()` в этом состоянии игнорирует попытки изменить experimental-setting. Это защищает сохранённый per-spec выбор в том числе от callback'ов скрытых UI-контролов: выключение global opt-in блокирует экспериментальную механику, но не перезаписывает её сохранённые параметры.

## Объявление experimental setting

Provider объявляет экспериментальную функцию через обычный setting definition:

```lua
{
    type = "checkbox",
    key = "useTargetTimeToDie",
    labelKey = "ROTATION_USE_TARGET_TIME_TO_DIE",
    default = false,
    experimental = true,
    experimentalFeature = addon.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE,
}
```

Для `experimentalFeature` действуют дополнительные ограничения:

- `experimental = true` обязателен;
- feature-toggle должен быть `checkbox`;
- `default` обязан быть `false`;
- один `experimentalFeature` может быть объявлен у provider'а только одним setting.

`SpecProvider` валидирует эти правила при создании provider'а.

## Проверка feature-toggle

Общий код не должен проверять `addon.db.experimentalFeaturesEnabled` и per-spec setting отдельно. Используется единый gate:

```lua
addon.Settings:IsExperimentalFeatureEnabled(
    provider,
    addon.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE
)
```

Метод возвращает `true` только когда:

1. глобальные экспериментальные функции разрешены;
2. provider объявил setting для указанного feature key;
3. пользователь включил этот setting у конкретной специализации.

## Правила разработки

- Экспериментальная функция не должна автоматически включаться при обновлении.
- Stable-ротация обязана оставаться fallback при выключенном global gate или per-spec feature-toggle.
- Не следует объявлять экспериментальный setting у спека, который фактически не использует соответствующую механику.
- Общий Core может предоставлять экспериментальный факт, но threshold/priority-решения остаются в specialization provider.
- Для feature-level решения использовать `IsExperimentalFeatureEnabled`, даже несмотря на дополнительную защиту `SpecProvider:GetSetting()`.
- Не обходить `provider:GetSetting()` / `provider:SetSetting()` прямым чтением или записью per-spec БД для experimental settings.
- При переводе функции из experimental в stable нужно отдельно решить судьбу старого per-spec setting и документации, а не просто снять флаг.

Первой функцией, использующей этот контракт, является оценка time-to-die цели. Её устройство описано в `docs/TIME_TO_DIE.md`.
