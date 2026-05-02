import Foundation

public enum DieValue: Int, CaseIterable, Equatable, Codable, Sendable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6

    public var displayableName: String {
        switch self {
        case .one: "One"
        case .two: "Two"
        case .three: "Three"
        case .four: "Four"
        case .five: "Five"
        case .six: "Six"
        }
    }
}
