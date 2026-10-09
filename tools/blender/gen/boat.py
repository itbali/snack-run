"""Лодка у причала (порт): корпус 1,6×4,2 м, палуба на 0,45 м над ватерлинией (origin), нос-клин, банка. Качается (Floater)."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 5.2}


def build():
	hull = lib.rounded_box("boat", (1.6, 4.2, 0.75), bevel=0.06, material="brick")
	hull.location.z = 0.075
	deck = lib.rounded_box("boat_deck", (1.4, 4.0, 0.06), bevel=0.01, segments=1, material="sand")
	deck.location.z = 0.45
	bow = lib.wedge("boat_bow", width=1.6, length=0.8, height=0.75, material="brick")
	bow.location = (0, 2.1, -0.3)
	seat = lib.rounded_box("boat_seat", (1.4, 0.3, 0.08), bevel=0.01, segments=1, material="cream")
	seat.location = (0, -0.8, 0.62)
	rim = lib.rounded_box("boat_rim", (1.7, 4.3, 0.06), bevel=0.01, segments=1, material="cream")
	rim.location.z = 0.48
	return lib.group([hull, deck, bow, seat, rim])
