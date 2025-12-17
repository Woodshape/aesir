package game

import "core:fmt"
import "core:log"
import "core:mem"
import "core:testing"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

JUMP_FORCE: f32 = 600.0
SPEED: f32 : 400.0
GRAVITY: f32 : 2000.0

TICK_TIME: f64 = 1.0

MAX_ENTITIES :: 2048 // increase this as needed.

Game_State :: struct {
	ticks:            u64,
	time_elapsed:     f64,

	// entity system
	entity_top_count: int,
	latest_entity_id: int,
	entities:         [MAX_ENTITIES]Entity,
	entity_free_list: [dynamic]int,

	// player stuff
	player_handle:    Entity_Handle,
	scratch:          struct {
		all_enemies: []Entity_Handle,
	},
}

Context :: struct {
	state:   ^Game_State,
	delta_t: f32,
}

ctx: ^Context

Player :: struct {
	using entity: Entity,
	hp:           i32,
	vel:          rl.Vector2,
	jumps:        u8,
	animation:    Animation,
	grounded:     bool,
}

Input :: struct {
	move_left:  bool,
	move_right: bool,
	jump:       bool,
}

can_jump :: proc(player: Player, jumps_taken: u8) -> bool {
	return jumps_taken < player.jumps
}

handle_input :: proc() -> Input {
	return {
		move_left = rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A),
		move_right = rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D),
		jump = rl.IsKeyPressed(.SPACE),
	}
}

main :: proc() {
	context.logger = log.create_console_logger()
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer {
			if (len(track.allocation_map) > 0) {
				for i, entry in track.allocation_map {
					fmt.printf("%v leaked %d bytes!\n", entry.location, entry.size)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	ctx = new(Context)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Aesir")

	load_animation_data()

	state: ^Game_State = new(Game_State)
	ctx.state = state

	// create player handle on the first tick
	player_entity: ^Entity = new(Entity)
	player: Player = setup_player(player_entity)

	player_dead: bool
	jumps: u8

	for !rl.WindowShouldClose() {
		// clear scratch
		ctx.state.scratch = {}

		rl.BeginDrawing()

		// ctx update
		ctx.delta_t = rl.GetFrameTime()
		ctx.state.time_elapsed += f64(ctx.delta_t)
		ctx.state.ticks = u64(ctx.state.time_elapsed / TICK_TIME)


		input: Input = handle_input()

		if !player_dead {
			if input.move_left {
				player.vel.x = -SPEED
				player.flip_x = true
				change_animation(&player.animation, animations[.player_run])
			} else if input.move_right {
				player.vel.x = SPEED
				player.flip_x = false
				change_animation(&player.animation, animations[.player_run])
			} else {
				player.vel.x = 0.0
				change_animation(&player.animation, animations[.player_idle])
			}
		} else {
			rl.DrawText("You are Dead", WINDOW_WIDTH / 2 - 200, WINDOW_HEIGHT / 2, 50, rl.BLACK)
		}

		if rl.IsKeyPressed(.F) {
			change_animation(&player.animation, animations[.player_death])
			player_dead = !player_dead
			player.vel.x = 0.0
		}

		player.vel.y += GRAVITY * ctx.delta_t

		if input.jump && can_jump(player, jumps) {
			player.vel.y = -JUMP_FORCE
			player.grounded = false
			jumps += 1
		}

		player.pos += player.vel * ctx.delta_t

		floor_pos: f32 = f32(rl.GetScreenHeight()) - 96
		if player.pos.y > floor_pos {
			player.pos.y = floor_pos
			player.grounded = true
			jumps = 0
		}

		update_animation(&player.animation, ctx.delta_t)

		rl.ClearBackground(rl.SKYBLUE)

		draw_animation(player.animation, player.pos, player.flip_x)

		rl.EndDrawing()

		rl.DrawText(fmt.caprintf("delta: %.6f", ctx.delta_t), 10, 10, 20, rl.BLACK)
		rl.DrawText(fmt.caprintf("elapsed: %.2f", ctx.state.time_elapsed), 10, 30, 20, rl.BLACK)
		rl.DrawText(fmt.caprintf("ticks: %d", ctx.state.ticks), 10, 50, 20, rl.BLACK)

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}

setup_player :: proc(entity: ^Entity) -> Player {
	entity.kind = .player

	player: Player = {
		hp        = 100,
		pos       = {WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2},
		jumps     = 2,
		animation = animations[.player_idle],
	}

	entity.variant = &player

	return player
}

@(test)
test_player_jump :: proc(t: ^testing.T) {
	player: Player = {
		pos   = rl.Vector2(0),
		jumps = 2,
	}

	testing.expect(t, can_jump(player, 0))
	testing.expect(t, can_jump(player, 1))
	testing.expect(t, !can_jump(player, 2))
}
