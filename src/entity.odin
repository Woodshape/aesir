package game

import "core:fmt"
import "core:log"
import "core:testing"
import rl "vendor:raylib"

zero_entity: Entity = {} //readonlytodo

Entity_Variant :: union {
	^Player,
	^Enemy,
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
	handle:      Entity_Handle,
	kind:        Entity_Kind,
	variant:     Entity_Variant,

	// todo, move this into static entity data
	update_proc: proc(_: ^Entity),
	draw_proc:   proc(_: Entity),

	// big sloppy entity state dump.
	// add whatever you need in here.
	pos:         rl.Vector2,
	flip_x:      bool,

	// this gets zeroed every frame. Useful for passing data to other systems.
	scratch:     struct{},
}

get_player :: proc() -> ^Entity {
	return entity_from_handle(ctx.state.player_handle)
}

get_all_ents :: proc() -> []Entity_Handle {
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
	entity_setup(&zero_entity, .none)
}

entity_setup :: proc(e: ^Entity, kind: Entity_Kind) {
	switch kind {
	case .none:
	case .player:
		setup_player(e)
	case .enemy:
		setup_enemy(e)
	}
}

setup_player :: proc(e: ^Entity) {
	e.kind = .player

	ctx.state.player_handle = e.handle

	e.update_proc = proc(e: ^Entity) {}
	e.draw_proc = proc(e: Entity) {}
}

setup_enemy :: proc(e: ^Entity) {
	e.kind = .enemy
}

entity_from_handle :: proc(handle: Entity_Handle) -> (entity: ^Entity, ok: bool) #optional_ok {
	if handle.index <= 0 || handle.index > ctx.state.entity_top_count {
		return &zero_entity, false
	}

	ent := &ctx.state.entities[handle.index]
	if ent.handle.id != handle.id {
		return &zero_entity, false
	}

	return ent, true
}

entity_create :: proc(kind: Entity_Kind) -> ^Entity {
	index := -1
	if len(ctx.state.entity_free_list) > 0 {
		index = pop(&ctx.state.entity_free_list)
	}

	if index == -1 {
		assert(ctx.state.entity_top_count + 1 < MAX_ENTITIES, "ran out of entities, increase size")
		ctx.state.entity_top_count += 1
		index = ctx.state.entity_top_count
	}

	log.infof("index: %d\n", index)

	ent := &ctx.state.entities[index]
	ent.handle.index = index
	ent.handle.id = ctx.state.latest_entity_id + 1
	ctx.state.latest_entity_id = ent.handle.id

	entity_setup(ent, kind)
	fmt.assertf(ent.kind != nil, "entity %v needs to define a kind during setup", kind)

	return ent
}

entity_destroy :: proc(e: ^Entity) {
	append(&ctx.state.entity_free_list, e.handle.index)
	e^ = {}
}

@(test)
test_entity_create :: proc(t: ^testing.T) {
	ctx = new(Context)
	state: ^Game_State = new(Game_State)
	defer free(ctx)
	defer free(state)
	ctx.state = state

	testing.expect_value(t, ctx.state.player_handle, Entity_Handle{})
	testing.expect_value(t, ctx.state.latest_entity_id, 0)
	testing.expect_value(t, len(ctx.state.entity_free_list), 0)
	testing.expect_value(t, len(ctx.state.entities), MAX_ENTITIES)

	ent := entity_create(.player)
	ent.pos = rl.Vector2{1, 1}
	testing.expect_value(t, ent.handle.index, 1)
	testing.expect_value(t, ent.handle.id, 1)
	testing.expect_value(t, ent.handle, ctx.state.player_handle)

	testing.expect_value(t, ctx.state.entities[ent.handle.index], ent^)

	testing.expect_value(t, ctx.state.latest_entity_id, 1)
	testing.expect_value(t, len(ctx.state.entity_free_list), 0)
}
