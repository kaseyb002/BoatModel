import Foundation

extension Round {
    public var currentPlayerIndex: Int? {
        switch state {
        case .playing(let playerID, _):
            return players.firstIndex(where: { $0.id == playerID })
        case .complete:
            return nil
        }
    }

    public var currentPlayer: Player? {
        guard let currentPlayerIndex else { return nil }
        return players[currentPlayerIndex]
    }

    public var currentPlayerID: PlayerID? {
        switch state {
        case .playing(let playerID, _):
            return playerID
        case .complete:
            return nil
        }
    }

    public var turnPhase: State.TurnPhase? {
        switch state {
        case .playing(_, let phase):
            return phase
        case .complete:
            return nil
        }
    }

    public var isComplete: Bool {
        if case .complete = state { return true }
        return false
    }

    public var winner: Player? {
        guard isComplete else { return nil }
        return players.max(by: { $0.scorecard.grandTotal < $1.scorecard.grandTotal })
    }

    public var currentTurnNumber: Int {
        guard let currentPlayerIndex else {
            return Self.totalTurns
        }
        return players[currentPlayerIndex].scorecard.scores.count + 1
    }

    public var logValue: String {
        """
        State: \(state.logValue)
        Dice: \(dice.map { "\($0.value.rawValue)" }.joined(separator: ", "))
        Rolls remaining: \(rollsRemaining)
        Current player: \(currentPlayer?.name ?? "None")

        \(players.logValue)
        """
    }
}
