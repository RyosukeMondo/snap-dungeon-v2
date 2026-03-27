class_name VisualEffects
extends RefCounted

## This used to be sprite-based, but for the example we'll use simple particles.

const PROJECTILE_SPEED := 400.0


## Animates a projectile from start to end position
static func animate_projectile(
	parent: Node,
	start_pos: Vector2i,
	end_pos: Vector2i,
	item: Item = null,
	is_thrown_item: bool = false
) -> void:
	var projectile := Sprite2D.new()
	if is_thrown_item and item:
		projectile.texture = ItemTiles.get_texture(item.sprite_name)
	else:
		projectile.texture = preload("res://assets/textures/fx/arrow.png")

	var start := Vector2(start_pos) * Constants.TILE_SIZE_VEC2 + Constants.HALF_TILE_SIZE_VEC2
	var end := Vector2(end_pos) * Constants.TILE_SIZE_VEC2 + Constants.HALF_TILE_SIZE_VEC2
	projectile.position = start
	parent.add_child(projectile)

	var distance := start.distance_to(end)
	var duration := distance / PROJECTILE_SPEED * (2.0 if is_thrown_item else 1.0)

	# Calculate rotation to face movement direction
	projectile.rotation = (end - start).angle()

	# Create animation tween
	var tween := parent.create_tween().set_parallel(true)
	tween.tween_property(projectile, "position", end, duration).set_ease(Tween.EASE_IN_OUT)

	if is_thrown_item:
		# Make thrown items spin and scale
		(
			tween
			. tween_property(projectile, "rotation", PI * 8 * distance / PROJECTILE_SPEED, duration)
			. set_ease(Tween.EASE_IN_OUT)
		)
		tween.tween_property(projectile, "scale", Vector2(1.2, 1.2), duration / 2.0).set_ease(
			Tween.EASE_IN_OUT
		)
		(
			tween
			. chain()
			. tween_property(projectile, "scale", Vector2(1.0, 1.0), duration / 2.0)
			. set_ease(Tween.EASE_IN_OUT)
		)

	await tween.finished
	projectile.queue_free()


## Creates and plays an explosion effect at the given position
static func create_explosion(
	parent: Node, pos: Vector2i, _big: bool = false, _item: Item = null
) -> void:
	var explosion := AnimatedSprite2D.new()
	explosion.sprite_frames = preload("res://scenes/fx/explosion.tres")
	explosion.position = (Vector2(pos) * Constants.TILE_SIZE_VEC2 + Constants.HALF_TILE_SIZE_VEC2)
	parent.add_child(explosion)
	explosion.play()
	await explosion.animation_finished
	explosion.queue_free()
