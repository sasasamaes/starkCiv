use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::ContractAddress;
use starkciv::starkciv_game::{IStarkCivGameDispatcher, IStarkCivGameDispatcherTrait};

pub fn PLAYER1() -> ContractAddress {
    starknet::contract_address_const::<0x1>()
}

pub fn PLAYER2() -> ContractAddress {
    starknet::contract_address_const::<0x2>()
}

pub fn PLAYER3() -> ContractAddress {
    starknet::contract_address_const::<0x3>()
}

pub fn PLAYER4() -> ContractAddress {
    starknet::contract_address_const::<0x4>()
}

pub fn PLAYER5() -> ContractAddress {
    starknet::contract_address_const::<0x5>()
}

pub fn deploy_contract() -> IStarkCivGameDispatcher {
    let contract = declare("StarkCivGame").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    IStarkCivGameDispatcher { contract_address }
}

pub fn join_all_players(dispatcher: IStarkCivGameDispatcher) {
    let contract_address = dispatcher.contract_address;

    start_cheat_caller_address(contract_address, PLAYER1());
    dispatcher.join_game();
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, PLAYER2());
    dispatcher.join_game();
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, PLAYER3());
    dispatcher.join_game();
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, PLAYER4());
    dispatcher.join_game();
    stop_cheat_caller_address(contract_address);
}

pub fn setup_game() -> IStarkCivGameDispatcher {
    let dispatcher = deploy_contract();
    join_all_players(dispatcher);
    dispatcher.start_game();
    dispatcher
}

#[test]
fn test_join_game_success() {
    let dispatcher = deploy_contract();

    start_cheat_caller_address(dispatcher.contract_address, PLAYER1());
    dispatcher.join_game();
    stop_cheat_caller_address(dispatcher.contract_address);

    let state = dispatcher.get_game_state();
    assert(state.player_count == 1, 'Player count should be 1');

    let player = dispatcher.get_player(PLAYER1());
    assert(player.alive, 'Player should be alive');
    assert(player.food == 5, 'Food should be 5');
    assert(player.wood == 2, 'Wood should be 2');
    assert(player.reputation == 0, 'Rep should be 0');
}

#[test]
fn test_join_4_players() {
    let dispatcher = deploy_contract();
    join_all_players(dispatcher);

    let state = dispatcher.get_game_state();
    assert(state.player_count == 4, 'Player count should be 4');
}

#[test]
#[should_panic(expected: 'Lobby full')]
fn test_reject_5th_player() {
    let dispatcher = deploy_contract();
    join_all_players(dispatcher);

    start_cheat_caller_address(dispatcher.contract_address, PLAYER5());
    dispatcher.join_game();
}

#[test]
#[should_panic(expected: 'Already joined')]
fn test_reject_double_join() {
    let dispatcher = deploy_contract();

    start_cheat_caller_address(dispatcher.contract_address, PLAYER1());
    dispatcher.join_game();
    dispatcher.join_game();
}

#[test]
fn test_start_game_success() {
    let dispatcher = setup_game();

    let state = dispatcher.get_game_state();
    assert(state.game_started, 'Game should be started');
    assert(state.current_turn == 1, 'Turn should be 1');
    assert(state.current_era == 1, 'Era should be 1');

    // Check spawn tiles
    let tile0 = dispatcher.get_tile(0);
    assert(tile0.owner == PLAYER1(), 'Tile 0 should be P1');
    assert(tile0.building == 1, 'Tile 0 should have City');

    let tile4 = dispatcher.get_tile(4);
    assert(tile4.owner == PLAYER2(), 'Tile 4 should be P2');

    let tile20 = dispatcher.get_tile(20);
    assert(tile20.owner == PLAYER3(), 'Tile 20 should be P3');

    let tile24 = dispatcher.get_tile(24);
    assert(tile24.owner == PLAYER4(), 'Tile 24 should be P4');
}

#[test]
#[should_panic(expected: 'Need 4 players')]
fn test_reject_start_with_less_than_4() {
    let dispatcher = deploy_contract();

    start_cheat_caller_address(dispatcher.contract_address, PLAYER1());
    dispatcher.join_game();
    stop_cheat_caller_address(dispatcher.contract_address);

    start_cheat_caller_address(dispatcher.contract_address, PLAYER2());
    dispatcher.join_game();
    stop_cheat_caller_address(dispatcher.contract_address);

    dispatcher.start_game();
}

#[test]
#[should_panic(expected: 'Game already started')]
fn test_reject_join_after_start() {
    let dispatcher = setup_game();

    start_cheat_caller_address(dispatcher.contract_address, PLAYER5());
    dispatcher.join_game();
}

#[test]
#[should_panic(expected: 'Game already started')]
fn test_reject_double_start() {
    let dispatcher = setup_game();
    dispatcher.start_game();
}

#[test]
fn test_player_city_tile_assigned() {
    let dispatcher = setup_game();

    let p1 = dispatcher.get_player(PLAYER1());
    assert(p1.city_tile == 0, 'P1 city should be tile 0');

    let p2 = dispatcher.get_player(PLAYER2());
    assert(p2.city_tile == 4, 'P2 city should be tile 4');

    let p3 = dispatcher.get_player(PLAYER3());
    assert(p3.city_tile == 20, 'P3 city should be tile 20');

    let p4 = dispatcher.get_player(PLAYER4());
    assert(p4.city_tile == 24, 'P4 city should be tile 24');
}
