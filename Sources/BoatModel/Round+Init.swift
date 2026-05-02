import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        players: [Player],
        ruleOptions: RuleOptions = .classic
    ) throws {
        guard players.count >= Self.minPlayers else {
            throw BoatError.notEnoughPlayers
        }
        guard players.count <= Self.maxPlayers else {
            throw BoatError.tooManyPlayers
        }
        self.id = id
        self.started = started
        self.players = players
        self.ruleOptions = ruleOptions
        self.dice = (0 ..< Self.diceCount).map { Die(id: $0, value: .one) }
        self.rollsRemaining = Self.maxRollsPerTurn
        self.cookedRolls = []
        self.state = .playing(
            currentPlayerID: players.first!.id,
            turnPhase: .needsToRoll
        )
    }

    init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        players: [Player],
        cookedRolls: [DieValue],
        ruleOptions: RuleOptions = .classic
    ) throws {
        guard players.count >= Self.minPlayers else {
            throw BoatError.notEnoughPlayers
        }
        guard players.count <= Self.maxPlayers else {
            throw BoatError.tooManyPlayers
        }
        self.id = id
        self.started = started
        self.players = players
        self.ruleOptions = ruleOptions
        self.dice = (0 ..< Self.diceCount).map { Die(id: $0, value: .one) }
        self.rollsRemaining = Self.maxRollsPerTurn
        self.cookedRolls = cookedRolls
        self.state = .playing(
            currentPlayerID: players.first!.id,
            turnPhase: .needsToRoll
        )
    }
}
