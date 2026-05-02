import Foundation

public enum BoatError: Error, Equatable, Sendable {
    case notEnoughPlayers
    case tooManyPlayers
    case notCurrentPlayersTurn
    case cannotRollInCurrentState
    case cannotKeepDiceOnFirstRoll
    case cannotScoreInCurrentState
    case categoryAlreadyScored
    case categoryNotAvailable
    case invalidDieID
    case roundAlreadyComplete
}
