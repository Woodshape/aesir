package game

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:strings"
import "core:testing"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

JUMP_FORCE: f32 : 600.0
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
	variants:         [MAX_ENTITIES]Entity_Variant,
	entity_free_list: [dynamic]int,

	// player stuff
	player_handle:    Entity_Handle,
	scratch:          struct {
		all_entities: []Entity_Handle,
		all_variants: []Entity_Handle,
	},
}

Context :: struct {
	state:   ^Game_State,
	delta_t: f32,
}

ctx: ^Context

Player :: struct {
	handle: Entity_Handle,
}

Input :: struct {
	move_left:  bool,
	move_right: bool,
	jump:       bool,
}

Attack_State :: struct {
	is_attacking: bool,
	timer:        f32,
	duration:     f32,
	start_angle:  f32,
	target_angle: f32,
	base_angle:   f32,
}

update_weapon_aim :: proc(player: ^Entity, weapon: ^Weapon, state: ^Attack_State, mouse_pos: rl.Vector2) {
	player_anim := player.animation
	player_width :=
		f32(player_anim.sprite.texture.width) /
		f32(player_anim.sprite.data.frames) *
		player_anim.data.scale.x
	player_height := f32(player_anim.sprite.texture.height) * player_anim.data.scale.y

	player_center_x := player.pos.x + player_width * 0.5
	player_center_y := player.pos.y + player_height * 0.5

	dir_x := mouse_pos.x - player_center_x
	dir_y := mouse_pos.y - player_center_y

	if !state.is_attacking {
		angle_rad := math.atan2(dir_y, dir_x)
		weapon.rotation_angle = angle_rad * (180.0 / math.PI)
		distance: f32 = 60.0
		weapon.offset.x = f32(math.cos(angle_rad)) * distance
		weapon.offset.y = f32(math.sin(angle_rad)) * distance
	} else {
		progress := state.timer / state.duration
		t := 1.0 - progress
		ease_t := 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t)

		if weapon.stats.animation_type == .swing {
			weapon.rotation_angle =
				state.start_angle + (state.target_angle - state.start_angle) * ease_t
			distance: f32 = 60.0
			angle_rad := weapon.rotation_angle * (math.PI / 180.0)
			weapon.offset.x = f32(math.cos(angle_rad)) * distance
			weapon.offset.y = f32(math.sin(angle_rad)) * distance
		} else if weapon.stats.animation_type == .thrust {
			weapon.rotation_angle = state.base_angle
			dist_t: f32 = t < 0.5 ? t * 2.0 : (1.0 - t) * 2.0
			ease_dist := 1.0 - (1.0 - dist_t) * (1.0 - dist_t)
			distance: f32 = 60.0 + weapon.stats.reach * ease_dist
			angle_rad := weapon.rotation_angle * (math.PI / 180.0)
			weapon.offset.x = f32(math.cos(angle_rad)) * distance
			weapon.offset.y = f32(math.sin(angle_rad)) * distance
		}
	}
}


