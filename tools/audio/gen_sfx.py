#!/usr/bin/env python3
"""Два звука, которых нет в CC0-паках Kenney: писк кота и лай. Только стандартная библиотека.
Запуск: make sfx (пишет assets/sfx/meow.wav и bark.wav, 22 050 Гц, моно, 16 бит)."""
import math
import pathlib
import random
import struct
import wave

RATE = 22050
OUT = pathlib.Path(__file__).resolve().parents[2] / "assets" / "sfx"


def write(name, samples):
	OUT.mkdir(parents=True, exist_ok=True)
	with wave.open(str(OUT / name), "wb") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(RATE)
		w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


def meow(duration=0.45):
	"""Писк: тон 900→520 Гц с вибрато 6 Гц/25 Гц, вторая гармоника 0,35, атака 30 мс, спад к концу."""
	out = []
	phase = 0.0
	n = int(RATE * duration)
	for i in range(n):
		t = i / RATE
		u = t / duration
		f = 900 - 380 * u + 25 * math.sin(2 * math.pi * 6 * t)
		phase += 2 * math.pi * f / RATE
		env = min(1.0, t / 0.03) * (1.0 - u) ** 1.5
		out.append(env * 0.6 * (math.sin(phase) + 0.35 * math.sin(2 * phase)))
	return out


def bark(duration=0.16, gap=0.07):
	"""Лай «гав-гав»: два импульса, тон 190→120 Гц с пятью гармониками плюс шум 0,25, атака 10 мс."""
	rnd = random.Random(7)

	def pulse():
		out = []
		phase = 0.0
		n = int(RATE * duration)
		for i in range(n):
			t = i / RATE
			u = t / duration
			phase += 2 * math.pi * (190 - 70 * u) / RATE
			env = min(1.0, t / 0.01) * (1.0 - u) ** 2
			tone = sum(math.sin(k * phase) / k for k in (1, 2, 3, 4, 5))
			out.append(env * (0.45 * tone + 0.25 * rnd.uniform(-1.0, 1.0)))
		return out

	return pulse() + [0.0] * int(RATE * gap) + pulse()


def hiss(duration=0.9):
	"""Шипение шланга: шум с плавной атакой 150 мс и затуханием, без тона."""
	rnd = random.Random(11)
	out = []
	n = int(RATE * duration)
	prev = 0.0
	for i in range(n):
		t = i / RATE
		env = min(1.0, t / 0.15) * (1.0 - t / duration) ** 0.5
		prev = prev * 0.55 + rnd.uniform(-1.0, 1.0) * 0.45   # мягкий фильтр: шипение, а не треск
		out.append(env * 0.5 * prev)
	return out


def sprinkle(count=6, gap=0.11):
	"""Бульканье дождевателя: короткие «бульки» — тон 300→700 Гц по 60 мс."""
	out = []
	for k in range(count):
		n = int(RATE * 0.06)
		phase = 0.0
		for i in range(n):
			u = i / n
			phase += 2 * math.pi * (300 + 400 * u + 40 * k) / RATE
			out.append(math.sin(phase) * 0.45 * (1 - u) ** 2)
		out += [0.0] * int(RATE * gap)
	return out


def coo(duration=0.5):
	"""Воркование голубя: два низких «гу-у» 320→260 Гц с вибрато 9 Гц."""
	out = []
	for part in (0.22, 0.28):
		n = int(RATE * part)
		phase = 0.0
		for i in range(n):
			t = i / RATE
			u = t / part
			phase += 2 * math.pi * (320 - 60 * u + 12 * math.sin(2 * math.pi * 9 * t)) / RATE
			env = min(1.0, t / 0.03) * (1.0 - u) ** 1.2
			out.append(env * 0.55 * (math.sin(phase) + 0.25 * math.sin(2 * phase)))
		out += [0.0] * int(RATE * 0.05)
	return out


if __name__ == "__main__":
	write("meow.wav", meow())
	write("bark.wav", bark())
	write("hiss.wav", hiss())
	write("sprinkle.wav", sprinkle())
	write("coo.wav", coo())
	print("ОК assets/sfx/meow.wav, bark.wav, hiss.wav, sprinkle.wav, coo.wav")
