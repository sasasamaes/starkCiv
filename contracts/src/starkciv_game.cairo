use starknet::ContractAddress;

// Game constants
const MAX_PLAYERS: u8 = 4;
const MAP_SIZE: u32 = 5;
const TURNS_PER_ERA: u32 = 5;
const VICTORY_REP: i32 = 10;
const VICTORY_TREATIES: u32 = 2;
const TREATY_BREAK_REP_PENALTY: i32 = 2;

// Building types
const BUILDING_NONE: u8 = 0;
const BUILDING_CITY: u8 = 1;
const BUILDING_FARM: u8 = 2;
const BUILDING_MARKET: u8 = 3;
const BUILDING_EMBASSY: u8 = 4;

// Treaty status
const TREATY_PENDING: u8 = 0;
const TREATY_ACTIVE: u8 = 1;
const TREATY_COMPLETED: u8 = 2;
const TREATY_BROKEN: u8 = 3;

// Proposal kinds
const PROPOSAL_SANCTION: u8 = 0;
const PROPOSAL_SUBSIDY: u8 = 1;
const PROPOSAL_OPEN_BORDERS: u8 = 2;
const PROPOSAL_GLOBAL_TAX: u8 = 3;

// Resource types for send_aid
const RESOURCE_FOOD: u8 = 0;
const RESOURCE_WOOD: u8 = 1;

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Player {
    pub addr: ContractAddress,
    pub food: u32,
    pub wood: u32,
    pub reputation: i32,
    pub city_tile: u32,
    pub embassy_built: bool,
    pub treaties_completed: u32,
    pub alive: bool,
    pub last_action_turn: u32,
    pub sanctioned_until: u32,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Tile {
    pub owner: ContractAddress,
    pub building: u8,
    pub guard: bool,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Treaty {
    pub id: u32,
    pub from: ContractAddress,
    pub to: ContractAddress,
    pub treaty_type: u8,
    pub status: u8,
    pub start_turn: u32,
    pub end_turn: u32,
    pub duration: u32,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Proposal {
    pub id: u32,
    pub kind: u8,
    pub target: ContractAddress,
    pub votes_for: u32,
    pub votes_against: u32,
    pub executed: bool,
    pub era: u32,
}

#[derive(Drop, Copy, Serde)]
pub struct GameState {
    pub game_started: bool,
    pub player_count: u8,
    pub current_turn: u32,
    pub current_era: u32,
    pub winner: ContractAddress,
}

#[starknet::interface]
pub trait IStarkCivGame<TContractState> {
    // Lobby
    fn join_game(ref self: TContractState);
    fn start_game(ref self: TContractState);

    // Turn
    fn end_turn(ref self: TContractState);

    // Actions
    fn expand(ref self: TContractState, tile_id: u32);
    fn build(ref self: TContractState, tile_id: u32, building_type: u8);
    fn train_guard(ref self: TContractState, tile_id: u32);
    fn send_aid(ref self: TContractState, to: ContractAddress, resource: u8, amount: u32);

    // Diplomacy
    fn propose_treaty(
        ref self: TContractState, to: ContractAddress, treaty_type: u8, duration: u32,
    );
    fn accept_treaty(ref self: TContractState, treaty_id: u32);
    fn break_treaty(ref self: TContractState, treaty_id: u32);

    // Governance
    fn create_proposal(ref self: TContractState, kind: u8, target: ContractAddress);
    fn vote(ref self: TContractState, proposal_id: u32, support: bool);
    fn execute_proposal(ref self: TContractState, proposal_id: u32);

    // Views
    fn get_game_state(self: @TContractState) -> GameState;
    fn get_player(self: @TContractState, addr: ContractAddress) -> Player;
    fn get_tile(self: @TContractState, tile_id: u32) -> Tile;
    fn get_active_proposal(self: @TContractState) -> Proposal;
    fn list_treaties_for(self: @TContractState, addr: ContractAddress) -> Array<Treaty>;
}

#[starknet::contract]
pub mod StarkCivGame {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use core::num::traits::Zero;
    use super::{
        Player, Tile, Treaty, Proposal, GameState, MAX_PLAYERS, MAP_SIZE, TURNS_PER_ERA,
        VICTORY_REP, VICTORY_TREATIES, TREATY_BREAK_REP_PENALTY, BUILDING_NONE, BUILDING_CITY,
        BUILDING_FARM, BUILDING_MARKET, BUILDING_EMBASSY, TREATY_PENDING, TREATY_ACTIVE,
        TREATY_COMPLETED, TREATY_BROKEN, PROPOSAL_SANCTION, PROPOSAL_SUBSIDY,
        PROPOSAL_OPEN_BORDERS, PROPOSAL_GLOBAL_TAX, RESOURCE_FOOD, RESOURCE_WOOD,
    };

    #[storage]
    struct Storage {
        game_started: bool,
        player_count: u8,
        current_turn: u32,
        current_era: u32,
        winner: ContractAddress,
        players: Map<ContractAddress, Player>,
        tiles: Map<u32, Tile>,
        treaties: Map<u32, Treaty>,
        treaty_nonce: u32,
        proposals: Map<u32, Proposal>,
        proposal_nonce: u32,
        player_addresses: Map<u8, ContractAddress>,
        has_voted: Map<(u32, ContractAddress), bool>,
        open_borders_until: u32,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        PlayerJoined: PlayerJoined,
        GameStarted: GameStarted,
        ActionExecuted: ActionExecuted,
        TreatyProposed: TreatyProposed,
        TreatyAccepted: TreatyAccepted,
        TreatyBroken: TreatyBroken,
        TreatyCompleted: TreatyCompleted,
        ProposalCreated: ProposalCreated,
        VoteCast: VoteCast,
        ProposalExecuted: ProposalExecuted,
        GameEnded: GameEnded,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PlayerJoined {
        #[key]
        pub player: ContractAddress,
        pub index: u8,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GameStarted {
        pub player_count: u8,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ActionExecuted {
        #[key]
        pub player: ContractAddress,
        pub action_type: felt252,
        pub turn: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TreatyProposed {
        pub treaty_id: u32,
        #[key]
        pub from: ContractAddress,
        #[key]
        pub to: ContractAddress,
        pub treaty_type: u8,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TreatyAccepted {
        pub treaty_id: u32,
        #[key]
        pub by: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TreatyBroken {
        pub treaty_id: u32,
        #[key]
        pub by: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TreatyCompleted {
        pub treaty_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProposalCreated {
        pub proposal_id: u32,
        pub kind: u8,
        #[key]
        pub target: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct VoteCast {
        pub proposal_id: u32,
        #[key]
        pub voter: ContractAddress,
        pub support: bool,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProposalExecuted {
        pub proposal_id: u32,
        pub passed: bool,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GameEnded {
        #[key]
        pub winner: ContractAddress,
    }

    // Spawn tile positions (corners of 5x5 grid)
    const SPAWN_TILE_0: u32 = 0; // (0,0)
    const SPAWN_TILE_1: u32 = 4; // (4,0)
    const SPAWN_TILE_2: u32 = 20; // (0,4)
    const SPAWN_TILE_3: u32 = 24; // (4,4)

    // ---------------------------------------------------------------
    // Internal helpers (private functions)
    // ---------------------------------------------------------------

    /// Check if caller has already acted this turn.
    /// Panics with 'Already acted' if last_action_turn >= current_turn.
    fn _check_already_acted(self: @ContractState, caller: ContractAddress) {
        let player = self.players.read(caller);
        let current_turn = self.current_turn.read();
        assert(player.last_action_turn < current_turn, 'Already acted');
    }

    /// Check if two tiles are orthogonally adjacent on a 5x5 grid.
    /// Returns true when Manhattan distance == 1 (no diagonals).
    fn _is_adjacent(a: u32, b: u32) -> bool {
        let ax = a % MAP_SIZE;
        let ay = a / MAP_SIZE;
        let bx = b % MAP_SIZE;
        let by = b / MAP_SIZE;

        let dx = if ax > bx {
            ax - bx
        } else {
            bx - ax
        };
        let dy = if ay > by {
            ay - by
        } else {
            by - ay
        };

        (dx + dy) == 1
    }

    /// Check if the caller owns at least one tile that is adjacent to `tile_id`.
    /// Iterates over all 25 tiles on the map.
    fn _has_adjacent_owned_tile(
        self: @ContractState, caller: ContractAddress, tile_id: u32,
    ) -> bool {
        let total_tiles: u32 = MAP_SIZE * MAP_SIZE; // 25
        let mut i: u32 = 0;
        let mut found = false;
        while i < total_tiles {
            if i != tile_id {
                let tile = self.tiles.read(i);
                if tile.owner == caller {
                    if _is_adjacent(i, tile_id) {
                        found = true;
                        break;
                    }
                }
            }
            i += 1;
        };
        found
    }

    /// Check if a player meets the diplomatic victory conditions:
    /// reputation >= 10, embassy_built == true, treaties_completed >= 2.
    fn _check_victory(player: @Player) -> bool {
        *player.reputation >= VICTORY_REP
            && *player.embassy_built
            && *player.treaties_completed >= VICTORY_TREATIES
    }

    /// Check victory for a player and set winner if conditions are met.
    /// Returns true if the player just won.
    fn _try_set_winner(ref self: ContractState, player_addr: ContractAddress) -> bool {
        let player = self.players.read(player_addr);
        if _check_victory(@player) {
            let current_winner = self.winner.read();
            if current_winner.is_zero() {
                self.winner.write(player_addr);
                self.emit(GameEnded { winner: player_addr });
                return true;
            }
        }
        false
    }

    /// Common validations for game actions: game started, no winner, caller alive.
    fn _validate_action_preconditions(self: @ContractState, caller: ContractAddress) {
        assert(self.game_started.read(), 'Game not started');
        assert(self.winner.read().is_zero(), 'Game ended');
        let player = self.players.read(caller);
        assert(player.alive, 'Not a valid player');
    }

    /// Process treaty completions: check all treaties and mark completed ones.
    fn _process_treaty_completions(ref self: ContractState) {
        let current_turn = self.current_turn.read();
        let nonce = self.treaty_nonce.read();
        let mut i: u32 = 0;
        while i < nonce {
            let mut treaty = self.treaties.read(i);
            if treaty.status == TREATY_ACTIVE && current_turn >= treaty.end_turn {
                // Mark as completed
                treaty.status = TREATY_COMPLETED;
                self.treaties.write(i, treaty);

                // +1 rep and +1 treaties_completed for both parties
                let mut from_player = self.players.read(treaty.from);
                from_player.reputation += 1;
                from_player.treaties_completed += 1;
                self.players.write(treaty.from, from_player);

                let mut to_player = self.players.read(treaty.to);
                to_player.reputation += 1;
                to_player.treaties_completed += 1;
                self.players.write(treaty.to, to_player);

                self.emit(TreatyCompleted { treaty_id: treaty.id });
            }
            i += 1;
        };
    }

    /// Generate resources for all alive players based on their owned tiles.
    /// +1 food per Farm tile, +1 wood per Market tile.
    fn _generate_resources(ref self: ContractState) {
        let player_count = self.player_count.read();
        let total_tiles: u32 = MAP_SIZE * MAP_SIZE;
        let mut p: u8 = 0;
        while p < player_count {
            let player_addr = self.player_addresses.read(p);
            let mut player = self.players.read(player_addr);
            if player.alive {
                let mut food_gain: u32 = 0;
                let mut wood_gain: u32 = 0;
                let mut t: u32 = 0;
                while t < total_tiles {
                    let tile = self.tiles.read(t);
                    if tile.owner == player_addr {
                        if tile.building == BUILDING_FARM {
                            food_gain += 1;
                        } else if tile.building == BUILDING_MARKET {
                            wood_gain += 1;
                        }
                    }
                    t += 1;
                };
                player.food += food_gain;
                player.wood += wood_gain;
                self.players.write(player_addr, player);
            }
            p += 1;
        };
    }

    /// Check victory for all players (used at end of turn after treaty completions).
    fn _check_all_victories(ref self: ContractState) {
        let player_count = self.player_count.read();
        let mut p: u8 = 0;
        while p < player_count {
            let player_addr = self.player_addresses.read(p);
            let won = _try_set_winner(ref self, player_addr);
            if won {
                break;
            }
            p += 1;
        };
    }

    #[abi(embed_v0)]
    impl StarkCivGameImpl of super::IStarkCivGame<ContractState> {
        // ---------------------------------------------------------------
        // Lobby (Issue 2 - existing)
        // ---------------------------------------------------------------

        fn join_game(ref self: ContractState) {
            let caller = get_caller_address();

            // Validate
            assert(!self.game_started.read(), 'Game already started');
            let count = self.player_count.read();
            assert(count < MAX_PLAYERS, 'Lobby full');

            // Check not already joined
            let existing = self.players.read(caller);
            assert(!existing.alive, 'Already joined');

            // Register player
            let player = Player {
                addr: caller,
                food: 5,
                wood: 2,
                reputation: 0,
                city_tile: 0,
                embassy_built: false,
                treaties_completed: 0,
                alive: true,
                last_action_turn: 0,
                sanctioned_until: 0,
            };
            self.players.write(caller, player);
            self.player_addresses.write(count, caller);
            self.player_count.write(count + 1);

            self.emit(PlayerJoined { player: caller, index: count });
        }

        fn start_game(ref self: ContractState) {
            assert(!self.game_started.read(), 'Game already started');
            let count = self.player_count.read();
            assert(count == MAX_PLAYERS, 'Need 4 players');

            // Assign spawn tiles with City
            let spawn_tiles: [u32; 4] = [SPAWN_TILE_0, SPAWN_TILE_1, SPAWN_TILE_2, SPAWN_TILE_3];
            let mut i: u8 = 0;
            while i < MAX_PLAYERS {
                let player_addr = self.player_addresses.read(i);
                let spawn_tile = *spawn_tiles.span()[i.into()];

                // Set tile
                let tile = Tile { owner: player_addr, building: BUILDING_CITY, guard: false };
                self.tiles.write(spawn_tile, tile);

                // Update player city_tile
                let mut player = self.players.read(player_addr);
                player.city_tile = spawn_tile;
                self.players.write(player_addr, player);

                i += 1;
            };

            self.game_started.write(true);
            self.current_turn.write(1);
            self.current_era.write(1);

            self.emit(GameStarted { player_count: count });
        }

        // ---------------------------------------------------------------
        // Issue 3: Turns & Resources
        // ---------------------------------------------------------------

        fn end_turn(ref self: ContractState) {
            assert(self.game_started.read(), 'Game not started');
            assert(self.winner.read().is_zero(), 'Game ended');

            // Increment turn
            let new_turn = self.current_turn.read() + 1;
            self.current_turn.write(new_turn);

            // Generate resources for all alive players
            _generate_resources(ref self);

            // Process treaty completions
            _process_treaty_completions(ref self);

            // Era progression: if new turn is start of a new era (turn % 5 == 1)
            // Turn 1 = era 1 (already set at start), turn 6 = era 2, turn 11 = era 3, etc.
            if new_turn % TURNS_PER_ERA == 1 {
                let new_era = self.current_era.read() + 1;
                self.current_era.write(new_era);
            }

            // Check victory for all players (treaties may have completed)
            _check_all_victories(ref self);
        }

        // ---------------------------------------------------------------
        // Issue 4: Actions (expand, build, train_guard)
        // ---------------------------------------------------------------

        fn expand(ref self: ContractState, tile_id: u32) {
            let caller = get_caller_address();
            _validate_action_preconditions(@self, caller);
            _check_already_acted(@self, caller);

            // Validate tile_id in range
            assert(tile_id < MAP_SIZE * MAP_SIZE, 'Invalid tile id');

            // Check tile has no owner
            let tile = self.tiles.read(tile_id);
            assert(tile.owner.is_zero(), 'Tile occupied');

            // Check sanction
            let player = self.players.read(caller);
            let current_turn = self.current_turn.read();
            assert(player.sanctioned_until < current_turn, 'Sanctioned');

            // Check adjacency (skip if open borders is active)
            let open_borders = self.open_borders_until.read();
            if open_borders < current_turn {
                assert(_has_adjacent_owned_tile(@self, caller, tile_id), 'Not adjacent');
            }

            // Assign tile to caller
            let new_tile = Tile { owner: caller, building: BUILDING_NONE, guard: false };
            self.tiles.write(tile_id, new_tile);

            // Update last_action_turn
            let mut player = self.players.read(caller);
            player.last_action_turn = current_turn;
            self.players.write(caller, player);

            self
                .emit(
                    ActionExecuted { player: caller, action_type: 'expand', turn: current_turn },
                );

            // Check victory
            _try_set_winner(ref self, caller);
        }

        fn build(ref self: ContractState, tile_id: u32, building_type: u8) {
            let caller = get_caller_address();
            _validate_action_preconditions(@self, caller);
            _check_already_acted(@self, caller);

            // Validate tile_id in range
            assert(tile_id < MAP_SIZE * MAP_SIZE, 'Invalid tile id');

            // Check tile owned by caller
            let tile = self.tiles.read(tile_id);
            assert(tile.owner == caller, 'Not your tile');

            // Check no existing building (building == NONE means empty; City tiles cannot be
            // built on)
            assert(tile.building == BUILDING_NONE, 'Already built');

            // Validate building_type
            assert(
                building_type == BUILDING_FARM
                    || building_type == BUILDING_MARKET
                    || building_type == BUILDING_EMBASSY,
                'Invalid building type',
            );

            // Set building on tile
            let new_tile = Tile { owner: tile.owner, building: building_type, guard: tile.guard };
            self.tiles.write(tile_id, new_tile);

            // If Embassy, update player
            if building_type == BUILDING_EMBASSY {
                let mut player = self.players.read(caller);
                player.embassy_built = true;
                let current_turn = self.current_turn.read();
                player.last_action_turn = current_turn;
                self.players.write(caller, player);

                self
                    .emit(
                        ActionExecuted {
                            player: caller, action_type: 'build', turn: current_turn,
                        },
                    );
            } else {
                let current_turn = self.current_turn.read();
                let mut player = self.players.read(caller);
                player.last_action_turn = current_turn;
                self.players.write(caller, player);

                self
                    .emit(
                        ActionExecuted {
                            player: caller, action_type: 'build', turn: current_turn,
                        },
                    );
            }

            // Check victory
            _try_set_winner(ref self, caller);
        }

        fn train_guard(ref self: ContractState, tile_id: u32) {
            let caller = get_caller_address();
            _validate_action_preconditions(@self, caller);
            _check_already_acted(@self, caller);

            // Validate tile_id in range
            assert(tile_id < MAP_SIZE * MAP_SIZE, 'Invalid tile id');

            // Check tile owned by caller
            let tile = self.tiles.read(tile_id);
            assert(tile.owner == caller, 'Not your tile');

            // Check no existing guard
            assert(!tile.guard, 'Already has guard');

            // Set guard
            let new_tile = Tile { owner: tile.owner, building: tile.building, guard: true };
            self.tiles.write(tile_id, new_tile);

            // Update last_action_turn
            let current_turn = self.current_turn.read();
            let mut player = self.players.read(caller);
            player.last_action_turn = current_turn;
            self.players.write(caller, player);

            self
                .emit(
                    ActionExecuted {
                        player: caller, action_type: 'train_guard', turn: current_turn,
                    },
                );

            // Check victory
            _try_set_winner(ref self, caller);
        }

        // ---------------------------------------------------------------
        // Issue 5: Send Aid & Reputation
        // ---------------------------------------------------------------

        fn send_aid(ref self: ContractState, to: ContractAddress, resource: u8, amount: u32) {
            let caller = get_caller_address();
            _validate_action_preconditions(@self, caller);
            _check_already_acted(@self, caller);

            // Validate target
            assert(caller != to, 'Cannot aid yourself');
            let target = self.players.read(to);
            assert(target.alive, 'Invalid target');

            // Validate amount > 0
            assert(amount > 0, 'Amount must be > 0');

            // Validate resource type and sufficient resources
            let mut sender = self.players.read(caller);
            let mut receiver = self.players.read(to);

            if resource == RESOURCE_FOOD {
                assert(sender.food >= amount, 'Insufficient food');
                sender.food -= amount;
                receiver.food += amount;
            } else if resource == RESOURCE_WOOD {
                assert(sender.wood >= amount, 'Insufficient wood');
                sender.wood -= amount;
                receiver.wood += amount;
            } else {
                assert(false, 'Invalid resource');
            }

            // +1 reputation to sender
            sender.reputation += 1;

            // Update last_action_turn
            let current_turn = self.current_turn.read();
            sender.last_action_turn = current_turn;

            self.players.write(caller, sender);
            self.players.write(to, receiver);

            self
                .emit(
                    ActionExecuted {
                        player: caller, action_type: 'send_aid', turn: current_turn,
                    },
                );

            // Check victory
            _try_set_winner(ref self, caller);
        }

        // ---------------------------------------------------------------
        // Issue 6: Treaties
        // ---------------------------------------------------------------

        fn propose_treaty(
            ref self: ContractState, to: ContractAddress, treaty_type: u8, duration: u32,
        ) {
            let caller = get_caller_address();
            _validate_action_preconditions(@self, caller);
            _check_already_acted(@self, caller);

            // Caller must have embassy
            let player = self.players.read(caller);
            assert(player.embassy_built, 'No embassy');

            // Target must be valid and not self
            assert(caller != to, 'Cannot treaty self');
            let target = self.players.read(to);
            assert(target.alive, 'Invalid target');

            // Validate duration > 0
            assert(duration > 0, 'Invalid duration');

            // Create treaty
            let treaty_id = self.treaty_nonce.read();
            let treaty = Treaty {
                id: treaty_id,
                from: caller,
                to: to,
                treaty_type: treaty_type,
                status: TREATY_PENDING,
                start_turn: 0,
                end_turn: 0,
                duration: duration,
            };
            self.treaties.write(treaty_id, treaty);
            self.treaty_nonce.write(treaty_id + 1);

            // Consume action
            let current_turn = self.current_turn.read();
            let mut player = self.players.read(caller);
            player.last_action_turn = current_turn;
            self.players.write(caller, player);

            self
                .emit(
                    TreatyProposed {
                        treaty_id: treaty_id, from: caller, to: to, treaty_type: treaty_type,
                    },
                );

            // Check victory
            _try_set_winner(ref self, caller);
        }

        fn accept_treaty(ref self: ContractState, treaty_id: u32) {
            let caller = get_caller_address();
            assert(self.game_started.read(), 'Game not started');
            assert(self.winner.read().is_zero(), 'Game ended');

            // Treaty must exist and be pending
            let nonce = self.treaty_nonce.read();
            assert(treaty_id < nonce, 'Treaty not found');

            let mut treaty = self.treaties.read(treaty_id);
            assert(treaty.status == TREATY_PENDING, 'Treaty not pending');

            // Caller must be the target
            assert(caller == treaty.to, 'Not treaty target');

            // Set active
            let current_turn = self.current_turn.read();
            treaty.status = TREATY_ACTIVE;
            treaty.start_turn = current_turn;
            treaty.end_turn = current_turn + treaty.duration;
            self.treaties.write(treaty_id, treaty);

            // Does NOT consume action (no last_action_turn update)

            self.emit(TreatyAccepted { treaty_id: treaty_id, by: caller });
        }

        fn break_treaty(ref self: ContractState, treaty_id: u32) {
            let caller = get_caller_address();
            assert(self.game_started.read(), 'Game not started');
            assert(self.winner.read().is_zero(), 'Game ended');

            // Treaty must exist and be active
            let nonce = self.treaty_nonce.read();
            assert(treaty_id < nonce, 'Treaty not found');

            let mut treaty = self.treaties.read(treaty_id);
            assert(treaty.status == TREATY_ACTIVE, 'Treaty not active');

            // Caller must be a party
            assert(caller == treaty.from || caller == treaty.to, 'Not treaty party');

            // Mark as broken
            treaty.status = TREATY_BROKEN;
            self.treaties.write(treaty_id, treaty);

            // Apply penalties to breaker: -2 reputation, -1 food, -1 wood
            let mut player = self.players.read(caller);
            player.reputation -= TREATY_BREAK_REP_PENALTY;
            if player.food > 0 {
                player.food -= 1;
            }
            if player.wood > 0 {
                player.wood -= 1;
            }
            self.players.write(caller, player);

            // Does NOT consume action

            self.emit(TreatyBroken { treaty_id: treaty_id, by: caller });
        }

        // ---------------------------------------------------------------
        // Issue 7: Governance
        // ---------------------------------------------------------------

        fn create_proposal(ref self: ContractState, kind: u8, target: ContractAddress) {
            let caller = get_caller_address();
            assert(self.game_started.read(), 'Game not started');
            assert(self.winner.read().is_zero(), 'Game ended');

            let player = self.players.read(caller);
            assert(player.alive, 'Not a valid player');

            // Validate it's the start of an era (current_turn % 5 == 1)
            let current_turn = self.current_turn.read();
            assert(current_turn % TURNS_PER_ERA == 1, 'Not era start');

            // Validate proposal kind
            assert(
                kind == PROPOSAL_SANCTION
                    || kind == PROPOSAL_SUBSIDY
                    || kind == PROPOSAL_OPEN_BORDERS
                    || kind == PROPOSAL_GLOBAL_TAX,
                'Invalid proposal kind',
            );

            // Check no active (non-executed) proposal for this era
            let current_era = self.current_era.read();
            let nonce = self.proposal_nonce.read();
            let mut i: u32 = 0;
            let mut has_active = false;
            while i < nonce {
                let p = self.proposals.read(i);
                if p.era == current_era && !p.executed {
                    has_active = true;
                    break;
                }
                i += 1;
            };
            assert(!has_active, 'Proposal exists for era');

            // Create proposal
            let proposal_id = nonce;
            let proposal = Proposal {
                id: proposal_id,
                kind: kind,
                target: target,
                votes_for: 0,
                votes_against: 0,
                executed: false,
                era: current_era,
            };
            self.proposals.write(proposal_id, proposal);
            self.proposal_nonce.write(proposal_id + 1);

            self.emit(ProposalCreated { proposal_id: proposal_id, kind: kind, target: target });
        }

        fn vote(ref self: ContractState, proposal_id: u32, support: bool) {
            let caller = get_caller_address();
            assert(self.game_started.read(), 'Game not started');
            assert(self.winner.read().is_zero(), 'Game ended');

            let player = self.players.read(caller);
            assert(player.alive, 'Not a valid player');

            // Proposal must exist and not be executed
            let nonce = self.proposal_nonce.read();
            assert(proposal_id < nonce, 'Proposal not found');

            let mut proposal = self.proposals.read(proposal_id);
            assert(!proposal.executed, 'Proposal already executed');

            // Check hasn't voted
            assert(!self.has_voted.read((proposal_id, caller)), 'Already voted');

            // Record vote
            if support {
                proposal.votes_for += 1;
            } else {
                proposal.votes_against += 1;
            }
            self.proposals.write(proposal_id, proposal);
            self.has_voted.write((proposal_id, caller), true);

            self.emit(VoteCast { proposal_id: proposal_id, voter: caller, support: support });
        }

        fn execute_proposal(ref self: ContractState, proposal_id: u32) {
            assert(self.game_started.read(), 'Game not started');
            assert(self.winner.read().is_zero(), 'Game ended');

            // Proposal must exist and not be executed
            let nonce = self.proposal_nonce.read();
            assert(proposal_id < nonce, 'Proposal not found');

            let mut proposal = self.proposals.read(proposal_id);
            assert(!proposal.executed, 'Proposal already executed');

            // Check all have voted or enough votes cast
            let total_votes = proposal.votes_for + proposal.votes_against;
            let player_count: u32 = self.player_count.read().into();
            assert(total_votes >= player_count, 'Not all voted');

            // Determine if passed (3/4 majority)
            let passed = proposal.votes_for >= 3;

            if passed {
                let current_turn = self.current_turn.read();
                let player_count_u8 = self.player_count.read();

                if proposal.kind == PROPOSAL_SANCTION {
                    // Target cannot expand next turn
                    let mut target_player = self.players.read(proposal.target);
                    target_player.sanctioned_until = current_turn + 1;
                    self.players.write(proposal.target, target_player);
                } else if proposal.kind == PROPOSAL_SUBSIDY {
                    // +1 food to all alive players
                    let mut p: u8 = 0;
                    while p < player_count_u8 {
                        let addr = self.player_addresses.read(p);
                        let mut pl = self.players.read(addr);
                        if pl.alive {
                            pl.food += 1;
                            self.players.write(addr, pl);
                        }
                        p += 1;
                    };
                } else if proposal.kind == PROPOSAL_OPEN_BORDERS {
                    // Skip adjacency for 1 turn
                    let current_turn = self.current_turn.read();
                    self.open_borders_until.write(current_turn + 1);
                } else if proposal.kind == PROPOSAL_GLOBAL_TAX {
                    // -1 wood to all alive players (min 0)
                    let mut p: u8 = 0;
                    while p < player_count_u8 {
                        let addr = self.player_addresses.read(p);
                        let mut pl = self.players.read(addr);
                        if pl.alive {
                            if pl.wood > 0 {
                                pl.wood -= 1;
                            }
                            self.players.write(addr, pl);
                        }
                        p += 1;
                    };
                }
            }

            // Mark executed
            proposal.executed = true;
            self.proposals.write(proposal_id, proposal);

            self.emit(ProposalExecuted { proposal_id: proposal_id, passed: passed });
        }

        // ---------------------------------------------------------------
        // Views
        // ---------------------------------------------------------------

        fn get_game_state(self: @ContractState) -> GameState {
            GameState {
                game_started: self.game_started.read(),
                player_count: self.player_count.read(),
                current_turn: self.current_turn.read(),
                current_era: self.current_era.read(),
                winner: self.winner.read(),
            }
        }

        fn get_player(self: @ContractState, addr: ContractAddress) -> Player {
            self.players.read(addr)
        }

        fn get_tile(self: @ContractState, tile_id: u32) -> Tile {
            self.tiles.read(tile_id)
        }

        fn get_active_proposal(self: @ContractState) -> Proposal {
            let current_era = self.current_era.read();
            let nonce = self.proposal_nonce.read();
            let mut i: u32 = 0;
            let mut result = Proposal {
                id: 0, kind: 0, target: Zero::zero(), votes_for: 0, votes_against: 0, executed: false, era: 0,
            };
            while i < nonce {
                let p = self.proposals.read(i);
                if p.era == current_era && !p.executed {
                    result = p;
                    break;
                }
                i += 1;
            };
            result
        }

        fn list_treaties_for(self: @ContractState, addr: ContractAddress) -> Array<Treaty> {
            let nonce = self.treaty_nonce.read();
            let mut result: Array<Treaty> = ArrayTrait::new();
            let mut i: u32 = 0;
            while i < nonce {
                let treaty = self.treaties.read(i);
                if treaty.from == addr || treaty.to == addr {
                    result.append(treaty);
                }
                i += 1;
            };
            result
        }
    }
}
