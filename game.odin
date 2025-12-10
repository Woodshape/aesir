package game

import "core:fmt"
import "core:log"
import "core:testing"
import rl "vendor:raylib"

SPEED: f32 : 400.0
GRAVITY: f32 : 2000.0

Enemy :: struct {
	hp:      i32,
	variant: EnemyVariant,
}

do_stuff_with_enemy :: proc(enemy: ^Enemy) {
	switch variant in enemy.variant {
	case ^Skeleton:
		log.infof("skeleton field 'bones': %v", variant.bones)
	case ^Bat:
		log.infof("bat field 'flying': %v", variant.flying)
	case:
		log.panicf("unhandled variant: %v\n", variant)
	}
}

Skeleton :: struct {
	using enemy: Enemy,
	bones:       i32,
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

new_enemy :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
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

	skeleton_container: EnemyContainer = {
		variant = skeleton,
	}

	do_stuff_with_enemy(skeleton)
	do_stuff_with_enemy(bat)

	myEnemyList: [dynamic]^EnemyContainer
	append(&myEnemyList, &skeleton_container)
	delete(myEnemyList)
}

main :: proc() {
	rl.InitWindow(1280, 720, "Aesir")

	player_idle_animation: Animation = {
		texture      = rl.LoadTexture("cat_idle.png"),
		frames       = 2,
		frame_length = 0.5,
	}

	player_run_animation: Animation = {
		texture      = rl.LoadTexture("cat_run.png"),
		frames       = 4,
		frame_length = 0.1,
	}

	player_animation: ^Animation = &player_idle_animation

	player_pos: rl.Vector2 = {640, 360}
	player_vel: rl.Vector2

	player_on_ground: bool = false
	player_flip_sprite: bool = false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		frame_time: f32 = rl.GetFrameTime()

		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			player_vel.x = -SPEED
			player_flip_sprite = true
			player_animation = &player_run_animation
		} else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			player_vel.x = SPEED
			player_flip_sprite = false
			player_animation = &player_run_animation
		} else {
			player_vel.x = 0.0
			player_animation = &player_idle_animation
		}

		player_vel.y += GRAVITY * frame_time

		if rl.IsKeyPressed(.SPACE) && player_on_ground {
			player_vel.y = -600
			player_on_ground = false
		}

		player_pos += player_vel * frame_time

		floor_pos: f32 = f32(rl.GetScreenHeight()) - 64
		if player_pos.y > floor_pos {
			player_pos.y = floor_pos
			player_on_ground = true
		}

		update_animation(player_animation, frame_time)

		rl.ClearBackground(rl.SKYBLUE)

		draw_animation(player_animation^, player_pos, player_flip_sprite)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
