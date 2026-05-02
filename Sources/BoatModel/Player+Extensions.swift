import Foundation

extension Player {
    public var logValue: String {
        """
        ID: \(id)
        Name: \(name)
        Grand Total: \(scorecard.grandTotal)
        Upper: \(scorecard.upperSectionTotal) (bonus: \(scorecard.upperBonus))
        Lower: \(scorecard.lowerSectionTotal)
        Boat Bonus: \(scorecard.boatBonus)
        """
    }
}

extension [Player] {
    public var logValue: String {
        var text: String = ""
        for player in self {
            text += player.logValue
            text += "\n\n"
        }
        return text
    }
}
