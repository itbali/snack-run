"""Ведро рыбака (план 15): голубое, с ручкой; в него падает золотая рыбка."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.45}


def build():
	body = lib.cylinder("bucket", radius=0.17, depth=0.3, segments=12, material="sky")
	body.location.z = 0.15
	rim = lib.torus("bucket_rim", major=0.17, minor=0.015, material="cream")
	rim.location.z = 0.3
	return lib.group([body, rim])
