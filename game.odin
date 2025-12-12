package game

import "core:log"
import "core:testing"
import rl "vendor:raylib"

SPEED: f32 : 400.0
GRAVITY: f32 : 2000.0

Enemy :: struct {
	hp:      i32,
	variant: EnemyVariant,
}

new_enemy :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
	return e
}

update_enemy :: proc(enemy: ^Enemy, frame_time: f32) {
	#partial switch e_variant in enemy.variant {
	case ^Skeleton:
		log.infof("skeleton field 'bones': %v", e_variant.bones)
		update_skeleton(e_variant, frame_time)
	case ^Bat:
		log.infof("bat field 'flying': %v", e_variant.flying)
		e_variant.flying = !e_variant.flying
	case:
		log.panicf("unhandled variant: %v\n", e_variant)
	}
}

Skeleton :: struct {
	using enemy: Enemy,
	bones:       i32,
}

update_skeleton :: proc(skeleton: ^Skeleton, frame_time: f32) {
	skeleton.bones += 10
	log.infof("skeleton update: %v", skeleton)
}

Bat :: struct {
	using enemy: Enemy,
	flying:      bool,
}

EnemyVariant :: union {
	^Skeleton,
	^Bat,
}

EnemyContainer :: struct {
	variant: EnemyVariant,
}

new_enemy_container :: proc(enemy: EnemyVariant) -> ^EnemyContainer {
	e := new(EnemyContainer)
	e.variant = enemy
	return e
}

@(test)
test_enemy_stuff :: proc(t: ^testing.T) {
	skeleton: ^Skeleton = new_enemy(Skeleton)
	defer free(skeleton)
	bat: ^Bat = new_enemy(Bat)
	defer free(bat)

	skeleton.hp = 100
	skeleton.bones = 250

	log.infof("%v\n", skeleton)
	log.infof("%v\n", bat)

	// skeleton_container: EnemyContainer = {
	// 	variant = skeleton,
	// }
	skeleton_container := new_enemy_container(skeleton)
	defer free(skeleton_container)

	log.infof("%v\n", skeleton_container)

	update_enemy(skeleton, 0.5)
	update_enemy(bat, 0.5)

	log.infof("%v\n", skeleton)
	log.infof("%v\n", bat)

	myEnemyList: [dynamic]^EnemyContainer
	append(&myEnemyList, skeleton_container)
	defer delete(myEnemyList)

	testing.expect(t, len(myEnemyList) == 1)
}

Player :: struct {
	hp:          i32,
	pos:         rl.Vector2,
	vel:         rl.Vector2,
	animation:   Animation,
	grounded:    bool,
	flip_sprite: bool,
}

Input :: struct {
	move_left:  bool,
	move_right: bool,
	jump:       bool,
}

handle_input :: proc() -> Input {
	return {
		move_left = rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A),
		move_right = rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D),
		jump = rl.IsKeyPressed(.SPACE),
	}
}

main :: proc() {
	rl.InitWindow(1280, 720, "Aesir")

	player_idle_animation: Animation = {
		texture      = rl.LoadTexture(ANIMATION_IDLE),
		frames       = 2,
		frame_length = 0.5,
	}

	player_run_animation: Animation = {
		texture      = rl.LoadTexture(ANIMATION_RUN),
		frames       = 4,
		frame_length = 0.1,
	}

	player: Player = {
		hp        = 100,
		pos       = {640, 360},
		animation = player_idle_animation,
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		frame_time: f32 = rl.GetFrameTime()

		input: Input = handle_input()

		if input.move_left {
			player.vel.x = -SPEED
			player.flip_sprite = true
			change_animation(&player.animation, player_run_animation)
		} else if input.move_right {
			player.vel.x = SPEED
			player.flip_sprite = false
			change_animation(&player.animation, player_run_animation)
		} else {
			player.vel.x = 0.0
			change_animation(&player.animation, player_idle_animation)
		}

		player.vel.y += GRAVITY * frame_time

		if input.jump && player.grounded {
			player.vel.y = -600
			player.grounded = false
		}

		player.pos += player.vel * frame_time

		floor_pos: f32 = f32(rl.GetScreenHeight()) - 64
		if player.pos.y > floor_pos {
			player.pos.y = floor_pos
			player.grounded = true
		}

		update_animation(&player.animation, frame_time)

		rl.ClearBackground(rl.SKYBLUE)

		draw_animation(player.animation, player.pos, player.flip_sprite)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
