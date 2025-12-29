package game

import "core:fmt"
import "core:log"
import "core:testing"
import rl "vendor:raylib"

@(rodata)
zero_entity: Entity = {
	allocated = false,
	handle = {id = -1, index = 1},
	kind = .none,
} //readonlytodo

@(rodata)
nothing_entity: Nothing = {}
Nothing :: struct {}

Entity_Variant :: union #no_nil {
	Nothing,
	Player,
	Enemy,
}

Entity_Kind :: enum {
	none,
	player,
	enemy,
}

Entity_Handle :: struct {
	index: int,
	id:    int,
}

Entity :: struct {
	allocated:   bool,

	// structs
	handle:      Entity_Handle,
	kind:        Entity_Kind,

	// callbacks
	update_proc: proc(_: ^Entity),
	draw_proc:   proc(_: Entity),

	// big sloppy entity state dump.
	// add whatever you need in here.
	animation:   Animation,
	hp:          i32,
	pos:         rl.Vector2,
	vel:         rl.Vector2,
	flip_x:      bool,
	extra_jumps: u8,
	jump_force:  f32,
	grounded:    bool,

	// this gets zeroed every frame. Useful for passing data to other systems.
	scratch:     struct{},
}

get_player :: proc() -> ^Entity {
	return entity_from_handle(ctx.state.player_handle)
}

variant_from_handle :: proc(handle: Entity_Handle, ctx := ctx) -> ^Entity_Variant {
	return &ctx.state.variants[handle.index]
}

get_all_variants :: proc(ctx := ctx) -> []Entity_Handle {
	return ctx.state.scratch.all_variants
}

get_all_ents :: proc(ctx := ctx) -> []Entity_Handle {
	return ctx.state.scratch.all_entities
}

is_valid :: proc {
	entity_is_valid,
	entity_is_valid_ptr,
}

entity_is_valid :: proc(entity: Entity) -> bool {
	return entity.handle.id != 0
}

entity_is_valid_ptr :: proc(entity: ^Entity) -> bool {
	return entity != nil && entity_is_valid(entity^)
}

entity_init_core :: proc() {
	// make sure the zero entity has good defaults, so we don't crash on stuff like functions pointers
	fmt.assertf(zero_entity.kind == .none, "zero entity kind invalid: %v", zero_entity.kind)
	entity_setup(&zero_entity, nil)
}

entity_setup :: proc(e: ^Entity, kind: Entity_Kind, ctx := ctx) {
	switch kind {
	case .none:
	case .player:
		setup_player(e, ctx)
	case .enemy:
		setup_enemy(e, ctx)
	}
}

setup_player :: proc(e: ^Entity, ctx := ctx) {
	e.kind = .player
	ctx.state.player_handle = e.handle

	player: Player = {
		handle = e.handle,
	}

	if v, ok := ctx.state.variants[e.handle.index].(Nothing); !ok {
		fmt.assertf(false, "entity for handle %v already exists: %v", e.handle, v)
	}

	ctx.state.variants[e.handle.index] = player
}

setup_enemy :: proc(e: ^Entity, ctx := ctx) {
	e.kind = .enemy

	enemy: Enemy = {
		handle = e.handle,
	}

	if v, ok := ctx.state.variants[e.handle.index].(Nothing); !ok {
		fmt.assertf(false, "entity for handle %v already exists: %v", e.handle, v)
	}

	ctx.state.variants[e.handle.index] = enemy
}

entity_from_handle :: proc(
	handle: Entity_Handle,
	ctx := ctx,
) -> (
	entity: ^Entity,
	ok: bool,
) #optional_ok {
	if handle.index <= 0 || handle.index > ctx.state.entity_top_count {
		log.errorf("index out of bounds: %d\n", handle.index)
		return &zero_entity, false
	}

	ent := &ctx.state.entities[handle.index]
	if ent.handle.id != handle.id {
		log.warnf("no entity found for handle: %d\n", handle.id)
		return &zero_entity, false
	}

	return ent, true
}

entity_create :: proc(kind: Entity_Kind, ctx := ctx) -> ^Entity {
	index := -1
	if len(ctx.state.entity_free_list) > 0 {
		index = pop(&ctx.state.entity_free_list)
	}

	if index == -1 {
		assert(ctx.state.entity_top_count + 1 < MAX_ENTITIES, "ran out of entities, increase size")
		ctx.state.entity_top_count += 1
		index = ctx.state.entity_top_count
	}

	ent := &ctx.state.entities[index]
	ent.handle.index = index
	ent.handle.id = ctx.state.latest_entity_id + 1
	ctx.state.latest_entity_id = ent.handle.id

	entity_setup(ent, kind, ctx)
	fmt.assertf(ent.kind != nil, "entity %v needs to define a kind during setup", kind)

	ent.allocated = true

	return ent
}

entity_destroy :: proc(e: ^Entity, ctx := ctx) {
	append(&ctx.state.entity_free_list, e.handle.index)
	ctx.state.variants[e.handle.index] = nothing_entity
	e^ = {}
}
