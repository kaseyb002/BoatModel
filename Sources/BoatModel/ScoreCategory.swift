import Foundation

public enum ScoreCategory: String, CaseIterable, Equatable, Codable, Sendable {
    // Upper section
    case ones
    case twos
    case threes
    case fours
    case fives
    case sixes

    // Lower section
    case threeOfAKind
    case fourOfAKind
    case fullHouse
    case smallStraight
    case largeStraight
    case chance
    case boat

    public var displayableName: String {
        switch self {
        case .ones: "Ones"
        case .twos: "Twos"
        case .threes: "Threes"
        case .fours: "Fours"
        case .fives: "Fives"
        case .sixes: "Sixes"
        case .threeOfAKind: "Three of a Kind"
        case .fourOfAKind: "Four of a Kind"
        case .fullHouse: "Full House"
        case .smallStraight: "Small Straight"
        case .largeStraight: "Large Straight"
        case .chance: "Chance"
        case .boat: "Boat"
        }
    }

    public var isUpperSection: Bool {
        Self.upperSection.contains(self)
    }

    public var isLowerSection: Bool {
        Self.lowerSection.contains(self)
    }

    public static var upperSection: [ScoreCategory] {
        [.ones, .twos, .threes, .fours, .fives, .sixes]
    }

    public static var lowerSection: [ScoreCategory] {
        [.threeOfAKind, .fourOfAKind, .fullHouse, .smallStraight, .largeStraight, .chance, .boat]
    }

    public var matchingDieValue: DieValue? {
        switch self {
        case .ones: .one
        case .twos: .two
        case .threes: .three
        case .fours: .four
        case .fives: .five
        case .sixes: .six
        default: nil
        }
    }

    public static func upperCategory(for dieValue: DieValue) -> ScoreCategory {
        switch dieValue {
        case .one: .ones
        case .two: .twos
        case .three: .threes
        case .four: .fours
        case .five: .fives
        case .six: .sixes
        }
    }
}
