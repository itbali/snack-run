# Клипы кота, сгенерированные UniMate

UniMate (SIGGRAPH Asia 2026, код MIT: https://github.com/Friedrich-M/UniMate,
чекпоинт `unimate_uniml3d_f60_v3`, шаг 150000, https://huggingface.co/Linzhan/UniMate).
Исходный риг: CC0-кот Quaternius (`third_party/quaternius_animal_pack_v2/Cat.blend`),
экспортированный нашим `tools/blender/cat.py` первой версии.

- `cat_canonical.glb` — риг и меш после `rig_preprocess` (канонический кадр, 20 костей, IK удалены).
- `annotation.json` — ручная разметка суставов (автоматическая перепутала хвост и спину).
- `jump.glb`, `hide.glb`, `hit.glb`, `run.glb` — сгенерированные движения, применённые к каноническому ригу.

Воспроизведение (Mac, CPU, Python 3.10 через uv):
```
python -m data_process.rig_preprocess run --input cat.glb --output_dir outputs/rig/cat --profile general --annotation annotation.json
python -m unimate.inference.sample --exp_dir outputs/unimate_uniml3d_f60_v3 --asset outputs/rig/cat \
    --prompt "An object jumps in place." --num_repetitions 2 --output_dir outputs/samples/cat --only_save_motion
bash scripts/run_animate_motion.sh outputs/samples/cat      # blender в PATH = venv python с pip-модулем bpy
```
В `config.json` чекпоинта `sampling.device` заменён на `cpu` (MPS не поддерживает float64 в torchdiffeq).
Сгенерированные движения — результат нашей работы над CC0-ассетом; код UniMate под MIT.
