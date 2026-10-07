GODOT   ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender
SHOT    ?= build/shot.png

.PHONY: import test test-godot test-blender assets shot run

import:
	$(GODOT) --headless --path . --import

test: import test-blender test-godot

test-godot:
	mkdir -p build
	set -o pipefail; $(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json 2>&1 | tee build/gut.log
	@! grep -q "SCRIPT ERROR" build/gut.log || (echo "Ошибки скриптов в тестах, см. build/gut.log"; exit 1)

test-blender:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/tests/run.py

assets:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/build.py -- $(ONLY)

shot:
	mkdir -p build
	$(GODOT) --path . --resolution 1280x720 ++ --screenshot=$(SHOT)

run:
	$(GODOT) --path .
