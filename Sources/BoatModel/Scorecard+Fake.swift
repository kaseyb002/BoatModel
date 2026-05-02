import Foundation

extension Scorecard {
    public static func fake(
        scores: [ScoreCategory: Int] = [:],
        boatBonusCount: Int = 0
    ) -> Scorecard {
        .init(scores: scores, boatBonusCount: boatBonusCount)
    }
}
