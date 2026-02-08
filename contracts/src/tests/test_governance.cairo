use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use starkciv::starkciv_game::IStarkCivGameDispatcherTrait;
use super::test_lobby::{setup_game, PLAYER1, PLAYER2, PLAYER3, PLAYER4};

// ---------------------------------------------------------------
// Issue 7: Governance Tests (proposals, voting, execution)
// ---------------------------------------------------------------

/// Create a proposal at era start (turn 1). Should succeed.
#[test]
fn test_create_proposal_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Turn 1, era 1 (turn % 5 == 1 => era start)
    // PLAYER1 creates a SUBSIDY proposal (kind=1) targeting PLAYER2
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.create_proposal(1, PLAYER2()); // PROPOSAL_SUBSIDY = 1
    stop_cheat_caller_address(ca);

    // Verify proposal was created
    let proposal = dispatcher.get_active_proposal();
    assert(proposal.kind == 1, 'Kind should be SUBSIDY (1)');
    assert(proposal.era == 1, 'Era should be 1');
    assert(!proposal.executed, 'Should not be executed');
    assert(proposal.votes_for == 0, 'Votes for should be 0');
    assert(proposal.votes_against == 0, 'Votes against should be 0');
}

/// All 4 players vote on a proposal. Verify votes are recorded.
#[test]
fn test_vote_success() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Create proposal at turn 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.create_proposal(1, PLAYER2()); // PROPOSAL_SUBSIDY = 1
    stop_cheat_caller_address(ca);

    // All 4 players vote: 3 for, 1 against
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

    // Verify vote counts
    let proposal = dispatcher.get_active_proposal();
    assert(proposal.votes_for == 3, 'Votes for should be 3');
    assert(proposal.votes_against == 1, 'Votes against should be 1');
}

/// Execute a SUBSIDY proposal with 3 votes_for. All alive players get +1 food.
#[test]
fn test_execute_subsidy() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Record food before
    let p1_food_before = dispatcher.get_player(PLAYER1()).food;
    let p2_food_before = dispatcher.get_player(PLAYER2()).food;
    let p3_food_before = dispatcher.get_player(PLAYER3()).food;
    let p4_food_before = dispatcher.get_player(PLAYER4()).food;

    // Create SUBSIDY proposal at turn 1
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.create_proposal(1, PLAYER2()); // PROPOSAL_SUBSIDY = 1
    stop_cheat_caller_address(ca);

    // All 4 vote: 3 for, 1 against (passes with votes_for >= 3)
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

    // Execute proposal
    dispatcher.execute_proposal(0);

    // Verify all players got +1 food
    assert(dispatcher.get_player(PLAYER1()).food == p1_food_before + 1, 'P1 food should +1');
    assert(dispatcher.get_player(PLAYER2()).food == p2_food_before + 1, 'P2 food should +1');
    assert(dispatcher.get_player(PLAYER3()).food == p3_food_before + 1, 'P3 food should +1');
    assert(dispatcher.get_player(PLAYER4()).food == p4_food_before + 1, 'P4 food should +1');
}

/// Execute a proposal where votes_against is the majority (3 against, 1 for).
/// Proposal should be marked executed but effects should NOT be applied.
#[test]
fn test_execute_rejected() {
    let dispatcher = setup_game();
    let ca = dispatcher.contract_address;

    // Record food before
    let p1_food_before = dispatcher.get_player(PLAYER1()).food;

    // Create SUBSIDY proposal
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.create_proposal(1, PLAYER2());
    stop_cheat_caller_address(ca);

    // 1 for, 3 against (does NOT pass: votes_for < 3)
    start_cheat_caller_address(ca, PLAYER1());
    dispatcher.vote(0, true);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER2());
    dispatcher.vote(0, false);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER3());
    dispatcher.vote(0, false);
    stop_cheat_caller_address(ca);

    start_cheat_caller_address(ca, PLAYER4());
    dispatcher.vote(0, false);
    stop_cheat_caller_address(ca);

    // Execute proposal
    dispatcher.execute_proposal(0);

    // Proposal should be executed (marked as done) but food should NOT increase
    assert(dispatcher.get_player(PLAYER1()).food == p1_food_before, 'P1 food should be unchanged');

    // get_active_proposal returns default (era=0) since the only proposal is executed
    let proposal = dispatcher.get_active_proposal();
    assert(proposal.era == 0, 'No active proposal');
}
