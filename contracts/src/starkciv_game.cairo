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

    // Views
    fn get_game_state(self: @TContractState) -> GameState;
    fn get_player(self: @TContractState, addr: ContractAddress) -> Player;
    fn get_tile(self: @TContractState, tile_id: u32) -> Tile;
}

#[starknet::contract]
pub mod StarkCivGame {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use super::{
        Player, Tile, Treaty, Proposal, GameState, MAX_PLAYERS, BUILDING_CITY,
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
    const SPAWN_TILE_0: u32 = 0;   // (0,0)
    const SPAWN_TILE_1: u32 = 4;   // (4,0)
    const SPAWN_TILE_2: u32 = 20;  // (0,4)
    const SPAWN_TILE_3: u32 = 24;  // (4,4)

    #[abi(embed_v0)]
    impl StarkCivGameImpl of super::IStarkCivGame<ContractState> {
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
    }
}
