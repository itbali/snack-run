extends GutTest

func test_target_in_front_within_range() -> void:
	assert_true(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, -3), 45.0, 6.0))

func test_target_behind_is_not_seen() -> void:
	assert_false(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, 3), 45.0, 6.0))

func test_target_at_edge_of_cone() -> void:
	assert_true(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(2.9, 0, -3), 45.0, 6.0))
	assert_false(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(3.2, 0, -3), 45.0, 6.0))

func test_out_of_range() -> void:
	assert_false(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, -6.5), 45.0, 6.0))

func test_height_is_ignored() -> void:
	assert_true(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 5, -3), 45.0, 6.0))
