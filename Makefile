GODOT   ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender
SHOT    ?= build/shot.png

.PHONY: import test test-godot test-blender assets shot run

import:
	$(GODOT) --headless --path . --import

test: import test-blender test-godot

test-godot:
	$(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json

test-blender:
	$(BLENDER) -b --python tools/blender/tests/run.py

assets:
	$(BLENDER) -b --python tools/blender/build.py -- $(ONLY)

shot:
	mkdir -p build
	$(GODOT) --path . --resolution 1280x720 ++ --screenshot=$(SHOT)

run:
	$(GODOT) --path .
