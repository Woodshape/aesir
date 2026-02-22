package game

import "core:math/rand"
import rl "vendor:raylib"

Weapon_Type :: enum {
	sword,
	bow,
	staff,
	spear,
}

Attack_Animation_Type :: enum {
	none,
	swing,
	thrust,
}

Weapon_Rarity :: enum {
	common,
	uncommon,
	rare,
	epic,
	legendary,
}

weapon_rarity_get_color :: proc(rarity: Weapon_Rarity) -> rl.Color {
	switch rarity {
	case .common:
		return rl.WHITE
	case .uncommon:
		return rl.GREEN
	case .rare:
		return rl.DARKBLUE
	case .epic:
		return rl.PURPLE
	case .legendary:
		return rl.ORANGE
	}
	return rl.WHITE
}

weapon_rarity_get_stat_multiplier :: proc(rarity: Weapon_Rarity) -> f32 {
	switch rarity {
	case .common:
		return 1.0
	case .uncommon:
		return 1.25
	case .rare:
		return 1.5
	case .epic:
		return 2.0
	case .legendary:
		return 3.0
	}
	return 1.0
}

weapon_rarity_get_name :: proc(rarity: Weapon_Rarity) -> string {
	switch rarity {
	case .common:
		return "Common"
	case .uncommon:
		return "Uncommon"
	case .rare:
		return "Rare"
	case .epic:
		return "Epic"
	case .legendary:
		return "Legendary"
	}
	return "Unknown"
}

Weapon_Stats :: struct {
	damage:           i32,
	attack_speed:     f32, // attacks per second
	projectile_speed: f32,
	life_time:        f32, // how long the projectile/hitbox lasts
	piercing:         i32,
	reach:            f32,
	animation_type:   Attack_Animation_Type,
}

Weapon_Sprite :: struct {
	texture: rl.Texture2D,
}

Weapon :: struct {
	weapon_type:    Weapon_Type,
	rarity:         Weapon_Rarity,
	stats:          Weapon_Stats,
	sprite:         Weapon_Sprite,
	rotation_angle: f32,
	offset:         rl.Vector2,
	origin:         rl.Vector2,
}

weapon_generate_random :: proc() -> Weapon {
	wt_int := rand.int_max(4)
	w_type := Weapon_Type(wt_int)

	// Weighted rarity: Common 50%, Uncommon 25%, Rare 15%, Epic 8%, Legendary 2%
	r := rand.float32()
	rarity: Weapon_Rarity
	if r < 0.50 {
		rarity = .common
	} else if r < 0.75 {
		rarity = .uncommon
	} else if r < 0.90 {
		rarity = .rare
	} else if r < 0.98 {
		rarity = .epic
	} else {
		rarity = .legendary
	}

	mult := weapon_rarity_get_stat_multiplier(rarity)
	stats: Weapon_Stats

	switch w_type {
	case .sword:
		base_dmg := 15.0 + rand.float32() * 10.0
		anim_type: Attack_Animation_Type = rand.float32() < 0.5 ? .swing : .thrust
		stats = {
			damage           = i32(base_dmg * mult),
			attack_speed     = (1.5 + rand.float32() * 1.0) * (1.0 + (mult - 1.0) * 0.2),
			projectile_speed = 0.0, // melee
			life_time        = 0.15, // short hitbox lifetime
			piercing         = 999, // swords hit everything in range
			reach            = anim_type == .thrust ? 40.0 + rand.float32() * 20.0 : 0.0,
			animation_type   = anim_type,
		}
	case .bow:
		base_dmg := 10.0 + rand.float32() * 5.0
		stats = {
			damage           = i32(base_dmg * mult),
			attack_speed     = (1.0 + rand.float32() * 0.5) * (1.0 + (mult - 1.0) * 0.2),
			projectile_speed = 600.0 + rand.float32() * 200.0,
			life_time        = 2.0, // arrow flies for 2s
			piercing         = 1,
		}
	case .staff:
		base_dmg := 20.0 + rand.float32() * 10.0
		stats = {
			damage           = i32(base_dmg * mult),
			attack_speed     = (0.5 + rand.float32() * 0.5) * (1.0 + (mult - 1.0) * 0.2),
			projectile_speed = 400.0 + rand.float32() * 100.0,
			life_time        = 3.0,
			piercing         = rarity == .legendary ? 3 : 1,
		}
	case .spear:
		base_dmg := 12.0 + rand.float32() * 8.0
		stats = {
			damage           = i32(base_dmg * mult),
			attack_speed     = (1.2 + rand.float32() * 0.8) * (1.0 + (mult - 1.0) * 0.2),
			projectile_speed = 0.0, // melee
			life_time        = 0.20, // longer hitbox lifetime
			piercing         = 999,
			reach            = 80.0 + rand.float32() * 40.0,
			animation_type   = .thrust,
		}
	}

	return Weapon{weapon_type = w_type, rarity = rarity, stats = stats}
}
