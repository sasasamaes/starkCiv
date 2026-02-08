// End-to-end integration test: full game flow
// Tests the complete flow: join -> start -> expand -> build -> aid -> treaty -> vote -> victory

use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use starkciv::starkciv_game::IStarkCivGameDispatcherTrait;
use super::test_lobby::{PLAYER1, PLAYER2, PLAYER3, PLAYER4, deploy_contract, join_all_players};

#[test]
fn test_full_game_flow() {
    // === SETUP: Deploy and start game ===
    // Players start with food=5, wood=2
    let dispatcher = deploy_contract();
    let ca = dispatcher.contract_address;

    join_all_players(dispatcher);
    dispatcher.start_game();

    let state = dispatcher.get_game_state();
    assert(state.game_started, 'Game should start');
    assert(state.current_turn == 1, 'Turn should be 1');
    assert(state.current_era == 1, 'Era should be 1');

    // Verify spawn tiles
    let t0 = dispatcher.get_tile(0);
    assert(t0.owner == PLAYER1(), 'P1 owns tile 0');
    assert(t0.building == 1, 'Tile 0 has City');

    // === TURN 1: P1 expands to tile 1 ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    let t1 = dispatcher.get_tile(1);
    assert(t1.owner == PLAYER1(), 'P1 owns tile 1');

    dispatcher.end_turn(); // Turn 1 -> 2

    // === TURN 2: P1 builds Farm on tile 1 ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 2); // Farm
    stop_cheat_caller_address(ca);

    let t1 = dispatcher.get_tile(1);
    assert(t1.building == 2, 'Tile 1 has Farm');

    dispatcher.end_turn(); // Turn 2 -> 3

    // Verify resource gen: P1 started with food=5, +1 from Farm = 6
    let p1 = dispatcher.get_player(PLAYER1());
    assert(p1.food == 6, 'P1 food should be 6');

    // === TURN 3: P1 expands to tile 5 ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(5);
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // Turn 3 -> 4

    // === TURN 4: P1 builds Embassy ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(5, 4); // Embassy
    stop_cheat_caller_address(ca);

    let p1 = dispatcher.get_player(PLAYER1());
    assert(p1.embassy_built, 'P1 has embassy');

    dispatcher.end_turn(); // Turn 4 -> 5

    // === TURN 5: P1 sends food aid ===
    // P1 food: 5 + 3 turns of farm = 8, minus 1 aid = 7
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // 1 food
    stop_cheat_caller_address(ca);

    let p1 = dispatcher.get_player(PLAYER1());
    assert(p1.reputation == 1, 'P1 rep should be 1');

    dispatcher.end_turn(); // Turn 5 -> 6 (Era 2)

    let state = dispatcher.get_game_state();
    assert(state.current_era == 2, 'Era should be 2');

    // === TURN 6: P1 proposes treaty (treaty_id=0) ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 2);
    stop_cheat_caller_address(ca);

    // P2 accepts (free action)
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(0); // treaty_id=0
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // Turn 6 -> 7

    // === TURN 7: Aid ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // food aid, rep=2
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // Turn 7 -> 8 (treaty 0 completes: end_turn=8)

    // === TURN 8: Aid ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER3(), 0, 1); // food aid, rep=4 (3 from aids + 1 treaty)
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // Turn 8 -> 9

    // Treaty 0 completed at turn 8
    let p1 = dispatcher.get_player(PLAYER1());
    assert(p1.treaties_completed == 1, 'P1 has 1 treaty done');
    assert(p1.reputation == 4, 'P1 rep is 4');

    // === TURNS 9-10: More food aid ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER3(), 0, 1); // rep=5
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // Turn 9 -> 10

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER4(), 0, 1); // rep=6
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // Turn 10 -> 11 (Era 3)

    let state = dispatcher.get_game_state();
    assert(state.current_era == 3, 'Era should be 3');

    // === GOVERNANCE: Subsidy proposal (proposal_id=0) ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.create_proposal(1, PLAYER1());
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.vote(0, true);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.vote(0, true);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER3());
    dispatcher.vote(0, true);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER4());
    dispatcher.vote(0, false);
    stop_cheat_caller_address(ca);

    // Execute (3/4 majority)
    dispatcher.execute_proposal(0);

    // Verify subsidy applied (+1 food to all)
    let p2 = dispatcher.get_player(PLAYER2());
    assert(p2.food > 5, 'P2 got subsidy food');

    // === Second treaty for victory (treaty_id=1) ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER3(), 0, 2);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER3());
    dispatcher.accept_treaty(1); // treaty_id=1
    stop_cheat_caller_address(ca);

    dispatcher.end_turn(); // Turn 11 -> 12

    // === TURN 12: Aid (food) ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 1); // food aid, rep=7
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // Turn 12 -> 13 (treaty 1 completes: end_turn=13)

    // === TURN 13: Aid ===
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER3(), 0, 1); // food aid, rep=9
    stop_cheat_caller_address(ca);
    dispatcher.end_turn(); // Turn 13 -> 14

    // Treaty 1 completed at turn 13
    let p1 = dispatcher.get_player(PLAYER1());
    assert(p1.treaties_completed == 2, 'P1 has 2 treaties');

    // === TURN 14: Final aid triggers victory ===
    // rep=9 + 1 = 10, plus embassy + 2 treaties = victory!
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER4(), 0, 1); // rep=10 -> victory!
    stop_cheat_caller_address(ca);

    // === VERIFY VICTORY ===
    let state = dispatcher.get_game_state();
    assert(state.winner == PLAYER1(), 'P1 should be winner');

    let p1 = dispatcher.get_player(PLAYER1());
    assert(p1.reputation >= 10, 'P1 rep >= 10');
    assert(p1.embassy_built, 'P1 has embassy');
    assert(p1.treaties_completed >= 2, 'P1 has 2+ treaties');
}

