import Foundation

public struct AIEngine: Sendable {
    public enum Difficulty: String, CaseIterable, Equatable, Codable, Sendable {
        case easy
        case medium
        case hard

        public var displayableName: String {
            switch self {
            case .easy: "Easy"
            case .medium: "Medium"
            case .hard: "Hard"
            }
        }
    }

    public let difficulty: Difficulty

    public init(difficulty: Difficulty) {
        self.difficulty = difficulty
    }

    public func makeMove(round: Round) -> Round {
        var updatedRound: Round = round

        guard case .playing(let playerID, let phase) = updatedRound.state else {
            return updatedRound
        }

        do {
            switch phase {
            case .needsToRoll:
                try updatedRound.rollDice()

            case .canRollOrScore:
                if shouldStopRolling(round: updatedRound, playerID: playerID) {
                    let category: ScoreCategory = chooseBestCategory(
                        round: updatedRound,
                        playerID: playerID
                    )
                    try updatedRound.score(category: category)
                } else {
                    let keeping: Set<DieID> = chooseDiceToKeep(
                        round: updatedRound,
                        playerID: playerID
                    )
                    try updatedRound.rollDice(keeping: keeping)
                }

            case .mustScore:
                let category: ScoreCategory = chooseBestCategory(
                    round: updatedRound,
                    playerID: playerID
                )
                try updatedRound.score(category: category)
            }
        } catch {
            do {
                if case .playing(_, .needsToRoll) = updatedRound.state {
                    try updatedRound.rollDice()
                } else if let category = updatedRound.availableCategories(for: playerID).first {
                    try updatedRound.score(category: category)
                }
            } catch {
                return round
            }
        }

        return updatedRound
    }

    // MARK: - Decision Making

    private func shouldStopRolling(round: Round, playerID: PlayerID) -> Bool {
        let bestScore: Int = bestAvailableScore(round: round, playerID: playerID)

        switch difficulty {
        case .easy:
            return Bool.random()

        case .medium:
            return bestScore >= 20

        case .hard:
            if Set(round.dice.map(\.value)).count == 1 { return true }
            if bestScore >= 25 { return true }
            if round.rollsRemaining == 1 && bestScore >= 15 { return true }
            return false
        }
    }

    private func chooseDiceToKeep(round: Round, playerID: PlayerID) -> Set<DieID> {
        let dice: [Die] = round.dice

        switch difficulty {
        case .easy:
            let keepCount: Int = Int.random(in: 0 ... 3)
            return Set(dice.shuffled().prefix(keepCount).map(\.id))

        case .medium, .hard:
            return chooseDiceStrategically(dice: dice)
        }
    }

    private func chooseBestCategory(round: Round, playerID: PlayerID) -> ScoreCategory {
        let available: [ScoreCategory] = round.availableCategories(for: playerID)
        guard !available.isEmpty else { return .chance }

        switch difficulty {
        case .easy:
            return available.randomElement()!

        case .medium:
            return available.max(by: {
                Round.calculateScore(dice: round.dice, for: $0)
                    < Round.calculateScore(dice: round.dice, for: $1)
            }) ?? available[0]

        case .hard:
            return chooseCategoryStrategically(
                round: round,
                playerID: playerID,
                available: available
            )
        }
    }

    // MARK: - Strategic Helpers

    private func chooseDiceStrategically(dice: [Die]) -> Set<DieID> {
        let values: [DieValue] = dice.map(\.value)
        let valueCounts: [DieValue: Int] = Dictionary(
            grouping: values,
            by: { $0 }
        ).mapValues(\.count)

        guard let (bestValue, bestCount) = valueCounts.max(by: { $0.value < $1.value }) else {
            return []
        }

        if bestCount >= 3 {
            return Set(dice.filter { $0.value == bestValue }.map(\.id))
        }

        let uniqueValues: Set<Int> = Set(values.map(\.rawValue))
        if uniqueValues.count >= 3 {
            let sorted: [Int] = uniqueValues.sorted()
            var bestRun: [Int] = []
            var currentRun: [Int] = [sorted[0]]
            for i in 1 ..< sorted.count {
                if sorted[i] == currentRun.last! + 1 {
                    currentRun.append(sorted[i])
                } else {
                    if currentRun.count > bestRun.count { bestRun = currentRun }
                    currentRun = [sorted[i]]
                }
            }
            if currentRun.count > bestRun.count { bestRun = currentRun }

            if bestRun.count >= 3 {
                let straightValues: Set<Int> = Set(bestRun)
                var kept: Set<DieID> = []
                var usedValues: Set<Int> = []
                for die in dice {
                    let raw: Int = die.value.rawValue
                    if straightValues.contains(raw) && !usedValues.contains(raw) {
                        kept.insert(die.id)
                        usedValues.insert(raw)
                    }
                }
                return kept
            }
        }

        if bestCount >= 2 {
            return Set(dice.filter { $0.value == bestValue }.map(\.id))
        }

        if difficulty == .hard {
            let highDice: [Die] = dice.filter { $0.value.rawValue >= 5 }
            if !highDice.isEmpty {
                return Set(highDice.map(\.id))
            }
        }

        return []
    }

    private func chooseCategoryStrategically(
        round: Round,
        playerID: PlayerID,
        available: [ScoreCategory]
    ) -> ScoreCategory {
        guard let playerIndex: Int = round.players.firstIndex(where: { $0.id == playerID }) else {
            return available[0]
        }
        let scorecard: Scorecard = round.players[playerIndex].scorecard

        var categoryScores: [(category: ScoreCategory, netValue: Int)] = []
        for category in available {
            let score: Int = Round.calculateScore(dice: round.dice, for: category)
            let penalty: Int = scoringPenalty(for: category, score: score, scorecard: scorecard)
            categoryScores.append((category: category, netValue: score - penalty))
        }

        categoryScores.sort { $0.netValue > $1.netValue }

        if let best = categoryScores.first, best.netValue > 0 {
            return best.category
        }

        let scratchPriority: [ScoreCategory] = [
            .boat, .largeStraight, .smallStraight, .fullHouse,
            .fourOfAKind, .threeOfAKind,
            .ones, .twos, .threes, .chance,
            .fours, .fives, .sixes,
        ]
        for category in scratchPriority {
            if available.contains(category) {
                return category
            }
        }

        return available[0]
    }

    private func bestAvailableScore(round: Round, playerID: PlayerID) -> Int {
        let available: [ScoreCategory] = round.availableCategories(for: playerID)
        return available.map { Round.calculateScore(dice: round.dice, for: $0) }.max() ?? 0
    }

    private func scoringPenalty(
        for category: ScoreCategory,
        score: Int,
        scorecard: Scorecard
    ) -> Int {
        switch category {
        case .ones:
            return max(0, 3 - score) * 2
        case .twos:
            return max(0, 6 - score) * 2
        case .threes:
            return max(0, 9 - score) * 2
        case .fours:
            return max(0, 12 - score) * 2
        case .fives:
            return max(0, 15 - score) * 2
        case .sixes:
            return max(0, 18 - score) * 2
        case .boat:
            return score == 0 ? 50 : 0
        case .largeStraight:
            return score == 0 ? 20 : 0
        case .smallStraight:
            return score == 0 ? 15 : 0
        case .fullHouse:
            return score == 0 ? 12 : 0
        case .chance:
            return max(0, 20 - score)
        case .threeOfAKind, .fourOfAKind:
            return max(0, 15 - score)
        }
    }
}
