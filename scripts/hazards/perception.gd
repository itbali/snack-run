class_name Perception
extends RefCounted
## Геометрия восприятия: конус зрения по горизонтали.


static func in_cone(origin: Vector3, forward: Vector3, target: Vector3, half_angle_deg: float, range_m: float) -> bool:
	var to := target - origin
	to.y = 0.0
	var fwd := forward
	fwd.y = 0.0
	if to.length() > range_m or to.length() < 0.001 or fwd.length() < 0.001:
		return false
	var cos_angle := fwd.normalized().dot(to.normalized())
	return cos_angle >= cos(deg_to_rad(half_angle_deg))
