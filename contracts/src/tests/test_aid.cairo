use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use starkciv::starkciv_game::IStarkCivGameDispatcherTrait;
use super::test_lobby::{setup_game, PLAYER1, PLAYER2};

// ---------------------------------------------------------------
// Issue 5: Send Aid & Reputation Tests
// ---------------------------------------------------------------

/// Send 2 food from PLAYER1 to PLAYER2. Verify resource transfer and +1 rep to sender.
#[test]
fn test_send_aid_food_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Both players start with food=5, wood=2, rep=0
    let p1_before = dispatcher.get_player(PLAYER1());
    let p2_before = dispatcher.get_player(PLAYER2());
    assert(p1_before.food == 5, 'P1 should start with 5 food');
    assert(p2_before.food == 5, 'P2 should start with 5 food');

    // PLAYER1 sends 2 food to PLAYER2 (resource_type 0 = food)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 2);
    stop_cheat_caller_address(ca);

    let p1_after = dispatcher.get_player(PLAYER1());
    let p2_after = dispatcher.get_player(PLAYER2());

    // PLAYER1 loses 2 food, gains +1 reputation
    assert(p1_after.food == 3, 'P1 should have 3 food');
    assert(p1_after.reputation == 1, 'P1 rep should be 1');

    // PLAYER2 gains 2 food
    assert(p2_after.food == 7, 'P2 should have 7 food');
}

/// Send 1 wood from PLAYER1 to PLAYER2. Verify resource transfer and +1 rep to sender.
#[test]
fn test_send_aid_wood_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    let p1_before = dispatcher.get_player(PLAYER1());
    let p2_before = dispatcher.get_player(PLAYER2());
    assert(p1_before.wood == 2, 'P1 should start with 2 wood');
    assert(p2_before.wood == 2, 'P2 should start with 2 wood');

    // PLAYER1 sends 1 wood to PLAYER2 (resource_type 1 = wood)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 1, 1);
    stop_cheat_caller_address(ca);

    let p1_after = dispatcher.get_player(PLAYER1());
    let p2_after = dispatcher.get_player(PLAYER2());

    assert(p1_after.wood == 1, 'P1 should have 1 wood');
    assert(p1_after.reputation == 1, 'P1 rep should be 1');
    assert(p2_after.wood == 3, 'P2 should have 3 wood');
}

/// Attempting to send more food than available should panic.
#[test]
#[should_panic(expected: 'Insufficient food')]
fn test_send_aid_reject_insufficient() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // PLAYER1 has 5 food, tries to send 10
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER2(), 0, 10);
}

/// Attempting to send aid to yourself should panic.
#[test]
#[should_panic(expected: 'Cannot aid yourself')]
fn test_send_aid_reject_self() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.send_aid(PLAYER1(), 0, 1);
}
