package game

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
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
		all_entities: []Entity_Handle,
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
			// Check for allocations that were never freed (leaks)
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
			}

			// Loop through all leaked entries and print a report
			for _, entry in track.allocation_map {
				// Pseudo-code for filtering:
				if strings.contains(entry.location.file_path, "core/") {
					continue // Skips the current entry and moves to the next loop iteration [3]
				}

				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}

			// You should also check track.bad_free_array for "bad frees" (like double free) [5]

			// Destroy the tracking allocator to clean up its memory
			mem.tracking_allocator_destroy(&track)
		}
	}

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Aesir")
	rl.SetTargetFPS(120)

	ctx = new(Context)
	defer free(ctx)
	state: ^Game_State = new(Game_State)
	defer free(state)
	ctx.state = state

	entity_init_core()
	load_animation_data(context.temp_allocator)

	player_entity: ^Entity = entity_create(.player)
	player := get_player()
	defer player_entity.delete_proc(player)
	player.pos = {WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}
	player.jumps = 2

	player_dead: bool
	jumps: u8

	for !rl.WindowShouldClose() {
		// clear scratch
		ctx.state.scratch = {}
		rebuild_scratch_helpers()

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

		if input.jump && can_jump(player^, jumps) {
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

		ents := get_all_ents()
		rl.DrawText(fmt.caprintf("delta: %.6f", ctx.delta_t), 10, 10, 20, rl.BLACK)
		rl.DrawText(fmt.caprintf("elapsed: %.2f", ctx.state.time_elapsed), 10, 30, 20, rl.BLACK)
		rl.DrawText(fmt.caprintf("ticks: %d", ctx.state.ticks), 10, 50, 20, rl.BLACK)
		rl.DrawText(fmt.caprintf("ents: %d", len(ents)), 10, 70, 20, rl.BLACK)
		rl.DrawFPS(WINDOW_WIDTH - 100, 10)

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}

rebuild_scratch_helpers :: proc() {
	// construct the list of all entities on the temp allocator
	// that way it's easier to loop over later on
	all_ents := make(
		[dynamic]Entity_Handle,
		0,
		len(ctx.state.entities),
		allocator = context.temp_allocator,
	)
	for &e in ctx.state.entities {
		if !is_valid(e) do continue
		append(&all_ents, e.handle)
	}
	ctx.state.scratch.all_entities = all_ents[:]
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
