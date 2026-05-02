import Foundation

extension Round {
    public static func calculateScore(
        dice: [Die],
        for category: ScoreCategory,
        isJoker: Bool = false
    ) -> Int {
        let values: [DieValue] = dice.map(\.value)
        let valueCounts: [DieValue: Int] = Dictionary(
            grouping: values,
            by: { $0 }
        ).mapValues(\.count)
        let sum: Int = values.reduce(0) { $0 + $1.rawValue }

        switch category {
        case .ones:
            return values.filter { $0 == .one }.count * DieValue.one.rawValue
        case .twos:
            return values.filter { $0 == .two }.count * DieValue.two.rawValue
        case .threes:
            return values.filter { $0 == .three }.count * DieValue.three.rawValue
        case .fours:
            return values.filter { $0 == .four }.count * DieValue.four.rawValue
        case .fives:
            return values.filter { $0 == .five }.count * DieValue.five.rawValue
        case .sixes:
            return values.filter { $0 == .six }.count * DieValue.six.rawValue

        case .threeOfAKind:
            return valueCounts.values.contains(where: { $0 >= 3 }) ? sum : 0

        case .fourOfAKind:
            return valueCounts.values.contains(where: { $0 >= 4 }) ? sum : 0

        case .fullHouse:
            if isJoker { return 25 }
            let hasThree: Bool = valueCounts.values.contains(where: { $0 == 3 })
            let hasTwo: Bool = valueCounts.values.contains(where: { $0 == 2 })
            return (hasThree && hasTwo) ? 25 : 0

        case .smallStraight:
            if isJoker { return 30 }
            return hasConsecutive(values, count: 4) ? 30 : 0

        case .largeStraight:
            if isJoker { return 40 }
            return hasConsecutive(values, count: 5) ? 40 : 0

        case .chance:
            return sum

        case .boat:
            return valueCounts.values.contains(where: { $0 == 5 }) ? 50 : 0
        }
    }

    public func availableCategories(for playerID: PlayerID) -> [ScoreCategory] {
        guard let playerIndex: Int = players.firstIndex(where: { $0.id == playerID }) else {
            return []
        }
        let scorecard: Scorecard = players[playerIndex].scorecard
        let unscored: [ScoreCategory] = scorecard.unscoredCategories

        let isBoat: Bool = Set(dice.map(\.value)).count == 1
        let boatAlreadyScored: Bool = scorecard.hasScored(.boat)

        if isBoat && boatAlreadyScored && ruleOptions.forcedJokerRules {
            let dieValue: DieValue = dice[0].value
            let matchingUpper: ScoreCategory = ScoreCategory.upperCategory(for: dieValue)

            if unscored.contains(matchingUpper) {
                return [matchingUpper]
            }

            let unscoredLower: [ScoreCategory] = unscored.filter(\.isLowerSection)
            if !unscoredLower.isEmpty {
                return unscoredLower
            }

            return unscored.filter(\.isUpperSection)
        }

        return unscored
    }

    private static func hasConsecutive(_ values: [DieValue], count: Int) -> Bool {
        let uniqueSorted: [Int] = Set(values.map(\.rawValue)).sorted()
        guard uniqueSorted.count >= count else { return false }
        var consecutive: Int = 1
        for i in 1 ..< uniqueSorted.count {
            if uniqueSorted[i] == uniqueSorted[i - 1] + 1 {
                consecutive += 1
                if consecutive >= count { return true }
            } else {
                consecutive = 1
            }
        }
        return consecutive >= count
    }
}