#[test]
fn test_treaty_break_penalties() {
    let dispatcher = deploy_contract();
    let ca = dispatcher.contract_address;

    join_all_players(dispatcher);
    dispatcher.start_game();

    // P1 builds embassy
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.build(1, 4);
    stop_cheat_caller_address(ca);
    dispatcher.end_turn();

    // P1 proposes treaty (treaty_id=0)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.propose_treaty(PLAYER2(), 0, 5);
    stop_cheat_caller_address(ca);

    // P2 accepts
    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.accept_treaty(0);
    stop_cheat_caller_address(ca);

    // P1 breaks treaty
    let p1_before = dispatcher.get_player(PLAYER1());

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.break_treaty(0);
    stop_cheat_caller_address(ca);

    let p1_after = dispatcher.get_player(PLAYER1());
    assert(p1_after.reputation == p1_before.reputation - 2, 'Rep penalty -2');
    assert(p1_after.food == p1_before.food - 1, 'Food penalty -1');
    assert(p1_after.wood == p1_before.wood - 1, 'Wood penalty -1');
}

#[test]
fn test_multi_player_same_turn() {
    let dispatcher = deploy_contract();
    let ca = dispatcher.contract_address;

    join_all_players(dispatcher);
    dispatcher.start_game();

    // All 4 players expand in the same turn
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.expand(1);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.expand(3);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER3());
    dispatcher.expand(21);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER4());
    dispatcher.expand(23);
    stop_cheat_caller_address(ca);

    assert(dispatcher.get_tile(1).owner == PLAYER1(), 'P1 at tile 1');
    assert(dispatcher.get_tile(3).owner == PLAYER2(), 'P2 at tile 3');
    assert(dispatcher.get_tile(21).owner == PLAYER3(), 'P3 at tile 21');
    assert(dispatcher.get_tile(23).owner == PLAYER4(), 'P4 at tile 23');
}