can_jump :: proc(entity: Entity, jumps_taken: u8) -> bool {
	return jumps_taken <= entity.extra_jumps
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

	player: ^Entity = entity_create(.player)
	player.pos = {WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}
	player.jump_force = JUMP_FORCE

	base_weapon_tex := rl.LoadTexture("res/images/sword.png")
	weapon: ^Weapon = new(Weapon)
	weapon^ = weapon_generate_random()
	weapon.sprite.texture = base_weapon_tex
	weapon.origin = {f32(base_weapon_tex.width) * 0.5, f32(base_weapon_tex.height)}

	for i in 0 ..< 20 {
		r := rand.float32()
		if r > 0.5 do continue
		e := entity_create(.enemy)
		bones := rand.int_max(10) + 1
		e.hp = 50 + i32(bones) * 5
		e.pos = {
			rand.float32() * f32(WINDOW_WIDTH),
			f32(WINDOW_HEIGHT) - 96.0,
		}
		e.radius = 20.0
		#partial switch &var in variant_from_handle(e.handle) {
		case Enemy:
			var.enemy_variant = Skeleton{bones = i32(bones)}
		}
	}

	rebuild_scratch_helpers()
	fmt.println("ents: ", get_all_ents())
	fmt.println("variants: ", get_all_variants())

	for e_handle in get_all_ents() {
		e := entity_from_handle(e_handle)
		fmt.println(e)
	}
	for e_handle in get_all_variants() {
		e := variant_from_handle(e_handle)
		if e_var, ok := e.(Enemy); ok {
			fmt.println(e_var.enemy_variant)
		}
	}

	p_var := variant_from_handle(ctx.state.player_handle)

	player_dead:  bool
	jumps:        u8
	attack_timer: f32
	attack_state: Attack_State

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

			fmt.println("player: ", player)
			fmt.println("entity: ", player)
			fmt.println("variant: ", p_var)
		}

		if attack_timer > 0 {
			attack_timer -= ctx.delta_t
		}

		if attack_state.is_attacking {
			attack_state.timer -= ctx.delta_t
			if attack_state.timer <= 0 {
				attack_state.is_attacking = false
			}
		}

		if rl.IsKeyPressed(.E) {
			weapon^ = weapon_generate_random()
			weapon.sprite.texture = base_weapon_tex
			weapon.origin = {f32(base_weapon_tex.width) * 0.5, f32(base_weapon_tex.height)}
		}

		if rl.IsMouseButtonDown(.LEFT) && attack_timer <= 0 && !player_dead {
			attack_timer = 1.0 / weapon.stats.attack_speed

			if weapon.stats.animation_type != .none {
				attack_state.is_attacking = true
				attack_state.duration = weapon.stats.life_time
				attack_state.timer = attack_state.duration

				pw :=
					f32(player.animation.sprite.texture.width) /
					f32(player.animation.sprite.data.frames) *
					player.animation.data.scale.x
				ph := f32(player.animation.sprite.texture.height) * player.animation.data.scale.y

				player_center_x := player.pos.x + pw * 0.5
				player_center_y := player.pos.y + ph * 0.5

				mouse_pos := rl.GetMousePosition()
				dir_x := mouse_pos.x - player_center_x
				dir_y := mouse_pos.y - player_center_y

				angle_rad := math.atan2(dir_y, dir_x)
				attack_state.base_angle = angle_rad * (180.0 / math.PI)

				if weapon.stats.animation_type == .swing {
					attack_state.start_angle = attack_state.base_angle - 60.0
					attack_state.target_angle = attack_state.base_angle + 60.0
					if mouse_pos.x < player_center_x {
						attack_state.start_angle = attack_state.base_angle + 60.0
						attack_state.target_angle = attack_state.base_angle - 60.0
					}
				}
			}

			player_width :=
				f32(player.animation.sprite.texture.width) /
				f32(player.animation.sprite.data.frames) *
				player.animation.data.scale.x
			player_height :=
				f32(player.animation.sprite.texture.height) * player.animation.data.scale.y

			spawn_pos := rl.Vector2 {
				player.pos.x + player_width * 0.5 + weapon.offset.x,
				player.pos.y + player_height * 0.5 + weapon.offset.y,
			}

			rad := weapon.rotation_angle * (math.PI / 180.0)
			dir := rl.Vector2{math.cos(rad), math.sin(rad)}

			proj_ent := entity_create(.projectile)
			proj_ent.pos = spawn_pos
			proj_ent.vel = dir * weapon.stats.projectile_speed
			if weapon.weapon_type == .sword {
				proj_ent.radius = 35.0
			} else if weapon.weapon_type == .spear {
				proj_ent.radius = 20.0
			} else {
				proj_ent.radius = 10.0
			}

			#partial switch &proj in variant_from_handle(proj_ent.handle) {
			case Projectile:
				proj.damage = weapon.stats.damage
				proj.life_time = weapon.stats.life_time
				proj.pierce_count = weapon.stats.piercing
				proj.shooter_id = player.handle.id
				proj.is_melee = weapon.weapon_type == .sword || weapon.weapon_type == .spear
				proj.color = weapon_rarity_get_color(weapon.rarity)
			}
		}

		// Projectile update and collision
		for p_handle in get_all_ents() {
			e := entity_from_handle(p_handle)
			if !is_valid(e) do continue
			if e.kind != .projectile do continue

			#partial switch &proj in variant_from_handle(p_handle) {
			case Projectile:
				if proj.life_time <= 0 {
					entity_destroy(e)
					continue
				}

				if !proj.is_melee {
					e.pos += e.vel * ctx.delta_t
				} else {
					player_width :=
						f32(player.animation.sprite.texture.width) /
						f32(player.animation.sprite.data.frames) *
						player.animation.data.scale.x
					player_height :=
						f32(player.animation.sprite.texture.height) *
						player.animation.data.scale.y
					e.pos = {
						player.pos.x + player_width * 0.5 + weapon.offset.x,
						player.pos.y + player_height * 0.5 + weapon.offset.y,
					}
				}

				proj.life_time -= ctx.delta_t

				for o_handle in get_all_ents() {
					if p_handle.id == o_handle.id do continue
					other := entity_from_handle(o_handle)
					if !is_valid(other) do continue
					if other.handle.id == proj.shooter_id do continue
					if other.kind == .projectile do continue
					if other.hp <= 0 && other.kind != .player do continue

					dx := e.pos.x - other.pos.x
					dy := e.pos.y - other.pos.y
					dist_sq := dx * dx + dy * dy
					rad_sum := e.radius + other.radius

					if dist_sq <= rad_sum * rad_sum {
						if !projectile_has_hit(proj, other.handle.id) {
							projectile_add_hit(&proj, other.handle.id)
							other.hp -= proj.damage
							proj.pierce_count -= 1

							if other.hp <= 0 && other.kind != .player {
								entity_destroy(other)
							}

							if proj.pierce_count <= 0 {
								proj.life_time = 0
							}
						}
					}
				}
			}
		}

		player.vel.y += GRAVITY * ctx.delta_t

		if input.jump && can_jump(player^, jumps) {
			player.vel.y = -player.jump_force
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

		update_weapon_aim(player, weapon, &attack_state, rl.GetMousePosition())
		update_animation(&player.animation, ctx.delta_t)

		// Rebuild scratch so destroyed entities are excluded from the draw loop
		ctx.state.scratch = {}
		rebuild_scratch_helpers()

		rl.ClearBackground(rl.SKYBLUE)

		draw_animation(player.animation, player.pos, player.flip_x)
		draw_weapon(weapon^, player^)

		// Draw enemies and projectiles
		for handle in get_all_ents() {
			e := entity_from_handle(handle)
			if !is_valid(e) do continue

			if e.kind == .enemy {
				rl.DrawRectangle(i32(e.pos.x - 15), i32(e.pos.y - 30), 30, 40, rl.GRAY)
				hp_ratio := clamp(f32(e.hp) / 100.0, 0.0, 1.0)
				if hp_ratio > 0 {
					rl.DrawRectangle(
						i32(e.pos.x - 15),
						i32(e.pos.y - 40),
						i32(30.0 * hp_ratio),
						5,
						rl.RED,
					)
				}
			}

			if e.kind == .projectile {
				#partial switch proj in variant_from_handle(handle) {
				case Projectile:
					if !proj.is_melee {
						rl.DrawCircle(i32(e.pos.x), i32(e.pos.y), e.radius, proj.color)
					}
				}
			}
		}

		rl.EndDrawing()

		ents := get_all_ents()
		rl.DrawText(fmt.caprintf("delta: %.6f", ctx.delta_t), 10, 10, 20, rl.BLACK)
		rl.DrawText(fmt.caprintf("elapsed: %.2f", ctx.state.time_elapsed), 10, 30, 20, rl.BLACK)
		rl.DrawText(fmt.caprintf("ticks: %d", ctx.state.ticks), 10, 50, 20, rl.BLACK)
		rl.DrawText(fmt.caprintf("ents: %d", len(ents)), 10, 70, 20, rl.BLACK)
		rl.DrawText(
			fmt.caprintf(
				"Weapon: %s %v\nDmg: %d SPD: %.2f",
				weapon_rarity_get_name(weapon.rarity),
				weapon.weapon_type,
				weapon.stats.damage,
				weapon.stats.attack_speed,
			),
			10,
			WINDOW_HEIGHT - 60,
			20,
			weapon_rarity_get_color(weapon.rarity),
		)
		rl.DrawFPS(WINDOW_WIDTH - 100, 10)

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}

