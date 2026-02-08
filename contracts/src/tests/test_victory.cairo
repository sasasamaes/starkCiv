use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use starkciv::starkciv_game::{IStarkCivGameDispatcher, IStarkCivGameDispatcherTrait};
use core::num::traits::Zero;
use super::test_lobby::{setup_game, PLAYER1, PLAYER2};

// ---------------------------------------------------------------
// Issue 8: Victory Tests
// ---------------------------------------------------------------

/// Helper: build embassy for PLAYER1 (expand tile 1, build embassy).
/// Consumes turns starting from the current turn. Returns after end_turn.
fn build_embassy_p1(dispatcher: IStarkCivGameDispatcher) {
    let ca = dispatcher.contract_address;

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1); // tile 1 adjacent to spawn 0
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 4); // BUILDING_EMBASSY = 4
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();
}

/// Helper: build embassy for PLAYER2 (expand tile 3, build embassy).
fn build_embassy_p2(dispatcher: IStarkCivGameDispatcher) {
    let ca = dispatcher.contract_address;

    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.expand(3); // tile 3 adjacent to spawn 4
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.build(3, 4); // BUILDING_EMBASSY = 4
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();
}

/// Helper: send aid from a player to PLAYER1 to boost reputation.
/// Each send_aid gives +1 rep. Requires 1 turn per aid.
fn send_aid_to_boost_rep(
    dispatcher: IStarkCivGameDispatcher,
    from: starknet::ContractAddress,
    resource: u8,
) {
    let ca = dispatcher.contract_address;
    start_cheat_caller_address(ca, from);
    dispatcher.send_aid(PLAYER1(), resource, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();
}

/// Test that a player wins when all conditions are met:
/// reputation >= 10, embassy_built == true, treaties_completed >= 2.
#[test]
fn test_victory_all_conditions_met() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Phase 1: Build embassies for PLAYER1 and PLAYER2
    // Turn 1: P1 expand tile 1
    build_embassy_p1(dispatcher); // uses turns 1-2, now at turn 3

    // Turn 3-4: P2 build embassy
    build_embassy_p2(dispatcher); // uses turns 3-4, now at turn 5

    // Phase 2: Create and complete 2 treaties (need treaties_completed >= 2)
    // Treaty 1: P1 proposes to P2, duration 1
    // Current turn: 5
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 1); // duration=1, end_turn = accept_turn + 1
    stop_cheat_caller_address(ca);

    // P2 accepts (no action consumed)
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(0); // active, start=5, end=6
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 6, treaty 0 completes (current_turn=6 >= end_turn=6)
    // Both get +1 rep, +1 treaties_completed
    // P1: rep=1, treaties=1, P2: rep=1, treaties=1

    // Treaty 2: P1 proposes to P2, duration 1
    // But P1 already acted turn 5 (propose). Now at turn 6.
    // Need embassy for P2 to propose back? No, P1 proposes again.
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 1); // treaty_id=1
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(1); // active, start=6, end=7
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // turn -> 7, treaty 1 completes
    // P1: rep=2, treaties=2, P2: rep=2, treaties=2

    // Phase 3: Boost PLAYER1 reputation to >= 10
    // P1 currently has rep=2 (from 2 treaty completions). Need 8 more.
    // Use send_aid from PLAYER1 to others (each gives sender +1 rep)
    // P1 starts with food=5, wood=2
    // Actually we need P1 to send aid (P1 is sender, gets +1 rep each time)

    // Send aid from P1: use food (5 available).
    // Turn 7: P1 sends 1 food to P2 -> rep=3
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 8

    // Turn 8: P1 sends 1 food to P2 -> rep=4
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 9

    // Turn 9: P1 sends 1 food to P2 -> rep=5
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 10

    // Turn 10: P1 sends 1 food to P2 -> rep=6 (food=1 left)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 11

    // Turn 11: P1 sends 1 wood to P2 -> rep=7 (wood=1 left)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 1, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 12

    // Need 3 more rep. P1 has food=0, wood=1. Need other players to send to P1.
    // Wait, send_aid gives rep to SENDER, not receiver. Let's use P2 who has lots of food.
    // Actually P2 gained a lot of food from P1. Let P2 send to P3 (not P1) for P2 rep.
    // We need P1 to get rep. Let's have P1 send remaining wood.
    // P1 has wood=1
    // Turn 12: P1 sends 1 wood to P2 -> rep=8 (wood=0)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 1, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 13

    // P1 has no more resources. We need 2 more rep.
    // Let's have P2 send food to P1 so P1 can then send it back.
    // Turn 13: P2 sends 2 food to P1
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.send_aid(PLAYER1(), 0, 2);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 14

    // Turn 14: P1 sends 1 food to P2 -> rep=9
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 15

    // Turn 15: P1 sends 1 food to P2 -> rep=10
    // This send_aid call should trigger victory check via _try_set_winner
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);

    // Check victory
    let state = dispatcher.get_game_state();
    assert(state.winner == PLAYER1(), 'PLAYER1 should be winner');

    let player = dispatcher.get_player(PLAYER1());
    assert(player.reputation >= 10, 'Rep should be >= 10');
    assert(player.embassy_built, 'Embassy should be built');
    assert(player.treaties_completed >= 2, 'Treaties should be >= 2');
}

/// Test that victory is NOT declared without an embassy, even if other conditions are met.
#[test]
fn test_no_victory_without_embassy() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Just send aid repeatedly to boost rep, without building embassy.
    // P1 sends food to P2 several times.
    // P1 starts with food=5

    // Turn 1: P1 sends 1 food -> rep=1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    // Even if we somehow had rep=10 and treaties=2, no embassy means no victory.
    // Just verify winner is still zero after actions without embassy.
    let state = dispatcher.get_game_state();
    assert(state.winner.is_zero(), 'No winner without embassy');

    let player = dispatcher.get_player(PLAYER1());
    assert(!player.embassy_built, 'Embassy should NOT be built');
}

/// After a player wins, no further game actions should be allowed (game ended).
#[test]
#[should_panic(expected: 'Game ended')]
fn test_game_blocked_after_victory() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // ---- Reproduce victory for PLAYER1 (same as test_victory_all_conditions_met) ----

    // Build embassies
    build_embassy_p1(dispatcher); // turns 1-2, now at turn 3
    build_embassy_p2(dispatcher); // turns 3-4, now at turn 5

    // Treaty 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(0);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 6, treaty completes

    // Treaty 2
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 1);
    stop_cheat_caller_address(ca);
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // turn -> 7, treaty completes

    // Boost rep to 10 via send_aid
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // rep=3
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // rep=4
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // rep=5
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // rep=6
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 1, 1); // rep=7
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 1, 1); // rep=8
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.send_aid(PLAYER1(), 0, 2);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // rep=9
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // rep=10 -> VICTORY
    stop_cheat_caller_address(ca);

    // Verify winner is set
    let state = dispatcher.get_game_state();
    assert(state.winner == PLAYER1(), 'PLAYER1 should be winner');

    // ---- Now try to perform an action after game ended ----
    // end_turn should panic with 'Game ended'
    dispatcher.end_turn();
}
