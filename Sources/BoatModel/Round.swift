import Foundation

public struct Round: Equatable, Codable, Sendable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date

    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var players: [Player]
    public internal(set) var dice: [Die]
    public internal(set) var rollsRemaining: Int
    public let ruleOptions: RuleOptions

    // MARK: - Results
    public internal(set) var log: Log = .init()
    public internal(set) var ended: Date?

    var cookedRolls: [DieValue] = []

    public static let diceCount: Int = 5
    public static let totalTurns: Int = 13
    public static let maxRollsPerTurn: Int = 3
    public static let upperBonusThreshold: Int = 63
    public static let upperBonusValue: Int = 35
    public static let boatBonusValue: Int = 100
    public static let minPlayers: Int = 2
    public static let maxPlayers: Int = 6

    public enum CodingKeys: String, CodingKey {
        case id
        case started
        case state
        case players
        case dice
        case rollsRemaining
        case ruleOptions
        case log
        case ended
    }

    public enum State: Equatable, Codable, Sendable {
        case playing(currentPlayerID: PlayerID, turnPhase: TurnPhase)
        case complete

        public enum TurnPhase: Equatable, Codable, Sendable {
            case needsToRoll
            case canRollOrScore
            case mustScore
        }

        public var logValue: String {
            switch self {
            case .playing(let playerID, let turnPhase):
                "Playing - Player \(playerID) (\(turnPhase))"
            case .complete:
                "Complete"
            }
        }
    }
}
