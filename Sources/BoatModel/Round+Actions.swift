import Foundation

extension Round {
    public mutating func rollDice(keeping: Set<DieID> = []) throws {
        guard case .playing(let playerID, let phase) = state else {
            throw BoatError.roundAlreadyComplete
        }

        switch phase {
        case .needsToRoll:
            guard keeping.isEmpty else {
                throw BoatError.cannotKeepDiceOnFirstRoll
            }
        case .canRollOrScore:
            for dieID in keeping {
                guard dice.contains(where: { $0.id == dieID }) else {
                    throw BoatError.invalidDieID
                }
            }
        case .mustScore:
            throw BoatError.cannotRollInCurrentState
        }

        for i in 0 ..< dice.count {
            if !keeping.contains(dice[i].id) {
                dice[i].value = consumeRoll()
            }
        }

        rollsRemaining -= 1

        log.addAction(
            .init(
                playerID: playerID,
                decision: .roll(
                    kept: Array(keeping),
                    result: dice.map(\.value)
                )
            )
        )

        if rollsRemaining > 0 {
            state = .playing(currentPlayerID: playerID, turnPhase: .canRollOrScore)
        } else {
            state = .playing(currentPlayerID: playerID, turnPhase: .mustScore)
        }
    }

    public mutating func score(category: ScoreCategory) throws {
        guard case .playing(let playerID, let phase) = state else {
            throw BoatError.roundAlreadyComplete
        }

        switch phase {
        case .needsToRoll:
            throw BoatError.cannotScoreInCurrentState
        case .canRollOrScore, .mustScore:
            break
        }

        guard let playerIndex: Int = players.firstIndex(where: { $0.id == playerID }) else {
            throw BoatError.notCurrentPlayersTurn
        }

        guard !players[playerIndex].scorecard.hasScored(category) else {
            throw BoatError.categoryAlreadyScored
        }

        let available: [ScoreCategory] = availableCategories(for: playerID)
        guard available.contains(category) else {
            throw BoatError.categoryNotAvailable
        }

        let isBoat: Bool = Set(dice.map(\.value)).count == 1
        let boatAlreadyScored: Bool = players[playerIndex].scorecard.hasScored(.boat)
        var isJoker: Bool = false

        if isBoat && boatAlreadyScored {
            if ruleOptions.boatBonus,
               let boatScore: Int = players[playerIndex].scorecard.scores[.boat],
               boatScore > 0 {
                players[playerIndex].scorecard.boatBonusCount += 1
            }
            isJoker = true
        }

        let points: Int = Self.calculateScore(dice: dice, for: category, isJoker: isJoker)
        players[playerIndex].scorecard.scores[category] = points

        log.addAction(
            .init(
                playerID: playerID,
                decision: .score(category: category, points: points)
            )
        )

        advanceToNextTurn(currentPlayerIndex: playerIndex)
    }

    private mutating func advanceToNextTurn(currentPlayerIndex: Int) {
        if players.allSatisfy(\.scorecard.isComplete) {
            state = .complete
            ended = Date()
            return
        }

        let nextPlayerIndex: Int = (currentPlayerIndex + 1) % players.count
        let nextPlayerID: PlayerID = players[nextPlayerIndex].id

        rollsRemaining = Self.maxRollsPerTurn
        state = .playing(currentPlayerID: nextPlayerID, turnPhase: .needsToRoll)
    }

    mutating func consumeRoll() -> DieValue {
        if !cookedRolls.isEmpty {
            return cookedRolls.removeFirst()
        }
        return DieValue.allCases.randomElement()!
    }
}
