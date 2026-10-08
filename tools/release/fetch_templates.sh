#!/bin/bash
# Скачивает шаблоны экспорта Godot 4.7.2 (1,28 ГБ) восемью параллельными диапазонами:
# один поток с GitHub шёл 150 КБ/с, восемь — около 1 МБ/с. Результат: build/templates.tpz.
set -e
cd "$(dirname "$0")/../.."
URL=https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
mkdir -p build/tpz_parts
SIZE=$(curl -sIL "$URL" | grep -i '^content-length' | tail -1 | tr -dc '0-9')
[ -n "$SIZE" ] || { echo "не удалось узнать размер $URL"; exit 1; }
N=8; CHUNK=$(( (SIZE + N - 1) / N ))
for i in $(seq 0 $((N-1))); do
  S=$((i*CHUNK)); E=$(( (i+1)*CHUNK - 1 )); [ $E -ge $SIZE ] && E=$((SIZE-1))
  curl -sL -r $S-$E -o build/tpz_parts/part_$i "$URL" &
done
wait
cat $(for i in $(seq 0 $((N-1))); do echo build/tpz_parts/part_$i; done) > build/templates.tpz
[ "$(stat -f %z build/templates.tpz)" = "$SIZE" ] || { echo "размер не совпал"; exit 1; }
rm -rf build/tpz_parts
echo "ОК build/templates.tpz ($SIZE байт)"
