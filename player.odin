package main

import rl "vendor:raylib"

Player :: struct {
	position: rl.Vector2,
	speed: f32
}

move_player_position :: proc(player: ^Player, animation: Animation, position: rl.Vector2) -> (distance: f32, at_target: bool) {
	player.position = rl.Vector2MoveTowards(player.position, position, player.speed * rl.GetFrameTime())
	distance = rl.Vector2Distance(player.position, position)
	at_target = distance == 0.0
	return
}