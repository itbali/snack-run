# Звуки (спек 2.7)

| Файл | Событие | Источник | Лицензия |
|---|---|---|---|
| pickup.ogg | подбор еды, клубочка | Kenney «Interface Sounds», pluck_001 | CC0 (LICENSE_kenney.txt) |
| eat.ogg | съедание | Kenney «Interface Sounds», drop_002 | CC0 |
| hit.ogg | удар | Kenney «Impact Sounds», impactPunch_medium_000 | CC0 |
| bell.ogg | звонок велосипеда | Kenney «Impact Sounds», impactBell_heavy_000 | CC0 |
| meow.wav | писк кота | синтез `tools/audio/gen_sfx.py` (`make sfx`) | проект |
| bark.wav | лай | синтез `tools/audio/gen_sfx.py` (`make sfx`) | проект |

Паки: https://kenney.nl/assets/interface-sounds, https://kenney.nl/assets/impact-sounds.
Правило: один `Sfx.play()` на игровое событие (сигнал), никогда из `_process`.
