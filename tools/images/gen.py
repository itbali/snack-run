#!/usr/bin/env python3
"""Генерация 2D-картинок (иконки, заставка, плакаты, облака, декали) через OpenAI Images API.
Ключ берётся только из переменной окружения OPENAI_API_KEY и никуда не пишется.
Запуск: make images (только отсутствующие файлы), make images FORCE=1 (все заново)."""
import base64
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
MANIFEST = pathlib.Path(__file__).with_name("manifest.json")
API = "https://api.openai.com/v1/images/generations"
STYLE = ("Style: flat cartoon game art, thick dark graphite (#394151) outline, soft pastel colors, "
         "simple rounded shapes, clean edges, no text unless the prompt asks for it.")


def generate(entry, key):
	body = {
		"model": entry.get("model", "gpt-image-2.5-flare"),
		"prompt": entry["prompt"] + " " + STYLE,
		"size": entry.get("size", "1024x1024"),
		"quality": entry.get("quality", "medium"),
		"output_format": "png",
		"n": 1,
	}
	if entry.get("background") == "transparent":
		body["background"] = "transparent"
	req = urllib.request.Request(API, data=json.dumps(body).encode(), method="POST",
	                             headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
	for attempt in range(3):
		try:
			with urllib.request.urlopen(req, timeout=180) as resp:
				data = json.load(resp)
			return base64.b64decode(data["data"][0]["b64_json"]), data.get("usage", {}).get("total_tokens")
		except urllib.error.HTTPError as e:
			text = e.read().decode(errors="replace")[:300]
			if e.code in (429, 500, 502, 503) and attempt < 2:
				time.sleep(5 * (attempt + 1))
				continue
			raise RuntimeError(f"{entry['file']}: HTTP {e.code} {text}") from None
		except (urllib.error.URLError, TimeoutError, OSError) as e:   # сеть/таймаут: ключ в сообщение не попадает
			if attempt < 2:
				time.sleep(5 * (attempt + 1))
				continue
			raise RuntimeError(f"{entry['file']}: сеть недоступна ({e.__class__.__name__})") from None
		except (KeyError, IndexError, ValueError) as e:
			raise RuntimeError(f"{entry['file']}: неожиданный ответ API ({e.__class__.__name__})") from None


def main(argv):
	force = "--force" in argv
	only = [a for a in argv if not a.startswith("--")]
	key = os.environ.get("OPENAI_API_KEY", "")
	entries = json.loads(MANIFEST.read_text(encoding="utf-8"))["images"]
	todo = [e for e in entries if (force or not (ROOT / e["file"]).exists()) and (not only or e["file"] in only)]
	if not todo:
		print("все картинки на месте")
		return 0
	if not key:
		print(f"нет OPENAI_API_KEY, а нужно сгенерировать {len(todo)} файл(ов):", ", ".join(e["file"] for e in todo))
		return 1
	for e in todo:
		png, tokens = generate(e, key)
		out = ROOT / e["file"]
		out.parent.mkdir(parents=True, exist_ok=True)
		out.write_bytes(png)
		print(f"ОК {e['file']} ({len(png) // 1024} КБ, {tokens} токенов)")
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