draw_weapon :: proc(weapon: Weapon, player: Entity) {
	weapon_sprite := weapon.sprite.texture

	// Calculate actual player center based on current animation
	player_anim := player.animation
	player_width :=
		f32(player_anim.sprite.texture.width) /
		f32(player_anim.sprite.data.frames) *
		player_anim.data.scale.x
	player_height := f32(player_anim.sprite.texture.height) * player_anim.data.scale.y
	player_center_x := player.pos.x + player_width * 0.5
	player_center_y := player.pos.y + player_height * 0.5

	rl.DrawTexturePro(
		weapon_sprite,
		{0, 0, f32(weapon_sprite.width), f32(weapon_sprite.height)},
		{
			player_center_x + weapon.offset.x,
			player_center_y + weapon.offset.y,
			f32(weapon_sprite.width) * ANIMATION_SCALE.x,
			f32(weapon_sprite.height) * ANIMATION_SCALE.y,
		},
		weapon.origin,
		weapon.rotation_angle + 90.0,
		weapon_rarity_get_color(weapon.rarity),
	)
}

rebuild_scratch_helpers :: proc(ctx := ctx) {
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

	all_variants := make(
		[dynamic]Entity_Handle,
		0,
		len(ctx.state.variants),
		allocator = context.temp_allocator,
	)
	for e in ctx.state.variants {
		#partial switch v in e {
		case Player:
			append(&all_variants, v.handle)
		case Enemy:
			append(&all_variants, v.handle)
		}
	}
	ctx.state.scratch.all_variants = all_variants[:]
}

@(test)
test_player_jump :: proc(t: ^testing.T) {
	player: Entity = {
		extra_jumps = 1,
	}

	testing.expect(t, can_jump(player, 0))
	testing.expect(t, can_jump(player, 1))
	testing.expect(t, !can_jump(player, 2))
}
