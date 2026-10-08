extends GutTest

func test_burst_creates_one_shot_particles_with_color() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var p := Effects.burst(root, Vector3(1, 2, 3), Color.RED)
	assert_true(p.one_shot)
	assert_true(p.emitting)
	assert_eq(p.color, Color.RED)
	assert_eq(p.global_position, Vector3(1, 2, 3))
	assert_true(p.is_in_group("fx"))
	assert_gt(p.amount, 0)
