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
	// log.infof("ents: %v\n", ents)
}

@(test)
test_entity_player :: proc(t: ^testing.T) {
	ent := test_player_ent
	testing.expect_value(t, ctx.state.entities[ent.handle.index].kind, Entity_Kind.player)

	variant := get_variant_from_handle(ent.handle)
	testing.expect_value(t, variant, test_player^)
}

@(test)
test_entity_enemy :: proc(t: ^testing.T) {
	ent := entity_create(.enemy)
	testing.expect_value(t, ctx.state.entities[ent.handle.index].kind, Entity_Kind.enemy)

	enemy := Enemy {
		handle = ent.handle,
	}

	variant := get_variant_from_handle(ent.handle)
	testing.expect_value(t, variant, enemy)
}
