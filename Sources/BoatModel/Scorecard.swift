import Foundation

public struct Scorecard: Equatable, Codable, Sendable {
    public var scores: [ScoreCategory: Int]
    public var boatBonusCount: Int

    public init(
        scores: [ScoreCategory: Int] = [:],
        boatBonusCount: Int = 0
    ) {
        self.scores = scores
        self.boatBonusCount = boatBonusCount
    }

    public func hasScored(_ category: ScoreCategory) -> Bool {
        scores[category] != nil
    }

    public var unscoredCategories: [ScoreCategory] {
        ScoreCategory.allCases.filter { !hasScored($0) }
    }

    public var isComplete: Bool {
        scores.count == ScoreCategory.allCases.count
    }

    public var upperSectionTotal: Int {
        ScoreCategory.upperSection.reduce(0) { $0 + (scores[$1] ?? 0) }
    }

    public var upperBonus: Int {
        upperSectionTotal >= Round.upperBonusThreshold ? Round.upperBonusValue : 0
    }

    public var lowerSectionTotal: Int {
        ScoreCategory.lowerSection.reduce(0) { $0 + (scores[$1] ?? 0) }
    }

    public var boatBonus: Int {
        boatBonusCount * Round.boatBonusValue
    }

    public var grandTotal: Int {
        upperSectionTotal + upperBonus + lowerSectionTotal + boatBonus
    }
}
