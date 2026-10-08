SHELL   := /bin/bash
GODOT   ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender
SHOT    ?= build/shot.png
TEMPLATES_DIR := $(HOME)/Library/Application Support/Godot/export_templates/4.7.2.stable
TPZ_URL := https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz

.PHONY: import test test-godot test-blender assets shot run replay sfx templates export

import:
	$(GODOT) --headless --path . --import

test: test-blender test-godot

test-godot: import
	mkdir -p build
	set -o pipefail; $(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json 2>&1 | tee build/gut.log
	@! grep -q "SCRIPT ERROR" build/gut.log || (echo "Ошибки скриптов в тестах, см. build/gut.log"; exit 1)
	@! (grep -E "^ERROR:" build/gut.log | grep -v 'Parameter "material" is null' | grep -q .) || (echo "Ошибки движка в тестах (кроме известного шума dummy-рендерера), см. build/gut.log"; exit 1)

test-blender:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/tests/run.py

assets:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/build.py -- $(ONLY)

shot: import
	mkdir -p build
	$(GODOT) --path . --resolution 1280x720 res://scenes/main.tscn ++ --screenshot=$(SHOT)

run: import
	$(GODOT) --path .

replay:
	python3 tools/replay/build_files_md.py

sfx:
	python3 tools/audio/gen_sfx.py

templates:
	mkdir -p "$(TEMPLATES_DIR)" build
	[ -f build/templates.tpz ] || curl -L -C - -o build/templates.tpz "$(TPZ_URL)"
	unzip -o -j build/templates.tpz 'templates/macos.zip' 'templates/version.txt' -d "$(TEMPLATES_DIR)"
	ls -la "$(TEMPLATES_DIR)"

export: import
	mkdir -p build
	$(GODOT) --headless --path . --export-release "macOS" build/SnackRun.zip
	ls -la build/SnackRun.zip && unzip -l build/SnackRun.zip | head -5
