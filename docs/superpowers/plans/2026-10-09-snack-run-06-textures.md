# Snack Run, план 6: Текстуры крупных поверхностей

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Асфальт, плитка тротуара и штукатурка стен вместо плоских цветов (спек 2.9, гибрид).

**Architecture:** Три бесшовные картинки генерируются по манифесту; статический класс `SurfaceTextures` по имени меша
(`ground`, `sidewalk`, `wall`) ставит материалу текстуру с трипланарной проекцией в мировых координатах и белым
`albedo_color`; `Main._ready` зовёт его для района после `Toon.apply`. Пропсы не трогаются.

**Spec:** `docs/superpowers/specs/2026-10-07-snack-run-design.md`, раздел 2.9. Решение владельца №21.

## Global Constraints
- Картинки только через `tools/images/gen.py` (OpenAI, `OPENAI_API_KEY`), проверка бесшовности плиткой 2×2 до использования.
- Тайл: асфальт 4 м, плитка 1,2 м, штукатурка 4,5 м (подобрано по кадру). Тун-диффуз сохраняется. Импорт: VRAM-сжатие + мипмапы.
- Тесты GUT зелёные, коммиты на русском с подписью текущей модели.

## Review Focus
1. Окна и рамки стен (меши `wall_frame*`, `wall_glass*`) остаются плоскими — текстура только на корпусе `wall`.
2. Лужи (зеркальный материал) и декали не получают текстуру асфальта.
3. Без файла текстуры игра стартует, поверхность остаётся плоского цвета.

### Task 1: Текстуры и SurfaceTextures
- [ ] Манифест: `assets/images/textures/{asphalt,paving,stucco}.png` (промпты «seamless tileable… straight from above… flat lighting»), `make images`, плитка 2×2 глазами.
- [ ] RED: `tests/integration/test_surface_textures.gd` — у мешей `ground`/`sidewalk`/`wall` в `Main` текстура нужного файла, `uv1_triplanar` и `uv1_world_triplanar`, `uv1_scale` = 1/тайл; у `wall_frame0`, `bin`, лужи текстуры нет; `SurfaceTextures.apply` на узле без файлов текстур не падает.
- [ ] GREEN: `scripts/visual/surface_textures.gd` (`TABLE`, `apply(root) -> int`), вызов в `main.gd` после `Toon.apply($DistrictYard)`; `.import` текстур: `compress/mode=2`, `mipmaps/generate=true`.
- [ ] Кадр `make shot`, коммит.

### Task 2: Документация (`02-procedure.md`, `make replay`, дорожная карта, `CLAUDE.md`).
