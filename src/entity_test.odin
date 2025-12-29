#+test
package game

import "base:runtime"
import "core:log"
import "core:testing"
import rl "vendor:raylib"

test_ctx: ^Context
test_state: ^Game_State
test_player_ent: ^Entity
test_player: ^Player

@(init)
entity_init :: proc "contextless" () {
	context = runtime.default_context()

	test_ctx = new(Context)
	test_state: ^Game_State = new(Game_State)
	test_ctx.state = test_state

	ctx = test_ctx

	assert_contextless(ctx.state.player_handle == Entity_Handle{})
	assert_contextless(ctx.state.latest_entity_id == 0)
	assert_contextless(len(ctx.state.entity_free_list) == 0)
	assert_contextless(len(ctx.state.entities) == MAX_ENTITIES)

	assert_contextless(ctx.state.entities[0].allocated == false)
	assert_contextless(ctx.state.entities[1].allocated == false)

	test_player_ent = entity_create(.player)
	test_player = new(Player)
	test_player.handle = test_player_ent.handle
}

@(test)
test_entity_create :: proc(t: ^testing.T) {
	ent := test_player_ent

	testing.expect_value(t, ent.handle.index, 1)
	testing.expect_value(t, ent.handle.id, 1)
	testing.expect_value(t, ent.handle, ctx.state.player_handle)

	testing.expect_value(t, ctx.state.entities[ent.handle.index], ent^)
	testing.expect_value(t, ctx.state.entities[ent.handle.index].kind, Entity_Kind.player)

	testing.expect_value(t, ctx.state.entities[0].allocated, false)
	testing.expect_value(t, ctx.state.entities[1].allocated, true)

	testing.expect_value(t, len(ctx.state.entity_free_list), 0)
	testing.expect(t, ctx.state.latest_entity_id >= 1)

	rebuild_scratch_helpers()
	ents := get_all_ents()
	testing.expect(t, len(ents) >= 1)

	vars := get_all_variants()
	testing.expect(t, len(vars) >= 1)

	entity_destroy(ent)
	rebuild_scratch_helpers()
	ents_after_des := get_all_ents()
	vars_after_des := get_all_variants()

	testing.expect_value(t, len(ents_after_des), len(ents) - 1)
	testing.expect_value(t, len(vars_after_des), len(vars) - 1)

	testing.expect_value(t, ctx.state.entities[ent.handle.index], ent^)

	delete(ctx.state.entity_free_list)
}

@(test)
test_entity_player :: proc(t: ^testing.T) {
	ent := test_player_ent
	ent.hp = 100

	testing.expect_value(t, ctx.state.entities[ent.handle.index].kind, Entity_Kind.player)

	variant := variant_from_handle(ent.handle)
	if p, ok := variant.(Player); ok {
		testing.expect_value(t, p, test_player^)
		testing.expect_value(t, ent.hp, 100)
	} else {
		testing.fail(t)
	}
}

@(test)
test_entity_enemy :: proc(t: ^testing.T) {
	local_ctx := new(Context)
	defer free(local_ctx)
	local_state: ^Game_State = new(Game_State)
	defer free(local_state)
	local_ctx.state = local_state

	ent := entity_create(.enemy, local_ctx)
	testing.expect_value(t, local_ctx.state.entities[ent.handle.index].kind, Entity_Kind.enemy)

	skeleton := Skeleton {
		bones = 1,
	}
	enemy := Enemy {
		handle        = ent.handle,
		enemy_variant = skeleton,
	}

	variant := variant_from_handle(ent.handle, local_ctx)
	if p, ok := variant.(Enemy); ok {
		p.enemy_variant = skeleton
		testing.expect_value(t, p, enemy)
	} else {
		log.fatal(variant)
		testing.fail(t)
	}
}
