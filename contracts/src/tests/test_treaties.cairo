use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use starkciv::starkciv_game::{IStarkCivGameDispatcher, IStarkCivGameDispatcherTrait};
use super::test_lobby::{setup_game, PLAYER1, PLAYER2};

// ---------------------------------------------------------------
// Issue 6: Treaty Tests
// ---------------------------------------------------------------

/// Helper: build an embassy for a player. Uses 2 turns (expand + build).
/// Returns the tile_id where the embassy was built.
fn build_embassy_for_player1(dispatcher: IStarkCivGameDispatcher) {
    let ca = dispatcher.contract_address;

    // Turn 1: PLAYER1 expands to tile 1 (adjacent to spawn tile 0)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 2

    // Turn 2: PLAYER1 builds Embassy on tile 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 4); // BUILDING_EMBASSY = 4
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 3
}

/// PLAYER1 (with embassy) proposes a treaty to PLAYER2.
#[test]
fn test_propose_treaty_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Build embassy for PLAYER1 (takes turns 1-2, ends at turn 3)
    build_embassy_for_player1(dispatcher);

    // Turn 3: PLAYER1 proposes a treaty to PLAYER2 (duration 3 turns)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 3);
    stop_cheat_caller_address(ca);

    // Verify treaty was created
    let treaties = dispatcher.list_treaties_for(PLAYER1());
    assert(treaties.len() == 1, 'Should have 1 treaty');
    let treaty = *treaties.at(0);
    assert(treaty.from == PLAYER1(), 'From should be PLAYER1');
    assert(treaty.to == PLAYER2(), 'To should be PLAYER2');
    assert(treaty.status == 0, 'Status should be PENDING (0)');
    assert(treaty.duration == 3, 'Duration should be 3');
}

/// PLAYER1 (without embassy) tries to propose a treaty. Should panic.
#[test]
#[should_panic(expected: 'No embassy')]
fn test_propose_reject_no_embassy() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // PLAYER1 has no embassy, tries to propose treaty
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 3);
}

/// PLAYER1 proposes, PLAYER2 accepts. Treaty should become active.
#[test]
fn test_accept_treaty_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Build embassy for PLAYER1
    build_embassy_for_player1(dispatcher);

    // Turn 3: PLAYER1 proposes treaty (duration 3)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 3);
    stop_cheat_caller_address(ca);

    // PLAYER2 accepts (accept_treaty does NOT consume action)
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(0); // treaty_id = 0
    stop_cheat_caller_address(ca);

    // Verify treaty is now ACTIVE
    let treaties = dispatcher.list_treaties_for(PLAYER1());
    let treaty = *treaties.at(0);
    assert(treaty.status == 1, 'Status should be ACTIVE (1)');
    assert(treaty.start_turn == 3, 'Start turn should be 3');
    assert(treaty.end_turn == 6, 'End turn should be 6');
}

/// Break a treaty: the breaker loses -2 rep, -1 food, -1 wood.
#[test]
fn test_break_treaty_penalties() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Build embassy for PLAYER1
    build_embassy_for_player1(dispatcher);

    // Turn 3: propose treaty
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 5);
    stop_cheat_caller_address(ca);

    // PLAYER2 accepts
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(0);
    stop_cheat_caller_address(ca);

    // Record PLAYER1 state before breaking
    let p1_before = dispatcher.get_player(PLAYER1());

    // PLAYER1 breaks treaty (break_treaty does NOT consume action)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.break_treaty(0);
    stop_cheat_caller_address(ca);

    let p1_after = dispatcher.get_player(PLAYER1());

    // Penalties: -2 rep, -1 food, -1 wood
    assert(p1_after.reputation == p1_before.reputation - 2, 'Rep should decrease by 2');
    assert(p1_after.food == p1_before.food - 1, 'Food should decrease by 1');
    assert(p1_after.wood == p1_before.wood - 1, 'Wood should decrease by 1');

    // Treaty status should be BROKEN (3)
    let treaties = dispatcher.list_treaties_for(PLAYER1());
    let treaty = *treaties.at(0);
    assert(treaty.status == 3, 'Status should be BROKEN (3)');
}

/// A treaty with duration 2 accepted at turn 3 ends at turn 5.
/// Advancing past end_turn via end_turn() should complete the treaty,
/// giving both parties +1 rep and +1 treaties_completed.
#[test]
fn test_treaty_completion() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Build embassy for PLAYER1 (uses turns 1-2, lands on turn 3)
    build_embassy_for_player1(dispatcher);

    // Turn 3: propose treaty with duration 2 (end_turn = 3 + 2 = 5)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 2);
    stop_cheat_caller_address(ca);

    // PLAYER2 accepts at turn 3
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(0);
    stop_cheat_caller_address(ca);

    // Record state before completion
    let p1_before = dispatcher.get_player(PLAYER1());
    let p2_before = dispatcher.get_player(PLAYER2());

    // Advance turns: turn 3 -> 4 -> 5
    // Treaty completes when current_turn >= end_turn (5)
    dispatcher.end_turn(); // turn -> 4
    dispatcher.end_turn(); // turn -> 5, treaty end_turn=5, treaty completes

    let p1_after = dispatcher.get_player(PLAYER1());
    let p2_after = dispatcher.get_player(PLAYER2());

    // Both parties get +1 rep and +1 treaties_completed
    assert(p1_after.reputation == p1_before.reputation + 1, 'P1 rep should increase by 1');
    assert(p2_after.reputation == p2_before.reputation + 1, 'P2 rep should increase by 1');
    assert(p1_after.treaties_completed == p1_before.treaties_completed + 1, 'P1 treaties +1');
    assert(p2_after.treaties_completed == p2_before.treaties_completed + 1, 'P2 treaties +1');

    // Treaty status should be COMPLETED (2)
    let treaties = dispatcher.list_treaties_for(PLAYER1());
    let treaty = *treaties.at(0);
    assert(treaty.status == 2, 'Status should be COMPLETED (2)');
}
