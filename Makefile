SHELL   := /bin/bash
GODOT   ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender
SHOT    ?= build/shot.png
PHASE   ?=
AT      ?=
TEMPLATES_DIR := $(HOME)/Library/Application Support/Godot/export_templates/4.7.2.stable

.PHONY: import test test-godot test-blender test-tools terrain layout assets shot run replay sfx templates export images

import:
	$(GODOT) --headless --path . --import

test: test-tools test-blender test-godot

test-tools:
	set -o pipefail; python3 -m unittest discover -s tools/terrain/tests -p "test_*.py" 2>&1 | tail -3
	set -o pipefail; python3 -m unittest discover -s tools/layout/tests -p "test_*.py" 2>&1 | tail -3

layout:
	for f in data/layout_src/*.json; do case $$f in *_core.json) ;; *) python3 tools/layout/layout_gen.py $$f || exit 1;; esac; done
	$(MAKE) terrain

terrain:
	python3 tools/terrain/terrain_gen.py

test-godot: import
	mkdir -p build && touch build/.gdignore
	set -o pipefail; $(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json 2>&1 | tee build/gut.log
	@! grep -q "SCRIPT ERROR" build/gut.log || (echo "Ошибки скриптов в тестах, см. build/gut.log"; exit 1)
	@! (grep -E "^ERROR:" build/gut.log | grep -v 'Parameter "material" is null' | grep -q .) || (echo "Ошибки движка в тестах (кроме известного шума dummy-рендерера), см. build/gut.log"; exit 1)

test-blender:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/tests/run.py

assets:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/build.py -- $(ONLY)

shot: import
	mkdir -p build && touch build/.gdignore
	$(GODOT) --path . --resolution 1280x720 res://scenes/main.tscn ++ $(if $(PHASE),--phase=$(PHASE),) $(if $(AT),--at=$(AT),) --screenshot=$(SHOT)

run: import
	$(GODOT) --path .

replay:
	python3 tools/replay/build_files_md.py

sfx:
	python3 tools/audio/gen_sfx.py

images:
	python3 tools/images/gen.py $(if $(FORCE),--force,)

templates:
	mkdir -p "$(TEMPLATES_DIR)" build
	[ -f build/templates.tpz ] || tools/release/fetch_templates.sh
	unzip -o -j build/templates.tpz 'templates/macos.zip' 'templates/version.txt' -d "$(TEMPLATES_DIR)"
	ls -la "$(TEMPLATES_DIR)"

export: import
	mkdir -p build && touch build/.gdignore
	$(GODOT) --headless --path . --export-release "macOS" build/SnackRun.zip
	ls -la build/SnackRun.zip && unzip -l build/SnackRun.zip | head -5
