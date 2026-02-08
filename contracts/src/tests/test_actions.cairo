use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use starkciv::starkciv_game::IStarkCivGameDispatcherTrait;
use super::test_lobby::{setup_game, PLAYER1};

// ---------------------------------------------------------------
// Issue 4: Actions Tests (expand, build, train_guard)
// ---------------------------------------------------------------

/// PLAYER1 expands to an adjacent empty tile (tile 1, next to spawn tile 0).
#[test]
fn test_expand_adjacent_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // PLAYER1 spawn at tile 0 (0,0). Tile 1 (1,0) is adjacent and empty.
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    let tile = dispatcher.get_tile(1);
    assert(tile.owner == PLAYER1(), 'PLAYER1 should own tile 1');
    assert(tile.building == 0, 'Building should be NONE');

    // Verify last_action_turn updated
    let player = dispatcher.get_player(PLAYER1());
    assert(player.last_action_turn == 1, 'last_action_turn should be 1');
}

/// Expanding to a non-adjacent tile should panic.
#[test]
#[should_panic(expected: 'Not adjacent')]
fn test_expand_reject_non_adjacent() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // PLAYER1 spawn at tile 0 (0,0). Tile 12 (2,2) is not adjacent.
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(12);
}

/// Expanding to a tile already occupied should panic.
#[test]
#[should_panic(expected: 'Tile occupied')]
fn test_expand_reject_occupied() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Tile 4 is PLAYER2's spawn tile (occupied).
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(4);
}

/// A player who already acted this turn cannot act again.
#[test]
#[should_panic(expected: 'Already acted')]
fn test_expand_reject_already_acted() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // PLAYER1 expands to tile 1 (uses action for turn 1)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);

    // Try expanding again in the same turn (tile 5, adjacent to tile 0)
    dispatcher.expand(5);
}

/// Build a Farm on a tile owned by PLAYER1 (not the City tile).
#[test]
fn test_build_farm_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // First expand to get an empty owned tile
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 2

    // Build Farm on tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 2); // BUILDING_FARM = 2
    stop_cheat_caller_address(ca);

    let tile = dispatcher.get_tile(1);
    assert(tile.building == 2, 'Tile should have Farm');
    assert(tile.owner == PLAYER1(), 'Owner should still be PLAYER1');
}

/// Build an Embassy and verify the player's embassy_built flag is set.
#[test]
fn test_build_embassy_sets_flag() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // First expand to get an empty owned tile
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 2

    // Build Embassy on tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 4); // BUILDING_EMBASSY = 4
    stop_cheat_caller_address(ca);

    let player = dispatcher.get_player(PLAYER1());
    assert(player.embassy_built, 'Embassy flag should be true');

    let tile = dispatcher.get_tile(1);
    assert(tile.building == 4, 'Tile should have Embassy');
}

/// Building on a tile owned by another player should panic.
#[test]
#[should_panic(expected: 'Not your tile')]
fn test_build_reject_enemy_tile() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Tile 4 belongs to PLAYER2. PLAYER1 tries to build there.
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(4, 2);
}

/// Train a guard on a tile owned by PLAYER1.
#[test]
fn test_train_guard_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Train guard on PLAYER1's spawn tile (tile 0, has City building)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.train_guard(0);
    stop_cheat_caller_address(ca);

    let tile = dispatcher.get_tile(0);
    assert(tile.guard, 'Tile should have guard');
}

/// Training a guard on a tile that already has one should panic.
#[test]
#[should_panic(expected: 'Already has guard')]
fn test_train_guard_reject_duplicate() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Train guard on tile 0
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.train_guard(0);
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 2

    // Try to train guard again on tile 0
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.train_guard(0);
}
