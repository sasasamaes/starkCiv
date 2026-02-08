use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use starkciv::starkciv_game::IStarkCivGameDispatcherTrait;
use super::test_lobby::{setup_game, PLAYER1};

// ---------------------------------------------------------------
// Issue 3: Turns & Resource Generation Tests
// ---------------------------------------------------------------

/// After calling end_turn, the current turn should increment by 1.
#[test]
fn test_end_turn_increments_turn() {
    let dispatcher = setup_game();

    // Game starts at turn 1
    let state = dispatcher.get_game_state();
    assert(state.current_turn == 1, 'Should start at turn 1');

    dispatcher.end_turn();

    let state = dispatcher.get_game_state();
    assert(state.current_turn == 2, 'Turn should be 2 after end_turn');
}

/// Build a Farm on an adjacent tile owned by PLAYER1, then end turn.
/// PLAYER1 should gain +1 food from the Farm.
#[test]
fn test_resource_generation_farm() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // PLAYER1 is at tile 0 (0,0). Adjacent empty tile: 1 (1,0).
    // Step 1: expand to tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    // End turn so PLAYER1 can act again
    dispatcher.end_turn();

    // Step 2: build Farm on tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 2); // BUILDING_FARM = 2
    stop_cheat_caller_address(ca);

    // Record food before resource generation
    let player_before = dispatcher.get_player(PLAYER1());
    let food_before = player_before.food;

    // End turn triggers resource generation
    dispatcher.end_turn();

    let player_after = dispatcher.get_player(PLAYER1());
    assert(player_after.food == food_before + 1, 'Farm should give +1 food');
}

/// Build a Market on an adjacent tile owned by PLAYER1, then end turn.
/// PLAYER1 should gain +1 wood from the Market.
#[test]
fn test_resource_generation_market() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // PLAYER1 is at tile 0 (0,0). Adjacent empty tile: 1 (1,0).
    // Step 1: expand to tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    // End turn so PLAYER1 can act again
    dispatcher.end_turn();

    // Step 2: build Market on tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 3); // BUILDING_MARKET = 3
    stop_cheat_caller_address(ca);

    // Record wood before resource generation
    let player_before = dispatcher.get_player(PLAYER1());
    let wood_before = player_before.wood;

    // End turn triggers resource generation
    dispatcher.end_turn();

    let player_after = dispatcher.get_player(PLAYER1());
    assert(player_after.wood == wood_before + 1, 'Market should give +1 wood');
}

/// Advance 5 turns from the starting turn to trigger era progression.
/// Era starts at 1, and should increment when turn becomes 6 (turn % 5 == 1).
#[test]
fn test_era_progression() {
    let dispatcher = setup_game();

    // Game starts at turn 1, era 1
    let state = dispatcher.get_game_state();
    assert(state.current_turn == 1, 'Should start at turn 1');
    assert(state.current_era == 1, 'Should start at era 1');

    // End turn 5 times: turn goes 1 -> 2 -> 3 -> 4 -> 5 -> 6
    // Era increments when new_turn % 5 == 1, i.e. turn 6
    dispatcher.end_turn(); // turn = 2
    dispatcher.end_turn(); // turn = 3
    dispatcher.end_turn(); // turn = 4
    dispatcher.end_turn(); // turn = 5
    dispatcher.end_turn(); // turn = 6 -> era = 2

    let state = dispatcher.get_game_state();
    assert(state.current_turn == 6, 'Turn should be 6');
    assert(state.current_era == 2, 'Era should be 2');
}

/// Build two Farms on separate tiles and verify cumulative resource generation.
/// PLAYER1 should gain +2 food per end_turn with 2 Farms.
#[test]
fn test_multiple_farms_accumulate() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // PLAYER1 at tile 0 (0,0). Adjacent tiles: 1 (1,0) and 5 (0,1).
    // Turn 1: expand to tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 2

    // Turn 2: build Farm on tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 2); // BUILDING_FARM = 2
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 3

    // Turn 3: expand to tile 5 (adjacent to tile 0)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(5);
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 4

    // Turn 4: build Farm on tile 5
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(5, 2); // BUILDING_FARM = 2
    stop_cheat_caller_address(ca);

    // Record food before resource generation
    let player_before = dispatcher.get_player(PLAYER1());
    let food_before = player_before.food;

    // End turn: both farms produce, +2 food total
    dispatcher.end_turn(); // turn -> 5

    let player_after = dispatcher.get_player(PLAYER1());
    assert(player_after.food == food_before + 2, 'Two farms should give +2 food');
}
