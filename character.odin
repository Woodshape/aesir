package game

import rl "vendor:raylib"

Character :: struct {
	position:          rl.Vector2,
	rect:              rl.Rectangle,
	speed:             f32,
	is_running:        bool,
	current_animation: ^Animation,
	target_pos:        rl.Vector2,
}

init_character :: proc(character: ^Character, position: rl.Vector2, width, height: i32) {
	character.position = position
	character.rect = rl.Rectangle {
		x      = position.x,
		y      = position.y,
		width  = f32(width),
		height = f32(height),
	}
}

move_character :: proc(character: ^Character) -> (distance: f32, at_target: bool) {
	return move_character_position(character, character.target_pos)
}

move_character_position :: proc(
	character: ^Character,
	position: rl.Vector2,
) -> (
	distance: f32,
	at_target: bool,
) {
	character.position = rl.Vector2MoveTowards(
		character.position,
		position,
		character.speed * rl.GetFrameTime(),
	)
	distance = rl.Vector2Distance(character.position, position)
	at_target = distance == 0.0
	return
}

should_flip_animation :: proc(character: Character) -> bool {
	if character.target_pos.x < character.position.x {
		return true
	}

	return false
}
